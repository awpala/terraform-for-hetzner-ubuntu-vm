# Provisioning Ubuntu OS on Hetzner via Terraform

## Overview

This repo contains configurations for provisioning cloud resources in [Hetzner](https://www.hetzner.com/) using [Terraform](https://www.terraform.io/). Specifically, the following resources will be provisioned:
  * A Hetzner **server** running Linux Ubuntu OS 22.04 LTS
    * Both `root` user and a custom-specified non-`root` user
  * A Hetzner **volume**, attached to the server
  * [Docker Engine](https://docs.docker.com/engine/) preinstalled on the server

Configurations are given in `main.tf`. Furthermore, user-specified values are listed in reference file `sample.terraform.tfvars`.

## Instructions

***N.B.*** These instructions assume a Unix-like terminal and executable (i.e., `terraform`, paths `/path/to/file`, etc.). For Windows host systems, make corresponding adjustments (e.g., executable `terraform.exe` rather than Unix-like `terraform`, Windows-style paths, etc.) and/or use an appropriate Unix-based terminal application for Windows (e.g., [Git Bash](https://gitforwindows.org/)).

1. Clone this repo locally as follows and change into it:

```bash
git clone https://github.com/awpala/terraform-for-hetzner-ubuntu-vm.git
```
```bash
cd terraform-for-hetzner-ubuntu-vm
```

2. Create an account in [Hetzner](https://www.hetzner.com/), and set up billing for this account.

3. [Download](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) the Terraform executable for the corresponding host system of choice. Extract the executable from the downloaded `.zip` file into the locally cloned repository (i.e., `.../terraform-for-hetzner-ubuntu-vm/`, now containing corresponding executable `.../terraform-for-hetzner-ubuntu-vm/terraform`).

4. If not present already, create a new SSH public/private key pair on the host system (see [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys) for reference). This setup assumes an `ed25519` key. Otherwise, if using a different key (e.g., `rsa`, `ecdsa`, etc.), make corresponding changes in `main.tf` before proceeding (i.e., change values from `id_ed25519` and `id_ed25519.pub` to appropriate key types). Furthermore, copy these keys (i.e., `id_ed25519` and `id_ed25519.pub`, or equivalent) into the locally cloned repository (i.e., from `~/.ssh/` to `.../terraform-for-hetzner-ubuntu-vm/`).

5. In the [Hetzner Cloud Console](https://console.hetzner.cloud), create a new project. Additionally, add a public key to the `SSH keys` under `Security` settings for this project (use the same public key as in the previous step), and additionally create a new API token under `API tokens` (**save/retain** this value for reference on its creation). 

6. Create a new file `terraform.tfvars` and populate values accordingly as specified in reference file `sample.terraform.tfvars` (user-specified values denoted by `<...>`). All non-default values **must** be specified, otherwise defaults (cf. `main.tf`) are pre-specified as follows (these can additionally be overridden accordingly, if so desired):

| Variable Name | Default Value | Unit of Measure | Reference |
|:--:|:--:|:--:|:--:|
| `"server_image"` | `"ubuntu-22.04"` | (N/A) | https://docs.hetzner.com/robot/dedicated-server/operating-systems/standard-images/ |
| `"server_location"` | `"ash"` | (N/A) | https://docs.hetzner.com/cloud/general/locations/ |
| `"server_type"` | `"cpx11"` | (N/A) | https://docs.hetzner.com/cloud/servers/overview/ |
| `"volume_size"` | `10` | GB | https://docs.hetzner.com/cloud/volumes/overview/ |

7. Run the following command to update dependencies if necessary (this will correspondingly modify lockfile `.terraform.lock.hcl`, as well as generate dependencies in local directory `/.terraform`):

```bash
./terraform init --upgrade
```

8. Run the following command to provision the resources in the Hetzner project (supply affirmative response `yes` in the terminal when prompted):

```bash
./terraform apply
```

9. Once the terminal prompt completes, the server should now be provisioned, along with the attached volume. This can be verified in the [Hetzner Cloud Console](https://console.hetzner.cloud) for the corresponding project. To access the provisioned server, simply SSH from the host machine (using the same machine from which the public key was generated/derived). Furthermore, note that the volume is mounted in the server at location `/mnt/<volume_name>` (with `<volume_name>` as specified in `terraform.tfvars`).

10. To destroy/deprovision the resources, simply run the following command (supply affirmative response `yes` in the terminal when prompted):

```bash
./terraform destroy
```
