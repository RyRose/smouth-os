package(default_visibility = ['//visibility:public'])

filegroup(
    name ='i686-elf-gcc',
    srcs = [
          'i686-elf/bin/i686-elf-gcc',
        ],
)

filegroup(
    name ='i686-elf-g++',
    srcs = [
          'i686-elf/bin/i686-elf-g++',
        ],
)

filegroup(
    name ='i686-elf-ar',
    srcs = [
          'i686-elf/bin/i686-elf-ar',
        ],
)

filegroup(
    name ='i686-elf-ld',
    srcs = [
          'i686-elf/bin/i686-elf-ld',
        ],
)

filegroup(
    name ='i686-elf-nm',
    srcs = [
          'i686-elf/bin/i686-elf-nm',
        ],
)

filegroup(
    name ='i686-elf-objcopy',
    srcs = [
          'i686-elf/bin/i686-elf-objcopy',
        ],
)

filegroup(
    name ='i686-elf-objdump',
    srcs = [
          'i686-elf/bin/i686-elf-objdump',
        ],
)

filegroup(
    name ='i686-elf-strip',
    srcs = [
          'i686-elf/bin/i686-elf-strip',
        ],
)

filegroup(
    name ='i686-elf-as',
    srcs = [
          'i686-elf/bin/i686-elf-as',
        ],
)

filegroup(
    name ='i686-elf-compiler_pieces',
    srcs = glob([
          'i686-elf/i686-elf/**',
          'i686-elf/libexec/**',
          'i686-elf/lib/gcc/i686-elf/**',
          'i686-elf/include/**',
        ]),
)

filegroup(
    name ='i686-elf-compiler_components',
    srcs = [
          ':i686-elf-gcc',
          ':i686-elf-g++',
          ':i686-elf-ar',
          ':i686-elf-ld',
          ':i686-elf-nm',
          ':i686-elf-objcopy',
          ':i686-elf-objdump',
          ':i686-elf-strip',
          ':i686-elf-as',
        ],
)
