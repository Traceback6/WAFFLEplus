import subprocess
def change_password_length(min_length):
    with open("/etc/pam.d","r") as file:
      data = file.readlines()
    data[25]+="minlen = 8"
    with open( "/etc/pam.d", "w") as file:
      file.writelines(data)
    file.close()
def change_password_age(min_age):
    subprocess.run(["sudo", "sed", "-i", f"s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS {min_age}/", "/etc/login.defs"])
def change_password_complexity(complexity):
    subprocess.run(["sudo", "sed", "-i", f"s/^PASS_COMPLEXITY.*/PASS_COMPLEXITY {complexity}/", "/etc/login.defs"])
def remove_wireshark():
  subprocess.run(["sudo", "apt-get", "remove", "--purge", "wireshark"])
  subprocess.run(["sudo", "apt-get", "autoremove"])
def update_firefox():
    subprocess.run(["sudo", "apt", "install","firefox"])
    #subprocess.run(["sudo", "apt-get", "install", "--only-upgrade", "firefox"])
def enable_ssh():
    subprocess.run(["sudo", "systemctl", "enable", "ssh"])
    subprocess.run(["sudo", "systemctl", "start", "ssh"])
def enable_firewall():
    subprocess.run(["sudo", "ufw", "enable"])
def disable_ctrl_alt_del():
    subprocess.run(["sudo", "sed", "-i", "/^exec uim-systray/a Exec=/bin/false", "/etc/lightdm/lightdm.conf"])
def update_os():
    subprocess.run(["sudo", "apt", "update"])
    subprocess.run(["sudo", "apt", "upgrade"])
    subprocess.run(["sudo", "apt", "full-upgrade"])
    subprocess.run(["sudo", "apt", "autoremove"])
def disable_guest_account():
    subprocess.run(["sudo", "usermod", "--expiredate", "1", "guest"])
"""change_password_length(10)
print("password lenght changed to 10")
change_password_age(7)
print("password age changed to 7")"""
#remove_wireshark()
print("wireshark removed")
#update_firefox()
print("firefox updated")
"""enable_ssh()
print("ssh enabled")
enable_firewall()
print("firewall enabled")# command sudo: ufw: not found
disable_ctrl_alt_del()
print("ctrl alt del disabled")
update_os()"""
print("os updated")#still in progress of making this work
"""disable_guest_account()
print("guest account disabled")"""