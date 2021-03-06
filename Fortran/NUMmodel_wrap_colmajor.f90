module NUMmodel_wrap
  use iso_c_binding, only: c_double, c_int
  use NUMmodel, only:  setupGeneralistsOnly, setupGeneralistsCopepod, &
       setupGeneric, calcderivatives, rates, m, &
       simulateChemostatEuler, simulateEuler
  use globals

  implicit none

contains

  subroutine f_setupGeneralistsOnly() bind(c)
    call setupGeneralistsOnly()
  end subroutine f_setupGeneralistsOnly

  subroutine f_setupGeneralistsCopepod() bind(c)
    call setupGeneralistsCopepod()
  end subroutine f_setupGeneralistsCopepod

  subroutine f_setupGeneric(nCopepods, mAdult) bind(c)
    integer(c_int), intent(in), value:: nCopepods
    real(c_double), intent(in):: mAdult(nCopepods)

    call setupGeneric(mAdult)
  end subroutine f_setupGeneric
  
  subroutine f_calcDerivatives(nGrid, u, L, dt, dudt) bind(c)
    integer(c_int), intent(in), value:: nGrid
    real(c_double), intent(in), value:: L, dt
    real(c_double), intent(in):: u(nGrid)
    real(c_double), intent(out):: dudt(nGrid)
    
    call calcDerivatives(u, L, dt)
    dudt = rates%dudt
  end subroutine f_calcDerivatives

  subroutine f_calcRates(nGrid, u, L, jN, jL, jF) bind(c)
    integer(c_int), intent(in), value:: nGrid
    real(c_double), intent(in):: u(nGrid)
    real(c_double), intent(in), value:: L
    real(c_double), intent(out):: jN(nGrid), jL(nGrid), jF(nGrid)

    call calcDerivatives(u, L, 0.d0)
    jN(idxB:nGrid) = rates%JN(idxB:nGrid) / m(idxB:nGrid)
    jL(idxB:nGrid) = rates%JL(idxB:nGrid) / m(idxB:nGrid)
    jF(idxB:nGrid) = rates%JF(idxB:nGrid) / m(idxB:nGrid)
  end subroutine f_calcRates
    
  subroutine f_simulateChemostatEuler(nGrid, u, L, Ndeep, diff, tEnd, dt) bind(c)
    integer(c_int), intent(in), value:: nGrid
    real(c_double), intent(inout):: u(nGrid)
    real(c_double), intent(in), value:: L, Ndeep, diff, tEnd, dt
    
    call simulateChemostatEuler(u, L, Ndeep, diff, tEnd, dt)
  end subroutine f_simulateChemostatEuler
  
  subroutine f_simulateEuler(nGrid, u, L, tEnd, dt) bind(c)
    integer(c_int), intent(in), value:: nGrid
    real(c_double), intent(inout):: u(nGrid)
    real(c_double), intent(in), value:: L, tEnd, dt
    
    call simulateEuler(u, L, tEnd, dt)
  end subroutine f_simulateEuler
  
end module NUMmodel_wrap


