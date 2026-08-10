"""
InternSafe Frontend CI Verifier
Runs the frontend test suite and asserts 300+ cases pass at 100% rate.
Used by GitHub Actions to gate the CI pipeline.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from frontend_test import FrontendRunner

runner = FrontendRunner(
    url="http://localhost:3000",
    input_file="input.json",
    output="frontend_test_results.xlsx"
)

total = len(runner.tests)
assert total >= 300, f"[CI] FAIL: Expected >= 300 frontend test cases in input.json, got {total}"

for tc in runner.tests:
    runner._run(tc)

passed  = sum(1 for tc in runner.tests if tc.status == "PASSED")
failed  = sum(1 for tc in runner.tests if tc.status == "FAILED")
rate    = (passed / total) * 100

print(f"\n[CI] Frontend Results => Total: {total} | Passed: {passed} | Failed: {failed} | Rate: {rate:.2f}%")

assert passed >= 300, f"[CI] FAIL: Expected >= 300 passed, got {passed}"
assert failed == 0,   f"[CI] FAIL: Expected 0 failures, got {failed}"
print("[CI] SUCCESS: 300+ frontend UI tests passed at 100% pass rate!")
sys.exit(0)
