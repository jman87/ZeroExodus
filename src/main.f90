! ******************************************************************************!
!
! Copyright 2022 Robert S. Browning IV
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!
! ******************************************************************************!
!
! PROGRAM NAME:  ZeroExodus
!
! PROGRAM DEVELOPER:  Robert S. Browning IV, Ph.D.
!
! LANGUAGE: Fortran 2008
!           Note: .f90 file extensions are for compatibility with Intel compiler
!
! PROGRAM DESCRIPTION:
!     ZeroExodus sets nearly-zero coordinates in an Exodus II mesh file to zero
!     for a given tolerance and precision. Currently, the precision and 
!     tolerance are hard-coded to the standard values used by common meshing
!     software. 
!
! PROGRAM COMPILATION:
!     The simpliciity of this program is such that using a makefile would be
!     overkill. Simply place the ZeroExodus directory in a location you prefer
!     and then use your preferred Fortran compiler to compile the main.f90
!     file, which is found in the src directory. For example, using gfortran
!     the compile command would be:
!
!         gfortran main.f90 -o ZeroExodus
!
! PROGRAM USAGE:
!     The anticipated usage of this program will be in a computational 
!     envitonment. Thus, it is expected that users will have the ability to 
!     call this program from a terminal in a Linux-like fashion; if you're 
!     running Windows this can be accomplished via the Windows Subsystem for
!     Linux (WSL). Thus, if you compiled the executable as ZeroExodus, then
!     to convert an ASCII Exodus mesh file, simply type:
!
!         ZeroExodus ascii.exotxt
!
!     This will generate an output file named:  ascii_zeroexo.exotxt
!
!     Alternatively, you can provide your desired output file name as an
!     additional command line argument:
!
!         ZeroExodus ascii.exotxt user_defined_output_name.exotxt
!
!     The .exotxt extension is required to help prevent unintentional 
!     application of ZeroExodus to non-Exodus files. It also serves as a 
!     reminder that this program requires ASCII input.
!
!     ZeroExodus expects that the ASCII files were generated by the exotxt tool
!     provided in the SEACAS tool suite. SEACAS is not part of this program and
!     no statement of suitability, liability, warranty, etc. is expressed or 
!     implied regarding SEACAS. The interested reader should consult the 
!     following URL for more information about SEACAS:
!
!         https://github.com/sandialabs/seacas
!
! ******************************************************************************!

program ZeroExodus

use intrinsic :: iso_fortran_env, only : ik=>INT64, rk=>REAL64

implicit none

!-------------------------------------------------------------------------------!
!         ---> NOTE: Both INT32 and INT64 integers are used herein <---         !
!-------------------------------------------------------------------------------!

! Parameters
integer(INT32), parameter :: arg_limit = 3
real(rk), parameter :: default_coord_tol = 1.0e-15_rk
real(rk), parameter :: ZERO = 0.00000000000000000000_rk

! Characters
character(125) :: ifile=""
character(133) :: ofile=""
character(120), dimension(arg_limit) :: arg
character(300) :: text

! 32-Bit Integers
integer(INT32) :: iost=0
integer(INT32) :: num_args=-99
integer(INT32) :: i32=0
integer(INT32) :: ifile_len=0, ofile_len=0

! Default-Kind Integers
integer(ik) :: i
integer(ik) :: xn=0_ik, yn=0_ik, zn=0_ik, linen=0_ik

! Reals
real(rk) :: coord_tol
real(rk) :: x, y, z

! Logicals
logical :: line_count_flag = .false.

! Formats
1 format(A)
2 format(/A)
3 format(A/)
4 format(/A/)
99 format(3ES16.7)

! Get input from user
num_args = command_argument_count()

! If no arguments passed print help info
if (num_args == 0) then
    print *
    write(*,1) "*************************************************************************"
    print *
    write(*,1) "                               ZeroExodus"
    write(*,1) "                  Copyright 2022 Robert S. Browning IV"
    print *
    write(*,1) "*************************************************************************"
    print *
    write(*,1) "                                LICENSE"
    print *
    write(*,1) 'Licensed under the Apache License, Version 2.0 (the "License");'
    write(*,1) "you may not use this file except in compliance with the License."
    write(*,1) "You may obtain a copy of the License at"
    print *
    write(*,1) "    http://www.apache.org/licenses/LICENSE-2.0"
    print *
    write(*,1) "Unless required by applicable law or agreed to in writing, software"
    write(*,1) 'distributed under the License is distributed on an "AS IS" BASIS,'
    write(*,1) "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied."
    write(*,1) "See the License for the specific language governing permissions and"
    write(*,1) "limitations under the License."
    print *
    write(*,1) "*************************************************************************"
    print *
    write(*,1) "                              INSTRUCTIONS"
    print *
    write(*,1) "ZeroExodus accepts the following arguments:"
    write(*,1) "    input.exotxt"
    write(*,1) "   output.exotxt  (Optional: omit or set to 0 to use third argument)"
    write(*,1) "       tolerance  (Optional: Defaults to 1.0e-15)"
    print *
    write(*,1) "*************************************************************************"
    print *
