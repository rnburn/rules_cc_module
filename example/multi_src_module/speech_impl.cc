module speech;

import <string>;

import spanish_english_dictionary;

std::string get_phrase_en() {
    return "Hello, world!";
}

std::string get_phrase_es() { return translate("Hello"); }
