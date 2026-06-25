import time

from playwright.sync_api import Page, expect
import re
import pytest

from eprints.utils import login, select_locator, get_counts_from_titles_per_key, \
    get_titles_for_year_from_test_data, get_titles_for_subject_from_test_data, get_titles_for_authors_from_test_data, \
    fill_in_register_user, get_table_cell

'''
These are intended to replace the "simple" selenium tests. Where possible they are based on the test data and are parameterised
'''

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

    def register_user():

        # not_logged_in_page.get_by_role("textbox", name="Title").fill(temp_user_info["title"])
        # not_logged_in_page.get_by_role("textbox", name="Given Name / Initials").fill(temp_user_info["name_given"])
        # not_logged_in_page.get_by_role("textbox", name="Family Name").fill(temp_user_info["name_family"])
        fill_in_register_user(not_logged_in_page, temp_user_info)
        not_logged_in_page.get_by_role("button", name="Register").click()

    register_user()
    expect(not_logged_in_page.get_by_text(f"You have registered with username {temp_user_info['username']}.",
                                          exact=False)).to_be_visible()

    not_logged_in_page.get_by_text("Create Account").first.click()

    register_user()
    expect(not_logged_in_page.get_by_text(f"A user with the email address {temp_user_info['email']} already exists.", exact=False)).to_be_visible()

    # login(not_logged_in_page, temp_user_info["username"], temp_user_info["password"])
@pytest.mark.order(0)
def test_empty_indexer_queue(page: Page, base_url):
    '''
    "test" that waits for the indexer to have finished. Useful to check there isn't anything in the indexer that's broken
    and that the data import has completely finished before the other tests launch
    :param page:
    :param base_url:
    :return:
    '''
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

def check_search_filter_result_count(page, filter_name, expected_count):
    # find the checkbox, then go up to the parent and along to the ep_facet_count
    # probably a bit fragile
    results = page.get_by_role("checkbox", name=filter_name).locator("..").locator(
        'xpath=/following-sibling::*', has_text=f"{expected_count}")
    expect(results).to_be_visible()

def test_simple_search(not_logged_in_page):
    not_logged_in_page.get_by_placeholder("Search Journal articles, titles, dates, authors…").fill("article")
    not_logged_in_page.get_by_role("button", name="Search").click()

    expect(not_logged_in_page.get_by_text("100 results", exact=True).first).to_be_visible()

    expect(not_logged_in_page.get_by_role("link", name="Refine search").first).to_be_visible()
    expect(not_logged_in_page.get_by_role("link", name="New search").first).to_be_visible()
    expect(not_logged_in_page.get_by_label("Order the results", exact=False).first).to_be_visible()
    not_logged_in_page.get_by_text("Export options").click()
    expect(not_logged_in_page.get_by_text("Export 100 results as", exact=False)).to_be_visible()
    for link_text in ["Atom", "RSS 1.0", "RSS 2.0"]:
        expect(not_logged_in_page.get_by_role("link", name=link_text, exact=False)).to_be_visible()





    filters = [("Fenderson Press", 14),
               ("Conference or Workshop Item", 50),
               ("Smith and Sons", 14),
               ("Husbandry Times", 8),
               ("2018", 17)
               ]
    for filter in filters:
        #get the next element along from the text and check there are the expected number of results
        check_search_filter_result_count(not_logged_in_page, *filter)

    not_logged_in_page.get_by_role("button", name="Show 5 more").click()
    check_search_filter_result_count(not_logged_in_page,"International Journal of Evolutionary Ideas", 2)



    not_logged_in_page.get_by_role("checkbox", name="2018").click()
    expect(not_logged_in_page.get_by_text("17 results", exact=True).first).to_be_visible()
    not_logged_in_page.get_by_role("checkbox", name="2020").click()

    expect(not_logged_in_page.locator("css=.ep_search_result").first).to_contain_text("Mandarin Ducks in Myth and Legend")
    expect(not_logged_in_page.locator("css=.ep_search_result").first).to_contain_text(
        "(2020)")

    expect(not_logged_in_page.get_by_text("30 results", exact=True).first).to_be_visible()

    not_logged_in_page.get_by_label("Order the results").first.select_option(label="by title")
    not_logged_in_page.get_by_role("button", name="Reorder").first.click()
    #expect the top result to be the duck
    expect(not_logged_in_page.locator("css=.ep_search_result").first).to_contain_text("Black-billed Whistling Duck")

    #untick 2018
    not_logged_in_page.get_by_role("checkbox", name="2018").click()

    expect(not_logged_in_page.get_by_text("13 results", exact=True).first).to_be_visible()

    not_logged_in_page.get_by_role("checkbox", name="Conference or Workshop Item").click()

    expect(not_logged_in_page.get_by_text("9 results", exact=True).first).to_be_visible()


