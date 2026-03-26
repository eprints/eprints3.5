#!/bin/bash

CREDS_FILE=$1

echo `pwd`

source /home/eprints/playwright-venv/bin/activate

printenv

thisfilepath=`dirname "$(realpath $0)"`
cd $thisfilepath
echo `pwd`

#--rootdir `pwd` 

python -m pytest -c $thisfilepath/pytest.ini --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/