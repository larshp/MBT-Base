CLASS /mbtools/cl_gui DEFINITION
  PUBLIC
  CREATE PUBLIC.

************************************************************************
* Marc Bernard Tools - GUI
*
* Copyright 2014 abapGit Contributors <http://www.abapgit.org>
* SPDX-License-Identifier: MIT
************************************************************************
  PUBLIC SECTION.

    INTERFACES /mbtools/if_gui_services.

    CONSTANTS:
      BEGIN OF c_event_state,
        not_handled         TYPE i VALUE 0,
        re_render           TYPE i VALUE 1,
        new_page            TYPE i VALUE 2,
        go_back             TYPE i VALUE 3,
        no_more_act         TYPE i VALUE 4,
        new_page_w_bookmark TYPE i VALUE 5,
        go_back_to_bookmark TYPE i VALUE 6,
        new_page_replacing  TYPE i VALUE 7,
      END OF c_event_state.

    METHODS go_home
      IMPORTING
        !iv_mode TYPE string
      RAISING
        /mbtools/cx_exception.
    METHODS back
      IMPORTING
        !iv_to_bookmark TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_exit)  TYPE abap_bool
      RAISING
        /mbtools/cx_exception.
    METHODS on_event
        FOR EVENT sapevent OF /mbtools/if_html_viewer
      IMPORTING
        !action
        !frame
        !getdata
        !postdata
        !query_table.
    METHODS constructor
      IMPORTING
        !io_component         TYPE REF TO object OPTIONAL
        !ii_asset_man         TYPE REF TO /mbtools/if_gui_asset_manager OPTIONAL
        !ii_hotkey_ctl        TYPE REF TO /mbtools/if_gui_hotkey_ctl OPTIONAL
        !ii_html_processor    TYPE REF TO /mbtools/if_gui_html_processor OPTIONAL
        !iv_rollback_on_error TYPE abap_bool DEFAULT abap_true
      RAISING
        /mbtools/cx_exception.
    METHODS free.
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_page_stack,
        page     TYPE REF TO /mbtools/if_gui_renderable,
        bookmark TYPE abap_bool,
      END OF ty_page_stack .

    DATA mv_rollback_on_error TYPE abap_bool .
    DATA mi_cur_page TYPE REF TO /mbtools/if_gui_renderable .
    DATA:
      mt_stack             TYPE STANDARD TABLE OF ty_page_stack .
    DATA:
      mt_event_handlers    TYPE STANDARD TABLE OF REF TO /mbtools/if_gui_event_handler .
    DATA mi_router TYPE REF TO /mbtools/if_gui_event_handler .
    DATA mi_asset_man TYPE REF TO /mbtools/if_gui_asset_manager .
    DATA mi_hotkey_ctl TYPE REF TO /mbtools/if_gui_hotkey_ctl .
    DATA mi_html_processor TYPE REF TO /mbtools/if_gui_html_processor .
    DATA mi_html_viewer TYPE REF TO /mbtools/if_html_viewer .
    DATA mo_html_parts TYPE REF TO /mbtools/cl_html_parts .
    DATA mv_online TYPE abap_bool .

    METHODS startup
      RAISING
        /mbtools/cx_exception .
    METHODS cache_html
      IMPORTING
        !iv_text      TYPE string
      RETURNING
        VALUE(rv_url) TYPE w3url
      RAISING
        /mbtools/cx_exception .
    METHODS render
      RAISING
        /mbtools/cx_exception .
    METHODS call_page
      IMPORTING
        !ii_page          TYPE REF TO /mbtools/if_gui_renderable
        !iv_with_bookmark TYPE abap_bool DEFAULT abap_false
        !iv_replacing     TYPE abap_bool DEFAULT abap_false
      RAISING
        /mbtools/cx_exception .
    METHODS handle_action
      IMPORTING
        !iv_action   TYPE c
        !iv_getdata  TYPE c OPTIONAL
        !it_postdata TYPE cnht_post_data_tab OPTIONAL .
    METHODS handle_error
      IMPORTING
        !ix_exception TYPE REF TO /mbtools/cx_exception .
    METHODS ping .
ENDCLASS.



