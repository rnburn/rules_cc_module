export module a;

import <iostream>;

import b;

export inline void run_a() {
  std::cout << "A\n";
  run_b();
}
