## ECS Task Role vs ECS Execution Role - Deep Dive

When I started learning ECS through AWS UI, I came across two special fields named Task Execution Role and Task Role. It was confused becuase of the fact why does ECS need two role permissions and what is the use of it?

What problem do these two roles solve?

* Task Execution Role is used by ECS service itself (AWS-managed)
* Task Role is used by the application running inside the container


> In simple terms:
>
>Task Execution role = Can ECS start my task?
>
>Task role = What can my app do?


## Task Execution role

The Task Execution role is used before your container starts. ECS needs permission to:

- Pull image from ECR

- Write logs to CloudWatch

- Read secrets from SSM / Secrets Manager (for env injection)

You can use AWS managed policy `AmazonECSTaskExecutionRolePolicy`, which includes the necessary permissions for ECS service or you can create a custom policy that suits your permissions.

For this project, I will use the AWS managed policy `AmazonECSTaskExecutionRolePolicy`.

### Implementation Steps

1. Create `backend-flask/aws/iam` directory.
2. Create a file named `ecs-tasks-trust-policy.json` that contains the trust policy to use for the IAM role.
```
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
```
3. Create a role named `CruddurServiceExecutionRole` using the trust policy:
```
$ aws iam create-role \
      --role-name CruddurServiceExecutionRole  \ 
      --assume-role-policy-document file://aws/iam/ecs-task-trust-policy.json
```
4. Attach the AWS managed `AmazonECSTaskExecutionRolePolicy` policy to the `CruddurServiceExecutionRole`:
```
$ aws iam attach-role-policy \
      --role-name CruddurServiceExecutionRole \
      --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```     
5. Becuase we are storing the secrets in AWS Parameter store, we need to manually add the permissions as a policy to the task execution role. Create a file named `ssm-read-policy.json` that contains the parameter store permissions specific to the path where you've stored all the parameters:

```
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowReadSpecificSSMParameters",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource": "arn:aws:ssm:us-east-1:111122223333:parameter/cruddur/backend-flask/*"
      }
    ]
  }
```

7. Attach a custom inline policy named `AllowSSMRead` to the `CruddurServiceExecutionRole` role:
```
$  aws iam put-role-policy \
        --role-name CruddurServiceExecutionRole \
        --policy-name AllowSSMRead \ 
        --policy-document file://aws/iam/ssm-read-policy.json
```

**Verficiation**
1. aws iam get-role --role-name CruddurServiceExecutionRole
2. aws iam list-attached-role-policies --role-name CruddurServiceExecutionRole
3. aws iam list-role-policies --role-name CruddurServiceExecutionRole


## Task role

The task role is used for anything your app does at runtime, such as:

- Read/write S3

- Read SSM parameters dynamically

- Access DynamoDB

- Publish to SNS

- Call SQS

For this project we need to provide permissions to cloudwatch and Session Manager permissions (for container access to ECS Fargate cluster).


### Implementation Steps

1. Create a role named `CruddurTaskRole` using the trust policy:
```
$ aws iam create-role \
      --role-name CruddurTaskRole  \ 
      --assume-role-policy-document file://aws/iam/ecs-task-trust-policy.json
```

2. Create a file named `ssm-access-policy.json` that contains the Session Manager permissions permissions:
```
{
    "Version":"2012-10-17",		 	 	 
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:UpdateInstanceInformation",
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
}
```

3. Attach a custom inline policy named `SSMAccessPolicy` to the `CruddurTaskRole` role:
```
$  aws iam put-role-policy \
        --role-name CruddurTaskRole \
        --policy-name SSMAccessPolicy \ 
        --policy-document file://aws/iam/ssm-access-policy.json
```

4. Attach the AWS managed `CloudWatchFullAccess` policy to the `CruddurTaskRole`:
```
$ aws iam attach-role-policy \
      --role-name CruddurTaskRole \
      --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
``` 
**Verficiation**
1. aws iam get-role --role-name CruddurTaskRole
2. aws iam list-attached-role-policies --role-name CruddurTaskRole
3. aws iam list-role-policies --role-name CruddurTaskRole
