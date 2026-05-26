import pytest

def pytest_addoption(parser):
    parser.addoption("--url", action="store", default="blankurl")
    parser.addoption("--creds", action="store", default="credentials.json")
    parser.addoption("--seed", action="store", default="0")
    # --headed appears to be added by playwright

@pytest.fixture
def scope():
    #TODO - system to reduce scope of tests so we cna have longer and quicker tests
    return "full"