program quick_test

implicit none

! Parameters
integer, parameter :: ik = 4
integer, parameter :: rk = selected_real_kind(p=14, r=99)
character(5), parameter :: ifile="ex1.g"
character(7), parameter :: ofile="ex1.out"

! Characters
character(300) :: text

! Integers
integer :: iost

! Formats 
1 format(A)


open(unit=1, file=ifile, iostat=iost, status="old", action="read")
open(unit=2, file=ofile, iostat=iost, status="replace", action="write")

do
  read(1,1,iostat=iost)  text
  write(*,1) trim(text)
  write(2,1) trim(text)
  if (iost /= 0) then
    exit
  end if
end do

close(1)
close(2)


end program quick_test

