# 🐳 Docker & Containerization Real-Time DevOps Handbook

This guide transforms raw Docker concepts and commands into **simple, practical English** backed by **real-time production scenarios** (using microservices like the RoboShop project as practical examples).

---

## 📑 Table of Contents
1. [The Real Problem Docker Solves](#1-the-real-problem-docker-solves)
2. [Running Containers: Foreground vs Detached vs Port Mapping](#2-running-containers-foreground-vs-detached-vs-port-mapping)
3. [Essential Inspection & Troubleshooting Commands](#3-essential-inspection--troubleshooting-commands)
4. [Dockerfile Instructions Explained in Order](#4-dockerfile-instructions-explained-in-order)
5. [The Core Distinction: `RUN` vs `CMD` vs `ENTRYPOINT`](#5-the-core-distinction-run-vs-cmd-vs-entrypoint)
6. [`COPY` vs `ADD`](#6-copy-vs-add)
7. [`ARG` (Build Time) vs `ENV` (Runtime)](#7-arg-build-time-vs-env-runtime)
8. [Docker Networking: Default Bridge vs Custom Bridge](#8-docker-networking-default-bridge-vs-custom-bridge)
9. [Multi-Container Orchestration with Docker Compose](#9-multi-container-orchestration-with-docker-compose)
10. [Data Persistence: Named Volumes vs Bind Mounts](#10-data-persistence-named-volumes-vs-bind-mounts)
11. [Multi-Stage Builds: Slashing Image Size (1.2 GB ➔ 180 MB)](#11-multi-stage-builds-slashing-image-size-12-gb--180-mb)
12. [Layer Caching & Dockerfile Optimization](#12-layer-caching--dockerfile-optimization)
13. [Production Docker Security Checklist](#13-production-docker-security-checklist)

---

## 1. The Real Problem Docker Solves

### 💡 The Classic Dilemma:
> *"It worked fine on my local laptop and in QA, but it crashed the moment we deployed to Production!"*

* **The Cause:** 
  * QA environment had Ubuntu with Node.js 18 and specific OpenSSL libraries.
  * Production server was running Red Hat Enterprise Linux (RHEL) with Node.js 16.
  * The difference in OS libraries or runtime versions breaks the application.

### 🛡️ How Docker Solves It:
Docker packages:
1. The **exact Operating System filesystem** (e.g., Alpine Linux or Ubuntu base).
2. The **exact runtime and binaries** (e.g., Node.js v18.16.0, Python 3.11).
3. The **application code and all its dependencies** (`node_modules/`, packages).
4. The **system configuration and environment variables**.

**Result:** The container running in Production is 100% identical byte-for-byte to the container tested in QA.

---

## 2. Running Containers: Foreground vs Detached vs Port Mapping

### ⚙️ Command Comparison:
```bash
# 1. Foreground mode (attached to terminal)
docker run nginx

# 2. Detached mode (runs in background)
docker run -d nginx

# 3. Detached mode with Port Mapping
docker run -d -p 8080:80 --name my-web-server nginx
```

### 🔍 Understanding Port Mapping (`-p 8080:80`):
* `8080` = **Host Port** (the port opened on your physical computer or AWS EC2 server).
* `80` = **Container Port** (the internal port Nginx listens to inside its isolated container).

```text
[User Web Browser] 
       │  (Requests http://<Server-Public-IP>:8080)
       ▼
[Host Machine Port 8080]
       │  (Docker Port Forwarding)
       ▼
[Container Port 80] ➔ [Nginx Service inside container]
```

### 🏢 Real-Time Scenario
> **Hosting a Web App on AWS:**  
> You deploy an Nginx web server on an AWS EC2 instance.  
> * If you run `docker run nginx`, the server starts, but as soon as your SSH connection drops or you press `Ctrl + C`, the web server dies immediately.  
> * If you run `docker run -d nginx`, the container runs in the background, but nobody from the internet can access it because the container has an isolated private IP address.  
> * Running `docker run -d -p 8080:80 nginx` ensures the container stays running permanently in the background and maps incoming user traffic from EC2 port `8080` directly to Nginx inside the container.

---

## 3. Essential Inspection & Troubleshooting Commands

When a container fails or behaves unexpectedly in production, use these commands to diagnose:

### 3.1 Check the OS Inside a Running Container
```bash
docker exec -it <container_name_or_id> cat /etc/*release
```
* **Real-Time Scenario:** You inherited an old container image without documentation. You need to know whether to use `apt-get`, `yum`, or `apk` to install a debugging tool.

---

### 3.2 Open an Interactive Shell Inside the Container
```bash
docker exec -it <container_name_or_id> bash
# If bash is not installed (e.g., Alpine Linux):
docker exec -it <container_name_or_id> sh
```
* **Real-Time Scenario:** The RoboShop Catalogue service cannot connect to the database. You jump directly inside the running container using `docker exec -it catalogue bash` and run `curl http://mongodb:27017` to test network connectivity.

---

### 3.3 Deep Inspection of Container Configuration
```bash
docker inspect <container_name_or_id>
```
* **Real-Time Scenario:** You want to find out the container's exact IP address, mounted volume paths, CPU limits, or health check status without logging into the container.

---

## 4. Dockerfile Instructions Explained in Order

A `Dockerfile` is an automated recipe for building container images. Here is the standard production sequence:

```dockerfile
# 1. Base Image: The starting OS/runtime foundation
FROM node:18-alpine

# 2. Build-Time Argument: Only available while running 'docker build'
ARG APP_VERSION=1.0.0

# 3. Metadata: Information about author/service
LABEL maintainer="devops-team@company.com" service="catalogue"

# 4. Runtime Environment Variable: Persists inside the running container
ENV NODE_ENV=production \
    APP_PORT=8080

# 5. Working Directory: Sets the folder for subsequent commands
WORKDIR /app

# 6. Copy files: Transfer code from host into container
COPY package.json server.js /app/

# 7. Run commands: Install dependencies during build time
RUN npm install --only=production

# 8. Security: Switch away from root user before starting app
USER node

# 9. Documentation: Notes which port the app intends to use
EXPOSE 8080

# 10. Process execution: The main application startup command
CMD ["node", "server.js"]
```

---

## 5. The Core Distinction: `RUN` vs `CMD` vs `ENTRYPOINT`

| Instruction | Execution Time | Can Be Overridden at `docker run`? | Primary Purpose |
| :--- | :--- | :--- | :--- |
| **`RUN`** | **Build Time** (when creating image) | **No** (creates a permanent cached image layer) | Install packages, compile code, create directories (e.g., `npm install`, `yum install nginx`). |
| **`CMD`** | **Runtime** (when container boots) | **Yes** (any arguments passed to `docker run` replace `CMD`) | Provides default command or default arguments for the container. |
| **`ENTRYPOINT`** | **Runtime** (when container boots) | **No** (arguments passed to `docker run` get appended) | Defines the fixed main executable binary that this container represents. |

### 🏢 Real-Time Scenario: Building a Diagnostic Utility Image
Consider a troubleshooting container:
```dockerfile
ENTRYPOINT ["ping"]
CMD ["google.com"]
```

1. **Default execution:**
   ```bash
   docker run my-ping-tool
   # Executes: ping google.com
   ```

2. **Custom target passed by engineer:**
   ```bash
   docker run my-ping-tool yahoo.com
   # Executes: ping yahoo.com (CMD "google.com" is overridden by "yahoo.com", but "ping" remains fixed)
   ```

---

## 6. `COPY` vs `ADD`

| Feature | `COPY` | `ADD` |
| :--- | :--- | :--- |
| Copy local files/folders into container | ✅ Yes (`COPY app.py /app/`) | ✅ Yes |
| Download files from remote URLs | ❌ No | ✅ Yes (`ADD https://.../package.tar.gz /tmp/`) |
| Automatically extract compressed tar archives (`.tar.gz`) | ❌ No (copies file as a tar) | ✅ Yes (extracts contents automatically into destination) |
| **Production Recommendation** | **Use `COPY` for 99% of tasks** (clear, transparent, predictable) | Use only when automatic `.tar` extraction is specifically desired |

### 🏢 Real-Time Scenario
> When packaging the RoboShop Catalogue application, always use `COPY . /app`.  
> If you used `ADD`, and your folder happened to have a `.tar.gz` backup file, `ADD` would automatically unpack it, unexpectedly modifying your application files.

---

## 7. `ARG` (Build Time) vs `ENV` (Runtime)

```text
[docker build --build-arg APP_ENV=dev]
       │
       ▼
  ARG APP_ENV  ────► [Used only during image creation] ────► Disappears after image is built!
       │
       ▼ (Can be passed into ENV)
  ENV ENVIRONMENT=${APP_ENV} ────► [Baked into Image] ────► Available inside running container!
```

### ⚙️ Example:
```dockerfile
# Build-time variable (e.g. choose software version)
ARG VERSION=1.0.0

# Make it accessible at runtime by assigning to ENV
ENV APP_VERSION=${VERSION}
ENV MONGO_URL="mongodb://mongo.internal:27017/catalogue"
```

### 🏢 Real-Time Scenario
> **Different Database Connections per Environment:**  
> You build one single container image for the Catalogue service.  
> In QA, you start it with:  
> `docker run -e MONGO_URL="mongodb://qa-db:27017/catalogue" catalogue:v1`  
> In Production, you start it with:  
> `docker run -e MONGO_URL="mongodb://prod-db:27017/catalogue" catalogue:v1`  
> Because `MONGO_URL` is an `ENV`, you do not need to rebuild the container image for each environment!

---

## 8. Docker Networking: Default Bridge vs Custom Bridge

### ❌ Default Bridge Network (`docker0`)
```bash
docker run --name db mongodb
docker run --name app catalogue
```
* On the default network, containers **cannot** communicate using container names.
* `app` trying to connect to `mongodb://db:27017` will fail with DNS lookup errors. You are forced to look up and hardcode dynamic container IP addresses (which change every restart).

---

### ✅ Custom User-Defined Bridge Network
```bash
# 1. Create a custom network
docker network create roboshop-net

# 2. Attach containers to the network
docker run -d --name mongodb --network roboshop-net mongo
docker run -d --name catalogue --network roboshop-net -e MONGO_URL="mongodb://mongodb:27017/catalogue" catalogue:v1
```
* **Built-in Docker DNS:** Containers on the same custom network can resolve each other directly by container name (`mongodb`, `catalogue`, `cart`).

### 🏢 Real-Time Scenario
> In the RoboShop architecture, the Catalogue service needs to fetch products from MongoDB. By placing both containers on `roboshop-net`, Catalogue connects to `mongodb://mongodb:27017`. If MongoDB restarts and gets a new private IP, Docker's embedded DNS server automatically updates the mapping, preventing any service downtime.

---

## 9. Multi-Container Orchestration with Docker Compose

Running 10 separate `docker run` commands with dozens of arguments is slow and error-prone. **Docker Compose** lets you define the entire application stack in a single `docker-compose.yaml` file.

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:5.0
    container_name: mongodb
    restart: always
    networks:
      - roboshop
    volumes:
      - mongo_data:/data/db

  catalogue:
    image: roboshop/catalogue:v1.0
    container_name: catalogue
    restart: always
    ports:
      - "8080:8080"
    environment:
      - MONGO_URL=mongodb://mongodb:27017/catalogue
    networks:
      - roboshop
    depends_on:
      - mongodb

networks:
  roboshop:
    driver: bridge

volumes:
  mongo_data:
```

### 🚀 Management Commands:
```bash
# Start all microservices in the background:
docker compose up -d

# Stop and remove all containers and networks:
docker compose down

# View aggregated logs for all services:
docker compose logs -f
```

### 🏢 Real-Time Scenario
> **Onboarding New Developers in 60 Seconds:**  
> When a new software engineer joins the team, they don't need to spend 2 days installing MongoDB, Redis, RabbitMQ, and Node.js on their machine. They simply clone the repository and run `docker compose up -d`. The entire 10-service e-commerce store boots up and is ready for development within 1 minute.

---

## 10. Data Persistence: Named Volumes vs Bind Mounts

Containers are **ephemeral** (temporary). If you delete or recreate a container, all files saved inside it are permanently wiped out.

```text
Host File System
  ├── Bind Mount:   Direct link to any specific folder (e.g. /home/user/project ➔ /app)
  └── Named Volume: Managed by Docker daemon in (/var/lib/docker/volumes/<vol-name>/_data)
```

| Type | Syntax | Best Used For |
| :--- | :--- | :--- |
| **Named Volume** (Managed by Docker) | `docker run -v mongo_data:/data/db mongo` | Production databases, persistent logs, stateful services. |
| **Bind Mount** (Host Folder) | `docker run -v /Users/dev/code:/app nginx` | Local development (code changes on host reflect inside container instantly without rebuilding). |

### 🏢 Real-Time Scenario
> **The Database Upgrade Crisis:**  
> You need to upgrade MongoDB from version 4.4 to 5.0.  
> * Without a volume: Deleting the MongoDB 4.4 container deletes all product inventories, customer accounts, and order history!  
> * With a Named Volume (`mongo_data:/data/db`): You can safely stop and delete the old container, start the new MongoDB 5.0 container pointing to the same `mongo_data` volume, and all customer data remains completely intact.

---

## 11. Multi-Stage Builds: Slashing Image Size (1.2 GB ➔ 180 MB)

### ❌ The Traditional (Heavy) Problem:
Compiling Java, Go, or TypeScript requires massive SDKs, build tools (Maven, Gradle, Webpack), and temporary caches. If you ship all these tools in your production image:
* The image size balloons to **1.2 GB+**.
* Builds take forever to upload/download over network connections.
* Compilers left on production servers represent serious security vulnerabilities.

---

### ✅ The Multi-Stage Solution:
Use one stage to compile the code, and copy **only the final executable binary** into a tiny, secure runtime image.

```dockerfile
# ─── STAGE 1: Build the Java application ───
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
# Compiles code and generates target/shipping.jar
RUN mvn clean package -DskipTests

# ─── STAGE 2: Lightweight Production Runtime ───
FROM openjdk:11-jre-alpine
WORKDIR /app
# Copy ONLY the compiled .jar from Stage 1 (Builder)
COPY --from=builder /build/target/shipping.jar app.jar
USER nobody
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### 🏢 Real-Time Scenario
> In the RoboShop `shipping` microservice (built in Java):
> * Single-stage image size: **~1.2 GB** (contains Maven, JDK, source files, cache).
> * Multi-stage image size: **~180 MB** (contains only Alpine Linux, slim JRE, and `shipping.jar`).
> **Benefits:** Deployments to 20 AWS EC2 instances take 15 seconds instead of 5 minutes, and AWS container registry storage bills drop by 85%.

---

## 12. Layer Caching & Dockerfile Optimization

Docker builds images layer by layer. If an instruction has not changed, Docker reuses the cached layer, saving enormous amounts of build time.

### ❌ Bad Practice (No Caching + Bloated Layers):
```dockerfile
FROM node:18
WORKDIR /app
# Copying everything first invalidates the cache on every small code change!
COPY . .
RUN npm install
```
* **Problem:** If a developer edits a single line in `README.md`, Docker invalidates the cache for `COPY . .` and re-runs `npm install`, redownloading all dependencies for 4 minutes!

---

### ✅ Production Best Practice:
```dockerfile
FROM node:18-alpine
WORKDIR /app

# 1. Copy only dependency manifest first
COPY package.json package-lock.json ./

# 2. Install dependencies (cached unless package.json actually changed)
RUN npm install --only=production

# 3. Copy application source code last
COPY . .

# 4. Chain Linux commands to minimize intermediate layers
RUN chown -R node:node /app
```
* **Result:** Since `package.json` rarely changes, `npm install` is cached. Code changes build in **less than 2 seconds**!

---

## 13. Production Docker Security Checklist

Before pushing any image to Amazon ECR or Docker Hub:

1. **Never run as root:** Always declare a non-root user (`USER node` or `USER appuser`) before the `CMD` / `ENTRYPOINT` directive.
2. **Use minimal base images:** Prefer `alpine` or `distroless` images (fewer installed binaries means a dramatically smaller attack surface for hackers).
3. **Never hardcode secrets:** Never store API keys, passwords, or AWS tokens in `Dockerfile` or `ENV` instructions. Pass them securely at runtime using Docker Secrets, AWS Secrets Manager, or `.env` files added to `.gitignore`.
4. **Always pin image versions:** Avoid `FROM node:latest`. Use specific tags like `FROM node:18.16.0-alpine` to prevent unexpected breaking upstream updates.
5. **Add a `.dockerignore` file:** Exclude `.git`, `.env`, `node_modules`, and local logs from being copied into the container during `COPY . .`.

---

## 🎯 Summary Cheatsheet
| Task | Command |
| :--- | :--- |
| **Run in background with port mapping** | `docker run -d -p 8080:80 --name web nginx` |
| **Live shell into container** | `docker exec -it <container_name> sh` |
| **Inspect IP & mounted volumes** | `docker inspect <container_name>` |
| **Create custom network** | `docker network create <network_name>` |
| **Create persistent volume** | `docker volume create <volume_name>` |
| **Start full stack with Compose** | `docker compose up -d` |
| **Stop full stack** | `docker compose down` |
| **Prune unused containers & images** | `docker system prune -f` |
