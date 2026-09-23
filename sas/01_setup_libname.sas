/*********************************************************************
*  PROGRAM : 01_setup_libname.sas
*  PURPOSE : Session setup for the Single-Family loan performance
*            reporting suite. Assigns the permanent library and
*            defines every path and shared constant as a macro
*            variable. Programs 02-05 reference these and contain
*            no hardcoded paths.
*  RUN     : First, in the same session as 02-05.
*
*  NOTE    : Representative legacy program written for the
*            SAS-to-Databricks migration project. It is the
*            migration source, not production code.
*********************************************************************/

options mprint mlogic symbolgen nocenter
        ls=132 ps=60 compress=yes
        dlcreatedir;

/*--- paths ---------------------------------------------------------*/
%let fm_root  = ~/fanniemae;
%let raw_file = &fm_root/2007Q1_sample.csv;
%let lib_path = &fm_root/sasdata;
%let out_path = &fm_root/output;

/*--- permanent library ---------------------------------------------*/
/* DLCREATEDIR (above) creates &lib_path if missing. The output      */
/* directory is NOT created by PROC EXPORT and must already exist.   */
libname fmlib "&lib_path";

/* Formats built in 05 are stored in FMLIB.FORMATS. FMTSEARCH makes   */
/* them visible to later sessions without re-running PROC FORMAT.     */
options fmtsearch=(fmlib work);

/*--- business constants --------------------------------------------*/
/* Delinquency status is months past due: 3 = 90+ days.              */
%let d90_threshold = 3;

/* Zero balance codes counted as a credit event (default):           */
/* 02 third-party sale, 03 short sale, 09 deed-in-lieu/REO,          */
/* 15 non-performing note sale.                                      */
%let dflt_zb_codes = '02','03','09','15';
