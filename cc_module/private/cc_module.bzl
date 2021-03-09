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
      "make_module_compilation_context",
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
def compile_module(ctx, cc_info_deps, module_info, i, src, cmi, cmi_dest):
  module_deps = module_info.module_dependencies
  module_info_p = ModuleCompileInfo(
      module_name = module_info.module_name,
      module_file = cmi,
      module_dependencies = module_deps)
  module_map = make_module_mapper(
      ctx.label.name + "." + str(i), 
      ctx.actions, 
      depset(direct = [module_info_p], transitive = [module_deps]))
  if i > 0:
    module_deps = depset(direct  = [module_info_p], transitive = [module_deps])
  compilation_context = make_module_compilation_context(cc_info_deps, module_map, module_deps) 
  return cc_module_compile_action(ctx, src=src, 
                                  compilation_context=compilation_context,
                                  module_out=module_info_p,
                                  module_dest=cmi_dest)


def compile_multi_source_module(ctx, cc_info_deps, module_info, export_src, impl_srcs):
  all_srcs = [export_src] + impl_srcs
  num_srcs = len(all_srcs)
  objs = []
  prev_cmi = None
  for i, src in enumerate(all_srcs):
    cmi = None
    if i == len(all_srcs)-1:
      cmi = module_info.module_file
    else:
      cmi = ctx.actions.declare_file(module_info.module_name + "." + str(i))
    if not prev_cmi:
      prev_cmi = cmi
    objs += compile_module(ctx, cc_info_deps, module_info, i, src, prev_cmi, cmi)
  return objs

def _cc_module_impl(ctx):
  module_name = ctx.label.name
  archive_out_file = ctx.actions.declare_file(module_name + ".a")
  module_out_file = ctx.actions.declare_file(module_name + ".gcm")
  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)
  module_info = ModuleCompileInfo(
      module_name = module_name,
      module_file = module_out_file,
      module_dependencies = module_deps,
  )

  objs = compile_multi_source_module(ctx, cc_info_deps, module_info, ctx.file.src, ctx.files.impl_srcs)

  linking_context = cc_module_archive_action(ctx, objs, archive_out_file)
  outputs = [
      archive_out_file,
      module_out_file,
  ]
  cc_info = CcInfo(
      compilation_context = cc_info_deps.compilation_context,
      linking_context = linking_context
  )
  cc_info = cc_common.merge_cc_infos(cc_infos=[cc_info, cc_info_deps])
  return [
        DefaultInfo(files = depset(outputs)),
        cc_info,
        module_info,
  ]

_cc_module_attrs = {
  "src": attr.label(mandatory = True, allow_single_file = True),
  "impl_srcs": attr.label_list(mandatory=False, allow_files=True),
}

cc_module = rule(
    implementation = _cc_module_impl,
    attrs = dict(_common_attrs.items() + _cc_module_attrs.items()),
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)

###########################################################################################
# cc_module_library
###########################################################################################
def _cc_module_library_impl(ctx):
  archive_out_file = ctx.actions.declare_file(ctx.label.name + ".a")

  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)

  module_map = make_module_mapper(ctx.label.name, ctx.actions, module_deps)

  compilation_context = cc_common.create_compilation_context(
      headers = depset(ctx.files.hdrs),
  )
  compilation_context = make_module_compilation_context(
      cc_common.merge_cc_infos(cc_infos=[
        CcInfo(
            compilation_context = compilation_context,
        ),
        cc_info_deps, 
      ]),
      module_map, module_deps) 

  objs = []
  for src in ctx.files.srcs:
    objs += cc_module_compile_action(ctx, src=src, 
                                           compilation_context = compilation_context)

  linking_context = cc_module_archive_action(ctx, objs, archive_out_file)
  outputs = [
      archive_out_file,
  ]
  cc_info = CcInfo(
      compilation_context = compilation_context.compilation_context,
      linking_context = linking_context
  )
  cc_info = cc_common.merge_cc_infos(cc_infos=[cc_info, cc_info_deps])
  return [
        DefaultInfo(files = depset(outputs)),
        cc_info,
  ]

_cc_module_library_attrs  = {
  "hdrs": attr.label_list(mandatory=False, allow_files=True),
  "srcs": attr.label_list(mandatory=False, allow_files=True),
}

cc_module_library = rule(
    implementation = _cc_module_library_impl,
    attrs = dict(_common_attrs.items() + _cc_module_library_attrs.items()),
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)

###########################################################################################
# cc_module_binary
###########################################################################################
def  _cc_module_binary_impl(ctx):
  exe = ctx.actions.declare_file(ctx.label.name)
  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)

  module_map = make_module_mapper(ctx.label.name, ctx.actions, module_deps)

  compilation_context = make_module_compilation_context(cc_info_deps, module_map, module_deps) 


  objs = []
  for src in ctx.files.srcs:
    objs += cc_module_compile_action(ctx, src=src, 
                                           compilation_context = compilation_context)
  cc_module_link_action(ctx, objs, cc_info_deps.linking_context, exe)

  return [
      DefaultInfo(files = depset([exe]), executable=exe),
  ]

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
