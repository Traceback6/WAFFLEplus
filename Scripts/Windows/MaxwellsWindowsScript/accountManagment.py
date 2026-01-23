import ctypes
import logging
import subprocess
import sys
from datetime import datetime
from getpass import getpass

# Set up logging
logging.basicConfig(filename='account-management.log', level=logging.INFO)

# log account creation
now = datetime.now()


# Checks if the user running the script has administrator privileges
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def create_account():
    """Creates local accounts"""
    username = input("Enter username: ")
    password = check_password()

    create_account_cmd = f"net user {username} {password} /add"
    run_cmd(create_account_cmd, f"User {username} created successfully.", f"Error creating user {username}.",
            f"Create user {username} {now}", f"Failed to create {username} {now}")


def create_admin():
    """Creates local admin accounts"""
    account_name = input("What account do you want to make an admin: ")
    make_admin_cmd = f"net localgroup administrators {account_name} /add"

    run_cmd(make_admin_cmd, f"{account_name} is now apart of administrator group", f"Error making {account_name} admin",
            f" {account_name} is now administrator {now}", f"Failed to create {account_name} {now}")


def assign_account_to_group():
    """Assign account to group"""
    get_groups_cmd = "net localgroup"

    run_cmd(get_groups_cmd, "All groups are listed", "Error getting groups", f"Get all users {now}",
            f"Failed to get all user {now}")


def remove_account_from_group():
    """Remove user from assigned group"""
    print("Remove user from group")

    username = input("Enter username: ")
    group = input(f"Remove {username} from: ")
    command = f"net localgroup \"{username}\" " f"\"{group}\" /DELETE"

    run_cmd(command, f"Removed {username} from {group}", f"Failed to remove {username} from {group}",
            f"Successfully removed {username} from {group} {now}")


def check_password():
    """Verifies password to create account"""
    password = getpass("Enter password for account: ")
    check_password = getpass("Enter password again: ")

    while password != check_password:
        print("Passwords do not match")
        password = getpass("Enter password for account: ")
        check_password = getpass("Enter password again: ")

    return password


def delete_account():
    """Deletes local account off computer"""
    command = "net user"
    run_cmd(command, "Got all users successfully", "Failed to get all users", f"All users {now}",
            f"Failed to get all {now}")

    # Removes \n and other text from the net user command
    try:
        all_accounts = subprocess.run(command, check=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        if all_accounts.returncode == 0:
            print("All Local Accounts are listed")
            for accounts in all_accounts.stdout.decode().splitlines():
                if accounts:
                    print(accounts)
        else:
            print(f"Error getting accounts")
    except subprocess.CalledProcessError as e:
        print(f"Error getting all accounts.")
        print(e.stderr.decode())

    username = input("Account to delete: ")
    delete_account_command = f"net user {username} /DELETE"

    run_cmd(delete_account_command, "Account successfully deleted", "Error deleting account",
            f"Successfully delete {username} account", f"Failed to delete {username}")


def enable_disable_account():
    """Enables or Disable accounts on machine"""
    ask_to_enable_disable = input("Would you like to enable or disable: ")
    username = input("Enter the username: ")
    enable_account_command = f"net user {username} /ACTIVE:yes"
    disable_account_command = f"net user {username} /ACTIVE:no"

    if ask_to_enable_disable == "enable":
        try:
            enable_account = subprocess.run(enable_account_command, check=True, shell=True, stdout=subprocess.PIPE,
                                            stderr=subprocess.PIPE)

            if enable_account.returncode == 0:
                print(f"{username} was successfully enabled")
            else:
                print("Failed to enable account")
                logging.info(f"Failed to enable account: {username} {now}")
        except subprocess.CalledProcessError as e:
            print("An error has happened when enabling account")
            print(e.stderr.decode())

    if ask_to_enable_disable == "disable":
        try:
            disable_account = subprocess.run(disable_account_command, check=True, shell=True, stdout=subprocess.PIPE,
                                             stderr=subprocess.PIPE)

            if disable_account.returncode == 0:
                print(f"{username} was successfully disabled")
            else:
                print("Failed to disabled account")
                logging.info(f"Failed to disable account {username} {now}")
        except subprocess.CalledProcessError as e:
            print("An error has happened when disabling account")
            print(e.stderr.decode())


def disable_defualt_accounts():
    disable_guest_account = "net user Guest /active:no"
    disable_admin_account = "net user Administrator /active:no"

    run_cmd(disable_guest_account, "Guest account is disabled", "Failed to disable Guest account",
            f"Guest is now disabled {now}", f"Failed to disable Guest account {now}")
    run_cmd(disable_admin_account, "Administrator account is disabled", "Failed to disable Administrator account",
            f"Administrator is now disabled {now}", f"Failed to disable Administrator account {now}")


def login_times():
    """Allows user to set up login restrictions for accounts"""
    username = input("Enter account name: ")
    days = input(f"Enter the days for {username} (ex M-F): ")
    times = input(f"Enter the times for the {username} (9am-5pm)")

    command = f"net user {username} /times:{days},{times}"

    run_cmd(command, f"{username} is now active during {days} and {times}", "Failed to setup login times",
            f"{username} can now login during {days} {times} {now}")


def all_groups_for_user():
    print("See all groups that belong to the user")
    username = input("Enter username: ")
    command = f"net user {username} | findstr \"Local Group Memberships\""

    run_cmd(command, "Got all user groups", "Failed to get all user assigned groups",
            f"{username} asspcoated groups listed {now}",
            f"Failed to get all {username} associated groups listed {now} ")


def run_cmd(cmd, success_msg, error_msg, success_log_msg, failed_log_msg):
    try:
        result = subprocess.run(cmd, check=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        if result.returncode == 0:
            print(success_msg)
            logging.info(success_log_msg)
        else:
            print(error_msg)
            print(result.stderr.decode())
            logging.critical(failed_log_msg)

    except subprocess.CalledProcessError as e:
        print(error_msg)
        print(e.stderr.decode())
        logging.error(failed_log_msg)


if is_admin():
    # Code of your program here
    try:
        print("ctrl-c to quit")

        while True:
            print("1. Create account \t\t    2. Make account admin")
            print("3. Manually add to group \t    4. Delete account")
            print("5. Enable/Disable Accounts \t    6. Disable defualt accounts")
            print("7. Listed associated groups to user 8. quit")
            print("-" * 50)

            # Valildates the user entered a number
            try:
                choice = int(input("Your choice: "))
            except ValueError:
                print("Please enter a number")
                continue

            options = {
                1: create_account,
                2: create_admin,
                3: assign_account_to_group,
                4: delete_account,
                5: enable_disable_account,
                6: disable_defualt_accounts,
                7: all_groups_for_user,
                8: quit,
            }

            # Runs the funciton based of user input
            if choice in options:
                options[choice]()
            else:
                print("Please enter a valid choice (1-6)")

            # Asks if the user want to change their choice
            switch_choice = input("Do you want to switch choice? (y/n) ")
            if switch_choice.lower() == "y":
                if choice == 1 or choice == 2 or choice == 3:
                    continue
            elif switch_choice.lower() == "n":
                while True:
                    options[choice]()
            else:
                break

    except KeyboardInterrupt:
        quit()
else:
    # Re-run the program with admin rights
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)

input("Press enter to exit")