CLASS /mbtools/cl_gui IMPLEMENTATION.


  METHOD /mbtools/if_gui_services~cache_all_assets.

    DATA:
      lx_error  TYPE REF TO /mbtools/cx_exception,
      lt_assets TYPE /mbtools/if_gui_asset_manager=>ty_web_assets.

    FIELD-SYMBOLS <ls_asset> LIKE LINE OF lt_assets.

    TRY.
        lt_assets = ii_asset_manager->get_all_assets( ).

        LOOP AT lt_assets ASSIGNING <ls_asset> WHERE is_cacheable = abap_true.
          /mbtools/if_gui_services~cache_asset(
            it_xdata   = <ls_asset>-mime_content
            iv_size    = <ls_asset>-size
            iv_url     = <ls_asset>-url
            iv_type    = <ls_asset>-type
            iv_subtype = <ls_asset>-subtype ).
        ENDLOOP.
      CATCH /mbtools/cx_exception INTO lx_error.
        " Some asset is missing
        MESSAGE lx_error TYPE 'E' DISPLAY LIKE 'I'.
    ENDTRY.

  ENDMETHOD.


  METHOD /mbtools/if_gui_services~cache_asset.

    DATA: lt_xdata TYPE lvc_t_mime,
          lv_size  TYPE i,
          lt_html  TYPE w3htmltab.

    ASSERT iv_text IS SUPPLIED OR iv_xdata IS SUPPLIED OR it_xdata IS SUPPLIED.

    IF iv_text IS SUPPLIED. " String input

      /mbtools/cl_convert=>string_to_tab(
        EXPORTING
          iv_str  = iv_text
        IMPORTING
          ev_size = lv_size
          et_tab  = lt_html ).

      mi_html_viewer->load_data(
        EXPORTING
          iv_url          = iv_url
          iv_type         = iv_type
          iv_subtype      = iv_subtype
          iv_size         = lv_size
        IMPORTING
          ev_assigned_url = rv_url
        CHANGING
          ct_data_table   = lt_html
        EXCEPTIONS
          OTHERS          = 1 ).

    ELSE. " Raw input

      IF iv_xdata IS INITIAL.
        lv_size  = iv_size.
        lt_xdata = it_xdata.
      ELSE.
        /mbtools/cl_convert=>xstring_to_bintab(
          EXPORTING
            iv_xstr   = iv_xdata
          IMPORTING
            ev_size   = lv_size
            et_bintab = lt_xdata ).
      ENDIF.

      mi_html_viewer->load_data(
        EXPORTING
          iv_url          = iv_url
          iv_type         = iv_type
          iv_subtype      = iv_subtype
          iv_size         = lv_size
        IMPORTING
          ev_assigned_url = rv_url
        CHANGING
          ct_data_table   = lt_xdata
        EXCEPTIONS
          OTHERS          = 1 ).

    ENDIF.

    IF sy-subrc <> 0.
      /mbtools/cx_exception=>raise( |Error caching data for HTML viewer: { iv_url }| ).
    ENDIF.

  ENDMETHOD.


  METHOD /mbtools/if_gui_services~get_current_page_name.

    IF mi_cur_page IS BOUND.
      rv_page_name = cl_abap_classdescr=>describe_by_object_ref( mi_cur_page )->get_relative_name( ).
    ENDIF." ELSE - return is empty => initial page

  ENDMETHOD.


  METHOD /mbtools/if_gui_services~get_hotkeys_ctl.
    ri_hotkey_ctl = mi_hotkey_ctl.
  ENDMETHOD.


  METHOD /mbtools/if_gui_services~get_html_parts.
    ro_parts = mo_html_parts.
  ENDMETHOD.


  METHOD /mbtools/if_gui_services~register_event_handler.
    ASSERT ii_event_handler IS BOUND.
    INSERT ii_event_handler INTO mt_event_handlers INDEX 1.
  ENDMETHOD.


  METHOD back.

    DATA: lv_index TYPE i,
          ls_stack LIKE LINE OF mt_stack.

    " If viewer is showing Internet page, then use browser navigation
    IF mi_html_viewer->get_url( ) CP 'http*'.
      mi_html_viewer->back( ).
      RETURN.
    ENDIF.

    lv_index = lines( mt_stack ).

    IF lv_index = 0.
      rv_exit = abap_true.
      RETURN.
    ENDIF.

    DO lv_index TIMES.
      READ TABLE mt_stack INDEX lv_index INTO ls_stack.
      ASSERT sy-subrc = 0.

      DELETE mt_stack INDEX lv_index.
      ASSERT sy-subrc = 0.

      lv_index = lv_index - 1.

      IF iv_to_bookmark = abap_false OR ls_stack-bookmark = abap_true.
        EXIT.
      ENDIF.
    ENDDO.

    mi_cur_page = ls_stack-page. " last page always stays
    render( ).

  ENDMETHOD.


  METHOD cache_html.

    rv_url = /mbtools/if_gui_services~cache_asset(
      iv_text    = iv_text
      iv_type    = 'text'
      iv_subtype = 'html' ).

  ENDMETHOD.


  METHOD call_page.

    DATA: ls_stack TYPE ty_page_stack.

    IF iv_replacing = abap_false AND mi_cur_page IS NOT INITIAL.
      ls_stack-page     = mi_cur_page.
      ls_stack-bookmark = iv_with_bookmark.
      APPEND ls_stack TO mt_stack.
    ENDIF.

    mi_cur_page = ii_page.
    render( ).

  ENDMETHOD.


  METHOD constructor.

    IF io_component IS BOUND.
      IF /mbtools/cl_gui_utils=>is_renderable( io_component ) = abap_true.
        mi_cur_page ?= io_component. " direct page
      ELSE.
        IF /mbtools/cl_gui_utils=>is_event_handler( io_component ) = abap_false.
          /mbtools/cx_exception=>raise( 'Component must be renderable or be an event handler' ).
        ENDIF.
        mi_router ?= io_component.
      ENDIF.
    ENDIF.

    CREATE OBJECT mo_html_parts.

    mv_rollback_on_error = iv_rollback_on_error.
    mi_asset_man      = ii_asset_man.
    mi_hotkey_ctl     = ii_hotkey_ctl.
    mi_html_processor = ii_html_processor. " Maybe improve to middlewares stack ??

    ping( ).

    startup( ).

  ENDMETHOD.


  METHOD free.

    SET HANDLER me->on_event FOR mi_html_viewer ACTIVATION space.
    mi_html_viewer->close_document( ).
    mi_html_viewer->free( ).
    FREE mi_html_viewer.

  ENDMETHOD.


  METHOD go_home.

    DATA:
      ls_stack LIKE LINE OF mt_stack,
      lv_mode  TYPE c LENGTH 20.

    IF mi_router IS BOUND.
      CLEAR: mt_stack, mt_event_handlers.
      APPEND mi_router TO mt_event_handlers.

      IF iv_mode IS INITIAL.
        lv_mode = /mbtools/cl_utilities=>get_user_parameter( '/MBTOOLS/MODE' ).
        lv_mode = to_lower( lv_mode ).
      ELSE.
        lv_mode = iv_mode.
      ENDIF.

      IF lv_mode = /mbtools/if_actions=>go_admin.
        " doesn't accept strings directly
        on_event( action = |{ /mbtools/if_actions=>go_admin }| ).
      ELSE.
        " doesn't accept strings directly
        on_event( action = |{ /mbtools/if_actions=>go_home }| ).
      ENDIF.
    ELSE.
      IF lines( mt_stack ) > 0.
        READ TABLE mt_stack INTO ls_stack INDEX 1.
        ASSERT sy-subrc = 0.
        mi_cur_page = ls_stack-page.
      ENDIF.
      render( ).
    ENDIF.

  ENDMETHOD.


  METHOD handle_action.

    DATA:
      lx_exception TYPE REF TO /mbtools/cx_exception,
      li_handler   TYPE REF TO /mbtools/if_gui_event_handler,
      li_event     TYPE REF TO /mbtools/if_gui_event,
      ls_handled   TYPE /mbtools/if_gui_event_handler=>ty_handling_result.

    CREATE OBJECT li_event TYPE /mbtools/cl_gui_event
      EXPORTING
        iv_action   = iv_action
        iv_getdata  = iv_getdata
        it_postdata = it_postdata.

    TRY.
        LOOP AT mt_event_handlers INTO li_handler.
          ls_handled = li_handler->on_event( li_event ).
          IF ls_handled-state IS NOT INITIAL AND ls_handled-state <> c_event_state-not_handled.
            EXIT.
          ENDIF.
        ENDLOOP.

        CASE ls_handled-state.
          WHEN c_event_state-re_render.
            render( ).
          WHEN c_event_state-new_page.
            call_page( ls_handled-page ).
          WHEN c_event_state-new_page_w_bookmark.
            call_page(
              ii_page          = ls_handled-page
              iv_with_bookmark = abap_true ).
          WHEN c_event_state-new_page_replacing.
            call_page(
              ii_page      = ls_handled-page
              iv_replacing = abap_true ).
          WHEN c_event_state-go_back.
            back( ).
          WHEN c_event_state-go_back_to_bookmark.
            back( abap_true ).
          WHEN c_event_state-no_more_act.
            " Do nothing, handling completed
            RETURN.
          WHEN OTHERS.
            /mbtools/cx_exception=>raise( |Unknown action: { iv_action }| ).
        ENDCASE.

      CATCH /mbtools/cx_cancel ##NO_HANDLER.
        " Do nothing = gc_event_state-no_more_act
      CATCH /mbtools/cx_exception INTO lx_exception.
        handle_error( lx_exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD handle_error.

    DATA: li_gui_error_handler TYPE REF TO /mbtools/if_gui_error_handler,
          lx_exception         TYPE REF TO cx_root.

    IF mv_rollback_on_error = abap_true.
      ROLLBACK WORK.                                   "#EC CI_ROLLBACK
    ENDIF.

    TRY.
        li_gui_error_handler ?= mi_cur_page.

        IF li_gui_error_handler->handle_error( ix_exception ) = abap_true.
          " We rerender the current page to display the error box
          render( ).
        ELSE.
          MESSAGE ix_exception TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.

      CATCH cx_root INTO lx_exception.
        " In case of fire we just fallback to plain old message
        MESSAGE lx_exception TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.


  METHOD on_event.

    handle_action(
      iv_action   = action
      iv_getdata  = getdata
      it_postdata = postdata ).

  ENDMETHOD.


  METHOD ping.

    mv_online = /mbtools/cl_mbt=>is_online( ).

  ENDMETHOD.


  METHOD render.

    DATA: lv_url  TYPE w3url,
          lv_html TYPE string,
          li_html TYPE REF TO /mbtools/if_html.

    IF mi_cur_page IS NOT BOUND.
      /mbtools/cx_exception=>raise( 'GUI error: no current page' ).
    ENDIF.

    CLEAR mt_event_handlers.
    mo_html_parts->clear( ).

    IF mi_router IS BOUND.
      APPEND mi_router TO mt_event_handlers.
    ENDIF.

    IF mi_hotkey_ctl IS BOUND.
      mi_hotkey_ctl->reset( ).
    ENDIF.

    li_html = mi_cur_page->render( ).
    lv_html = li_html->render( abap_true ).

    IF mi_html_processor IS BOUND.
      lv_html = mi_html_processor->process(
        iv_html         = lv_html
        ii_gui_services = me ).
    ENDIF.

    lv_url  = cache_html( lv_html ).
    mi_html_viewer->show_url( lv_url ).

  ENDMETHOD.


  METHOD startup.

    DATA: lt_events TYPE cntl_simple_events,
          ls_event  LIKE LINE OF lt_events,
          lt_assets TYPE /mbtools/if_gui_asset_manager=>ty_web_assets.

    FIELD-SYMBOLS <ls_asset> LIKE LINE OF lt_assets.

    mi_html_viewer = /mbtools/cl_gui_factory=>get_html_viewer( ).

    IF mi_asset_man IS BOUND.
      lt_assets = mi_asset_man->get_all_assets( ).
      LOOP AT lt_assets ASSIGNING <ls_asset> WHERE is_cacheable = abap_true.
        /mbtools/if_gui_services~cache_asset(
          iv_xdata   = <ls_asset>-content
          it_xdata   = <ls_asset>-mime_content
          iv_size    = <ls_asset>-size
          iv_url     = <ls_asset>-url
          iv_type    = <ls_asset>-type
          iv_subtype = <ls_asset>-subtype ).
      ENDLOOP.
    ENDIF.

    ls_event-eventid    = mi_html_viewer->c_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    mi_html_viewer->set_registered_events( lt_events ).
    SET HANDLER me->on_event FOR mi_html_viewer.

  ENDMETHOD.
ENDCLASS.
