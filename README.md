# Secure Azure Container Platform

A security-focused container delivery platform built with **Terraform, Docker, GitHub Actions, GHCR, and Microsoft Azure**.

The project demonstrates how a containerized application can be built, validated, security-scanned, published, and ultimately deployed to Azure using Infrastructure as Code and automated CI workflows.

The repository is designed around practical Cloud and DevOps engineering patterns rather than isolated technology demonstrations.

---

## Project Overview

The platform combines application containerization, CI automation, container security, Infrastructure as Code, and Azure deployment into a single workflow.

The current implementation focuses on two independent areas:

- **Container delivery** — building, testing, scanning, and publishing the application container
- **Infrastructure validation** — managing Azure infrastructure with Terraform and validating infrastructure changes through CI

Infrastructure and application workflows are intentionally separated so that changes only trigger the CI processes relevant to them.

---

## Architecture

```text
                         GitHub Repository
                                |
                 +--------------+--------------+
                 |                             |
                 v                             v
              app/**                      terraform/**
                 |                             |
                 v                             v
          Container Image CI              Terraform CI
                 |                             |
        +--------+--------+            +-------+-------+
        |        |        |            |       |       |
        v        v        v            v       v       v
      Build   Health    Trivy          fmt    init   validate
              Check     Scan
        |                 |
        +--------+--------+
                 |
                 v
                GHCR
          Private Container
               Image
                 |
                 v
        Azure Container Platform
             (planned)
```

The Azure runtime layer will be introduced incrementally using Terraform.

---

## Current Implementation

### Containerized Application

The repository contains a lightweight Flask application used as the workload for the platform.

The application provides:

- HTTP application endpoint
- `/health` health endpoint
- Containerized Python runtime
- Port `8080`
- Non-root container execution

The Docker image is built from a minimal Python base image and runs using a dedicated unprivileged user.

---

### Container Image CI

Application changes under `app/**` trigger the container workflow.

The workflow performs:

```text
Checkout
   ↓
Generate Image Metadata
   ↓
Build Container Image
   ↓
Start Test Container
   ↓
Health Check
   ↓
Trivy Vulnerability Scan
   ↓
Publish to GHCR
```

Pull requests perform build, runtime validation, and security scanning without publishing an image.

Image publishing only occurs after changes reach the configured push workflow.

The publish job depends on successful completion of the build and validation job.

---

### Container Security

Container security is integrated directly into the CI workflow.

Current controls include:

- Non-root container execution
- Minimal container base image
- Automated runtime health validation
- Trivy vulnerability scanning
- CI failure for configured critical vulnerabilities
- Private container image storage
- Restricted GitHub Actions permissions

Trivy scans both operating-system packages and application libraries.

---

### GitHub Container Registry

Container images are stored in **GitHub Container Registry (GHCR)**.

```text
ghcr.io/mikecayan99/secure-azure-container-platform
```

The container package is private.

GitHub Actions authenticates to GHCR using the workflow-provided `GITHUB_TOKEN`. Publishing permissions are restricted to the job that requires package write access.

---

## Terraform Infrastructure

Azure infrastructure is managed using Terraform and the AzureRM provider.

The Terraform configuration uses local reusable modules to separate infrastructure components from the root configuration.

Current structure:

```text
terraform/
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── versions.tf
└── modules/
    └── resource-group/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

The Resource Group is implemented as a dedicated Terraform module.

The root module passes configuration values to the child module and consumes the module outputs.

Conceptually:

```text
Root Variables
      ↓
Module Arguments
      ↓
Child Module Variables
      ↓
Azure Resource
      ↓
Child Module Outputs
      ↓
