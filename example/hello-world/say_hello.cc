// file: hello.cc
module;
// legacy includes go here – not part of this module
#include <iostream>
#include <string_view>
export module Hello;
// the module purview starts here
// provide a function to users by exporting it
export void SayHello
  (std::string_view const &name)
{
  std::cout << "Hello " << name << "!\n";
}

