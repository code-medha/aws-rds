<!--
Guidance for AI coding agents working on this repository.
Keep this file short and actionable. Do not add generic advice.
-->
# Copilot instructions for aws-rds

This repository contains a small Flask backend and a React frontend. Key areas an AI coding agent should know to be productive quickly:

- Backend entry: `backend-flask/app.py` (Flask app, routes, and instrumentation).
- Services: `backend-flask/services/*.py` — each service exposes a .run(...) method. Some return a plain list (e.g. `HomeActivities.run`) while others return a model dict with `{'data':..., 'errors':...}` (e.g. `CreateActivity`, `Messages`). Follow the existing return shapes when editing or adding services.
- Auth helper: `backend-flask/lib/cognito_jwt_token.py` provides `extract_access_token()` and `CognitoJwtToken.verify()` which the app uses to authenticate routes. Use these utilities rather than reimplementing JWT verification.
- Environment-driven behavior: Several features are toggled by environment variables (for example `SIMULATE_HOME_LATENCY`, `SIMULATE_HOME_ERROR`, `FRONTEND_URL`, `BACKEND_URL`, `ROLLBAR_ACCESS_TOKEN`, AWS_COGNITO_*). When testing or adding features, prefer using env vars to toggle behavior as the project does.
- Observability: The app uses OpenTelemetry instrumentation (`opentelemetry`), and Rollbar for error reporting. If you change request flow or add new long-running operations, add tracing spans or rollbar notifications where appropriate (follow examples in `app.py` and `home_activities.py`).

Project conventions and patterns to mirror:

- Routes live in `app.py` and call into the service layer. Keep business logic in `services/` and keep route handlers thin (parse request, call Service.run, map result to (data, status)).
- Service return contract:
  - For CRUD-like services: return a model dict: `{'data': ..., 'errors': None}` or `{'data': None, 'errors': [...]} `
  - For mock data providers: returning raw lists/dicts is acceptable (e.g. `HomeActivities.run`). When converting a mock to a CRUD service, migrate to the model dict shape.
- Hard-coded user handles: Several routes use a placeholder handle `andrewbrown`. When adding auth, replace these placeholders with values from verified Cognito claims (see `HomeActivities` usage in `app.py`).
- TTL handling: `CreateActivity.run` accepts an externally-specified TTL string (e.g., '30-days', '12-hours'); reuse this pattern for expiry calculations if creating new activity-like resources.

Developer workflows (how to run & test locally):

- Start local Postgres (if needed) with the project's `docker-compose.dev.yml`:
  - docker compose -f ./docker-compose.dev.yml up -d --build
  - psql "postgresql://postgres:password@localhost:5436/postgres"
- Backend: run `backend-flask/app.py` directly. The repository expects a Python 3.10 venv. See `backend-flask/README.md` for quick setup.

Files and places to inspect for changes:

- `backend-flask/app.py` — routing, CORS, instrumentation, rollbar init.
- `backend-flask/services/*.py` — business logic. Use existing `.run()` signatures.
- `backend-flask/lib/cognito_jwt_token.py` — auth verification utility.
- `docker-compose.dev.yml` and `backend-flask/db/schema.sql` — local DB and migration entrypoint.

Small code examples to follow

- Route -> Service pattern (in `app.py`):

  1. parse request (headers, params, JSON)
  2. call Service.run(...)
  3. if model has `errors` return errors with 422 else return data with 200

- Using Cognito verify:

  - access_token = extract_access_token(request.headers)
  - claims = cognito_jwt_token.verify(access_token)

When to ask for help / limitations

- The repo contains placeholder/hard-coded data and not all services are backed by a persistent DB. If you need to add database migrations or persistent state, confirm whether the change should modify `backend-flask/db/schema.sql` and `docker-compose.dev.yml`.
- If a change requires secrets (AWS, Rollbar tokens, Cognito IDs) do not add them to the repo; use environment variables and document required env vars in `backend-flask/README.md`.

If anything in these instructions is unclear or you want more examples (tests, request samples), tell me which area to expand and I'll update this file.
