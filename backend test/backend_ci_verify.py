"""
InternSafe Backend CI Verifier
Runs the backend test suite and asserts 300+ cases pass at 100% rate.
Used by GitHub Actions to gate the CI pipeline.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from backend_test import BackendTestRunner

runner = BackendTestRunner(
    target_url="http://localhost:8080",
    input_file="input.json",
    excel_output="backend_test_results.xlsx"
)

total = len(runner.test_cases)
assert total >= 300, f"[CI] FAIL: Expected >= 300 backend test cases in input.json, got {total}"

for tc in runner.test_cases:
    runner.execute_test(tc)

passed  = sum(1 for tc in runner.test_cases if tc.status == "PASSED")
failed  = sum(1 for tc in runner.test_cases if tc.status == "FAILED")
rate    = (passed / total) * 100

print(f"\n[CI] Backend Results => Total: {total} | Passed: {passed} | Failed: {failed} | Rate: {rate:.2f}%")

assert passed >= 300, f"[CI] FAIL: Expected >= 300 passed, got {passed}"
assert failed == 0,   f"[CI] FAIL: Expected 0 failures, got {failed}"
print("[CI] SUCCESS: 300+ backend API tests passed at 100% pass rate!")
sys.exit(0)
