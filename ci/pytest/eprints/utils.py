import datetime
import gzip
import os
import xml
from xml.etree import ElementTree
from playwright.sync_api import Page, expect
import re
import pathlib
import random
import string

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

def get_test_data_xml():
    path_to_test_data = os.path.join(pathlib.Path(__file__).parent.resolve(), "../../../testdata/data/data.xml.gz")

    lines = []
    with gzip.open(path_to_test_data) as gzipfile:
        lines = [line.decode() for line in gzipfile.readlines()]
        # haven't figured out namespaces
        lines = [line.replace('xmlns="http://eprints.org/ep2/data/2.0"', "") for line in lines]

    raw_xml = "\n".join(lines)

    root = ElementTree.fromstring(raw_xml)
    return root
def get_titles_for_year_from_test_data():

    root = get_test_data_xml()

    yearinfo = {}

    # for date in root.findall(".//date"):
    #     fulldate = date.text
    #     year = fulldate.split('-')[0]
    #     if year not in yearinfo:
    #         yearinfo[year] = 1
    #     else:
    #         yearinfo[year]+= 1
    for eprint in root.iter("eprint"):
        date = None
        for date_element in eprint.iter("date"):
            date = date_element.text
            break

        year = date.split('-')[0]
        title = eprint.find("title").text
        if year not in yearinfo:
            yearinfo[year] = [title]
        else:
            yearinfo[year].append(title)
    return yearinfo

def get_counts_from_titles_per_key(titles_for_thing):
    # titles = get_titles_for_year_from_test_data()
    counts = {}
    for key in titles_for_thing:
        counts[key] = len(titles_for_thing[key])
    return counts

def get_titles_for_authors_from_test_data():
    root = get_test_data_xml()
    author_info = {}
    for eprint in root.iter("eprint"):
        names = []
        title = eprint.find("title").text
        contributions_element = eprint.find("contributions")
        for contributor in contributions_element.iter("contributor"):
            if contributor.find("datasetid").text == "person":
                #some have trailing spaces
                name = contributor.find("name").text.strip()
                #some end in a comma which eprints ignores
                if name.endswith(","):
                    name = name[:-1]
                names.append(name)

        for name in names:
            if name in author_info:
                author_info[name].append(title)
            else:
                author_info[name] = [title]
    return author_info

def get_titles_for_subject_from_test_data(division=False):
    root = get_test_data_xml()

    subject_tree = SubjectsAndDivisionsTree()

    tree_title = "subjects"
    if division:
        tree_title = "divisions"

    subject_info = {}
    for eprint in root.iter("eprint"):

        subjects_element = eprint.find(tree_title)
        if subjects_element is None:
            continue
        subjects = [element.text for element in subjects_element]
        title = eprint.find("title").text
        for subject in subjects:
            # subject_title = subject
            try:
                if division:
                    subject_title = subject_tree.divisions[subject]["title"]
                else:
                    subject_title = subject_tree.subjects[subject]["title"]
            except:
                #this subject isn't in the tree. Skip it as it won't appear in the browse page either
                continue
            if subject_title not in subject_info:
                subject_info[subject_title] = [title]
            else:
                subject_info[subject_title].append(title)

    return subject_info

class SubjectsAndDivisionsTree:
    def __init__(self):
        subjects_path = os.path.join(pathlib.Path(__file__).parent.resolve(),"../../../flavours/pub_lib/defaultcfg/subjects")
        lines = []
        with open(subjects_path) as subjects_file:
            lines = [line for line in subjects_file.readlines()]

        self.divisions = {}
        self.subjects = {}
        adding_to = self.divisions
        for line in lines:
            if line.startswith("#") or ":" not in line:
                continue

            if "subjects:Library of Congress Subject Areas" in line:
                adding_to = self.subjects
                continue

            key, title, parents_key, can_add = line.split(":")
            adding_to[key] = {
                "title": title,#.replace(f"{key} ", ""),#strip out key from front of title. don't understand why it's there
                "parents_key": parents_key,
                "can_add": True if can_add == "1" else False
            }

def get_things_from_xml():
    root = get_test_data_xml()

    # for eprint in root.findall(".//eprint"):
    #     print(eprint.text)
    for eprint in root.findall("eprint"):
        for date in eprint.iter("date"):
            print(date.text)
        # print(date)
    # for eprint in root.iter("eprint"):
    #     for tag in eprint.iter():
    #         if
    #         # print(tag.text)
    

def fill_in_person_names(page, user_info_dict):
    page.get_by_label("Title").fill(user_info_dict["title"])
    page.get_by_label("Given Name / Initials").fill(user_info_dict["name_given"])
    page.get_by_label("Family Name").fill(user_info_dict["name_family"])

def fill_in_register_user(page, user_info_dict, include_username=True, include_email=True):
    fill_in_person_names(page, user_info_dict)
    if include_email:
        page.get_by_role("textbox", name="Email address").fill(user_info_dict["email"])
    if include_username:
        page.get_by_role("textbox", name="Username").fill(user_info_dict["username"])
    page.get_by_role("textbox", name="password").fill(user_info_dict["password"])


def get_full_name(user_info_dict):
    return f"{user_info_dict['title']} {user_info_dict['name_given']} {user_info_dict['name_family']}"

def get_random_user_info():
    now = datetime.datetime.now()
    datestring = f"{now.year}_{now.month}_{now.day}_{now.hour}_{now.min}_{now.second}"

    given = ''.join([random.choice(string.ascii_letters) for i in range(10)]).title()
    family = ''.join([random.choice(string.ascii_letters) for i in range(10)]).title()

    return {
        "username": f"temporary_user_{datestring}",
        "name_given": given,
        "name_family": family,
        "title": random.choice(["Dr", "Ms", "Prof", "Rev", "Mr"]),
        "email": f"{given.lower()}{family.lower()}@eprints-hosting.org",
        "password": ''.join([random.choice(string.ascii_letters) for i in range(10)]),
        "country": random.choice(["France", "Belgium", "England", "Wales"]),
        "department": random.choice(["Physics", "History", "English", "Tap Dancing"])
    }

def get_random_organisation_info():
    org = get_random_user_info()
    org["name"] = f"University of {org['name_family']}"
    return org

def main_page_search_button(page: Page):
    main_page = page.locator("#main_content")
    # get the search button in the page, not in the navigation bar
    return main_page.get_by_role("button", name="Search").first

def get_table_cell(table_locator, column_header, row):
    '''

    :param table_locator:  Locator for the table element
    :param column_header: header text for the column required
    :param row: dict of {'column header' : value_in_this_column_for_this_row}
    :return:
    '''
    # headers = table_locator.locator("xpath=/tbody/tr/th").all_inner_texts()
    headers = table_locator.get_by_role("columnheader").all_inner_texts()

    find_by_column = [key for key in row.keys()][0]
    find_in_this_column = row[find_by_column]

    column_index = headers.index(column_header)

    # cells_in_column = table_locator.get_by_role("row").get_by_text("find_in_this_column", exact=True)

    row_locator = table_locator.locator("tr")

    cell_locator = row_locator.filter(has_text=find_in_this_column).locator("td").nth(column_index)

    # print(cell_locator.all_inner_texts())

    return cell_locator




if __name__ == "__main__":
    # get_titles_for_year_from_test_data()
    # get_things_from_xml()
    # print(get_titles_for_subject_from_test_data())
    # print(get_titles_for_subject_from_test_data())
    print(get_titles_for_authors_from_test_data())