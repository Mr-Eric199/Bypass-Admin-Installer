@echo off
setlocal
title Bypass Admin Rights to Install Software
color 0A

:: #################################################
:: # Created by Eric Antwi                         #
:: # Note: This script can bypass installers that  #
:: # require explicit admin rights.                #
:: #################################################

:: -- File Picker --
for /f "delims=" %%I in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog; $FileBrowser.Filter = 'EXE Files|*.exe'; $FileBrowser.Title = 'Select EXE Installer'; if ($FileBrowser.ShowDialog() -eq 'OK') { echo $FileBrowser.FileName }"') do set "INSTALLER=%%I"

:: -- Validation --
if "%INSTALLER%"=="" (
    echo [!] Operation cancelled by user.
    timeout /t 2
    exit /b
)
if not exist "%INSTALLER%" (
    echo [!] ERROR: File not found: "%INSTALLER%"
    pause
    exit /b
)

:: -- EXE Signature Check --
echo [+] Verifying digital signature...
powershell -NoProfile -Command "try { if ((Get-AuthenticodeSignature -LiteralPath '%INSTALLER%').Status -ne 'Valid') { exit 1 } } catch { exit 1 }"
if errorlevel 1 (
    color 0C
    echo [!] WARNING: Unsigned or suspicious file!
    choice /c YN /m "Proceed anyway (Y/N)?"

    if errorlevel 2 (
        echo [!] Installation aborted by user.
        timeout /t 5
        exit /b
    )

    color 0A
)

:: -- Execution with Compatibility Layer --
set "__COMPAT_LAYER=RunAsInvoker"

:: Generate timestamped log filename
for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set "LOG_FILE=%TEMP%\InstallerLog_%%a.txt"

echo ============================================================= >> "%LOG_FILE%"
echo [Date/Time] %DATE% %TIME% >> "%LOG_FILE%"
echo [Installer] %INSTALLER% >> "%LOG_FILE%"
echo ============================================================= >> "%LOG_FILE%"

echo [!] Starting installation (DO NOT CLOSE)...

start /wait "" "%INSTALLER%"
set "EXIT_CODE=%ERRORLEVEL%"
echo [%TIME%] Exit Code: %EXIT_CODE% >> "%LOG_FILE%"

:: -- Post-Install Check --
if %EXIT_CODE% equ 0 (
    color 0A
    echo [+] SUCCESS: Installation completed.
) else (
    color 0C
    echo [!] ERROR: Installer failed (Code: %EXIT_CODE%).
    echo [Troubleshooting Steps]
    echo 1. The installer may require admin rights.
    echo 2. Verify the installer file integrity.
)
echo.
echo [!] Installation log saved to:
echo     "%LOG_FILE%"
timeout /t 10
exit /b %EXIT_CODE%
