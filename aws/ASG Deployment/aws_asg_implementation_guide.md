# Step-by-Step Implementation: Non-Immutable ASG Deployment

This guide provides a "pin to pin" step-by-step implementation for the **Non-Immutable (Docker + ECR + SSM)** deployment pattern. This is the recommended pattern for frequent, fast application releases.

---

## Phase 1: AWS Infrastructure Setup

Before configuring GitHub Actions, you need the base AWS infrastructure ready.

### 1. Create the Amazon ECR Repository
1. Go to the AWS Console -> **Elastic Container Registry (ECR)**.
2. Click **Create repository**.
3. Visibility settings: **Private**.
4. Repository name: `xr-backend` (or your app name).
5. Click **Create repository**.

### 2. Create the SSM Parameter
1. Go to **AWS Systems Manager** -> **Parameter Store**.
2. Click **Create parameter**.
3. Name: `/production/xr-backend/image`
4. Tier: **Standard**
5. Type: **String**
6. Data type: **text**
7. Value: `placeholder` (We will overwrite this in the pipeline).
8. Click **Create parameter**.

### 3. Base AMI & ASG Setup
*(As described in the document)*
1. Launch an Ubuntu EC2 instance, install Docker, AWS CLI, and SSM Agent.
2. Create an AMI from this instance (e.g., `prod-base-ubuntu-docker`).
3. Create a **Launch Template** using this Base AMI. Add this User Data script to the Launch Template:
   ```bash
   #!/bin/bash
   set -euo pipefail
   REGION="ap-south-1"
   PARAMETER="/production/xr-backend/image"
   CONTAINER="xr_backend"
   
   # Read image from SSM
   IMAGE=$(aws ssm get-parameter --name "$PARAMETER" --region "$REGION" --query 'Parameter.Value' --output text)
   
   # Login and Pull
   aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin $(echo $IMAGE | cut -d/ -f1)
   docker pull "$IMAGE"
   
   # Run
   docker rm -f "$CONTAINER" 2>/dev/null || true
   docker run -d --name "$CONTAINER" --restart unless-stopped -p 8080:8080 "$IMAGE"
   ```
4. Create your **Auto Scaling Group (ASG)** using this Launch Template.

---

## Phase 2: Setup GitHub OIDC in AWS (No Access Keys!)

Using OpenID Connect (OIDC) is the most secure way for GitHub Actions to authenticate with AWS.

### 1. Create the Identity Provider in AWS IAM
1. Go to **AWS IAM** -> **Identity providers** (left menu).
2. Click **Add provider**.
3. Provider type: **OpenID Connect**.
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Click **Get thumbprint**.
6. Audience: `sts.amazonaws.com`
7. Click **Add provider**.

### 2. Create the IAM Role for GitHub Actions
1. Go to **AWS IAM** -> **Roles** -> **Create role**.
2. Trusted entity type: **Web identity**.
3. Identity provider: Select `token.actions.githubusercontent.com`.
4. Audience: `sts.amazonaws.com`.
5. GitHub organization: Your GitHub Username or Organization (e.g., `my-org`).
6. GitHub repository: Your Repo Name (e.g., `my-repo`).
7. Click **Next**.
8. **Permissions:** We need to create an inline policy later, so just click **Next** for now.
9. Role name: `GitHubActions-ASG-DeployRole`
10. Click **Create role**.

