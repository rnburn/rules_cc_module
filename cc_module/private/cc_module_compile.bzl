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

load("@rules_cc//cc:action_names.bzl", "CPP_COMPILE_ACTION_NAME")
load("@rules_cc//cc:toolchain_utils.bzl", "find_cpp_toolchain")
load("//cc_module/private:provider.bzl", "ModuleCompileInfo")


def replace_extension(f, new_ext):
  ext = f.extension
  return f.basename[:-len(ext)]  + new_ext

def make_source(ctx, src, module_info):
  src = ctx.actions.declare_file('%s.cc' % module_info.module_name)
  cmd = "touch %s" % src.path
  ctx.actions.run_shell(
      outputs = [src],
      command = cmd,
  )
  return src

def cc_module_compile_action(ctx, src, compilation_context, module_info=None, is_interface=False, is_system=False):
    cc_toolchain = find_cpp_toolchain(ctx)

    if not src:
      src = make_source(ctx, src, module_info)
    obj_name = replace_extension(src, "o")
    if is_interface:
      obj_name = "cc_module_interface-" + obj_name
    obj = ctx.actions.declare_file(obj_name)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    c_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
    )
    cc = compilation_context.compilation_context
    copts = getattr(ctx.attr, "copts", [])
    c_compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts + copts,
        include_directories = cc.includes,
        quote_include_directories = cc.quote_includes,
        system_include_directories = cc.system_includes,
        source_file = src.path,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )
    command_line = list(command_line)
    command_line += ["-iquote", "."]

    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )

    driver_args = []
    driver_args += ['--object_out', obj.path]
    driver_args += ['--module_map', compilation_context.module_mapper.path]
    if is_system:
      driver_args += ['--is_system']
    if module_info:
      driver_args += ['--module_name', module_info.module_name]
      driver_args += ['--module_file', module_info.module_file.path]

    outputs = [obj]
    if is_interface:
      outputs.append(module_info.module_file)
      driver_args += ['--module_interface']


    ctx.actions.run(
        executable = ctx.executable._driver,
        arguments = driver_args + ["--", c_compiler_path] + command_line,
        env = env,
        inputs = depset(
            [src],
            transitive = [compilation_context.module_inputs, cc_toolchain.all_files],
        ),
        outputs = outputs,
    )
    return [obj]

def cc_header_module_compile_action(ctx, src, compilation_context, module_info):
    cc_toolchain = find_cpp_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    c_compiler_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
    )
    cc = compilation_context.compilation_context
    c_compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts + \
            ["-x", "c++-header", "-fmodules", "-std=c++20"],
        include_directories = cc.includes,
        quote_include_directories = cc.quote_includes,
        system_include_directories = cc.system_includes,
        source_file = src.path,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )
    command_line = list(command_line)
    command_line += ["-iquote", "."]

    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )

    driver_args = []
    driver_args += ['--module_map', compilation_context.module_mapper.path]

    outputs = [module_info.module_file]
    driver_args += ['--module_name', module_info.module_name]
    driver_args += ['--module_file', module_info.module_file.path]

    ctx.actions.run(
        executable = ctx.executable._driver,
        arguments = driver_args + ["--", c_compiler_path] + command_line,
        env = env,
        inputs = depset(
            [src],
            transitive = [compilation_context.module_inputs, cc_toolchain.all_files],
        ),
        outputs = outputs,
    )
