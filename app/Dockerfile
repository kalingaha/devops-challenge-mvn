# Stage 1: Build the application using a full JDK
FROM maven:3.9.6-amazoncorretto-17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven project files (pom.xml) first to leverage Docker cache
COPY pom.xml .

# Download dependencies (only if pom.xml changes, speeding up subsequent builds)
RUN mvn dependency:go-offline -B

# Copy the rest of the application source code
COPY src ./src

# Package the application into a JAR file
RUN mvn package -DskipTests

# Stage 2: Create the final, slim runtime image
# Use a lightweight JRE (Java Runtime Environment) image
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine-jdk AS final

# Create a non-root user and group
# Alpine's 'addgroup -S' creates a system group, 'adduser -S -G' creates a system user.
RUN addgroup -S springboot && adduser -S -G springboot springboot

# Set the working directory
WORKDIR /app

# Copy the built JAR file from the build stage
# The JAR name is usually artifactId-version.jar
COPY --from=build /app/target/devops-0.0.1-SNAPSHOT.jar app.jar

# Expose the port the Spring Boot app will run on
EXPOSE 8080

# Switch to the non-root user
USER springboot

# Command to run the application when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]

# Image size optimization considerations:
# - Using 'alpine' JRE image is very small.
# - Multi-stage build ensures only the JAR and JRE are in final image.
# - The JAR itself is relatively small for a basic Spring Boot app.
# The target image size should be well under 200MB.
