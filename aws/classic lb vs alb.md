# AWS Classic Load Balancer (CLB) vs Application Load Balancer (ALB)

A practical comparison between AWS Classic Load Balancer (v1 / legacy) and Application Load Balancer (v2 / Layer 7).

---

## 1. Classic Load Balancer (CLB)

* **Overview:** The legacy generation load balancer (operates at Layer 4 and basic Layer 7).
* **Routing Behavior:** Routes incoming requests to a **single application** across multiple EC2 instances.
* **Limitation:** Does **not** inspect URLs or HTTP request paths—it distributes all requests to the same application regardless of the requested path.

### Traffic Flow Diagram:
```text
                          ┌──► Server 1 (Same Application)
Incoming Request ──► CLB ─┼──► Server 2 (Same Application)
                          └──► Server 3 (Same Application)
```

---

## 2. Application Load Balancer (ALB)

* **Overview:** A modern, intelligent Layer 7 load balancer that acts like a smart router and security guard.
* **Routing Behavior:** Inspects request content (URL path, host header, query parameters, HTTP headers, source IP) and intelligently routes requests to **multiple distinct applications or microservices**.

### Path-Based Routing Example:

Consider the domain `example.com`:
* `example.com/products` ──► Forwarded to **Server 1 / Target Group 1** (Products Service)
* `example.com/orders`   ──► Forwarded to **Server 2 / Target Group 2** (Orders Service)

### Traffic Flow Diagram:
```text
                                  ┌──► /products ──► Server 1 (Products App)
Incoming Request ──► ALB (Rule) ──┤
                                  └──► /orders   ──► Server 2 (Orders App)
```

> [!IMPORTANT]
> Classic Load Balancer does **not** support path-based routing or multiple target groups. ALB is specifically designed for containerized workloads, microservices, and modern web architectures.

---

## 3. Feature Comparison

| Feature | Classic Load Balancer (CLB) | Application Load Balancer (ALB) |
| :--- | :--- | :--- |
| **OSI Layer** | Layer 4 (TCP/SSL) & basic Layer 7 (HTTP/HTTPS) | Layer 7 (HTTP/HTTPS/gRPC) |
| **Routing Capability** | Basic round-robin to a single application | Advanced routing (Path-based, Host-based, Query string, Headers) |
| **Target Types** | EC2 instances only (EC2-Classic & EC2-VPC) | EC2 instances, IP addresses, Lambda functions, Containers |
| **Multiple Target Groups** | ❌ No | ✅ Yes |
| **Path Routing (`/orders`, `/products`)**| ❌ No | ✅ Yes |
| **Host Routing (`app1.domain`, `app2.domain`)**| ❌ No | ✅ Yes |
| **HTTP/2 and gRPC Support** | ❌ No | ✅ Yes |
| **WebSockets Support** | ⚠️ Basic (via TCP listener) | ✅ Native support |
| **AWS WAF Integration** | ❌ No | ✅ Yes (Layer 7 web ACLs) |
| **Redirects & Custom Fixed Responses** | ❌ Requires web server logic | ✅ Native HTTP-to-HTTPS redirect & custom error pages |
| **Current AWS Status** | **Legacy / Deprecated** | **Current Generation / Recommended** |
