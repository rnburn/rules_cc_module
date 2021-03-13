module;

#include <string>
#include <string_view>

module spanish_english_dictionary;

std::string translate(std::string_view s) {
  if (s == "Hello") {
    return "Hola";
  }
  return "???";
}
