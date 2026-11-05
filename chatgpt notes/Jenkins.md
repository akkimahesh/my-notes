# 🚀 Jenkins & CI/CD Real-Time DevOps Handbook

This guide transforms raw Jenkins concepts into **clear, simple English** paired with **real-world production scenarios** (based on standard enterprise and e-commerce microservices projects like RoboShop).

---

## 📑 Table of Contents
1. [Manual Approval Gates (`input` block)](#1-manual-approval-gates-input-block)
2. [Jenkins Agent Security (Non-Root User)](#2-jenkins-agent-security-non-root-user)
3. [Essential Pipeline Directives (`options`, `post`, `when`)](#3-essential-pipeline-directives-options-post-when)
4. [Parsing Configuration Files (`readJSON`)](#4-parsing-configuration-files-readjson)
5. [SCM Integration vs Manual Git Clone](#5-scm-integration-vs-manual-git-clone)
6. [Node.js & Dependency Management (`node_modules`)](#6-nodejs--dependency-management-node_modules)
7. [Database Schema Initialization](#7-database-schema-initialization)
8. [Nexus Repository Requirements](#8-nexus-repository-requirements)
9. [Running Terraform from a Jenkins Agent](#9-running-terraform-from-a-jenkins-agent)
10. [Packaging Artifacts Cleanly (`zip` command)](#10-packaging-artifacts-cleanly-zip-command)
11. [Artifact Versioning Strategy (Dev vs Prod)](#11-artifact-versioning-strategy-dev-vs-prod)
12. [Uploading Artifacts to Nexus](#12-uploading-artifacts-to-nexus)
13. [What is "Provisioning"?](#13-what-is-provisioning)
14. [Deployment Repository Architecture](#14-deployment-repository-architecture)
15. [Parent to Child Job Orchestration (CI ➔ CD)](#15-parent-to-child-job-orchestration-ci--cd)
16. [SonarQube Static Code Analysis](#16-sonarqube-static-code-analysis)
17. [Multibranch Pipelines](#17-multibranch-pipelines)
18. [Jenkins Shared Libraries](#18-jenkins-shared-libraries)
19. [Speeding Up Pipelines with Parallel Stages](#19-speeding-up-pipelines-with-parallel-stages)
20. [Understanding Groovy Files (`.groovy`)](#20-understanding-groovy-files-groovy)

---

## 1. Manual Approval Gates (`input` block)

### 💡 What is it?
The `input` directive pauses the pipeline execution and waits for a human team member to click "Approve" or "Abort" in the Jenkins UI.

```groovy
stage('Production Approval') {
    steps {
        input {
            message "All tests passed in QA. Do you want to deploy to Production?"
            ok "Yes, Deploy to Prod"
        }
    }
}
```

### 🏢 Real-Time Scenario
> **The Accidental Friday Deployment:**  
> A developer pushes a bugfix on Friday at 5:00 PM. Automated CI builds the code and runs unit tests successfully. Without an approval gate, Jenkins would immediately trigger a rollout to live customers. If a bug slips through, the site could go down over the weekend.  
> **How `input` solves it:** The pipeline stops before the `Deploy to Prod` stage. A DevOps Lead or Product Manager must inspect the QA sign-off and manually click **"Yes, Deploy to Prod"** during a scheduled maintenance window.

---

## 2. Jenkins Agent Security (Non-Root User)

### 💡 What is it?
Never run the Jenkins agent daemon or execute build commands as the Linux `root` (superuser) account. Always create a dedicated non-root user (e.g., `jenkins` or `ec2-user`).

### 🏢 Real-Time Scenario
> **Preventing Server Wipeouts:**  
> In a build script, a developer wrote:
> ```bash
> rm -rf $BUILD_DIR/*
> ```
> If the variable `$BUILD_DIR` happens to be empty due to a typo or bug, the command evaluates to:
> ```bash
> rm -rf /*
> ```
> If Jenkins is running as `root`, the command will completely delete the operating system files, crashing the agent server permanently.  
> If Jenkins runs as a regular user (e.g., `jenkins`), the OS refuses permission and blocks the destructive command, keeping the host server safe.

---

## 3. Essential Pipeline Directives (`options`, `post`, `when`)

### 3.1 Pipeline Timeout (`options`)
```groovy
pipeline {
    agent any
    options {
        timeout(time: 30, unit: 'MINUTES')
    }
    // stages...
}
```
* **Real-Time Scenario:** A database integration test gets stuck waiting for a response that never comes. Without a timeout, this build job hangs forever, hogging the Jenkins agent and blocking all other developers' builds. Setting a 30-minute timeout automatically aborts stuck jobs.

---

### 3.2 Cleaning Up Workspaces (`post { always { deleteDir() } }`)
```groovy
pipeline {
    agent any
    stages {
        // build steps...
    }
    post {
        always {
            deleteDir() // Deletes the entire workspace folder
        }
    }
}
```
* **Real-Time Scenario:** Building Node.js or Java projects downloads hundreds of megabytes of dependencies (`node_modules`, `.m2`, `.zip` files). If 50 builds run every day, the agent's disk fills up to 100% within a week (`No space left on device` error). `deleteDir()` ensures every build leaves behind a clean slate.

---

### 3.3 Conditional Execution (`when`)
```groovy
stage('Deploy to Prod') {
    when {
        branch 'main'
    }
    steps {
        echo "Deploying release to live production servers..."
    }
}
```
* **Real-Time Scenario:** Developers push code to feature branches (e.g., `feature/login-page`, `bugfix/cart`). We want to run tests on every branch, but deployment to production must **only** occur when changes are merged into the `main` branch.

---

## 4. Parsing Configuration Files (`readJSON`)

### 💡 What is it?
The **Pipeline Utility Steps** plugin provides the `readJSON` step, allowing Jenkins to read `.json` files and access properties dynamically inside your pipeline script.

```groovy
stage('Read App Version') {
    steps {
        script {
            def packageJson = readJSON file: 'package.json'
            def appVersion = packageJson.version
            echo "Current version being built: ${appVersion}"
        }
    }
}
```

### 🏢 Real-Time Scenario
> **Automated Release Tagging:**  
> In the RoboShop Catalogue service, developers update the version inside `package.json` (e.g., `"version": "1.2.0"`). Instead of asking developers to manually type `1.2.0` in Jenkins every build, Jenkins dynamically extracts the version from `package.json` and uses it to name the artifact (`catalogue-1.2.0.zip`).

---

## 5. SCM Integration vs Manual Git Clone

### 💡 What is it?
When creating a Jenkins Pipeline job, choose **Pipeline script from SCM** (Source Code Management) and provide the Git repository URL.

* ✅ **Pipeline from SCM:** Jenkins automatically clones the exact branch/commit into the workspace before executing the `Jenkinsfile`.
* ❌ **Anti-pattern:** Writing `sh 'git clone https://...'` manually inside pipeline steps.

### 🏢 Real-Time Scenario
> **Reproducible Builds:**  
> When a developer triggers a build for a specific commit, Jenkins automatically checks out that exact commit SHA. If you used a manual `git clone`, it would always clone the latest commit, making it impossible to debug or rebuild an older version.

---

## 6. Node.js & Dependency Management (`node_modules`)

### 💡 What is it?
`node_modules` is the directory created when you run:
```bash
npm install
```
It downloads all third-party libraries defined in `package.json` (such as Express, MongoDB client, etc.).

### 🏢 Real-Time Scenario
> **Application Startup Failure:**  
> When deploying the RoboShop Catalogue microservice (`server.js`), running `node server.js` will immediately crash with `Cannot find module 'express'` if `npm install` was not executed.  
> **In CI/CD:** We run `npm install` inside the build stage on Jenkins, package both the source code and `node_modules` (or install them during image build / server provisioning), ensuring the service has everything needed to run.

---

## 7. Database Schema Initialization

### 💡 What is it?
A **database schema** defines the structure of data (tables, columns, collections) and any initial master data.

### 🏢 Real-Time Scenario
> **Populating Product Inventory:**  
> When launching the RoboShop Catalogue service for the first time, MongoDB is completely empty. Customers visiting the website would see zero products.  
> The development team provides a schema file (e.g., `schema/catalogue.js`). During deployment, the CI/CD pipeline runs a script to load this file into MongoDB, populating categories, product names, prices, and stock counts.

---

## 8. Nexus Repository Requirements

### 💡 What is it?
Sonatype Nexus is an **Artifact Repository Manager** used to store packaged binaries (`.jar`, `.war`, `.zip`, Docker images).

* ⚠️ **Key Requirement:** Nexus is a Java application. **Java (JDK/JRE 8 or 11/17)** must be installed on the Nexus server, otherwise Nexus will not start.

### 🏢 Real-Time Scenario
> **Company Binary Storage:**  
> You do not want production servers downloading source code and compiling it. Instead, Jenkins builds the code once, packages it into `catalogue.zip`, and pushes it to Nexus. Production servers then pull the ready-to-run `.zip` directly from Nexus.

---

## 9. Running Terraform from a Jenkins Agent

### 💡 What is it?
If your Jenkins pipeline provisions AWS infrastructure using Terraform, the Jenkins **agent machine** must have:
1. The **Terraform CLI binary** installed and added to `$PATH`.
2. **AWS Credentials** configured (either via an AWS IAM Instance Role attached to the EC2 agent, or Jenkins AWS credentials injected as environment variables).

### 🏢 Real-Time Scenario
> **Automated Cloud Provisioning:**  
> A stage in your pipeline runs:
> ```bash
> terraform init
> terraform apply --auto-approve
> ```
> If Terraform is missing from the agent, the stage fails with `terraform: command not found`. If AWS credentials are missing, it fails with `No valid AWS credential sources found`.

---

## 10. Packaging Artifacts Cleanly (`zip` command)

### 💡 What is it?
When creating a deployment archive for a microservice:
```bash
zip -q -r catalogue.zip ./* -x ".git*" -x "*.zip"
```

### 🔍 Breakdown of Flags:
* `-q` (quiet): Suppresses verbose terminal output so Jenkins build logs stay readable.
* `-r` (recursive): Includes all subdirectories (like `node_modules/`).
* `catalogue.zip`: The target output file name.
* `./*`: Captures all files in the current workspace.
* `-x ".git*"`: Excludes Git history (which is large and not needed in production).
* `-x "*.zip"`: Excludes any existing `.zip` files.

### 🏢 Real-Time Scenario
> **The Nested Zip Bug:**  
> If you run a build without `-x "*.zip"`, and a previous build created `catalogue.zip`, the new command will pack `catalogue.zip` *inside* the new `catalogue.zip`. After 5 builds, you have a zip file containing 5 layers of zips, bloating the file from 20MB to 500MB and breaking deployment scripts!

---

## 11. Artifact Versioning Strategy (Dev vs Prod)

| Environment | Version Format | Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Development (DEV)** | `1.0.0-SNAPSHOT` | Overwriteable / Mutable | Allows continuous testing without bumping the version number on every small commit. |
| **Production (PROD)** | `1.0.0-release` | Read-only / Immutable | Permanent record of what is deployed to customers. Can never be overwritten. |

### 🏢 Real-Time Scenario
> **Rollback Assurance:**  
> If production build `1.0.0-release` develops an unexpected issue, the DevOps team can immediately roll back to `0.9.9-release` stored in Nexus. Because production releases are immutable, you are 100% guaranteed that `0.9.9-release` has not been tampered with or changed.

---

## 12. Uploading Artifacts to Nexus

### 💡 What is it?
Using the **Nexus Artifact Uploader** plugin in Jenkins to push compiled zip/tar packages to Nexus.

### 📋 Setup Steps:
1. Install **Nexus Artifact Uploader** plugin in Jenkins (`Manage Jenkins ➔ Plugins`).
2. Add Nexus credentials under `Manage Jenkins ➔ Credentials` (e.g., ID: `nexus-credentials`).
3. Add the upload step in your `Jenkinsfile`:

```groovy
stage('Upload to Nexus') {
    steps {
        nexusArtifactUploader(
            nexusVersion: 'nexus3',
            protocol: 'http',
            nexusUrl: 'nexus.mycompany.internal:8081',
            groupId: 'com.roboshop',
            version: "${BUILD_VERSION}",
            repository: 'catalogue',
            credentialsId: 'nexus-credentials',
            artifacts: [
                [artifactId: 'catalogue', classifier: '', file: 'catalogue.zip', type: 'zip']
            ]
        )
    }
}
```

### 🏢 Real-Time Scenario
> Once the artifact is uploaded, deployment scripts running on target servers (via Ansible or AWS UserData) simply download:
> `http://nexus.mycompany.internal:8081/repository/catalogue/com/roboshop/catalogue/1.0.0/catalogue-1.0.0.zip`

---

## 13. What is "Provisioning"?

### 💡 Definition:
**Provisioning** is the automated process of preparing a server to run an application. This includes:
* Installing required software (Node.js, Nginx, Python, Docker).
* Creating system users and permission groups.
* Configuring systemd service files.
* Setting up networking, firewalls, and storage mounts.

### 🏢 Real-Time Scenario
> Rather than having a system administrator manually log into 10 servers via SSH and type `apt-get install nodejs`, an automated tool (like Ansible or Terraform with UserData) provisions all 10 servers identically in minutes.

---

## 14. Deployment Repository Architecture

In enterprise DevOps, we keep the **Application Source Code** separate from the **Infrastructure / Deployment Code**.

```text
catalogue-deploy/
 ├── Jenkinsfile           # Deployment orchestration pipeline
 └── terraform/            # Infrastructure definition
      ├── main.tf
      ├── variables.tf
      └── outputs.tf
```

### 🏢 Real-Time Scenario
> Software engineers should write business logic in `catalogue/` without having permissions to modify AWS security groups or Terraform files. The DevOps team maintains `catalogue-deploy/`, which manages how and where the application is deployed.

---

## 15. Parent to Child Job Orchestration (CI ➔ CD)

### 💡 What is it?
Jenkins allows one pipeline (Parent / CI) to trigger another pipeline (Child / CD) and pass parameters dynamically.

```groovy
stage('Trigger Deployment') {
    steps {
        script {
            build job: 'catalogue-deploy-pipeline',
                  parameters: [
                      string(name: 'APP_VERSION', value: "${BUILD_VERSION}"),
                      string(name: 'ENVIRONMENT', value: 'dev')
                  ],
                  wait: true // Pauses parent until child completes
        }
    }
}
```

### 🏢 Real-Time Scenario
> **End-to-End Pipeline:**
> 1. Developer pushes code to `catalogue` repo.
> 2. **Parent Job (CI):** Runs unit tests, lints code, zips artifact, and uploads `catalogue-2.1.0.zip` to Nexus.
> 3. Upon success, Parent automatically triggers **Child Job (CD):** `catalogue-deploy-pipeline`, passing version `2.1.0` and environment `dev`.
> 4. The child job pulls `catalogue-2.1.0.zip` and deploys it to the Dev EC2 instances.

---

## 16. SonarQube Static Code Analysis

### 💡 What is it?
SonarQube inspects source code for security vulnerabilities, bugs, code smells, and test coverage before allowing code to be deployed.

```text
[Jenkins Agent: sonar-scanner] ➔ Sends metrics ➔ [SonarQube Server] ➔ Generates Quality Gate Report
```

### ⚙️ Agent Configuration (`sonar-scanner.properties`):
```properties
sonar.host.url=http://sonarqube.internal:9000
sonar.login=squ_9876543210abcdef_token
```

### 🏢 Real-Time Scenario
> **The Hardcoded Password Catch:**  
> A developer accidentally commits an AWS secret key or hardcoded database password into `server.js`. During the CI run, `sonar-scanner` scans the code, triggers a **Quality Gate Failure**, and Jenkins halts the pipeline, preventing the security leak from ever reaching production.

---

## 17. Multibranch Pipelines

### 💡 What is it?
A Jenkins job type that automatically discovers new Git branches, builds them using the `Jenkinsfile` present in each branch, and cleans up when the branch is deleted.

### 🏢 Real-Time Scenario
> In a team of 15 developers, each developer creates their own branch:
> * `feature/payment-gateway`
> * `feature/search-filter`
> * `bugfix/cart-calculation`
>
> You do **not** need to manually create 15 Jenkins jobs. Multibranch Pipeline automatically detects each branch, runs tests, and reports commit statuses back to GitHub/GitLab pull requests.

---

## 18. Jenkins Shared Libraries

### 💡 What is it?
A centralized Git repository of reusable Groovy scripts and pipeline steps shared across all projects.

### 🏢 Real-Time Scenario
> **10 Microservices, 1 Standard Pipeline:**  
> The RoboShop architecture has 10 services (Cart, Catalogue, User, Shipping, Payment, etc.). If all 10 services write their own 200-line `Jenkinsfile`, updating SonarQube configuration requires editing 10 separate repositories.  
> With a **Shared Library**, every repository has a clean 5-line `Jenkinsfile`:
> ```groovy
> @Library('my-shared-library') _
> microservicePipeline(
>     appName: 'catalogue',
>     appType: 'nodejs'
> )
> ```
> All common build, test, scan, and deploy logic lives in one shared repository.

---

## 19. Speeding Up Pipelines with Parallel Stages

### 💡 What is it?
Executing independent stages simultaneously rather than sequentially.

```groovy
stage('Quality Checks') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'npm test'
            }
        }
        stage('SonarQube Scan') {
            steps {
                sh 'sonar-scanner'
            }
        }
        stage('Security Vulnerability Scan') {
            steps {
                sh 'npm audit'
            }
        }
    }
}
```

### 🏢 Real-Time Scenario
> If Unit Tests take 4 minutes, SonarQube takes 3 minutes, and Security scanning takes 3 minutes:
> * **Sequential Run:** $4 + 3 + 3 = 10 \text{ minutes}$
> * **Parallel Run:** $\max(4, 3, 3) = \mathbf{4 \text{ minutes}}$
> This saves developers 6 minutes per build, significantly speeding up pull request feedback.

---

## 20. Understanding Groovy Files (`.groovy`)

### 💡 What is it?
Groovy is an object-oriented scripting language that runs on the Java Virtual Machine (JVM). Jenkins pipelines are written in Groovy syntax.

### 🏢 Comparison to Other DevOps Tools:
| Tool | Configuration File | Purpose |
| :--- | :--- | :--- |
| **Jenkins** | `vars/*.groovy` | Reusable pipeline functions, shared variables, custom steps |
| **Terraform** | `variables.tf` | Infrastructure input parameters and state definitions |
| **Ansible** | `vars/main.yaml` | Configuration values, package lists, credentials |

### 🏢 Real-Time Scenario
> Instead of hardcoding environment URLs directly in your `Jenkinsfile`, you create a `GlobalVars.groovy` file:
> ```groovy
> class GlobalVars {
>     static String DEV_NEXUS_URL = "http://nexus.dev.internal:8081"
>     static String PROD_NEXUS_URL = "http://nexus.prod.internal:8081"
> }
> ```
> If the Nexus server IP changes, you only update it in one central file.

---

## 🎯 Summary Checklist for Production Pipelines
- [x] Run agents as a restricted **non-root user**.
- [x] Always clean up workspace with `post { always { deleteDir() } }`.
- [x] Set reasonable **timeouts** to prevent hanging builds.
- [x] Run unit tests and static scans in **parallel**.
- [x] Protect production rollouts with a manual **`input` approval gate**.
- [x] Tag artifacts with **immutable release versions** in Nexus.
- [x] Centralize repetitive pipeline logic using **Jenkins Shared Libraries**.
