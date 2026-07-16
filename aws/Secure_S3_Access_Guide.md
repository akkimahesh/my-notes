# Secure S3 Access for Clients Using IAM User (AWS SDK/CLI)

This is the standard approach used by most companies. Here's how to
implement it securely.

## Step 1: Create an S3 Bucket

For example:

``` text
Bucket Name: client-documents-storage
Region: ap-south-1
```

Suppose the client should only access:

``` text
client-documents-storage/project1/
```

------------------------------------------------------------------------

## Step 2: Create an IAM Policy

Go to:

**AWS Console → IAM → Policies → Create Policy → JSON**

Paste this policy (replace bucket name and folder):

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListProjectFolder",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::client-documents-storage",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "project1/*"
          ]
        }
      }
    },
    {
      "Sid": "ProjectFolderAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::client-documents-storage/project1/*"
    }
  ]
}
```

Save it as:

``` text
Project1S3Access
```

------------------------------------------------------------------------

## Step 3: Create an IAM User

Go to:

``` text
IAM → Users → Create User
```

Example:

``` text
Username:
project1-user
```

Do **not** enable console access unless they need the AWS Management
Console.

------------------------------------------------------------------------

## Step 4: Attach the Policy

Choose:

``` text
Attach policies directly
```

Select:

``` text
Project1S3Access
```

Finish creating the user.

------------------------------------------------------------------------

## Step 5: Create Access Keys

Open the IAM user.

Go to:

``` text
Security credentials
```

Click:

``` text
Create access key
```

Choose:

``` text
Application running outside AWS
```

AWS generates:

``` text
Access Key ID:
AKIA...................

Secret Access Key:
********************************
```

**Download the CSV or copy the secret immediately**, because AWS won't
show it again.

------------------------------------------------------------------------

## Step 6: Share These Details with the Client

``` text
Bucket Name:
client-documents-storage

Region:
ap-south-1

Folder:
project1/

Access Key ID:
AKIA....

Secret Access Key:
xxxxxxxxxxxxxxxx
```

------------------------------------------------------------------------

## Step 7: Client Configuration

### AWS CLI

``` bash
aws configure
```

Enter:

``` text
AWS Access Key ID:
AKIA...

AWS Secret Access Key:
xxxxxxxx

Region:
ap-south-1

Output:
json
```

Test:

``` bash
aws s3 ls s3://client-documents-storage/project1/
```

Upload:

``` bash
aws s3 cp file.pdf s3://client-documents-storage/project1/
```

Download:

``` bash
aws s3 cp s3://client-documents-storage/project1/file.pdf .
```

### Using an SDK (Python)

``` bash
pip install boto3
```

``` python
import boto3

s3 = boto3.client(
    "s3",
    aws_access_key_id="AKIA...",
    aws_secret_access_key="SECRET...",
    region_name="ap-south-1"
)

s3.upload_file(
    "sample.pdf",
    "client-documents-storage",
    "project1/sample.pdf"
)
```

------------------------------------------------------------------------

## Security Best Practices

-   Never share your own administrator IAM credentials.
-   Create a separate IAM user for each client or application.
-   Restrict access to a specific bucket or folder.
-   Rotate access keys periodically.
-   Use pre-signed URLs instead of credentials when possible.

This setup gives the client only the permissions they need while
protecting the rest of your AWS account.
