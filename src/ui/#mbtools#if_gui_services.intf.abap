************************************************************************
* /MBTOOLS/IF_GUI_SERVICES
* MBT GUI Services
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************
INTERFACE /mbtools/if_gui_services
  PUBLIC .

  METHODS cache_asset
    IMPORTING
      !iv_text      TYPE string OPTIONAL
      !iv_xdata     TYPE xstring OPTIONAL
      !iv_url       TYPE w3url OPTIONAL
      !iv_type      TYPE c
      !iv_subtype   TYPE c
    RETURNING
      VALUE(rv_url) TYPE w3url .

  METHODS register_event_handler
    IMPORTING
      !ii_event_handler TYPE REF TO /mbtools/if_gui_event_handler .

  METHODS get_current_page_name
    RETURNING
      VALUE(rv_page_name) TYPE string .

  METHODS get_hotkeys_ctl
    RETURNING
      VALUE(ri_hotkey_ctl) TYPE REF TO /mbtools/if_gui_hotkey_ctl.

  METHODS get_html_parts
    RETURNING
      VALUE(ro_parts) TYPE REF TO /mbtools/cl_html_parts .

ENDINTERFACE.
