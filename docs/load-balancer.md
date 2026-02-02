## What Problem Does a Load Balancer Solve?

Imagine your frontend calls a single EC2 instance or ECS task by its IP. Without a load balancer, that setup causes real issues.

That instance can go down, get overloaded, or change its IP when you redeploy (especially with ECS/Fargate). The result is downtime, manual traffic management, and no real scalability.

A load balancer sits in front of your instances and addresses this. It distributes traffic, handles failover, and lets you scale without tying clients to a single IP.

---

## What Is AWS ALB?

AWS Application Load Balancer (ALB) is a Layer 7 load balancer for HTTP and HTTPS. It understands URLs (e.g. `/api`, `/login`), HTTP methods (GET, POST), headers, and hostnames, so you can route traffic by path, host, or other request attributes.

---

## Components of ALB

ALB is built from four main pieces:

- **Listener** – how traffic enters the ALB
- **Listener Rules** – where that traffic is sent
- **Target Group** – which backends receive the traffic
- **Targets** – the actual application instances (ECS tasks, EC2, etc.)

---

## Listener – How Traffic Enters the ALB

A listener defines the protocol (HTTP or HTTPS) and port (e.g. 80 or 443) on which the ALB accepts traffic. Without at least one listener, the ALB cannot accept traffic at all.

**Example:**

- HTTP on port 80
- HTTPS on port 443 (with a TLS certificate for termination at the ALB)

This separates “how traffic arrives” from “which backend handles it” and lets you do TLS termination at the ALB instead of on every backend.

---

## Listener Rules – Where Traffic Should Go

Listeners have rules. Each rule says: *if the request matches condition X, send it to target group Y.*

Common conditions include:

- **Path-based routing** – e.g. `/api/*` → backend API target group
- **Host-based routing** – e.g. `api.example.com` → backend
- **Header-based routing** – match on specific headers

One ALB can therefore serve many services (e.g. frontend, API, admin) without a separate load balancer per service, which is very useful for microservices.

---

## Target Group – Who Receives the Traffic

A target group is a logical group of backends. Targets in a group can be EC2 instances, ECS tasks (in IP mode), or Lambda functions.

Each target group has:

- A **port** (e.g. 5000)
- A **protocol** (e.g. HTTP)
- A **health check path** (e.g. `/health`)

The ALB never talks directly to an EC2 instance or ECS task; it always sends traffic through a target group, which keeps routing and health checks consistent.

---

## Targets – The Actual Application Instances

Targets are your real workloads: ECS tasks, EC2 instances, or containers. The ALB distributes traffic across all healthy targets in the target group and adjusts automatically when you scale up or down.

**ECS example (your use case):**

When ECS scales:

- New tasks are automatically registered to the target group.
- Stopped tasks are automatically removed.

You don’t have to manage IPs or registration manually.

---

## Cost of AWS Application Load Balancer (ALB)

ALB pricing has two main parts.

### Fixed hourly cost

You pay for each hour the ALB exists, even if there is no traffic. Approximate typical pricing is around **$0.0225 per hour** per ALB. If the ALB runs all month:

`0.0225 × 24 × 30 ≈ $16–17 / month`

### LCU (Load Balancer Capacity Units)

Most of the variable cost comes from LCUs. ALB usage is measured in LCUs; your bill is based on the highest of these dimensions (per hour):

| Dimension            | What it measures              |
|----------------------|-------------------------------|
| New connections      | New TCP connections per second|
| Active connections   | Concurrent connections        |
| Processed bytes      | Volume of data processed (GB) |
| Rule evaluations     | Listener rules evaluated     |

An LCU is calculated from the maximum of these dimensions in that hour, which is where most of the pricing confusion comes from.
