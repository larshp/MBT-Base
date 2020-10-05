CLASS /mbtools/cl_ajson DEFINITION
  PUBLIC
  CREATE PRIVATE .
************************************************************************
* MBT AJSON
*
* Original Author: Copyright (c) 2020 Alexander Tsybulsky
* https://github.com/sbcgua/ajson
*
* Released under MIT License: https://opensource.org/licenses/MIT
*
* Last update: 2020-08-02
************************************************************************

  PUBLIC SECTION.

    CONSTANTS version TYPE string VALUE 'v1.0.0'.

    INTERFACES /mbtools/if_ajson_reader .
    INTERFACES /mbtools/if_ajson_writer .

    ALIASES:
      exists FOR /mbtools/if_ajson_reader~exists,
      members FOR /mbtools/if_ajson_reader~members,
      get FOR /mbtools/if_ajson_reader~get,
      get_boolean FOR /mbtools/if_ajson_reader~get_boolean,
      get_integer FOR /mbtools/if_ajson_reader~get_integer,
      get_number FOR /mbtools/if_ajson_reader~get_number,
      get_date FOR /mbtools/if_ajson_reader~get_date,
      get_string FOR /mbtools/if_ajson_reader~get_string,
      slice FOR /mbtools/if_ajson_reader~slice,
      to_abap FOR /mbtools/if_ajson_reader~to_abap,
      array_to_string_table FOR /mbtools/if_ajson_reader~array_to_string_table.

    ALIASES:
      clear FOR /mbtools/if_ajson_writer~clear,
      set FOR /mbtools/if_ajson_writer~set,
      set_boolean FOR /mbtools/if_ajson_writer~set_boolean,
      set_string FOR /mbtools/if_ajson_writer~set_string,
      set_integer FOR /mbtools/if_ajson_writer~set_integer,
      set_date FOR /mbtools/if_ajson_writer~set_date,
      set_null FOR /mbtools/if_ajson_writer~set_null,
      delete FOR /mbtools/if_ajson_writer~delete,
      touch_array FOR /mbtools/if_ajson_writer~touch_array,
      push FOR /mbtools/if_ajson_writer~push.

    TYPES:
      BEGIN OF ty_node,
        path     TYPE string,
        name     TYPE string,
        type     TYPE string,
        value    TYPE string,
        index    TYPE i,
        children TYPE i,
      END OF ty_node .
    TYPES:
      ty_nodes_tt TYPE STANDARD TABLE OF ty_node WITH KEY path name .
    TYPES:
      ty_nodes_ts TYPE SORTED TABLE OF ty_node
        WITH UNIQUE KEY path name
        WITH NON-UNIQUE SORTED KEY array_index COMPONENTS path index .
    TYPES:
      BEGIN OF ty_path_name,
        path TYPE string,
        name TYPE string,
      END OF ty_path_name.

    CLASS-METHODS parse
      IMPORTING
        !iv_json           TYPE string
        !iv_freeze         TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(ro_instance) TYPE REF TO /mbtools/cl_ajson
      RAISING
        /mbtools/cx_ajson_error .

    CLASS-METHODS create_empty
      RETURNING
        VALUE(ro_instance) TYPE REF TO /mbtools/cl_ajson.

    METHODS stringify
      IMPORTING
        iv_indent      TYPE i DEFAULT 0
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        /mbtools/cx_ajson_error.

    METHODS freeze.

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES:
      ty_node_stack_tt TYPE STANDARD TABLE OF REF TO ty_node WITH DEFAULT KEY.

    DATA mt_json_tree TYPE ty_nodes_ts.
    DATA mv_read_only TYPE abap_bool.

    METHODS get_item
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_item) TYPE REF TO ty_node.
    METHODS prove_path_exists
      IMPORTING
        iv_path              TYPE string
      RETURNING
        VALUE(rt_node_stack) TYPE ty_node_stack_tt
      RAISING
        /mbtools/cx_ajson_error.
    METHODS delete_subtree
      IMPORTING
        iv_path           TYPE string
        iv_name           TYPE string
      RETURNING
        VALUE(rv_deleted) TYPE abap_bool.

ENDCLASS.



