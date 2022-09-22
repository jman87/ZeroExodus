function int2text(value)
  use iso_fortran_env
  implicit none
  ! Parameters
  integer, parameter :: ik = int64
  ! Calling values
  integer(kind=ik), intent(in) :: value
  character(20) :: int2text
  ! Function variables
  character(5) :: frmt
  character(20) :: string
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
  if (value < 0) then
    string = "-" // adjustl(string)
  endif
  ! Return left adjusted portion of string
  int2text = adjustl(string)
end function int2text

