CLASS /mbtools/cl_base DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
************************************************************************
* MBT Base
*
* (c) MBT 2020 https://marcbernardtools.com/
************************************************************************

  PUBLIC SECTION.

    METHODS initialize
      IMPORTING
        !iv_all_tools   TYPE abap_bool
        !iv_all_bundles TYPE abap_bool .
    METHODS screen .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mv_all_tools TYPE abap_bool .
    DATA mv_all_bundles TYPE abap_bool .
ENDCLASS.



CLASS /MBTOOLS/CL_BASE IMPLEMENTATION.


  METHOD initialize.

    mv_all_tools = iv_all_tools.
    mv_all_bundles = iv_all_bundles.

  ENDMETHOD.


  METHOD screen.

    DATA lv_show TYPE abap_bool.

    LOOP AT SCREEN.
      lv_show = abap_true.

      IF screen-name = 'P_TITLE' AND
        ( mv_all_tools = abap_true OR mv_all_bundles = abap_true ).
        lv_show = abap_false.
      ELSEIF mv_all_bundles = abap_true AND
        ( screen-name = 'P_ACT' OR screen-name = 'P_DEACT' OR
          screen-name = 'P_CHECK' OR screen-name = 'P_UPDATE' OR
          screen-name = 'P_UNINST' ).
        lv_show = abap_false.
      ENDIF.

      IF lv_show = abap_true.
        screen-input = '1'.
      ELSE.
        screen-input = '0'.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
