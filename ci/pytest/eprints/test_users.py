import string

import pytest
import random

from playwright.sync_api import expect

from eprints.utils import select_locator, fill_in_register_user, get_full_name, get_random_user_info

'''
More imported and adapted selenium tests
'''


def test_admin_create_destroy_user(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("System Tools").click()
    temp_user = get_random_user_info()
    # temp_user = {
    #     "username": "temporary_user2",
    #     "name_given": "Flibble",
    #     "name_family": "Wibble",
    #     "title": "Dr",
    #     "email": "wibbleflibble@eprints-hosting.org",
    #     "password": ''.join([random.choice(string.ascii_letters) for i in range(10)])
    # }

    logged_in_page.get_by_role("button", name="Create user").click()

    logged_in_page.get_by_role("textbox", name="username").fill(temp_user["username"])

    logged_in_page.get_by_role("button", name="Create User").click()

    expect(logged_in_page.get_by_role("heading", name="Edit")).to_be_visible()

    # select_locator(logged_in_page, "User Type").select_option("User")
    logged_in_page.get_by_role("radio", name="User").click()

    logged_in_page.get_by_role("button", name="Next").first.click()
    fill_in_register_user(logged_in_page, temp_user, include_username=False)
    logged_in_page.get_by_role("button", name="Save and Return").first.click()

    expect(logged_in_page.get_by_text(get_full_name(temp_user)).first).to_be_visible()
    expect(logged_in_page.get_by_text(temp_user["email"]).first).to_be_visible()
    expect(logged_in_page.get_by_text(temp_user["username"]).first).to_be_visible()


    logged_in_page.get_by_role("button", name="Destroy").click()

    expect(logged_in_page.get_by_role("heading", name="Destroy")).to_be_visible()

    logged_in_page.get_by_role("button", name="Cancel").click()

    logged_in_page.get_by_role("button", name="Destroy").click()

    expect(logged_in_page.get_by_text(f"Are you sure you want to destroy {get_full_name(temp_user)}? this action cannot be undone.")).to_be_visible()

    logged_in_page.get_by_role("button", name="Remove").click()

    expect(logged_in_page.get_by_role("heading", name="Manage Users")).to_be_visible()




