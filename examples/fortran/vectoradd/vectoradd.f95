! example of simple vector add combined with AMD GPU offloading
program main
    parameter (nsize=1000000)
    real a(nsize), b(nsize), c(nsize)
    integer i
  
    do i=1,nsize
      a(i)=0
      b(i) = i
      c(i) = 10
    end do
      
  !$omp target teams distribute parallel do map(from:a) map(to:b,c)
    do i=1,nsize
      a(i) = b(i) + c(i)
    end do
  !$omp end target teams distribute parallel do
    return
  end