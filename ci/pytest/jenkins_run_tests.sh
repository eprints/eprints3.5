#!/bin/bash

CREDS_FILE=$1

echo `pwd`

source /home/eprints/playwright-venv/bin/activate

printenv

cd `dirname "$(realpath $0)"`

echo `pwd`

#--rootdir `pwd` 

python -m pytest --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/