import subprocess

argsList = ["update", "upgrade", "dist-upgrade", "autoremove", "autoclean", "install"]


def apt(option: str, *package: str):
    subprocess.run(["sudo", "apt-get", option])


for o in argsList:
    apt(o)
