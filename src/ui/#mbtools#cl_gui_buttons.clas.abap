CLASS /mbtools/cl_gui_buttons DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

************************************************************************
* Marc Bernard Tools - GUI Buttons
*
* Copyright 2014 abapGit Contributors <http://www.abapgit.org>
* SPDX-License-Identifier: MIT
************************************************************************
  PUBLIC SECTION.
    CLASS-METHODS admin
      RETURNING VALUE(rv_html_string) TYPE string.
    CLASS-METHODS help
      RETURNING VALUE(rv_html_string) TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /mbtools/cl_gui_buttons IMPLEMENTATION.


  METHOD admin.
    rv_html_string = /mbtools/cl_html=>icon( 'bars' ).
  ENDMETHOD.


  METHOD help.
    rv_html_string = /mbtools/cl_html=>icon( 'question-circle-solid' ).
  ENDMETHOD.
ENDCLASS.
