import os
import sys

import subprocess

def setup_module_map(driver_args):
    m = ""
    with open(driver_args.module_map, 'r') as f:
        for line in f.readlines():
            name, module_file = line.split(' ')
            m += '-fmodule-file=%s=%s' % (name, module_file)
    if driver_args.module_file and not driver_args.module_interface:
        m += '-fmodule-file=%s\n' % driver_args.module_file
    map_file = 'clang-module-map'
    with open(map_file, 'w') as f:
        f.write(m)
    return map_file

def get_src_type(module_name):
    if module_name.startswith('.'):
        return 'c++-header'
    return 'c++-module'

def invoke_clang(driver_args, compiler, compiler_args):
    map_file = setup_module_map(driver_args)

    compiler_args += ['@' + map_file]

    # compile the module
    if driver_args.module_interface:
        additional_args = [
            '-x', get_src_type(driver_args.module_name),
            '--precompile',
            '-o', driver_args.module_file,
        ]
        interface_args = [arg for arg in compiler_args if arg != '-c']
        # print(' '.join([compiler] + compiler_args + additional_args), file=sys.stderr)
        subprocess.run([compiler] + interface_args + additional_args, check=True)

    # compile the object file
    if driver_args.object_out:
        # print(' '.join([compiler] + compiler_args + ['-o', driver_args.object_out]), file=sys.stderr)
        os.execv(compiler, [compiler] + compiler_args + ['-o', driver_args.object_out])
