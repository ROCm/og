
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// simple example of vector addition combined with AMD GPU offloading
// to keep it simple there is no error handling (e.g. malloc fails)
int main(int argc, char **argv) {

  int nsize = 1000000;
  int *a, *b, *c;

  a = (int *)malloc(nsize * sizeof(int));
  b = (int *)malloc(nsize * sizeof(int));
  c = (int *)malloc(nsize * sizeof(int));

  // memset((void*) a, 0, nsize);

  for (int i = 0; i < nsize; i++) {
    b[i] = 1;
    c[i] = 2;
  }

#pragma omp target teams distribute parallel for map(from : a) map(to : b, c)
  for (int i = 0; i < nsize; i++) {
    a[i] = b[i] + c[i];
  }

  for (int i = 0; i < nsize; i++) {
    if (a[i] != 3) {
      printf("Found wrong value! Found %u expected 3\n", a[i]);
      return EXIT_FAILURE;
    }
  }

  printf("All values are correct!\n");

  free(a);
  free(b);
  free(c);

  return EXIT_SUCCESS;
}