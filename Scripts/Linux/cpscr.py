import argparse
import socket
import shlex
import subprocess
import sys
import textwrap
import threading


parser = argparse.ArgumentParser()
# standard hardening (bundles pw complexity, updates, etc)
# add flag for if machine needs hacking tools
#   parser.add_argument("-c", "--decipher", action="store_true", help="decipher file")
parser.add_argument("-e", "--execute", action="store_true", help="execute command")
parser.add_argument("-f", "--find", action="store_true", help="find file")
parser.add_argument("-g", "--group", action="store_true", help="edit groups")
parser.add_argument("-p", "--path", action="store_true", help="specified path")
parser.add_argument("-k", "--kill", action="store_true", help="kill user")

args = parser.parse_args()





print(parser())


git config --global user.email "you@example.com"
  git config --global user.name "Your Name"