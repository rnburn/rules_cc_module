import sys
import argparse
import subprocess
from util.driver.clang import invoke_clang
from util.driver.gcc import invoke_gcc

argument_parser = argparse.ArgumentParser(prog='driver')
argument_parser.add_argument('--module_map', default=None)
argument_parser.add_argument('--module_name', default=None)
argument_parser.add_argument('--module_out', default=None)
argument_parser.add_argument('--object_out', default=None)

def main():
    break_index = sys.argv.index('--')
    driver_args = argument_parser.parse_args(sys.argv[1:break_index])
    compiler_command = sys.argv[(break_index+1):]
    compiler = compiler_command[0]
    compiler_args = compiler_command[1:]

    compiler_version = str(subprocess.check_output([compiler, '-v'], stderr=subprocess.STDOUT))
    if 'clang' in compiler_version:
        invoke_clang(driver_args, compiler, compiler_args)
    else:
        invoke_gcc(driver_args, compiler, compiler_args)


if __name__ == "__main__":
    main()
