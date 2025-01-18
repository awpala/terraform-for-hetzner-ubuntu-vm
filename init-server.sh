#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log installation steps
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

# Read environment variables passed from Terraform
NONROOT_USER_NAME="$1"
NONROOT_USER_GROUP="$2"
NONROOT_USER_PASSWORD="$3"
NONROOT_USER_EMAIL="$4"
VOLUME_NAME="$5"
SSH_PUBLIC_KEY="$6"

log "Initializing Hetzner server..."

# ------ 1) Set up Docker ------

# ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# ref: https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user

log "Installing Docker..."

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ------ 2) Set up nonroot user ------

log "Setting up non-root user..."

# Create group and user and set password
sudo groupadd "$NONROOT_USER_GROUP"
sudo useradd -m -G sudo,docker -g "$NONROOT_USER_GROUP" "$NONROOT_USER_NAME"
echo "${NONROOT_USER_NAME}:${NONROOT_USER_PASSWORD}" | sudo chpasswd

# Set user's shell to `bash`
sudo chsh -s /bin/bash "$NONROOT_USER_NAME"

# Initialize volume directory (auto-mounted in subsequent resource setup step for the attached volume)
sudo mkdir -p "/mnt/${VOLUME_NAME}"

# Set ownership and permissions for user's home directory and volume mount
sudo chown -R "${NONROOT_USER_NAME}:${NONROOT_USER_GROUP}" "/home/${NONROOT_USER_NAME}" "/mnt/${VOLUME_NAME}"
sudo chmod 700 "/home/${NONROOT_USER_NAME}" "/mnt/${VOLUME_NAME}"

# Set up SSH directory for user
sudo -H -u "$NONROOT_USER_NAME" bash -c "mkdir -p /home/${NONROOT_USER_NAME}/.ssh && chmod 700 /home/${NONROOT_USER_NAME}/.ssh"

# Generate SSH key pair for user
sudo -H -u "$NONROOT_USER_NAME" ssh-keygen -t ed25519 -C "$NONROOT_USER_EMAIL" -N '' -f "/home/${NONROOT_USER_NAME}/.ssh/id_ed25519"

# Insert SSH public key into authorized_keys file
sudo -H -u "$NONROOT_USER_NAME" bash -c "echo \"${SSH_PUBLIC_KEY}\" >> /home/${NONROOT_USER_NAME}/.ssh/authorized_keys"

# Initialize files for user's bash profile
sudo -H -u "$NONROOT_USER_NAME" bash -c "touch /home/${NONROOT_USER_NAME}/.bashrc /home/${NONROOT_USER_NAME}/.bash_aliases /home/${NONROOT_USER_NAME}/.profile"


log "Hetzner server initialization completed successfully"
