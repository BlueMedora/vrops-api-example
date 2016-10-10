# Using the vRealize Operations Manager REST API

### What is This?

These scripts are examples of using the vRealize Operations (vROps) Manager REST API, [as featured on the VMware Cloud Management blog](http://blogs.vmware.com/management/2016/02/straight-up-flying-with-the-vrealize-operations-rest-api.html). In this case, the API is accessed directly via HTTP using [Ruby](https://www.ruby-lang.org/). Because this is a standard REST API (thoroughly documented at `https://{your-vrealize-host}/suite-api/`), this example can be translated into the language of your preference, from simple [cURL](https://curl.haxx.se/) calls to C, to Haskell. The are no Ruby dependencies in the API.

The basic example produces a list of all the adapter kinds and instances on a vRealize Operations system. The [advanced example](http://blogs.vmware.com/management/2016/03/blast-off-advanced-usage-of-the-vrealize-operations-rest-api.html) creates, starts and deletes SQL Server adapter instances.

### Prerequisites

To run the scripts, you will need a system with Ruby (OS X and Linux have it by default) and (for ease of use) [Bundler](http://bundler.io/) installed. You will also need a vROps instance to point the scripts at. For the basic example, you'll need a vROps user with API Access enabled. For the advanced, you'll need a full admin.

You will then need to clone this repository and run `bundle` in the repo directory:

`bundle install`

This will download and install the Ruby gems used in these scripts.

You are now ready for the...

### Basic Example

The basic example lists the adapters on your vROps system. Open a terminal and:

```
cd path/to/local/repo/vrops-api-example
ruby basic/mp-instances.rb -o vrops-hostname -u vrops-username
```

You will be prompted for the password. Your output will look like this:

```
Password?
CiscoNexusAdapter instances:
  nexus_ai_1 : 10.66.1.15/32
CiscoUcsAdapter instances:
  ucs_ai : 10.66.4.120
Container instances:
  Container : N/A
DellComputeAdapter instances:
  Dell_ai : 10.66.3.137/32
EP Ops Adapter instances:
  EP Ops adapter - a5e7ce6d-94b5-46c5-b01d-bcad7dfb8713 : N/A
MySQLAdapter instances:
  mysql56-rh7 : mysql56-rh7
[...]
```

### Advanced Example

The advanced example will create, start, and/or delete adapter instances.

To use this example as written, you will need the vRealize Operations Management Pack for SQL Server. It's available for a free trial from [Blue Medora](http://www.bluemedora.com/products/vrops-management-pack-for-microsoft-sql-server/). You will also need to gather hostnames for some SQL Servers you have laying around (port and instance names, too, if not default). From there, you'll set up a vROps credential for SQL Server targets, and put together a JSON string in this format:

```
[
  {
    "name":"nod-mssql12-win", 
    "credential":"mssql_cred"
  }, 
  {
    "name":"nod-mssql14-h1a", 
    "credential":"mssql_cred", 
    "instance":"SQLSERVERENT", 
    "port":"11433"
  }
]
```

To create the adapter instances

```
cd path/to/local/repo/vrops-api-example
ruby advanced/makeadapters.rb -o your-vrops-host -u your-vrops-username --create \
'[{"name":"nod-mssql12-win","credential":"mssql_cred"}, {"name":"nod-mssql14-h1a","credential":"mssql_cred"}]'
```

If successful, your output will look like this:

```
Password for admin?
nod-mssql12-win_ai successfully created (HTTP status code: 201)
nod-mssql14-h1a_ai successfully created (HTTP status code: 201)

Created Adapter Instances:
'{"nod-mssql12-win_ai":"b4604a7b-c0ba-45b4-8169-555655216800","nod-mssql14-h1a_ai":"1ead16e1-0718-48e3-b4ed-b216fc353bd4"}'
```

The JSON from the `--create` output can then be used for `--start` and `--delete` requests.

To start the adapters:

```
ruby advanced/makeadapters.rb -o your-vrops-host -u your-vrops-username --start \
'{"nod-mssql12-win_ai":"b4604a7b-c0ba-45b4-8169-555655216800","nod-mssql14-h1a_ai":"1ead16e1-0718-48e3-b4ed-b216fc353bd4"}'
```

To delete the adapters:

```
ruby advanced/makeadapters.rb -o your-vrops-host -u your-vrops-username --delete \
'{"nod-mssql12-win_ai":"b4604a7b-c0ba-45b4-8169-555655216800","nod-mssql14-h1a_ai":"1ead16e1-0718-48e3-b4ed-b216fc353bd4"}'
```

-

See [bluemedora.com](http://bluemedora.com/) for blogs and vRealize Operations management packs.