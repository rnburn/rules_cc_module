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

"""Example showing how to create a rule that just compiles C sources."""

load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:toolchain_utils.bzl", "find_cpp_toolchain")

MyCCompileInfo = provider(doc = "", fields = ["object"])

DISABLED_FEATURES = [
#     "module_maps",  # copybara-comment-this-out-please
]

def _cc_module_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    source_file = ctx.file.src
    output_file = ctx.actions.declare_file(source_file.basename + ".o")

    # output_cmi_dir = ctx.actions.declare_directory("gcm.cache", sibling=output_file)
    output_cmi = ctx.actions.declare_file(ctx.label.name + ".gcm", sibling=output_file)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = DISABLED_FEATURES + ctx.disabled_features,
    )
    c_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = C_COMPILE_ACTION_NAME,
    )
    c_compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts + ["-fmodules-ts", "-std=c++20"],
        source_file = source_file.path,
        output_file = output_file.path,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = C_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )
    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = C_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )

    copy_args = [
        "--copy-output",
        "gcm.cache/%s.gcm" % ctx.label.name,
        output_cmi.path,
    ]

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = copy_args + ["--", c_compiler_path] + command_line,
        env = env,
        inputs = depset(
            [source_file],
            transitive = [cc_toolchain.all_files],
        ),
        outputs = [output_file, output_cmi],
    )
    return [
        DefaultInfo(files = depset([output_file])),
        MyCCompileInfo(object = output_file),
    ]

cc_module = rule(
    implementation = _cc_module_impl,
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
        "_process_wrapper": attr.label(
            default = Label("//util/process_wrapper"),
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        )
    },
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)
