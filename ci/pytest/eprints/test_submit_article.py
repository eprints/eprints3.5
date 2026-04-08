import re
import time
import pytest

from playwright.sync_api import Page, expect

from eprints.utils import add_to_table


def test_submit_article(logged_in_page, random_eprint):

    page = logged_in_page

    # text = page.get_by_text("Hello world")
    # if text.

    page.get_by_role("link", name="Manage deposits").click()
    page.get_by_role("button", name="New Item").click()
    page.get_by_role("button", name="Next →").first.click()

    # page.get_by_role("input", name="Click this box or drag and drop files here to begin uploading.").click()
    page.get_by_text("Click this box or drag and").click()
    # page.locator("body").set_input_files("IMG_20250101_172508.jpg")
    #page.get_by_role("button", name="Select file to upload").set_input_files(name= 'article.pdf', mimeType= 'text/plain', buffer=random_pdf_bytes)

    file_name = 'article.pdf'

    random_pdf_bytes = random_eprint.pdf.output()

    page.get_by_label("Click this box or drag and drop files here to begin uploading.").set_input_files(files={
        'name': file_name, 'mimeType': 'application/pdf', 'buffer': random_pdf_bytes})

    #wait for the block that describes the uploaded file to be present
    expect(page.get_by_role("textbox", name="Description")).to_be_visible()

    page.get_by_role("button", name="Next →").nth(1).click()

    page.get_by_role("textbox", name="Required Title").fill(random_eprint.title)

    contributions_section = page.locator("css=.ep_sr_component").filter(has_text="Contributions")
    contributions_more_rows_button = contributions_section.locator(page.get_by_role("button", name="More input rows"))

    def get_contributor_row_count():
        #wait for page to settle, make sure more rows button is clickable before counting how many rows exist
        #note to future me: just waiting for button to be visible didn't seem to be sufficient.
        contributions_more_rows_button.click(trial=True)
        #because this doesn't wait, just takes a live snapshot
        contributor_inputs = contributions_section.locator(page.get_by_role("textbox", name="Contributor Name")).all()
        count = len(contributor_inputs)
        # print(f"row count: {count}")
        return count


    while get_contributor_row_count() < len(random_eprint.authors):
        contributions_more_rows_button.click()

    for i, author in enumerate(random_eprint.authors):
        name_parts = random_eprint.authors[i].split(" ")
        name_parts.reverse()
        name = ", ".join(name_parts)
        page.get_by_role("textbox", name="Contributor Name").nth(i).fill(name)


    # page.get_by_role("checkbox", name="No, this version has not been refereed.").check()
    page.get_by_label("No, this version has not been refereed.").check()

    # page.get_by_role("checkbox", name=" Unpublished").check()
    page.get_by_label("Unpublished").check()

    dates_section = page.locator("css=.ep_form_field_input").filter(has_text="Dates")
    dates_section.locator(page.get_by_role("textbox", name="Year")).fill(f"{random_eprint.date.year}")
    dates_section.locator(page.get_by_label("Month:")).select_option(f"{random_eprint.date.month:02}")
    dates_section.locator(page.get_by_label("Day:")).select_option(f"{random_eprint.date.day:02}")
    dates_section.locator(page.get_by_label("Event")).select_option(label='Published')


    page.get_by_role("textbox", name="Journal or Publication Title").fill("Fake Journal")

    page.get_by_role("button", name="Next →").first.click()

    page.get_by_text("T Technology", exact=True).click()
    # page.get_by_role("button", name="TS Manufactures").click()
    page.get_by_label("TS Manufactures").click()
    # page.locator("input[name=\"_internal_c_subjects_TS_add\"]").click()

    page.get_by_role("button", name="Next →").nth(1).click()

    page.get_by_text("Faculty of Law, Arts and Social Sciences", exact=True).click()

    # page.get_by_role("button", name="Save and Return").first.click()
    page.get_by_label("School of Social Sciences").click()

    page.get_by_role("button", name="Next →").nth(1).click()

    page.get_by_role("button", name="Deposit Item Now").click()

    page.get_by_role("button", name="Move to Repository").click()
