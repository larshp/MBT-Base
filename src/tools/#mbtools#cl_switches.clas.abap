************************************************************************
* /MBTOOLS/CL_SWITCHES
* MBT Switches
*
* WARNING: Any syntax errors in this class may impact system stability
* DO NOT CHANGE
*
* (c) MBT 2020 https://marcbernardtools.com/
************************************************************************
CLASS /mbtools/cl_switches DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS class_constructor .
    CLASS-METHODS is_active
      IMPORTING
        VALUE(iv_title)  TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool .
    CLASS-METHODS is_debug
      IMPORTING
        VALUE(iv_title)  TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool .
    CLASS-METHODS is_trace
      IMPORTING
        VALUE(iv_title)  TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_reg,
        " Registry Switches
        switches   TYPE string VALUE 'Switches' ##NO_TEXT,
        key_active TYPE string VALUE 'Active' ##NO_TEXT,
        key_debug  TYPE string VALUE 'Debug' ##NO_TEXT,
        key_trace  TYPE string VALUE 'Trace' ##NO_TEXT,
      END OF c_reg .
    CLASS-DATA go_reg_root TYPE REF TO /mbtools/cl_registry .

    CLASS-METHODS check_switch
      IMPORTING
        VALUE(iv_title)  TYPE string
        VALUE(iv_key)    TYPE string
      RETURNING
        VALUE(rv_result) TYPE abap_bool .
ENDCLASS.



CLASS /MBTOOLS/CL_SWITCHES IMPLEMENTATION.


  METHOD check_switch.

    DATA:
      lv_name       TYPE string,
      ls_bundle     TYPE /mbtools/cl_registry=>ty_keyobj,
      lt_bundles    TYPE /mbtools/cl_registry=>ty_keyobjs,
      lo_reg_bundle TYPE REF TO /mbtools/cl_registry,
      lo_reg_tool   TYPE REF TO /mbtools/cl_registry,
      lo_reg_entry  TYPE REF TO /mbtools/cl_registry,
      lt_users      TYPE TABLE OF string,
      lv_value      TYPE string.

    lv_name = to_upper( iv_title ).
    REPLACE ALL OCCURRENCES OF ` ` IN lv_name WITH `_`.

    TRY.
        lt_bundles = go_reg_root->get_subentries( ).

        LOOP AT lt_bundles INTO ls_bundle.
          " Is tool installed?
          lo_reg_tool = ls_bundle-value->get_subentry( lv_name ).
          IF lo_reg_tool IS BOUND.
            EXIT.
          ENDIF.
        ENDLOOP.
        CHECK lo_reg_tool IS BOUND.

        " Switches entry
        lo_reg_entry = lo_reg_tool->get_subentry( c_reg-switches ).
        CHECK lo_reg_entry IS BOUND.

        " Is switch active?
        lv_value = lo_reg_entry->get_value( iv_key ).
        IF lv_value = abap_true.
          rv_result = abap_true.
        ELSEIF lv_value = sy-uname.
          rv_result = abap_true.
        ELSEIF lv_value CS ','.
          SPLIT lv_value AT ',' INTO TABLE lt_users.
          FIND sy-uname IN TABLE lt_users.
          IF sy-subrc = 0.
            rv_result = abap_true.
          ENDIF.
        ENDIF.

      CATCH cx_root.
        rv_result = abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD class_constructor.

    TRY.
        " Get root of registry
        go_reg_root = /mbtools/cl_registry=>get_root( ).

      CATCH /mbtools/cx_exception.
        " MBT Base is not installed properly. Contact Marc Bernard Tools
        ASSERT 0 = 1.
    ENDTRY.

  ENDMETHOD.


  METHOD is_active.

    rv_result = check_switch( iv_title = iv_title
                              iv_key   = c_reg-key_active ).

  ENDMETHOD.


  METHOD is_debug.

    rv_result = check_switch( iv_title = iv_title
                              iv_key   = c_reg-key_debug ).

  ENDMETHOD.


  METHOD is_trace.

    rv_result = check_switch( iv_title = iv_title
                              iv_key   = c_reg-key_trace ).

  ENDMETHOD.
ENDCLASS.
