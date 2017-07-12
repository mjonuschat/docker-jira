#!/bin/bash
set -xeo pipefail

sed -i -e 's/<Connector port="8080"/<Connector port="8080" proxyName="jira.mojocode.de" proxyPort="443" scheme="https"/' /srv/atlassian/jira/conf/server.xml