CLASS /MBTOOLS/CL_AJSON IMPLEMENTATION.


  METHOD /mbtools/if_ajson_reader~array_to_string_table.

    DATA lv_normalized_path TYPE string.
    DATA lr_node TYPE REF TO ty_node.
    FIELD-SYMBOLS <item> LIKE LINE OF mt_json_tree.

    lv_normalized_path = lcl_utils=>normalize_path( iv_path ).
    lr_node = get_item( iv_path ).

    IF lr_node IS INITIAL.
      /mbtools/cx_ajson_error=>raise( |Path not found: { iv_path }| ).
    ENDIF.
    IF lr_node->type <> 'array'.
      /mbtools/cx_ajson_error=>raise( |Array expected at: { iv_path }| ).
    ENDIF.

    LOOP AT mt_json_tree ASSIGNING <item> WHERE path = lv_normalized_path.
      CASE <item>-type.
        WHEN 'num' OR 'str'.
          APPEND <item>-value TO rt_string_table.
        WHEN 'null'.
          APPEND '' TO rt_string_table.
        WHEN 'bool'.
          DATA lv_tmp TYPE string.
          IF <item>-value = 'true'.
            lv_tmp = abap_true.
          ELSE.
            CLEAR lv_tmp.
          ENDIF.
          APPEND lv_tmp TO rt_string_table.
        WHEN OTHERS.
          /mbtools/cx_ajson_error=>raise( |Cannot convert [{ <item>-type
            }] to string at [{ <item>-path }{ <item>-name }]| ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~exists.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS NOT INITIAL.
      rv_exists = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS NOT INITIAL.
      rv_value = lv_item->value.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get_boolean.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS INITIAL OR lv_item->type = 'null'.
      RETURN.
    ELSEIF lv_item->type = 'bool'.
      rv_value = boolc( lv_item->value = 'true' ).
    ELSEIF lv_item->value IS NOT INITIAL.
      rv_value = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get_date.

    DATA lv_item TYPE REF TO ty_node.
    DATA lv_y TYPE c LENGTH 4.
    DATA lv_m TYPE c LENGTH 2.
    DATA lv_d TYPE c LENGTH 2.

    lv_item = get_item( iv_path ).

    IF lv_item IS NOT INITIAL AND lv_item->type = 'str'.
      FIND FIRST OCCURRENCE OF REGEX '^(\d{4})-(\d{2})-(\d{2})'
        IN lv_item->value
        SUBMATCHES lv_y lv_m lv_d.
      CONCATENATE lv_y lv_m lv_d INTO rv_value.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get_integer.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS NOT INITIAL AND lv_item->type = 'num'.
      rv_value = lv_item->value.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get_number.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS NOT INITIAL AND lv_item->type = 'num'.
      rv_value = lv_item->value.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~get_string.

    DATA lv_item TYPE REF TO ty_node.
    lv_item = get_item( iv_path ).
    IF lv_item IS NOT INITIAL AND lv_item->type <> 'null'.
      rv_value = lv_item->value.
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~members.

    DATA lv_normalized_path TYPE string.
    FIELD-SYMBOLS <item> LIKE LINE OF mt_json_tree.

    lv_normalized_path = lcl_utils=>normalize_path( iv_path ).

    LOOP AT mt_json_tree ASSIGNING <item> WHERE path = lv_normalized_path.
      APPEND <item>-name TO rt_members.
    ENDLOOP.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~slice.

    DATA lo_section         TYPE REF TO /mbtools/cl_ajson.
    DATA ls_item            LIKE LINE OF mt_json_tree.
    DATA lv_normalized_path TYPE string.
    DATA ls_path_parts      TYPE ty_path_name.
    DATA lv_path_len        TYPE i.

    CREATE OBJECT lo_section.
    lv_normalized_path = lcl_utils=>normalize_path( iv_path ).
    lv_path_len        = strlen( lv_normalized_path ).
    ls_path_parts      = lcl_utils=>split_path( lv_normalized_path ).

    LOOP AT mt_json_tree INTO ls_item.
      " TODO potentially improve performance due to sorted tree (all path started from same prefix go in a row)
      IF strlen( ls_item-path ) >= lv_path_len
          AND substring( val = ls_item-path
                         len = lv_path_len ) = lv_normalized_path.
        ls_item-path = substring( val = ls_item-path
                                  off = lv_path_len - 1 ). " less closing '/'
        INSERT ls_item INTO TABLE lo_section->mt_json_tree.
      ELSEIF ls_item-path = ls_path_parts-path AND ls_item-name = ls_path_parts-name.
        CLEAR: ls_item-path, ls_item-name. " this becomes a new root
        INSERT ls_item INTO TABLE lo_section->mt_json_tree.
      ENDIF.
    ENDLOOP.

    ri_json = lo_section.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_reader~to_abap.

    DATA lo_to_abap TYPE REF TO lcl_json_to_abap.

    CLEAR ev_container.
    lcl_json_to_abap=>bind(
      CHANGING
        c_obj = ev_container
        co_instance = lo_to_abap ).
    lo_to_abap->to_abap( mt_json_tree ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~clear.

    IF mv_read_only = abap_true.
      /mbtools/cx_ajson_error=>raise( 'This json instance is read only' ).
    ENDIF.

    CLEAR mt_json_tree.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~delete.

    IF mv_read_only = abap_true.
      /mbtools/cx_ajson_error=>raise( 'This json instance is read only' ).
    ENDIF.

    DATA ls_split_path TYPE ty_path_name.
    ls_split_path = lcl_utils=>split_path( iv_path ).

    delete_subtree( iv_path = ls_split_path-path
                    iv_name = ls_split_path-name ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~push.

    DATA parent_ref TYPE REF TO ty_node.
    DATA new_node_ref TYPE REF TO ty_node.

    IF mv_read_only = abap_true.
      /mbtools/cx_ajson_error=>raise( 'This json instance is read only' ).
    ENDIF.

    parent_ref = get_item( iv_path ).

    IF parent_ref IS INITIAL.
      /mbtools/cx_ajson_error=>raise( |Path [{ iv_path }] does not exist| ).
    ENDIF.

    IF parent_ref->type <> 'array'.
      /mbtools/cx_ajson_error=>raise( |Path [{ iv_path }] is not array| ).
    ENDIF.

    DATA lt_new_nodes TYPE ty_nodes_tt.
    DATA ls_new_path TYPE ty_path_name.

    ls_new_path-path = lcl_utils=>normalize_path( iv_path ).
    ls_new_path-name = |{ parent_ref->children + 1 }|.

    lt_new_nodes = lcl_abap_to_json=>convert(
      iv_data   = iv_val
      is_prefix = ls_new_path ).
    READ TABLE lt_new_nodes INDEX 1 REFERENCE INTO new_node_ref. " assume first record is the array item - not ideal !
    ASSERT sy-subrc = 0.
    new_node_ref->index = parent_ref->children + 1.

    " update data
    parent_ref->children = parent_ref->children + 1.
    INSERT LINES OF lt_new_nodes INTO TABLE mt_json_tree.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set.

    DATA lt_path TYPE string_table.
    DATA ls_split_path TYPE ty_path_name.
    DATA parent_ref TYPE REF TO ty_node.
    DATA lt_node_stack TYPE TABLE OF REF TO ty_node.
    FIELD-SYMBOLS <topnode> TYPE ty_node.

    IF mv_read_only = abap_true.
      /mbtools/cx_ajson_error=>raise( 'This json instance is read only' ).
    ENDIF.

    IF iv_val IS INITIAL AND iv_ignore_empty = abap_true.
      RETURN. " nothing to assign
    ENDIF.

    ls_split_path = lcl_utils=>split_path( iv_path ).
    IF ls_split_path IS INITIAL. " Assign root, exceptional processing
      mt_json_tree = lcl_abap_to_json=>convert(
        iv_data   = iv_val
        is_prefix = ls_split_path ).
      RETURN.
    ENDIF.

    " Ensure whole path exists
    lt_node_stack = prove_path_exists( ls_split_path-path ).
    READ TABLE lt_node_stack INDEX 1 INTO parent_ref.
    ASSERT sy-subrc = 0.

    " delete if exists with subtree
    delete_subtree(
      iv_path = ls_split_path-path
      iv_name = ls_split_path-name ).

    " convert to json
    DATA lt_new_nodes TYPE ty_nodes_tt.
    DATA lv_array_index TYPE i.

    IF parent_ref->type = 'array'.
      lv_array_index = lcl_utils=>validate_array_index(
        iv_path  = ls_split_path-path
        iv_index = ls_split_path-name ).
    ENDIF.

    lt_new_nodes = lcl_abap_to_json=>convert(
      iv_data        = iv_val
      iv_array_index = lv_array_index
      is_prefix      = ls_split_path ).

    " update data
    parent_ref->children = parent_ref->children + 1.
    INSERT LINES OF lt_new_nodes INTO TABLE mt_json_tree.

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set_boolean.

    DATA lv_bool TYPE abap_bool.
    lv_bool = boolc( iv_val IS NOT INITIAL ).
    /mbtools/if_ajson_writer~set(
      iv_ignore_empty = abap_false
      iv_path = iv_path
      iv_val  = lv_bool ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set_date.

    DATA lv_val TYPE string.

    IF iv_val IS NOT INITIAL.
      lv_val = iv_val+0(4) && '-' && iv_val+4(2) && '-' && iv_val+6(2).
    ENDIF.

    /mbtools/if_ajson_writer~set(
      iv_ignore_empty = abap_false
      iv_path = iv_path
      iv_val  = lv_val ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set_integer.

    /mbtools/if_ajson_writer~set(
      iv_ignore_empty = abap_false
      iv_path = iv_path
      iv_val  = iv_val ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set_null.

    DATA lv_null_ref TYPE REF TO data.
    /mbtools/if_ajson_writer~set(
      iv_ignore_empty = abap_false
      iv_path = iv_path
      iv_val  = lv_null_ref ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~set_string.

    DATA lv_val TYPE string.
    lv_val = iv_val.
    /mbtools/if_ajson_writer~set(
      iv_ignore_empty = abap_false
      iv_path = iv_path
      iv_val  = lv_val ).

  ENDMETHOD.


  METHOD /mbtools/if_ajson_writer~touch_array.

    DATA node_ref TYPE REF TO ty_node.
    DATA ls_new_node LIKE LINE OF mt_json_tree.
    DATA ls_split_path TYPE ty_path_name.

    IF mv_read_only = abap_true.
      /mbtools/cx_ajson_error=>raise( 'This json instance is read only' ).
    ENDIF.

    ls_split_path = lcl_utils=>split_path( iv_path ).
    IF ls_split_path IS INITIAL. " Assign root, exceptional processing
      ls_new_node-path = ls_split_path-path.
      ls_new_node-name = ls_split_path-name.
      ls_new_node-type = 'array'.
      INSERT ls_new_node INTO TABLE mt_json_tree.
      RETURN.
    ENDIF.

    IF iv_clear = abap_true.
      delete_subtree( iv_path = ls_split_path-path
                      iv_name = ls_split_path-name ).
    ELSE.
      node_ref = get_item( iv_path ).
    ENDIF.

    IF node_ref IS INITIAL. " Or node was cleared

      DATA parent_ref TYPE REF TO ty_node.
      DATA lt_node_stack TYPE TABLE OF REF TO ty_node.

      lt_node_stack = prove_path_exists( ls_split_path-path ).
      READ TABLE lt_node_stack INDEX 1 INTO parent_ref.
      ASSERT sy-subrc = 0.
      parent_ref->children = parent_ref->children + 1.

      ls_new_node-path = ls_split_path-path.
      ls_new_node-name = ls_split_path-name.
      ls_new_node-type = 'array'.
      INSERT ls_new_node INTO TABLE mt_json_tree.

    ELSEIF node_ref->type <> 'array'.
      /mbtools/cx_ajson_error=>raise( |Path [{ iv_path }] already used and is not array| ).
    ENDIF.

  ENDMETHOD.


  METHOD create_empty.
    CREATE OBJECT ro_instance.
  ENDMETHOD.


  METHOD delete_subtree.

    DATA lv_parent_path TYPE string.
    DATA lv_parent_path_len TYPE i.
    FIELD-SYMBOLS <node> LIKE LINE OF mt_json_tree.
    READ TABLE mt_json_tree ASSIGNING <node>
      WITH KEY
        path = iv_path
        name = iv_name.
    IF sy-subrc = 0. " Found ? delete !
      IF <node>-children > 0. " only for objects and arrays
        lv_parent_path = iv_path && iv_name && '/'.
        lv_parent_path_len = strlen( lv_parent_path ).
        LOOP AT mt_json_tree ASSIGNING <node>.
          IF strlen( <node>-path ) >= lv_parent_path_len
            AND substring( val = <node>-path
                           len = lv_parent_path_len ) = lv_parent_path.
            DELETE mt_json_tree INDEX sy-tabix.
          ENDIF.
        ENDLOOP.
      ENDIF.

      DELETE mt_json_tree WHERE path = iv_path AND name = iv_name.
      rv_deleted = abap_true.

      DATA ls_path TYPE ty_path_name.
      ls_path = lcl_utils=>split_path( iv_path ).
      READ TABLE mt_json_tree ASSIGNING <node>
        WITH KEY
          path = ls_path-path
          name = ls_path-name.
      IF sy-subrc = 0.
        <node>-children = <node>-children - 1.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD freeze.
    mv_read_only = abap_true.
  ENDMETHOD.


  METHOD get_item.

    FIELD-SYMBOLS <item> LIKE LINE OF mt_json_tree.
    DATA ls_path_name TYPE ty_path_name.
    ls_path_name = lcl_utils=>split_path( iv_path ).

    READ TABLE mt_json_tree
      ASSIGNING <item>
      WITH KEY
        path = ls_path_name-path
        name = ls_path_name-name.
    IF sy-subrc = 0.
      GET REFERENCE OF <item> INTO rv_item.
    ENDIF.

  ENDMETHOD.


  METHOD parse.

    DATA lo_parser TYPE REF TO lcl_json_parser.

    CREATE OBJECT ro_instance.
    CREATE OBJECT lo_parser.
    ro_instance->mt_json_tree = lo_parser->parse( iv_json ).

    IF iv_freeze = abap_true.
      ro_instance->freeze( ).
    ENDIF.

  ENDMETHOD.


  METHOD prove_path_exists.

    DATA lt_path TYPE string_table.
    DATA node_ref LIKE LINE OF rt_node_stack.
    DATA node_parent LIKE LINE OF rt_node_stack.
    DATA lv_size TYPE i.
    DATA lv_cur_path TYPE string.
    DATA lv_cur_name TYPE string.
    DATA node_tmp LIKE LINE OF mt_json_tree.

    SPLIT iv_path AT '/' INTO TABLE lt_path.
    DELETE lt_path WHERE table_line IS INITIAL.
    lv_size = lines( lt_path ).

    DO.
      node_parent = node_ref.
      READ TABLE mt_json_tree REFERENCE INTO node_ref
        WITH KEY
          path = lv_cur_path
          name = lv_cur_name.
      IF sy-subrc <> 0. " New node, assume it is always object as it has a named child, use touch_array to init array
        IF node_parent IS NOT INITIAL. " if has parent
          node_parent->children = node_parent->children + 1.
          IF node_parent->type = 'array'.
            node_tmp-index = lcl_utils=>validate_array_index(
              iv_path  = lv_cur_path
              iv_index = lv_cur_name ).
          ENDIF.
        ENDIF.
        node_tmp-path = lv_cur_path.
        node_tmp-name = lv_cur_name.
        node_tmp-type = 'object'.
        INSERT node_tmp INTO TABLE mt_json_tree REFERENCE INTO node_ref.
      ENDIF.
      INSERT node_ref INTO rt_node_stack INDEX 1.
      lv_cur_path = lv_cur_path && lv_cur_name && '/'.
      READ TABLE lt_path INDEX sy-index INTO lv_cur_name.
      IF sy-subrc <> 0.
        EXIT. " no more segments
      ENDIF.
    ENDDO.

    ASSERT lv_cur_path = iv_path. " Just in case

  ENDMETHOD.


  METHOD stringify.

    rv_json = lcl_json_serializer=>stringify(
      it_json_tree = mt_json_tree
      iv_indent = iv_indent ).

  ENDMETHOD.
ENDCLASS.