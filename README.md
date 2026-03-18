# Azure Virtual Desktop (AVD) Infrastructure as Code Lab

This repository contains a modular **Infrastructure as Code (IaC)** deployment for an Azure Virtual Desktop environment using **Bicep**. The project is designed as a laboratory to practice automated deployments of scalable virtual desktop infrastructures on Microsoft Azure.

## 🏗️ Architecture Overview

The project follows a modular approach to ensure reusability and clean code practices. It orchestrates the deployment of the core components required for a functional AVD host pool.

### Core Modules:
* **`main.bicep`**: The primary orchestrator that manages parameters, variables, and module dependencies.
* **`modules/network.bicep`**: Deploys the Virtual Network (VNet) and a dedicated Subnet for the Session Hosts.
* **`modules/storage.bicep`**: Configures a Storage Account and an Azure File Share specifically for **FSLogix** profile management, including a 5GB quota to optimize costs during the lab phase.

## 🚀 Key Features

* **Modular Design**: Separation of concerns between networking and storage.
* **Cost Optimization**: Implemented storage quotas to prevent unexpected billing.
* **Automated Deployment**: Ready to be deployed via Azure CLI or PowerShell.
* **Best Practices**: Use of parameters and outputs to maintain a dynamic and flexible infrastructure.

## 🛠️ Getting Started

### Prerequisites
* An active **Azure Subscription**.
* **Azure CLI** installed or access to **Azure Cloud Shell**.
* **Bicep CLI** installed.

### Deployment Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/Lab-AVD-Bicep.git](https://github.com/YOUR_USERNAME/Lab-AVD-Bicep.git)
   cd Lab-AVD-Bicep
