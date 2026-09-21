# Step-by-Step Implementation: Immutable ASG Deployment

This guide provides a "pin to pin" step-by-step implementation for the **Immutable Deployment** pattern. In this model, you bake a brand new Amazon Machine Image (AMI) for every code release. Old EC2 instances are terminated and entirely replaced by new instances running the new AMI.

We will use **HashiCorp Packer** within GitHub Actions to build the AMI, and **AWS Auto Scaling Group Instance Refresh** to roll it out safely.

---

## Phase 1: AWS Infrastructure Setup

### 1. Create the Launch Template
1. Go to **AWS EC2** -> **Launch Templates**.
2. Click **Create launch template**.
3. Name: `prod-xr-backend-lt`
4. Choose an initial dummy or base AMI (e.g., standard Ubuntu).
5. Choose your Instance Type, Key Pair (if any), and Security Groups.
6. Under **Advanced details**, assign an IAM Instance Profile (role) that your application needs to run.
7. Click **Create launch template**.

### 2. Create the Auto Scaling Group (ASG)
1. Go to **AWS EC2** -> **Auto Scaling Groups**.
2. Click **Create Auto Scaling group**.
3. Name: `prod-xr-backend-asg`
4. Select the Launch Template you just created (`prod-xr-backend-lt`).
5. Configure your VPC, Subnets, Load Balancer (ALB), and Target Group.
6. Set Desired, Minimum, and Maximum capacity.
7. Click **Create Auto Scaling group**.

---

## Phase 2: Setup GitHub OIDC in AWS

We will securely authenticate GitHub Actions using OIDC.

### 1. Create the Identity Provider (If not already done)
1. Go to **AWS IAM** -> **Identity providers** -> **Add provider**.
2. Type: **OpenID Connect**.
3. URL: `https://token.actions.githubusercontent.com` (Get thumbprint).
4. Audience: `sts.amazonaws.com`.
5. Click **Add provider**.

### 2. Create the IAM Role for GitHub Actions (Packer + ASG)
1. Go to **AWS IAM** -> **Roles** -> **Create role**.
2. Trusted entity type: **Web identity** -> Select your GitHub OIDC provider.
3. Set your GitHub Organization and Repository.
4. Click **Next**, skip permissions for now, and name the role `GitHubActions-ImmutableDeployRole`.
5. Click **Create role**.

### 3. Add Permissions to the Role
1. Open the `GitHubActions-ImmutableDeployRole`.
2. Under **Permissions policies**, click **Add permissions** -> **Create inline policy**.
3. Switch to the **JSON** tab and paste the following policy. *(This grants Packer the ability to create AMIs, and the ASG the ability to update the Launch Template and trigger a refresh)*:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ec2:RunInstances",
                   "ec2:CreateTags",
                   "ec2:DescribeInstances",
                   "ec2:TerminateInstances",
                   "ec2:CreateImage",
                   "ec2:DeregisterImage",
                   "ec2:DescribeImages",
                   "ec2:DescribeSnapshots",
                   "ec2:DeleteSnapshot",
                   "ec2:DescribeRegions",
                   "ec2:DescribeSubnets",
                   "ec2:DescribeSecurityGroups",
                   "ec2:DescribeVpcs",
                   "ec2:GetPasswordData",
                   "ec2:StopInstances",
                   "ec2:DescribeVolumes",
                   "ec2:CreateLaunchTemplateVersion",
                   "ec2:DescribeLaunchTemplates",
                   "ec2:DescribeLaunchTemplateVersions",
                   "ec2:ModifyLaunchTemplate"
               ],
               "Resource": "*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "autoscaling:UpdateAutoScalingGroup",
                   "autoscaling:StartInstanceRefresh",
                   "autoscaling:DescribeAutoScalingGroups",
                   "autoscaling:DescribeInstanceRefreshes"
               ],
               "Resource": "arn:aws:autoscaling:<REGION>:<ACCOUNT_ID>:autoScalingGroup:*:autoScalingGroupName/prod-xr-backend-asg"
           }
       ]
   }
   ```
4. Click **Next**, name it `PackerAndASGDeployPolicy`, and click **Create policy**.
5. **CRITICAL:** Copy the **Role ARN** (e.g., `arn:aws:iam::<ACCOUNT_ID>:role/GitHubActions-ImmutableDeployRole`).

---

## Phase 3: GitHub Repository Configuration

1. Go to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions**.
2. Add a new repository secret:
   - Name: `AWS_ROLE_ARN`
   - Value: The Role ARN from Phase 2.

---

## Phase 4: Packer Configuration

Create a folder in your repo called `packer/` and create two files. Packer will spin up a temporary EC2 instance, install your app, bake the AMI, and tear down the temporary instance.

### `packer/app.pkr.hcl`
```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "xr-backend-app"
}

variable "git_sha" {
  type    = string
  default = "unknown"
}

