####
# Variables Declarations
##

# Hetzner access and authentication
variable "hetzner_api_token" {
  description = "Hetzner API token"
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  # sensitive   = true
}

variable "ssh_key_name_hetzner" {
  description = "Name of SSH public key as defined in Hetzner Cloud for this project"
  type        = string
  # sensitive   = true
}

variable "hetzner_project_id" {
  description = "Hetzner project ID"
}

# Hetzner resource - server
variable "server_name" {
  description = "Hetzner server name"
}

variable "server_image" {
  description = "Hetzner server image. See https://docs.hetzner.com/robot/dedicated-server/operating-systems/standard-images/ for options."
  default     = "ubuntu-22.04"
}

variable "server_location" {
  description = "Hetzner server location. See https://docs.hetzner.com/cloud/general/locations/ for options."
  default     = "ash"
}

variable "server_type" {
  description = "Hetzner server type. See https://docs.hetzner.com/cloud/servers/overview/ for options."
  default     = "cpx11"
}

# Hetzner resource - volume
variable "volume_name" {
  description = "Name of the volume"
}

variable "volume_size" {
  description = "Size of the volume in GB. See https://docs.hetzner.com/cloud/volumes/overview for options."
  default     = 10
}

# Non-root user settings -- uncomment `sensitive = true` to obscure values in terraform CLI outputs
variable "nonroot_user" {
  description = "Name for the nonroot user"
  # sensitive   = true
}

variable "nonroot_user_group" {
  description = "Group for the nonroot user"
  # sensitive   = true
}

variable "nonroot_user_password" {
  description = "Password for the nonroot user"
  # sensitive   = true
}

variable "nonroot_user_email" {
  description = "Email address for the nonroot user"
  default     = "gpb@gatech.edu"
  # sensitive   = true
}

####
# Resources Provisioning
##

# Hetzner - cloud config
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_api_token
}

# Hetzner - provision server
resource "hcloud_server" "ubuntu_server" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.server_image
  location    = var.server_location
  ssh_keys = [var.ssh_key_name_hetzner]

  connection {
    type            = "ssh"
    user            = "root"
    host            = self.ipv4_address
    timeout         = "1m"
    agent           = false
    target_platform = "unix"
    private_key     = file("id_ed25519")
  }

  provisioner "remote-exec" {
    inline = [
      # ------ 1) Set up Docker  ------
      # ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
      # ref: https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user

      # Update package repositories
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg",

      # Configure Docker repository key
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker-archive-keyring.gpg",

      # Configure Docker repository
      "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",

      # Install Docker and related packages
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

      # ------ 2) Set up nonroot user ------

      # Create group and user and set password
      "sudo groupadd ${var.nonroot_user_group}",
      "sudo useradd -m -G sudo,docker -g ${var.nonroot_user_group} ${var.nonroot_user}",
      "echo \"${var.nonroot_user}:${var.nonroot_user_password}\" | sudo chpasswd",

      # Set user's shell to `bash`
      "sudo chsh -s /bin/bash ${var.nonroot_user}",

      # Initialize volume directory (mounted in subsequent resource setup step at the end of this config file)
      "sudo mkdir -p /mnt/${var.volume_name}",

      # Set ownership and permissions for user's home directory and volume mount
      "sudo chown -R ${var.nonroot_user}:${var.nonroot_user_group} /home/${var.nonroot_user} /mnt/${var.volume_name}",
      "sudo chmod 700 /home/${var.nonroot_user} /mnt/${var.volume_name}",

      # Set up SSH directory for user
      "sudo -H -u ${var.nonroot_user} bash -c 'mkdir -p /home/${var.nonroot_user}/.ssh && chmod 700 /home/${var.nonroot_user}/.ssh'",

      # Generate SSH key pair for user
      "sudo -H -u ${var.nonroot_user} ssh-keygen -t ed25519 -C '${var.nonroot_user_email}' -N '' -f /home/${var.nonroot_user}/.ssh/id_ed25519",

      # Insert SSH public key into authorized_keys file
      "sudo -H -u ${var.nonroot_user} bash -c 'echo \"${var.ssh_public_key}\" >> /home/${var.nonroot_user}/.ssh/authorized_keys'",

      # Initialize files for user's bash profile
      "sudo -H -u ${var.nonroot_user} bash -c 'touch /home/${var.nonroot_user}/.bashrc /home/${var.nonroot_user}/.bash_aliases /home/${var.nonroot_user}/.profile'",
    ]
  }

  # add bash profile for root and user
  provisioner "file" {
    source = "${path.module}/.bashrc"
    destination = "/root/.bashrc"
  }
  provisioner "file" {
    source = "${path.module}/.bashrc"
    destination = "/home/${var.nonroot_user}/.bashrc"
  }

  provisioner "file" {
    source = "${path.module}/.bash_aliases"
    destination = "/root/.bash_aliases"
  }
  provisioner "file" {
    source = "${path.module}/.bash_aliases"
    destination = "/home/${var.nonroot_user}/.bash_aliases"
  }

  provisioner "file" {
    source = "${path.module}/.profile"
    destination = "/root/.profile"
  }
  provisioner "file" {
    source = "${path.module}/.profile"
    destination = "/home/${var.nonroot_user}/.profile"
  }
}

# Hetzner - provision volume and mount/attach it to the server at location `/mnt/<volume_name>`
resource "hcloud_volume" "data_volume" {
  name      = var.volume_name
  size      = var.volume_size
  server_id = hcloud_server.ubuntu_server.id
}

# alias server id to use in volume mounting configs
data "hcloud_server" "ubuntu_server" {
  id = hcloud_server.ubuntu_server.id
}

# Create the volume and mount it to server
resource "null_resource" "mount_volume" {
  depends_on = [hcloud_volume.data_volume]

  # add trigger in order to mount the volume to the server post-launch of server
  triggers = {
    timestamp = timestamp()
  }

  connection {
    type            = "ssh"
    user            = "root"
    host            = hcloud_server.ubuntu_server.ipv4_address
    timeout         = "1m"
    agent           = false
    target_platform = "unix"
    private_key     = file("id_ed25519")
  }

  # these commands are provided by Hetzner on Volume creation in order to mount the volume into a server(s)
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data_volume.id}",
      "sudo mount /dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data_volume.id} /mnt/${var.volume_name}",
      "sudo echo '/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data_volume.id} /mnt/${var.volume_name} ext4 defaults 0 0' | sudo tee -a /etc/fstab",
    ]
  }
}
