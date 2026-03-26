#!/bin/bash

CREDS_FILE=$1

echo `pwd`



source /home/eprints/playwright-venv/bin/activate

printenv

thisfilepath=`dirname "$(realpath $0)"`
cd $thisfilepath
echo `pwd`
export WORKSPACE=`pwd`

#--rootdir `pwd` 
#-c $thisfilepath/pytest.ini
#python -m 
pytest --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/