### 3. Add Permissions to the Role
1. Find the newly created role `GitHubActions-ASG-DeployRole` and open it.
2. Under **Permissions policies**, click **Add permissions** -> **Create inline policy**.
3. Switch to the **JSON** tab and paste the following (replace `<ACCOUNT_ID>` and `<REGION>`):
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ecr:GetAuthorizationToken"
               ],
               "Resource": "*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "ecr:BatchCheckLayerAvailability",
                   "ecr:GetDownloadUrlForLayer",
                   "ecr:GetRepositoryPolicy",
                   "ecr:DescribeRepositories",
                   "ecr:ListImages",
                   "ecr:DescribeImages",
                   "ecr:BatchGetImage",
                   "ecr:InitiateLayerUpload",
                   "ecr:UploadLayerPart",
                   "ecr:CompleteLayerUpload",
                   "ecr:PutImage"
               ],
               "Resource": "arn:aws:ecr:<REGION>:<ACCOUNT_ID>:repository/xr-backend"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "ssm:PutParameter",
                   "ssm:GetParameter"
               ],
               "Resource": "arn:aws:ssm:<REGION>:<ACCOUNT_ID>:parameter/production/xr-backend/image"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "ssm:SendCommand"
               ],
               "Resource": [
                   "arn:aws:ec2:<REGION>:<ACCOUNT_ID>:instance/*",
                   "arn:aws:ssm:<REGION>:*:document/AWS-RunShellScript"
               ]
           }
       ]
   }
   ```
4. Click **Next**, name the policy `GitHubActionsDeployPolicy`, and click **Create policy**.
5. **CRITICAL:** Copy the **Role ARN** (e.g., `arn:aws:iam::<ACCOUNT_ID>:role/GitHubActions-ASG-DeployRole`). You will need this for GitHub.

---

## Phase 3: GitHub Repository Configuration

1. Go to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions**.
2. Under **Repository secrets**, click **New repository secret**.
   - Name: `AWS_ROLE_ARN`
   - Value: The Role ARN you copied in Phase 2.
3. Add another secret (Optional, but good practice):
   - Name: `AWS_REGION`
   - Value: e.g., `ap-south-1`

---

## Phase 4: GitHub Actions Pipeline YAML

Create the following file in your repository: `.github/workflows/deploy-production.yml`.

> **Note:** The final step uses AWS SSM Run Command to restart the Docker container on *currently running* EC2 instances. New instances launched by the ASG will automatically pull the new image via the User Data script you created in Phase 1.

```yaml
name: Deploy Production (Non-Immutable)

on:
  push:
    branches:
      - main # Triggers deployment when code is merged to main

env:
  AWS_REGION: ${{ secrets.AWS_REGION || 'ap-south-1' }}
  ECR_REPOSITORY: xr-backend
  SSM_PARAMETER: /production/xr-backend/image
  CONTAINER_NAME: xr_backend

permissions:
  id-token: write   # Required for requesting the OIDC JWT token
  contents: read    # Required for actions/checkout

jobs:
  build-and-deploy:
    name: Build, Push, and Deploy
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # (Optional) Step to build/test your app before Docker
      # - name: Setup .NET / Node
      #   uses: actions/setup-dotnet@v4 ...

      - name: Configure AWS Credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push Docker image to ECR
        id: build-image
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }} # Immutable Git SHA tag
        run: |
          # Build a docker container and push it to ECR
          docker build -t $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "IMAGE_URI=$REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_ENV

      - name: Update SSM Parameter
        run: |
          echo "Updating SSM Parameter $SSM_PARAMETER with image $IMAGE_URI"
          aws ssm put-parameter \
            --name "$SSM_PARAMETER" \
            --value "$IMAGE_URI" \
            --type "String" \
            --overwrite

      - name: Deploy to Existing ASG Instances
        run: |
          echo "Triggering SSM Run Command to update existing instances..."
          
          # Fetch instances currently attached to the specific SSM Parameter / Application
          # Alternatively, you can target instances by tags (e.g., target ASG instances)
          
          COMMAND="
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${{ steps.login-ecr.outputs.registry }};
            docker pull $IMAGE_URI;
            docker rm -f $CONTAINER_NAME || true;
            docker run -d --name $CONTAINER_NAME --restart unless-stopped -p 8080:8080 $IMAGE_URI;
          "
          
          # We execute this command on all EC2 instances tagged with our ASG name.
          # Update the tag value below to match your actual ASG Name tag!
          aws ssm send-command \
            --document-name "AWS-RunShellScript" \
            --targets "Key=tag:aws:autoscaling:groupName,Values=Your-ASG-Name" \
            --parameters '{"commands":["'"$COMMAND"'"]}' \
            --comment "Deploying new image $IMAGE_URI" \
            --timeout-seconds 600 \
            --max-concurrency "50%" \
            --max-errors "10%"
```

### What this Pipeline Does:
1. **OIDC Authentication**: Authenticates to AWS securely without permanent keys.
2. **Docker Build & Push**: Builds your code and pushes it to ECR, tagging it with the exact Git Commit SHA (`${{ github.sha }}`) to keep the image strictly versioned.
3. **SSM Update**: Updates `/production/xr-backend/image` with the new ECR URI. Any *new* EC2 instances created by ASG scale-out will read this and pull the new app.
4. **SSM Run Command**: Uses the AWS SSM Agent installed on your *currently running* EC2 instances to dynamically log in to ECR, pull the new Docker image, kill the old container, and start the new one. Using `--max-concurrency "50%"` ensures half your servers stay up while the other half updates, preventing downtime.
