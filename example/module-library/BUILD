load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_module_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

cc_module(
    name = "a",
    src = "a.cc",
)

cc_module_library(
    name = "b",
    hdrs = [
        "b.h",
    ],
    srcs = [
        "b.cc",
    ],
    deps = [
        ":a",
    ],
)

cc_binary(
    name = "a.out",
    srcs = [
        "main.cc",
    ],
    deps = [
        ":b",
    ],
)
