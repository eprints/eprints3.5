#!/bin/bash

CREDS_FILE=$1

echo `pwd`



# source /home/eprints/playwright-venv/bin/activate



thisfilepath=`dirname "$(realpath $0)"`
cd $thisfilepath
echo `pwd`
export WORKSPACE=`pwd`


python -m venv jenkins-venv
source jenkins-venv/bin/activate

pip install pytest fpdf2 playwright pytest-playwright
playright install


printenv

#--rootdir `pwd` 
#-c $thisfilepath/pytest.ini
#python -m 
pytest --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/