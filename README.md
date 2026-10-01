# Secure Azure Container Platform
 
A security-focused container platform built with **Terraform, Docker, GitHub Actions, GHCR, and Microsoft Azure**.
 
The project demonstrates practical Cloud and DevOps engineering patterns around containerization, CI automation, vulnerability scanning, Infrastructure as Code, and Azure Container Apps.
 
The repository is developed incrementally. Implemented components are kept separate from planned capabilities so that the documented architecture reflects the actual project state.
 
---
 
## Table of Contents
 
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Current Implementation](#current-implementation)
- [Container Image CI](#container-image-ci)
- [Container Security](#container-security)
- [GitHub Container Registry](#github-container-registry)
- [GitHub Actions Hardening](#github-actions-hardening)
- [Terraform Infrastructure](#terraform-infrastructure)
- [Terraform Configuration](#terraform-configuration)
- [Terraform CI](#terraform-ci)
- [Workflows](#workflows)
- [Repository Structure](#repository-structure)
- [Technologies](#technologies)
- [Security Principles](#security-principles)
- [Cost Control](#cost-control)
- [Roadmap](#roadmap)
- [Project Status](#project-status)
---
 
## Project Overview
 
The platform currently combines three main areas:
 
- **Container delivery**: building, testing, scanning, and publishing a container image
- **Infrastructure as Code**: provisioning Azure resources through reusable Terraform modules
- **CI validation**: independently validating application and infrastructure changes
Application and infrastructure workflows are intentionally separated so that changes only trigger the CI processes relevant to them.
 
The Azure infrastructure currently includes:
 
- Resource Group
- Azure Container Apps Environment
- Azure Container App
- HTTPS-only external ingress
- Configurable IP restrictions
- Scale-to-zero configuration
> **Note:** The remaining Azure runtime integration, including secure authentication to the private container registry, is intentionally not considered complete yet.
 
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
    Container Image CI               Terraform CI
            |                             |
   +--------+--------+             +------+------+
   |        |        |             |      |      |
   v        v        v             v      v      v
 Build    Health   Trivy          fmt    init  validate
          Check    Scan
   |                 |
   +--------+--------+
            |
            v
          GHCR
   Container Registry
            |
            |  Runtime integration
            |  (not yet completed)
            v
   Azure Container Apps
   (Terraform foundation)
```
 
Terraform currently defines the Azure runtime infrastructure, while secure registry authentication and end-to-end deployment of the GHCR image remain future implementation steps.
 
---
 
## Current Implementation
 
### Containerized Application
 
The repository contains a lightweight Flask application used as the workload for the platform.
 
The application provides:
 
- HTTP application endpoint
- `/health` health endpoint
- Python / Flask runtime
- Port `8080`
- Non-root container execution
Example response from the root endpoint:
 
```text
Secure Azure Container Platform is running
```
 
Health endpoint:
 
```text
GET /health
```
 
Example response:
 
```json
{
  "status": "ok"
}
```
 
### Docker Container
 
The application is packaged using a minimal Python container image.
 
Current container hardening includes:
 
- `python:3.14-slim` base image
- Dedicated Linux group
- Dedicated non-root application user
- Application files owned by the application user
- Runtime execution as an unprivileged user
- Dependency installation without retaining the pip download cache
- Reduced Docker build context through `.dockerignore`
The container listens on port `8080`.
 
Build locally:
 
```bash
docker build -t secure-azure-container-platform:local ./app
```
 
Run locally:
 
```bash
docker run --rm -p 8080:8080 secure-azure-container-platform:local
```
 
Validate health:
 
```bash
curl http://localhost:8080/health
```
 
---
 
## Container Image CI
 
Changes under `app/**` trigger the container workflow.
 
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
 
- Pull requests perform build, runtime validation, and vulnerability scanning **without** publishing an image.
- Publishing only occurs after changes are merged or pushed to the configured `main` workflow path.
- The publish job depends on successful completion of the build and validation job.

### Runtime Validation
 
The CI pipeline starts the built image temporarily and binds it only to the GitHub Actions runner loopback interface:
 
```text
127.0.0.1:8080
```
 
The pipeline then validates `/health`. The health request uses retries so that short container startup delays do not immediately fail the workflow.
 
---
 
## Container Security
 
Container security is integrated directly into the CI workflow.
 
Current controls include:
 
- Non-root container execution
- Minimal Python base image
- Automated runtime health validation
- Trivy vulnerability scanning
- Critical vulnerability failure policy
- Operating-system and application dependency scanning
- Restricted GitHub Actions permissions
- Controlled container publishing
- Immutable GitHub Actions references
Trivy scans the following vulnerability types:
 
```text
os
library
```
 
The pipeline fails on vulnerabilities with severity `CRITICAL`. Unfixed vulnerabilities are currently ignored by the configured scan policy.
 
---
 
## GitHub Container Registry
 
Container images are published to:
 
```text
ghcr.io/mikecayan99/secure-azure-container-platform
```
 
GitHub Actions authenticates to GHCR using the workflow-provided `GITHUB_TOKEN`. No separate long-lived registry password is stored in the repository.
 
Package publishing permission is limited to the publish job:
 
```yaml
permissions:
  contents: read
  packages: write
```
 
The build and validation job only requires:
 
```yaml
permissions:
  contents: read
```
 
Container package visibility is managed through GitHub package settings.
 
---
 
## GitHub Actions Hardening
 
External GitHub Actions used by the repository are pinned to immutable commit SHAs rather than relying only on moving major-version tags.
 
Examples include:
 
- `actions/checkout`
- `hashicorp/setup-terraform`
- `docker/metadata-action`
- `docker/build-push-action`
- `docker/login-action`
- `aquasecurity/trivy-action`
This reduces the risk of an external action reference changing unexpectedly while preserving version comments for readability.
 
---
 
## Terraform Infrastructure
 
Azure infrastructure is managed using Terraform and the AzureRM provider. The configuration uses reusable local modules.
 
```text
terraform/modules/
├── resource-group/
├── container-app-environment/
└── container-app/
```
 
### Resource Group Module
 
Manages the Azure Resource Group used by the platform.
 
Outputs:
 
- Resource Group name
- Azure location
### Container App Environment Module
 
Creates the Azure Container Apps runtime environment.
 
Outputs:
 
- Environment name
- Location
- Resource Group name
- Environment resource ID
### Container App Module
 
Defines the application runtime.
 
| Setting          | Value               |
| ---------------- | ------------------- |
| Revision mode    | Single              |
| CPU              | `0.25`              |
| Memory           | `0.5 GiB`           |
| Min replicas     | `0`                 |
| Max replicas     | `1`                 |
| Ingress          | External, port 8080 |
| Connections      | HTTPS only          |
| IP allow rules   | Configurable        |
 
Scale configuration:
 
```text
min_replicas = 0
max_replicas = 1
```
 
This allows the application to scale down when not required and supports the project's cost-control goals.
 
### Network Access Restrictions
 
The Container App module supports configurable IP ranges:
 
```hcl
allowed_ip_ranges = [
  "203.0.113.10/32"
]
```
 
Terraform dynamically creates Azure Container App ingress IP security restrictions for the supplied ranges. The address above is only an example value.
 
---
 
## Terraform Configuration
 
The project uses Terraform with the AzureRM provider `~> 5.0`.
 
Provider configuration and required provider constraints are separated using the conventional structure:
 
```text
providers.tf
versions.tf
```
 
### Terraform Variables
 
Important configurable values:
 
```text
location
resource_group_name
container_app_environment_name
container_app_name
container_image
allowed_ip_ranges
```
 
A safe example configuration is included as `terraform/terraform.tfvars.example`.
 
Copy it locally when creating a real configuration:
 
```bash
cp terraform.tfvars.example terraform.tfvars
```
 
On PowerShell:
 
```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```
 
Then replace the example values with the required deployment values. The real `terraform.tfvars` file is excluded from Git through `.gitignore`.
 
---
 
## Terraform CI
 
Changes under `terraform/**` trigger a dedicated Terraform validation workflow.
 
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
 
The CI workflow intentionally performs static validation only. It does **not** automatically execute:
 
```text
terraform plan
terraform apply
terraform destroy
```
 
Infrastructure-changing operations therefore remain explicit and manually controlled.
 
---
 
## Workflows
 
### CI Workflow Separation
 
Container and Terraform validation use independent GitHub Actions workflows.
 
```text
app/**        →  Container Image CI
terraform/**  →  Terraform CI
```
 
Each workflow also triggers when its own workflow definition changes. This prevents unrelated repository changes from unnecessarily running every pipeline.
 
### Git Workflow
 
Changes are developed using short-lived branches and Pull Requests.
 
```text
Feature / Chore Branch
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
Automated CI
        ↓
Review
        ↓
Merge to main
```
 
CI validation is performed before repository changes are integrated into `main`.
 
### Terraform Workflow
 
Infrastructure development follows a reviewed Terraform workflow:
 
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
 
Temporary Azure resources can later be removed using `terraform destroy`. Infrastructure-changing operations are intentionally kept outside the automatic CI workflow.
 
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
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
│
├── terraform/
│   ├── modules/
│   │   ├── resource-group/
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   │
│   │   ├── container-app-environment/
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   │
│   │   └── container-app/
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   │
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
│
├── .gitignore
└── README.md
```
 
---
 
## Technologies
 
- Microsoft Azure
- Azure Container Apps
- Azure CLI
- Terraform (AzureRM Provider)
- Docker
- Python / Flask
- Git / GitHub
- GitHub Actions
- GitHub Container Registry
- Trivy
---
 
## Security Principles
 
Security controls are introduced as part of the engineering workflow rather than added only as documentation.
 
- Least-privilege GitHub Actions permissions
- Non-root container execution
- Automated vulnerability scanning
- Runtime health validation
- Controlled container publishing
- Immutable GitHub Actions references
- HTTPS-only Container App ingress
- Configurable ingress IP restrictions
- Explicit infrastructure changes
- Infrastructure as Code
- Separation of application and infrastructure validation
Additional Azure-native identity and registry security controls remain future work.
 
---
 
## Cost Control
 
The project operates with a strict Azure learning and development budget of approximately **20 EUR**. Cost is therefore treated as an architectural constraint.
 
Current cost-control decisions:
 
- Container App minimum replicas set to `0`
- Container App maximum replicas limited to `1`
- Small container CPU and memory allocation
- No automatic Terraform deployment from CI
- Intentional infrastructure creation
- Destruction of temporary Azure resources after testing
Before paid Azure infrastructure is deployed:
 
1. Expected resources are reviewed.
2. Deployment is performed intentionally.
3. Runtime behavior is validated.
4. Temporary resources are removed when they are no longer required.
---
 
## Roadmap
 
### Implemented
 
- [x] Dockerized Flask application
- [x] Application health endpoint
- [x] Non-root container execution
- [x] Minimal Python container base image
- [x] Local Docker build and runtime validation
- [x] GHCR image publishing
- [x] Automated container image build
- [x] Automated container health validation
- [x] Trivy vulnerability scanning
- [x] Critical vulnerability failure policy
- [x] Separate build/test and publish CI jobs
- [x] Restricted GitHub Actions permissions
- [x] Immutable GitHub Action references
- [x] Terraform AzureRM foundation
- [x] Terraform Resource Group module
- [x] Terraform Container App Environment module
- [x] Terraform Container App module
- [x] Container App HTTPS-only ingress
- [x] Configurable Container App IP restrictions
- [x] Scale-to-zero configuration
- [x] Terraform outputs and module integration
- [x] Terraform CI validation
- [x] Path-filtered Container and Terraform workflows
- [x] `terraform.tfvars.example`

### Next
 
- [ ] Implement secure Container App access to the GHCR image
- [ ] Validate private container deployment in Azure
- [ ] Integrate Managed Identity where appropriate
- [ ] Perform full Azure runtime validation

### Later
 
Depending on future requirements:
 
- [ ] Azure monitoring and diagnostics
- [ ] Secure application configuration
- [ ] Additional network and access controls
- [ ] Automated Azure deployment
- [ ] Terraform remote state
- [ ] Additional CI/CD security controls
---
 
## Project Status
 
The current implementation provides a working foundation for secure container delivery, CI validation, and modular Azure infrastructure.
 
Implemented areas:
 
- Containerization
- Non-root runtime
- CI build and runtime validation
- Vulnerability scanning
- GHCR publishing
- Terraform modularization
- Azure Container Apps infrastructure definition
- Ingress restrictions
- Cost-conscious scaling configuration
- Terraform static validation
Further Azure runtime capabilities can be added incrementally as the platform evolves.