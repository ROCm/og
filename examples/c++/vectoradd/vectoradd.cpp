#include <iostream>
#include <vector>

int main() {
  int nsize = 1000000;

  std::vector<int> a(nsize);
  std::vector<int> b(nsize);
  std::vector<int> c(nsize);

  std::fill(std::begin(a), std::end(a), 0);
  std::fill(std::begin(b), std::end(b), 1);
  std::fill(std::begin(c), std::end(c), 2);

#pragma omp target teams distribute parallel for map(from : a) map(to : b, c)
  for (int i = 0; i < nsize; i++) {
    a[i] = b[i] + c[i];
  }

  for (auto val : a) {
    if (val != 3) {
      std::cout << "Wrong value! Found " << val << " expected 3" << std::endl;
      return EXIT_FAILURE;
    }
  }

  std::cout << "All values are correct" << std::endl;

  return EXIT_SUCCESS;
}
