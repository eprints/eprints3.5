#!/bin/bash

CREDS_FILE=$1

echo `pwd`

source /home/eprints/playwright-venv/bin/activate

printenv

#--rootdir `pwd` 
python -m pytest --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/