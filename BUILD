py_binary(
  name = "qemu",
  srcs = [
    "qemu.py"
  ],
  data = [
    "//kernel"
  ],
  args = [
    "--arch=$(TARGET_CPU)",
    "--kernel=$(location //kernel)"
  ]
)
