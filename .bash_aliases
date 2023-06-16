# volume mount and VM-mounted docker volumes data
# export z=/mnt/<volume-name> # replace `<volume-name>`, uncomment this line, and then navigate via `cd $z`
export vols=/var/lib/docker/volumes
# export vad=$vols/apps-and-dbs-data/_data # create `apps-and-dbs-data` (or equivalent) via `docker volume <...>` then uncomment this line

# docker compose commands
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# VM memory management -- ref: https://askubuntu.com/a/1280347
alias free-ram='sync && echo 3 | sudo tee /proc/sys/vm/drop_caches***'
alias check-ram='free -h'
