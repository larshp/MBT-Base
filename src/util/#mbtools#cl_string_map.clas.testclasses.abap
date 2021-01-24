CLASS ltcl_string_map DEFINITION
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT
  FINAL.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_struc,
        a TYPE string,
        b TYPE abap_bool,
        c TYPE i,
      END OF ty_struc.

    METHODS get_set_has FOR TESTING.
    METHODS size_empty_clear FOR TESTING.
    METHODS delete FOR TESTING.
    METHODS keys_values FOR TESTING.
    METHODS to_struc FOR TESTING.
    METHODS from_struc FOR TESTING.
    METHODS strict FOR TESTING.
    METHODS from_to_struc_negative FOR TESTING.
    METHODS from_entries FOR TESTING.
    METHODS freeze FOR TESTING.
    METHODS create_from FOR TESTING.
    METHODS case_insensitive FOR TESTING.

ENDCLASS.

CLASS ltcl_string_map IMPLEMENTATION.

  METHOD create_from.

    DATA lx_error TYPE REF TO cx_root.
    DATA lo_src TYPE REF TO /mbtools/cl_string_map.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    DATA: BEGIN OF ls_dummy, a TYPE string VALUE '1', END OF ls_dummy.

    lo_src = /mbtools/cl_string_map=>create( ).
    lo_src->set(
      iv_key = 'A'
      iv_val = '1' ).

    TRY.
        /mbtools/cl_string_map=>create( iv_from = `abc` ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'Incorrect input for string_map=>create, typekind g'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        /mbtools/cl_string_map=>create( iv_from = me ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'Incorrect string map instance to copy from'
          act = lx_error->get_text( ) ).
    ENDTRY.

    " From obj
    lo_cut = /mbtools/cl_string_map=>create( iv_from = lo_src ).
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lo_cut->size( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = '1'
      act = lo_cut->get( 'A' ) ).

    " From tab
    lo_cut = /mbtools/cl_string_map=>create( iv_from = lo_src->mt_entries ).
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lo_cut->size( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = '1'
      act = lo_cut->get( 'A' ) ).

    " From struc
    lo_cut = /mbtools/cl_string_map=>create( iv_from = ls_dummy ).
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lo_cut->size( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = '1'
      act = lo_cut->get( 'A' ) ).

  ENDMETHOD.

  METHOD freeze.

    DATA lt_entries TYPE /mbtools/cl_string_map=>ty_entries.
    DATA ls_dummy TYPE syst.
    DATA lx_error TYPE REF TO cx_root.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' )->freeze( ).

    TRY.
        lo_cut->set(
          iv_key = 'A'
          iv_val = '2' ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->set(
          iv_key = 'B'
          iv_val = '2' ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->delete( 'A' ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->clear( ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->from_entries( lt_entries ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->from_struc( ls_dummy ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'String map is read only'
          act = lx_error->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD get_set_has.

    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' ).
    lo_cut->set(
      iv_key = 'B'
      iv_val = 'bvalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'A' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'bvalue'
      act = lo_cut->get( 'B' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = ''
      act = lo_cut->get( 'C' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_cut->has( 'C' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lo_cut->has( 'A' ) ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'newvalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'newvalue'
      act = lo_cut->get( 'A' ) ).

  ENDMETHOD.

  METHOD size_empty_clear.

    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lo_cut->size( ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lo_cut->is_empty( ) ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lo_cut->size( ) ).

    lo_cut->set(
      iv_key = 'B'
      iv_val = 'bvalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lo_cut->size( ) ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'newvalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lo_cut->size( ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_cut->is_empty( ) ).

    lo_cut->clear( ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lo_cut->size( ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lo_cut->is_empty( ) ).

  ENDMETHOD.

  METHOD delete.

    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'A' ) ).

    lo_cut->delete( iv_key = 'A' ).

    cl_abap_unit_assert=>assert_equals(
      exp = ''
      act = lo_cut->get( 'A' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lo_cut->has( 'A' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lo_cut->size( ) ).

  ENDMETHOD.

  METHOD keys_values.

    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    DATA lt_exp TYPE string_table.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' ).
    lo_cut->set(
      iv_key = 'B'
      iv_val = 'bvalue' ).

    CLEAR lt_exp.
    APPEND 'A' TO lt_exp.
    APPEND 'B' TO lt_exp.

    cl_abap_unit_assert=>assert_equals(
      exp = lt_exp
      act = lo_cut->keys( ) ).

    CLEAR lt_exp.
    APPEND 'avalue' TO lt_exp.
    APPEND 'bvalue' TO lt_exp.

    cl_abap_unit_assert=>assert_equals(
      exp = lt_exp
      act = lo_cut->values( ) ).

  ENDMETHOD.

  METHOD to_struc.

    DATA ls_struc_act TYPE ty_struc.
    DATA ls_struc_exp TYPE ty_struc.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'a'
      iv_val = 'avalue' ).
    lo_cut->set(
      iv_key = 'b'
      iv_val = 'X' ).
    lo_cut->set(
      iv_key = 'c'
      iv_val = '123' ).

    lo_cut->to_struc( CHANGING cs_container = ls_struc_act ).

    ls_struc_exp-a = 'avalue'.
    ls_struc_exp-b = abap_true.
    ls_struc_exp-c = 123.

    cl_abap_unit_assert=>assert_equals(
      exp = ls_struc_exp
      act = ls_struc_act ).

  ENDMETHOD.

  METHOD from_struc.

    DATA ls_struc TYPE ty_struc.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    ls_struc-a = 'avalue'.
    ls_struc-b = abap_true.
    ls_struc-c = 123.

    lo_cut->set(
      iv_key = 'z'
      iv_val = 'xyz' ).

    lo_cut->from_struc( ls_struc ).

    cl_abap_unit_assert=>assert_equals(
      exp = 3
      act = lo_cut->size( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'A' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'X'
      act = lo_cut->get( 'B' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = '123'
      act = lo_cut->get( 'C' ) ).

  ENDMETHOD.

  METHOD strict.

    DATA ls_struc_act TYPE ty_struc.
    DATA ls_struc_exp TYPE ty_struc.
    DATA lx_error TYPE REF TO cx_root.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    lo_cut->set(
      iv_key = 'a'
      iv_val = 'avalue' ).
    lo_cut->set(
      iv_key = 'b'
      iv_val = 'X' ).
    lo_cut->set(
      iv_key = 'c'
      iv_val = '123' ).
    lo_cut->set(
      iv_key = 'z'
      iv_val = 'xyz' ).

    ls_struc_exp-a = 'avalue'.
    ls_struc_exp-b = abap_true.
    ls_struc_exp-c = 123.

    TRY.
        lo_cut->to_struc( CHANGING cs_container = ls_struc_act ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'Component Z not found in target'
          act = lx_error->get_text( ) ).
    ENDTRY.

    lo_cut->strict( abap_false )->to_struc( CHANGING cs_container = ls_struc_act ).

    cl_abap_unit_assert=>assert_equals(
      exp = ls_struc_exp
      act = ls_struc_act ).

  ENDMETHOD.

  METHOD from_to_struc_negative.

    DATA lt_dummy TYPE string_table.
    DATA lx_error TYPE REF TO cx_root.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    TRY.
        lo_cut->from_struc( lt_dummy ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'Only structures supported'
          act = lx_error->get_text( ) ).
    ENDTRY.

    TRY.
        lo_cut->to_struc( CHANGING cs_container = lt_dummy ).
        cl_abap_unit_assert=>fail( ).
      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>assert_equals(
          exp = 'Only structures supported'
          act = lx_error->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD from_entries.

    TYPES:
      BEGIN OF ty_pair,
        key TYPE string,
        val TYPE string,
      END OF ty_pair.

    DATA lt_entries TYPE TABLE OF ty_pair.
    DATA ls_entry LIKE LINE OF lt_entries.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( ).

    ls_entry-key = 'A'.
    ls_entry-val = 'avalue'.
    APPEND ls_entry TO lt_entries.

    ls_entry-key = 'B'.
    ls_entry-val = '123'.
    APPEND ls_entry TO lt_entries.

    lo_cut->from_entries( lt_entries ).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lo_cut->size( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'A' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = '123'
      act = lo_cut->get( 'B' ) ).

  ENDMETHOD.

  METHOD case_insensitive.

    DATA lt_exp_keys TYPE string_table.
    DATA lo_cut TYPE REF TO /mbtools/cl_string_map.
    lo_cut = /mbtools/cl_string_map=>create( iv_case_insensitive = abap_true ).

    lo_cut->set(
      iv_key = 'A'
      iv_val = 'avalue' ).
    lo_cut->set(
      iv_key = 'b'
      iv_val = 'bvalue' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'A' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'avalue'
      act = lo_cut->get( 'a' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'bvalue'
      act = lo_cut->get( 'B' ) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'bvalue'
      act = lo_cut->get( 'b' ) ).

    APPEND 'A' TO lt_exp_keys.
    APPEND 'B' TO lt_exp_keys.

    cl_abap_unit_assert=>assert_equals(
      exp = lt_exp_keys
      act = lo_cut->keys( ) ).

  ENDMETHOD.

ENDCLASS.