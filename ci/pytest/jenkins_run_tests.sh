#!/bin/bash

CREDS_FILE=$1

#to create again:
# python -m venv playwright-venv
# source playwright-venv/bin/activate
# pip install pytest fpdf2 playwright pytest-playwright
# playwright install
source /home/eprints/playwright-venv/bin/activate


thisfilepath=`dirname "$(realpath $0)"`
cd $thisfilepath
echo `pwd`
export WORKSPACE=`pwd`


#supplying CREDS_FILE (a jenkins secret file) on command line to pytest results in jenkins doing very weird things to the environment and pytest being unable to find its tests.
#I assume as a result of whatever jenkins does to prevent secrets ending up in the log
cp $CREDS_FILE credentials.json

pytest --url https://testnode-1.eprints-hosting.org/  --junitxml=results.xml -s

rm credentials.json
