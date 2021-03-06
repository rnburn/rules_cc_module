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

load("//cc_module/private:cc_module_compile.bzl", "cc_module_compile_action")
load("//cc_module/private:cc_module_link.bzl", "cc_module_link_action")
load("//cc_module/private:provider.bzl", "ModuleCompileInfo")

_common_attrs = {
  "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
  "_process_wrapper": attr.label(
      default = Label("//util/process_wrapper"),
      executable = True,
      allow_single_file = True,
      cfg = "exec",
  ),
  "deps": attr.label_list(),
}

def gather_modules(deps):
  modules = []
  for dep in deps:
    if ModuleCompileInfo in dep:
      ci = dep[ModuleCompileInfo]
      if ci.module_file:
        modules.append((ci.module_name, ci.module_file))
  return modules

def setup_module_dependencies(owner, actions, modules):
  module_map = ""
  module_files = []
  for module_name, module_file in modules:
    module_files.append(module_file)
    module_map += "%s %s\n" % (module_name, module_file.path)
  map_file = actions.declare_file(owner + "-module-map")
  actions.write(map_file, module_map)
  return map_file

###########################################################################################
# cc_module
###########################################################################################
def _cc_module_impl(ctx):
  deps = ctx.attr.deps
  modules = gather_modules(deps)
  module_name = ctx.label.name
  module_out_file = ctx.actions.declare_file(module_name + ".gcm")
  module_out = (module_name, module_out_file)
  module_map = setup_module_dependencies(ctx.label.name, ctx.actions, modules + [module_out])
  module_deps = depset([module_map] + [m[1] for m in modules])
  return cc_module_compile_action(ctx, src=ctx.file.src, 
                                  deps=deps,
                                  module_map=module_map, 
                                  module_deps=module_deps,
                                  module_out=module_out)

_cc_module_attrs = {
  "src": attr.label(mandatory = True, allow_single_file = True),
}

cc_module = rule(
    implementation = _cc_module_impl,
    attrs = dict(_common_attrs.items() + _cc_module_attrs.items()),
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)

###########################################################################################
# cc_module_binary
###########################################################################################
def  _cc_module_binary_impl(ctx):
  deps = ctx.attr.deps
  modules = gather_modules(deps)
  module_map = setup_module_dependencies(ctx.label.name, ctx.actions, modules)
  module_deps = depset([module_map] + [m[1] for m in modules])
  objs = []
  for src in ctx.files.srcs:
    output_info = cc_module_compile_action(ctx, src=src, deps=deps,
                                           module_map=module_map, module_deps=module_deps)
    objs.append(output_info[1].object)
  return cc_module_link_action(ctx, objs, ctx.label.name)

_cc_module_binary_attrs  = {
  "srcs": attr.label_list(mandatory=True, allow_files=True),
}

cc_module_binary = rule(
    implementation = _cc_module_binary_impl,
    attrs = dict(_common_attrs.items() + _cc_module_binary_attrs.items()),
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)
