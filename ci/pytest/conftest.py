import pytest

def pytest_addoption(parser):
    parser.addoption("--url", action="store", default="blankurl")
    parser.addoption("--creds", action="store", default="credentials.json")
