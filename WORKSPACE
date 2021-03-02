workspace(name = "com_github_rnburn_bazel_cpp20_modules")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_skylib",
    commit = "f80bc733d4b9f83d427ce3442be2e07427b2cc8d",
    remote = "http://github.com/bazelbuild/bazel-skylib"
)

git_repository(
    name = "rules_cc",
    commit = "d5d830baafdf0c6f95d7af1577dbaa610fa76a92",
    remote = "http://github.com/bazelbuild/rules_cc",
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
