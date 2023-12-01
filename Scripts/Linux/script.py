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
run(["sudo", "apt-get", "Clamav"])
run(["sudo", "apt-get", "Openssh-server"])
run(["sudo", "apt-get", "libpam-cracklib"])
run(["sudo", "apt-get", "bum"])
#disable ctrl+alt+delete
run(["sudo", "sed", "-i", "/^exec uim-systray/a Exec=/bin/false", "/etc/lightdm/lightdm.conf",])

# Password complexity requirement.
run(["sudo", "sed", "-i", f"s/^PASS_COMPLEXITY.*/PASS_COMPLEXITY {complexity}/", "/etc/login.defs"])

#remove wireshark if its installed (User is responsible for figuring out if wireshark exists.)
WireRemove = input("Does wireshark exist and need to be deleted?: ")
if (WireRemove == "yes" or WireRemove == "Yes"):
    run(["sudo", "apt-get", "remove", "--purge", "wireshark"])
    run(["sudo", "apt-get", "autoremove"])

#update firefox
FoxUpdate = input("Does FireFox need updated?: ")
if (FoxUpdate == "yes" or FoxUpdate == "Yes"):
    run(["sudo", "apt", "install", "firefox"])
#enable SSH
sshEnable = input("Does ssh need enabled?: ")
if (sshEnable == "yes" or sshEnable == "Yes"):
    run(["sudo", "systemctl", "enable", "ssh"])
    run(["sudo", "systemctl", "start", "ssh"])
#change minimum password age
#change min password length
check_command = "grep -q 'minlen=' /etc/pam.d/common-password && echo 'exists' || echo 'not exists'"
check_process = subprocess.run(check_command, shell=True, capture_output=True, text=True)
check_result = check_process.stdout.strip()

try:
    if check_result == 'exists':
        command = f"sudo sed -i 's/\\bminlen=[0-9]\\+\\b/minlen={length}/' /etc/pam.d/common-password"
    else:
        command = f"sudo sed -i '/pam_unix.so/ s/$/ minlen={length}/' /etc/pam.d/common-password"
        subprocess.run(command, shell=True, check=True)
        print(f"Minimum password length changed to {length}")

except subprocess.CalledProcessError:
    print("Failed to change minimum password length")

