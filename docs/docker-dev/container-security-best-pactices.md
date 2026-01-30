## Container Security Best Practices

Security is an essential part of any containerized application workflow. Below are some best practices to ensure your images are secure, starting with automated scanning using Snyk.

### Image Vulnerability Scanning

Image Vulnerability Scanning is the process of inspecting Docker container images to detect known security vulnerabilities (CVEs — Common Vulnerabilities and Exposures) in:

- Base OS packages (e.g., Ubuntu, Alpine)

- Application dependencies (e.g., Node.js, Python, Java packages)

- Open-source libraries

- System tools included in the image

In this project, we'll integrate Snyk, a popular container security scanner, using GitHub Actions.

1. Create an account at [snyk.io](https://snyk.io).

2. Click [Snyk account settings](https://app.snyk.io/account).

3. Under **Auth Token**, copy your API key.

4. Go to your GitHub repository.

5. Navigate to **Settings** → **Secrets and variables** → **Actions**.

6. Click **New repository secret**.

7. Enter the following details:
- Name: SNYK_TOKEN
- Secret: Paste the API token you copied

8. Under root directory, create `.github/workflows/snyk-docker-scan.yml` file.

9. Add the following snyk configuration in snyk-docker-scan.yml:
```
name: Snyk Security

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

permissions:
  contents: read

jobs:
  snyk:
    permissions:
      contents: read # for actions/checkout
      security-events: write # for uploading SARIF results
      actions: read
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master

      - name: Set up Snyk CLI
        uses: snyk/actions/setup@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      # SAST - Snyk Code (Optional: || true prevents pipeline failure)
      - name: Snyk Code test
        run: snyk code test --sarif > snyk-code.sarif || true

      # Build and Scan Backend Docker image
      - name: Build backend Docker image
        run: docker build -t backend-image backend-flask/

      - name: Snyk Container test (backend)
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        run: snyk container test backend-image --file=backend-flask/Dockerfile --severity-threshold=high || true

      - name: Snyk Container SARIF output (backend)
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}      
        run: |
          snyk container test backend-image \
            --file=backend-flask/Dockerfile \
            --severity-threshold=high \
            --severity=low=3.0,medium=6.0,high=8.0 \
            --sarif-file-output=container-backend.sarif || true

      - name: Upload Snyk Container SARIF to GitHub Code Scanning
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}      
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: container-backend.sarif
          category: "snyk-container-backend"

      # Build and Scan Frontend Docker image
      - name: Build frontend Docker image
        run: docker build -t frontend-image frontend-react-js/

      - name: Snyk Container test (frontend)
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        run: snyk container test frontend-image --file=frontend-react-js/Dockerfile --severity-threshold=high || true

      - name: Snyk Container SARIF output (frontend)
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}      
        run: |
          snyk container test frontend-image \
            --file=frontend-react-js/Dockerfile \
            --severity-threshold=high \
            --severity=low=3.0,medium=6.0,high=8.0 \
            --sarif-file-output=container-frontend.sarif || true

      - name: Upload Snyk Container SARIF to GitHub Code Scanning
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}      
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: container-frontend.sarif
          category: "snyk-container-frontend"
```

### No Sensitive Data in Docker Files or Images

Never hardcode secrets, passwords, or API keys in Dockerfiles, environment variables, or baked into images.


### Read-Only File System and Volume for Docker

Set the file system of containers as read-only wherever possible to reduce tampering risk.


### Non-Root User Mode

Avoid running containers (and Docker daemon where possible) as root to limit damage if compromised.
