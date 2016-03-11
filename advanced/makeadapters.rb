require 'httparty'
require 'trollop'
require 'highline/import'
require 'json'

class AdapterRequest
  attr_reader :request
  def initialize(instance, creds, template = nil)
    # This is a template for a SQL Server adapter instance.
    # We can supply a template argument above to create different types.
    @template = template || {
      "name"=>"",
      "adapterKindKey"=>"SqlServerAdapter",
      "resourceKindKey"=>"SqlServerAdapterInstance",
      "resourceIdentifiers"=>
       [{"name"=>"host",
         "value"=>""},
        {"name"=>"instance",
         "value"=>"MSSQLSERVER"},
        {"name"=>"number_events",
         "value"=>"10000"},
        {"name"=>"port",
         "value"=>nil},
        {"name"=>"SUPPORT_AUTODISCOVERY",
         "value"=>"True"}],
      "description"=>nil,
      "collectorId"=>"1",
      "credential" => {
        "id" => "",
        "adapterKindKey"=>"SqlServerAdapter",
        "credentialKindKey"=>"sql_server_credentials"
      },
      "others" => [ ],
      "otherAttributes" => { }
    }
    @request = create_request(instance, creds)
  end

  def create_request(instance, creds)
    request = @template
    # change this for a different adapter instance naming convention
    request["name"] = "#{instance["name"]}_ai"
    request["credential"]["id"] = creds[instance["credential"]]
    request["resourceIdentifiers"].each do |identifier|
      if identifier["name"] == "host"
        identifier["value"] = instance["name"]
      elsif identifier["name"] == "instance" && instance.key?("instance")
        identifier["value"] = instance["instance"]
      elsif identifier["name"] == "port" && instance.key?("port")
        identifier["value"] = instance["port"]
      end
    end
    request
  end
end

# TODO: better exception handling for get, put, post, delete
class RestvROpsClient
  def initialize(hostname, username, password=nil)
    @hostname = hostname
    @base_uri = "https://#{@hostname}/suite-api"
    @auth = { 
      username: username, 
      password: password || prompt_password(username)
    }
    @basic_options = { basic_auth: @auth, verify: false }
  end

  def prompt_password(username)
    ask("Password for #{username}? ") { |q| q.echo = false }
  end

  def vrops_url(url_end)
    "#{@base_uri}#{url_end}"
  end

  def basic_rest(url_end, options = @basic_options)
    begin
      yield vrops_url(url_end), options
    rescue Exception => e
      puts e
      puts "Couldn't find host: #{@hostname}"
      nil
    end
  end

  def get(url_end)
    basic_rest(url_end) { |x,y| HTTParty.get(x,y) }
  end

  def delete(url_end)
    basic_rest(url_end) { |x,y| HTTParty.delete(x,y) }
  end

  def put(url_end)
    basic_rest(url_end) { |x,y| HTTParty.put(x,y) }
  end

  def post(url_end, data)
    data = data.to_json
    headers = { 'Content-Type' => 'application/json' }
    options = { headers: headers, body: data }.merge(@basic_options)
    basic_rest(url_end, options) { |x,y| HTTParty.post(x,y) }
  end
end

def match_credentials(vrops_creds, local_creds)
  local_creds.each do |key, value|
    vrops_creds["credential_instances"]["credential"].each do |h|
      if h["name"] == key
        local_creds[key] = h["id"]
        break
      end
    end
  end
end

def get_needed_credentials(instances)
  creds = {}
  instances.each do |instance|
    creds[instance["credential"]] = ""
  end
  creds
end

def parse_http_response(response, verb, resource_name)
  if response != nil
    if response.code >= 200 && response.code < 300
      puts [
        "#{resource_name} successfully #{verb}",
        "(HTTP status code: #{response.code})"
        ].join(" ")
      true
    else
      puts "#{resource_name} not #{verb}. Response from server:"
      puts response
      false
    end
  else
    false
  end
end

def json_parse_with_handling(str)
  begin
    JSON.parse(str)
  rescue JSON::ParserError => e
    puts [
      "\nJSON input did not parse properly.",
      "Check that it was wrapped in single quotes or try a JSON validator.\n\n"
      ].join(" ")
    raise e
  end
end

def create_adapters(client, instances_str)
  # Example instance list as a JSON string:
  # '[{"name":"nod-mssql12-win","credential":"mssql_cred"},
  #   {"name":"nod-mssql14-h1a","credential":"mssql_cred"}]'
  instances = json_parse_with_handling(instances_str)
  local_creds = get_needed_credentials(instances)
  vrops_creds = client.get("/api/credentials")
  match_credentials(vrops_creds, local_creds)
  results = {}
  # create and do POST requests
  instances.each do |h|
    req = AdapterRequest.new(h, local_creds).request
    response = client.post("/api/adapters", req)
    if parse_http_response(response, "created", req["name"])
      results[req["name"]] = response["adapter_instance"]["id"]
    end
  end
  puts
  puts "Created Adapter Instances:"
  # results formatted for use with delete and start arguments
  puts "'#{results.to_json}'"
end

def handle_args
  opts = Trollop::options do
    banner "Create, start, and delete vROps SQL Server adapter instances."
    opt :host, "Host", :short => "-o", :required => true, :type => :string
    opt :user, "User", :required => true, :type => :string
    opt :pass, "Password", :type => :string
    opt :create, 
      ["Adapters to create. Format:",
        "[{",
        "  \"name\" : \"target hostname\",",
        "  \"credential\" : \"adapter credential name\",",
        "  \"instance\" : \"SQL Server instance name\", # default: MSSQLSERVER",
        "  \"port\" : \"SQL Server port number\" # default: 1433",
        "}]"
      ].join("\n"),
      :type => :string
    opt :delete, "Adapters to delete", :type => :string
    opt :start, "Adapters to start", :type => :string
  end
  no_request = opts[:create].nil? && opts[:delete].nil? && opts[:start].nil?
  Trollop::die "Create, delete or start argument is required" if no_request
  opts
end

def main
  opts = handle_args
 
  client = RestvROpsClient.new(opts[:host], opts[:user], opts[:pass])
  create = opts[:create]
  delete = opts[:delete]
  start = opts[:start]
  
  if create
    create_adapters(client, create)
  elsif delete
    json_parse_with_handling(delete).each do |name, id|
      response = client.delete("/api/adapters/#{id}")
      parse_http_response(response, "deleted", name)
    end
  elsif start
    json_parse_with_handling(start).each do |name, id|
      response = client.put("/api/adapters/#{id}/monitoringstate/start")
      parse_http_response(response, "started", name)
    end
  end
end

if __FILE__ == $0
  main
end