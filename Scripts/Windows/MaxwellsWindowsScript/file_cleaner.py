import os
import shutil

# File types to delete
fileTypes = [".jpg", ".png", ".aac", ".ac3", ".avi", ".aiff", ".bat", ".bmp", ".exe", ".flac", ".gif", ".jpeg", ".mov",
             ".m3u", ".m4p",
             ".mp2", ".mp3", ".mp4", ".mpeg4", ".midi", ".msi", ".ogg", ".png", ".txt", ".sh", ".wav", ".wma", ".vqf",
             ".pcap", ".zip",
             ".pdf", ".json"]

# Directory path to exclude (e.g., "Cyber Patriot Personnel")
user = os.getlogin()
exclude_directory = ["C://Program Files/Cyber Patriot Personnel", "C://Users//" + user + "//Desktop"]

# Directories to search through
userDirectories = ["C://Users"]
safe_folder = "C://Users//" + user + "Desktop//DELETEME"

# mkdir on desktop for files
os.mkdir(f"C://Users//{user}/Desktop//DELETEME")

for root_dir in userDirectories:
    for root, dirs, files in os.walk(root_dir):
        # Skip the exclude directory
        skip = False
        for thing in exclude_directory:
            if thing in root:
                skip = True
        if not skip:
            # Delete files of specified types
            for file in files:
                if any(file.endswith(ft) for ft in fileTypes):
                    file_path = os.path.join(root, file)
                    try:
                        shutil.move(file_path, safe_folder)
                        print(f"Deleted: {file_path}")
                    except Exception as e:
                        print(f"Failed to delete {file_path}: {e}")
