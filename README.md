# DevOps Challenge: Cloud Build CI/CD Pipeline

This repository contains a simple Spring Boot application and a Google Cloud Build CI/CD pipeline (`cloudbuild.yml`) designed to automate the build, test, security scan, infrastructure provisioning (via Terraform), deployment, and health checking of the application on Google Cloud Run. The Cloud Build logs and a summary of the build can be seen on github by clicking the green tick ( or red X ) which appears next to the commit.   



## Pipeline Description

This CI/CD pipeline, defined in `cloudbuild.yml`, automates the software delivery process through a series of sequential and interdependent steps:

1.  **Build and Test Java Application (Maven):**
    * **Tool:** Apache Maven (`maven:3.9.6-amazoncorretto-17`)
    * **Purpose:** Compiles the Spring Boot application, runs unit tests, and packages it into a fat JAR (`devops-0.0.1-SNAPSHOT.jar`). This step ensures that the code compiles and passes its integrated tests before moving forward.

2.  **Build Docker Image:**
    * **Tool:** Docker (`gcr.io/cloud-builders/docker`)
    * **Purpose:** Creates a Docker image of the Spring Boot application based on the `Dockerfile` located in the `app/` directory. The image is tagged with the Git short SHA for versioning.
    * **Note:** During this step, a crucial `JAVA_TOOL_OPTIONS` environment variable is injected into the Docker image's environment to resolve `java.lang.reflect.InaccessibleObjectException` errors when running Tomcat 10.1.x on Java 17, which was a significant debugging point.

3.  **Push Docker Image:**
    * **Tool:** Docker (`gcr.io/cloud-builders/docker`)
    * **Purpose:** Pushes the newly built Docker image to Google Artifact Registry (`devops-repo`). This makes the image available for deployment and further scanning.

4.  **Container Vulnerability Scan (Trivy):**
    * **Tool:** Trivy (`aquasec/trivy:latest`)
    * **Purpose:** Scans the Docker image for known security vulnerabilities. The pipeline is configured to fail if any `CRITICAL` severity vulnerabilities are detected in OS packages or application libraries. This is a crucial security gate.

5.  **Terraform Init, Validate, and Plan:**
    * **Tool:** Terraform (`hashicorp/terraform:1.12.0`)
    * **Purpose:** Initializes the Terraform working directory, validates the `.tf` configuration files for syntax and consistency, and generates an execution plan. This step ensures that our Infrastructure as Code (IaC) is valid and previews the infrastructure changes before actual application.

6.  **Deploy to Cloud Run:**
    * **Tool:** Google Cloud SDK (`gcr.io/google.com/cloudsdktool/cloud-sdk`)
    * **Purpose:** Deploys the Docker image to Google Cloud Run, creating or updating the `devops-challenge` service. It configures the service to be publicly accessible (`--allow-unauthenticated`).
    * **Note:** Initial challenges with permissions for `--allow-unauthenticated` required granting `roles/iam.serviceAccountUser` to the Cloud Build service account on the Google-managed Cloud Run Service Agent (`service-<PROJECT_NUMBER>@gcp-sa-cloudrun.iam.gserviceaccount.com`).

7.  **Health Check Cloud Run:**
    * **Tool:** Google Cloud SDK (`gcr.io/google.com/cloudsdktool/cloud-sdk` which includes `curl`)
    * **Purpose:** After deployment, this step performs a health check on the deployed Cloud Run service. It dynamically retrieves the service URL, then repeatedly curls the `/health` endpoint (as defined by `_HEALTH_CHECK_PATH`) with retries until an HTTP 200 response is received. This ensures the application is fully started and ready to serve traffic before marking the build as successful.

8.  **Write Cloud Run URL to Job Summary:**
    * **Tool:** Google Cloud SDK (`gcr.io/google.com/cloudsdktool/cloud-sdk`)
    * **Purpose:** Fetches the deployed Cloud Run service URL and writes it to a Cloud Build job summary file (`/workspace/_OUT.md`). This provides a convenient, clickable link directly within the Cloud Build console once the pipeline completes successfully.

## Trade-offs Made

During the development of this pipeline, several design decisions and trade-offs were made:

1.  **Terraform "Plan Only" vs. "Apply":**
    * **Trade-off:** The Terraform step currently only performs `init`, `validate`, and `plan`. It does **not** automatically apply infrastructure changes (`terraform apply`).
    * **Reasoning:** For a development environment or a proof-of-concept, a fully automated `terraform apply` might be acceptable. However, in production or more mature environments, it's often preferred to have a manual approval step after a `terraform plan` is reviewed. This provides a human gate to prevent unintended infrastructure modifications. For this initial setup, we opted for the safer "plan only" approach, acknowledging that a manual step would be required to provision new infrastructure changes.

2.  **Container Security Scan (Trivy) Severity:**
    * **Trade-off:** The Trivy scan is configured to fail the build only on `CRITICAL` severity vulnerabilities (`--severity CRITICAL --exit-code 1`).
    * **Reasoning:** While scanning for all severities (low, medium, high, critical) provides the most comprehensive security posture, it can also lead to frequent build failures due to less urgent vulnerabilities, especially in the early stages of development or when using third-party base images/libraries. By focusing on `CRITICAL` issues, we prioritize the most immediate and severe risks, allowing the pipeline to proceed while still catching major security flaws. This balances security rigor with pipeline efficiency. A more mature pipeline might gradually increase the required severity level or introduce vulnerability exemption policies.

3.  **Publicly Accessible Cloud Run Service (`--allow-unauthenticated`):**
    * **Trade-off:** The Cloud Run service is deployed with `--allow-unauthenticated`, making it publicly accessible to anyone on the internet.
    * **Reasoning:** For a demo or a simple web application, public access is desired for easy testing and visibility. However, for internal services or APIs handling sensitive data, this would be a significant security risk. A more secure approach would involve private services with controlled access via Identity-Aware Proxy (IAP), VPC Service Controls, or internal load balancers. This trade-off prioritizes ease of access for the challenge over strict security lockdown, which would add complexity beyond the scope of this initial pipeline.

## Time Spent

The approximate time spent on setting up and debugging this CI/CD pipeline, from initial setup to a fully functional state, was **~16 hours**.

This includes:

* Initial setup of Cloud Build and repository connection.
* Configuring Maven build, Docker build, and push steps.
* Integrating Trivy for vulnerability scanning.
* Adding Terraform plan step.
* Initial Cloud Run deployment.
* **Significant time (~5 hours) was spent debugging:**
    * `java.lang.reflect.InaccessibleObjectException` (due to Java 17 and Tomcat reflection issues).
    * "Revision not ready" (due to Spring Boot not binding to `PORT` environment variable).
    * "Setting IAM policy failed" for `--allow-unauthenticated` (due to subtle Cloud Build SA permissions with the Cloud Run Service Agent).
* Implementing health checks and job summary.