def test_advanced_search(not_logged_in_page):
    # should be a hidden text for the magnifiying glass button
    not_logged_in_page.get_by_role("link", name="Advanced Search").click()

    #check the h1 is "Advanced Search"
    # expect(not_logged_in_page.locator("css=h1").filter(has=not_logged_in_page.get_by_text("Advanced Search"))).to_be_visible()
    expect(not_logged_in_page.get_by_role("heading", name="Advanced Search")).to_be_visible()
    #link back to simple search
    expect(not_logged_in_page.get_by_role("link", name="simple search")).to_be_visible()

    expect(not_logged_in_page.get_by_role("button", name="Reset the form").first).to_be_visible()
    #
    # for link_text in ["Atom", "RSS 1.0", "RSS 2.0"]:
    #     expect(not_logged_in_page.get_by_role("link", name=link_text, exact=False)).to_be_visible()

    #check drop downs are present:
    for text in ["Documents", "Title", "Creators", "Abstract", "Uncontrolled Keywords", "Journal or Publication Title", "Refereed", "Retrieved records must fulfill", "Order the results"]:

        expect(select_locator(not_logged_in_page, text, exact=True)).to_be_visible()

    not_logged_in_page.get_by_role("textbox", name="Title", exact=True).type("frog")

    #can't click the first one as that's the simple search!
    not_logged_in_page.get_by_role("button", name="Search", exact=True).nth(1).click()
    # time.sleep(10)

    expect(not_logged_in_page.get_by_text("8 results", exact=True).first).to_be_visible()

    filters = [("Article", 8),
               ("Published", 8),
               ("Elseware Publishing", 4),
               ("Fine Animal Breeding", 2),
               ("2017", 2)
               ]
    for filter in filters:
        # get the next element along from the text and check there are the expected number of results
        check_search_filter_result_count(not_logged_in_page, *filter)
    # check_search_filter_result_count(not_logged_in_page, "Article", 8)

    expect(not_logged_in_page.get_by_role("button", name="Reorder").first).to_be_visible()

    not_logged_in_page.get_by_text("Export options").click()

    for link_text in ["Atom", "RSS 1.0", "RSS 2.0"]:
        expect(not_logged_in_page.get_by_role("link", name=link_text, exact=False)).to_be_visible()

    not_logged_in_page.get_by_role("checkbox", name="Elseware Publishing").click()

    expect(not_logged_in_page.get_by_text("4 results", exact=True).first).to_be_visible()

    expect(not_logged_in_page.locator("css=.ep_search_result").nth(1)).to_contain_text(
        "Dusky Tree Frogs in the Wild")
    expect(not_logged_in_page.locator("css=.ep_search_result").nth(2)).to_contain_text("Giant Waxing Monkey Tree Frogs in the Wild")

    #varying slightly from old selenium tests because I can't reproduce them or figure out exactly which filter they were choosing
    not_logged_in_page.get_by_role("checkbox", name="Husbandry Times").click()
    expect(not_logged_in_page.get_by_text("2 results", exact=True).first).to_be_visible()

    expect(not_logged_in_page.locator("css=.ep_search_result").nth(0)).to_contain_text(
        "Blue Poison Arrow Frogs in the Wild")
    expect(not_logged_in_page.locator("css=.ep_search_result").nth(1)).to_contain_text(
        "Habits of the Yellow and Black Poison Arrow Frogs")

