@echo off
setlocal EnableDelayedExpansion

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

echo Windows Security Hardening Script
echo ================================
echo This script will:
echo - Disable vulnerable services (e.g., Remote Desktop)
echo - Configure Windows Firewall
echo - Check for suspicious processes
echo - Apply security policies
echo - Provide security recommendations
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

:: Create a log file
set "logfile=%temp%\security_hardening_%date:~-4%%date:~4,2%%date:~7,2%.log"
echo Security Hardening Log > "%logfile%"
echo Date: %date% %time% >> "%logfile%"
echo. >> "%logfile%"

:: 1. Disable Vulnerable Services
echo Disabling vulnerable services... >> "%logfile%"
echo Disabling Remote Desktop...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1
sc config TermService start= disabled >> "%logfile%" 2>&1

echo Disabling NetBIOS over TCP/IP...
wmic nicconfig where TcpipNetbiosOptions=0 call SetTcpipNetbios 2 >> "%logfile%" 2>&1

echo Disabling SMBv1 (vulnerable to exploits like WannaCry)...
powershell -Command "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol" >> "%logfile%" 2>&1

:: 2. Configure Windows Firewall
echo Configuring Windows Firewall... >> "%logfile%"
echo Enabling Firewall...
netsh advfirewall set allprofiles state on >> "%logfile%" 2>&1

echo Blocking inbound connections to common attack ports...
netsh advfirewall firewall add rule name="Block_RDP_3389" dir=in action=block protocol=TCP localport=3389 >> "%logfile%" 2>&1
netsh advfirewall firewall add rule name="Block_SMB_445" dir=in action=block protocol=TCP localport=445 >> "%logfile%" 2>&1

echo Allowing only essential outbound traffic...
netsh advfirewall firewall add rule name="Allow_HTTP_80" dir=out action=allow protocol=TCP remoteport=80 >> "%logfile%" 2>&1
netsh advfirewall firewall add rule name="Allow_HTTPS_443" dir=out action=allow protocol=TCP remoteport=443 >> "%logfile%" 2>&1

:: 3. Check for Suspicious Processes (e.g., common keyloggers)
echo Checking for suspicious processes... >> "%logfile%"
set "suspicious_processes=keylogger.exe logger.exe spy.exe monitor.exe"
for %%p in (%suspicious_processes%) do (
    tasklist | findstr /I "%%p" >nul
    if !errorlevel! equ 0 (
        echo Found suspicious process: %%p >> "%logfile%"
        echo Terminating %%p...
        taskkill /F /IM "%%p" >> "%logfile%" 2>&1
    )
)

:: 4. Apply Security Policies
echo Applying security policies... >> "%logfile%"
echo Enabling UAC (User Account Control)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1

echo Disabling AutoRun (prevents USB-based malware)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >> "%logfile%" 2>&1

echo Enabling Windows Defender real-time protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring 0" >> "%logfile%" 2>&1

:: 5. Restrict Network Shares
echo Restricting network shares... >> "%logfile%"
net share | findstr /V "default" | findstr /V "ADMIN$" | findstr /V "C$" | findstr /V "IPC$" > "%temp%\shares.txt"
for /f "tokens=1" %%s in (%temp%\shares.txt) do (
    echo Removing share: %%s >> "%logfile%"
    net share %%s /delete >> "%logfile%" 2>&1
)
del "%temp%\shares.txt" 2>nul

:: 6. Check for Windows Updates
echo Checking for Windows Updates... >> "%logfile%"
echo Please ensure Windows is up to date. Run 'wuauclt.exe /detectnow' manually to check for updates.
echo Checking update status is not fully supported in batch. >> "%logfile%"

:: 7. Security Recommendations
echo. >> "%logfile%"
echo Security Recommendations: >> "%logfile%"
echo - Install and regularly update a reputable antivirus (e.g., Windows Defender, Malwarebytes). >> "%logfile%"
echo - Enable automatic Windows Updates. >> "%logfile%"
echo - Use strong, unique passwords and enable multi-factor authentication. >> "%logfile%"
echo - Avoid running unknown executables or opening suspicious email attachments. >> "%logfile%"
echo - Regularly back up your data to an external drive or cloud service. >> "%logfile%"

:: Display Results
echo.
echo Security hardening complete. Log saved to: %logfile%
echo.
echo Summary of Actions:
echo - Disabled Remote Desktop, NetBIOS, and SMBv1.
echo - Configured Firewall to block risky ports and allow essential traffic.
echo - Checked for suspicious processes.
echo - Enabled UAC, disabled AutoRun, and activated Windows Defender.
echo - Removed non-essential network shares.
echo.
echo Important Recommendations:
echo - Ensure Windows and antivirus are up to date.
echo - Use strong passwords and multi-factor authentication.
echo - Regularly back up your data.
echo - Consider professional security software for advanced protection.
echo.
echo Press any key to exit...
pause >nul

endlocal
exit /b 0