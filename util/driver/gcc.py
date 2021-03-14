import os

def setup_module_map(driver_args):
    if not driver_args.module_name:
        return driver_args.module_map
    m = None
    with open(driver_args.module_map, 'r') as f:
        m = f.read()
    m += "%s %s\n" % (driver_args.module_name, driver_args.module_out)
    map_file = 'gcc-module-map'
    with open(map_file, 'w') as f:
        f.write(m)
    return map_file


def invoke_gcc(driver_args, compiler, compiler_args):
    map_file = setup_module_map(driver_args)
    compiler_args += ['-fmodule-mapper=%s' % map_file]
    os.execv(compiler, [compiler] + compiler_args)
