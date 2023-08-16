# Hetzner access and authentication
hetzner_api_token = <value-from-hetzner-cloud-console>
ssh_public_key = <custom-value>
ssh_key_name_hetzner = <value-from-hetzner-cloud-console>
hetzner_project_id = <custom-value>

# Hetzner resource - server
server_name = <custom-value>
server_image = <value-from-hetzner> # default "ubuntu-22.04" if omitted | ref: https://docs.hetzner.com/robot/dedicated-server/operating-systems/standard-images/
server_location = <value-from-hetzner> # default "ash" if omitted | ref: https://docs.hetzner.com/cloud/general/locations/
server_type = <value-from-hetzner> # default "cpx11" if omitted | ref: https://docs.hetzner.com/cloud/servers/overview/

# Hetzner resource - volume
volume_name = <custom-value>
volume_size = <value-from-hetzner-within-valid-range> # default 10 (GB) if omitted | ref: https://docs.hetzner.com/cloud/volumes/overview

# Non-root user settings 
nonroot_user_group = <custom-value>
nonroot_user = <custom-value>
nonroot_user_password = <custom-value>
nonroot_user_email = <custom-value>
