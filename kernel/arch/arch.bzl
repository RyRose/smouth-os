
def arch_library(name, visibility=None):
  native.exports_files([name + ".h"])
  native.cc_library(
    name = name,
    hdrs = [name + ".h"],
    deps = select({
      "//tools:i386" : ["//kernel/arch/i386/" + name],
      "//conditions:default" : ["//kernel/arch/local/" + name]
    }),
    visibility = visibility
  )
