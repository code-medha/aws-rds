What problem does a Load Balancer solve? 

Imagine this without a load balancer:

Your frontend calls one EC2 / ECS task IP

That instance:

Can go down

Can get overloaded

Changes IP when redeployed (ECS/Fargate)

Result:
Downtime
Manual traffic management
No scalability

A load balancer sits in front and solves this.


What is AWS ALB?

AWS Application Load Balancer is a Layer 7 (HTTP/HTTPS) load balancer.

It understands:

URLs (/api, /login)

HTTP methods (GET, POST)

Headers, hostnames

## Compoenents of ALB

- Listener
- Listener Rules
- Target Group
- Targets


1️Listener – “How traffic enters ALB”
What is a Listener?

A listener defines:

Protocol: HTTP / HTTPS

Port: 80 / 443

Example:

HTTP : 80

HTTPS : 443 (with TLS certificate)

Without a listener:
ALB cannot accept traffic at all.

Problem it solves

Separates traffic entry from backend logic

Enables HTTPS termination (TLS handled at ALB)


Listener Rules – “Where traffic should go”

Listeners have rules.

A rule says:

“If traffic matches X → send to Y”

Common rule conditions

Path-based routing
/api/* → backend

Host-based routing
api.example.com → backend

Header-based routing

Problem it solves

One ALB → multiple services

No need for separate load balancers per service

This is huge for microservices.


Target Group – “Who receives traffic”
What is a Target Group?

A target group is a logical group of backends.

Targets can be:

EC2 instances

ECS tasks (IP mode)

Lambda functions

Each target group has:

Port (e.g., 5000)

Protocol (HTTP)

Health check path (/health)

ALB never talks directly to EC2/ECS
It always talks via target groups


Targets – “Actual application instances”

Targets are:

Your ECS tasks

Your EC2 instances

Your containers

ALB:

Distributes traffic across all healthy targets

Automatically adjusts when tasks scale up/down

ECS example (your use case)

When ECS scales:

New task → auto-registered to target group

Stopped task → auto-removed

No manual IP handling 

Cost of AWS Application Load Balancer (ALB)

AWS Application Load Balancer pricing has two main components.

Fixed hourly cost (ALB running time)

You pay per hour the ALB exists (even if no traffic).

Typical pricing (approx):

~$0.0225 per hour per ALB

If your ALB runs all month:

0.0225 × 24 × 30 ≈ $16–17 / month

LCU (Load Balancer Capacity Units)

This is where most confusion happens.

ALB pricing is usage-based, measured in LCUs.

An LCU is calculated based on the maximum of these (per hour):

Dimension	What it measures
New connections	How many new TCP connections/sec
Active connections	Concurrent connections
Processed bytes	GBs of data processed
Rule evaluations	Listener rules checked
