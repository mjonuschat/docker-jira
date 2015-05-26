#!/bin/bash
set -xeo pipefail

cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu trusty main
deb http://archive.ubuntu.com/ubuntu trusty-security main
deb http://archive.ubuntu.com/ubuntu trusty-updates main
deb http://archive.ubuntu.com/ubuntu trusty universe
EOF

JIRA_VERSION=6.4.4

apt-get update
apt-get install -y --force-yes \
    curl \
    default-jre-headless \
    language-pack-de \
    language-pack-en \
    tar \
    zip \
    #

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

mkdir -p /srv/atlassian
mkdir -p /srv/application-data/jira

curl --silent --retry 3 http://downloads.atlassian.com/software/jira/downloads/atlassian-jira-${JIRA_VERSION}.tar.gz | tar -xz -C /srv/atlassian

ln -nsf /srv/atlassian/atlassian-jira-${JIRA_VERSION}-standalone /srv/atlassian/jira

cat >/srv/atlassian/jira/atlassian-jira/WEB-INF/classes/jira-application.properties <<-CONFIG
# Do not modify this file unless instructed. It is here to store the location of the JIRA home directory only and is typically written to by the installer.
jira.home = /srv/application-data/jira/
CONFIG

sed -i -e 's/<Connector port="8080"/<Connector port="5000"/' /srv/atlassian/jira/conf/server.xml

chown -R jira:jira /srv/atlassian/atlassian-jira-${JIRA_VERSION}-standalone /srv/atlassian/jira /srv/application-data/jira

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

# remove non-root ownership of files
chown root:root /var/lib/libuuid

echo -e "\nSuccess!"
exit 0
