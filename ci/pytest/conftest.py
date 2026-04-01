import pytest

def pytest_addoption(parser):
    parser.addoption("--url", action="store", default="blankurl")
    parser.addoption("--creds", action="store", default="credentials.json")
    parser.addoption("--seed", action="store", default="0")
    # --headed appears to be added by playwright
