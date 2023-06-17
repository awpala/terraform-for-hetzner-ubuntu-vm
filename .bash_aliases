# volume mount and VM-mounted docker volumes data
# export z=/mnt/<volume-name> # replace `<volume-name>`, uncomment this line, and then navigate via `cd $z`
export vols=/var/lib/docker/volumes
# export vad=$vols/apps-and-dbs-data/_data # create `apps-and-dbs-data` (or equivalent) via `docker volume <...>` then uncomment this line

# docker compose commands
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# docker commands
alias dv='docker volume'
alias dvc='dv create'
alias dvc-ad='dvc apps-and-dbs-data'
alias dn='docker network'
alias dnc='dn create'
alias dnc-ad='dnc apps-and-dbs-network'

# VM memory management -- ref: https://askubuntu.com/a/1280347
alias free-ram='sync && echo 3 | sudo tee /proc/sys/vm/drop_caches***'
alias check-ram='free -h'

# OS maintenance
alias ubuntu-v='sudo lsb_release -a'
alias ubuntu-up='sudo apt update && sudo apt upgrade -y'
