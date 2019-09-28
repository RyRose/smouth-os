import argparse
import subprocess
import sys
import os

AVAILABLE_ARCHITECTURES = ["i386"]
AVAILABLE_OUTPUT = ["serial", "monitor", "gdb"]


def run_qemu(arch, kernel, output, workspace_file):
    args = ["qemu-system-{arch}".format(arch=arch), "-kernel", kernel]
    args.extend({
        "monitor": ["-monitor", "stdio"],
        "serial": ["-nographic"],
        "gdb": ["-S", "-s"],
    }[output])
    if output == "gdb":
        qemu = subprocess.Popen(args,
                                stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL)
        try:
            subprocess.run([
                "gdb",
                "-ex",
                "file {}".format(kernel),
                "-ex",
                "target remote :1234",
                "-ex",
                "layout split",
                "-d",
                open(workspace_file).read().strip().strip("'"),
            ],
                           check=True,
                           stdin=sys.stdin,
                           stdout=sys.stdout,
                           stderr=sys.stderr)
        finally:
            qemu.terminate()

    else:
        subprocess.check_call(args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cpu",
                        help="The guest architecture to run with.",
                        choices=AVAILABLE_ARCHITECTURES)
    parser.add_argument("--kernel", help="Path to the kernel to boot.")
    parser.add_argument(
        "--workspace_file",
        help=
        "File containing path to the root directory containing source code.")
    parser.add_argument("--output",
                        help="Method of displaying output from QEMU.",
                        choices=AVAILABLE_OUTPUT)
    args = parser.parse_args()
    run_qemu(args.cpu, args.kernel, args.output, args.workspace_file)


if __name__ == "__main__":
    main()
