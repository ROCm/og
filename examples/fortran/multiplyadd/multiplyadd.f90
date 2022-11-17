program multiplyadd_example
    use multiplyadd_impl
    use iso_fortran_env
    use omp_lib

    implicit none

    integer, parameter :: N = 1000
    integer :: i

    real(kind=real32),dimension(N) :: x
    real(kind=real32),dimension(N) :: y

    x(:) = 2.0
    y(:) = 1.0

    call multiplyadd(20.5, x, y, N)

    do i = 1,N
        if(y(i).ne.42) then
            print"(a,f5.2)", "Expected 42 found ", y(i)
            stop
        endif
    end do

end program multiplyadd_example

