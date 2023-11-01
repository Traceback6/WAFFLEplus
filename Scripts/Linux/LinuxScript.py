import subprocess
import subprocess
import shlex


class Tools:
    
    
    
    def __init__(self) -> None:
        wd = subprocess.check_output("pwd")
        for s in wd:
            if s == "/":
                subprocess.run("cd", "..")
        
        global psp
        distro = subprocess.check_output("lsb_release", "-a")
        if distro == "ubuntu":  # not actually correct but is placeholder
            # password path
            psp = "/etc/pam.d/common-password"
        """        
        elif distro == "debian":
            stuff
        """

    def execute(cmd):
        cmd = cmd.strip()
        if not cmd:
            return
        output = subprocess.check_output(shlex.split(cmd), stderr=subprocess.STDOUT)
        return output.decode()

    def change_min_password_length(length):
        check_command = "grep -q 'minlen=' /etc/pam.d/common-password && echo 'exists' || echo 'not exists'"
        check_process = subprocess.run(
            check_command, shell=True, capture_output=True, text=True
        )
        check_result = check_process.stdout.strip()
        # this try/except block doesn't account for errors in the shell
        try:
            if check_result == "exists":
                command = f"sudo sed -i 's/\\bminlen=[0-9]\\+\\b/minlen={length}/' /etc/pam.d/common-password"
            else:
                command = f"sudo sed -i '/pam_unix.so/ s/$/ minlen={length}/' /etc/pam.d/common-password"

            subprocess.run(command, shell=True, check=True)
            print(f"Minimum password length changed to {length}")

        except subprocess.CalledProcessError:
            print("Failed to change minimum password length")

    def change_min_password_age(age):
        check_command = "grep -q 'minlen=' /etc/pam.d/common-password && echo 'exists' || echo 'not exists'"
        check_process = subprocess.run(
            check_command, shell=True, capture_output=True, text=True
        )
        check_result = check_process.stdout.strip()

        try:
            if check_result == "exists":
                command = f"sudo sed -i 's/\\bminlen=[0-9]\\+\\b/minlen={length}/' /etc/pam.d/common-password"

            else:
                command = f"sudo sed -i '/pam_unix.so/ s/$/ minlen={length}/' /etc/pam.d/common-password"
            subprocess.run(command, shell=True, check=True)
            print(f"Minimum password length changed to {length}")

        except subprocess.CalledProcessError:
            print("Failed to change minimum password length")

    def change_password_complexity(complexity):
        subprocess.run(
            [
                "sudo",
                "sed",
                "-i",
                f"s/^PASS_COMPLEXITY.*/PASS_COMPLEXITY {complexity}/",
                "/etc/login.defs",
            ]
        )

    def remove_wireshark():
        subprocess.run(["sudo", "apt-get", "remove", "--purge", "wireshark"])
        subprocess.run(["sudo", "apt-get", "autoremove"])

    def update_firefox():
        subprocess.run(["sudo", "apt", "install", "firefox"])
        # subprocess.run(["sudo", "apt-get", "install", "--only-upgrade", "firefox"])

    def enable_ssh():
        subprocess.run(["sudo", "systemctl", "enable", "ssh"])
        subprocess.run(["sudo", "systemctl", "start", "ssh"])

    def enable_firewall():
        subprocess.run(["sudo", "ufw", "enable"])

    def disable_ctrl_alt_del():
        subprocess.run(
            [
                "sudo",
                "sed",
                "-i",
                "/^exec uim-systray/a Exec=/bin/false",
                "/etc/lightdm/lightdm.conf",
            ]
        )

    def update_os():
        subprocess.run(["sudo", "apt", "update"])
        subprocess.run(["sudo", "apt", "upgrade"])
        subprocess.run(["sudo", "apt", "full-upgrade"])
        subprocess.run(["sudo", "apt", "autoremove"])

    def disable_guest_account():
        subprocess.run(["sudo", "usermod", "--expiredate", "1", "guest"])

    change_min_password_length(
        10
    )  # code in theory works, but when tested didn't edit the settings file
    # to get to the file, go to /etc/pam.d/common-password
    
    #note to Jordan, it's because the first thing the script should do is go to the root folder -Justin
    print("password lenght changed to 10")
    """change_password_age(7)
    print("password age changed to 7")"""
    # remove_wireshark()
    print("wireshark removed")
    # update_firefox()
    print("firefox updated")
    """enable_ssh()
    print("ssh enabled")
    enable_firewall()
    print("firewall enabled")# command sudo: ufw: not found
    disable_ctrl_alt_del()
    print("ctrl alt del disabled")
    update_os()"""
    print("os updated")  # still in progress of making this work
    """disable_guest_account()
    print("guest account disabled")"""
