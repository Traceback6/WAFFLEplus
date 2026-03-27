import subprocess


def manage_services():
    services_to_disable = [
        "TermService", "SharedAccess", "UmRdpService", "ftpsvc",
        "RemoteRegistry", "SessionEnv", "SSDPSRV", "upnphost", "W3SVC",
        "sshd"
    ]
    for service in services_to_disable:
        print(f"Stopping {service}")
        try:
            subprocess.run(f'net stop {service}', shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(e)
            print(f"Failed to stop {service}")

        try:
            subprocess.run(f'sc config {service} start= disabled', shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(e)
            print(f"Failed to disable {service}")
    print("Disabled and stopped unnecessary services.")


if __name__ == "__main__":
    manage_services()
