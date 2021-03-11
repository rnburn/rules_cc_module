module;

#include <iostream>

export module b;

import "example/header-module/a.h";

export void do_b() {
  std::cout << "b\n";
  std::cout << do_a() << "\n";
}