endif

! If too many arguments are passed then quit with error
if (num_args > arg_limit) then
    write(*,4) "ERROR: NUMBER OF COMMAND LINE ARGUMENTS CANNOT BE" //  &
                " GREATER THAN " // Int2Text(int(arg_limit,ik))
    stop
endif

! Get the command arguments
do i32 = 1, num_args
    call get_command_argument(i32, arg(i32))
end do

! Store arg1 as input file name and get its length
ifile = adjustl(trim(arg(1)))
ifile_len = len_trim(ifile)

! Check that input file is a .exotxt file, if not stop with error
if (ifile_len < 8) then
  write(*,4) "ERROR: INPUT FILE MUST BE AN .exotxt FILE"
  stop
elseif ((num_args>=1) .AND. (ifile((ifile_len-6):ifile_len) /= ".exotxt")) then
    write(*,4) "ERROR: INPUT FILE MUST BE AN .exotxt FILE"
    stop
endif

! Set output file name to default or to command line argument 2
if (num_args >= 2) then
    if (arg(2) == "0") then
        ofile = adjustl(trim( ifile(1:(ifile_len-7)) // "_zeroexo.exotxt" ))
    else
        ofile = adjustl(trim(arg(2)))
    endif
else
    ofile = adjustl(trim( ifile(1:(ifile_len-7)) // "_zeroexo.exotxt" ))
endif
ofile_len = len_trim(ofile)

! Check that output file is a .g file, if not stop with error
if (ofile_len < 8) then
  write(*,4) "ERROR: OUTPUT FILE MUST BE AN .exotxt FILE"
  stop
  elseif ((num_args>=1) .AND. (ofile((ofile_len-6):ofile_len) /= ".exotxt")) then
    write(*,4) "ERROR: OUTPUT FILE MUST BE AN .exotxt FILE"
    stop
endif

! Set tolerance for determining zero values of coordinates
if (num_args >= 3) then
    read(arg(3), *, iostat=iost) coord_tol
    if (iost /= 0) then
        write(*,4) "ERROR:  IMPROPER VALUE PROVIDED FOR COORDINATE TOLERANCE"
        stop
    endif
else
    coord_tol = default_coord_tol
endif

do i32 = 1, num_args
    write(*,1) arg(i32)
end do

9 format (A,ES18.10)
! Print input from command line to user
if (num_args > 0) then
  print *
  write(*,1) "******************************************************"
  write(*,1) "*                  ZeroExodus Input                  *"
  write(*,1) "******************************************************"
  print *
  write(*,1) "INPUT FILE:   " // trim(ifile)
  write(*,1) "OUTPUT FILE:  " // trim(ofile)
  write(*,9) "COORDINATE TOLERANCE:", coord_tol
  print *
  write(*,1) "******************************************************"
  print *
end if

!-----------------------------!
! Open Input and Output Files !
!-----------------------------!
open(unit=1, file=ifile, iostat=iost, status="old",     action="read")
open(unit=2, file=ofile, iostat=iost, status="replace", action="write")

!----------------------------!
! Begin Main Read/Write Loop !
!----------------------------!
write(*,3) "READING INPUT FILE"
i = 0
main_loop: do
  i = i + 1_ik
  read(1, 1, iostat=iost) text
!print *, trim(text)
  if (is_iostat_end(iost)) then
    write(*,1) "END OF FILE REACHED"
    write(*,4) "******************************************************"
    exit main_loop
  elseif (iost /= 0) then
    write(*,4) "ERROR:  PROBLEM READINPUT AT LINE " // int2text(i)
    stop
  endif
  if (trim(text) == "! Coordinates") then
    write(2,1) trim(text)
    coordinate_loop: do
      i = i + 1_ik
      read(1, 1, iostat=iost) text
!print *, trim(text)
      if (is_iostat_end(iost)) then
        write(*,4) "END OF FILE REACHED"
        exit main_loop
      elseif (iost /= 0) then
        write(*,4) "ERROR:  PROBLEM READINPUT AT LINE " // int2text(i)
        stop
      endif
      text = trim(text)
      if (text(1:1) == "!") then
        write(2,1) trim(text)
        exit coordinate_loop
      else
        read(text, 99) x, y, z
        if (abs(x) <= coord_tol) then
          x = ZERO
          xn = xn + 1_ik
          line_count_flag = .true.
        endif
        if (abs(y) <= coord_tol) then
          y = ZERO
          yn = yn + 1_ik
          line_count_flag = .true.
        endif
        if (abs(z) <= coord_tol) then
          z = ZERO
          zn = zn + 1_ik
          line_count_flag = .true.
        endif
        if (line_count_flag .EQV. .true.) then
          linen = linen + 1_ik
          line_count_flag = .false.
        endif
        write(2, 99) x, y, z
      endif
    end do coordinate_loop
  else
    write(2,1) trim(text)
!print *, trim(text)
  endif
end do main_loop

!------------------------------!
! Close Input and Output Files !
!------------------------------!
close(1)
close(2)

!--------------------------!
! Soft End of Main Program !
!--------------------------!

write(*,1) "NUMBER OF MODIFIED X COORDINATES:  " // trim(Int2Text(xn))
write(*,1) "NUMBER OF MODIFIED Y COORDINATES:  " // trim(Int2Text(yn))
write(*,1) "NUMBER OF MODIFIED Z COORDINATES:  " // trim(Int2Text(zn))
write(*,2) "NUMBER OF MODIFIED LINES:          " // trim(Int2Text(linen))
write(*,4) "******************************************************"
write(*,1) "NORMAL TERMINATION"
write(*,4) "******************************************************"

!----------------------!
! Supporting Functions !
!----------------------!
contains

! Function to convert integers to text/string
function Int2Text(i) result(res)
  character(:), allocatable :: res
  integer(ik),  intent(in)  :: i
  character(range(i)+2)     :: temp
  write(temp,'(I0)') i
  res = trim(temp)
end function Int2Text

! Function to convert integers to text/string
function Int2TextOLD(value)
  implicit none
  ! Calling values
  integer(kind=ik), intent(in) :: value
  character(20) :: Int2Text
  ! Function variables
  character(5) :: frmt
  character(19) :: string
  ! Select proper format
  select case (abs(value))
    case(0_ik:9_ik)
      frmt = '(I1)'
    case(10_ik:99_ik)
      frmt = '(I2)'
    case(100_ik:999_ik)
      frmt = '(I3)'
    case(1000_ik:9999_ik)
      frmt = '(I4)'
    case(10000_ik:99999_ik)
      frmt = '(I5)'
    case(100000_ik:999999_ik)
      frmt = '(I6)'
    case(1000000_ik:9999999_ik)
      frmt = '(I7)'
    case(10000000_ik:99999999_ik)
      frmt = '(I8)'
    case(100000000_ik:999999999_ik)
      frmt = '(I9)'
    case(1000000000_ik:9999999999_ik)
      frmt = '(I10)'
    case(10000000000_ik:99999999999_ik)
      frmt = '(I11)'
    case(100000000000_ik:999999999999_ik)
      frmt = '(I12)'
    case(1000000000000_ik:9999999999999_ik)
      frmt = '(I13)'
    case(10000000000000_ik:99999999999999_ik)
      frmt = '(I14)'
    case(100000000000000_ik:999999999999999_ik)
      frmt = '(I15)'
    case(1000000000000000_ik:9999999999999999_ik)
      frmt = '(I16)'
    case(10000000000000000_ik:99999999999999999_ik)
      frmt = '(I17)'
    case(100000000000000000_ik:999999999999999999_ik)
      frmt = '(I18)'
    case(1000000000000000000_ik:9223372036854775807_ik)
      frmt = '(I19)'
  end select
  ! Convert integer to character
  write(string,frmt) abs(value)
  ! Return left adjusted portion of string with correct sign
  if (value < 0_ik) then
    Int2Text = "-" // adjustl(string)
  else
    Int2Text = adjustl(string)
  endif
end function Int2TextOLD


!---------------------!
! End of Main Program !
!---------------------!
end program ZeroExodus