@pytest.mark.parametrize("category_name,expected_totals,total_text", [
    ("Year", get_counts_from_titles_per_key(get_titles_for_year_from_test_data()), "Number of items"),
    ("Subject", get_counts_from_titles_per_key(get_titles_for_subject_from_test_data()), "Number of items at this level"),
    # ("Division", get_counts_from_titles_per_key(get_titles_for_subject_from_test_data(division=True)), "Number of items at this level")
])
#was hoping to make this more generic, only partially succeeded for year and subject
def test_browse_page_generic(not_logged_in_page, category_name, expected_totals, total_text, scope):
    '''
    for year, subject and division they're all the same structure with different text. Author is different because it doesn't list them all on the top level page
    :param not_logged_in_page:
    :param category_name: eg Year or Division
    :param category_name:  dict of title and number of results, eg {"2023": "8",...}
    :return:
    '''
    # category_name = "Year"
    # expected_totals = get_counts_from_titles_per_key(get_titles_for_year_from_test_data())
    first_time=True
    url = "/view/"

    def get_to_top_level_browse():
        #using the mouse is a tiny bit unreliable - I assume because js hooks haven't been registered? not entirely sure.
        nonlocal first_time
        nonlocal  url
        if first_time:
            time.sleep(1)
            not_logged_in_page.get_by_role("menuitem", name="Browse").hover()
            not_logged_in_page.get_by_role("menuitem", name=f"Browse by {category_name}").click()
            url = not_logged_in_page.url
            first_time = False
        else:
            not_logged_in_page.goto(url)
    keys = [key for key in expected_totals]
    if scope != "full" and len(keys) > 20:
        #reduce quantity, no need for test to take an age
        keys = [key for i,key in enumerate(keys) if i%3==0]

    for info in keys:
        get_to_top_level_browse()
        #eg info = 2023 and expected_totals[info] = 8
        not_logged_in_page.get_by_role("link", name=info, exact=True).click()
        print(f"Expecting {expected_totals[info]} for {info}")
        expect(not_logged_in_page.get_by_text(f"{total_text}: {expected_totals[info]}")).to_be_visible()

def test_browse_page_divisions(not_logged_in_page):
    #test data only has one eprint with a division, so just go there manually for now
    not_logged_in_page.goto("/view/divisions/sch=5Fmat/2016.html")
    expect(not_logged_in_page.get_by_text("Number of items: 1.")).to_be_visible()

def test_browse_page_authors(not_logged_in_page):
    titles_by_author = get_titles_for_authors_from_test_data()
    not_logged_in_page.get_by_role("menuitem", name="Browse").hover()
    not_logged_in_page.get_by_role("menuitem", name=f"Browse by Author").click()

    expected_texts = []
    for author in titles_by_author:
        expected_texts.append(f"{author} ({len(titles_by_author[author])})")
    seen_texts = []

    not_logged_in_page.wait_for_load_state()

    links = not_logged_in_page.locator("xpath=//*[@class=\"ep_toolbox_content\"]//a")

    def check_for_texts():
        nonlocal seen_texts
        for text in expected_texts:
            if not_logged_in_page.get_by_text(text, exact=True).is_visible():
                seen_texts.append(text)
    #we start on A
    check_for_texts()
    #loop round all the alphabetical links and check we see all the authors we expect
    for i in range(links.count()):
        print(f"Navigating to View Authors {links.nth(i).inner_html()}")
        links.nth(i).click()
        not_logged_in_page.wait_for_load_state()
        check_for_texts()

    unseen_authors = [text for text in expected_texts if text not in seen_texts]
    assert len(unseen_authors) == 0


def test_manage_profile_page(logged_in_page, test_admin_user_info):

    # title = "Mr"
    # name_given = "Fred"
    # name_family = "Blogs"

    logged_in_page.get_by_role("link", name="Profile").click()
    logged_in_page.get_by_role("button", name="Edit").first.click()
    logged_in_page.get_by_role("button", name="Next").first.click()

    logged_in_page.get_by_role("textbox", name="Title").fill(test_admin_user_info["title"])
    logged_in_page.get_by_role("textbox", name="Given Name / Initials").fill(test_admin_user_info["name_given"])
    logged_in_page.get_by_role("textbox", name="Family Name").fill(test_admin_user_info["name_family"])

    logged_in_page.get_by_role("button", name="Save and Return").first.click()

    expect(logged_in_page.get_by_text(f"{test_admin_user_info['title']} {test_admin_user_info['name_given']} {test_admin_user_info['name_family']}", exact=True).first).to_be_visible()

    logged_in_page.get_by_role("link", name="Logout").click()

