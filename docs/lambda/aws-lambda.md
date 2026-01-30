## AWS Lambda Implementation

We will implement custom authorizer for cognito. 

> Why do we need it?

Because as per our schema architecture, in the users table, we need to fill in the `cognito_user_id`.
During the singup process, a `cognito_user_id` is created. So, we need some way to pull in the `cognito_user_id` from the user pool and and copy into users table --> `cognito_user_id` column. We will achieve this by using the AWS Lambda function.

> What is AWS Lambda Funcion? How is it useful in our scenario?




