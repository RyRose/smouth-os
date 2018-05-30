py_binary(
    name = "qemu",
    srcs = [
        "qemu.py",
    ],
    args = [
        "--cpu=$(TARGET_CPU)",
        "--kernel=$(location //kernel)",
    ],
    data = [
        "//kernel",
    ],
)
