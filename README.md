# Flask App on Azure App Service with VNET Integration

A Flask Python application deployed to Azure App Service with VNET integration using Azure Developer CLI (azd) and Azure Verified Modules (AVM).

## Features

- **Azure App Service** (B1 Basic tier) with Python 3.10 runtime
- **VNET Integration** with layered provisioning
- **Application Insights** for monitoring
- **Oryx Build** for automatic deployment
- **Infrastructure as Code** using Bicep with AVM modules

## Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azd-install)
- Azure account with an active subscription ([Create one for free](https://azure.microsoft.com/free/?WT.mc_id=A261C142F))
- Contributor role on your Azure subscription

## Quick Start

```bash
# Clone the repository
git clone https://github.com/puicchan/cat-appservice-vnet
cd cat-appservice-vnet

# Login to Azure
azd auth login

# Provision and deploy
azd up
```

The deployment uses layered provisioning:
1. **Network layer** - Creates VNET with delegated subnet
2. **Main layer** - Deploys App Service Plan, App Service with VNET integration, and Application Insights

## Project Structure

```
.
├── app.py                    # Flask application
├── requirements.txt          # Python dependencies
├── azure.yaml               # azd configuration
├── infra/
│   ├── main.bicep           # Main infrastructure
│   ├── main.parameters.json # Parameters
│   ├── app/
│   │   └── web-appservice-avm.bicep  # App Service module
│   └── network/
│       ├── main.bicep       # Network orchestration
│       ├── vnet.bicep       # VNET with subnet
│       └── nsg.bicep        # Network Security Group
└── templates/               # Flask templates
```

## Architecture

- **App Service Plan**: B1 Basic (Linux)
- **Runtime**: Python 3.10 with Gunicorn
- **VNET**: 10.0.0.0/16 with /23 subnet delegated to `Microsoft.Web/serverFarms`
- **Monitoring**: Application Insights + Log Analytics

## Documentation

For detailed VNET integration patterns and troubleshooting, see the comprehensive guide in `debug/vnet_integration.md` (not pushed to repo, but available locally).
