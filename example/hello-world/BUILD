load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//cc_module:defs.bzl", "cc_module", "cc_module_binary")

# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Example showing how to create a custom Starlark rule that just compiles C sources
licenses(["notice"])

cc_module(
    name = "Hello",
    src = "say_hello.cc",
)

cc_module_binary(
    name = "h",
    srcs = [
        "main.cc",
    ],
)

# cc_binary(
#     name = "h",
#     srcs = [
#         "main.cc",
#     ],
# )
