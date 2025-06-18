# ManageDockerCompose
This is an interactive Bash script designed to simplify Docker-Compose management on Ubuntu servers through a command-line interface. The tool provides a user-friendly menu system for common Docker-Compose operations while maintaining security best practices.


# Docker Compose Manager for Ubuntu Servers 🐳

![GitHub](https://img.shields.io/badge/Ubuntu-20.04%20|%2022.04-E95420?logo=ubuntu)
![GitHub](https://img.shields.io/badge/Docker-2CE3F6?logo=docker)
![GitHub](https://img.shields.io/badge/Bash-Script-4EAA25?logo=gnu-bash)
![GitHub](https://img.shields.io/badge/Maintainer-donpat1to-blue)

A secure, interactive CLI tool for managing Docker Compose environments on Ubuntu servers with proper privilege management.

## Features ✨

- 🛑 **Service Management**: Stop/restart all or selected Docker stacks
- 🔄 **Smart Updates**: Option to update compose files during restarts
- 🖥 **System Maintenance**: Integrated server update routine
- 🔢 **Multi-Select**: Number-based selection of multiple services
- 🔒 **Security First**: 
  - On-demand sudo with clean privilege drop
  - Input validation and sanitization
  - Clear operation logging

## Installation ⚙️

### Requirements
- Ubuntu 20.04/22.04 LTS
- Docker Engine & Docker Compose
- Standard `/srv/*/docker-compose.yaml` structure

### Setup
```bash
git clone https://github.com/donpat1to/ManageDockerCompose.git
cd docker-compose-manager
chmod +x *.sh
