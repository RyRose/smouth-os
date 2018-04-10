import argparse
import subprocess
import sys
import os

AVAILABLE_ARCHITECTURES=["i386"]

def run_qemu(arch, kernel):
  subprocess.check_call(["qemu-system-{arch}".format(arch=arch),
                         "-kernel",
                         kernel,
                         "-monitor",
                         "stdio",
                         "-s"
  ])


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--arch", help="The guest architecture to run with.",
      choices=AVAILABLE_ARCHITECTURES)
  parser.add_argument("--kernel", help="Path to the kernel to boot.")
  args = parser.parse_args()
  run_qemu(args.arch, args.kernel)

if __name__ == "__main__":
  main()
