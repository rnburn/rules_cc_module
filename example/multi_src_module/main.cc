#include <iostream>

import speech;

std::string get_phrase() {
    return "Hello, world!";
}

int main() {
  std::cout << get_phrase() << std::endl;
  std::cout << get_phrase_en() << std::endl;
  /* std::cout << get_phrase_es() << std::endl; */
  return 0;
}
