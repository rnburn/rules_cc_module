load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_header_module", "cc_module_binary")

package(default_visibility = ["//visibility:public"])

cc_header_module(
    name = "a_hdr",
    hdr = "a.h",
)

cc_module(
    name = "b",
    src = "b.cc",
    deps = [
        ":a_hdr",
    ],
    copts = [
        "-fmodules-ts",
        "-std=c++20",
    ],
)

cc_module_binary(
    name = "a.out",
    srcs = ["main.cc"],
    deps = [
        ":b",
    ],
    copts = [
        "-fmodules-ts",
        "-std=c++20",
    ],
)
