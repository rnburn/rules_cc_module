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

load("//cc_module/private:cc_module_archive.bzl", "cc_module_archive_action")
load("//cc_module/private:cc_module_compile.bzl", "cc_module_compile_action")
load("//cc_module/private:cc_module_link.bzl", "cc_module_link_action")
load("//cc_module/private:utility.bzl", 
      "get_cc_info_deps",
      "get_module_deps",
      "make_module_mapper",
      "get_module_compilation_context",
     )
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

###########################################################################################
# cc_module
###########################################################################################
def _cc_module_impl(ctx):
  module_name = ctx.label.name
  module_out_file = ctx.actions.declare_file(module_name + ".gcm")
  module_info = ModuleCompileInfo(
      module_name = module_name,
      module_file = module_out_file,
  )
  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)

  module_map = make_module_mapper(ctx.label.name, ctx.actions, module_deps + [module_info])

  compilation_context = get_module_compilation_context(cc_info_deps, module_map, module_deps) 

  module_out = (module_name, module_out_file)

  obj = cc_module_compile_action(ctx, src=ctx.file.src, 
                                  compilation_context=compilation_context,
                                  module_out=module_out)
  outputs = [
      obj,
      module_info.module_file,
  ]
  return [
        DefaultInfo(files = depset(outputs)),
        module_info,
  ]

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
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)

  module_map = make_module_mapper(ctx.label.name, ctx.actions, module_deps)

  compilation_context = get_module_compilation_context(cc_info_deps, module_map, module_deps) 


  objs = []
  for src in ctx.files.srcs:
    obj = cc_module_compile_action(ctx, src=src, 
                                           compilation_context = compilation_context)
    objs.append(obj)
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
