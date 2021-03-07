load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_module_binary")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

cc_module(
    name = "a",
    src = "a.cc",
    deps = [
        ":b",
    ],
)

cc_module(
    name = "b",
    src = "b.cc",
)

cc_module_binary(
    name = "a.out",
    srcs = [
        "main.cc",
    ],
    deps = [
        ":a",
    ],
)
