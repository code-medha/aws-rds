## ECS Task Definitions

I will document the task defintion for the backend and frontend using in-line comments.


1. create backend-flask-.json file.
2. register task dfintion:
$ aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
