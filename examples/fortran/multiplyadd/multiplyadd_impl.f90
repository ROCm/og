module multiplyadd_impl
!    implicit none
contains
    subroutine multiplyadd(a, x, y, n)
        use iso_fortran_env
        integer :: n
        real(kind=real32) :: a
        real(kind=real32), dimension(n) :: x
        real(kind=real32), dimension(n) :: y
        integer :: i
        
    !$omp target teams distribute parallel do simd
        do i=1,n
            y(i) = a * x(i) + y(i)
        enddo
    !$omp end target teams distribute parallel do simd
    end subroutine multiplyadd
end module multiplyadd_impl