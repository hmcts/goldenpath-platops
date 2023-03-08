# GoldenPath HandsOn

## Section 1 - Virtual Networks

Checkout [goldenpath-platops](link) repo, cd into the labs-azure-resource folder

### Step 1
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

### Step 2

Run the following command terraform commands
```cmd 
terraform init
```
```cmd 
terraform plan
```
```cmd 
terraform apply
```

Select `yes` to build resource as terraform will prompt you to approve you action

Log into the Azure portal and navigate to the `DTS-SHAREDSERVICES-SBOX` subscription, you should now have similar resources created

![lab](./images/labs-resources.png)

📣 Verify the following
- A Vnet exits
- VNet has two peerings, one to the Hub and the other to the core management vnet
- A route table to one default route to x.x.x.x

Select the virtual network and copy the vnet address cidr e.g. `10.10.7.0/25`

### Step 3. 

Checkout the [hub-panorama-terraform](https://github.com/hmcts/hub-panorama-terraform) repo and create a new branch 

Navigate to `/components/configuration/groups/objects/address-objects/02-addresses-sbox.tf` add a new address object called `labs-goldenpath-<yourname>` in the `02-addresses-sbox.tf` file with the following

```json
 {
   environments = ["sbox"]
   device_group = "sbox"
   name         = "labs-goldenpath-<yourname>"
   value        = "10.10.7.0/25"
}
```
The value should be the cidr address space for your vnet
 
Next navigate to the `/components/groups/policies/secuity-policy-rules/04-policy-rules-sbox/tf` file and
  create a new security policy with the following details
```json
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
```

Ordering of security rules does matter, but you can add this just after the "trusted-default" policy. This is telling the firewall
  to allow traffic coming from the untrusted zone, internet traffic, to your vnet in the trusted zone

### Step 4  

Add your new address object to the `G_Trusted` group. What this does is to allow your vnet communicate with other vnet. e.g. when logged in via the VPN you can ssh via the bastions to your vm
   
To do this navigate to the Address Group folder to `/components/groups/objects/address-gropus/02-address-groups-sbox.tf` add the your new address object to the existing `G_truted` group's `static_addresses` list. 

Example below
```json
 {
   environments = ["sbox"]
   device_group = "sbox"
   name         = "G_trusted"
   static_addresses = [
   ...,
   "labs-goldenpath-<yourname>"
   ]
}
```  

### Step 5
Commit your changes, add relevant details to your PR, review plan and merge 

### Step 6
Log into the [sbox Panorama management](https://panorama-sbox-uks-0.sandbox.platform.hmcts.net) ui and review your changes are in place. 
Note, you need to be on the VPN to access this resource. To find out how to access the VPN if not already done so, please have a
read of this [document](link).

You should now have resources similar to the following:

<details>

<summary>Address Object entry</summary>

<img alt="Address object" src="./images/goldenpath-address.png" width="auto">

</details>

<details>

<summary>Address Group entry</summary>

<img alt="Address group" src="./images/goldenpath-addres-group.png" width="auto">

</details>

<details>

<summary>Security policy entry</summary>

<img alt="Security policy" src="./images/goldenpath-policy.png" width="auto">

</details>


### Step 7
Create an an Azure Firewall DNAT rule (explain why dnat). Checkout the [rdo-terraform-hub-dmz](https://github.com/hmcts/rdo-terraform-hub-dmz) repo

To add a new DNAT rule, navigate to the xxx and add the following snipet, name should be the name of you lab and ip that of your apache server
Use the next available index in your case, you can find this resource in [sbox-int-uksouth-fw](https://portal.azure.com/#@HMCTS.NET/resource/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/hmcts-hub-sbox-int/providers/Microsoft.Network/azureFirewalls/sbox-int-uksouth-fw/rules)
```json
{
   name : "labsgoldenpathfelix",
   palo_ips : {
   "uksouth" : "10.10.7.4",
   "ukwest" : "10.10.7.4"
   },
   port : [80,]
   index : 6
}
``` 

📣**Note:** Adding the `ukwest` option is not necessary in this instance as the resource of built in `uksouth` only.

Commit your PR, review your plan and merge.

Go to the Azure portal and review your changes in the [sbox-int-uksouth-fw](https://portal.azure.com/#@HMCTS.NET/resource/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/hmcts-hub-sbox-int/providers/Microsoft.Network/azureFirewalls/sbox-int-uksouth-fw/overview)
This will create a new public Ip address, you can verify your new IP by looking at the IP configuration in the `IP Configuration` menu right of
the firewall menu you should see something similar to `fw-uksouth-sbox-int-palo-labsgoldenpathfelix-pip`. 

Resources would be similar to the following:

<details>

<summary>IP Configuration</summary>

<img alt="IPs" src="./images/ip-configuration.png" width="auto">

</details>

<details>

<summary>Azure Firewall rules</summary>

<img alt="DNAT rule" src="./images/az-fw-rule.png" width="auto">

</details>

📣 Keep a note of the public IP address

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