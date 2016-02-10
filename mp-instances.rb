require 'httparty'
require 'trollop'
require 'highline/import'

def get_adapters(hostname, username, urlend, password=nil)
  password ||= promptpass 
  base_uri = "https://#{hostname}/#{urlend}"
  auth = { "username": username, "password": password }
  begin
    request = HTTParty.get(base_uri, basic_auth: auth, verify: false)
    request
  rescue Exception => e
    puts "Couldn't find host: #{hostname}"
    nil
  end
end

# Prompt the user without echo
def promptpass
  ask("Password? ") { |q| q.echo = false }
end

def host_from_resource_kinds(resource_kinds)
  resource_kinds["resourceIdentifiers"]["resourceIdentifier"].each do |identifier|      
    # skip iterations where the schema is not what we expect
    next unless identifier.is_a?(Hash)
    if ["host", "VCURL", "DfmServer"].include?(identifier["identifierType"]["name"])
      return identifier["value"]
    end
  end
  nil
end

def get_instances(adapters)
  adapter_kinds = {}
  adapters["adapter_instances"]["adapter_instance"].each do |instance|
    resource_kinds = instance["resourceKey"]
    name = resource_kinds["name"]
    adapter_kinds[resource_kinds["adapterKindKey"]] ||= {}
    adapter_kinds[resource_kinds["adapterKindKey"]][name] = host_from_resource_kinds resource_kinds
  end
  adapter_kinds
end

def main
  # Handle command line arguments
  opts = Trollop::options do
    opt :host, "Host", :short => "-o", :required => true, :type => :string
    opt :user, "User", :required => true, :type => :string
  end
  hostname = opts[:host]
  username = opts[:user]

  # Do the REST API call to GET a hash of the adapter instances
  adapters = get_adapters(hostname, username, "suite-api/api/adapters")

  # Uncomment the following line to view the raw output of the API call
  # puts adapters

  # Create a hash of hash: {adapter_kind => {adapter_instance => host}} 
  adapter_kinds = get_instances(adapters)

  # Pretty print a list of Adapter kinds and instances
  keys = adapter_kinds.keys.sort
  keys.each do |kind|
    puts "#{kind} instances:"
    sub_keys = adapter_kinds[kind].keys.sort
    sub_keys.each do |inst|
      host = adapter_kinds[kind][inst] || "N/A"
      puts "  #{inst} : #{host}"
    end
  end
end

if __FILE__ == $0
  main
end