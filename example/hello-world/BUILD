load("//cc_module:defs.bzl", "cc_module", "cc_module_binary")

cc_module(
    name = "hello",
    src = "hello.ixx",
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    deps = [
        ":_Builtin_stddef_max_align_t",
        ":std",
    ],
)

cc_module_binary(
    name = "a.out",
    srcs = [
        "main.cc",
    ],
    deps = [
        ":hello",
        ":_Builtin_stddef_max_align_t",
        ":std",
    ],
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    linkopts = [
        "-stdlib=libc++",
    ],
)

cc_module(
    name = "_Builtin_stddef_max_align_t",
    is_system = True,
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
)

cc_module(
    name = "std_config",
    is_system = True,
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    deps = [
        ":_Builtin_stddef_max_align_t",
    ],
)

cc_module(
    name = "std",
    is_system = True,
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    deps = [
        ":_Builtin_stddef_max_align_t",
        ":std_config",
    ],
)