Root Outputs
```

This structure allows additional Azure components to be introduced without placing all infrastructure configuration in a single Terraform file.

---

## Terraform CI

Terraform changes under `terraform/**` trigger a dedicated Terraform CI workflow.

The workflow performs:

```text
Checkout
   ↓
Setup Terraform
   ↓
terraform fmt -check -recursive
   ↓
terraform init -backend=false
   ↓
terraform validate
```

The workflow currently performs **static validation only**.

It does not automatically execute:

```text
terraform plan
terraform apply
terraform destroy
```

Infrastructure-changing operations remain intentional and manually reviewed.

This avoids CI automatically modifying Azure resources while the infrastructure architecture is still being developed.

---

## CI Workflow Separation

Container and Terraform validation are implemented as separate GitHub Actions workflows.

```text
app/**
   ↓
Container Image CI


terraform/**
   ↓
Terraform CI
```

Each workflow also runs when its own workflow definition is modified.

This prevents unrelated changes from unnecessarily triggering both pipelines.

---

## Git Workflow

Changes are developed using short-lived feature branches and Pull Requests.

```text
Feature Branch
      ↓
Development
      ↓
Local Validation
      ↓
Commit
      ↓
Push
      ↓
Pull Request
      ↓
Automated CI Checks
      ↓
Review
      ↓
Merge to main
```

CI validation is used before changes are integrated into the main branch.

---

## Local Container Workflow

The application can also be built and tested locally.

Typical workflow:

```text
Dockerfile
    ↓
docker build
    ↓
docker run
    ↓
Health Validation
    ↓
docker logs / inspect / exec
```

Operational Docker commands are used for troubleshooting and runtime inspection.

Examples include:

```text
docker ps
docker logs
docker inspect
docker exec
```

---

## Terraform Workflow

Infrastructure changes follow a reviewed Terraform workflow:

```text
terraform init
      ↓
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
Review
      ↓
terraform apply
      ↓
Validation
```

Resources used for temporary testing can be removed using:

```text
terraform destroy
```

Infrastructure changes are reviewed before execution.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── container-ci.yml
│       └── terraform-ci.yml
│
├── app/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .dockerignore
│
├── terraform/
│   ├── modules/
│   │   └── resource-group/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── versions.tf
│
├── .gitignore
└── README.md
```

The repository structure will evolve as additional Azure infrastructure components are introduced.

---

## Technologies

### Currently Used

- Microsoft Azure
- Terraform
- AzureRM Provider
- Docker
- Python / Flask
- Git
- GitHub
- GitHub Actions
- GitHub Container Registry (GHCR)
- Trivy
- Azure CLI

### Planned / Evaluated as the Platform Evolves

Additional Azure services will be introduced only where they support the architecture and security requirements of the platform.

Potential areas include:

- Azure Container Apps
- Managed Identities
- Secure secret handling
- Azure monitoring and diagnostics
- Additional network and access controls

Planned components are intentionally not treated as implemented features until they are integrated and validated.

---

## Security Principles

Security controls are introduced as part of the engineering workflow rather than as a separate demonstration layer.

Current principles include:

- Least-privilege CI permissions
- Non-root container execution
- Automated vulnerability scanning
- Private container image storage
- Controlled image publishing
- Explicit infrastructure changes
- Infrastructure as Code
- Separation of application and infrastructure validation

Additional Azure-native security controls will be introduced as the runtime architecture is implemented.

---

## Cost Control

The project operates with a strict Azure budget of approximately **20 EUR**.

Cost is therefore treated as an architectural constraint.

Before paid Azure resources are deployed:

1. The resource and expected cost are reviewed.
2. Deployment is performed intentionally.
3. Resources are validated after deployment.
4. Temporary resources are destroyed when they are no longer required.

Expensive continuously running services are avoided unless they provide a clear engineering benefit.

---

## Roadmap

The platform is being implemented incrementally.

### Implemented

- Dockerized Flask application
- Application health endpoint
- Non-root container execution
- Local Docker build and runtime validation
- Private GHCR container registry
- Automated container image build
- Automated container health validation
- Trivy vulnerability scanning
- Controlled GHCR image publishing
- Separate build/test and publish CI jobs
- Terraform AzureRM foundation
- Terraform Resource Group module
- Terraform outputs and module integration
- Terraform CI validation
- Path-filtered Container and Terraform workflows
- Least-privilege GitHub Actions permissions

### Next

- Azure Container Apps infrastructure
- Container App Environment
- Deployment of the private GHCR image to Azure
- Secure registry authentication from Azure
- Runtime validation in Azure

### Later

Depending on the requirements of the deployed platform:

- Managed Identity integration
- Secure application configuration and secret handling
- Azure monitoring and diagnostics
- Additional infrastructure security controls
- CI/CD deployment improvements
- Terraform remote state

The roadmap may evolve as architectural decisions are validated during implementation.

---

## Project Status

**Active Development**

The container build, validation, vulnerability scanning, registry publishing, Terraform module foundation, and CI validation workflows are operational.

The next major milestone is extending the Terraform infrastructure to provide the Azure runtime environment for the containerized application.

---

## Disclaimer

This repository is a Cloud / DevOps portfolio project designed to demonstrate practical engineering patterns using Azure, Terraform, Docker, GitHub Actions, container security, and Infrastructure as Code.

The project does not represent a certified production environment and does not claim compliance with regulatory or certification frameworks.