py_binary(
  name = "qemu",
  srcs = [
    "qemu.py"
  ],
  data = [
    "//kernel"
  ],
  args = [
    "--cpu=$(TARGET_CPU)",
    "--kernel=$(location //kernel)"
  ]
)
