import os
import shutil
import subprocess


def deleteDirectories(listA, listB):
    malwareList = ["Wireshark", "Npcap"]
    for dir in listA:
        if dir in malwareList:
            print(dir)
            shutil.rmtree(f"C:/Program Files/{dir}")
    for dir in listB:
        if dir in malwareList:
            shutil.rmtree(f"C:/Program Files (x86)/{dir}")


softwareListPF = os.listdir("C:/Program Files")
softwareList86 = os.listdir("C:/Program Files (x86)")
print(f"Collected Software: {softwareListPF} {softwareList86}")
deleteDirectories(softwareListPF, softwareList86)
