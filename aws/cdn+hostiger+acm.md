# AWS ACM + CloudFront + Hostinger DNS Complete Notes

A complete implementation and troubleshooting guide for setting up a custom CDN domain using CloudFront, S3, AWS Certificate Manager (ACM), and Hostinger DNS.

---

## Architecture Scenario

* **Primary Domain:** `xrdashboard.com` (Managed in Hostinger)
* **Custom CDN Domain:** `cdn.xrdashboard.com`
* **CDN:** AWS CloudFront
* **Origin:** Amazon S3 (Private Bucket)
* **SSL/TLS:** AWS Certificate Manager (ACM)

### High-Level Architecture:
```text
User
 │
 ▼
https://cdn.xrdashboard.com
 │
CloudFront
 │
Origin Access Control (OAC)
 │
Private S3 Bucket
```

---

## Step 1: Create CloudFront Distribution

Navigate to: **AWS Console** ➔ **CloudFront** ➔ **Create Distribution**

### 1. Origin Configuration
* **Origin Type:** Amazon S3
* **Origin Domain:** Select your private S3 bucket

### 2. Security (Origin Access Control)
* Use **Origin Access Control (OAC)** (Recommended)
* > [!WARNING]
  > Do **NOT** make the S3 bucket public. Always use OAC with a restrictive bucket policy.

### 3. Viewer Protocol Policy
* Select **Redirect HTTP to HTTPS**

### 4. Distribution Domain Name
Once created, CloudFront assigns a default distribution domain, for example:
```text
d2bjlkkw60g6rj.cloudfront.net
```

---

## Step 2: Request AWS ACM Certificate

> [!IMPORTANT]
> CloudFront requires SSL certificates to be created in the **US East (N. Virginia) `us-east-1`** region only. Even if your S3 bucket or users are located in another region, the certificate **must** reside in `us-east-1`.

1. Go to **AWS Certificate Manager (ACM)**.
2. Ensure the selected region in the top right is **US East (N. Virginia) `us-east-1`**.
3. Click **Request Certificate**.
4. Choose **Request a public certificate** ➔ **Next**.
5. **Fully qualified domain name:** `cdn.xrdashboard.com`
6. **Validation method:** **DNS Validation** (Recommended)
7. **Key algorithm:** **RSA 2048**
8. Click **Request**.

---

## Step 3: Retrieve ACM Validation Records

AWS ACM will generate a CNAME validation record:

* **Domain:** `cdn.xrdashboard.com`
* **CNAME Name:** `_805c3b232ffc231727ac3b3aacaa700a.cdn.xrdashboard.com`
* **CNAME Value:** `_37c079fdb5753a3fef8b06cd39030aee.jkddzztszm.acm-validations.aws`

> [!NOTE]
> Do not alter or modify these hash strings.

---

## Step 4: Configure Hostinger DNS

Open: **Hostinger** ➔ **Domains** ➔ `xrdashboard.com` ➔ **DNS / Nameservers (DNS Zone)**

You must create **two** CNAME records:

### Record 1: CDN Traffic Routing
Points your custom subdomain to CloudFront:

| Type | Name | Points To | TTL |
| :--- | :--- | :--- | :--- |
| **CNAME** | `cdn` | `d2bjlkkw60g6rj.cloudfront.net` | Default |

*Result:* `cdn.xrdashboard.com` routes to CloudFront.

---

### Record 2: ACM Validation Record
Validates ownership of the subdomain for AWS to issue the SSL certificate.

> [!CAUTION]
> Hostinger automatically appends your root domain (`.xrdashboard.com`) to the **Name** field. 
> Therefore, if AWS provides:
> `_805c3b232ffc231727ac3b3aacaa700a.cdn.xrdashboard.com`
> 
> Enter **only**:
> `_805c3b232ffc231727ac3b3aacaa700a.cdn`

