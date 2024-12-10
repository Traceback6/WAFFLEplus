import audit_policies
import ctypes
import defender_updates
import firewall_config
import password_policies
import service_manaement
import uac_settings


def is_admin():
    try:
        admin = ctypes.windll.shell32.IsUserAnAdmin()
        if not admin:
            print("No no! Run me as admin, its better that way")
    except:
        return False


is_admin()

print("\033[0m\033[31m")
print("Begin computer fixing ;)")

print("running defender scan")
input("press enter to begin... ")
print("\033[0m")
defender_updates.run_windows_defender_scan()

print("\033[31m")
print("configuring firewall settings")
input("press enter to begin... ")
print("\033[0m")
firewall_config.enable_firewall()

print("\033[31m")
print("fix audit policies")
input("press enter to begin... ")
print("\033[0m")
audit_policies.configure_audit_policies()

print("\033[31m")
print("changing password policies")
input("press enter to begin... ")
print("\033[0m")
password_policies.configure_password_policies()

print("\033[31m")
print("running service management")
input("press enter to begin... ")
print("\033[0m")
service_manaement.manage_services()

print("\033[31m")
print("running software management")
input("press enter to begin... ")
print("\033[0m")
import software_management

print("\033[31m")
print("changing uac settings")
input("press enter to begin... ")
print("\033[0m")
uac_settings.configure_uac()

print("\033[31m")
print("WARNING! RUNNING FILE CLEANER. HOPE AND PRAY")
input("press enter to begin... ")
print("\033[0m")
import file_cleaner

print("\033[31m")
print("done. didn't run account mgmt, btw")
print("if you want ot try and update (might not work), type (y)yes")
ans = input("try update, (y)yes or no? ")
if ans == "y":
    print("attempting update")
    print("\033[0m")
    defender_updates.check_install_updates()
else:
    print("skipped. the end. if it wasn't enough, blame maxwell")

print("\033[0m")
