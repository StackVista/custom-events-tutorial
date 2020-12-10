require 'puppet'

require 'net/http'
require 'openssl'
require 'uri'
require 'json'

Puppet::Reports.register_report(:stackstate) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "stackstate.yaml"])
  raise(Puppet::ParseError, "StackState report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  STACKSTATE_URL = config[:stackstate_url]
  STACKSTATE_API_KEY = config[:stackstate_api_key]
  PUPPETCONSOLE_HOST = config[:puppetconsole_host]

  desc "Send Puppet reports to StackState"

  # Define and configure the report processor.
  def process
    Puppet.debug "Sending status for #{self.host} to StackState server at #{STACKSTATE_URL}"

    payload = <<-END
    {
      "collection_timestamp": #{self.time.to_i},
      "events": {
        "puppet": [
          {
            "context": {
              "category": "Changes",
              "data": {
                "configuration_version": "#{self.configuration_version.to_s}",
                "transaction_uuid": "#{self.transaction_uuid}",
                "catalog_uuid": "#{self.catalog_uuid}",
                "status": "#{self.status}"
              },
              "element_identifiers": [
                 "urn:host:/#{self.host}"
              ],
              "source": "Puppet",
              "source_id": "#{self.transaction_uuid}",
              "source_links": [
                {
                  "title": "Puppet console",
                  "url": "https://#{PUPPETCONSOLE_HOST}/#/node_groups/inventory/node/#{self.host}/reports"
                }
              ]
            },
            "event_type": "ConfigurationChangedEvent",
            "msg_title": "Puppet run for #{self.host} #{self.status}",
            "msg_text": "Puppet run for #{self.host} #{self.status} on configuration version #{self.configuration_version.to_s} in #{self.environment}",
            "source_type_name": "ConfigurationChangedEvent",
            "tags": [
              "environment:#{self.environment}"
            ],
            "timestamp": #{self.time.to_i}
          }
        ]
      },
      "internalHostname": "#{self.host}",
      "metrics": [],
      "service_checks": [],
      "topologies": []
    }
END

    Puppet.debug "StackState event payload: #{payload}"
    result = post_json("#{STACKSTATE_URL}/intake?api_key=#{STACKSTATE_API_KEY}", payload)
    Puppet.debug "HTTP POST result: #{result.code}"
  end

  def post_json(url, payload)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    #http.set_debug_output $stderr
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.request_uri)
    Puppet.debug "HTTP URL: #{uri.request_uri}"
    request['Content-Type'] = "application/json"
    request.body = payload
    return http.request(request)
  end
end
