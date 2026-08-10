"""
InternSafe - Master Test Runner
================================
Runs all 3 test suites SEPARATELY with clear section headers.

Usage:
    python run_all_tests.py                  # Run all 3 suites
    python run_all_tests.py --suite selenium # Run only Selenium
    python run_all_tests.py --suite appium   # Run only Appium
    python run_all_tests.py --suite backend  # Run only Backend
    python run_all_tests.py --suite frontend # Run only Frontend
"""

import sys
import os
import time
import argparse
import subprocess

ROOT = os.path.dirname(os.path.abspath(__file__))

# ── Colour helpers ──────────────────────────────────────────────────────────
G  = "\033[92m"   # Green
R  = "\033[91m"   # Red
Y  = "\033[93m"   # Yellow
B  = "\033[1m"    # Bold
C  = "\033[96m"   # Cyan
M  = "\033[95m"   # Magenta
E  = "\033[0m"    # Reset

SUITES = {
    "selenium": {
        "label": "Selenium E2E Tests",
        "script": os.path.join(ROOT, "app testing", "selenium_e2e.py"),
        "args":   ["--output", "test_results.xlsx"],
        "cwd":    os.path.join(ROOT, "app testing"),
        "emoji":  "🌐",
    },
    "appium": {
        "label": "Appium Mobile E2E Tests",
        "script": os.path.join(ROOT, "app testing", "appium_test.py"),
        "args":   ["--output", "appium_test_results.xlsx"],
        "cwd":    os.path.join(ROOT, "app testing"),
        "emoji":  "📱",
    },
    "backend": {
        "label": "Backend API Tests",
        "script": os.path.join(ROOT, "backend test", "backend_test.py"),
        "args":   ["--output", "backend_test_results.xlsx"],
        "cwd":    os.path.join(ROOT, "backend test"),
        "emoji":  "⚙️ ",
    },
    "frontend": {
        "label": "Frontend UI Tests",
        "script": os.path.join(ROOT, "frontend test", "frontend_test.py"),
        "args":   ["--output", "frontend_test_results.xlsx"],
        "cwd":    os.path.join(ROOT, "frontend test"),
        "emoji":  "🖥️ ",
    },
}


def banner(title: str, char: str = "=", width: int = 80):
    print("\n" + char * width)
    print(f"{B}{M}  {title}{E}")
    print(char * width)


def run_suite(key: str) -> dict:
    """Run one test suite as a subprocess and return result info."""
    suite   = SUITES[key]
    label   = suite["label"]
    emoji   = suite["emoji"]
    script  = suite["script"]
    cwd     = suite["cwd"]
    args    = suite["args"]

    banner(f"{emoji}  {label}")

    if not os.path.exists(script):
        print(f"{R}[SKIP] Script not found: {script}{E}")
        return {"suite": label, "status": "SKIPPED", "duration": 0}

    cmd   = [sys.executable, script] + args
    start = time.time()

    result = subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        capture_output=False,   # stream stdout live to terminal
    )

    duration = time.time() - start
    success  = result.returncode == 0

    status_str = f"{G}PASSED{E}" if success else f"{R}FAILED{E}"
    print(f"\n{B}► {label} → {status_str}  ({duration:.1f}s){E}")

    return {
        "suite":    label,
        "status":   "PASSED" if success else "FAILED",
        "duration": duration,
        "rc":       result.returncode,
    }


def print_final_summary(results: list):
    banner("MASTER TEST RUNNER — FINAL SUMMARY", char="═")
    total   = len(results)
    passed  = sum(1 for r in results if r["status"] == "PASSED")
    failed  = sum(1 for r in results if r["status"] == "FAILED")
    skipped = sum(1 for r in results if r["status"] == "SKIPPED")

    print(f"\n  {'Suite':<35} {'Status':<10} {'Duration':>10}")
    print(f"  {'─'*35} {'─'*10} {'─'*10}")
    for r in results:
        icon = "✅" if r["status"] == "PASSED" else ("⚠️ " if r["status"] == "SKIPPED" else "❌")
        col  = G if r["status"] == "PASSED" else (Y if r["status"] == "SKIPPED" else R)
        print(f"  {r['suite']:<35} {col}{r['status']:<10}{E} {r['duration']:>8.1f}s  {icon}")

    total_time = sum(r["duration"] for r in results)
    print(f"\n  Suites Run : {total}")
    print(f"  {G}Passed     : {passed}{E}")
    print(f"  {(R if failed else G)}Failed     : {failed}{E}")
    if skipped:
        print(f"  {Y}Skipped    : {skipped}{E}")
    print(f"  Total Time : {total_time:.1f}s")
    print("═" * 80 + "\n")

    if failed > 0:
        print(f"{R}{B}[RESULT] ❌  {failed} suite(s) FAILED. Fix errors above and re-run.{E}\n")
        sys.exit(1)
    else:
        print(f"{G}{B}[RESULT] ✅  All {passed} suite(s) PASSED successfully!{E}\n")
        sys.exit(0)


def main():
    parser = argparse.ArgumentParser(
        description="InternSafe Master Test Runner — runs all 3 test suites separately."
    )
    parser.add_argument(
        "--suite",
        choices=list(SUITES.keys()) + ["all"],
        default="all",
        help="Which suite to run (default: all)",
    )
    args = parser.parse_args()

    suites_to_run = list(SUITES.keys()) if args.suite == "all" else [args.suite]

    print(f"\n{B}{C}{'='*80}{E}")
    print(f"{B}{C}   INTERNSAFE MASTER TEST RUNNER — {len(suites_to_run)} suite(s) queued{E}")
    print(f"{B}{C}{'='*80}{E}")

    results = []
    for key in suites_to_run:
        results.append(run_suite(key))

    print_final_summary(results)


if __name__ == "__main__":
    main()
