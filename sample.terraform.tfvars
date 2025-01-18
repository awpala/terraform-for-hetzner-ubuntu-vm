# Hetzner resources
hetzner = {
  api_token      = <value-from-hetzner-cloud-console>
  ssh_public_key = <custom-value>
  ssh_key_name   = <value-from-hetzner-cloud-console>
  project_id     = <custom-value>

  server = {
    name     = <custom-value>
    image    = <value-from-hetzner> # default "ubuntu-22.04" if omitted | ref: https://docs.hetzner.com/robot/dedicated-server/operating-systems/standard-images/
    location = <value-from-hetzner> # default "ash" if omitted | ref: https://docs.hetzner.com/cloud/general/locations/
    type     = <value-from-hetzner> # default "cpx11" if omitted | ref: https://docs.hetzner.com/cloud/servers/overview/
  }

  volume = {
    name = <custom-value>
    size = <value-from-hetzner-within-valid-range> # default 10 (GB) if omitted | ref: https://docs.hetzner.com/cloud/volumes/overview
  }
}

# Non-root user
nonroot_user = {
  name     = <custom-value>
  group    = <custom-value>
  password = <custom-value>
  email    = <custom-value>
}
