CLASS /mbtools/cl_html_lib DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

************************************************************************
* MBT HTML Library
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_event_signature,
        method TYPE string,
        name   TYPE string,
      END OF  ty_event_signature .
    TYPES:
      BEGIN OF ty_col_spec,
        tech_name    TYPE string,
        display_name TYPE string,
        css_class    TYPE string,
        add_tz       TYPE abap_bool,
        title        TYPE string,
      END OF ty_col_spec .
    TYPES:
      ty_col_specs TYPE STANDARD TABLE OF ty_col_spec
                                    WITH NON-UNIQUE KEY tech_name .

    CLASS-METHODS class_constructor .
    CLASS-METHODS render_error
      IMPORTING
        !ix_error       TYPE REF TO /mbtools/cx_exception OPTIONAL
        !iv_error       TYPE string OPTIONAL
        !iv_extra_style TYPE string OPTIONAL
      RETURNING
        VALUE(ri_html)  TYPE REF TO /mbtools/if_html .
    CLASS-METHODS render_js_error_banner
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html
      RAISING
        /mbtools/cx_exception .
    CLASS-METHODS render_news
      IMPORTING
        !io_news       TYPE REF TO /mbtools/cl_news
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html
      RAISING
        /mbtools/cx_exception .
    CLASS-METHODS render_error_message_box
      IMPORTING
        !ix_error      TYPE REF TO /mbtools/cx_exception
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html .
    CLASS-METHODS render_warning_banner
      IMPORTING
        !iv_text       TYPE string
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html .
    CLASS-METHODS render_infopanel
      IMPORTING
        !iv_div_id     TYPE string
        !iv_title      TYPE string
        !iv_hide       TYPE abap_bool DEFAULT abap_true
        !iv_hint       TYPE string OPTIONAL
        !iv_scrollable TYPE abap_bool DEFAULT abap_true
        !ii_content    TYPE REF TO /mbtools/if_html
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html
      RAISING
        /mbtools/cx_exception .
    CLASS-METHODS render_event_as_form
      IMPORTING
        !is_event      TYPE ty_event_signature
      RETURNING
        VALUE(ri_html) TYPE REF TO /mbtools/if_html .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA gv_time_zone TYPE timezone.

    CLASS-METHODS get_t100_text
      IMPORTING
        iv_msgid       TYPE scx_t100key-msgid
        iv_msgno       TYPE scx_t100key-msgno
      RETURNING
        VALUE(rv_text) TYPE string.
    CLASS-METHODS normalize_program_name
      IMPORTING
        iv_program_name                   TYPE sy-repid
      RETURNING
        VALUE(rv_normalized_program_name) TYPE string.
ENDCLASS.



