
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_module_binary")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

cc_module(
    name = "algorithm",
    src = "algorithm.cc",
    copts = [
        "-fmodules-ts",
        "-std=c++20",
    ],
)

cc_module_binary(
    name = "a.out",
    srcs = [
        "main.cc",
    ],
    deps = [
        ":algorithm",
    ],
    copts = [
        "-fmodules-ts",
        "-std=c++20",
    ],
)
