CLASS ltcl_camel_case DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      to_abap FOR TESTING RAISING /mbtools/cx_ajson_error,
      to_json FOR TESTING RAISING /mbtools/cx_ajson_error,
      to_json_nested_struc FOR TESTING RAISING /mbtools/cx_ajson_error,
      to_json_nested_table FOR TESTING RAISING /mbtools/cx_ajson_error,
      to_json_first_lower FOR TESTING RAISING /mbtools/cx_ajson_error.

ENDCLASS.


CLASS ltcl_camel_case IMPLEMENTATION.


  METHOD to_abap.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_camel_case( ).

    lo_ajson = /mbtools/cl_ajson=>parse( iv_json = '{"FieldData":"field_value"}'
                                         ii_custom_mapping = li_mapping ).

    lo_ajson->to_abap( IMPORTING ev_container = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-field_data
      exp = 'field_value' ).

  ENDMETHOD.


  METHOD to_json.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_camel_case( iv_first_json_upper = abap_false ).

    ls_result-field_data = 'field_value'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"fieldData":"field_value"}' ).

  ENDMETHOD.


  METHOD to_json_nested_struc.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
        BEGIN OF struc_data,
          field_more TYPE string,
        END OF struc_data,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_camel_case( iv_first_json_upper = abap_false ).

    ls_result-field_data = 'field_value'.
    ls_result-struc_data-field_more = 'field_more'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"fieldData":"field_value","strucData":{"fieldMore":"field_more"}}' ).

  ENDMETHOD.


  METHOD to_json_nested_table.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      lv_value TYPE string,
      BEGIN OF ls_result,
        field_data TYPE string,
        BEGIN OF struc_data,
          field_more TYPE string_table,
        END OF struc_data,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_camel_case( iv_first_json_upper = abap_false ).

    ls_result-field_data = 'field_value'.
    lv_value = 'field_more'.
    INSERT lv_value INTO TABLE ls_result-struc_data-field_more.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"fieldData":"field_value","strucData":{"fieldMore":["field_more"]}}' ).

  ENDMETHOD.


  METHOD to_json_first_lower.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_camel_case( ).

    ls_result-field_data = 'field_value'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"FieldData":"field_value"}' ).

  ENDMETHOD.


ENDCLASS.



CLASS ltcl_fields DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      to_abap FOR TESTING RAISING /mbtools/cx_ajson_error,
      to_json FOR TESTING RAISING /mbtools/cx_ajson_error.
ENDCLASS.


CLASS ltcl_fields IMPLEMENTATION.


  METHOD to_abap.

    DATA:
      lo_ajson          TYPE REF TO /mbtools/cl_ajson,
      li_mapping        TYPE REF TO /mbtools/if_ajson_mapping,
      lt_mapping_fields TYPE /mbtools/if_ajson_mapping=>ty_mapping_fields,
      ls_mapping_field  LIKE LINE OF lt_mapping_fields.
    DATA:
      BEGIN OF ls_result,
        abap_field TYPE string,
        field      TYPE string,
      END OF ls_result.

    CLEAR ls_mapping_field.
    ls_mapping_field-abap  = 'ABAP_FIELD'.
    ls_mapping_field-json = 'json.field'.
    INSERT ls_mapping_field INTO TABLE lt_mapping_fields.

    li_mapping = /mbtools/cl_ajson_mapping=>create_field_mapping( lt_mapping_fields ).

    lo_ajson =
        /mbtools/cl_ajson=>parse( iv_json = '{"field":"value","json.field":"field_value"}'
                                  ii_custom_mapping = li_mapping ).

    lo_ajson->to_abap( IMPORTING ev_container = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-abap_field
      exp = 'field_value' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-field
      exp = 'value' ).

  ENDMETHOD.


  METHOD to_json.

    DATA:
      lo_ajson          TYPE REF TO /mbtools/cl_ajson,
      li_mapping        TYPE REF TO /mbtools/if_ajson_mapping,
      lt_mapping_fields TYPE /mbtools/if_ajson_mapping=>ty_mapping_fields,
      ls_mapping_field  LIKE LINE OF lt_mapping_fields.
    DATA:
      BEGIN OF ls_result,
        abap_field TYPE string,
        field      TYPE string,
      END OF ls_result.

    CLEAR ls_mapping_field.
    ls_mapping_field-abap  = 'ABAP_FIELD'.
    ls_mapping_field-json = 'json.field'.
    INSERT ls_mapping_field INTO TABLE lt_mapping_fields.

    li_mapping = /mbtools/cl_ajson_mapping=>create_field_mapping( lt_mapping_fields ).

    ls_result-abap_field = 'field_value'.
    ls_result-field      = 'value'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"field":"value","json.field":"field_value"}' ).

  ENDMETHOD.


ENDCLASS.



CLASS ltcl_to_lower DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      to_json FOR TESTING RAISING /mbtools/cx_ajson_error.
ENDCLASS.


CLASS ltcl_to_lower IMPLEMENTATION.


  METHOD to_json.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_lower_case( ).

    ls_result-field_data = 'field_value'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"field_data":"field_value"}' ).

  ENDMETHOD.


ENDCLASS.



CLASS ltcl_to_upper DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      to_json FOR TESTING RAISING /mbtools/cx_ajson_error.
ENDCLASS.


CLASS ltcl_to_upper IMPLEMENTATION.


  METHOD to_json.

    DATA:
      lo_ajson   TYPE REF TO /mbtools/cl_ajson,
      li_mapping TYPE REF TO /mbtools/if_ajson_mapping.
    DATA:
      BEGIN OF ls_result,
        field_data TYPE string,
      END OF ls_result.

    li_mapping = /mbtools/cl_ajson_mapping=>create_upper_case( ).

    ls_result-field_data = 'field_value'.

    lo_ajson = /mbtools/cl_ajson=>create_empty( ii_custom_mapping = li_mapping ).

    lo_ajson->set( iv_path = '/'
                   iv_val = ls_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ajson->stringify( )
      exp = '{"FIELD_DATA":"field_value"}' ).

  ENDMETHOD.


ENDCLASS.
