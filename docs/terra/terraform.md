## Deploying RDS PostgreSQL Instance Using Terraform

After testing PostgreSQL locally using a Docker image, it's time to deploy it on AWS. AWS provides PostgreSQL through RDS (Relational Database Service), which allows you to provision databases of your choice.

While you can provision an AWS RDS PostgreSQL instance using the AWS CLI or the AWS Management Console, I chose to use Terraform as a great learning opportunity. Using Terraform, I will provision the following resources:

- RDS PostgreSQL instance
- Custom VPC with public subnets

You might be wondering why create a custom VPC when AWS already provides a default VPC in each region? While the default VPC works for quick deployments, I chose to create a custom VPC because in real-world scenarios, organizations rarely use the default VPC, so learning to build custom VPCs prepares me for production environments where custom networking is standard practice.

> **Important Notice**
>
> In this project, the RDS instance is deployed in **public subnets** and can be reachable from the internet (tightly restricted by a security group that only allows my current IP). This setup is **intentional for testing/demo purposes**, so I can easily connect with tools like `psql` or a GUI client from my laptop.
>
> For **production-grade** workloads, the recommended best practice is:
>
> - Place RDS in **private subnets** (no direct internet route).
> - Access RDS via:
>   - An **application** running in the same VPC (ECS, EKS, EC2, Lambda),
>   - Or through **bastion hosts**, **VPN**, or **AWS Client VPN**,  
>   - Or via **AWS Systems Manager Session Manager / port forwarding**.
> - Restrict security groups to **only allow traffic from application/security groups**, not from arbitrary IPs.


---

## Terraform Folder Structure

First let me provide the folder structure I followed. At a high level, the Terraform layout looks like this:

```text
terraform/
├── main.tf            # Root modules (vpc, rds)
├── variables.tf       # Root input variables for the whole project
├── locals.tf          # Root locals; constructs name_prefix, etc.
├── modules/
│   ├── vpc/
│   │   ├── main.tf       # VPC + subnets + routing
│   │   └── variables.tf  # Inputs needed by the VPC module
│   │   └── outputs.tf    # Outputs needed for the RDS module
│   └── rds/
│       ├── main.tf       # RDS instance + SG + data sources
│       └── variables.tf  # Inputs needed by the RDS module
```

> Why module-based?

From the Terraform folder structure, you can see that I haved used module based structure because of the following reasons:

- **Reusability**: I can reuse the `vpc` or `rds` module in other projects/environments.
- **Separation of concerns**: VPC logic is isolated from RDS logic.
- **Cleaner root**: Root `main.tf` just connects pieces instead of containing all resources.

---

## Root Variables (`terraform/variables.tf`)

These are the inputs to the **entire** Terraform configuration.

**Examples – project & environment:**

```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cruddur"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

**VPC-related variables:**

```hcl
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "map of public subnets"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.0.0/24"
    "us-east-1b" = "10.0.1.0/24"
  }
}
```

**RDS-related variables** (identifier, instance class, engine, etc.) also live here and are passed into the RDS module.


> Why are we passing th variables from root? why not pass the variables directly from respective modules folder?

Module variables cannot directly read `terraform.tfvars` files. The `.tfvars` files only assign values to root module variables. You must pass those values (or derived locals) into modules via the module block.

---

## Root Locals (`terraform/locals.tf`)

`locals` are *computed* values based on variables. They are not passed in from outside; they are built from existing data.

```hcl
locals {
  project     = var.project_name
  environment = var.environment

  name_prefix = "${var.project_name}-${var.environment}"
}
```

- **`project`** and **`environment`** are convenience aliases.
- **`name_prefix`** is important: it becomes a standard base for naming almost every resource.

**Why `name_prefix`?**

- **Consistency**: All resources are named like `cruddur-dev-*`.
- **Environment isolation**: `cruddur-dev-vpc` vs `cruddur-prod-vpc`.
- **Searchability**: Easy to filter resources by project+env in the AWS console.

---

## Root Main (`terraform/main.tf`)

This is where we need to **wire modules together**.

**VPC Module Call**

```hcl
module "vpc" {
  source         = "./modules/vpc"
  name_prefix    = local.name_prefix
  vpc_cidr_block = var.vpc_cidr_block
  public_subnets = var.public_subnets
}
```

**RDS Module Call**

```hcl
module "rds" {
  source             = "./modules/rds"
  subnet_ids         = module.vpc.public_subnet_id
  vpc_id             = module.vpc.vpc_id_cruddur
  vpc_cidr_block     = module.vpc.vpc_cidr_block

