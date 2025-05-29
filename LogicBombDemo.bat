@echo off
setlocal enabledelayedexpansion

:: Configuration
set filePath=C:\Users\%USERNAME%\Desktop\config.txt
set logPath=C:\Users\%USERNAME%\Desktop\logic_bomb_log.txt

:: Main script
echo Running Batch logic bomb demo...

:: Check trigger conditions
call :TestLogicBombTriggers
if !trigger!==1 (
    echo Trigger conditions met! Executing logic bomb payload...
    call :InvokeLogicBombPayload
) else (
    echo Trigger conditions not met. Logic bomb remains dormant.
)

exit /b

:TestLogicBombTriggers
set trigger=0
:: Trigger 1: File-based (activates if config.txt is missing)
if not exist "%filePath%" set trigger=1
:: Trigger 2: Input-based (activates if user enters 'detonate')
set /p userInput=Enter command (type 'detonate' to trigger manually, or anything else to check other triggers):
if /i "!userInput!"=="detonate" set trigger=1
goto :eof

:InvokeLogicBombPayload
echo Logic Bomb Activated! This is a demo - no harm done. > "%logPath%"
echo Activated on: %DATE% %TIME% >> "%logPath%"
echo Logic bomb triggered! Check 'logic_bomb_log.txt' on your Desktop.
goto :eof