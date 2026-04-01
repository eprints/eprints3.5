from playwright.sync_api import Page, expect
import re
import pytest

from eprints.utils import login


@pytest.mark.parametrize("link_name,expected_texts", [
    ("About", ["About the Repository"]),
    ("Login", ["Please enter your username and password."]),
    ("Browse", ["BROWSE ITEMS"]),
    ("See our Policies", ["Repository Policies"]),
    ("About EPrints", ["School of Electronics and Computer Science"]),
    ("Accessibility", ["Accessibility statement"]),
    ("Browse", ["Subject", "Division", "Year", "Author"]),
    ("Create Account", ["Email address", "Username", "Password"])
])
def test_go_to_simple_page(not_logged_in_page, link_name, expected_texts):
    not_logged_in_page.get_by_text(link_name).first.click()
    for expected_text in expected_texts:
        expect(not_logged_in_page.get_by_text(expected_text, exact=False).first).to_be_visible()


def test_create_account(not_logged_in_page, temp_user_info):
    not_logged_in_page.get_by_text("Create Account").first.click()

    def fill_in_register_user():

        # not_logged_in_page.get_by_role("textbox", name="Title").fill(temp_user_info["title"])
        # not_logged_in_page.get_by_role("textbox", name="Given Name / Initials").fill(temp_user_info["name_given"])
        # not_logged_in_page.get_by_role("textbox", name="Family Name").fill(temp_user_info["name_family"])
        not_logged_in_page.get_by_label("Title").fill(temp_user_info["title"])
        not_logged_in_page.get_by_label("Given Name / Initials").fill(temp_user_info["name_given"])
        not_logged_in_page.get_by_label("Family Name").fill(temp_user_info["name_family"])
        not_logged_in_page.get_by_role("textbox", name="Email address").fill(temp_user_info["email"])
        not_logged_in_page.get_by_role("textbox", name="Username").fill(temp_user_info["username"])
        not_logged_in_page.get_by_role("textbox", name="password").fill(temp_user_info["password"])
        not_logged_in_page.get_by_role("button", name="Register").click()

    fill_in_register_user()
    expect(not_logged_in_page.get_by_text(f"You have registered with username {temp_user_info['username']}.",
                                          exact=False)).to_be_visible()

    not_logged_in_page.get_by_text("Create Account").first.click()

    fill_in_register_user()
    expect(not_logged_in_page.get_by_text(f"A user with the email address {temp_user_info['email']} already exists.", exact=False)).to_be_visible()

    # login(not_logged_in_page, temp_user_info["username"], temp_user_info["password"])