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
load("//cc_module/private:cc_module_compile.bzl", 
     "cc_module_compile_action",
     "cc_header_module_compile_action",
)
load("//cc_module/private:cc_module_link.bzl", "cc_module_link_action")
load("//cc_module/private:utility.bzl", 
      "get_cc_info_deps",
      "get_module_deps",
      "get_header_module_name",
      "make_module_mapper",
      "make_module_compilation_context",
     )
load("//cc_module/private:provider.bzl", "ModuleCompileInfo", "ModuleCompilationContext")

_common_attrs = {
  "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
  "_driver": attr.label(
      default = Label("//util/driver"),
      executable = True,
      cfg = "exec",
  ),
  "deps": attr.label_list(),
  "copts": attr.string_list(),
  "linkopts": attr.string_list(),
}

###########################################################################################
# cc_module
###########################################################################################
def compile_module_impl_srcs(ctx, module_name, module_out_file):
  impl_deps = ctx.attr.deps + ctx.attr.impl_deps
  cc_info_impl_deps = get_cc_info_deps(impl_deps)
  module_impl_deps = get_module_deps(impl_deps)
  module_info = ModuleCompileInfo(
      module_name = module_name,
      module_file = module_out_file,
      module_dependencies = module_impl_deps,
  )
  module_map = make_module_mapper(
      ctx.label.name + "-impl_srcs",
      ctx.actions, 
      module_impl_deps)
  compilation_context = make_module_compilation_context(
      cc_info_impl_deps, module_map, module_impl_deps) 
  compilation_context = ModuleCompilationContext(
      compilation_context = compilation_context.compilation_context,
      module_mapper = compilation_context.module_mapper,
      module_inputs = depset(
          direct = [module_out_file],
          transitive = [compilation_context.module_inputs]
      ),
  )

  objs = []
  for impl_src in ctx.files.impl_srcs:
    objs += cc_module_compile_action(ctx, src=impl_src,
                                     compilation_context=compilation_context, 
                                     module_info=module_info)

  return objs, CcInfo(linking_context=cc_info_impl_deps.linking_context)

def _cc_module_impl(ctx):
  if ctx.attr.is_system and ctx.file.src:
    fail("src must not be specified if is_system is True")
  if not ctx.file.src and not ctx.attr.is_system:
    fail("src must be specified")

  module_name = ctx.label.name
  archive_out_file = ctx.actions.declare_file(module_name + ".a")
  module_out_file = ctx.actions.declare_file(module_name + ".pcm")
  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)
  module_deps = get_module_deps(deps)
  module_info = ModuleCompileInfo(
      module_name = module_name,
      module_file = module_out_file,
      module_dependencies = module_deps,
  )

  module_map = make_module_mapper(
      ctx.label.name,
      ctx.actions, 
      module_deps)
  compilation_context = make_module_compilation_context(cc_info_deps, module_map, module_deps) 
  objs = []
  objs += cc_module_compile_action(ctx, src=ctx.file.src,
                                   compilation_context=compilation_context,
                                   module_info=module_info, is_interface=True, 
                                   is_system=ctx.attr.is_system)

  impl_objs, impl_cc_info = compile_module_impl_srcs(ctx, module_name, module_out_file)
  objs += impl_objs

  linking_context = cc_module_archive_action(ctx, objs, archive_out_file)
  outputs = [
      archive_out_file,
      module_out_file,
  ]
  cc_info = CcInfo(
      compilation_context = cc_info_deps.compilation_context,
      linking_context = linking_context
  )
  cc_info = cc_common.merge_cc_infos(cc_infos=[cc_info, impl_cc_info, cc_info_deps])
  dep_files = outputs
  if ctx.file.src:
    dep_files += [ctx.file.src]
  return [
        DefaultInfo(files = depset(dep_files)),
        cc_info,
        module_info,
  ]

_cc_module_attrs = {
  "src": attr.label(mandatory = False, allow_single_file = True),
  "impl_srcs": attr.label_list(mandatory=False, allow_files=True),
  "impl_deps": attr.label_list(),
  "is_system": attr.bool(default=False),
}

cc_module = rule(
    implementation = _cc_module_impl,
    attrs = dict(_common_attrs.items() + _cc_module_attrs.items()),
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    fragments = ["cpp"],
)

###########################################################################################
# cc_header_module
###########################################################################################
def _cc_header_module_impl(ctx):
  hdr = ctx.file.hdr
   
  module_name = "./" + hdr.path
  module_out_file = ctx.actions.declare_file(hdr.basename + ".gcm")

  includes = []
  hdr_dep = [hdr]
  outputs = [module_out_file]
  if ctx.attr.include_path:
    gen_dir = module_out_file.dirname + "/" + hdr.basename + "-include"
    inc_dir = hdr.basename + "-include/" + ctx.attr.include_path 
    hdr_mirror = ctx.actions.declare_file(inc_dir + "/" + hdr.basename)
    hdr_dir = ctx.actions.declare_directory(hdr_mirror.dirname)
    ctx.actions.run_shell(
        outputs = [hdr_dir],
        command = "mkdir -p %s" % hdr_dir.path,
    )
    ctx.actions.run_shell(
        outputs = [hdr_mirror],
        inputs = [hdr],
        command = "cp %s %s" % (hdr.path, hdr_mirror.path),
    )
    includes = [
        gen_dir
    ]
    hdr_dep = [hdr_mirror]
    outputs.append(hdr_mirror)
    hdr = hdr_mirror
    module_name = "./" + hdr_mirror.path


  deps = ctx.attr.deps
  cc_info_deps = get_cc_info_deps(deps)

  module_deps = get_module_deps(deps)

  module_info = ModuleCompileInfo(
      module_name = module_name,
      module_file = module_out_file,
      module_dependencies = module_deps,
  )
  module_map = make_module_mapper(
      ctx.label.name,
      ctx.actions, 
      module_deps)
  compilation_context = make_module_compilation_context(cc_info_deps, module_map, module_deps)
  cc_header_module_compile_action(ctx, src=hdr,
                           compilation_context=compilation_context,
                           module_info=module_info)

  hdr_compilation_context = cc_common.create_compilation_context(
      headers = depset(hdr_dep),
      includes = depset(includes),
  )
  cc_info = CcInfo(
      compilation_context = hdr_compilation_context,
  )
  cc_info = cc_common.merge_cc_infos(cc_infos=[cc_info, cc_info_deps])
  return [
        DefaultInfo(files = depset(outputs)),
        cc_info,
        module_info,
  ]


_cc_header_module_attrs = {
  "hdr": attr.label(mandatory = True, allow_single_file = True),
  "include_path": attr.string(),
}

cc_header_module = rule(
    implementation = _cc_header_module_impl,
    attrs = dict(_common_attrs.items() + _cc_header_module_attrs.items()),
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
    executable = True,
)
