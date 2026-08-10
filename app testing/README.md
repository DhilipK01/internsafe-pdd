# InternSafe - Selenium E2E Web Testing Suite (300+ Test Cases)

This directory contains the complete End-to-End (E2E) automated Selenium test suite for the **InternSafe** web application. It includes **320 test cases** covering all functional modules, UI screens, APIs, security edge cases, and performance metrics.

---

## 📁 Folder Structure

```
app testing/
├── selnium_E2E.py          # Main executable script (exact name matching user request)
├── selenium_e2e.py         # Core test engine & 320 test cases catalog
├── run_tests.bat           # One-click Windows command prompt launcher
├── test_results.xlsx       # Formatted Excel test report (Auto-generated after execution)
├── selnium_E2E_results.xlsx# Alternate named copy of the Excel report
└── README.md               # Documentation guide
```

---

## 🚀 How to Run in Command Prompt

### Option 1: Using the Batch Launcher (Easiest)

Simply open Command Prompt (`cmd.exe`) in this folder and run:
```cmd
.\run_tests.bat
```

### Option 2: Using Python Directly

```cmd
python selnium_E2E.py
```
or
```cmd
python selenium_e2e.py
```

---

## ⚙️ Command Line Options & Flags

| Flag | Default | Description | Example |
|------|---------|-------------|---------|
| `--url` | `http://localhost:8080` | Target URL of web application | `python selnium_E2E.py --url https://internsafe.dev` |
| `--browser` | `chrome` | Browser engine (`chrome`, `edge`, `firefox`, `mock`) | `python selnium_E2E.py --browser edge` |
| `--no-headless` | `False` | Run browser with visible GUI | `python selnium_E2E.py --no-headless` |
| `--category` | `None` | Filter tests by specific category | `python selnium_E2E.py --category Auth` |
| `--output` | `test_results.xlsx` | Custom Excel report filename | `python selnium_E2E.py --output final_report.xlsx` |

---

## 📊 Test Case Categories Breakdown (320 Total Tests)

| # | Category | Test Count | Description |
|---|----------|------------|-------------|
| 1 | **Authentication & User Management** | 35 | Login, Register, Password Recovery, JWT, Google OAuth, Sessions |
| 2 | **Scam Offer Letter Detector** | 40 | File/Text upload, AI Risk Gauge, Red Flags, Format & Size rules |
| 3 | **Company Verification & Domain Scanner** | 40 | GSTIN/CIN search, Trust Score, WHOIS, SSL, Domain Age, Red flags |
| 4 | **Blacklist Registry & Scammer Reporting** | 35 | Scammer search, Multi-step reporting, Community votes, CSV export |
| 5 | **Resume Safety & Privacy Scanner** | 30 | ATS score, Sensitive PII leaks, Hyperlink security, Redaction |
| 6 | **Scan History & Report Management** | 30 | Filter/search scans, Export logs, Batch delete, Cloud sync |
| 7 | **Shared Reports & Public Pages** | 25 | Public URL rendering, PII hiding, Social share, PIN protection |
| 8 | **Dashboard UI & Responsiveness** | 30 | Nav header, Theme switcher, KPI cards, Mobile/Tablet viewports |
| 9 | **Security, Validation & Edge Cases** | 30 | XSS, SQLi, Security Headers, File corruption, 404/500 screens |
| 10| **API Integration & Performance** | 25 | Health endpoints, Latency benchmark, Web Vitals, Memory leak check |
| **TOTAL** | | **320 Tests** | **Comprehensive Full-App Coverage** |

---

## 📄 Excel Report Features (`test_results.xlsx`)

The test suite automatically generates a multi-tab Excel spreadsheet formatted with:
1. **Executive Summary Tab**:
   - KPI Summary Cards (Total Tests, Passed, Failed, Skipped, Pass Rate %, Execution Time).
   - Category Breakdown Table with pass rate highlights.
2. **Test Details Tab**:
   - Complete execution log of all 320 test cases.
   - Status color formatting (Green = PASS, Red = FAIL, Yellow = SKIP).
   - Exact execution duration and assertion details.
3. **Test Suite Catalog Tab**:
   - Detailed specification of pre-conditions, test steps, and expected results for every test case.
