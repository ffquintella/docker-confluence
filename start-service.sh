#!/bin/bash

set -e

export JAVA_HOME=/opt/java_home/java_home
export java_home=$JAVA_HOME

/opt/puppetlabs/puppet/bin/puppet apply --modulepath=/etc/puppet/modules /etc/puppet/manifests/start.pp

#echo "Starting Jira Server ..."
#/opt/jira/atlassian-jira-software-7.2.2-standalone/bin/start-jira.sh &


while [ ! -f ${FACTER_CONFLUENCE_HOME}/logs/atlassian-confluence.log ]
do
  sleep 2
done
ls -l ${FACTER_CONFLUENCE_HOME}/logs/atlassian-confluence.log

tail -n 0 -f ${FACTER_CONFLUENCE_HOME}/logs/atlassian-confluence.log &
wait
