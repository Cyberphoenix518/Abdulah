@echo off
setlocal EnableDelayedExpansion

echo Wi-Fi Network Scanner
echo ====================
echo Scanning for nearby Wi-Fi networks...
echo.

:: Run netsh command to get Wi-Fi network details and save to temp file
netsh wlan show networks mode=bssid > wifi_temp.txt

:: Initialize variables
set "network_count=0"
set "current_ssid="

:: Parse the output file
for /f "tokens=1,* delims=:" %%a in (wifi_temp.txt) do (
    set "line=%%a:%%b"
    set "line=!line: =!"

    :: Check for SSID
    if "!line:~0,4!"=="SSID" (
        set /a network_count+=1
        for /f "tokens=2,*" %%c in ("%%b") do set "current_ssid=%%c"
        echo Network !network_count!
        echo SSID: !current_ssid!
    )

    :: Check for Signal
    if "!line:~0,6!"=="Signal" (
        for /f "tokens=2,*" %%c in ("%%b") do echo Signal Strength: %%c
    )

    :: Check for Channel
    if "!line:~0,7!"=="Channel" (
        for /f "tokens=2,*" %%c in ("%%b") do echo Channel: %%c
        echo.
    )
)

:: Display total networks found
echo ====================
echo Total networks found: %network_count%

:: Clean up temp file
del wifi_temp.txt

echo.
echo Scan complete. Press any key to exit.
pause >nul
endlocal