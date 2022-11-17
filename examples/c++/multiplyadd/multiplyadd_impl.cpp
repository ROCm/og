#include "multiplyadd_impl.hpp"

void multiplyadd(int co, std::vector<int>* a, std::vector<int>* b,
                 std::vector<int>* c, unsigned nsize) {

#pragma omp target teams distribute parallel for map(from : a) map(to : b, c)
  for (int i = 0; i < nsize; ++i) {
    (*a)[i] = co * (*b)[i] + (*c)[i];
  }
}