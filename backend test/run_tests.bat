@echo off
title InternSafe - Backend API Test Suite Runner
echo ============================================================
echo   InternSafe Backend API Test Suite (300+ Test Cases)
echo   Reads from: input.json
echo   Output   : backend_test_results.xlsx
echo ============================================================
echo.

:: Run from the backend test folder
cd /d "%~dp0"
python backend_test.py

echo.
echo ============================================================
echo   Test suite execution completed!
echo   Check: backend_test_results.xlsx and input_results.xlsx
echo ============================================================
pause
