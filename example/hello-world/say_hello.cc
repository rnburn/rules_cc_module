// file: hello.cc
export module Hello;

import <iostream>;
import <string_view>;

// the module purview starts here
// provide a function to users by exporting it
export inline void SayHello
  (std::string_view const &name)
{
  std::cout << "Hello " << name << "!\n";
}