def test_admin_pages(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()


    def button_present(text):
        expect(logged_in_page.get_by_role("button", name=text)).to_be_visible()

    for button_text in ["Search items", "Search issues", "Search users", "Search people", "Search organisations", "Search history"]:
        button_present(button_text)

    logged_in_page.get_by_text("System Tools").click()

    for button_text in ["Status", "Create user", "Create person", "Create organisation", "Force Start Indexer", "Stop Indexer", "Regenerate Abstracts", "Regenerate Entities", "Regenerate Citations", "Regenerate Views", "Send Test Email", "Database Schema"]:
        button_present(button_text)

    logged_in_page.get_by_text("Config. Tools").click()

    for button_text in ["Storage Manager", "Update Database", "Reload Configuration", "View Configuration", "Phrase Editor", "Template Tests", "Create a Page", "Edit subject", "Manage Metadata Fields"]:
        button_present(button_text)

    logged_in_page.get_by_role("link", name="Logout").click()

'''
I wonder if it was possible to abstract out and unify the admin search pages. They're all a bit different in subtle ways, but do the same job.

'''
def test_admin_search_issues_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name ="Search issues").click()
    logged_in_page.get_by_role("button", name="Search").first.click()
    expect(logged_in_page.get_by_text("Search has no matches.")).to_be_visible()

    logged_in_page.get_by_role("link", name="Logout").click()


def test_admin_search_items_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name ="Search items").click()

    logged_in_page.get_by_role("textbox", name="Title", exact=True).fill("monkey")

    logged_in_page.get_by_role("button", name="Search").first.click()

    expect(logged_in_page.get_by_text("1.	McInerny, Γαία (2018) Giant Waxing Monkey Tree Frogs in the Wild. Natural World Journal (NWJ), 4 (19). pp. 145-191.")).to_be_visible()
    expect(logged_in_page.get_by_text("2.	Joergensen, M. and Notley, V. and Beda, J. (2017) Waxing Monkey Frogs in the Wild. Fine Animal Breeding, 9 (17). pp. 117-163.")).to_be_visible()

    select_locator(logged_in_page, "Order the results").first.select_option(label="by year (oldest first)")
    logged_in_page.get_by_role("button", name="Reorder").first.click()

    expect(logged_in_page.get_by_text(
        "2.	McInerny, Γαία (2018) Giant Waxing Monkey Tree Frogs in the Wild. Natural World Journal (NWJ), 4 (19). pp. 145-191.")).to_be_visible()
    expect(logged_in_page.get_by_text(
        "1.	Joergensen, M. and Notley, V. and Beda, J. (2017) Waxing Monkey Frogs in the Wild. Fine Animal Breeding, 9 (17). pp. 117-163.")).to_be_visible()


    logged_in_page.get_by_role("link", name="Refine search").first.click()
    title_box = logged_in_page.get_by_role("textbox", name="Title", exact=True)
    title_box.clear()
    title_box.fill("snake")

    logged_in_page.get_by_role("button", name="Search").first.click()

    expect(logged_in_page.get_by_text(
        "2.	Tachizaki, H. and Aφροδίτη, S. and Ciavola, C. and Leir, Γαία (2019) Observations on the Green Vine Snake. Fine Animal Breeding, 6 (20). pp. 35-66.")).to_be_visible()
    expect(logged_in_page.get_by_text(
        "1.	Paulitsch, R. and Tachizaki, F. and Calafat, E. (2018) Mating rituals of the Indigo Snake. Chinese Gamekeeping Journal, 5 (9). pp. 196-237.")).to_be_visible()

    logged_in_page.get_by_text("Export options").click()

    select_locator(logged_in_page, "Export 2 results as ").select_option(label="EP3 XML with Files Embedded")

    logged_in_page.get_by_role("link", name="Observations on the Green Vine Snake.").click()

    expect(logged_in_page.get_by_role("heading", name="View Item: Observations on the Green Vine Snake")).to_be_visible()

    logged_in_page.get_by_role("link", name="Logout").click()

@pytest.mark.order(after="test_manage_profile_page")
def test_admin_search_users_page(logged_in_page, test_admin_user_info, temp_user_info):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name="Search users").click()

    logged_in_page.get_by_role("checkbox", name="User").check()
    logged_in_page.get_by_role("checkbox", name="Repository Administrator").check()

    logged_in_page.get_by_role("button", name="Search").first.click()

    def check_user(user_info, position):

        expect(logged_in_page.get_by_text(f"{position}.	{user_info['title']} {user_info['name_given']} {user_info['name_family']}"))

    check_user(test_admin_user_info, 1)
    check_user(temp_user_info, 2)

    logged_in_page.get_by_label("Order the results").first.select_option(label="By registration date (newest first)")
    logged_in_page.get_by_role("button", name="Reorder").first.click()

    check_user(test_admin_user_info, 2)
    check_user(temp_user_info, 1)

    logged_in_page.get_by_role("link", name="Refine search").first.click()


    logged_in_page.get_by_role("textbox", name="Username").fill("admin")
    logged_in_page.get_by_role("button", name="Search").first.click()

    expect(logged_in_page.get_by_text("Displaying results 1 to 1 of 1").first).to_be_visible()

    logged_in_page.get_by_role("link", name="Logout").click()


