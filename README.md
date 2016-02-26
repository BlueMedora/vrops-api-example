# Using the vRealize Operations Manager REST API

### What is This?

This script is an example of how to use the vRealize Operations (vROps) Manager REST API, [as featured in this VMware Cloud Management blog post](http://blogs.vmware.com/management/2016/02/straight-up-flying-with-the-vrealize-operations-rest-api.html). In this case, the API is accessed directly via HTTP using [Ruby](https://www.ruby-lang.org/). Because this is a standard REST API (thoroughly documented at `https://{your-vrealize-host}/suite-api/`), this example can be translated into the language of your preference, from simple [cURL](https://curl.haxx.se/) calls to C, to Haskell. The are no Ruby dependencies in the API.

When run, this script produces a list of all the adapter kinds and instances on a vRealize Operations system.

### Running the Script

To run the script, you will need a system with Ruby (OS X and Linux have it by default) and [Bundler](http://bundler.io/) installed. You will also need a vROps instance to point the script, and vROps use with API access enabled.

With those prerequisites out of the way, you will need to clone this repository and run `bundle` in the repo directory once:

- `bundle install`

This will download and install the three Ruby gems used in this script.

Now you can run the script (omitting the brackets):

- `ruby mp-instances.rb -o [vrops-hostname] -u [vrops-username]`

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
  mysql56-rh7 : mysql56-rh7.bluemedora.localnet
NetAppAdapter instances:
  netapp_ai : netapp-521-d.bluemedora.localnet
POSTGRESQL_ADAPTER instances:
  pg92-rh6-3_ai : pg92-rh6-3.bluemedora.localnet
SqlServerAdapter instances:
  mssql-d2-ai : mssql-d2.bluemedora.localnet
  mssql12-c3_ai : 10.66.3.227
VMWARE instances:
  triton : triton-vcsa.bluemedora.localnet
  zeus : zeus.bluemedora.localnet
vCenter Operations Adapter instances:
  vRealize Operations Manager Adapter : N/A
```

See [bluemedora.com](http://bluemedora.com/) for blogs and vRealize Operations management packs.