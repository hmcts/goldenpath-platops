# GoldenPath HandsOn

## Section 1 - Virtual Networks

Checkout [goldenpath-platops](link) repo, cd into the labs-azure-resource folder

Run the following commands to confirm you are in the right repository
```cmd 
az login
```

```cmd
az account show
``` 
```cmd
az account set --subscription DTS-SHAREDSERVICES-SBOX
```

```cmd
az account show
```

NOTE: run once, a re-run will rebuild

2. run the following command
   terraform init
   terraform plan
   terraform apply

seletct yes to build resource

you should have the following resources created

select the virtual network and copy the vnet address cidr e.g. 10.10.7.0/25

3. Checkout the hub-panorama-terraform repo and create a new branch
   navigate to the address object under create a new address object call labs-goldenpath-yourname with the following
   /components/groups/objects/address-objects/02-addresses-sbox.tf     
    {
   environments = ["sbox"]
   device_group = "sbox"
   name         = "labs-goldenpath-<yourname>"
   value        = "10.10.7.0/25"
   }
    The value should be the cidr address space for your vnet
 
  Next navigate to the /components/groups/policies/secuity-policy-rules/04-policy-rules-sbox/tf and
  create a new security policy
     {
     environments          = ["sbox"]
     device_group          = "sbox"
     name                  = "labs-goldenpath-<yourname>"
     source_zones          = [var.zone_untrusted]
     destination_zones     = [var.zone_trusted]
     source_addresses      = ["any"]
     destination_addresses = ["labs-goldenpath-<yourname>"]
     services              = ["service-http"]
     action                = "allow"
     disabled              = false
     }
     ]
 Ordering of security rules does mater, but you can add this just after the "trusted-default" policy. This is telling the firewall
  to allow traffic coming from the untrusted zone, internet traffic, to your vnet in the trusted zone
  
4. Add your new address object to the G_Trusted group. What this does is to allow your vnet communicate with other vnet. e.g. when logged in
   via the VPN you can ssh via the bastions to your vm
   
   Navigate to the Address Group folder to /components/groups/objects/address-gropus/02-address-groups-sbox.tf
   add the following code
   {
   environments = ["sbox"]
   device_group = "sbox"
   name         = "G_trusted"
   static_addresses = [
   ...,
   "labs-goldenpath-felix"
   ]
   }

5. Commit your changes, add relevant details to your PR, review plan and merge
6. Log into the Panorama managemt ui and review your changes are in place
   To test that your rule will match the request type do the following xxxx
7. Add an Azure Firewall DNAT rule (explain why dnat)
    Checkout the rdo-terraform-hub-dmz repo
   To add a new DNAT rule, navigate to the xxx and add the foloowing snipet, name should be the name of you lab and ip that of your apache server
   use the next available index in your case, you can find this resource in [sbox-int-uksouth-fw](https://portal.azure.com/#@HMCTS.NET/resource/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/hmcts-hub-sbox-int/providers/Microsoft.Network/azureFirewalls/sbox-int-uksouth-fw/rules)
   {
   name : "labsgoldenpathfelix",
   palo_ips : {
   "uksouth" : "10.10.7.4",
   "ukwest" : "10.10.7.4"
   },
   port : [80,]
   index : 6
   }

This will create a new public Ip address, you can verify your new IP by looking at the pi configuration in the IP Configuration menu right of
the firewall menu you should see something similar to `fw-uksouth-sbox-int-palo-labsgoldenpathfelix-pip`. Copy the Ip address

8. Create a Public DNS record. 
    Checkout the [azure-public-dns](https://github.com/hmcts/azure-public-dns)
   Navigate to /environments/sandbox.yml
   add a new CNAME record using Azure Frontdoor url hmcts-sbox.azurefd.net create from above step

CNAME:
...
- name: "labs-goldenpath-felix"
  ttl: 300
  record: "hmcts-sbox.azurefd.net"

9. Create a Frontdoor
   Check out the [azure-platform-terraform](https://github.com/hmcts/azure-platform-terraform) repo


## Section 2 - AKS Cluster


## Section 3 - Clean Up
Tear down

- You need to disassociate the pip from the Azure firewall
- If running from local, run terraform destroy to remove all resourcs in your resourse group
- For all the other PR's create create new once removing only the bit you added then commit, review plan then merged