def test_admin_search_history_page(logged_in_page, test_admin_user_info, temp_user_info):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name="Search history").click()

    logged_in_page.get_by_role("checkbox", name="Created").check()

    logged_in_page.get_by_role("button", name="Search", exact=True).first.click()

    expect(logged_in_page.get_by_role("heading", name="Action matches any of \"Created\"", exact=True)).to_be_visible()
    expect(logged_in_page.get_by_text("Displaying results 1 to 10").first).to_be_visible()

    logged_in_page.get_by_label("Order the results").first.select_option(label="Time (oldest first)")
    logged_in_page.get_by_role("button", name="Reorder").first.click()
    expect(logged_in_page.locator("css=.ep_history_item").first).to_contain_text("African Elephants in Τάρταρος (eprint 1 r1)")

    logged_in_page.get_by_role("link", name="Refine search").first.click()

    logged_in_page.get_by_role("textbox", name="Object ID").fill("100")
    logged_in_page.get_by_role("checkbox", name="Created").uncheck()
    logged_in_page.get_by_role("button", name="Search", exact=True).first.click()

    expect(logged_in_page.get_by_role("heading", name="Object ID is 100", exact=True)).to_be_visible()

    expect(logged_in_page.get_by_text("Yellow Spotted Amazon River Turtle (eprint 100 r1)", exact=True)).to_be_visible()

    logged_in_page.get_by_text("Export options").click()
    select_locator(logged_in_page, "Export 1 results as").select_option(label="Object IDs")
    logged_in_page.get_by_role("button", name="Export", exact=True).click()

    expect(logged_in_page.get_by_text("380", exact=True)).to_be_visible()

def test_admin_search_people_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name ="Search people").click()

    logged_in_page.get_by_role("textbox", name="All Names").fill("Beda")

    logged_in_page.get_by_role("button", name="Search", exact=True).first.click()

    expect(logged_in_page.get_by_text("Displaying results 1 to 9 of 9").first).to_be_visible()

    expect(logged_in_page.get_by_text("1.	Beda, B.")).to_be_visible()

def test_admin_search_organisation_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_role("button", name ="Search organisations").click()

    logged_in_page.get_by_role("textbox", name="All Names").fill("Elseware")

    logged_in_page.get_by_role("button", name="Search", exact=True).first.click()

    logged_in_page.get_by_text("Export options").click()
    select_locator(logged_in_page, "Export 1 results as").select_option(label="HTML Citation")
    logged_in_page.get_by_role("button", name="Export", exact=True).click()

    expect(logged_in_page.get_by_text("Elseware Publishing", exact=True)).to_be_visible()

def test_admin_database_schema_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("System Tools").click()
    logged_in_page.get_by_role("button", name ="Database Schema").click()

    texts = [
        "Database Schema",
        "Database Tables",
        "Dataset Tables",
        "Access Logs",
        "Cache Tables",
        "Documents",
        "Eprints",
        "Tasks",
        "Files",
        "Object Revisions",
        "User Log-ins",
        "User Notifications",
        "Metafield",
        "Organisations",
        "Page",
        "People",
        "Requests",
        "Saved Searches",
        "Subjects",
        "Users",
        "Misc. Tables"
    ]

    for text in texts:

        expect(logged_in_page.get_by_text(text).first).to_be_visible()

'''
Assumes running only on the test data
TODO check text is in the right cells in the table? bit noddy otherwise
I can't really tell if this is actually working properly.
note - must be run before anything other than the eprints test data has been added
'''
def test_admin_storage_manager_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("Config. Tools").click()
    logged_in_page.get_by_role("button", name ="Storage Manager").click()

    expect(logged_in_page.get_by_role("heading", name="Storage Manager")).to_be_visible()

    texts = [
        "Local disk storage",
        "Documents:",
        "600",
        "Object Revisions:",
        "100"
    ]

    for text in texts:
        expect(logged_in_page.get_by_text(text).first).to_be_visible()


