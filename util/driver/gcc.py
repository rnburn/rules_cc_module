import os

def invoke_gcc(driver_args, compiler, compiler_args):
    os.execv(compiler, [compiler] + compiler_args)
