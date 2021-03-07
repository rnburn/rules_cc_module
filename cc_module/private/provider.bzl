ModuleCompileInfo = provider(doc = "", fields = ["object", "module_name", "module_file"])

ModuleCompilationContext = provider(
    doc = "",
    fields = [
        "compilation_context",
        "module_mapper",
        "module_inputs",
    ],
)
