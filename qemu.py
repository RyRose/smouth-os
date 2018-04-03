import argparse
import subprocess
import sys
import os

def run_qemu(arch):
    subprocess.check_call(["qemu-system-{arch}".format(arch=arch),
                           "-cdrom",
                           "os.iso",
                           "-monitor",
                           "stdio",
                           "-s"
    ])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--arch", help="The guest architecture to run with.")
    args = parser.parse_args()
    run_qemu(args.arch)

if __name__ == "__main__":
    main()
