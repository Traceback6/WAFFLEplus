import subprocess


def configure_password_policies():
    password_policies = [
        "net accounts /minpwlen:8",
        "net accounts /maxpwage:30",
        "net accounts /minpwage:1",
        "net accounts /uniquepw:5",
        "net accounts /lockoutthreshold:5",
        "net accounts /lockoutduration:30",
        "net accounts /lockoutwindow:30"
    ]
    for policy in password_policies:
        subprocess.run(policy, shell=True, check=True)
        print(f"{policy} executed")


if __name__ == "__main__":
    configure_password_policies()
