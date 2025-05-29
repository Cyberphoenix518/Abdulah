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

echo Undo Windows Security Hardening Script
echo =====================================
echo This script will REVERSE the security measures applied by keep_device_safe.bat.
echo WARNING: This will make your system MORE VULNERABLE to attacks.
echo Actions to be undone:
echo - Re-enable Remote Desktop, SMBv1, and AutoRun.
echo - Remove custom firewall rules (Firewall may remain enabled).
echo - Disable UAC and Windows Defender real-time protection (HIGH RISK).
echo - Note: Cannot restore terminated processes or deleted temporary files.
echo.
echo BACKUP your system before proceeding.
echo Press any key to start or Ctrl+C to cancel...
pause >nul

:: Create a log file
set "logfile=%temp%\undo_security_%date:~-4%%date:~4,2%%date:~7,2%.log"
echo Undo Security Hardening Log > "%logfile%"
echo Date: %date% %time% >> "%logfile%"
echo. >> "%logfile%"

:: 1. Re-enable Risky Features
echo Re-enabling features... >> "%logfile%"
echo Re-enabling Remote Desktop (port 3389 will be open)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1
sc config TermService start= auto >> "%logfile%" 2>&1
net start TermService >> "%logfile%" 2>&1

echo Re-enabling SMBv1 (WARNING: Vulnerable to exploits like WannaCry)...
powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol" >> "%logfile%" 2>&1

echo Re-enabling AutoRun (may allow USB-based malware)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 145 /f >> "%logfile%" 2>&1

:: 2. Revert Windows Firewall Changes
echo Reverting Windows Firewall changes... >> "%logfile%"
echo Removing custom firewall rules...
netsh advfirewall firewall delete rule name="Block_RDP_3389" >> "%logfile%" 2>&1
netsh advfirewall firewall delete rule name="Block_SMB_445" >> "%logfile%" 2>&1
netsh advfirewall firewall delete rule name="Allow_HTTP_80" >> "%logfile%" 2>&1
netsh advfirewall firewall delete rule name="Allow_HTTPS_443" >> "%logfile%" 2>&1

echo WARNING: Firewall is still enabled for safety. To disable it, run manually:
echo netsh advfirewall set allprofiles state off
echo Note: Disabling the firewall is NOT recommended. >> "%logfile%"

:: 3. Note on Suspicious Processes
echo. >> "%logfile%"
echo Cannot reverse process termination... >> "%logfile%"
echo The original script terminated suspicious processes (e.g., keylogger.exe).
echo These cannot be restored. Check the original log for details. >> "%logfile%"

:: 4. Revert Security Features
echo Reverting security features... >> "%logfile%"
echo Disabling User Account Control (UAC) (WARNING: Reduces security)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1

echo Disabling Windows Defender real-time protection (WARNING: HIGH RISK)...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring 1" >> "%logfile%" 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1

:: 5. Note on Temporary Files
echo. >> "%logfile%"
echo Cannot restore temporary files... >> "%logfile%"
echo The original script deleted files in %temp%. These cannot be recovered. >> "%logfile%"

:: 6. Warnings and Recommendations
echo. >> "%logfile%"
echo IMPORTANT WARNINGS: >> "%logfile%"
echo - Re-enabling SMBv1, Remote Desktop, and AutoRun increases your risk of malware and unauthorized access. >> "%logfile%"
echo - Disabling UAC and Windows Defender significantly weakens your system. >> "%logfile%"
echo - Consider re-running keep_device_safe.bat or installing antivirus software. >> "%logfile%"
echo Recommendations: >> "%logfile%"
echo - Keep Windows and software updated. >> "%logfile%"
echo - Use a reputable antivirus (e.g., Windows Defender, Malwarebytes). >> "%logfile%"
echo - Enable multi-factor authentication for online accounts. >> "%logfile%"
echo - Avoid suspicious downloads or links. >> "%logfile%"
echo - Back up your data regularly. >> "%logfile%"

:: Display Results
echo.
echo Reversal complete! Log saved to: %logfile%
echo.
echo What was done:
echo - Re-enabled Remote Desktop, SMBv1, and AutoRun.
echo - Removed custom firewall rules (Firewall remains enabled for safety).
echo - Disabled UAC and Windows Defender (HIGH RISK).
echo - Noted: Cannot restore terminated processes or deleted temporary files.
echo.
echo WARNING: Your system is now MORE VULNERABLE.
echo To stay safe:
echo 1. Reconsider using Remote Desktop, SMBv1, or disabling Defender.
echo 2. Install and update antivirus software.
echo 3. Keep Windows updated (Settings > Windows Update).
echo 4. Use strong passwords and multi-factor authentication.
echo 5. Back up your data regularly.
echo.
echo Press any key to exit...
pause >nul

endlocal
exit /b 0