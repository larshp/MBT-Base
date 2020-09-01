CLASS ltcl_logger_settings_should DEFINITION DEFERRED.
CLASS /mbtools/cl_logger_settings DEFINITION LOCAL FRIENDS ltcl_logger_settings_should.

CLASS ltcl_logger_settings_should DEFINITION FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO /mbtools/cl_logger_settings.
    METHODS setup.
    METHODS have_correct_defaults FOR TESTING.
    METHODS set_autosave FOR TESTING.
    METHODS set_expiry_date FOR TESTING.
    METHODS set_expiry_in_days FOR TESTING.
    METHODS set_flag_to_keep_until_expiry FOR TESTING.
    METHODS set_usage_of_2nd_db_connection FOR TESTING.
    METHODS set_max_drilldown_level FOR TESTING.
ENDCLASS.

CLASS ltcl_logger_settings_should IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT cut.
  ENDMETHOD.

  METHOD have_correct_defaults.
    cl_aunit_assert=>assert_equals(
        exp     = abap_true
        act     = cut->/mbtools/if_logger_settings~get_autosave( )
        msg     = |Auto save should be on by default| ).
    cl_aunit_assert=>assert_equals(
        exp     = abap_true
        act     = cut->/mbtools/if_logger_settings~get_usage_of_secondary_db_conn( )
        msg     = |2nd database connection should be used by default| ).
    cl_aunit_assert=>assert_equals(
        exp     = abap_false
        act     = cut->/mbtools/if_logger_settings~get_must_be_kept_until_expiry( )
        msg     = |Log should be deletable before expiry date is reached by default| ).
    cl_aunit_assert=>assert_initial(
        act     = cut->/mbtools/if_logger_settings~get_expiry_date( )
        msg     = |No expiry date set by default| ).
    cl_aunit_assert=>assert_equals(
        exp     = 10
        act     = cut->/mbtools/if_logger_settings~get_max_exception_drill_down( )
        msg     = |Max exception drill down should be 10 by default| ).
  ENDMETHOD.

  METHOD set_autosave.
    cut->/mbtools/if_logger_settings~set_autosave( abap_false ).
    cl_aunit_assert=>assert_equals(
        exp     = abap_false
        act     = cut->/mbtools/if_logger_settings~get_autosave( )
        msg     = |Auto save was not deactivated correctly| ).
  ENDMETHOD.

  METHOD set_expiry_date.
    cut->/mbtools/if_logger_settings~set_expiry_date( '20161030' ).
    cl_aunit_assert=>assert_equals(
        exp     = '20161030'
        act     = cut->/mbtools/if_logger_settings~get_expiry_date( )
        msg     = |Expiry date was not set correctly| ).
  ENDMETHOD.

  METHOD set_expiry_in_days.
    cut->/mbtools/if_logger_settings~set_expiry_in_days( -1 ).
    cl_aunit_assert=>assert_initial(
        act     = cut->/mbtools/if_logger_settings~get_expiry_date( )
        msg     = |Expiry in days should remain default when setting incorrect values.| ).

    cut->/mbtools/if_logger_settings~set_expiry_in_days( 10 ).

    DATA lv_exp TYPE d.
    lv_exp = sy-datum + 10.

    cl_aunit_assert=>assert_equals(
        exp     = lv_exp
        act     = cut->/mbtools/if_logger_settings~get_expiry_date( )
        msg     = |Expiry in days was not set correctly.| ).
  ENDMETHOD.

  METHOD set_flag_to_keep_until_expiry.
    cut->/mbtools/if_logger_settings~set_must_be_kept_until_expiry( abap_true ).
    cl_aunit_assert=>assert_equals(
        exp     = abap_true
        act     = cut->/mbtools/if_logger_settings~get_must_be_kept_until_expiry( )
        msg     = |Setter for keeping log until expiry is not working correctly.| ).
  ENDMETHOD.

  METHOD set_usage_of_2nd_db_connection.
    cut->/mbtools/if_logger_settings~set_usage_of_secondary_db_conn( abap_false ).
    cl_aunit_assert=>assert_equals(
        exp     = abap_false
        act     = cut->/mbtools/if_logger_settings~get_usage_of_secondary_db_conn( )
        msg     = |Setter for using 2nd db connection is not working correctly.| ).
  ENDMETHOD.

  METHOD set_max_drilldown_level.
    cut->/mbtools/if_logger_settings~set_max_exception_drill_down( 20 ).
    cl_aunit_assert=>assert_equals(
        exp     = 20
        act     = cut->/mbtools/if_logger_settings~get_max_exception_drill_down( )
        msg     = |Setter for max drilldown level is not working correctly.| ).
    cut->/mbtools/if_logger_settings~set_max_exception_drill_down( -1 ).
    cl_aunit_assert=>assert_equals(
        exp     = 20
        act     = cut->/mbtools/if_logger_settings~get_max_exception_drill_down( )
        msg     = |Max exception drill down level should not change if value is incorrect.| ).
    cut->/mbtools/if_logger_settings~set_max_exception_drill_down( 0 ).
    cl_aunit_assert=>assert_equals(
        exp     = 0
        act     = cut->/mbtools/if_logger_settings~get_max_exception_drill_down( )
        msg     = |Max exception drill down should be deactivatable.| ).
  ENDMETHOD.

ENDCLASS.
