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

def get_dep_info(deps):
  headers = []
  includes = []
  quote_includes = []
  system_includes = []
  for dep in deps:
    if CcInfo in dep:
      cc = dep[CcInfo].compilation_context
      headers += cc.headers
      includes += cc.includes
      quote_includes += cc.quote_includes
      system_includes += cc.system_includes
  return {
      'headers' : depset(headers),
      'includes' : depset(includes),
      'quote_includes' : depset(quote_includes),
      'system_includes': depset(system_includes),
  }

def cc_module_compile_action(ctx, src, deps, module_map, module_deps, module_out=None):
    cc_toolchain = find_cpp_toolchain(ctx)

    dep_info = get_dep_info(deps)

    obj = ctx.actions.declare_file(replace_extension(src, "o"))

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
    c_compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts + ["-fmodules-ts", "-std=c++20"],
        include_directories = dep_info['includes'],
        quote_include_directories = dep_info['quote_includes'],
        system_include_directories = dep_info['system_includes'],
        source_file = src.path,
        output_file = obj.path,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )
    command_line = command_line + ["-fmodule-mapper=%s" % module_map.path]
    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
        variables = c_compile_variables,
    )

    module_outputs = []
    module_name = None
    module_file = None
    copy_args = []
    if module_out:
      module_name, module_file = module_out
      module_outputs.append(module_file)

    outputs = module_outputs + [obj]
    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = copy_args + ["--", c_compiler_path] + command_line,
        env = env,
        inputs = depset(
            [src] + dep_info['headers'].to_list() + [module_map] + module_deps.to_list(),
            transitive = [cc_toolchain.all_files],
        ),
        outputs = outputs,
    )
    return [
        DefaultInfo(files = depset(outputs)),
        ModuleCompileInfo(object = obj, module_name = module_name, module_file = module_file),
    ]
