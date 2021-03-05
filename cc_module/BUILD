load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

exports_files([
    "defs.bzl",
])

bzl_library(
    name = "rules",
    srcs = glob(["**/*.bzl"]),
    deps = [
        # "//cc_module/platform:rules",
        # "//cc_module/private:rules",
    ],
)
