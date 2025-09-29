# AWS Cognito Implementation


## Install AWS Amplify package

```
cd frontend-react-js
npm install aws-amplify@5.0.16 --save
```

## Env Variables

Set the following env variables in `.env` file:
```
REACT_APP_AWS_PROJECT_REGION= # Set to your AWS project region, e.g., us-east-1
REACT_APP_AWS_COGNITO_REGION= # Set to your AWS Cognito region, e.g., us-east-1
REACT_APP_AWS_USER_POOLS_ID= # Set to your AWS Cognito User Pool ID
REACT_APP_CLIENT_ID= # Set to your AWS Cognito App Client ID
```

REACT_APP_AWS_USER_POOLS_ID and REACT_APP_CLIENT_ID values are available in AWS Cognito user pool UI.

## Configure Amplify

Hook up our cognito pool to our code in the `App.js`

```
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_AWS_PROJECT_REGION,
  "aws_cognito_identity_pool_id": process.env.REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```



