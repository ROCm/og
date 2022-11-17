#include "multiplyadd_impl.h"

void multiplyadd(int co, int *a, int *b, int *c, unsigned nsize) {

#pragma omp target teams distribute parallel for map(from : a) map(to : b, c)
  for (int i = 0; i < nsize; ++i) {
    a[i] = co * b[i] + c[i];
  }
}