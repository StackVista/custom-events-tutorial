#/bin/bash

# ensure the right environment variables are set
if [ -z "${STS_STS_URL}" -o -z "${STS_API_KEY}" ]
then
  echo "Missing environment variables."
  echo "Please specify:"
  echo "- STS_STS_URL (eg https://stackstate.acme.com/stsAgent)"
  echo "- STS_API_KEY (eg my-api-key)"
  exit 1
fi

# put the STS_STS_URL and STS_API_KEY in the puppet configuration file
cat /etc/puppetlabs/puppet/stackstate.yaml | sed -i "2s#.*#:stackstate_url: '${STS_STS_URL}'#" /etc/puppetlabs/puppet/stackstate.yaml
cat /etc/puppetlabs/puppet/stackstate.yaml | sed -i "3s#.*#:stackstate_api_key: '${STS_API_KEY}'#" /etc/puppetlabs/puppet/stackstate.yaml

# install the agent if it's not already there
is_active=`systemctl is-active stackstate-agent`
if [ "${is_active}" = "unknown" ]
then
  curl -o- https://stackstate-agent-2.s3.amazonaws.com/install.sh | STS_API_KEY="${STS_API_KEY}" STS_URL="${STS_STS_URL}" bash
fi

# start the agent if it's not already running
if [ "${is_active}" = "inactive" ]
then
  systemctl start stackstate-agent
fi

# trigger puppet
rm -rf /var/www && puppet apply --modulepath /etc/puppetlabs/puppet/modules manifest.pp
