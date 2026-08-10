@echo off
title InternSafe - Frontend UI Test Suite Runner
echo ============================================================
echo   InternSafe Frontend UI Test Suite (300+ Test Cases)
echo   Reads from: input.json
echo   Output   : frontend_test_results.xlsx
echo ============================================================
echo.
cd /d "%~dp0"
python frontend_test.py
echo.
echo ============================================================
echo   Done! Check: frontend_test_results.xlsx
echo ============================================================
pause
