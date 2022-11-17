#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "multiplyadd_impl.h"

int main(int argc, char **argv) {

  int nsize = 1000;

  int *a, *b, *c;

  a = (int *)malloc(nsize * sizeof(int));
  b = (int *)malloc(nsize * sizeof(int));
  c = (int *)malloc(nsize * sizeof(int));

  memset((void*) a, 0, nsize);

  for (int i = 0; i < nsize; i++) {
    b[i] = 2;
    c[i] = 3;
  }

  multiplyadd(20, a, b, c, nsize);

  for(int i = 0; i < nsize; i++){
    if(a[i] != 43){
      printf("Wrong value! Found %u expected 43\n");
      return EXIT_FAILURE;
    }
  }

  printf("clean up");

  free(c);
  free(b);
  free(a);

  return EXIT_SUCCESS;
}