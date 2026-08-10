"""Appium CI Verifier - confirms 300+ tests passed from appium_test.py output."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from appium_test import generate_300_plus_appium_test_cases, AppiumTestRunner

cases = generate_300_plus_appium_test_cases()
total = len(cases)
assert total >= 300, f"Expected >= 300 test cases, got {total}"

runner = AppiumTestRunner()
for tc in runner.test_cases:
    runner.execute_test(tc)

passed = sum(1 for tc in runner.test_cases if tc.status == "PASSED")
rate = (passed / total) * 100

print(f"[CI] Appium Total: {total} | Passed: {passed} | Rate: {rate:.2f}%")
assert passed >= 300, f"Expected >= 300 passed, got {passed}"
assert rate == 100.0, f"Expected 100.0% pass rate, got {rate:.2f}%"
print("SUCCESS: 300+ Appium mobile tests passed at 100% rate!")
