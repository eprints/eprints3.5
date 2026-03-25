#!/bin/bash

CREDS_FILE=$1

source /home/eprints/playwright-venv/bin/activate

python -m pytest --creds $CREDS_FILE --url https://playwright.eprints-hosting.org/