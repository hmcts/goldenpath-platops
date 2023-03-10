# Platform Operations Golden Path

## Welcome to the Group

> The Platform Operations team provides the creation, support, maintenance and enhancement of our Platform services and associated pipelines, with a focus on automation and self-service.  This enables project development and enduring product teams to deliver quality digital products rapidly, supporting the business as well as supporting and enhancing live services to citizens and internal staff.

### More about PlatOps
You can find more information about the team on [DTS Platform Operations](https://tools.hmcts.net/confluence/display/DTSPO/DTS+Platform+Operations) confluence page

## About the Golden Path
The PlatOps Golden path aim is to introduce our engineers to some key areas and technologies stack
that they most certainly will encounter on the project and also provide links to core repositories while walking you through some hands-on
exercise to get you familiar with them and the Azure portal.

#### Core Repositories
- [rdo-terraform-hub](https://github.com/hmcts/rdo-terraform-hub-dmz)
- [hub-panorama-terraform](https://github.com/hmcts/hub-panorama-terraform)
- [azure-platform-terraform](https://github.com/hmcts/azure-platform-terraform)
- [azure-public-dns](https://github.com/hmcts/azure-public-dns)
- [GoldenPath-platops](https://github.com/hmcts/goldenpath-platops)

### The Architecture

![golden-path.png](./images/golden-path.png)

### What you will learn
At the end of this exercise you would have been introduced to the following technologies we use
- Kubernetes
- Flux/Helm
- Palo Alto Firewalls
- Azure Firewall
- Hub and Spoke Network Architecture
- Panorama Management
- GitHub and source control
- Azure DevOps Pipeline
- Azure FrontDoor
- Application Gateway
- DNS Zones

You will have a feel of the HMCTS landscape to help you navigate your way through your epics and tasks.

#### GoldenPath Sections
- [Azure Kubernetes Services - AKS Clusters](1-clusters.md)
- [Firewalls - Azure & Palo Alto](2-firewalls.md)
- [Azure FrontDoor](3-frontdoor.md)
- [Logs](4-logs.md)
- [Clean Up](4-logs.md)

#### GoldenPath HandsOs
To follow the hands on check out the [goldenpath-paltops](https://github.com/hmcts/goldenpath-platops) repo and follow the instructions

### Feedback
We would appreciate your feedback at the end of this exercise. This would help us improve
on this for other engineers. Please leave your on the _#platops-goldenpath_ channel.