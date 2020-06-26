************************************************************************
* /MBTOOLS/IF_PROGRESS
* MBT Progress Indicator
*
* Original Author: Copyright (c) 2014 abapGit Contributors
* http://www.abapgit.org
*
* Released under MIT License: https://opensource.org/licenses/MIT
************************************************************************
INTERFACE /mbtools/if_progress
  PUBLIC .


  METHODS show
    IMPORTING
      !iv_current TYPE i
      !iv_text    TYPE csequence .
  METHODS set_total
    IMPORTING
      !iv_total TYPE i OPTIONAL.
ENDINTERFACE.