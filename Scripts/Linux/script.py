#script

from subprocess import run
#disable guest
run(["sudo", "usermod", "--expiredate", "1", "guest"])

# update system and apps
run(["sudo", "apt", "update"])
run(["sudo", "apt", "upgrade"])
run(["sudo", "apt", "full-upgrade"])
run(["sudo", "apt", "autoremove"])

#Install Security tools
run(["sudo", "apt-get", "ufw"])
run(["sudo", "enable", "ufw"])
run(["sudo", "apt", "update", "&&", "sudo", "apt", "Upgrade", "-y"])
run(["sudo", "apt-get", "install", "openssh-server"])
run(["sudo", "apt-get", "update", "-y"])
run(["sudo", "apt-get", "install", "y-", "bum"])
#disable ctrl+alt+delete
run(["sudo", "sed", "-i", "/^exec uim-systray/a Exec=/bin/false", "/etc/lightdm/lightdm.conf",])

# Password complexity requirement.
#remove wireshark if its installed (User is responsible for figuring out if wireshark exists.)
WireRemove = input("Does wireshark exist and need to be deleted?: ")
if (WireRemove == "y" or WireRemove == "Y"):
    run(["sudo", "apt-get", "remove", "--purge", "wireshark"])
    run(["sudo", "apt-get", "autoremove"])

#update firefox
FoxUpdate = input("Does FireFox need updated?: ")
if (FoxUpdate == "y" or FoxUpdate == "Y"):
    run(["sudo", "apt", "install", "firefox"])
#enable SSH
sshEnable = input("Does ssh need enabled?: ")
if (sshEnable == "y" or sshEnable == "Y"):
    run(["sudo", "systemctl", "enable", "ssh"])
    run(["sudo", "systemctl", "start", "ssh"])
#change minimum password age
#change min password length
