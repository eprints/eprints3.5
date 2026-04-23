import re
import time
import pytest

from playwright.sync_api import Page, expect

from eprints.utils import add_to_table, get_table_cell, get_full_name


#put last as it will alter data expected by the very prescriptive test_pages tests
@pytest.mark.order(-1)
def test_eprint_submit_article(logged_in_page, random_eprint):

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


    page.get_by_role("textbox", name="Journal or Publication Title").fill(random_eprint.publication)

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

    expect(page.get_by_text("This item is in review. It will not appear in the repository until it has been checked by an editor.")).to_be_visible()

    # page.get_by_role("button", name="Move to Repository").click()

@pytest.mark.order(after="test_eprint_submit_article")
def test_eprint_review(logged_in_page, test_admin_user_info, random_eprint):
    page = logged_in_page
    page.get_by_role("link", name="Review").first.click()
    table = page.locator("xpath=//table")
    actions_cell = get_table_cell(table, "Actions", {"Depositing User": get_full_name(test_admin_user_info)})
    actions_cell.get_by_alt_text("View Item").click()

    expect(page.get_by_role("heading", name=f"View Item: {random_eprint.title}")).to_be_visible()

    page.get_by_text("Details").first.click()

    expect(page.get_by_role("cell", name=random_eprint.publication)).to_be_visible()

    page.get_by_text("Preview").first.click()

    page.get_by_role("button", name="Return item (with notification)").click()

    expect(page.get_by_role("heading", name=f"Return item (with notification): {random_eprint.title}")).to_be_visible()
    expect(page.get_by_text("Please enter in the box below the reason for returning this item, and any possible fix. This will be emailed to the relevant author.")).to_be_visible()

    expect(page.get_by_text("Change Reason")).to_be_visible()

    page.get_by_role("button", name="Cancel").click()

    page.get_by_role("button", name="Return item (with notification)").click()

    page.get_by_role("button", name="Return Item").click()

    for text in [f"Item status successfully changed.", "Email successfully sent."]:
        expect(page.get_by_text(text)).to_be_visible()

    page.get_by_text("Details").first.click()

    expect(page.get_by_text("User Workarea")).to_be_visible()

@pytest.mark.order(after="test_eprint_review")
def test_eprint_resubmit(logged_in_page, test_admin_user_info, random_eprint):
    page = logged_in_page
    table = page.locator("xpath=//table")

    actions_cell = get_table_cell(table, "Actions", {"Title": random_eprint.title})

    actions_cell.get_by_alt_text("View Item").click()

    #could follow the original test and do some editing here. Do we need to?

    page.get_by_role("button", name="Deposit Item").click()

    page.get_by_role("button", name="Deposit Item Now").click()

    for text in ["Item has been deposited.", "Your item will not appear on the public website until it has been checked by an editor."]:
        expect(page.get_by_text(text)).to_be_visible()

@pytest.mark.order(after="test_eprint_resubmit")
def test_eprint_rereview(logged_in_page, test_admin_user_info, random_eprint):
    page = logged_in_page
    page.get_by_role("link", name="Review").first.click()
    table = page.locator("xpath=//table")
    actions_cell = get_table_cell(table, "Actions", {"Depositing User": get_full_name(test_admin_user_info)})
    actions_cell.get_by_alt_text("View Item").click()

    page.get_by_text("Details").first.click()

    page.get_by_role("button", name="Move to Repository").click()

    expect(page.get_by_text("Status of item changed to \"Live Archive\".")).to_be_visible()