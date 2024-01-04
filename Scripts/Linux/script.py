# script

from subprocess import run
# errorCheck
fail = []

# disable guest
try :
    run(["sudo", "usermod", "--expiredate", "1", "guest"])
except:
    fail.append("couldn't dissable guest")


# update system and apps
try:
    run(["sudo", "apt", "update"])
    run(["sudo", "apt", "upgrade"])
    run(["sudo", "apt", "full-upgrade"])
    run(["sudo", "apt", "autoremove"])
except:
    fail.append("couldn't update system/apps")


# Install Security tools
try:
    run(["sudo", "apt-get", "ufw"])
    run(["sudo", "enable", "ufw"])
except:
    fail.append("couldn't enable ufw")

try:
    run(["sudo", "apt", "update", "&&", "sudo", "apt", "Upgrade", "-y"])
    run(["sudo", "apt-get", "install", "openssh-server"])
    run(["sudo", "apt-get", "update", "-y"])
    run(["sudo", "apt-get", "install", "y-", "bum"])
except:
    fail.append("couldn't install security tools")


# disable ctrl+alt+delete
try:
    run(["sudo", "sed", "-i", "/^exec uim-systray/a Exec=/bin/false", "/etc/lightdm/lightdm.conf", ])
except:
    fail.append("couldn't dissable ctrl+alt+delete")

# Password complexity requirement.
# remove wireshark if its installed (User is responsible for figuring out if wireshark exists.)
try:
    WireSharkRemove = input("Does wireshark exist and need to be deleted? y/n: ")
    if (WireSharkRemove == "y" or WireSharkRemove == "Y"):
        run(["sudo", "apt-get", "remove", "--purge", "wireshark"])
        run(["sudo", "apt-get", "autoremove"])
except:
    fail.append("couldn't delete wireshark")

# update firefox
try:
    FoxUpdate = input("Does FireFox need updated? y/n: ")
    if (FoxUpdate == "y" or FoxUpdate == "Y"):
        run(["sudo", "apt", "install", "firefox"])
except:
    fail.append("failed to update firefox")

# enable SSH
try:
    sshEnable = input("Does ssh need enabled? y/n: ")
    if (sshEnable == "y" or sshEnable == "Y"):
        run(["sudo", "systemctl", "enable", "ssh"])
        run(["sudo", "systemctl", "start", "ssh"])
except:
    fail.append("couldn't enable ssh")


# change minimum password age
# change min password length

# update insecure passwords
try:
    usrPswdUpdt = input("Are there any users who need their password updated y/n: ")
    if (usrPswdUpdt == "y" or usrPswdUpdt == "Y"):
        UsrCount = int(input(" how many users need their password changed? : "))
        for count in range(1 , UsrCount + 1):
            try:
                UsrNme = input("Who needs their password changed? Name is caps specific. :")
                run(["sudo", "passwd", UsrNme])
            except:
                fail.append("unable to change "+UsrNme+"'s password")
except:
    fail.append("Failed to update passwords")


# groups
try:
    groups = input("do we need to make any groups? y/n:")
    if (groups == "y" or groups == "Y"):
        newGroupName = input("What is the new groups name?: ")
        newGroupQuan = input("How many people are in the group?: ")
        run(["sudo", "groupadd", newGroupName])
        for num in range(1 , int(newGroupQuan) + 1):
            newGroupMember = input("Who is being added to the group? Please enter one user at a time: ")
            run(["sudo", "usermod", "-a", "-g", newGroupName, newGroupMember])
except:
    fail.append("Failed to add groups or users")

try:
    groups = input("do you need to add anyone to a group that already exists? y/n: ")
    if (groups == "y" or groups == "Y"):
        groupname = input("What is the groups name?: ")
        groupnum = input("How many people are being added?: ")
        for count in range(1 , int(groupnum) + 1):
            groupmem = input("Who is being added to the group? One user at a time.: ")
            run(["sudo", "usermod", "-a", "-g", groupname, groupmem])
except:
    fail.append("Failed to add members")


# delete users
try:
    deluser = input("Are there any users who need to be removed from the computer? y/n: ")
    if (deluser == "y" or deluser == "Y"):
        delusercount = int(input("How many users need deleted?: "))
        for number in range(1 , delusercount + 1):
            delusername = input("What is the name of the account being deleted? Use one name at a time.: ")
            run(["sudo", "userdel", delusername])
except:
    fail.append("Failed to delete users")


# add new users
try:
    useradd = input("do you need to add any users? y/n: ")
    if (useradd == "y" or useradd == "Y"):
        newUserCount = int(input("How many users do you need to add?: "))
        for all in range(1 , newUserCount + 1):
            newUserName = input("What is the name of the new user?: ")
            run(["sudo", "useradd", newUserName])
except:
    fail.append("Failed to add new Users")

print(fail)
