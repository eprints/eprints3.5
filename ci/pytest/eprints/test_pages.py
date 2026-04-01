from playwright.sync_api import Page, expect
import re
import pytest

@pytest.mark.parametrize("link_name,expected_texts", [
    ("About", ["About the Repository"]),
    ("Login", ["Please enter your username and password."]),
    ("Browse", ["BROWSE ITEMS"]),
    ("See our Policies", ["Repository Policies"]),
    ("About EPrints", ["School of Electronics and Computer Science"]),
    ("Accessibility", ["Accessibility statement"]),
    ("Browse", ["Subject", "Division", "Year", "Author"])
])
def test_go_to_simple_page(not_logged_in_page, link_name, expected_texts):
    not_logged_in_page.get_by_text(link_name).first.click()
    for expected_text in expected_texts:
        expect(not_logged_in_page.get_by_text(expected_text, exact=False).first).to_be_visible()