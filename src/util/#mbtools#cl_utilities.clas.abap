CLASS /mbtools/cl_utilities DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

************************************************************************
* Marc Bernard Tools - Utilities
*
* Copyright 2021 Marc Bernard <https://marcbernardtools.com/>
* SPDX-License-Identifier: GPL-3.0-or-later
************************************************************************
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_strv_release_patch,
        release TYPE n LENGTH 3,
        version TYPE n LENGTH 5,
        patch   TYPE n LENGTH 5,
      END OF ty_strv_release_patch.

    CONSTANTS:
      BEGIN OF c_property,
        year             TYPE string VALUE 'YEAR',
        month            TYPE string VALUE 'MONTH',
        day              TYPE string VALUE 'DAY',
        hour             TYPE string VALUE 'HOUR',
        minute           TYPE string VALUE 'MINUTE',
        second           TYPE string VALUE 'SECOND',
        database         TYPE string VALUE 'DB',
        database_release TYPE string VALUE 'DB_RELEASE',
        database_patch   TYPE string VALUE 'DB_PATCH',
        dbsl_release     TYPE string VALUE 'DBSL_RELEASE',
        dbsl_patch       TYPE string VALUE 'DBSL_PATCH',
        hana             TYPE string VALUE 'HANA',
        hana_release     TYPE string VALUE 'HANA_RELEASE',
        hana_sp          TYPE string VALUE 'HANA_SP',
        hana_revision    TYPE string VALUE 'HANA_REVISION',
        hana_patch       TYPE string VALUE 'HANA_PATCH',
        spam_release     TYPE string VALUE 'SPAM_RELEASE',
        spam_version     TYPE string VALUE 'SPAM_VERSION',
        kernel           TYPE string VALUE 'KERNEL',
        kernel_release   TYPE string VALUE 'KERNEL_RELEASE',
        kernel_patch     TYPE string VALUE 'KERNEL_PATCH',
        kernel_bits      TYPE string VALUE 'KERNEL_BITS',
        codepage         TYPE string VALUE 'CODEPAGE',
        endian           TYPE string VALUE 'ENDIAN',
        unicode          TYPE string VALUE 'UNICODE',
      END OF c_property.
    CONSTANTS c_unknown TYPE string VALUE 'UNKNOWN' ##NO_TEXT.
    CONSTANTS c_not_authorized TYPE string VALUE 'NOT_AUTHORIZED' ##NO_TEXT.

    CLASS-METHODS call_browser
      IMPORTING
        !iv_url TYPE csequence.
    CLASS-METHODS is_batch
      RETURNING
        VALUE(rv_batch) TYPE abap_bool.
    CLASS-METHODS is_system_modifiable
      RETURNING
        VALUE(rv_modifiable) TYPE abap_bool.
    CLASS-METHODS is_system_test_or_prod
      RETURNING
        VALUE(rv_test_prod) TYPE abap_bool.
    CLASS-METHODS is_snote_allowed
      RETURNING
        VALUE(rv_snote_allowed) TYPE abap_bool.
    CLASS-METHODS is_upgrage_running
      RETURNING
        VALUE(rv_upgrade_running) TYPE abap_bool.
    CLASS-METHODS is_spam_locked
      RETURNING
        VALUE(rv_spam_locked) TYPE abap_bool.
    CLASS-METHODS get_property
      IMPORTING
        VALUE(iv_property) TYPE clike
      EXPORTING
        !ev_value          TYPE string
        !ev_value_float    TYPE f
        !ev_value_integer  TYPE i
        !ev_subrc          TYPE sy-subrc.
    CLASS-METHODS get_syst_field
      IMPORTING
        VALUE(iv_field) TYPE clike
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_db_release
      RETURNING
        VALUE(rs_dbinfo) TYPE dbrelinfo.
    CLASS-METHODS get_hana_release
      RETURNING
        VALUE(rs_hana_release) TYPE ty_strv_release_patch.
    CLASS-METHODS get_spam_release
      RETURNING
        VALUE(rs_details) TYPE ty_strv_release_patch.
    CLASS-METHODS get_kernel_release
      RETURNING
        VALUE(rs_details) TYPE ty_strv_release_patch.
    CLASS-METHODS get_swcomp_release
      IMPORTING
        VALUE(iv_component) TYPE clike
      RETURNING
        VALUE(rv_release)   TYPE string.
    CLASS-METHODS get_swcomp_support_package
      IMPORTING
        VALUE(iv_component)       TYPE clike
      RETURNING
        VALUE(rv_support_package) TYPE string.
    CLASS-METHODS get_profile_parameter
      IMPORTING
        VALUE(iv_parameter) TYPE clike
      RETURNING
        VALUE(rv_value)     TYPE string.
    CLASS-METHODS get_profile_parameter_name
      IMPORTING
        VALUE(iv_parameter) TYPE clike
      RETURNING
        VALUE(rv_result)    TYPE string.
    CLASS-METHODS get_date_time
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_database
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_hana
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_spam
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_kernel
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_codepage
      IMPORTING
        !iv_property    TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    CLASS-METHODS get_user_parameter
      IMPORTING
        !iv_parameter    TYPE clike
      RETURNING
        VALUE(rv_result) TYPE string.
    CLASS-METHODS set_user_parameter
      IMPORTING
        !iv_parameter TYPE clike
        !iv_value     TYPE clike.
  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS c_original_name TYPE string VALUE 'ORIG:' ##NO_TEXT.
    CLASS-DATA:
      gt_cvers TYPE SORTED TABLE OF cvers WITH UNIQUE KEY component.

    CLASS-METHODS _get_all_profile_parameters
      RETURNING
        VALUE(ro_parameters) TYPE REF TO /mbtools/cl_string_map
      RAISING
        /mbtools/cx_exception.
