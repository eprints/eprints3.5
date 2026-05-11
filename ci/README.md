# Jenkins automated testing of EPrints for development

Please note, there is no support provided for this CI code.

There is a jenkinsjob - using a pipeline in `jenkinsfile`.

Playwright based tests using pytest under `pytest`. These should work fine without jenkins. For more information on running the pytest code see `ci/pytest/README.md`.

## Jenkins secure configuration
Jenkins will need a copies of (with real passwords) in Jenkins credential store:

 - `config/credentials.json` as `playwright_credentials`.
 - `config/playwright_archive.yml` as `playwright_archive_config`.

## Jenkins nodes
Jenkins uses a RHEL-like node for running EPrints and a Ubuntu node for running Playwright.