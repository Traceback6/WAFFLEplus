#script

from subprocess import run
#disable guest
run(["sudo", "usermod", "--expiredate", "1", "guest"])

# update system and apps
run(["sudo", "apt", "update"])
run(["sudo", "apt", "upgrade"])
run(["sudo", "apt", "full-upgrade")
run(["sudo", "apt", "autoremove")

#Install/enable UFW
run(["sudo", "apt", "get", "ufw"])
run(["sudo", "enable", "ufw"])
