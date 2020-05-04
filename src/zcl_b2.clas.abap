class ZCL_B2 definition
  public
  final
  create public .

public section.

  class-methods READ
    importing
      !IV_PERNR type P_PERNR
      !IV_BEGDA type BEGDA
      !IV_ENDDA type ENDDA
    returning
      value(RT_B2) type ZST_B2 .
  class-methods READ_PERIOD
    importing
      !IV_PERNR type P_PERNR
      !IV_BEG_PERIOD type FAPER
      !IV_END_PERIOD type FAPER
    returning
      value(RT_B2) type ZST_B2 .
protected section.
private section.
ENDCLASS.



CLASS ZCL_B2 IMPLEMENTATION.


method READ.

    data lt_tbuff TYPE cl_hrpclx_buffer=>ty_t_buffer.

    CALL FUNCTION 'HR_TIME_RESULTS_GET'
      EXPORTING
        GET_PERNR                   = iv_pernr
        GET_PABRJ                   = iv_endda(4)
        GET_PABRP                   = iv_endda+4(2)
*       GET_KDATE                   = iv_endda
        GET_CLTYP                   = '1'
       IMPORTING
        GET_BEZUG                   = rt_b2-data-fs_bezug
        GET_KNTAG                   = rt_b2-data-fs_kntag
      TABLES
        GET_TBUFF                   = lt_tbuff
*       GET_BUFFER_DIR              =
        GET_WPBP                    = rt_b2-data-ft_wpbp
        GET_ALP                     = rt_b2-data-ft_alp
        GET_AB                      = rt_b2-data-ft_ab
        GET_SKO                     = rt_b2-data-ft_sko
        GET_VERT                    = rt_b2-data-ft_vert
        GET_SALDO                   = rt_b2-data-ft_saldo
        GET_ZES                     = rt_b2-data-ft_zes
        GET_ZKO                     = rt_b2-data-ft_zko
        GET_FEHLER                  = rt_b2-data-ft_fehler
        GET_ABWKONTI                = rt_b2-data-ft_abwkonti
        GET_PSP                     = rt_b2-data-ft_psp
        GET_ANWKONTI                = rt_b2-data-ft_anwkonti
        GET_MEHR                    = rt_b2-data-ft_mehr
        GET_ANWES                   = rt_b2-data-ft_anwes
        GET_RUFB                    = rt_b2-data-ft_rufb
        GET_ZL                      = rt_b2-data-ft_zl
        GET_URLAN                   = rt_b2-data-ft_urlan
        GET_VS                      = rt_b2-data-ft_vs
        GET_CVS                     = rt_b2-data-ft_cvs
        GET_C1                      = rt_b2-data-ft_c1
        GET_AT                      = rt_b2-data-ft_at
        GET_PT                      = rt_b2-data-ft_pt
        GET_WST                     = rt_b2-data-ft_wst
        GET_CWST                    = rt_b2-data-ft_cwst
        GET_QTACC                   = rt_b2-data-ft_qtacc
        GET_QTBASE                  = rt_b2-data-ft_qtbase
        GET_QTTRANS                 = rt_b2-data-ft_qttrans
     EXCEPTIONS
       NO_PERIOD_SPECIFIED         = 1
       WRONG_CLUSTER_VERSION       = 2
       NO_READ_AUTHORITY           = 3
       CLUSTER_ARCHIVED            = 4
       TECHNICAL_ERROR             = 5
       OTHERS                      = 6
              .
    IF SY-SUBRC <> 0.
* Implement suitable error handling here
    ENDIF.

    rt_b2-pernr = iv_pernr.



  endmethod.


method READ_PERIOD.

    data lv_begda type begda.
    data lv_endda type endda.

    concatenate iv_beg_period '01' into lv_begda.
    concatenate iv_end_period '01' into lv_endda.

    call function 'RP_LAST_DAY_OF_MONTHS'
      exporting
        day_in                  = lv_endda
      IMPORTING
        LAST_DAY_OF_MONTH       = lv_endda
      EXCEPTIONS
        DAY_IN_NO_DATE          = 1
        OTHERS                  = 2.

    if sy-subrc <> 0.

    endif.

    rt_b2 = read( iv_pernr = iv_pernr iv_begda = lv_begda iv_endda = lv_endda ).

  endmethod.
ENDCLASS.