source "amazon-ebs" "app" {
  ami_name      = "${var.ami_prefix}-${var.git_sha}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  instance_type = "t3.micro"
  region        = "ap-south-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical's AWS Account ID
  }
  ssh_username = "ubuntu"
  tags = {
    Name    = "XR-Backend-Release"
    Commit  = var.git_sha
  }
}

build {
  name    = "bake-app"
  sources = ["source.amazon-ebs.app"]

  # Upload the built application from GitHub Actions to the temporary EC2 instance
  provisioner "file" {
    source      = "../app-build/"
    destination = "/tmp/app/"
  }

  # Run a script to install dependencies and set up the app as a systemd service
  provisioner "shell" {
    script = "./packer/setup.sh"
  }
}
```

### `packer/setup.sh`
```bash
#!/bin/bash
set -e

echo "Updating OS and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y dotnet-sdk-8.0 nginx # Example for .NET

echo "Moving application files..."
sudo mkdir -p /opt/xr-backend
sudo mv /tmp/app/* /opt/xr-backend/
sudo chown -R ubuntu:ubuntu /opt/xr-backend

# (Optional) Create a systemd service to start the app on boot
sudo cat <<EOF > /etc/systemd/system/xr-backend.service
[Unit]
Description=XR Backend Application
After=network.target

[Service]
WorkingDirectory=/opt/xr-backend
ExecStart=/usr/bin/dotnet /opt/xr-backend/XrBackend.dll
Restart=always
User=ubuntu

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable xr-backend.service
```

---

## Phase 5: GitHub Actions Pipeline YAML

Create `.github/workflows/deploy-immutable.yml`. This pipeline builds your code, runs Packer to create the AMI, updates the Launch Template, and triggers the ASG Instance Refresh.

```yaml
name: Deploy Production (Immutable)

on:
  push:
    branches:
      - main

env:
  AWS_REGION: ap-south-1
  ASG_NAME: prod-xr-backend-asg
  LAUNCH_TEMPLATE_NAME: prod-xr-backend-lt

permissions:
  id-token: write   
  contents: read    

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # 1. Build your application (Example: .NET)
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
          
      - name: Publish Application
        run: dotnet publish src/XrBackend/XrBackend.csproj -c Release -o ./app-build/

      # 2. Authenticate with AWS via OIDC
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      # 3. Setup and Run Packer
      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        
      - name: Packer Init
        run: packer init packer/app.pkr.hcl

      - name: Packer Build
        id: packer
        env:
          PKR_VAR_git_sha: ${{ github.sha }}
        # The 'machine-readable' flag lets us extract the resulting AMI ID easily
        run: |
          packer build -machine-readable packer/app.pkr.hcl | tee packer-output.txt
          # Extract the new AMI ID
          NEW_AMI_ID=$(grep 'artifact,0,id' packer-output.txt | cut -d: -f2 | tr -d ' ' | tail -n 1)
          echo "NEW_AMI_ID=$NEW_AMI_ID" >> $GITHUB_ENV
          echo "Successfully created AMI: $NEW_AMI_ID"

      # 4. Update Launch Template
      - name: Update Launch Template
        run: |
          echo "Updating Launch Template $LAUNCH_TEMPLATE_NAME to use AMI $NEW_AMI_ID"
          
          # Create a new version of the launch template with the new AMI
          aws ec2 create-launch-template-version \
            --launch-template-name "$LAUNCH_TEMPLATE_NAME" \
            --version-description "Release ${{ github.sha }}" \
            --source-version '$Latest' \
            --launch-template-data '{"ImageId":"'"$NEW_AMI_ID"'"}'
          
          # Set the newly created version as the default version
          aws ec2 modify-launch-template \
            --launch-template-name "$LAUNCH_TEMPLATE_NAME" \
            --default-version '$Latest'

      # 5. Start ASG Instance Refresh
      - name: Start ASG Instance Refresh
        run: |
          echo "Triggering ASG Instance Refresh for $ASG_NAME..."
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name "$ASG_NAME" \
            --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 300}'
          
          echo "Instance Refresh initiated. AWS will now gradually replace old instances with the new AMI."
```

### What this Pipeline Does:
1. **Code Build**: Compiles your raw code (e.g., .NET, Node, etc.) and puts the artifacts in a folder.
2. **Packer Build**: AWS spins up a temporary EC2 server. Packer securely copies your built artifacts onto this server, installs dependencies (like Nginx, Systemd services, etc.), bakes a permanent snapshot (AMI), and deletes the temporary server.
3. **Launch Template Update**: Injects the newly created AMI ID into your ASG's Launch Template, creating a new "Latest/Default" version.
4. **Instance Refresh**: Tells the Auto Scaling Group to start destroying old instances and spinning up new instances using the new Launch Template. Setting `MinHealthyPercentage: 50` ensures that your app does not go offline while the swap occurs.
