load("//cc_module/private:provider.bzl", "ModuleCompilationContext", "ModuleCompileInfo")

def get_cc_info_deps(deps):
  return cc_common.merge_cc_infos(
      cc_infos = [dep[CcInfo] for dep in deps if CcInfo in dep])

def get_module_deps(deps):
  return [dep[ModuleCompileInfo] for dep in deps if ModuleCompileInfo in dep]

def make_module_mapper(owner, actions, modules):
  module_map = ""
  for module in modules:
    module_map += "%s %s\n" % (module.module_name, module.module_file.path)
  map_file = actions.declare_file(owner + "-module-map")
  actions.write(map_file, module_map)
  return map_file

def get_module_compilation_context(cc_info_deps, mapper, module_deps):
  return ModuleCompilationContext(
    compilation_context = cc_info_deps.compilation_context,
    module_mapper = mapper,
    module_inputs = depset(
        direct=[m.module_file for m in module_deps] + [mapper],
        transitive=[cc_info_deps.compilation_context.headers]),
  )

