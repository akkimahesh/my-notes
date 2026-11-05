# AWS OIDC Authentication with IAM and GitHub Actions

A secure, keyless authentication setup for GitHub Actions workflows accessing AWS services using OpenID Connect (OIDC).

> [!NOTE]
> You do **not** need to create an IAM User with long-lived access keys (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) for OIDC. OIDC relies on an Identity Provider and an IAM Role with temporary, short-lived security tokens via AWS STS.

---

## 1. AWS Configuration Steps

### Step 1: Create an Identity Provider
1. Navigate to **AWS Console** -> **IAM** -> **Identity providers** -> **Add provider**.
2. Select **OpenID Connect**.
3. Enter the following details:
   * **Provider URL:** `https://token.actions.githubusercontent.com`
   * **Audience:** `sts.amazonaws.com`
4. Click **Add provider**.

---

### Step 2: Create an IAM Role
1. In IAM, go to **Roles** -> **Create role**.
2. Select **Web identity**.
3. Choose the Identity Provider (`token.actions.githubusercontent.com`) and Audience (`sts.amazonaws.com`).
4. Configure the **Trust Policy** (Trust Relationship) to restrict access to only your specific GitHub repository (and optionally branch or environment).

#### Example Trust Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG_OR_USERNAME>/<REPO_NAME>:*"
        }
      }
    }
  ]
}
```

---

### Step 3: Attach Permissions Policies
Attach the required IAM policies to this new Role according to your pipeline's needs (e.g., S3 read/write, ECR push/pull, ECS deploy, etc.). Follow the principle of least privilege.

---

## 2. GitHub Actions Workflow

Create or update your `.github/workflows/deploy.yml` or `workflow.yml`:

```yaml
name: AWS OIDC Test

on:
  push:
    branches: 
      - main

# Required permissions for OIDC authentication
permissions:
  id-token: write # Strictly required for requesting the JWT from GitHub
  contents: read  # Required for actions/checkout

jobs:
  oidc-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Configure AWS Credentials using OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          # Replace with your actual AWS IAM Role ARN
          role-to-assume: arn:aws:iam::111122223333:role/YourGithubActionsRole
          # Replace with your target AWS Region
          aws-region: us-east-1 
          
      - name: Test AWS Authentication
        run: |
          aws sts get-caller-identity
```

---

## 3. Key Concepts & Best Practices

1. **IAM Role vs. IAM User:** No long-lived AWS credentials stored as GitHub Secrets. If secrets leak, there are no permanent keys to revoke.
2. **Permissions Block:** `id-token: write` is mandatory. Without it, GitHub Actions cannot request the JWT token from the OIDC token minting endpoint.
3. **Workflow Syntax:** Ensure `on: push: branches:` indentation is correct and valid YAML.
4. **Verification Step:** Running `aws sts get-caller-identity` verifies that the workflow assumed the expected IAM role and account ID before running deployment commands.
