FROM yabawock/baseimage:2.0.0
MAINTAINER Morton Jonuschat <m.jonuschat@mojocode.de>

ADD ./image/ /tmp/build/
ADD ./services/jira /etc/service/jira
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive /tmp/build/build.sh

EXPOSE 8080
