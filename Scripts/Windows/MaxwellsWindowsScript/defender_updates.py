import subprocess


# Function to run a quick scan using Windows Defender
def run_windows_defender_scan():
    # Define the command to start a quick scan using PowerShell
    command = ["powershell", "Start-MpScan", "-ScanType", "QuickScan"]
    # Execute the command and capture output
    result = subprocess.run(command, capture_output=True, text=True)
    # Check if the scan was successful
    if result.returncode == 0:
        print("Quick scan completed successfully.")
        print(result.stdout)  # Print the output from the scan
    else:
        print("Quick scan failed.")
        print(result.stderr)  # Print any error message if the scan failed


# Function to check for and install Windows updates
def check_install_updates():
    try:
        print("Checking for updates...")
        # Initiate an update check using the 'usoclient' command
        subprocess.run(["wuauclt", "/detectnow"])
        print("Update check initiated.")

        print("Installing updates...")
        # Initiate update installation using 'usoclient' command
        subprocess.run(["wuauclt", "/updatenow"])
        print("Update installation initiated.")
    except subprocess.CalledProcessError as e:
        # Handle any errors during update check or installation
        print(f"Failed to check or install updates: {e}")


# Main section to execute the functions
if __name__ == "__main__":
    run_windows_defender_scan()  # Run the quick scan function
    check_install_updates()  # Run the update check and installation function
