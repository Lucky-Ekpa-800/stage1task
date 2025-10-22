# DevOps Intern — Stage 1 Deployment Script

This repository contains `deploy.sh`, a Bash script that automates the deployment of a Dockerized application to a remote Linux server. It is designed to handle everything from cloning your repository to setting up Docker, Nginx, and verifying that your application is running correctly.

---

## Features

The script provides:

- **Interactive prompts** for essential deployment information:
  - Git repository URL (HTTPS)
  - Personal Access Token (for private repositories)
  - Branch selection (defaults to `main`)
  - Remote SSH username and host
  - SSH key path
  - Application internal container port
  - Optional remote project directory
- **Repository management:** Clones or updates your repository locally with branch selection support.
- **Remote server setup:** Installs Docker, Docker Compose, and Nginx if missing.
- **Deployment automation:** Builds and runs containers using either `docker-compose.yml` or a `Dockerfile`.
- **Reverse proxy configuration:** Sets up Nginx to forward traffic to your application.
- **Deployment validation:** Checks Docker containers, Nginx configuration, and application health.
- **Logging:** All actions are recorded in `./logs/deploy_YYYYMMDD_HHMMSS.log`.
- **Idempotency:** Stops old containers before redeploying.
- **Cleanup:** Remove deployed resources with the `--cleanup` flag.

---

## Prerequisites

### Local Machine

Ensure the following tools are installed:

- `git`
- `ssh`
- `rsync`
- `curl`

### Remote Server

- Ubuntu/Debian or RHEL/CentOS compatible
- User with `sudo` privileges
- Port 22 open for SSH connections

---

## Usage

### Make the script executable:

```bash
chmod +x deploy.sh
Run interactively:
bash
Copy code
./deploy.sh
You will be prompted for:

Git repository URL

Personal Access Token (if private)

Branch (default: main)

Remote SSH username

Remote server IP or hostname

SSH key path (e.g., ~/.ssh/id_rsa)

Application internal container port (e.g., 3000)

Remote project directory (optional)

Cleanup deployed resources:
bash
Copy code
./deploy.sh --cleanup
Deployment Workflow
Checks local prerequisites (git, ssh, rsync, curl).

Clones or updates your repository.

Verifies SSH connectivity to the remote server.

Installs Docker, Docker Compose, and Nginx if missing.

Transfers project files to the remote server.

Builds and runs Docker containers.

Configures Nginx reverse proxy with SSL placeholder.

Validates deployment and application health.

Logs all actions for auditing and debugging.

Notes & Limitations
For production, add proper TLS/SSL using Certbot or Let’s Encrypt.

The script assumes the remote user can run sudo commands without interactive password prompts.

A default Node.js Dockerfile is generated if none is provided. You can replace it with your own Dockerfile.

Logs are stored in ./logs/ for reference and troubleshooting.

Example Log Output
text
Copy code
INFO: Connecting to 192.168.1.100...
SUCCESS: SSH connectivity OK
INFO: Installing Docker...
SUCCESS: Docker installation verified
INFO: Deploying application on remote host...
SUCCESS: Deployment completed successfully! 
