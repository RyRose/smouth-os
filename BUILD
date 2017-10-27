genrule(
  name = "iso",
  srcs = [
    "//kernel",
    "//tools:configs/grub.cfg"
  ],
  outs = [
    "os.iso",
    "isodir/boot/grub/grub.cfg",
    "isodir/boot/kernel",
  ],
  cmd = "cp $(location //kernel) $(location isodir/boot/kernel); cp $(location //tools:configs/grub.cfg) $(location isodir/boot/grub/grub.cfg); grub2-mkrescue -o $(location os.iso) $$(dirname $$(dirname $(location isodir/boot/kernel)));",
)
