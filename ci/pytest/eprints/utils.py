from playwright.sync_api import Page, expect
import re

def get_section(page, section_title, parent_class="ep_form_field_input"):
    # return page.locator(f"css=.{parent_class}").filter(has=page.get_by_text("Creators"))#re.compile("Creators")))
    #find the section with <a name="section_title">
    return page.locator(f"css=.{parent_class}").filter(has=page.locator(f"xpath=//a[@name='{section_title.lower()}']"))

def add_to_table(page, section_title, addme):
    '''

    :param page: page object
    :param section_title: text for this section of workflow
    :param addme: dict of colname:value to add to a row
    :return:
    '''
    section = get_section(page, section_title)

    table = section.locator("css=table")
    expect(table).to_be_visible()

def login(page, username, password):
    page.goto(f"cgi/users/login")

    page.get_by_role("textbox", name="Username:").fill(username)
    page.get_by_role("textbox", name="Password:").fill(password)
    page.get_by_role("button", name="Login").click()


def select_locator(page, label, **kwargs):
    '''
    find the <select> element with label text
    for reasons I've yet to determine, get_by_label("option",...) doesn't work
    '''
    return page.get_by_label(label, **kwargs).and_(page.locator("xpath=//select"))