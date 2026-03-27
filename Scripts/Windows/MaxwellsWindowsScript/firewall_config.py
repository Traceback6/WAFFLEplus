import subprocess


def enable_firewall():
    subprocess.run(["powershell", "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True"])
    print("Firewall enabled.")


if __name__ == "__main__":
    enable_firewall()
