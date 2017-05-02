require 'httparty'
require 'trollop'
require 'highline/import'

def rest_get(hostname, username, urlend, password=nil)
  password ||= prompt_password 
  base_uri = "https://#{hostname}/suite-api#{urlend}"
  auth = { "username": username, "password": password }
  begin
    request = HTTParty.get(base_uri, basic_auth: auth, verify: false)
    request
  rescue Exception => e
    puts "Couldn't find host: #{hostname}"
    nil
  end
end

# Prompt for the password without echo
def prompt_password
  ask("Password? ") { |q| q.echo = false }
end

def host_from_resource_kinds(resource_kinds)
  host_aliases = ["host", "Host", "VCURL", "DfmServer", "ip_range", 
    "ITM_REST_HOST", "host_name", "delivery_controller", "URL"]
  resource_kinds["resourceIdentifiers"]["resourceIdentifier"].each do |identifier|      
    # skip iterations where the schema is not what we expect
    next unless identifier.is_a?(Hash)
    if host_aliases.include?(identifier["identifierType"]["name"])
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
    begin
      adapter_kinds[resource_kinds["adapterKindKey"]] ||= {}
      adapter_kinds[resource_kinds["adapterKindKey"]][name] = host_from_resource_kinds resource_kinds
    rescue
      puts "Error handling: '#{resource_kinds}'"
    end
  end
  adapter_kinds
end

def main
  # Handle command line arguments
  opts = Trollop::options do
    opt :host, "Host", :short => "-o", :required => true, :type => :string
    opt :user, "User", :required => true, :type => :string
    opt :pass, "Password", :type => :string
  end
  hostname = opts[:host]
  username = opts[:user]
  password = opts[:pass]

  # Do the REST API call to GET a hash of the adapter instances
  adapters = rest_get(hostname, username, "/api/adapters", password)

  # Uncomment the following lines to view the full output of the API call
  # require 'pp'
  # PP.pp adapters

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