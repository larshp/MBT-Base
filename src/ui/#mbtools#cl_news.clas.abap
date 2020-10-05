CLASS /mbtools/cl_news DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .
************************************************************************
* MBT News
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_log,
        version      TYPE string,
        pos_to_cur   TYPE i,
        is_header    TYPE abap_bool,
        is_important TYPE abap_bool,
        text         TYPE string,
      END OF ty_log .
    TYPES:
      ty_logs TYPE STANDARD TABLE OF ty_log WITH DEFAULT KEY .

    CONSTANTS c_tail_length TYPE i VALUE 5 ##NO_TEXT.       " Number of versions to display if no updates

    CLASS-METHODS create
      IMPORTING
        !io_tool           TYPE REF TO /mbtools/cl_tools
      RETURNING
        VALUE(ro_instance) TYPE REF TO /mbtools/cl_news
      RAISING
        /mbtools/cx_exception .
    METHODS get_log
      RETURNING
        VALUE(rt_log) TYPE ty_logs.
    METHODS has_news
      RETURNING
        VALUE(rv_boolean) TYPE abap_bool .
    METHODS has_important
      RETURNING
        VALUE(rv_boolean) TYPE abap_bool .
    METHODS has_updates
      RETURNING
        VALUE(rv_boolean) TYPE abap_bool .
    METHODS has_unseen
      RETURNING
        VALUE(rv_boolean) TYPE abap_bool .
    METHODS constructor
      IMPORTING
        !iv_rawdata          TYPE xstring
        !iv_lastseen_version TYPE string
        !iv_current_version  TYPE string .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mt_log TYPE ty_logs .
    DATA mv_current_version TYPE string .
    DATA mv_lastseen_version TYPE string .
    DATA mv_latest_version TYPE string .

    METHODS latest_version
      RETURNING
        VALUE(rv_version) TYPE string .
    CLASS-METHODS version_to_numeric
      IMPORTING
        !iv_version       TYPE string
      RETURNING
        VALUE(rv_version) TYPE i .
    CLASS-METHODS normalize_version
      IMPORTING
        !iv_version       TYPE string
      RETURNING
        VALUE(rv_version) TYPE string .
    CLASS-METHODS compare_versions
      IMPORTING
        !iv_a            TYPE string
        !iv_b            TYPE string
      RETURNING
        VALUE(rv_result) TYPE i .
    CLASS-METHODS parse_line
      IMPORTING
        !iv_line            TYPE string
        !iv_current_version TYPE string
      RETURNING
        VALUE(rs_log)       TYPE ty_log .
    CLASS-METHODS parse
      IMPORTING
        !it_lines           TYPE string_table
        !iv_current_version TYPE string
      RETURNING
        VALUE(rt_log)       TYPE ty_logs .
ENDCLASS.



