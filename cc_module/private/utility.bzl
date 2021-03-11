load("//cc_module/private:provider.bzl", "ModuleCompilationContext", "ModuleCompileInfo")

def get_cc_info_deps(deps):
  return cc_common.merge_cc_infos(
      cc_infos = [dep[CcInfo] for dep in deps])

def get_module_deps(deps):
  direct = []
  transitive = []
  for dep in deps:
    if not ModuleCompileInfo in dep:
      continue
    module = dep[ModuleCompileInfo]
    direct.append(module)
    transitive.append(module.module_dependencies)
  return depset(direct=direct, transitive=transitive)

def get_includes(ctx):
  includes = ctx.attr.includes
  result = []
  basepath = ctx.build_file_path.split("/")
  basepath[:-1]
  for inc in includes:
    result.append("/".join(basepath + [inc]))
  return result

def make_module_mapper(owner, actions, modules):
  module_map = ""
  for module in modules.to_list():
    module_map += "%s %s\n" % (module.module_name, module.module_file.path)
  map_file = actions.declare_file(owner + "-module-map")
  actions.write(map_file, module_map)
  return map_file


def make_module_compilation_context(cc_info_deps, mapper, module_deps):
  module_files = [m.module_file for m in module_deps.to_list()]
  return ModuleCompilationContext(
    compilation_context = cc_info_deps.compilation_context,
    module_mapper = mapper,
    module_inputs = depset(
        direct = [mapper] + module_files,
        transitive = [cc_info_deps.compilation_context.headers],
    )
  )

def get_header_module_name(hdr, include_path):
  if not include_path:
    return "./" + hdr.path
  return include_path + "/" + hdr.basename


