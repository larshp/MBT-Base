************************************************************************
* /MBTOOLS/CL_PROXY_AUTH
* MBT Proxy Authentication
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************
CLASS /mbtools/cl_proxy_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS run
      IMPORTING
        !ii_client TYPE REF TO if_http_client
      RAISING
        /mbtools/cx_exception .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: gv_username TYPE string,
                gv_password TYPE string.

    CLASS-METHODS: enter RAISING /mbtools/cx_exception.

ENDCLASS.



CLASS /MBTOOLS/CL_PROXY_AUTH IMPLEMENTATION.


  METHOD enter.

    /mbtools/cl_password_dialog=>popup(
      EXPORTING
        iv_url  = 'Proxy Authentication'
      CHANGING
        cv_user = gv_username
        cv_pass = gv_password ).

    IF gv_username IS INITIAL OR gv_password IS INITIAL.
      /mbtools/cx_exception=>raise( 'Proxy authentication failed' ).
    ENDIF.

  ENDMETHOD.


  METHOD run.

    IF gv_username IS INITIAL OR gv_password IS INITIAL.
      enter( ).
    ENDIF.

    ii_client->authenticate(
      proxy_authentication = abap_true
      username             = gv_username
      password             = gv_password ).

  ENDMETHOD.
ENDCLASS.