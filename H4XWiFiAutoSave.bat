@echo off
setlocal EnableDelayedExpansion
title H4X-WIFI-AUTOSAVE v1.0
color 0a
cls

:: Hacker-style ASCII art header
echo.
echo   ==============================
echo      H4X-WIFI-AUTOSAVE v1.0
echo   ==============================
echo      Cyber-Net Profile Vault
echo   ==============================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Admin access required, H4X0R!
    echo [H4X-NET] Right-click and select "Run as administrator".
    pause
    exit /b
)

:: Set backup and log directories
set BACKUP_DIR=%~dp0H4X_WiFi_Backup
set LOG_FILE=%BACKUP_DIR%\WiFi_AutoSave_Log.txt
set TEMP_PROFILE_LIST=%BACKUP_DIR%\temp_profiles.txt
set OLD_PROFILE_LIST=%BACKUP_DIR%\old_profiles.txt

:: Create backup directory if it doesn't exist
if not exist "!BACKUP_DIR!" (
    mkdir "!BACKUP_DIR!"
    echo [H4X-NET] Created backup vault: !BACKUP_DIR!
)

:: Initialize log file
if not exist "!LOG_FILE!" (
    echo Wi-Fi Auto-Save Log - %DATE% %TIME% > "!LOG_FILE!"
    echo. >> "!LOG_FILE!"
    echo Saved Wi-Fi Profiles: >> "!LOG_FILE!"
    echo ------------------------- >> "!LOG_FILE!"
)

:: Main loop to monitor profiles
:monitor
cls
echo [H4X-NET] Monitoring Wi-Fi profiles... Press Ctrl+C to exit.

:: Get current profiles
netsh wlan show profiles | findstr "All User Profile" > "!TEMP_PROFILE_LIST!"
if not exist "!TEMP_PROFILE_LIST!" (
    echo [H4X-NET] No Wi-Fi profiles found.
    echo No Wi-Fi profiles found at %DATE% %TIME%. >> "!LOG_FILE!"
    timeout /t 5 >nul
    goto monitor
)

:: Export all profiles to XML
netsh wlan export profile folder="!BACKUP_DIR!" key=clear >nul
echo [H4X-NET] Backed up profiles to: !BACKUP_DIR!

:: Compare with previous profiles (if exists)
if exist "!OLD_PROFILE_LIST!" (
    echo [H4X-NET] Checking for forgotten profiles...
    for /f "tokens=4*" %%i in (!OLD_PROFILE_LIST!) do (
        set "OLD_SSID=%%i %%j"
        set "OLD_SSID=!OLD_SSID:~0,-1!"
        :: Check if SSID is missing in current profiles
        findstr /C:"!OLD_SSID!" "!TEMP_PROFILE_LIST!" >nul
        if errorlevel 1 (
            echo [H4X-NET] Detected forgotten SSID: !OLD_SSID!
            echo Forgotten SSID: !OLD_SSID! at %DATE% %TIME% >> "!LOG_FILE!"
            
            :: Get password from exported XML (if exists)
            set FOUND=0
            for %%f in ("!BACKUP_DIR!\Wi-Fi-!OLD_SSID!.xml") do (
                if exist "%%f" (
                    set FOUND=1
                    findstr "keyMaterial" "%%f" > temp_key.txt
                    if exist temp_key.txt (
                        for /f "tokens=2 delims=><" %%k in (temp_key.txt) do (
                            set "PASSWORD=%%k"
                            echo [H4X-NET] Password: !PASSWORD!
                            echo Password: !PASSWORD! >> "!LOG_FILE!"
                        )
                        del temp_key.txt
                    ) else (
                        echo [H4X-NET] Password: [Not Available]
                        echo Password: [Not Available] >> "!LOG_FILE!"
                    )
                )
            )
            if !FOUND! equ 0 (
                echo [H4X-NET] Password: [Not Available]
                echo Password: [Not Available] >> "!LOG_FILE!"
            )
            
            :: Ensure profile is deleted
            netsh wlan delete profile name="!OLD_SSID!" >nul 2>&1
            echo [H4X-NET] Profile deleted from system.
            echo Profile deleted from system. >> "!LOG_FILE!"
            echo ------------------------- >> "!LOG_FILE!"
        )
    )
)

:: Update old profile list
copy /Y "!TEMP_PROFILE_LIST!" "!OLD_PROFILE_LIST!" >nul

:: Check Event Logs for deletions (using PowerShell)
powershell -Command "Get-WinEvent -LogName 'Microsoft-Windows-WLAN-AutoConfig/Operational' -MaxEvents 10 | Where-Object { $_.Id -eq 8003 } | Select-Object -Property TimeCreated,@{Name='SSID';Expression={$_.Properties[0].Value}} | Format-Table -AutoSize | Out-File -Encoding ASCII temp_events.txt"
if exist temp_events.txt (
    findstr /C:"SSID" temp_events.txt > temp_filtered.txt
    if !errorlevel! equ 0 (
        for /f "tokens=3*" %%a in (temp_filtered.txt) do (
            echo [H4X-NET] Event Log - Deleted SSID: %%a
            echo Event Log - Deleted SSID: %%a at %DATE% %TIME% >> "!LOG_FILE!"
            echo Password: [Not Available in Logs] >> "!LOG_FILE!"
            echo ------------------------- >> "!LOG_FILE!"
        )
    )
    del temp_events.txt temp_filtered.txt 2>nul
)

:: Wait before next check
timeout /t 5 >nul
goto monitor