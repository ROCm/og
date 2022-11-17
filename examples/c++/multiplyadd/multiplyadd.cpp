#include <iostream>
#include <vector>

#include "multiplyadd_impl.hpp"

int main() {

  int nsize = 1000;

  std::vector<int> a(nsize);
  std::vector<int> b(nsize);
  std::vector<int> c(nsize);

  std::fill(std::begin(a), std::end(a), 0);
  std::fill(std::begin(b), std::end(b), 2);
  std::fill(std::begin(c), std::end(c), 3);

  multiplyadd(20, &a, &b, &c, nsize);

  for (auto val : a) {
    if (val != 43) {
      std::cout << "Wrong value! Found " << val << " expected 43" << std::endl;
      return EXIT_FAILURE;
    }
  }

  printf("clean up");

  return EXIT_SUCCESS;
}