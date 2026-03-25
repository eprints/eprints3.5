import json
from datetime import datetime

import pytest
from random_eprints.random_eprints import get_random_eprint
from playwright.sync_api import Page

def pytest_addoption(parser):
    parser.addoption("--url", action="store")

@pytest.fixture
def random_pdf():
    eprint = get_random_eprint()
    return eprint.pdf

@pytest.fixture
def random_pdf_bytes(random_pdf):
    return random_pdf.output()

@pytest.fixture(scope="session")
def base_url(pytestconfig):
    return pytestconfig.getoption('url')

@pytest.fixture
def logged_in_page(base_url, page: Page):
    page.goto(f"{base_url}/cgi/users/login")
    with open("credentials.json") as credentials_file:
        credentials = json.load(credentials_file)
    page.get_by_role("textbox", name="Username:").fill(credentials["test_user"]["name"])
    page.get_by_role("textbox", name="Password:").fill(credentials["test_user"]["password"])
    page.get_by_role("button", name="Login").click()

    return page

@pytest.fixture
def random_title():
    return f"Title {datetime.now()}"