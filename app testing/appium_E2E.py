import os
import sys

# Add script directory to sys.path to ensure module imports work smoothly
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from appium_test import main

if __name__ == "__main__":
    main()
