module;

#include <cassert>

export module algorithm;

import <algorithm>;
import <type_traits>;
import <vector>;

export template <class Iter>
auto compute_median(Iter first, Iter last) {
  using T = std::decay_t<decltype(*first)>;
  auto n = std::distance(first, last);
  assert(n > 0);
  std::vector<const T*> v(n);
  std::transform(first, last, v.begin(), [](auto& x) { return &x; });
  auto mid = v.begin() + n / 2;
  std::nth_element(v.begin(), mid, v.end(),
                   [](const T* lhs, const T* rhs) { return *lhs < *rhs; });
  return **mid;
}
