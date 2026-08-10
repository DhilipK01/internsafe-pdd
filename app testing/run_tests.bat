@echo off
title InternSafe - Selenium E2E Test Runner (300+ Test Cases)
echo =======================================================================
echo          INTERNSAFE WEB APPLICATION - SELENIUM E2E TEST RUNNER        
echo =======================================================================
echo.
echo Running 320 End-to-End Test Cases...
echo Results will be automatically saved to test_results.xlsx in this folder.
echo.

python "%~dp0selnium_E2E.py" %*

echo.
echo =======================================================================
echo Execution finished. Check test_results.xlsx in this folder.
echo =======================================================================
pause
