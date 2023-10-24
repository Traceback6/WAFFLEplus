import argparse
import socket
import shlex
import subprocess
import sys
import textwrap
import threading


def execute(cmd):
    cmd = cmd.strip()
    if not cmd:
        return
    output = subprocess.check_output(shlex.split(cmd), stderr=subprocess.STDOUT)
    return output.decode()


class CPscr:
    def __init__(self, args, buffer=None):
        self.args = args
        self.buffer = buffer

    def run():
        return


def create_parser():
    parser = argparse.ArgumentParser(
        description="Automated Cyberpatriot",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent(
            """Example:
	cpscr.py -c b64 -p="Desktop/enciphered.txt" 
	cpscr.py -f mp3
	cpscr.py -g userGroup -a candace,wendy    #add users to a group
	cspcr.py -g otherGroup -r bofa,wallocomb    #remove users from group
	cspcr.py -k rmomuy
	"""
        ),
    )
    parser.add_argument("-c", "--decipher", action="store_true", help="decipher file")
    parser.add_argument("-f", "--find", action="store_true", help="find file")
    parser.add_argument("-g", "--group", action="store_true", help="edit groups")
    parser.add_argument("-p", "--path", action="store_true", help="specified path")
    parser.add_argument("-k", "--kill", action="store_true", help="kill user")
    return parser.parse_args()


print(create_parser())
print("hello")
"""args = create_parser()
if args.listen:
	buffer = ''
else:
	buffer = sys.stdin.read()

print(args)
sc = CPscr(args, buffer.encode())
sc.run()"""
