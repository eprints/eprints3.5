# Running the Tests Locally

Pytest is being used (mildly abused) to provide system tests, rather than unit tests. The tests are intended for developers to use to expand automated testing of new features and bug fixes. It's not targetted at testing a new installation.

## Setting up a Python Virtual Environment
I recommend using a venv. The tests can be run from either Windows or Linux. Note that for Linux it's easiest to install Playwright on Ubuntu and not officially supported on Red Hat.

```bash
#older ubuntu/debian distros may need python3 and venv installed
apt install python-is-python3 python3-venv

#create venv
python -m venv path/to/venv

#activate venv for the following instructions
source path/to/venv/bin/activate

#updating pip will prevent warnings
pip install --upgrade pip

#install python packages
pip install -r requirements.txt

#on linux you may need to install the dependencies for playwright:
playwright install-deps

#let playwright install its browsers
playwright install
```

create `credentials.json`, specific to your EPrints instance:
```json
{
  "test_user": {
    "name": "admin_user",
    "password": "SuperHappyAdminPassword"
  }
}
```
## Running Tests

Note that many of the tests assume the repository is freshly created and is only populated with the stock test data.

See `ci/bin/create_eprints_archive`


Running the tests will upload a document and create an EPrint, so you can't run them multiple times. Therefore if you're developing a test you're likely going to want to run just one test. This can be specified with `-k`

If you want to watch what's happening - very useful when developing a test - add `--headed`. `-s` will configure pytest to print any stdout as the tests run, rather than gathering it up for the end of the test.

This will run just `test_eprint_submit_article`:
```bash
pytest --url http://your-merry-eprints-instance.eprints-hosting.org/ --creds credentials.json -s -k test_eprint_submit_article --headed
```