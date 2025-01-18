####
# Variables Declarations
##

# Hetzner resources configs -- uncomment `sensitive = true` (i.e., shown by default) in below to suppress outputs in Terraform CLI outputs
variable "hetzner" {
  description = "Hetzner Cloud configuration settings"

  type = object({
    # Authentication configuration
    api_token      = string # Hetzner API token
    ssh_public_key = string # SSH public key
    ssh_key_name   = string # Name of SSH public key as defined in Hetzner Cloud for this project
    project_id     = string # Hetzner project ID

    # Server configuration
    server = object({
      name     = string                           # Hetzner server name
      image    = optional(string, "ubuntu-24.04") # Hetzner server image. See https://docs.hetzner.com/robot/dedicated-server/operating-systems/standard-images/ for options.
      location = optional(string, "ash")          # Hetzner server location. See https://docs.hetzner.com/cloud/general/locations/ for options.
      type     = optional(string, "cpx11")        # Hetzner server type. See https://docs.hetzner.com/cloud/servers/overview/ for options.
    })
    
    # Volume configuration
    volume = object({
      name = string               # Hetzner volume name
      size = optional(number, 10) # Hetzner volume size, in GB. See https://docs.hetzner.com/cloud/volumes/overview for options.
    })
  })

  # sensitive = true
}

# Non-root user configs
variable "nonroot_user" {
  description = "Non-root user configuration settings"

  type = object({
    name     = string                             # Non-root user name
    group    = string                             # Non-root user group
    password = string                             # Non-root user password
    email    = optional(string, "gpb@gatech.edu") # Non-root user email
  })

  # sensitive = true
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
  token = var.hetzner.api_token
}

# Hetzner - provision server
resource "hcloud_server" "ubuntu_server" {
  name        = var.hetzner.server.name
  server_type = var.hetzner.server.type
  image       = var.hetzner.server.image
  location    = var.hetzner.server.location
  ssh_keys    = [var.hetzner.ssh_key_name]

  connection {
    type            = "ssh"
    user            = "root"
    host            = self.ipv4_address
    timeout         = "1m"
    target_platform = "unix"
    agent           = false
    private_key     = file("id_ed25519")
  }

  # install dependencies upon server initialization
  provisioner "file" {
    source      = "${path.module}/init-server.sh"
    destination = "/tmp/init-server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-server.sh",
      "/tmp/init-server.sh '${var.nonroot_user.name}' '${var.nonroot_user.group}' '${var.nonroot_user.password}' '${var.nonroot_user.email}' '${var.hetzner.volume.name}' '${var.hetzner.ssh_public_key}'",
    ]
  }

  # add bash profile for root and non-root user
  provisioner "file" {
    source      = "${path.module}/bash-starters/.bashrc"
    destination = "/root/.bashrc"
  }
  provisioner "file" {
    source      = "${path.module}/bash-starters/.bashrc"
    destination = "/home/${var.nonroot_user.name}/.bashrc"
  }

  provisioner "file" {
    source      = "${path.module}/bash-starters/.bash_aliases"
    destination = "/root/.bash_aliases"
  }
  provisioner "file" {
    source      = "${path.module}/bash-starters/.bash_aliases"
    destination = "/home/${var.nonroot_user.name}/.bash_aliases"
  }

  provisioner "file" {
    source      = "${path.module}/bash-starters/.profile"
    destination = "/root/.profile"
  }
  provisioner "file" {
    source      = "${path.module}/bash-starters/.profile"
    destination = "/home/${var.nonroot_user.name}/.profile"
  }
}

# Hetzner - provision volume and mount/attach it to the server at location `/mnt/<volume_name>`
resource "hcloud_volume" "data_volume" {
  name      = var.hetzner.volume.name
  size      = var.hetzner.volume.size
  server_id = hcloud_server.ubuntu_server.id
  automount = true
  format    = "ext4"

  depends_on = [hcloud_server.ubuntu_server]
}