| Type | Name | Points To | TTL |
| :--- | :--- | :--- | :--- |
| **CNAME** | `_805c3b232ffc231727ac3b3aacaa700a.cdn` | `_37c079fdb5753a3fef8b06cd39030aee.jkddzztszm.acm-validations.aws` | Default |

---

## Step 5: Resolving CAA Record Errors

### The Issue
If Hostinger already has Certificate Authority Authorization (CAA) records for other certificate authorities (such as Let's Encrypt, Sectigo, DigiCert, GlobalSign, Comodo, Google PKI):
```text
CAA issue letsencrypt.org
CAA issue sectigo.com
CAA issue digicert.com
CAA issue globalsign.com
CAA issue comodoca.com
CAA issue pki.goog
```
AWS ACM will **fail** to issue certificates and show:
```text
Certificate Authority Authorization (CAA) Error
```

### The Fix: Add AWS CAA Records
Add CAA records in Hostinger DNS that explicitly authorize Amazon Trust Services:

| Type | Name | Tag | Flag | Value |
| :--- | :--- | :--- | :--- | :--- |
| **CAA** | `@` | issue | 0 | `"amazon.com"` |
| **CAA** | `@` | issuewild | 0 | `"amazon.com"` |
| **CAA** | `@` | issue | 0 | `"amazontrust.com"` |
| **CAA** | `@` | issuewild | 0 | `"amazontrust.com"` |

Once DNS propagation completes, AWS ACM will be able to issue the certificate.

---

## Step 6: Verify DNS Propagation via CLI

### 1. Verify CAA Records:
```bash
nslookup -type=CAA xrdashboard.com 8.8.8.8
```

**Expected Output:**
```text
issue "amazon.com"
issuewild "amazon.com"
issue "amazontrust.com"
issuewild "amazontrust.com"
```

### 2. Verify ACM CNAME Record:
```bash
nslookup -type=CNAME _805c3b232ffc231727ac3b3aacaa700a.cdn.xrdashboard.com 8.8.8.8
```

**Expected Output:**
```text
canonical name = _37c079fdb5753a3fef8b06cd39030aee.jkddzztszm.acm-validations.aws
```

---

## Step 7: Wait for Certificate Issuance

Monitor certificate status in AWS ACM:
```text
Pending Validation  ──►  Issued
```

> [!WARNING]
> If the certificate status changes to **Failed**, do not attempt to reuse it. Delete the failed certificate, verify the DNS and CAA records, and request a **new** certificate.

---

## Step 8: Attach Certificate to CloudFront

1. Open **CloudFront** ➔ Select your distribution ➔ **General** ➔ **Settings** ➔ **Edit**.
2. **Alternate domain name (CNAME):** Add `cdn.xrdashboard.com`
3. **Custom SSL certificate:** Select your newly issued ACM certificate.
4. **Security policy:** Select TLSv1.2_2021 (Recommended).
5. Click **Save changes** and wait for CloudFront deployment status to complete.

---

## Step 9: Verification & Testing

Open in a browser or test via `curl`:
```bash
curl -I https://cdn.xrdashboard.com
```

Confirm that:
* HTTPS connection succeeds without SSL warnings.
* The SSL certificate displays Amazon as the issuer.
* Files and assets are served directly from CloudFront caches.

---

## Complete End-to-End Workflow

```text
Request ACM Certificate (us-east-1)
        │
        ▼
AWS Generates Validation CNAME
        │
        ▼
Add Validation CNAME in Hostinger DNS
        │
        ▼
Verify CAA Records Allow Amazon Trust Services
        │
        ▼
DNS Propagation & Validation
        │
        ▼
Certificate Status = Issued
        │
        ▼
Attach Custom SSL Certificate to CloudFront
        │
        ▼
Add Alternate Domain Name (cdn.xrdashboard.com)
        │
        ▼
CloudFront Distribution Deployed
        │
        ▼
https://cdn.xrdashboard.com Live & Secured
```
