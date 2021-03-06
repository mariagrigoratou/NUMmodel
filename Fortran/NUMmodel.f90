!
! Module to handle the NUM model framework
!
module NUMmodel
  use globals
  use spectrum
  use generalists
  use generalists_csp
  use copepods
  use debug
  implicit none

  integer:: nGroups, iGroup
  integer, dimension(:), allocatable:: typeGroups
  type(typeSpectrum), dimension(:), allocatable:: group
  integer, dimension(:), allocatable:: ixStart, ixEnd

  real(dp), dimension(:,:), allocatable:: theta
  real(dp), dimension(:), allocatable:: upositive
  
  real(dp), dimension(:), allocatable:: pHTL ! Selectivity function for HTL mortality
  real(dp) :: mortHTL ! Level of HTL mortality (see below for override)
  real(dp):: gammaHTL ! Parameter for quadratic HTL mortality
  logical:: bQuadraticHTL ! Boolean flag to signify whether mortality is standard or "quadratic"
  ! Defaults to true; can be overridden but parameters must then be set with a
  ! call to parametersFinalize()
  
  type(typeRates):: rates

  real(dp), dimension(:), allocatable:: m, z, beta, sigma, AF, JFmax, epsilonF ! Feeding parameters

contains
  ! ======================================
  !  Various model setups
  ! ======================================


  ! -----------------------------------------------
  ! A basic setup with only generalists
  ! -----------------------------------------------
  subroutine setupGeneralistsOnly()
    call parametersInit(1, 10) ! 1 group, 10 size classes (excl nutrients and DOC)
    call parametersAddGroup(typeGeneralist, 10, 0.1d0) ! generalists with 10 size classes
    bQuadraticHTL = .false. ! Use standard "linear" mortality
    call parametersFinalize()
  end subroutine setupGeneralistsOnly

  ! -----------------------------------------------
  ! A basic setup with only generalists -- Camila
  ! -----------------------------------------------
  subroutine setupGeneralistsOnly_csp()
    call parametersInit(1, 10) ! 1 group, 10 size classes (excl nutrients and DOC)
    call parametersAddGroup(typeGeneralist_csp, 10, 0.1d0) ! generalists with 10 size classes
    call parametersFinalize()
  end subroutine setupGeneralistsOnly_csp

  ! -----------------------------------------------
  ! A basic setup with generalists and 1 copepod
  ! -----------------------------------------------
  subroutine setupGeneralistsCopepod()
    call parametersInit(2, 20)
    call parametersAddGroup(typeGeneralist, 10, 0.1d0)
    call parametersAddGroup(typeCopepod, 10, .1d0) ! add copepod with adult mass .1 mugC
    call parametersFinalize()
  end subroutine setupGeneralistsCopepod
  
  ! -----------------------------------------------
  ! A generic setup with generalists and a number of copepod species
  ! -----------------------------------------------
  subroutine setupGeneric(mAdult)
    real(dp), intent(in):: mAdult(:)
    integer, parameter:: n = 10 ! number of size classes in each group
    integer:: iCopepod

    call parametersInit(size(mAdult)+1, n*(size(mAdult)+1))
    call parametersAddGroup(typeGeneralist, n, 0.1d0)
    do iCopepod = 1, size(mAdult)
       call parametersAddGroup(typeCopepod, n, mAdult(iCopepod)) ! add copepod
    end do
    call parametersFinalize()
  end subroutine setupGeneric

  ! ======================================
  !  Model initialization stuff:
  ! ======================================

  ! -----------------------------------------------
  ! Initialize parameters
  ! In:
  !    nnGroups: number of size spectrum groups
  !    nnGrid: total length of the grid (excl 2 points for N and DOC)
  ! -----------------------------------------------
  subroutine parametersInit(nnGroups, nnGrid)
    integer, intent(in):: nnGrid, nnGroups
    !
    ! Set groups:
    !
    nGroups = nnGroups
    nGrid = nnGrid+2
    iGroup = 0
    !
    ! Allocate variables:
    !
    if (allocated(m)) then
       deallocate(m)
       deallocate(z)
       deallocate(beta)
       deallocate(sigma)
       deallocate(AF)
       deallocate(JFmax)
       deallocate(epsilonF)

       deallocate(group)
       deallocate(typeGroups)
       deallocate(ixStart)
       deallocate(ixEnd)

       deallocate(upositive)

       ! Interaction matrix:
       deallocate(theta)
       !
       ! Deallocate rates:
       !
       deallocate(rates%dudt)

       deallocate(rates%F)
       deallocate(rates%flvl)
       deallocate(rates%JF)
       deallocate(rates%JEnc)

       deallocate(rates%JN)
       deallocate(rates%JL)
       deallocate(rates%JDOC)
       deallocate(rates%JNtot)
       deallocate(rates%JCtot)
       deallocate(rates%Jtot)
       deallocate(rates%JLreal)
       deallocate(rates%JCloss_feeding)
       deallocate(rates%JCloss_photouptake)
       deallocate(rates%JNlossLiebig)
       deallocate(rates%JClossLiebig)
       deallocate(rates%JNloss)
       deallocate(rates%JCloss)

       deallocate(rates%mortpred)
       deallocate(rates%mortHTL)
       deallocate(pHTL)

       deallocate(rates%g)
       deallocate(rates%mortStarve)
       deallocate(rates%mort)

    end if

    allocate(m(nGrid))
    allocate(z(nGrid))
    allocate(beta(nGrid))
    allocate(sigma(nGrid))
    allocate(AF(nGrid))
    allocate(JFmax(nGrid))
    allocate(epsilonF(nGrid))

    allocate(group(nGroups))
    allocate(typeGroups(nGroups))
    allocate(ixStart(nGroups))
    allocate(ixEnd(nGroups))

    allocate(upositive(nGrid))

    ! Interaction matrix:
    allocate(theta(nGrid,nGrid))
    !
    ! Allocate rates:
    !
    allocate(rates%dudt(nGrid))

    allocate(rates%F(nGrid))
    allocate(rates%flvl(nGrid))
    allocate(rates%JF(nGrid))
    allocate(rates%JEnc(nGrid))

    allocate(rates%JN(nGrid))
    allocate(rates%JL(nGrid))
    allocate(rates%JDOC(nGrid))
    allocate(rates%JNtot(nGrid))
    allocate(rates%JCtot(nGrid))
    allocate(rates%Jtot(nGrid))
    allocate(rates%JLreal(nGrid))
    allocate(rates%JCloss_feeding(nGrid))
    allocate(rates%JCloss_photouptake(nGrid))
    allocate(rates%JNlossLiebig(nGrid))
    allocate(rates%JClossLiebig(nGrid))
    allocate(rates%JNloss(nGrid))
    allocate(rates%JCloss(nGrid))

    allocate(rates%mortpred(nGrid))
    allocate(rates%mortHTL(nGrid))
    allocate(pHTL(nGrid))

    allocate(rates%g(nGrid))
    allocate(rates%mortStarve(nGrid))
    allocate(rates%mort(nGrid))

    bQuadraticHTL = .true. ! Default to quadratic mortality
  end subroutine parametersInit
  ! -----------------------------------------------
  !  Add a size spectrum group
  !  In:
  !    typeGroup: the group type (see definitions in Globals.f90
  !    n: number of grid points
  !    mMax: the maximum size (mid-point in grid cell)
  ! -----------------------------------------------
  subroutine parametersAddGroup(typeGroup, n, mMax)
    integer, intent(in):: typeGroup, n
    real(dp), intent(in):: mMax
    !
    ! Find the group number and grid location:
    !
    iGroup = iGroup + 1
    if (iGroup.eq.1) then
       ixStart(iGroup) = idxB
    else
       ixStart(iGroup) = ixEnd(iGroup-1)+1
    end if
    ixEnd(iGroup) = ixStart(iGroup)+n-1

    if (ixEnd(iGroup) .gt. nGrid) then
       write(6,*) 'Attempting to add more grid points than allocated', ixEnd(igroup), nGrid
       stop 1
    end if
    !
    ! Add the group
    !
    typeGroups(iGroup) = typeGroup
    select case (typeGroup)
    case (typeGeneralist)
      group(iGroup) = initGeneralists(n, ixStart(iGroup)-1, mMax)
    case (typeGeneralist_csp)
      group(iGroup) = initGeneralists_csp(n, ixStart(iGroup)-1, mMax)
    case(typeCopepod)
       group(iGroup) = initCopepod(n, ixStart(iGroup)-1, mMax)
    end select
    !
    ! Import grid to globals:
    !
    m(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%m
    z(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%z
    !
    ! Import feeding parameters:
    !
    beta(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%beta
    sigma(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%sigma
    AF(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%AF
    JFmax(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%JFmax
    epsilonF(ixStart(iGroup) : ixEnd(iGroup)) = group(iGroup)%epsilonF

  end subroutine parametersAddGroup
  ! -----------------------------------------------
  !  Finalize the setting of parameters. Must be called when
  !  all groups have been added.
  ! -----------------------------------------------
  subroutine parametersFinalize()
    integer:: i,j
    real(dp):: betaHTL, mHTL, mMax
    !
    ! Calc theta:
    !
    do i = idxB, nGrid
       do j = idxB, nGrid
          theta(i,j) = exp( -(log(m(i)/m(j)/beta(i)))**2/(2*sigma(i)**2))
       end do
    end do
    !
    ! Calc htl mortality
    !
    betaHTL = 500.
    if (.not. bQuadraticHTL) then
       !
       ! Standard HTL mortality. In this case "pHTL" represent the selectivity of HTL mortality
       !
       mHTL = m(nGrid)/betaHTL**1.5  ! Bins affected by HTL mortality
       mortHTL = 0.1
       pHTL(idxB:nGrid) = (1/(1+(m(idxB:nGrid)/mHTL)**(-2)))
    else
       !
       ! Linear HTL mortality (commonly referred to as "quadratic")
       ! In this case "pHTL" represents p_HTL*m^-1/4 from eq (16) in Serra-Pompei (2020)
       !
       mortHTL = 0.003 ! Serra-Pompei (2020)
       gammaHTL = 0.2 ! ibid
       mMax = maxval(m(idxB:nGrid))
       do i=idxB, nGrid
          if (m(i) .lt. (mMax/betaHTL)) then
             pHTL(i) = exp( -(log(m(i)*betaHTL/mMax))**2/4.)
          else
             pHTL(i) = 1.
          end if
       end do
       pHTL(idxB:nGrid) = pHTL(idxB:nGrid) * m(idxB:nGrid)**(-0.25)
    end if
    !write(6,*) m,pHTL
  end subroutine parametersFinalize

  ! ======================================
  !  Calculate rates and derivatives:
  ! ======================================

  !
  ! Calculate derivatives for unicellular groups
  ! In:
  !   gammaN and gammaDOC are reduction factors [0...1] of uptakes of N and DOC,
  !   used for correction of Euler integration. If no correction is used, just set to 1.0
  !   This correction procedure is needed for correct Euler integration.
  subroutine calcDerivativesUnicellulars(upositive, L, gammaN, gammaDOC)
    real(dp), intent(in):: upositive(:), L, gammaN, gammaDOC
    !type(typeRates), intent(inout):: rates
    integer:: i,j
    !
    ! Calc uptakes of all unicellular groups:
    !
    do iGroup = 1, nGroups
       select case (typeGroups(iGroup))
       case (typeGeneralist)
          call calcRatesGeneralists(group(iGroup), &
               rates, L, upositive(idxN), upositive(idxDOC), gammaN, gammaDOC)
       case(typeGeneralist_csp)
          call calcRatesGeneralists_csp(group(iGroup), &
               upositive(group(iGroup)%ixStart:group(iGroup)%ixEnd), &
               rates, L, upositive(idxN), upositive(idxDOC), gammaN, gammaDOC)
       end select
    end do
    !
    ! Calc predation mortality
    !
    do i=idxB, nGrid
       rates%mortpred(i) = 0.d0
       do j=idxB, nGrid
          if (rates%F(j) .ne. 0.d0) then
             rates%mortpred(i) = rates%mortpred(i)  &
                  + theta(j,i) * rates%JF(j)*upositive(j)/(epsilonF(j)*m(j)*rates%F(j))
          end if
       end do
    end do
    !
    ! Assemble derivatives:
    !
    rates%dudt(idxN) = 0
    rates%dudt(idxDOC) = 0
    do iGroup = 1, nGroups
       select case (typeGroups(iGroup))
       case (typeGeneralist)
          call calcDerivativesGeneralists(group(iGroup),&
               upositive(group(iGroup)%ixStart:group(iGroup)%ixEnd), &
               rates)
       case (typeGeneralist_csp)
          call calcDerivativesGeneralists_csp(group(iGroup),&
               upositive(group(iGroup)%ixStart:group(iGroup)%ixEnd), &
               rates)
       end select
    end do
  end subroutine calcDerivativesUnicellulars

  ! -----------------------------------------------
  !  Calculate the derivatives for all groups:
  !  In:
  !    L: light level
  ! -----------------------------------------------
  subroutine calcDerivatives(u, L, dt)
    real(dp), intent(in):: L, dt, u(:)
    integer:: i, j, iGroup
    real(dp):: gammaN, gammaDOC
    !
    ! Use only the positive part of biomasses for calculation of derivatives:
    !
    do i = 1, nGrid
       upositive(i) = max( 0.d0, u(i) )
    end do
    !
    ! Calc uptakes of food
    !
    do i = idxB, nGrid
       rates%F(i) = 0.d0
       do j = idxB, nGrid
          rates%F(i) = rates%F(i) + theta(i,j)*upositive(j)
       end do
    end do
    rates%flvl(idxB:nGrid) = AF(idxB:nGrid)*rates%F(idxB:nGrid) / (AF(idxB:nGrid)*rates%F(idxB:nGrid) + JFmax(idxB:nGrid))
    rates%JF(idxB:nGrid) = rates%flvl(idxB:nGrid) * JFmax(idxB:nGrid)
    !
    ! Calc HTL mortality:
    !
    if (bQuadraticHTL) then
       do i = idxB, nGrid
          rates%mortHTL(i) = calcHTL(upositive, i)*upositive(i)
       end do
    else
       rates%mortHTL(idxB:nGrid) = mortHTL*pHTL(idxB:nGrid)
    end if
    !
    ! Calc derivatives of unicellular groups
    !
    gammaN = 1.d0
    gammaDOC = 1.d0
    call calcDerivativesUnicellulars(upositive, L, gammaN, gammaDOC)
    !
    ! Make a correction if nutrient fields will become less than zero:
    !
    if ((u(idxN) + rates%dudt(idxN)*dt) .lt. 0) then
       gammaN = max(0.d0, min(1.d0, -u(idxN)/(rates%dudt(idxN)*dt)))
    end if
    if ((u(idxDOC) + rates%dudt(idxDOC)*dt) .lt. 0) then
       gammaDOC = max(0.d0, min(1.d0, -u(idxDOC)/(rates%dudt(idxDOC)*dt)))
    end if
    if ((gammaN .lt. 1.d0) .or. (gammaDOC .lt. 1.d0)) then
       !write(6,*) u(idxN), u(idxDOC), rates%dudt(idxN), rates%dudt(idxDOC), gammaN, gammaDOC
       call calcDerivativesUnicellulars(upositive, L, gammaN, gammaDOC)
       !write(6,*) '->', rates%dudt(idxN), rates%dudt(idxDOC)
    end if
    !
    ! Calc derivatives of multicellular groups:
    !
    do iGroup = 2, nGroups
       call calcDerivativesCopepod(group(iGroup), &
            upositive(group(iGroup)%ixStart:group(iGroup)%ixEnd), &
            rates)
    end do
  end subroutine calcDerivatives
  !
  ! Returns the htl mortlity divided by h for size bin i
  !
  function calcHTL(u, i) result(mHTL)
    real(dp) :: mHTL, B
    real(dp), intent(in):: u(:)
    integer, intent(in):: i
    integer:: j
    
    !
    ! First calc the biomass within a size range:
    !
    B = 0.d0
    do j = 1, nGrid
       if (m(j)>m(i)/3.16 .and. m(j)<m(i)*3.16) then
          B = B + u(j)
       end if
    end do
    
    mHTL = pHTL(i)*mortHTL/z(i)*u(i)**gammaHTL*B**(1.-gammaHTL)
  end function calcHTL
  
  ! -----------------------------------------------
  ! Simulate a chemostat with Euler integration
  ! -----------------------------------------------
  subroutine simulateChemostatEuler(u, L, Ndeep, diff, tEnd, dt)
    real(dp), intent(inout):: u(:) ! Initial conditions and result after integration
    real(dp), intent(in):: L      ! Light level
    real(dp), intent(in):: Ndeep ! Nutrient in the deep layer
    real(dp), intent(in):: diff      ! Diffusivity
    real(dp), intent(in):: tEnd ! Time to simulate
    real(dp), intent(in):: dt    ! time step
    integer:: i, iEnd

    iEnd = floor(tEnd/dt)

    do i=1, iEnd
       call calcDerivatives(u, L, dt)
       rates%dudt(idxN) = rates%dudt(idxN) + diff*(Ndeep-u(idxN))
       rates%dudt(idxDOC) = rates%dudt(idxDOC) + diff*(0.d0 - u(idxDOC))
       !
       ! Note: should not be done for copepods:
       !
       !rates%dudt(idxB:nGrid) = rates%dudt(idxB:nGrid) + diff*(0.d0 - u(idxB:nGrid))
       u = u + rates%dudt*dt
       !write(6,*) calcN(u)
    end do
  end subroutine simulateChemostatEuler

  function calcN(u) result(N)
    real(dp), intent(in):: u(:)
    integer:: i
    real(dp):: N
    
    N = 0
    N = u(idxN)
    do i = 1, nGrid
       N = N + u(2+i)/5.68
    end do
  end function calcN
    

  ! -----------------------------------------------
  ! Simulate with Euler integration
  ! -----------------------------------------------
  subroutine simulateEuler(u, L, tEnd, dt)
    real(dp), intent(inout):: u(:) ! Initial conditions and result after integration
    real(dp), intent(in):: L      ! Light level
    real(dp), intent(in):: tEnd ! Time to simulate
    real(dp), intent(in):: dt    ! time step
    integer:: i, iEnd

    iEnd = floor(tEnd/dt)

    do i=1, iEnd
       call calcDerivatives(u, L, dt)
       u = u + rates%dudt*dt
    end do
  end subroutine simulateEuler
  ! -----------------------------------------------
  ! Temperature Q10 function
  ! -----------------------------------------------
  function fTemp(Q10, T) result(f)
    real(dp), intent(in), value:: Q10, T
    real(dp):: f

    f = Q10**(T/10.-1.)
  end function fTemp

end module NUMmodel
