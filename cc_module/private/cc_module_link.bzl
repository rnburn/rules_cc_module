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

load("@rules_cc//cc:action_names.bzl", "CPP_LINK_EXECUTABLE_ACTION_NAME")
load("@rules_cc//cc:toolchain_utils.bzl", "find_cpp_toolchain")

ModuleCompileInfo = provider(doc = "", fields = ["object", "module"])

def _create_linking_context(ctx, cc_toolchain, feature_configuration, objs):
    library = cc_common.create_library_to_link(
        actions = ctx.actions, 
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        objects=objs)
    linker_inputs = cc_common.create_linker_input(
        ctx.label, 
        libraries = [library])
    return cc_common.create_linking_context(
        linker_inputs = depset(linker_inputs, order = "topological"),
    )

def cc_module_link_action(ctx, objs, output):
    cc_toolchain = find_cpp_toolchain(ctx)
    exe = ctx.actions.declare_file(output)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    # linker_path = cc_common.get_tool_for_action(
    #     feature_configuration = feature_configuration,
    #     action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
    # )
    # link_variables  = cc_common.create_link_variables(
    #     feature_configuration = feature_configuration,
    #     cc_toolchain = cc_toolchain,
    #     output_file = exe.path,
    #     is_using_linker = True,
    # )
    # command_line = cc_common.get_memory_inefficient_command_line(
    #     feature_configuration = feature_configuration,
    #     action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
    #     variables = link_variables,
    # )

    # env = cc_common.get_environment_variables(
    #     feature_configuration = feature_configuration,
    #     action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
    #     variables = link_variables,
    # )

    linking_context = _create_linking_context(ctx, cc_toolchain, feature_configuration, objs)

    linker_output = cc_common.link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        linking_context = [linking_context],
        user_link_flags = [],
        name = ctx.label.name,
        output_type = 'executable',
    )
    # args = ctx.actions.args()
    # args.add_all(command_line)
    # args.add_all(objs)

    # ctx.actions.run(
    #     executable = linker_path,
    #     arguments = [args],
    #     env = env,
    #     inputs = depset(
    #         direct = objs,
    #         transitive = [cc_toolchain.all_files],
    #     ),
    #     outputs = [exe],
    # )
    return [
        DefaultInfo(files = depset([exe]), executable=exe),
    ]
