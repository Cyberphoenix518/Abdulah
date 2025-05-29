@echo off
setlocal EnableDelayedExpansion

echo WiFi and Device Scanner
echo Note: Run as Administrator for best results.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo This script requires administrative privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

:: Get available WiFi networks
echo Scanning WiFi networks...
echo Available WiFi Networks:
echo ------------------------
netsh wlan show networks mode=bssid | findstr "SSID BSSID" > temp_wifi.txt
for /f "tokens=1-4" %%a in (temp_wifi.txt) do (
    if "%%a"=="SSID" (
        echo SSID: %%c
    ) else if "%%a"=="BSSID" (
        echo   BSSID: %%b
    )
)
del temp_wifi.txt
echo.

:: Get connected WiFi network
echo Checking connected WiFi network...
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces ^| findstr "SSID" ^| findstr /v "BSSID"') do (
    set "connected_ssid=%%a"
    set "connected_ssid=!connected_ssid:~1!"
)
if defined connected_ssid (
    echo Connected to: !connected_ssid!
) else (
    echo Not connected to any WiFi network.
    pause
    exit /b 1
)
echo.

:: Get network info (IP range)
echo Determining network information...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "Default Gateway"') do (
    set "gateway=%%a"
    set "gateway=!gateway:~1!"
)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4 Address"') do (
    set "ip=%%a"
    set "ip=!ip:~1!"
)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "Subnet Mask"') do (
    set "subnet=%%a"
    set "subnet=!subnet:~1!"
)
if not defined gateway (
    echo Could not determine network information.
    pause
    exit /b 1
)
echo Local IP: !ip!
echo Subnet Mask: !subnet!
echo Default Gateway: !gateway!
echo.

:: Scan devices using ARP cache
echo Scanning devices on the network...
:: Ping the broadcast address to populate ARP table (basic approach)
for /f "tokens=1-3 delims=." %%a in ("!gateway!") do (
    set "network=%%a.%%b.%%c"
)
ping -n 1 !network!.255 >nul
echo Devices on the Network:
echo ------------------------
arp -a | findstr /v "Interface" | findstr /v "Internet" > temp_arp.txt
for /f "tokens=1,2" %%a in (temp_arp.txt) do (
    echo IP: %%a, MAC: %%b
)
del temp_arp.txt
echo.

echo Scan complete.
pause
exit /b 0