# GitHub Actions File Structure for AWS ASG Deployments

Based on the **AWS Auto Scaling Group Production Deployment** document you provided, there are two distinct deployment strategies: **Immutable** and **Non-Immutable**. 

Depending on which strategy you choose, your GitHub Actions and project file structure will look different. Below is a guide on how to structure your `.github/workflows/` and related scripts for both patterns.

---

## Pattern A: Immutable AMI Deployment
*In this model, every release creates a new Amazon Machine Image (AMI) containing your application.*

### Suggested File Structure
```text
.github/
└── workflows/
    ├── pr-validation.yml             # Runs tests on Pull Requests
    ├── deploy-immutable.yml          # Main deployment pipeline (Build -> Packer -> ASG)
    └── rollback-immutable.yml        # Reverts Launch Template to previous AMI

infrastructure/
└── packer/
    ├── app-ami.pkr.hcl               # Packer template defining how to build the AMI
    └── scripts/
        ├── install-dependencies.sh   # Installs runtime (e.g., .NET 8)
        └── setup-app.sh              # Copies build artifacts and configures systemd
```

### Workflow Steps (`deploy-immutable.yml`)
1. **Checkout & Setup:** Checkout code and set up the build environment (e.g., .NET 8).
2. **Build & Test:** Compile the application and run unit tests.
3. **Publish:** Publish the application artifacts.
4. **Configure AWS Credentials:** Authenticate via OIDC (`aws-actions/configure-aws-credentials`).
5. **Build AMI:** Run `packer build` to bake a new AMI containing the artifacts.
6. **Update Launch Template:** Update the AWS Launch Template to point to the newly created AMI.
7. **Instance Refresh:** Trigger an AWS Auto Scaling Group Instance Refresh to gradually replace old EC2 instances with new ones.

---

## Pattern B: Non-Immutable Deployment (Recommended for Docker)
*In this model, the AMI is a stable base OS. The application is a Docker container stored in ECR, and the current version is tracked in AWS SSM Parameter Store.*

### Suggested File Structure
```text
.github/
└── workflows/
    ├── pr-validation.yml             # Runs tests on Pull Requests
    ├── deploy-non-immutable.yml      # Main pipeline (Build -> Docker -> ECR -> SSM -> Deploy)
    └── rollback-non-immutable.yml    # Reverts SSM Parameter to previous Git SHA

scripts/
└── deploy/
    ├── update-ssm-parameter.sh       # Updates SSM with the new ECR Image URI
    └── update-existing-instances.sh  # Uses AWS SSM Run Command to restart containers on existing EC2s

Dockerfile                            # Application Dockerfile
```

### Workflow Steps (`deploy-non-immutable.yml`)
1. **Checkout & Setup:** Checkout code.
2. **Build & Test:** Compile and test the application.
3. **Configure AWS Credentials:** Authenticate via OIDC.
4. **Login to ECR:** Use `aws-actions/amazon-ecr-login`.
5. **Build & Push Docker Image:** 
   - Build the Docker image.
   - Tag the image explicitly with the **Git SHA** (e.g., `xr-backend:8f31a21`). Do not rely on `latest`.
   - Push to Amazon ECR.
6. **Update SSM Parameter:** Update the SSM Parameter (e.g., `/production/xr-backend/image`) with the new image URI.
7. **Rolling Update:** Trigger a deployment on existing instances (e.g., using AWS SSM Run Command or CodeDeploy) to pull the new image and restart the container. *(Note: New instances scaling out will automatically pull the new image from SSM during boot via EC2 User Data).*

---

## Key Best Practices for GitHub Actions

1. **Security:** 
   - Never store long-lived AWS Access Keys in GitHub Secrets. Use **GitHub OIDC (OpenID Connect)** to authenticate GitHub Actions with AWS.
2. **Environment Protection:**
   - Use GitHub Environments for production deployments to require manual approval before updating AMIs or SSM Parameters.
3. **Tagging:**
   - Always tag your Docker images or AMIs with the immutable Git Commit SHA (`${{ github.sha }}`) to ensure traceability back to the exact code change.
4. **Rollbacks:**
   - Keep a dedicated workflow for rollbacks. For Immutable, rollback means reverting the Launch Template to the previous AMI ID. For Non-Immutable, it means reverting the SSM Parameter to the previous Git SHA image.
