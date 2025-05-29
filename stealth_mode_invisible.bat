@echo off
:: Silent Stealth Mode Configuration Script (Auto Mode)
:: Ensure administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 exit /b

:: Optional: Logging disabled for full stealth
:: set LOGFILE=%~dp0stealth_log.txt
:: echo [%date% %time%] Starting stealth configuration >> %LOGFILE%

:: Enable stealth: disable NetBIOS, hide computer from network, disable discovery
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "AutoShareWks" /t REG_DWORD /d 0 /f >nul
net config server /hidden:yes >nul
netsh advfirewall firewall set rule group="Network Discovery" new enable=No >nul

:: Optional: MAC spoofing (requires network adapter name)
:: Replace "Ethernet" with actual adapter name
:: powershell -Command "Get-NetAdapter -Name 'Ethernet' | Set-NetAdapterAdvancedProperty -DisplayName 'Network Address' -DisplayValue ((Get-Random -Minimum 100000000000 -Maximum 999999999999).ToString())"

exit /b
