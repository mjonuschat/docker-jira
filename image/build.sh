#!/bin/bash
set -xeo pipefail

cat > /etc/apt/sources.list <<EOF
deb http://de.archive.ubuntu.com/ubuntu xenial main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu xenial-updates main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu xenial-security main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu xenial-backports main restricted universe multiverse
EOF

JIRA_VERSION=${JIRA_VERSION:-7.5.2}

# Install dependencies
apt-get update
apt-get install -y --no-install-recommends \
    curl \
    language-pack-de \
    language-pack-en \
    tar \
    zip \
    #

# Download installer
curl --silent \
    --retry 3 \
    --output /tmp/atlassian-jira-software-${JIRA_VERSION}-jira-${JIRA_VERSION}-x64.bin \
    https://downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${JIRA_VERSION}-x64.bin

# Create a random user
/usr/sbin/addgroup --quiet --gid 1000 jira
/usr/sbin/adduser --shell /bin/bash \
                  --disabled-password \
                  --force-badname \
                  --no-create-home \
                  --uid 1000 \
                  --gid 1000 \
                  --gecos '' \
                  --quiet \
                  --home /home/jira \
                  jira

# Prepare filesystem
mkdir -p /srv/atlassian
mkdir -p /srv/application-data/jira

# Create unattended install response file
cat >/tmp/response.varfile <<-RESPONSE
https://raw.githubusercontent.com/docker-atlassian/jira/master/response.varfile
#install4j response file for JIRA 7.0.10
#Thu Jan 29 16:43:18 UTC 2016
rmiPort$Long=8005
app.jiraHome=/srv/application-data/jira
app.install.service$Boolean=true
existingInstallationDir=/srv/atlassian/jira
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=/srv/atlassian/jira
executeLauncherAction$Boolean=false
httpPort$Long=8080
portChoice=default
RESPONSE

# Install application
sh /tmp/atlassian-jira-software-${JIRA_VERSION}-jira-${JIRA_VERSION}-x64.bin -q -varfile /tmp/response.varfile

# Forcibly set home directory
cat >/srv/atlassian/jira/atlassian-jira/WEB-INF/classes/jira-application.properties <<-CONFIG
# Do not modify this file unless instructed. It is here to store the location of the JIRA home directory only and is typically written to by the installer.
jira.home = /srv/application-data/jira/
CONFIG

# Perform finalization of setup
/tmp/build/finalize.sh

# Fix permissions
chown -R jira:jira /srv/atlassian/jira /srv/application-data/jira

# Perform cleanup
cd /
rm -rf /var/cache/apt/archives/*.deb
rm -rf /root/*
rm -rf /tmp/*

# remove SUID and SGID flags from all binaries
function pruned_find() {
  find / -type d \( -name dev -o -name proc \) -prune -o $@ -print
}

pruned_find -perm /u+s | xargs -r chmod u-s
pruned_find -perm /g+s | xargs -r chmod g-s

echo -e "\nSuccess!"
exit 0
