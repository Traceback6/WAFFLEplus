import argparse
import socket
import shlex
import subprocess
import sys
import textwrap
import threading


def parser():
    parser = argparse.ArgumentParser()
    # standard hardening (bundles pw complexity, updates, etc)
    # add flag for if machine needs hacking tools
    parser.add_argument("-c", "--decipher", action="store_true", help="decipher file")
    parser.add_argument("-f", "--find", action="store_true", help="find file")
    parser.add_argument("-g", "--group", action="store_true", help="edit groups")
    parser.add_argument("-p", "--path", action="store_true", help="specified path")
    parser.add_argument("-k", "--kill", action="store_true", help="kill user")
    return parser.parse_args()


print(parser())
