FROM ubuntu:21.04

WORKDIR /third_party

ADD setup_build_environment.sh /third_party
ADD install_bazel.sh /third_party
ADD install_clang.sh /third_party

RUN /third_party/setup_build_environment.sh \
 && /third_party/install_clang.sh \
 && /third_party/install_bazel.sh

EXPOSE 8888
