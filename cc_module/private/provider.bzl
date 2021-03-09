ModuleCompileInfo = provider(doc = "", fields = [
    "module_name", 
    "module_file",
    "module_dependencies",
])

ModuleCompilationContext = provider(
    doc = "",
    fields = [
        "compilation_context",
        "produce_object",
        "module_mapper",
        "module_inputs",
    ],
)
