# HNG Stage 1 — DevOps Automated Deployment

This repository contains a sample project and an automated deployment script for HNG Stage 1 DevOps tasks.  
The deployment script (`deploy.sh`) handles the cloning of your repository, Docker container setup, and Nginx reverse proxy configuration.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Deployment Steps](#deployment-steps)
- [Cleanup](#cleanup)
- [Logging](#logging)
- [Notes](#notes)

---

## Features

- Automatically clones your GitHub repository.
- Supports private repositories via Personal Access Token (PAT).
- Builds and runs your app in a Docker container.
- Configures Nginx as a reverse proxy.
- Handles SSH connectivity and file transfer.
- Logs deployment steps for easy troubleshooting.
- Idempotent operations with optional cleanup mode.

---

## Prerequisites

**Local machine:**

- Git
- SSH client
- `rsync` or `scp`
- `curl` (for validation)

**Remote server:**

- Ubuntu server (or any Debian-based distro)
- Docker installed (script can install if missing)
- Nginx installed (script can configure)

> Ensure you have a valid SSH key to access the remote server.

---

## Usage

Make the script executable:

```bash
chmod +x deploy.sh
Run the deployment script:

bash
Copy code
./deploy.sh
Follow the prompts to provide:

Git repository URL

Personal Access Token (optional, if private)

Branch (default: main)

Remote SSH username

Remote server IP or hostname

SSH key path

Container port (e.g., 3000)

Remote project directory (optional)

Deployment Steps
Local checks – Verifies that git, ssh, and rsync (or scp) are installed.

Prepare repository – Clones the repository if not present locally; pulls latest changes if it exists.

Docker deployment – Builds the Docker image and runs the container.

Nginx configuration – Sets up a reverse proxy pointing to the container port.

Validation – Ensures container is running and accessible through Nginx.

Cleanup
To remove deployed containers and clean up the project directory, run:

bash
Copy code
./deploy.sh --cleanup
Cleanup mode is idempotent and will safely stop containers if they exist.

Logging
All deployment logs are saved under the logs/ directory with timestamped filenames:

text
Copy code
logs/deploy_YYYYMMDD_HHMMSS.log
Notes
Default container port is 3000 but can be updated during prompts.

If rsync is not installed, the script falls back to scp.

Ensure your firewall allows traffic on HTTP port 80 for Nginx.

Docker and Nginx must be installed on the remote server for full deployment.

The script is idempotent — safe to rerun without breaking existing deployments.

Happy deploying! ���

pgsql
Copy code

