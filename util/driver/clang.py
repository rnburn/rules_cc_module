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
    if not module_name:
        return 'c++'
    if module_name.startswith('.'):
        return 'c++-header'
    return 'c++-module'

def make_interface_args(compiler_args):
    interface_args = []
    is_source = False
    for i in range(len(compiler_args)):
        arg = compiler_args[i]
        if arg == '-c':
            is_source = True
            continue
        if is_source:
            is_source = False
            arg = os.readlink(os.getcwd() + "/" + arg)
        interface_args.append(arg)
    return interface_args

def make_stub_object(driver_args, compiler):
    empty_src = 'empty_src.cc'
    open(empty_src, 'a').close()
    args = [
            '-o', driver_args.object_out,
            '-c', empty_src,
    ]
    os.execv(compiler, [compiler] + args)

def query_arguments(driver_args, compiler, interface_args):
    additional_args = [
        '-###',
        '-x', get_src_type(driver_args.module_name),
        '--precompile',
        '-o', driver_args.module_file,
    ]
    res = subprocess.run(
            [compiler] + additional_args + interface_args, check=True, capture_output=True)
    res = res.stderr.decode('utf-8').splitlines()[-1]
    args = res.split()
    args_p = []
    args = args[:-1] # drop dummy source
    nargs = len(args)
    i = 0
    while i < nargs: 
        arg = args[i].strip('"')
        if arg == '-emit-module-interface':
            arg = '-emit-module'
        elif arg.startswith('-fmodule-map-file'):
            arg = arg.split('=')[-1]
        elif arg == '-D':
            i += 2
            continue
        args_p.append(arg)
        i += 1
    return args_p

def make_system_module(driver_args, compiler, interface_args):
    args = query_arguments(driver_args, compiler, interface_args)
    args.append('-fmodule-name=%s' % driver_args.module_name)
    subprocess.run(args, check=True)

def make_module(driver_args, compiler, interface_args):
    additional_args = [
        '-x', get_src_type(driver_args.module_name),
        '--precompile',
        '-o', driver_args.module_file,
    ]
    subprocess.run([compiler] + additional_args + interface_args, check=True)

def invoke_clang(driver_args, compiler, compiler_args):
    map_file = setup_module_map(driver_args)
    additional_args = [
        '-x', get_src_type(driver_args.module_name),
        '--precompile',
        '-o', driver_args.module_file,
    ]

    compiler_args += ['@' + map_file]

    # compile the module
    if driver_args.module_interface:
        interface_args = make_interface_args(compiler_args)
        if driver_args.is_system:
            make_system_module(driver_args, compiler, interface_args)
        else:
            make_module(driver_args, compiler, interface_args)

    # compile the object file
    if driver_args.object_out:
        if driver_args.module_interface:
            return make_stub_object(driver_args, compiler)
        args = [compiler] + compiler_args + ['-o', driver_args.object_out]
        os.execv(compiler, [compiler] + compiler_args + ['-o', driver_args.object_out])
