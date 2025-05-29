@echo off
setlocal EnableDelayedExpansion
title H4X-HOTSPOT-MONITOR v1.0
color 0a
cls

:: Hacker-style ASCII art header
echo.
echo   ==============================
echo      H4X-HOTSPOT-MONITOR v1.0
echo   ==============================
echo      Cyber-Net Device Scanner
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

:: Set log directory and file
set SCAN_DIR=%~dp0H4X_Hotspot_Scan
set LOG_FILE=%SCAN_DIR%\Hotspot_Device_Log.txt
set TEMP_FILE=%SCAN_DIR%\temp_scan.txt

:: Create scan directory if it doesn't exist
if not exist "!SCAN_DIR!" (
    mkdir "!SCAN_DIR!"
    echo [H4X-NET] Created scan vault: !SCAN_DIR!
)

:: Initialize log file
if not exist "!LOG_FILE!" (
    echo Hotspot Device Scan Log - %DATE% %TIME% > "!LOG_FILE!"
    echo. >> "!LOG_FILE!"
    echo Scanned Devices: >> "!LOG_FILE!"
    echo ------------------------- >> "!LOG_FILE!"
)

:: Check if hosted network is running
netsh wlan show hostednetwork | findstr "Status" | findstr "Started" >nul
if %errorlevel% neq 0 (
    echo [ERROR] No active hotspot detected.
    echo [H4X-NET] Start your hotspot using: netsh wlan start hostednetwork
    echo No active hotspot detected at %DATE% %TIME%. >> "!LOG_FILE!"
    pause
    exit /b
)

:: Main monitoring loop
:monitor
cls
echo [H4X-NET] Monitoring hotspot devices... Press Ctrl+C to exit.
echo.

:: Get connected devices (MAC addresses)
netsh wlan show hostednetwork | findstr "MAC" > "!TEMP_FILE!"
if not exist "!TEMP_FILE!" (
    echo [H4X-NET] No devices connected to hotspot.
    echo No devices connected at %DATE% %TIME%. >> "!LOG_FILE!"
    timeout /t 5 >nul
    goto monitor
)

:: Get ARP table for IP and MAC mapping
arp -a > arp_table.txt

:: Process each connected device
for /f "tokens=3" %%m in (!TEMP_FILE!) do (
    set MAC=%%m
    echo [H4X-NET] Device Detected - MAC: !MAC!
    echo Device Detected at %DATE% %TIME% >> "!LOG_FILE!"
    echo MAC Address: !MAC! >> "!LOG_FILE!"
    
    :: Find IP address from ARP table
    set IP=
    for /f "tokens=1,2" %%i in (arp_table.txt) do (
        set ARP_IP=%%i
        set ARP_MAC=%%j
        :: Normalize MAC format (replace - with :)
        set ARP_MAC=!ARP_MAC:-=:!
        if /i "!ARP_MAC!"=="!MAC!" (
            set IP=!ARP_IP!
            echo [H4X-NET] IP Address: !IP!
            echo IP Address: !IP! >> "!LOG_FILE!"
        )
    )
    
    :: Get hostname (if available)
    if defined IP (
        nbtstat -A !IP! | findstr "Name" > temp_nbt.txt
        set HOSTNAME=[Not Available]
        if exist temp_nbt.txt (
            for /f "tokens=1" %%n in (temp_nbt.txt) do (
                set HOSTNAME=%%n
                echo [H4X-NET] Hostname: !HOSTNAME!
                echo Hostname: !HOSTNAME! >> "!LOG_FILE!"
                goto :break_nbt
            )
            :break_nbt
        ) else (
            echo [H4X-NET] Hostname: !HOSTNAME!
            echo Hostname: !HOSTNAME! >> "!LOG_FILE!"
        )
        del temp_nbt.txt 2>nul
        
        :: Basic port scan using PowerShell
        echo [H4X-NET] Scanning for open ports...
        powershell -Command "Test-NetConnection -ComputerName !IP! -Port 80,443,445,3389 | Select-Object ComputerName,TcpTestSucceeded,RemotePort | Where-Object { $_.TcpTestSucceeded -eq $true } | Format-Table -AutoSize | Out-File -Encoding ASCII temp_ports.txt"
        set PORTS=[None Detected]
        if exist temp_ports.txt (
            findstr "True" temp_ports.txt >nul
            if !errorlevel! equ 0 (
                set PORTS=
                for /f "tokens=3" %%p in (temp_ports.txt) do (
                    set PORTS=!PORTS!%%p,
                )
                set PORTS=!PORTS:~0,-1!
                echo [H4X-NET] Open Ports: !PORTS!
                echo Open Ports: !PORTS! >> "!LOG_FILE!"
            ) else (
                echo [H4X-NET] Open Ports: !PORTS!
                echo Open Ports: !PORTS! >> "!LOG_FILE!"
            )
        )
        del temp_ports.txt 2>nul
    ) else (
        echo [H4X-NET] IP Address: [Not Found]
        echo IP Address: [Not Found] >> "!LOG_FILE!"
        echo [H4X-NET] Hostname: [Not Available]
        echo Hostname: [Not Available] >> "!LOG_FILE!"
        echo [H4X-NET] Open Ports: [Not Scanned]
        echo Open Ports: [Not Scanned] >> "!LOG_FILE!"
    )
    
    :: Vulnerability notes
    echo [H4X-NET] Vulnerability Notes:
    echo [H4X-NET] - MAC may reveal device vendor (check OUI database).
    echo [H4X-NET] - Open ports (e.g., 445, 3389) may indicate exploitable services.
    echo Vulnerability Notes: >> "!LOG_FILE!"
    echo - MAC may reveal device vendor (check OUI database). >> "!LOG_FILE!"
    echo - Open ports (e.g., 445, 3389) may indicate exploitable services. >> "!LOG_FILE!"
    echo ------------------------- >> "!LOG_FILE!"
)

:: Cleanup
del arp_table.txt "!TEMP_FILE!" 2>nul

:: Wait before next scan
timeout /t 5 >nul
goto monitor