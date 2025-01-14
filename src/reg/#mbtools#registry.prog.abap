REPORT /mbtools/registry MESSAGE-ID /mbtools/bc.
************************************************************************
* MBT Registry
*
* Viewer and editor for registry stored in /MBTOOLS/REGS
*
* Implementation of a registry for storing arbitrary values (similar
* to the MS Windows registry)
*
* Ported to namespace and enhanced by Marc Bernard Tools
*
* Copyright 2015 Martin Ceronio <http://ceronio.net>
* SPDX-License-Identifier: MIT
************************************************************************

" For splitter container
DATA: gr_splitter TYPE REF TO cl_gui_easy_splitter_container.

" Single statement to generate a selection screen
PARAMETERS: p_dummy ##NEEDED.

DATA: gv_dynnr TYPE sydynnr.
DATA: gv_repid TYPE syrepid.

START-OF-SELECTION.


AT SELECTION-SCREEN OUTPUT.

  " Disable Execute and Save functions on report selection screen
  PERFORM insert_into_excl(rsdbrunt) USING 'ONLI'.
  PERFORM insert_into_excl(rsdbrunt) USING 'SPOS'.

  " Initialize the display on the first dynpro roundtrip
  IF gr_splitter IS NOT BOUND.
    gv_dynnr = sy-dynnr.
    gv_repid = sy-repid.

    CREATE OBJECT gr_splitter
      EXPORTING
        link_dynnr        = gv_dynnr
        link_repid        = gv_repid
        parent            = cl_gui_easy_splitter_container=>default_screen
        orientation       = 1    " Orientation: 0 = Vertical, 1 = Horizontal
        sash_position     = 30    " Position of Splitter Bar (in Percent)
        with_border       = 0    " With Border = 1; Without Border = 0
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    /mbtools/cl_registry_ui=>create_tree( gr_splitter ).

    " Table creation is deferred until the first node is selected

  ENDIF.
