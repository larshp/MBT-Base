************************************************************************
* /MBTOOLS/CL_GUI_ROUTER
* MBT GUI Router
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************
CLASS /mbtools/cl_gui_router DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES /mbtools/if_gui_event_handler .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_event_data,
        action    TYPE string,
        prev_page TYPE string,
        getdata   TYPE string,
        postdata  TYPE cnht_post_data_tab,
      END OF ty_event_data .

    METHODS general_page_routing
      IMPORTING
        !is_event_data TYPE ty_event_data
      EXPORTING
        !ei_page       TYPE REF TO /mbtools/if_gui_renderable
        !ev_state      TYPE i
      RAISING
        /mbtools/cx_exception.

    METHODS sap_gui_actions
      IMPORTING
        !is_event_data TYPE ty_event_data
      EXPORTING
        !ei_page       TYPE REF TO /mbtools/if_gui_renderable
        !ev_state      TYPE i
      RAISING
        /mbtools/cx_exception.

ENDCLASS.



CLASS /MBTOOLS/CL_GUI_ROUTER IMPLEMENTATION.


  METHOD /mbtools/if_gui_event_handler~on_event.

    DATA: ls_event_data TYPE ty_event_data.

    ls_event_data-action    = iv_action.
    ls_event_data-getdata   = iv_getdata.
    ls_event_data-postdata  = it_postdata.

    general_page_routing(
      EXPORTING
        is_event_data = ls_event_data
      IMPORTING
        ei_page       = ei_page
        ev_state      = ev_state ).

    sap_gui_actions(
      EXPORTING
        is_event_data = ls_event_data
      IMPORTING
        ei_page       = ei_page
        ev_state      = ev_state ).

    IF ev_state IS INITIAL.
      ev_state = /mbtools/cl_gui=>c_event_state-not_handled.
    ENDIF.

  ENDMETHOD.


  METHOD general_page_routing ##TODO.

    CASE is_event_data-action.

      WHEN /mbtools/cl_gui=>c_action-go_home.
        CREATE OBJECT ei_page TYPE /mbtools/cl_gui_page_main.
        ev_state = /mbtools/cl_gui=>c_event_state-new_page.
      WHEN /mbtools/if_definitions=>c_action-go_settings.
*        CREATE OBJECT ei_page TYPE /mbtools/cl_gui_page_settings.
*        ev_state = /mbtools/cl_gui=>c_event_state-new_page.
    ENDCASE.

  ENDMETHOD.


  METHOD sap_gui_actions ##TODO.

    CASE is_event_data-action.

      WHEN /mbtools/if_definitions=>c_action-jump.                          " Open object editor
        ev_state = /mbtools/cl_gui=>c_event_state-no_more_act.

      WHEN /mbtools/if_definitions=>c_action-url.
        ev_state = /mbtools/cl_gui=>c_event_state-no_more_act.

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
