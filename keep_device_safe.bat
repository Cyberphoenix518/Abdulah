@echo off
setlocal EnableDelayedExpansion

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo Keep Your Device Safe - Windows Security Script
echo =============================================
echo This script will help protect your device by:
echo - Disabling risky features (e.g., Remote Desktop, SMBv1)
echo - Setting up the Windows Firewall
echo - Checking for suspicious processes
echo - Enabling security features (e.g., UAC, Windows Defender)
echo - Providing tips for ongoing safety
echo.
echo WARNING: Backup your system before proceeding.
echo Press any key to start or Ctrl+C to cancel...
pause >nul

:: Create a log file
set "logfile=%temp%\device_safety_%date:~-4%%date:~4,2%%date:~7,2%.log"
echo Device Safety Log > "%logfile%"
echo Date: %date% %time% >> "%logfile%"
echo. >> "%logfile%"

:: 1. Disable Risky Features
echo Disabling risky features... >> "%logfile%"
echo Disabling Remote Desktop (unless you use it, can be re-enabled)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1
sc config TermService start= disabled >> "%logfile%" 2>&1

echo Disabling SMBv1 (vulnerable to ransomware)...
powershell -Command "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol" >> "%logfile%" 2>&1

echo Disabling AutoRun (prevents USB malware)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >> "%logfile%" 2>&1

:: 2. Configure Windows Firewall
echo Setting up Windows Firewall... >> "%logfile%"
echo Enabling Firewall for all profiles...
netsh advfirewall set allprofiles state on >> "%logfile%" 2>&1

echo Blocking risky inbound ports (RDP:3389, SMB:445)...
netsh advfirewall firewall add rule name="Block_RDP_3389" dir=in action=block protocol=TCP localport=3389 >> "%logfile%" 2>&1
netsh advfirewall firewall add rule name="Block_SMB_445" dir=in action=block protocol=TCP localport=445 >> "%logfile%" 2>&1

echo Allowing essential outbound traffic (web browsing)...
netsh advfirewall firewall add rule name="Allow_HTTP_80" dir=out action=allow protocol=TCP remoteport=80 >> "%logfile%" 2>&1
netsh advfirewall firewall add rule name="Allow_HTTPS_443" dir=out action=allow protocol=TCP remoteport=443 >> "%logfile%" 2>&1

:: 3. Check for Suspicious Processes
echo Checking for suspicious processes... >> "%logfile%"
set "suspicious_processes=keylogger.exe logger.exe spy.exe monitor.exe hack.exe"
for %%p in (%suspicious_processes%) do (
    tasklist | findstr /I "%%p" >nul
    if !errorlevel! equ 0 (
        echo WARNING: Found suspicious process: %%p >> "%logfile%"
        echo Terminating %%p...
        taskkill /F /IM "%%p" >> "%logfile%" 2>&1
        echo ALERT: Suspicious process %%p was found and terminated. >> "%logfile%"
    ) else (
        echo No suspicious process %%p found. >> "%logfile%"
    )
)

:: 4. Enable Security Features
echo Enabling security features... >> "%logfile%"
echo Enabling User Account Control (UAC)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1

echo Enabling Windows Defender real-time protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring 0" >> "%logfile%" 2>&1

echo Ensuring Windows Defender is not disabled...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1

:: 5. Clean Up Temporary Files
echo Cleaning temporary files... >> "%logfile%"
del /q /s "%temp%\*" >> "%logfile%" 2>&1
for /d %%d in ("%temp%\*") do rd /s /q "%%d" >> "%logfile%" 2>&1

:: 6. Recommendations for Ongoing Safety
echo. >> "%logfile%"
echo Recommendations for Ongoing Safety: >> "%logfile%"
echo - Keep Windows and all software updated (check Settings > Windows Update). >> "%logfile%"
echo - Use a reputable antivirus (e.g., Windows Defender, Malwarebytes). >> "%logfile%"
echo - Enable automatic updates for Windows Defender. >> "%logfile%"
echo - Use strong, unique passwords and a password manager. >> "%logfile%"
echo - Enable multi-factor authentication (MFA) for online accounts. >> "%logfile%"
echo - Avoid clicking suspicious links or downloading unknown files. >> "%logfile%"
echo - Back up your data regularly to an external drive or cloud. >> "%logfile%"
echo - Use a VPN on public Wi-Fi to encrypt your connection. >> "%logfile%"

:: Display Results
echo.
echo Security setup complete! Log saved to: %logfile%
echo.
echo What was done:
echo - Disabled Remote Desktop, SMBv1, and AutoRun.
echo - Enabled and configured Windows Firewall.
echo - Checked for suspicious processes (see log for details).
echo - Enabled UAC and Windows Defender.
echo - Cleaned temporary files.
echo.
echo To stay safe, please follow these steps:
echo 1. Check for Windows Updates (Settings > Windows Update).
echo 2. Ensure Windows Defender or another antivirus is active.
echo 3. Use strong passwords and enable MFA where possible.
echo 4. Avoid suspicious emails, links, or downloads.
echo 5. Back up your data regularly.
echo 6. Consider a VPN for public Wi-Fi.
echo.
echo For advanced protection, install a third-party antivirus (e.g., Malwarebytes, ESET).
echo.
echo Press any key to exit...
pause >nul

endlocal
exit /b 0