def test_admin_reload_config(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("Config. Tools").click()
    logged_in_page.get_by_role("button", name ="Reload Configuration").click()

    expect(logged_in_page.get_by_text("Repository configuration reloaded!", exact=True)).to_be_visible()

#should we even still support this feature? it's slightly mad
# def test_admin_view_config(logged_in_page):
#     logged_in_page.get_by_role("link", name="Admin", exact=True).click()
#     logged_in_page.get_by_text("Config. Tools").click()
#     logged_in_page.get_by_role("button", name ="View Configuration").click()
#
#     expect(logged_in_page.get_by_text("Repository configuration reloaded!")).to_be_visible()

def test_phrase_editor(logged_in_page, base_url):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("Config. Tools").click()
    logged_in_page.get_by_role("button", name="Phrase Editor").click()

    table = logged_in_page.locator("//table[@id='ep_phraseedit_table']")
    edit_cell = get_table_cell(table, "Content", {"Identifier": "archive_name"})

    test_text = "Text to replace the name of the repository for testing here"

    # textbox = edit_cell.get_by_role("textbox")
    edit_cell.click()
    edit_cell.get_by_role("textbox").fill(test_text)

    edit_cell.get_by_role("button", name="Save").click()
    expect(edit_cell.get_by_text("Phrase saved.")).to_be_visible()

    # table.locator("xpath=/tbody/tr/th").all_inner_texts()
    #archive_name
    logged_in_page.get_by_role("link", name="Admin", exact=True).first.click()
    logged_in_page.get_by_text("Config. Tools").click()
    logged_in_page.get_by_role("button", name="Reload Configuration").click()
    expect(logged_in_page.get_by_text("Repository configuration reloaded!", exact=True)).to_be_visible()

    logged_in_page.goto(base_url)


    #EPrints 3.5 Publications CI
    expect(logged_in_page.get_by_text(test_text).first).to_be_visible()

#expects only the 100 test eprints
def test_edit_subject_page(logged_in_page):
    logged_in_page.get_by_role("link", name="Admin", exact=True).click()
    logged_in_page.get_by_text("Config. Tools").click()
    logged_in_page.get_by_role("button", name="Edit subject").click()

    expect(logged_in_page.get_by_role("heading", name="Edit subject: (Top Level)")).to_be_visible()

    expect(logged_in_page.get_by_role("link", name="Library of Congress Subject Areas")).to_be_visible()

    #bit fragile, ideally need a way of finding tables with expected headers?
    table = logged_in_page.locator("//table")
    cell = get_table_cell(table, "Eprints (Repository)", {"Children": "Library of Congress Subject Areas"})

    expect(cell.get_by_text("100 (100)")).to_be_visible()

    cell = get_table_cell(table, "Eprints (Repository)", {"Children": "University Structure"})

    expect(cell.get_by_text("1 (1)")).to_be_visible()

    subject_id = "subject_new_id"
    subject_new_name = "subject_new_name"

    logged_in_page.get_by_role("textbox", name="Subject ID String").fill(subject_id)
    logged_in_page.get_by_role("button", name="Create").click()

    expect(logged_in_page.get_by_text(f"Created new subject node with ID \"{subject_id}\". Please now enter a subject name and set the subject to be depositable, if applicable.")).to_be_visible()

    logged_in_page.get_by_role("textbox", name="Name", exact=True).fill(subject_new_name)

    select_locator(logged_in_page, "Language").select_option(label="English")

    logged_in_page.get_by_role("button", name="Save changes").click()

    expect(logged_in_page.get_by_text("Saved changes")).to_be_visible()

    logged_in_page.get_by_role("link", name="(Top Level)").click()

    cell = get_table_cell(table, "Actions", {"Children":subject_new_name})
    cell.get_by_role("button", name="Unlink").click()

    for text in [f"Deleting {subject_new_name}", "Unlinking this subject will cause it to be permanently deleted. Are you sure you want to do this?"]:
        expect(logged_in_page.get_by_text(text)).to_be_visible()
    logged_in_page.get_by_role("button", name="Remove").click()

    expect(logged_in_page.get_by_text("Removed subject. This subject node has been deleted.")).to_be_visible()

    expect(logged_in_page.get_by_text(subject_new_name)).not_to_be_visible()