  db_identifier           = var.db_identifier
  db_instance_class       = var.db_instance_class
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  allocated_storage       = var.allocated_storage
  aws_region              = var.aws_region
  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  deletion_protection     = var.deletion_protection
  skip_snapshot           = var.skip_snapshot

  name_prefix = local.name_prefix

  depends_on = [module.vpc]
}
```

- **Networking dependency**: `subnet_ids`, `vpc_id`, and `vpc_cidr_block` are outputs from the **VPC module**. That means **RDS cannot exist until the VPC is created**.
- **`depends_on = [module.vpc]`** explicitly enforces: *build VPC first, then RDS*.

---

## Module Variables (`modules/*/variables.tf`)

Each module declares what it *expects* to receive.

**VPC Module Variables (`modules/vpc/variables.tf`)**

```hcl
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "map of public subnets"
  type        = map(string)
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}
```

**RDS Module Variables (`modules/rds/variables.tf`)**

```hcl
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block used for RDS SG ingress"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}
```

*Plus the rest of the DB-related variables, which mirror the root variables like `db_identifier`, `db_instance_class`, etc.*

This keeps each module **generic** and **reusable**: nothing is hard-coded to “cruddur” inside the modules themselves.

---

## VPC Module: Detailed Explanation (`modules/vpc/main.tf`)

The VPC module sets up basic internet-facing networking.

**`aws_vpc`**

- **Purpose**: Creates the virtual private cloud (VPC).
- Uses `vpc_cidr_block` from module variables.
- Enables DNS so instances can resolve names.
- Names are consistent using `name_prefix`.

```hcl
resource "aws_vpc" "cruddur-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}
```

---

**`aws_internet_gateway`**

- **Purpose**: Connects the VPC to the internet.
- Attaches directly to the created VPC.

```hcl
resource "aws_internet_gateway" "cruddur-igw" {
  vpc_id = aws_vpc.cruddur-vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}
```

---

**`aws_route_table` and `aws_route`**

- **Route table**: A routing rules container for subnets.
- **Route**: Says “for any traffic to `0.0.0.0/0`, send it to the internet gateway”.

This makes subnets **public** when they are associated to this route table.

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cruddur-vpc.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "cruddur-public-route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cruddur-igw.id
}
```

---

**`aws_subnet` with `for_each`**

- **Purpose**: Creates one subnet **per availability zone** defined in `public_subnets`.
- `for_each = var.public_subnets`:
  - If `public_subnets` is:
    - `"us-east-1a" = "10.0.0.0/24"`
    - `"us-east-1b" = "10.0.1.0/24"`, then:
      - It creates 2 subnets:
        - One in `us-east-1a`, CIDR `10.0.0.0/24`
        - One in `us-east-1b`, CIDR `10.0.1.0/24`
- `map_public_ip_on_launch = true` makes them **public subnets**.

**Tag naming with `substr`:**

```hcl
Name = "${var.name_prefix}-public-subnet-${substr(each.key, -1, 1)}"
```

- `each.key` is the AZ (e.g., `"us-east-1a"`).
- `substr(each.key, -1, 1)` takes the **last character** of the AZ (`"a"` or `"b"`).
- So names become like:
  - `cruddur-dev-public-subnet-a`
  - `cruddur-dev-public-subnet-b`


```hcl
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.cruddur-vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-subnet-${substr(each.key, -1, 1)}"
  }
}
```

---

**`aws_route_table_association`**

- **Purpose**: Associates each subnet with the public route table.
- Uses `for_each` over the `aws_subnet.public` resources:
  - Every subnet created earlier gets attached to the route table.
- Result: **all those subnets become internet-routable** via the IGW.

```hcl
resource "aws_route_table_association" "pulic" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
```

---

## RDS Module: Detailed Explanation (`modules/rds/main.tf`)

The RDS module sets up:

- SSM parameters for credentials (read-only)
- RDS subnet group
- Security group + ingress/egress rules
- The actual `aws_db_instance`

---

**`aws_ssm_parameter`**

- **Purpose**: Read sensitive config from **AWS Systems Manager Parameter Store**.
- You don’t hard-code DB credentials in Terraform:
  - `db_name` – the database name inside PostgreSQL.
  - `db_username` – DB user.
  - `db_password` – stored as a secure string (`with_decryption = true`).

This keeps **secrets out of code** and Terraform state (as much as possible).

```hcl
data "aws_ssm_parameter" "db_name" {
  name = "/cruddur/db/name"
}

data "aws_ssm_parameter" "db_username" {
  name = "/cruddur/db/user_name"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/cruddur/db/password"
  with_decryption = true
}
```
---

**`http` Data Source**
- **Purpose**: Fetch your **current public IP** at apply time.
- The endpoint returns something like `"1.2.3.4\n"`.

Later use this IP in the security group ingress to allow only **your machine** to connect to the DB.


```hcl
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}
```

---

**`aws_db_subnet_group`**

- RDS must live in *at least two subnets* in different AZs for high availability.
- `subnet_ids` are passed in from the root module using `module.vpc.public_subnet_id`.

```hcl
resource "aws_db_subnet_group" "cruddur" {
  name       = "cruddur-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-sg"
  }
}
```

---

**`aws_security_group`**

- **Purpose**: A dedicated security group for the RDS instance.
- Located inside the VPC (`vpc_id` from module input).

```hcl
resource "aws_security_group" "cruddur-sg" {
  name        = "cruddur-sg"
  description = "allow postgress access"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}
```
---

**`aws_vpc_security_group_ingress_rule`**

- **Purpose**: Allow PostgreSQL (port 5432) only from your IP.
- `data.http.my_ip.response_body` returns something like `"1.2.3.4\n"`.
- `chomp(...)` removes the trailing newline so we can safely append `/32`.
- Final `cidr_ipv4` value becomes: `1.2.3.4/32`.

This is **much more secure** than opening RDS to `0.0.0.0/0`.


```hcl
resource "aws_vpc_security_group_ingress_rule" "allow-inbound-postgres" {
  security_group_id = aws_security_group.cruddur-sg.id
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}
```
---

**`aws_vpc_security_group_egress_rule`**

- Allows **all outbound traffic** from RDS.
- `ip_protocol = "-1"` = all protocols (standard Terraform idiom).

```hcl
resource "aws_vpc_security_group_egress_rule" "allow-outbound-postgres" {
  security_group_id = aws_security_group.cruddur-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
```

---

**`aws_db_instance`**

```hcl
resource "aws_db_instance" "cruddur_db_instance" {
  identifier                            = var.db_identifier
  instance_class                        = var.db_instance_class
  engine                                = var.db_engine
  engine_version                        = var.db_engine_version
  username                              = data.aws_ssm_parameter.db_username.value
  password                              = data.aws_ssm_parameter.db_password.value
  allocated_storage                     = var.allocated_storage
  availability_zone                     = var.aws_region
  backup_retention_period               = var.backup_retention_period
  port                                  = 5432
  multi_az                              = var.multi_az
  db_name                               = data.aws_ssm_parameter.db_name.value
  storage_type                          = "gp2"
  publicly_accessible                   = var.publicly_accessible
  storage_encrypted                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  deletion_protection                   = var.deletion_protection
  db_subnet_group_name                  = aws_db_subnet_group.cruddur.name
  vpc_security_group_ids                = [aws_security_group.cruddur-sg.id]
  skip_final_snapshot                   = var.skip_snapshot
}
```

Here:

- **Credentials**:
  - `username` and `password` come from SSM parameters.
  - `db_name` also comes from SSM.
- **Availability**:
  - `multi_az` controls whether AWS creates a standby in another AZ.
  - `availability_zone` (here using `aws_region` variable value) defines where the primary DB sits.
- **Security**:
  - `vpc_security_group_ids` attaches the RDS SG we defined above.
  - `publicly_accessible` controls if it gets a public IP.
- **Backups & safety**:
  - `backup_retention_period` determines how many days of automated backups to keep.
  - `deletion_protection` prevents accidental deletion.
  - `skip_final_snapshot` controls whether to create a final snapshot at deletion.

---

## Built-in Functions Used: `for_each`, `substr`, `chomp`

**`for_each`**

Lets you create **multiple instances** of a resource (or module) from a map or set, instead of copying/pasting blocks.

General pattern:

```hcl
resource "TYPE" "NAME" {
  for_each = SOME_MAP

  # each.key   -> map key
  # each.value -> map value
}
```

Benefits:

- Avoids duplicated resource blocks.
- Adding a new AZ is as simple as adding one more entry to `public_subnets`.

---

**`substr`**

`substr(string, offset, length)` returns a substring starting at `offset` with `length` characters.

- `offset` can be negative (start from the end).

**Example from this project:**

```hcl
Name = "${var.name_prefix}-public-subnet-${substr(each.key, -1, 1)}"
```

- `each.key` is the AZ name (e.g., `"us-east-1a"`).
- `substr(each.key, -1, 1)`:
  - `-1` = start at last character.
  - `1` = take one character.
- Result: `"a"` or `"b"` etc.

This is purely for **nicer tag names** like `cruddur-dev-public-subnet-a`.

---

**`chomp`**

`chomp(string)` trims a single trailing newline (and sometimes other whitespace) from a string.

**Example from this project:**

```hcl
cidr_ipv4 = "${chomp(data.http.my_ip.response_body)}/32"
```

- `data.http.my_ip.response_body` returns something like `"1.2.3.4\n"`.
- `chomp(...)` turns it into `"1.2.3.4"`.
- Then we append `/32` to build a valid CIDR: `"1.2.3.4/32"`.

**Why it matters:**

- If we didn’t `chomp`, the CIDR string would be invalid because of the newline.
- This ensures **Terraform can correctly parse** it as a CIDR block.


-----

## Variable & Local Flow (How Values Move Around)

Here is the visual representation of how variables flow:

```
Root variables
        │
        ▼
Root locals.tf:
        │
        ▼
Root main.tf:
        │
        ▼
VPC/RDS module variables.tf:
        │
        ▼
VPC/RDS module main.tf:

```  

------


## `variables.tf` vs `terraform.tfvars`

Defaults in `variables.tf` should only be used for safe, environment-agnostic values.
For environment-specific, cost-impacting, or security-sensitive inputs, defaults should be removed and values must be explicitly provided via `terraform.tfvars` or CI/CD to avoid accidental infrastructure changes.

**Purpose of variables.tf**

- Defines what inputs exist

- Defines type constraints

- Adds descriptions

- Optionally provides safe defaults

- **It does not represent a specific environment.**

**Purpose of terraform.tfvars**

- Supplies environment-specific values

- Keeps secrets & configs out of code

- Overrides defaults from variables.tf

- **Makes configs reusable across environments**


## Precedence Order of `terraform.tfvars`

Terraform resolves variables in this order (last wins):

- CLI -var

- CLI -var-file

- terraform.tfvars

- *.auto.tfvars

- Environment variables (TF_VAR_*)

- default in variables.tf

Terraform variable precedence follows a last-wins model: defaults are lowest priority, then environment variables, auto tfvars, terraform.tfvars, CLI var-files, and finally CLI -var, which has the highest precedence.
