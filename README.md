# rules_cc_module

Rules to use C++20 modules with Bazel.

## Getting started

Note: Currently only works with a recent version of gcc (with module support).

Build a simple module:
```bazel
cc_module(
    name = "Hello",
    src = "say_hello.cc", # say_hello exports the module Hello
)

# Build a binary with the module
cc_module_binary(
    name = "a.out",
    srcs = [
        "main.cc",  # We can import Hello in main.cc
    ],
    deps = [
        ":Hello",
    ],
)
```

Build a module with implementation units:
```bazel
cc_module_binary(
  name = "speech",
  src = "speech.cc",  # speech.cc exports the module speech
  impl_srcs = [
    "speech_impl.cc", # speech_impl.cc provides implements (but doesn't export) speech
  ],
)
```

Interoperate with regular cc libraries
```bazel
cc_module(
    name = "a",
    src = "a.cc",
)

cc_module_library(
    name = "b",
    hdrs = [
        "b.h",
    ],
    srcs = [
        "b.cc", # b can import module a, but shouldn't export a module
    ],
    deps = [
        ":a",
    ],
)

# We can use b with regular cc rules
cc_binary(
    name = "a.out",
    srcs = [
        "main.cc",
    ],
    deps = [
        ":b",
    ],
)
```

## Examples
The directory [example](https://github.com/rnburn/bazel-cpp20-modules/tree/main/example) demonstrates 
usage and there is a docker image that provides a build environment. To build the examples,
run
```
./ci/run_docker.sh # spins up a build environment
bazel build //example/... # build the examples
```