CLASS /MBTOOLS/CL_NEWS IMPLEMENTATION.


  METHOD compare_versions.

    rv_result = /mbtools/cl_version=>compare( iv_current = iv_a
                                              iv_compare = iv_b ).

  ENDMETHOD.


  METHOD constructor.

    DATA: lt_lines    TYPE string_table,
          lv_string   TYPE string,
          ls_log_line LIKE LINE OF mt_log.

    " Validate params
    mv_current_version  = normalize_version( iv_current_version ).
    mv_lastseen_version = normalize_version( iv_lastseen_version ).
    IF mv_current_version IS INITIAL.
      RETURN. " Internal format of program version is not correct -> abort parsing
    ENDIF.

    lv_string = /mbtools/cl_convert=>xstring_to_string_utf8( iv_rawdata ).
    lt_lines  = /mbtools/cl_convert=>split_string( lv_string ).
    mt_log    = parse( it_lines = lt_lines
                       iv_current_version = mv_current_version ).

    READ TABLE mt_log INTO ls_log_line INDEX 1.
    mv_latest_version = ls_log_line-version. " Empty if not found

  ENDMETHOD.


  METHOD create ##TODO.

  ENDMETHOD.


  METHOD get_log.
    rt_log = me->mt_log.
  ENDMETHOD.


  METHOD has_important.
    READ TABLE mt_log WITH KEY is_important = abap_true TRANSPORTING NO FIELDS.
    rv_boolean = boolc( sy-subrc IS INITIAL ).
  ENDMETHOD.


  METHOD has_news.
    rv_boolean = boolc( lines( mt_log ) > 0 ).
  ENDMETHOD.


  METHOD has_unseen.
    rv_boolean = boolc( compare_versions(
      iv_a = mv_latest_version
      iv_b = mv_lastseen_version ) > 0 ).
  ENDMETHOD.


  METHOD has_updates.
    rv_boolean = boolc( compare_versions(
      iv_a = mv_latest_version
      iv_b = mv_current_version ) > 0 ).
  ENDMETHOD.


  METHOD latest_version.
    rv_version = me->mv_latest_version.
  ENDMETHOD.


  METHOD normalize_version.

    rv_version = /mbtools/cl_version=>normalize( iv_version ).

  ENDMETHOD.


  METHOD parse.

    DATA: lv_tail                TYPE i,
          lv_first_version_found TYPE abap_bool,
          lv_version             TYPE string,
          ls_log                 LIKE LINE OF rt_log.

    FIELD-SYMBOLS: <lv_line> LIKE LINE OF it_lines.


    LOOP AT it_lines ASSIGNING <lv_line>.
      ls_log = parse_line( iv_line = <lv_line>
                           iv_current_version = iv_current_version ).

      " Skip until first version head and Skip empty lines
      CHECK ls_log IS NOT INITIAL AND
            ( lv_first_version_found = abap_true OR ls_log-version IS NOT INITIAL ).

      IF lv_first_version_found = abap_false.
        lv_first_version_found = abap_true.
        IF compare_versions( iv_a = ls_log-version
                             iv_b = iv_current_version ) <= 0.
          lv_tail = c_tail_length. " Display some last versions if no updates
        ENDIF.
      ENDIF.

      IF ls_log-is_header = abap_true.
        "Skip everything below current version or show tail news
        IF compare_versions( iv_a = ls_log-version
                             iv_b = iv_current_version ) <= 0.
          IF lv_tail > 0.
            lv_tail = lv_tail - 1.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
        lv_version = ls_log-version. " Save to fill news lines
      ELSE.
        ls_log-version = lv_version.
      ENDIF.

      APPEND ls_log TO rt_log.
    ENDLOOP.

  ENDMETHOD.


  METHOD parse_line.

    CONSTANTS: lc_header_pattern TYPE string
        VALUE '^\d{4}-\d{2}-\d{2}\s+v(\d{1,3}\.\d{1,3}\.\d{1,3})\s*$'.

    DATA: lv_version TYPE string.

    IF iv_line IS INITIAL OR iv_line CO ' -='.
      RETURN. " Skip empty and markup lines
    ENDIF.

    " Check if line is a header line
    FIND FIRST OCCURRENCE OF REGEX lc_header_pattern IN iv_line SUBMATCHES lv_version.
    IF sy-subrc IS INITIAL.
      lv_version        = normalize_version( lv_version ).
      rs_log-version    = lv_version.
      rs_log-is_header  = abap_true.
      rs_log-pos_to_cur = compare_versions( iv_a = lv_version
                                            iv_b = iv_current_version ).
    ELSE.
      FIND FIRST OCCURRENCE OF REGEX '^\s*!' IN iv_line.
      rs_log-is_important = boolc( sy-subrc IS INITIAL ). " Change is important
    ENDIF.

    rs_log-text = iv_line.

  ENDMETHOD.


  METHOD version_to_numeric.

    DATA: lv_major   TYPE n LENGTH 4,
          lv_minor   TYPE n LENGTH 4,
          lv_release TYPE n LENGTH 4.

    SPLIT iv_version AT '.' INTO lv_major lv_minor lv_release.

    " Calculated value of version number, empty version will become 0 which is OK
    rv_version = lv_major * 1000000 + lv_minor * 1000 + lv_release.

  ENDMETHOD.
ENDCLASS.