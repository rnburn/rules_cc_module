load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_module_binary")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

cc_module(
    name = "a",
    src = "a.cc",
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    deps = [
        ":b",
        ":_Builtin_stddef_max_align_t",
        ":std",
    ],
)

cc_module(
    name = "b",
    src = "b.cc",
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
    copts = [
        "-fmodules",
        "-fbuiltin-module-map",
        "-stdlib=libc++",
        "-std=c++20",
    ],
    deps = [
        ":a",
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
