import time

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

# do this even more first
@pytest.mark.order(1)
def test_empty_indexer_queue(page: Page, base_url):
    start = time.time()
    event_queue = -1
    #try for 120 seconds to wait for the event queue to finish
    while(event_queue != 0 and time.time() - start < 300):
        page.goto(f"{base_url}/cgi/counter").finished()
        text = page.content()
        lines = text.split("\n")
        for line in lines:
            if line.startswith("event_queue:"):
                event_queue = int(line.split(":")[1])
        time.sleep(10)

    if event_queue != 0:
        raise RuntimeError(f"Event queue still not finished. {event_queue} tasks remaining")




#do this first as it expects nothing but the precanned test data to be present
@pytest.mark.order(2)
def test_simple_search(not_logged_in_page):
    not_logged_in_page.get_by_placeholder("Search Journal articles, titles, dates, authors…").fill("article")
    not_logged_in_page.get_by_role("button", name="Search").click()

    expect(not_logged_in_page.get_by_text("100 results", exact=True).first).to_be_visible()

    expect(not_logged_in_page.get_by_role("link", name="Refine search").first).to_be_visible()
    expect(not_logged_in_page.get_by_role("link", name="New search").first).to_be_visible()
    expect(not_logged_in_page.get_by_label("Order the results", exact=False).first).to_be_visible()
    not_logged_in_page.get_by_text("Export options").click()
    expect(not_logged_in_page.get_by_text("Export 100 results as", exact=False)).to_be_visible()
    for link_text in ["Atom", "RSS 1.0", "RSS 2.0", "Conference or Workshop Item", "Show 5 more"]:
        expect(not_logged_in_page.get_by_role("link", name=link_text, exact=False)).to_be_visible()


    def check_filter_result_count(filter_name, expected_count):
        # get the next element along from the text
        results = not_logged_in_page.get_by_role("link", name=filter_name).locator(
            'xpath=/following-sibling::*', has_text=f"{expected_count}")
        expect(results).to_be_visible()


    filters = [("Fenderson Press", 14),
               ("Conference or Workshop Item", 50),
               ("Smith and Sons", 14),
               ("Husbandry Times", 8),
               ("2018", 17)
               ]
    for filter in filters:
        #get the next element along from the text and check there are the expected number of results
        check_filter_result_count(*filter)

    not_logged_in_page.get_by_role("link", name="Show 5 more...").click()
    check_filter_result_count("International Journal of Evolutionary Ideas", 2)


    # TODO create issue to fix this. It appears the buttons are visible and (to playwright) stable before the javascript onclick handler has been attached.
    # therefore a crude sleep after page load is enough for clicking the filters to trigger the js (which reloads the page and requires another sleep)
    time.sleep(1)
    not_logged_in_page.get_by_role("checkbox", name="2018").click()
    html = not_logged_in_page.get_by_role("checkbox", name="2020").inner_html()
    print(f"button html:{html}")
    time.sleep(1)
    not_logged_in_page.get_by_role("checkbox", name="2020").click()

    expect(not_logged_in_page.get_by_text("30 results", exact=True).first).to_be_visible(timeout=10000)