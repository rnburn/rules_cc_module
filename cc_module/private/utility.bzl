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

def make_module_mapper(owner, actions, modules):
  module_map = ""
  for module in modules.to_list():
    module_map += "%s %s\n" % (module.module_name, module.module_file.path)
  map_file = actions.declare_file(owner + "-module-map")
  actions.write(map_file, module_map)
  return map_file

def make_module_compilation_context(cc_info_deps, mapper, module_deps, produce_object=True):
  module_files = [m.module_file for m in module_deps.to_list()]
  return ModuleCompilationContext(
    compilation_context = cc_info_deps.compilation_context,
    module_mapper = mapper,
    produce_object = produce_object,
    module_inputs = depset(
        direct = [mapper] + module_files,
        transitive = [cc_info_deps.compilation_context.headers],
    )
  )

