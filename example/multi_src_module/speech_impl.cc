module;

#include <string>

module speech;

/* import spanish_english_dictionary; */

std::string get_phrase_en() {
    return "Hello, world!";
}

std::string get_phrase_es() {
  return "abc";
  /* return translate("Hello"); */
    /* return std::string{"¡"} + translate("Hello") + " Mundo!"; */
}
