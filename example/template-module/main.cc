import <iostream>;
import <vector>;

import algorithm;

int main() {
  std::vector<int> v1 = {1, -9, 7};
  std::cout << compute_median(v1.begin(), v1.end()) << std::endl;
  std::vector<double> v2 = {10.0, 5.0, 7.2, -3.5};
  std::cout << compute_median(v2.begin(), v2.end()) << std::endl;
  return 0;
}
