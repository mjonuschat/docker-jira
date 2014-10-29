FROM ubuntu-debootstrap:14.04
MAINTAINER Morton Jonuschat <m.jonuschat@mojocode.de>

ADD ./stack/build.sh /tmp/build.sh
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive /tmp/build.sh

USER jira
WORKDIR /srv/atlassian/jira

EXPOSE 5000
ENTRYPOINT ["bin/catalina.sh", "run"]