ENDCLASS.



CLASS /mbtools/cl_utilities IMPLEMENTATION.


  METHOD call_browser.

    cl_gui_frontend_services=>execute(
      EXPORTING
        document               = |{ iv_url }|
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
        DISPLAY LIKE sy-msgty.
    ENDIF.

  ENDMETHOD.                    "call_browser


  METHOD get_codepage.

    CASE iv_property.
      WHEN c_property-codepage.
        rv_value = cl_abap_codepage=>sap_codepage( '' ).
      WHEN c_property-endian.
        CASE cl_abap_char_utilities=>endian.
          WHEN 'L'.
            rv_value = 'LittleEndian'.
          WHEN 'B'.
            rv_value = 'BigEndian'.
          WHEN OTHERS.
            rv_value = c_unknown.
        ENDCASE.
      WHEN c_property-unicode.
        IF cl_abap_char_utilities=>charsize = 1.
          rv_value = 'No'.
        ELSE.
          rv_value = 'Yes'.
        ENDIF.
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_database.

    DATA lv_property TYPE string.

    CASE iv_property.
      WHEN c_property-database.
        rv_value = get_db_release( )-srvrel.
      WHEN c_property-database_release.
        FIND FIRST OCCURRENCE OF REGEX '(\d+)\.\d+\.*' IN get_db_release( )-srvrel
          SUBMATCHES rv_value ##SUBRC_OK.
      WHEN c_property-database_patch.
        FIND FIRST OCCURRENCE OF REGEX '\d+\.(\d+)\.*' IN get_db_release( )-srvrel
          SUBMATCHES rv_value ##SUBRC_OK.
      WHEN c_property-dbsl_release.
        SPLIT get_db_release( )-dbsl_vers AT '.' INTO rv_value lv_property.
      WHEN c_property-dbsl_patch.
        SPLIT get_db_release( )-dbsl_vers AT '.' INTO lv_property rv_value.
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_date_time.

    CASE iv_property.
      WHEN c_property-year.
        rv_value = sy-datum+0(4).
      WHEN c_property-month.
        rv_value = sy-datum+4(2).
      WHEN c_property-day.
        rv_value = sy-datum+6(2).
      WHEN c_property-hour.
        rv_value = sy-uzeit+0(2).
      WHEN c_property-minute.
        rv_value = sy-uzeit+2(2).
      WHEN c_property-second.
        rv_value = sy-uzeit+4(2).
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_db_release.

    CALL FUNCTION 'DB_DBRELINFO'
      IMPORTING
        dbinfo = rs_dbinfo.

  ENDMETHOD.                    "get_db_release


  METHOD get_hana.

    CASE iv_property.
      WHEN c_property-hana.
        IF sy-dbsys = 'HDB'.
          rv_value = 'Yes'.
        ELSE.
          rv_value = 'No'.
        ENDIF.
      WHEN c_property-hana_release.
        rv_value = get_hana_release( )-release DIV 100.
      WHEN c_property-hana_sp.
        rv_value = get_hana_release( )-release MOD 100.
      WHEN c_property-hana_revision.
        rv_value = get_hana_release( )-version.
      WHEN c_property-hana_patch.
        rv_value = get_hana_release( )-patch.
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_hana_release.

    DATA:
      ls_dbinfo   TYPE dbrelinfo,
      lv_release  TYPE n LENGTH 3,
      lv_text_1   TYPE string,
      lv_text_2   TYPE string,
      lv_hana_rel TYPE i,
      lv_hana_sps TYPE i.

    CALL FUNCTION 'DB_DBRELINFO'
      IMPORTING
        dbinfo = ls_dbinfo.

    IF ls_dbinfo-dbsys = 'HDB'.
      " First number in version is release, third one is revision level
      FIND FIRST OCCURRENCE OF REGEX '(\d+)\.(\d+)\.(\d+)\.(\d*)\.\d*' IN ls_dbinfo-srvrel
        SUBMATCHES lv_text_1 lv_text_2 rs_hana_release-version rs_hana_release-patch.
      IF sy-subrc = 0.
        lv_hana_rel = lv_text_1.
        lv_hana_sps = lv_text_2. "= 0 (except SAP-internally)

        CASE lv_hana_rel.
          WHEN 1.
            IF rs_hana_release-version = 0.
              lv_hana_sps = 0.
            ELSEIF rs_hana_release-version BETWEEN 1 AND 10. "#EC NUMBER_OK
              lv_hana_sps = 1.
            ELSEIF rs_hana_release-version BETWEEN 11 AND 18. "#EC NUMBER_OK
              lv_hana_sps = 2.
            ELSEIF rs_hana_release-version BETWEEN 19 AND 27. "#EC NUMBER_OK
              lv_hana_sps = 3.
            ELSEIF rs_hana_release-version BETWEEN 28 AND 44. "#EC NUMBER_OK
              lv_hana_sps = 4.
            ELSEIF rs_hana_release-version BETWEEN 45 AND 59. "#EC NUMBER_OK
              lv_hana_sps = 5.
            ELSE.
              lv_hana_sps = rs_hana_release-version DIV 10.
            ENDIF.
          WHEN OTHERS.
            lv_hana_sps = rs_hana_release-version DIV 10.
        ENDCASE.

        lv_release = 100 * lv_hana_rel + lv_hana_sps.
        rs_hana_release-release = lv_release.
        IF rs_hana_release-patch > 1000. " it's the changelog for old revisions
          rs_hana_release-patch = 0.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.                    "get_db_release


  METHOD get_kernel.

    CASE iv_property.
      WHEN c_property-kernel.
        rv_value = get_kernel_release( ).
      WHEN c_property-kernel_release.
        rv_value = get_kernel_release( )-release.
      WHEN c_property-kernel_patch.
        rv_value = get_kernel_release( )-patch.
      WHEN c_property-kernel_bits.
        rv_value = get_kernel_release( )-version.
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_kernel_release.

*   Kernel Info retrival copied from FuGrp SHSY Module get_kinfo
    TYPES:
      BEGIN OF ty_kernel_info,
        key  TYPE c LENGTH 21,
        data TYPE c LENGTH 400,
      END OF ty_kernel_info.

    DATA:
      lt_kernel_info TYPE STANDARD TABLE OF ty_kernel_info,
      lo_kernel_info TYPE REF TO            ty_kernel_info.

*   Kernel Release Information
    CALL 'SAPCORE' ID 'ID' FIELD 'VERSION'
                   ID 'TABLE' FIELD lt_kernel_info.       "#EC CI_CCALL

    READ TABLE lt_kernel_info REFERENCE INTO lo_kernel_info INDEX 12.
    IF sy-subrc = 0.
      rs_details-release = lo_kernel_info->data.
    ENDIF.

    READ TABLE lt_kernel_info REFERENCE INTO lo_kernel_info INDEX 15.
    IF sy-subrc = 0.
      rs_details-patch = lo_kernel_info->data.
    ENDIF.

*   32- or 64-bit Kernel
    READ TABLE lt_kernel_info REFERENCE INTO lo_kernel_info INDEX 3.
    IF sy-subrc = 0 AND lo_kernel_info->data CS '64'.
      rs_details-version = 64.
    ELSE.
      rs_details-version = 32.
    ENDIF.

  ENDMETHOD.                    "get_kernel_release


  METHOD get_profile_parameter.

    DATA lo_parameters TYPE REF TO /mbtools/cl_string_map.

    TRY.
        lo_parameters = _get_all_profile_parameters( ).
      CATCH /mbtools/cx_exception.
        rv_value = c_not_authorized.
        RETURN.
    ENDTRY.

    rv_value = lo_parameters->get( iv_parameter ).

    IF rv_value IS INITIAL.
      rv_value = c_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD get_profile_parameter_name.

    rv_result = get_profile_parameter( c_original_name && iv_parameter ).

  ENDMETHOD.


  METHOD get_property.

    DATA lv_property TYPE string.

    CLEAR: ev_value, ev_value_float, ev_value_integer, ev_subrc.

    lv_property = iv_property.
    TRANSLATE lv_property TO UPPER CASE.

    ev_value = get_date_time( lv_property ).
    IF ev_value = c_unknown.
      ev_value = get_database( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_hana( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_spam( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_kernel( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_codepage( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_syst_field( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_swcomp_release( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_swcomp_support_package( lv_property ).
    ENDIF.
    IF ev_value = c_unknown.
      ev_value = get_profile_parameter( lv_property ).
    ENDIF.

    IF ev_value = c_unknown OR ev_value = c_not_authorized.
      ev_subrc = 4.
    ENDIF.

    IF ev_subrc = 0.
      SHIFT ev_value LEFT DELETING LEADING space.
      TRY.
          ev_value_integer = ev_value.
          ev_value_float = ev_value.
        CATCH cx_root.
          "not a numeric value, just ignore
          ev_subrc = 0.
      ENDTRY.
    ENDIF.

  ENDMETHOD.


  METHOD get_spam.

    CASE iv_property.
      WHEN c_property-spam_release.
        rv_value = get_spam_release( )-release.
      WHEN c_property-spam_version.
        rv_value = get_spam_release( )-version.
      WHEN OTHERS.
        rv_value = c_unknown.
    ENDCASE.

  ENDMETHOD.


  METHOD get_spam_release.

    CONSTANTS:
      lc_spam_vers_func TYPE funcname VALUE 'SPAM_VERSION'.

    DATA:
      lv_spam_vers TYPE n LENGTH 4.

    TRY.
        CALL FUNCTION lc_spam_vers_func
          IMPORTING
            version = lv_spam_vers.

        rs_details-release = sy-saprl.                    "#EC SAPRL_OK
        rs_details-version = lv_spam_vers.
      CATCH cx_sy_dyn_call_illegal_func.
        RETURN.
    ENDTRY.

  ENDMETHOD.                    "get_spam_release


  METHOD get_swcomp_release.

    DATA:
      ls_cvers TYPE cvers.

    IF gt_cvers IS INITIAL.
      SELECT * FROM cvers INTO TABLE gt_cvers ORDER BY PRIMARY KEY.
      ASSERT sy-subrc = 0.
    ENDIF.

    READ TABLE gt_cvers INTO ls_cvers WITH TABLE KEY
      component = iv_component.
    IF sy-subrc = 0.
      rv_release = ls_cvers-release.
    ELSE.
      rv_release = c_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD get_swcomp_support_package.

    DATA:
      ls_cvers TYPE cvers.

    IF gt_cvers IS INITIAL.
      SELECT * FROM cvers INTO TABLE gt_cvers ORDER BY PRIMARY KEY.
      ASSERT sy-subrc = 0.
    ENDIF.

    ls_cvers-component = iv_component.
    REPLACE '_SP' IN ls_cvers-component WITH ''.

    READ TABLE gt_cvers INTO ls_cvers WITH TABLE KEY
      component = ls_cvers-component.
    IF sy-subrc = 0.
      rv_support_package = ls_cvers-extrelease.
    ELSE.
      rv_support_package = c_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD get_syst_field.

    DATA:
      lv_field TYPE fieldname.

    FIELD-SYMBOLS:
      <lv_value> TYPE any.

    lv_field = iv_field.

    TRANSLATE lv_field TO UPPER CASE.

    IF lv_field CS 'SY-' OR lv_field CS 'SYST-'.
      REPLACE 'SY-' WITH '' INTO lv_field.
      REPLACE 'SYST-' WITH '' INTO lv_field.
      CONDENSE lv_field NO-GAPS.

      ASSIGN COMPONENT lv_field OF STRUCTURE sy TO <lv_value>.
      IF sy-subrc = 0.
        TRY.
            rv_value = <lv_value>.
          CATCH cx_root.
            rv_value = c_unknown.
        ENDTRY.
      ELSE.
        rv_value = c_unknown.
      ENDIF.
    ELSE.
      rv_value = c_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD get_user_parameter.

    " Get parameter from user record (better than GET PARAMETER ID which buffers settings)
    SELECT SINGLE parva FROM usr05 INTO rv_result
      WHERE bname = sy-uname AND parid = iv_parameter ##SUBRC_OK.

  ENDMETHOD.


  METHOD is_batch.

    rv_batch = boolc( sy-binpt = abap_true OR sy-batch = abap_true ).

  ENDMETHOD.


  METHOD is_snote_allowed.

    CALL FUNCTION 'OCS_CHECK_RUNNING_UPGRADE_4_NA'
      IMPORTING
        ev_snote_allowed = rv_snote_allowed.

  ENDMETHOD.                    "is_spam_in_progress


  METHOD is_spam_locked.

    DATA:
      ls_sema TYPE pat10.

    CALL FUNCTION 'OCS_QUEUE_SEMAPHORE'
      EXPORTING
        iv_tool        = 'SPAM'
        iv_read_only   = abap_true
      IMPORTING
        ev_locked      = rv_spam_locked
      CHANGING
        cs_sema        = ls_sema
      EXCEPTIONS
        foreign_lock   = 1
        internal_error = 2
        OTHERS         = 3.
    CHECK sy-subrc = 0. "ignore errors

  ENDMETHOD.                    "is_spam_in_progress


  METHOD is_system_modifiable.

    DATA:
      lv_systemedit TYPE tadir-edtflag.

    CALL FUNCTION 'TR_SYS_PARAMS'
      IMPORTING
        systemedit    = lv_systemedit
      EXCEPTIONS
        no_systemname = 1
        no_systemtype = 2
        OTHERS        = 3.
    rv_modifiable = boolc( sy-subrc <> 0 OR lv_systemedit = 'N' ). "not modifiable

  ENDMETHOD.                    "is_system_modifiable


  METHOD is_system_test_or_prod.

    DATA:
      lv_client_role TYPE cccategory.

    CALL FUNCTION 'TR_SYS_PARAMS'
      IMPORTING
        system_client_role = lv_client_role
      EXCEPTIONS
        no_systemname      = 1
        no_systemtype      = 2
        OTHERS             = 3.
    rv_test_prod = boolc( sy-subrc <> 0 OR lv_client_role CA 'PTS' ). "prod/test/sap reference

  ENDMETHOD.                    "is_system_test_or_prod


  METHOD is_upgrage_running.

    CALL FUNCTION 'OCS_CHECK_RUNNING_UPGRADE_4_NA'
      IMPORTING
        ev_upg_running = rv_upgrade_running.

  ENDMETHOD.                    "is_spam_in_progress


  METHOD set_user_parameter.

    " Save parameter to user record
    DATA ls_usr05 TYPE usr05.

    ls_usr05-mandt = sy-mandt.
    ls_usr05-bname = sy-uname.
    ls_usr05-parid = iv_parameter.
    ls_usr05-parva = iv_value.

    MODIFY usr05 FROM ls_usr05 ##SUBRC_OK.

  ENDMETHOD.


  METHOD _get_all_profile_parameters.

    TYPES:
      BEGIN OF ty_par,
        status       TYPE sy-index,
        pname        TYPE c LENGTH 60,
        user_wert    TYPE c LENGTH 60,
        default_wert TYPE c LENGTH 60,
      END OF ty_par.

    DATA:
      lr_data    TYPE REF TO data,
      lt_par_sub TYPE STANDARD TABLE OF ty_par WITH DEFAULT KEY.

    FIELD-SYMBOLS:
      <lv_name>       TYPE any,
      <lv_value>      TYPE any,
      <ls_par_sub>    LIKE LINE OF lt_par_sub,
      <ls_parameter>  TYPE any,
      <lt_parameters> TYPE ANY TABLE.

    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD' ID 'S_ADMI_FCD' FIELD 'DBA'.
    IF sy-subrc <> 0.
      /mbtools/cx_exception=>raise( 'No authorization to read profile parameters' ).
    ENDIF.

    ro_parameters = /mbtools/cl_string_map=>create( iv_case_insensitive = abap_true ).

    TRY.
        CREATE DATA lr_data TYPE ('SPFL_PARAMETER_LIST_T').
        ASSIGN lr_data->* TO <lt_parameters> ##SUBRC_OK.

        " Dynamic call since class is not available in lower releases
        CALL METHOD ('CL_SPFL_PROFILE_PARAMETER')=>('GET_ALL_PARAMETER')
          IMPORTING
            parameter_sub = <lt_parameters>.

        LOOP AT <lt_parameters> ASSIGNING <ls_parameter>.
          ASSIGN COMPONENT 'NAME' OF STRUCTURE <ls_parameter> TO <lv_name> ##SUBRC_OK.
          ASSIGN COMPONENT 'USER_VALUE' OF STRUCTURE <ls_parameter> TO <lv_value> ##SUBRC_OK.
          IF <lv_value> IS INITIAL.
            ASSIGN COMPONENT 'DEFAULT_VALUE' OF STRUCTURE <ls_parameter> TO <lv_value> ##SUBRC_OK.
          ENDIF.
          ro_parameters->set(
            iv_key = <lv_name>
            iv_val = <lv_value> ).
          " Original parameter name
          ro_parameters->set(
            iv_key = c_original_name && <lv_name>
            iv_val = <lv_name> ).
        ENDLOOP.

      CATCH cx_root.
        " For lower releases resort to c-call
        CALL 'C_SAPGALLPARAM'
          ID 'PAR_SUB' FIELD lt_par_sub.                  "#EC CI_CCALL

        LOOP AT lt_par_sub ASSIGNING <ls_par_sub>.
          ASSIGN COMPONENT 'PNAME' OF STRUCTURE <ls_par_sub> TO <lv_name> ##SUBRC_OK.
          ASSIGN COMPONENT 'USER_WERT' OF STRUCTURE <ls_par_sub> TO <lv_value> ##SUBRC_OK.
          IF <lv_value> IS INITIAL.
            ASSIGN COMPONENT 'DEFAULT_WERT' OF STRUCTURE <ls_par_sub> TO <lv_value> ##SUBRC_OK.
          ENDIF.
          ro_parameters->set(
            iv_key = |{ <lv_name> }|
            iv_val = |{ <lv_value> }| ).
          " Original parameter name
          ro_parameters->set(
            iv_key = c_original_name && <lv_name>
            iv_val = <lv_name> ).
        ENDLOOP.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
