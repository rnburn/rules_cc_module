module;

#include <iostream>

export module a;

import b;

export void run_a() {
  std::cout << "A\n";
  run_b();
}
