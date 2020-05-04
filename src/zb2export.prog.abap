*&---------------------------------------------------------------------*
*& Report  ZB2EXPORT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ZB2EXPORT.


NODES:PERNR, PERAS.

data gt_table type ztt_b2.

** Selection screen
selection-screen begin of block b1 with frame title text-001.
  parameters: p_dir type pathextern default 'D:\Temp\' lower case obligatory.
selection-screen end of block b1.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dir.

    data lv_outdir type string.
    lv_outdir = text-001.
    CALL METHOD cl_gui_frontend_services=>directory_browse
      EXPORTING
        window_title         = lv_outdir
      CHANGING
        selected_folder      = lv_outdir
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3.
    IF sy-subrc EQ 0.
      CONCATENATE lv_outdir '\' INTO p_dir.
    ENDIF.


START-OF-SELECTION.


GET peras.

  data l_b2 type zst_b2.
** get B2 cluster
  l_b2 = zcl_b2=>read( iv_pernr = pernr-pernr iv_begda = pnpbegda iv_endda = pnpendda ).

  append l_b2 to gt_table.


END-OF-SELECTION.
** Download xml
  perform download_xml.
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_XML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form download_xml .
  data lv_xml_result type xstring.
  data lv_string type string.
  data lv_file type string.

  check gt_table[] is not initial.

** Create filename
  concatenate: 'B2_CLUSTER' sy-datum into lv_file separated by '_',
    lv_file sy-uzeit into lv_file,
    lv_file pnpendda(6) into lv_file separated by '_',
    lv_file '.xml' into lv_file,
    p_dir lv_file into lv_file.

** Call transformation to transform internal table to XML
  call transformation z_b2
    source B2 = gt_table
    result xml lv_xml_result.

** Convert XSTRING to string
  call function 'CRM_IC_XML_XSTRING2STRING'
    exporting
      inxstring = lv_xml_result
    importing
      outstring = lv_string.

  REPLACE ALL OCCURRENCES OF 'Á' IN lv_string WITH 'A'.
  REPLACE ALL OCCURRENCES OF 'É' IN lv_string WITH 'E'.
  REPLACE ALL OCCURRENCES OF 'Í' IN lv_string WITH 'I'.
  REPLACE ALL OCCURRENCES OF 'Ó' IN lv_string WITH 'O'.
  REPLACE ALL OCCURRENCES OF 'Ú' IN lv_string WITH 'U'.

  data itab type table of string.
  append lv_string to itab.

  cl_gui_frontend_services=>gui_download( EXPORTING
                                              filename = lv_file
                                              filetype = 'DAT'
                                            CHANGING
                                              data_tab = itab
                                            EXCEPTIONS
                                              file_write_error          = 1
                                              no_batch                  = 2
                                              gui_refuse_filetransfer   = 3
                                              invalid_type              = 4
                                              no_authority              = 5
                                              unknown_error             = 6
                                              header_not_allowed        = 7
                                              separator_not_allowed     = 8
                                              filesize_not_allowed      = 9
                                              header_too_long           = 10
                                              dp_error_create           = 11
                                              dp_error_send             = 12
                                              dp_error_write            = 13
                                              unknown_dp_error          = 14
                                              access_denied             = 15
                                              dp_out_of_memory          = 16
                                              disk_full                 = 17
                                              dp_timeout                = 18
                                              file_not_found            = 19
                                              dataprovider_exception    = 20
                                              control_flush_error       = 21
                                              not_supported_by_gui      = 22
                                              error_no_gui              = 23
                                              OTHERS                    = 24   ).

  if sy-subrc ne 0.
    message 'Error while creating file' type 'E'.
  else.
    message 'File downloaded successfully' type 'S'.
  endif.

*** Download file
*  open dataset lv_file for output in text mode encoding default.
*
*  if sy-subrc ne 0.
*    message 'Error while creating file' type 'E'.
*  else.
*    transfer lv_string to lv_file.
*    close dataset lv_file.
*    message 'File downloades successfully' type 'S'.
*  endif.

endform.
