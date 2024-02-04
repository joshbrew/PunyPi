@echo off
set HYP_HOME=C:\MentorGraphics\HLVX.2.10\SDD_HOME\hyperlynx64
if EXIST %HYP_HOME%\Ams goto InstallDirFound

REM Get path from Registry
set KEYNAME=HKEY_CLASSES_ROOT\ffsfile\shell\open\command
REM Check for presence of key first.
reg query %KEYNAME% 2>nul || (echo HyperLynx is not installed! & exit /b 1)
for /f "tokens=3" %%a in ('reg query %KEYNAME% 2^>nul') do (
    set HYP_HOME=%%a
)
REM Remove bsw.exe
for /f %%i IN ("%HYP_HOME%") do (
	set HYP_HOME=%%~dpi
)

:InstallDirFound
echo HYP_HOME: %HYP_HOME%
set MGC_HOME=%HYP_HOME%\Ams

if not "%MGC_HOME%" == "" goto mgc_home_set
   echo ;; Error: MGC_HOME environment variable not set.
   echo ;;        Please set MGC_HOME to the root tree for your MGC products
   goto end

:mgc_home_set

if exist "%MGC_HOME%\pkgs\icx_pro_mb\_bin" goto got_mb
   echo ;; Error: icx_pro_mb package is not installed in current MGC_HOME.
   echo ;;        Please set MGC_HOME to a tree that contains that package, or install the package.
   goto end

:got_mb


if exist "%MGC_HOME%\pkgs\icx_pro_sim" goto got_icxs
   echo ;; Error: icx_pro_sim package is not installed in current MGC_HOME.
   echo ;;        Please set MGC_HOME to a tree that contains that package, or install the package.
   goto end

:got_icxs

REM .tcl script expected to be next to the batch file
set "SCRIPT_DIR=%~dp0"
cd "%SCRIPT_DIR%\.."
set "RESULTS_DIR=%CD%"
set "RESULTS_DIR=%RESULTS_DIR:\=/%"
set RESULTS_DIR

if [%1]==[] goto noArgs

set DataRate=%1
set TableType=%2

if %3=="" goto noThresholds
set Thresholds=%3
:noThresholds

set Time=%4

set WFfile1="%RESULTS_DIR%/%~5"
set WFname1=%6

if [%7]==[] goto noMoreWF
set WFfile2="%RESULTS_DIR%/%~7"
set WFname2=%8
shift
shift

if [%7]==[] goto noMoreWF
set WFfile3="%RESULTS_DIR%/%~7"
set WFname3=%8
shift
shift

if [%7]==[] goto noMoreWF
set WFfile4="%RESULTS_DIR%/%~7"
set WFname4=%8
:noMoreWF

:noArgs

REM Change drive: install might be on a different drive
%HYP_HOME:~0,2%

REM Support EZWave links to work with future releases of Ams
REM Sometimes installation has >1 subfolders in Ams\pkgs\icx_pro_sim
REM But first one might not have ixw\bin\ezwave.bat => loop through all folders

REM dp obsolete: cd %HYP_HOME%\Ams\pkgs\icx_pro_sim\18*
REM dp obsolete: cd %HYP_HOME%\Ams\pkgs\icx_pro_sim\19*
REM dp obsolete: cd %HYP_HOME%\Ams\pkgs\icx_pro_sim\21*

REM HLVX2.10: for /D %%d in (%HYP_HOME%\Ams\pkgs\icx_pro_sim\1*) do (
REM Find ezwave.bat in Ams tree
for /D %%d in (%HYP_HOME%\Ams\pkgs\icx_pro_sim\*) do (
    if EXIST %%d\ixw\bin\ezwave.bat (
        cd %%d
        goto have_AMS_DIR
    )
)
START CMD /C "ECHO Cannot find ezwave.bat in %HYP_HOME%\Ams\pkgs\icx_pro_sim to execute EZWave && PAUSE"
exit
:have_AMS_DIR

set AMS_DIR=%CD%
call .\bin\ams_setup.bat %AMS_DIR%

cd %SCRIPT_DIR%

set TCL_SCRIPT="%SCRIPT_DIR%\showDDRwfs.tcl"
if [%1]==[] set TCL_SCRIPT="%SCRIPT_DIR%\saveDDRimgs.tcl"

REM "" needed to support spaces in path
call %AMS_DIR%\ixw\bin\ezwave.bat -dofile ""%TCL_SCRIPT%""
REM dp HLVX2.10: This call doesn't allow spaces in HTML report paths:
REM dp HLVX2.10: call "%MGC_HOME%\pkgs\icx_pro_perl\_bin\icxperl" "%MGC_HOME%\pkgs\icx_pro_mb\_bin\icxezwave.pl" -dofile ""%TCL_SCRIPT%""

if exist "%SCRIPT_DIR%\ezwave_error.log" (
	wscript %HYP_HOME%\Scripts\check_EZwave_out.vbs "%SCRIPT_DIR%\ezwave_error.log"
)

:end
