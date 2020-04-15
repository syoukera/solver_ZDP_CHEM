      SUBROUTINE ZDPINIT()
      use ZDPlasKin

      OPEN (17, FORM='FORMATTED', FILE = 'output/zdpout')

      call ZDPlasKin_init()

      RETURN
      END
C
C---------------------------------------------------------------
C
      SUBROUTINE RCONP_ZDP (TIME, Z, ZP, DELTA, IRES, RPAR, IPAR)
      use ZDPlasKin

      IMPLICIT DOUBLE PRECISION (A-H, O-Z), INTEGER (I-N)
      LOGICAL gas_heating
      DIMENSION Z(*), ZP(*), DELTA(*), RPAR(*), IPAR(*),
     1          source_terms_species(83)
      COMMON /RES1/ P
C
C  Residual of differential equations for constant pressure case
C
C  Variables:
C    Z(1)   = temperature (Kelvin)
C    Z(K+1) = species mass fractions
C    P      = pressure (dyne/cm2) - constant in time
C    RHO    = density (gm/cm3)
C    RPAR   = array of reaction pre-exponential constants
C
      KK     = IPAR(1)
      IPRCK  = IPAR(2)
      IPRD   = IPAR(3)
      IPWT   = IPAR(6)
      IPWDOT = IPAR(7)
      IPH    = IPAR(8)
      IPICK  = IPAR(9)
      LOUT   = IPAR(10)
      II     = IPAR(11)
C
C        MODIFY CHEMKIN WORK ARRAY FOR PRE-EXPONENTIAL
C
      DO 15 I = 1, II
        CALL CKRDEX (-I, RPAR(IPRCK), RPAR(IPRD+I-1))
15    CONTINUE
C
C         CALL CHEMKIN SUBROUTINES
C
      CALL CKRHOY (P, Z(1), Z(2), IPAR(IPICK), RPAR(IPRCK), RHO)
      CALL CKCPBS (Z(1), Z(2), IPAR(IPICK), RPAR(IPRCK), CPB)
      CALL CKWYP  (P, Z(1), Z(2), IPAR(IPICK), RPAR(IPRCK),
     1             RPAR(IPWDOT))
      CALL CKHMS  (Z(1), IPAR(IPICK), RPAR(IPRCK), RPAR(IPH))
      IF (RHO .EQ. 0.0) THEN
         WRITE (LOUT, '(/1X,A)') 'Stop, zero density in RCONP.'
         STOP
      ENDIF
      VOLSP = 1. / RHO
C
C         ENERGY EQUATION
C
      SUM = 0.
      DO 100 K = 1, KK
         K1 = K-1
         SUM = SUM + RPAR(IPH+K1) * RPAR(IPWDOT+K1) * RPAR(IPWT+K1)
 100  CONTINUE
      DELTA(1) = ZP(1) + VOLSP *SUM /CPB
C
C         SPECIES EQUATIONS
C
      DO 200 K = 1, KK
         K1 = K-1
         DELTA(K+1) = ZP(K+1) - RPAR(IPWDOT+K1) *RPAR(IPWT+K1) *VOLSP
 200  CONTINUE

C ---------- ZDPlasKin ----------

      ! Set intial conditions
      reduced_field_Td = 180.d0
      gas_temperature_K = 296.0d0
      call ZDPlasKin_set_conditions(GAS_TEMPERATURE=gas_temperature_K,
     1                              REDUCED_FIELD=reduced_field_Td)

      ! call ZDPlasKin_set_conditions(SPEC_HEAT_RATIO=spec_heat_ratio, GAS_HEATING=gas_heating )
      density_ini_ch4  = 1.6254d+17
      density_ini_o2   = 3.2705d+17
      density_ini_he   = 1.4688d+18
      density_ini_elec = 1.d+5  
      call ZDPlasKin_set_density( 'CH4',density_ini_ch4)
      call ZDPlasKin_set_density(  'O2',density_ini_o2)
      call ZDPlasKin_set_density(  'He',density_ini_he)
      call ZDPlasKin_set_density(   'e',density_ini_elec)

      ! Calcurate Energy Eq. (Look at line:47)
      spec_heat_ratio          = 7.d0/5.d0
      elec_power_elastic_n     = 0.d0
      gas_heating              = .true.
C
      call ZDPlasKin_get_rates(SOURCE_TERMS=source_terms_species)

      write(17, *) (source_terms_species(I), I = 1, II)

      RETURN
      END
C
C---------------------------------------------------------------
C
