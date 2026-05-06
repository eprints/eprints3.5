# Running the Tests Locally

Pytest is being used (mildly abused) to provide system tests, rather than unit tests.

## Setting up a Python Virtual Environment
I recommend using a venv. The tests can be run from either Windows or Linux.

```bash
#create venv
python -m venv path/to/venv

#activate venv
source path/to/venv/bin/activate

#install python packages
pip install -r requirements.txt

#let playwright install its browsers
playwright install
```

create `credentials.json`:
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
```
pytest --url http://your-merry-eprints-instance.eprints-hosting.org/ --creds credentials.json -s -k test_eprint_submit_article --headed
```