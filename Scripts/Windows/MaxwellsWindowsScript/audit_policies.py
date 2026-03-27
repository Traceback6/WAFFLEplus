import subprocess

policies = [
    "Account Logon",
    "Account Management",
    "Detailed Tracking",
    "DS Access",
    "Logon/Logoff",
    "Object Access",
    "Policy Change",
    "Privilege Use",
    "System"
]


def configure_audit_policies():
    audit_policy_mapping = policies.copy()
    command_template = 'auditpol /set /category:"{}" /success:enable /failure:enable'

    for policy_name in audit_policy_mapping:
        command = command_template.format(policy_name)
        print(command)
        try:
            subprocess.run(command, shell=True, check=True)
            print(f"{command} executed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Error executing {command}: {e}")


if __name__ == "__main__":
    configure_audit_policies()