CLASS /MBTOOLS/CL_HTML_LIB IMPLEMENTATION.


  METHOD class_constructor.

    CALL FUNCTION 'GET_SYSTEM_TIMEZONE'
      IMPORTING
        timezone            = gv_time_zone
      EXCEPTIONS
        customizing_missing = 1
        OTHERS              = 2.
    ASSERT sy-subrc = 0.

  ENDMETHOD.


  METHOD get_t100_text.

    SELECT SINGLE text
           FROM t100
           INTO rv_text
           WHERE arbgb = iv_msgid
           AND msgnr = iv_msgno
           AND sprsl = sy-langu.

  ENDMETHOD.


  METHOD normalize_program_name.

    rv_normalized_program_name = substring_before(
                                     val   = iv_program_name
                                     regex = `(=+CP)?$` ).

  ENDMETHOD.


  METHOD render_error.

    DATA lv_error TYPE string.
    DATA lv_class TYPE string VALUE 'panel error center'.

    IF iv_extra_style IS NOT INITIAL.
      lv_class = lv_class && ` ` && iv_extra_style.
    ENDIF.

    ri_html = /mbtools/cl_html=>create( ).

    IF ix_error IS BOUND.
      lv_error = ix_error->get_text( ).
    ELSE.
      lv_error = iv_error.
    ENDIF.

    ri_html->add( |<div class="{ lv_class }">| ).
    ri_html->add( |{ ri_html->icon( 'exclamation-circle/red' ) } Error: { lv_error }| ).
    ri_html->add( '</div>' ).

  ENDMETHOD.


  METHOD render_error_message_box.

    DATA:
      lv_error_text   TYPE string,
      lv_longtext     TYPE string,
      lv_program_name TYPE sy-repid,
      lv_title        TYPE string,
      lv_text         TYPE string.

    ri_html = /mbtools/cl_html=>create( ).

    lv_error_text = ix_error->get_text( ).
    lv_longtext = ix_error->get_longtext( abap_true ).

    REPLACE FIRST OCCURRENCE OF REGEX |(<br>{ /mbtools/cl_message_helper=>gc_section_text-cause }<br>)|
            IN lv_longtext
            WITH |<h3>$1</h3>|.

    REPLACE FIRST OCCURRENCE OF REGEX |(<br>{ /mbtools/cl_message_helper=>gc_section_text-system_response }<br>)|
            IN lv_longtext
            WITH |<h3>$1</h3>|.

    REPLACE FIRST OCCURRENCE OF REGEX |(<br>{ /mbtools/cl_message_helper=>gc_section_text-what_to_do }<br>)|
            IN lv_longtext
            WITH |<h3>$1</h3>|.

    REPLACE FIRST OCCURRENCE OF REGEX |(<br>{ /mbtools/cl_message_helper=>gc_section_text-sys_admin }<br>)|
            IN lv_longtext
            WITH |<h3>$1</h3>|.

    ri_html->add( |<div id="message" class="message-panel">| ).
    ri_html->add( |{ lv_error_text }| ).
    ri_html->add( |<div class="float-right">| ).

    ri_html->add_a(
        iv_txt   = `&#x274c;`
        iv_act   = `toggleDisplay('message')`
        iv_class = `close-btn`
        iv_typ   = /mbtools/if_html=>c_action_type-onclick ).

    ri_html->add( |</div>| ).

    ri_html->add( |<div class="float-right message-panel-commands">| ).

    IF ix_error->if_t100_message~t100key-msgid IS NOT INITIAL.

      lv_title = get_t100_text(
                    iv_msgid = ix_error->if_t100_message~t100key-msgid
                    iv_msgno = ix_error->if_t100_message~t100key-msgno ).

      lv_text = |Message ({ ix_error->if_t100_message~t100key-msgid }/{ ix_error->if_t100_message~t100key-msgno })|.

      ri_html->add_a(
          iv_txt   = lv_text
          iv_typ   = /mbtools/if_html=>c_action_type-sapevent
          iv_act   = /mbtools/if_actions=>goto_message
          iv_title = lv_title
          iv_id    = `a_goto_message` ).

    ENDIF.

    ix_error->get_source_position( IMPORTING program_name = lv_program_name ).

    lv_title = normalize_program_name( lv_program_name ).

    ri_html->add_a(
        iv_txt   = `Goto source`
        iv_act   = /mbtools/if_actions=>goto_source
        iv_typ   = /mbtools/if_html=>c_action_type-sapevent
        iv_title = lv_title
        iv_id    = `a_goto_source` ).

    ri_html->add_a(
        iv_txt = `Callstack`
        iv_act = /mbtools/if_actions=>show_callstack
        iv_typ = /mbtools/if_html=>c_action_type-sapevent
        iv_id  = `a_callstack` ).

    ri_html->add( |</div>| ).
    ri_html->add( |<div class="message-panel-commands">| ).
    ri_html->add( |{ lv_longtext }| ).
    ri_html->add( |</div>| ).
    ri_html->add( |</div>| ).

  ENDMETHOD.


  METHOD render_event_as_form.

    ri_html = /mbtools/cl_html=>create( ).

    ri_html->add(
      |<form id='form_{ is_event-name }' method={ is_event-method } action='sapevent:{ is_event-name }'></form>| ).

  ENDMETHOD.


  METHOD render_infopanel.

    DATA lv_display TYPE string.
    DATA lv_class TYPE string.

    ri_html = /mbtools/cl_html=>create( ).

    IF iv_hide = abap_true. " Initially hide
      lv_display = 'display:none'.
    ENDIF.

    lv_class = 'info-panel'.
    IF iv_scrollable = abap_false. " Initially hide
      lv_class = lv_class && ' info-panel-fixed'.
    ENDIF.

    ri_html->add( |<div id="{ iv_div_id }" class="{ lv_class }" style="{ lv_display }">| ).

    ri_html->add( |<div class="info-title">{ iv_title
                  }<div class="float-right">{
                  ri_html->a(
                    iv_txt   = '&#x274c;'
                    iv_typ   = /mbtools/if_html=>c_action_type-onclick
                    iv_act   = |toggleDisplay('{ iv_div_id }')|
                    iv_class = 'close-btn' )
                  }</div></div>| ).

    IF iv_hint IS NOT INITIAL.
      ri_html->add( |<div class="info-hint">{ iv_hint }</div>| ).
    ENDIF.

    ri_html->add( '<div class="info-list">' ).
    ri_html->add( ii_content ).
    ri_html->add( '</div>' ).
    ri_html->add( '</div><!-- infopanel -->' ).

  ENDMETHOD.


  METHOD render_js_error_banner.

    ri_html = /mbtools/cl_html=>create( ).

    ri_html->add( '<div id="js-error-banner" class="dummydiv error">' ).
    ri_html->add( |{ ri_html->icon( 'exclamation-triangle/red' ) }| &&
                  ' If this does not disappear soon,' &&
                  ' then there is a JS init error, please log an issue' ).
    ri_html->add( '</div>' ).

  ENDMETHOD.


  METHOD render_news.

    DATA: lv_text TYPE string,
          lv_hint TYPE string,
          lt_log  TYPE /mbtools/cl_news=>ty_logs.

    FIELD-SYMBOLS: <ls_line> LIKE LINE OF lt_log.

    ri_html = /mbtools/cl_html=>create( ).

    IF io_news IS NOT BOUND OR io_news->has_news( ) = abap_false.
      RETURN.
    ENDIF.

    lt_log = io_news->get_log( ).

    " Render news
    LOOP AT lt_log ASSIGNING <ls_line>.
      IF <ls_line>-is_header = abap_true.
        IF <ls_line>-pos_to_cur > 0.
          lv_text = <ls_line>-text && '<span class="version-marker update">update</span>'.
        ELSEIF <ls_line>-pos_to_cur = 0.
          lv_text = <ls_line>-text && '<span class="version-marker">current</span>'.
        ELSE. " < 0
          lv_text = <ls_line>-text.
        ENDIF.
        ri_html->add( |<h1>{ lv_text }</h1>| ).
      ELSE.
        ri_html->add( |<li>{ <ls_line>-text }</li>| ).
      ENDIF.
    ENDLOOP.

    " Wrap
    IF io_news->has_important( ) = abap_true.
      lv_hint = 'Please note changes marked with "!"'.
    ENDIF.

    ri_html = render_infopanel(
      iv_div_id  = 'news'
      iv_title   = 'Announcement of Latest Changes'
      iv_hint    = lv_hint
      iv_hide    = boolc( io_news->has_unseen( ) = abap_false )
      ii_content = ri_html ).

  ENDMETHOD.


  METHOD render_warning_banner.

    ri_html = /mbtools/cl_html=>create( ).

    ri_html->add( '<div class="dummydiv warning">' ).
    ri_html->add( |{ ri_html->icon( 'exclamation-triangle/yellow' ) } { iv_text }| ).
    ri_html->add( '</div>' ).

  ENDMETHOD.
ENDCLASS.