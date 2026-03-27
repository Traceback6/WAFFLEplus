import subprocess


def configure_uac():
    subprocess.run(
        'powershell.exe -Command "Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System -Name ConsentPromptBehaviorAdmin -Value 2"',
        shell=True, check=True)
    print("UAC settings updated.")


if __name__ == "__main__":
    configure_uac()
