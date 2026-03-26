#!/bin/bash

CREDS_FILE=$1

echo `pwd`

source /home/eprints/playwright-venv/bin/activate

printenv

python -m pytest --rootdir `pwd` --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/