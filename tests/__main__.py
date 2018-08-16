import sys
import pytest

sys.exit(pytest.main(["-v", "--vhost", sys.argv[2:], "tests"]))

