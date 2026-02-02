## AWS Cognito and Lambda Implementation

To implement authentication to our app, I will use Cogntio service. 

I will also create Lambda function as a Cognito Post Confirmation trigger so that when a user finishes sign-up and confirmation, it automatically creates a row in our users table with their Cognito data.

## Why do we need it?

Our schema has a users table with a `cognito_user_id` column. During the signup process, Cognito creates a user and assigns a `cognito_user_id` (the sub claim). We need that value (and a few other attributes) in our own database so the app can link Cognito users to our users table. We don’t want to do this manually, so we use a Lambda that Cognito calls right after the user confirms sign-up. That Lambda reads the user’s attributes from the event and inserts them into the users table.


## What is an AWS Lambda function? How is it useful here?

AWS Lambda is a serverless function. You write the code, AWS runs it when something triggers it. In our case, Cognito triggers it on the `Post Confirmation` lifecycle event. So as soon as a user confirms their sign-up (e.g. email), Cognito invokes our Lambda and passes the new user’s attributes in the event. We use that to insert one row into public.users with `display_name`, `email`, `handle`, and `cognito_user_id`. That way, every confirmed Cognito user automatically gets a matching row in our DB.


Add the following pythong code in the AWS Lambda code editor and deploy it.

```python
import psycopg2
import os
import json


def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes:', user)

    user_display_name  = user.get('name')
    user_email         = user.get('email')
    user_handle        = user.get('preferred_username')
    user_cognito_id    = user.get('sub')

    conn = None 

    try:
        sql = """
        INSERT INTO public.users (
          display_name, email, handle, cognito_user_id
        ) VALUES (%s, %s, %s, %s)
        """       

        conn = psycopg2.connect(os.getenv("CONNECTION_URL"))
        cur = conn.cursor()
        cur.execute(sql, (user_display_name, user_email, user_handle, user_cognito_id))
        conn.commit()
        cur.close()
        print('Insert committed.')
    except (Exception, psycopg2.DatabaseError) as error:
        print('DB error:', error)

    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event        
```


## Psycopg2 Lambda layer

Our Post Confirmation Lambda uses psycopg2 to insert the new user into the RDS (PostgreSQL) users table. Lambda’s built-in Python runtime does not include psycopg2 or its C libraries, so we have to provide it ourselves. We do that by building a Lambda layer and attaching it to the function.

## Why can’t we just add psycopg2 to the deployment package?

We could zip psycopg2 with our code, but psycopg2 depends on native (C) libraries that must be compiled for the same OS and architecture as the Lambda runtime. Lambda runs on Amazon Linux 2 (x86_64 or arm64). If we install psycopg2 on macOS or Windows and pack it into the deployment package, it often fails at runtime with import or linking errors. So we build the dependency inside a container that matches Lambda’s environment (Python 3.9, Linux), then zip that and upload it as a layer.


## Psycopg2 Lambda layer Implementation

1. Create a folder for the layer contents.
```
$ mkdir psycopg2-layer

```


2. Run a container that matches Lambda’s Python 3.9 Linux environment. We use it so that pip install psycopg2-binary compiles/installs the right binaries for Lambda.

```
$ docker run --rm -v "$PWD":/var/task public.ecr.aws/sam/build-python3.9:latest   bash -lc "python -m pip install --upgrade pip"
```

3. Install psycopg2 into python/lib/python3.9/site-packages/. Lambda expects layers to use this structure so it can add python/ to the path.

```
$ pip install --target python/lib/python3.9/site-packages psycopg2-binary
```

4. Zip the python directory. This archive is what we upload as a Lambda layer.
```
$ zip -r psycopg2-layer-python39-x86_64.zip python
```

After uploading the zip as a new layer, we attach that layer to the Post Confirmation Lambda so the function can import psycopg2 and connect to RDS.


