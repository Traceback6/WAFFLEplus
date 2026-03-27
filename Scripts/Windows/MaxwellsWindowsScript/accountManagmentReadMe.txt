Windows User Management
This Python script provides functions to manage local user accounts on a Windows machine. This script requires administrative privileges to run.

Prerequisites
This script requires Python 3.6 or higher to be installed on the Windows machine. Administrative privileges are also required to create, delete, or modify user accounts.

Functions
The following functions are provided by this script:

create_account(): This function creates a standard user account. The user is prompted to enter a username and password for the new account.

create_admin(): This function adds an existing user account to the Administrators group.

assign_account_to_group(): This function adds an existing user account to a specified group.

delete_account(): This function deletes an existing user account.

enable_disable_account(): This function enables or disables an existing user account.


Navigate to the directory containing the script.

Run the script using the following command:

Copy code
python Windows-User-Account-Management.py
Follow the prompts to perform user management tasks.

Example
To create a new user account, run the script and choose the Create Account option. Enter a username and password for the new account when prompted. The script will create the account and provide a success message if the operation is successful.

Disclaimer
Use this script at your own risk. The author is not responsible for any damages or losses that may result from the use of this script.