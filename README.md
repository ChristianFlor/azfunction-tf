# azfunction-tf

Infrastructure as Code (IaC) project for Microsoft Azure, built with [Terraform](https://www.terraform.io/) and the [`azurerm`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) provider.

The project provisions two independent pieces of infrastructure inside the same Azure Resource Group:

1. **An Azure Function App** (Windows, Consumption plan, Node.js) exposing an anonymous HTTP-triggered function.
2. **A Linux Virtual Machine** (Ubuntu 24.04 LTS) with its own virtual network, public IP, network security group and SSH access.

This README documents (a) everything that was built and why, and (b) a full, reproducible, step-by-step guide to deploy the stack from scratch.

---

## Table of contents

- [Architecture](#architecture)
- [Repository structure](#repository-structure)
- [What was built — step by step](#what-was-built--step-by-step)
  - [1. Azure Function App](#1-azure-function-app)
  - [2. Linux Virtual Machine](#2-linux-virtual-machine)
- [Prerequisites](#prerequisites)
- [Deployment guide](#deployment-guide)
  - [1. Clone the repository](#1-clone-the-repository)
  - [2. Authenticate against Azure](#2-authenticate-against-azure)
  - [3. Generate an SSH key pair (for the VM)](#3-generate-an-ssh-key-pair-for-the-vm)
  - [4. Create your variables file](#4-create-your-variables-file)
  - [5. Initialize Terraform](#5-initialize-terraform)
  - [6. Validate and format the code](#6-validate-and-format-the-code)
  - [7. Plan the deployment](#7-plan-the-deployment)
  - [8. Apply the deployment](#8-apply-the-deployment)
  - [9. Verify the Function App](#9-verify-the-function-app)
  - [10. Connect to the Virtual Machine](#10-connect-to-the-virtual-machine)
  - [11. Destroy the infrastructure](#11-destroy-the-infrastructure)
- [Input variables reference](#input-variables-reference)
- [Outputs reference](#outputs-reference)
- [Managing multiple environments](#managing-multiple-environments)
- [State management](#state-management)
- [Security considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Infrastructure as Code notes](#infrastructure-as-code-notes)

---

## Architecture

```
                         Resource Group (azurerm_resource_group.rg)
                         ─────────────────────────────────────────
   ┌───────────────────────────────────────────┐   ┌──────────────────────────────────────────────┐
   │              Function App stack             │   │                   VM stack                    │
   │                                             │   │                                                │
   │  Storage Account (azurerm_storage_account)  │   │  Virtual Network 10.0.0.0/16 (azurerm_virtual_ │
   │           │                                 │   │  network)                                      │
   │           ▼                                 │   │           │                                    │
   │  Service Plan "Y1" - Consumption            │   │           ▼                                    │
   │  (azurerm_service_plan)                     │   │  Subnet 10.0.1.0/24 (azurerm_subnet)            │
   │           │                                 │   │           │                                    │
   │           ▼                                 │   │           ▼                                    │
   │  Windows Function App, Node ~18             │   │  Network Interface (azurerm_network_interface)  │
   │  (azurerm_windows_function_app)             │   │      │                    │                     │
   │           │                                 │   │      ▼                    ▼                     │
   │           ▼                                 │   │  Public IP (Static,   Network Security Group     │
   │  HTTP-triggered function "index.js"         │   │  Standard SKU)        (allows inbound TCP/22)    │
   │  (azurerm_function_app_function)            │   │      │                    │                     │
   │           │                                 │   │      └────────┬───────────┘                     │
   │           ▼                                 │   │                ▼                                │
   │  Public invocation URL (HTTP GET/POST)      │   │  Linux VM - Ubuntu 24.04 LTS (Standard_B1s)     │
   │                                             │   │  SSH key-based auth only                        │
   └───────────────────────────────────────────┘   └──────────────────────────────────────────────┘
```

Both stacks share the **same resource group** (`azurerm_resource_group.rg`, named after `var.name_function`) so that everything related to this exercise can be located and destroyed together.

## Repository structure

```
.
├── main.tf              # Resource group, storage account, service plan, Function App and function
├── variables.tf         # Input variables for the Function App stack
├── outputs.tf           # Outputs for the Function App stack
├── vm.tf                # Virtual network, subnet, NSG, public IP, NIC and Linux VM
├── vm-variables.tf      # Input variables for the VM stack
├── vm-outputs.tf        # Outputs for the VM stack
├── example/
│   └── index.js         # Source code of the HTTP-triggered Azure Function
├── dev.tfvars           # Environment-specific variable values (gitignored, you create this)
├── .terraform.lock.hcl  # Provider dependency lock file
└── .gitignore           # Ignores .terraform/, *.tfstate*, *.tfvars, etc.
```

> Terraform automatically loads **every** `*.tf` file in the working directory, regardless of its file name. Splitting the code into `main.tf` / `vm.tf`, `variables.tf` / `vm-variables.tf` and `outputs.tf` / `vm-outputs.tf` is purely for readability — at plan/apply time everything is merged into a single configuration.

## What was built — step by step

This reflects the actual evolution of the project (see `git log`):

### 1. Azure Function App

1. **Provider configuration** (`main.tf`): the `azurerm` provider is declared with an empty `features {}` block, which is mandatory for the provider even when no feature flags are customized.
2. **Resource Group** (`azurerm_resource_group.rg`): the parent container for every resource in the project. Its name and location come from the `name_function` and `location` variables.
3. **Storage Account** (`azurerm_storage_account.sa`): Azure Functions require an associated Storage Account to store triggers, logs and function keys. `Standard` tier with `LRS` (locally redundant) replication was chosen to keep costs low, since this is a learning/demo project.
4. **Service Plan** (`azurerm_service_plan.sp`): defines the hosting tier for the Function App. `sku_name = "Y1"` is the **Consumption plan** — you only pay per execution, and Azure scales the app in and out automatically.
5. **Windows Function App** (`azurerm_windows_function_app.wfa`): the app itself, linked to the storage account and the service plan, running the Node.js `~18` runtime stack.
6. **Function App Function** (`azurerm_function_app_function.faf`): a single HTTP-triggered function:
   - Source code is uploaded inline from `example/index.js` using Terraform's `file()` function.
   - `config_json` defines the `bindings`: an anonymous (`authLevel = "anonymous"`) HTTP trigger that accepts `GET` and `POST`, and an HTTP output binding.
   - `test_data` provides a default JSON payload (`{"name": "Azure"}`) used when testing the function from the Azure Portal.
   - The function logic (`example/index.js`) reads a `name` parameter from the query string or request body and echoes it back as `{"id": name}`; if no name is provided it returns a default greeting message.
7. **Output** (`outputs.tf`): exposes the public `invocation_url` of the deployed function so it can be called immediately after `terraform apply`.

### 2. Linux Virtual Machine

Added later (`vm.tf`, `vm-variables.tf`, `vm-outputs.tf`) to extend the exercise with classic IaaS networking and compute, reusing the same resource group created above:

1. **Virtual Network** (`azurerm_virtual_network.vnet`): address space `10.0.0.0/16`.
2. **Subnet** (`azurerm_subnet.subnet`): carved out of the VNet as `10.0.1.0/24`.
3. **Public IP** (`azurerm_public_ip.pip`): `Static` allocation with `Standard` SKU (required to pair with a Standard NIC/NSG setup and to keep the address stable across restarts).
4. **Network Security Group** (`azurerm_network_security_group.nsg`): a single inbound rule (`PermitirSSH`) allowing TCP/22 from `var.allowed_ssh_cidr` (defaults to `0.0.0.0/0` — see [Security considerations](#security-considerations)).
5. **Network Interface** (`azurerm_network_interface.nic`): binds the subnet and the public IP together with dynamic private IP allocation.
6. **NSG ↔ NIC association** (`azurerm_network_interface_security_group_association.nic_nsg`): attaches the security group to the network interface.
7. **Linux Virtual Machine** (`azurerm_linux_virtual_machine.vm`):
   - Image: `Canonical / ubuntu-24_04-lts / server / latest`.
   - Size: `Standard_B1s` by default (burstable, low-cost, ideal for demos/labs).
   - Authentication: **SSH key only** — `disable_password_authentication = true` and `admin_ssh_key` reads the public key from `var.ssh_public_key_path` (`~/.ssh/id_rsa.pub` by default) via `file(pathexpand(...))`.
   - OS disk: `Standard_LRS`, `ReadWrite` caching.
8. **Outputs** (`vm-outputs.tf`): the VM's public IP address and a ready-to-use `ssh` command string.

---

## Prerequisites

Install and configure the following before deploying:

| Tool | Purpose | Suggested version |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | IaC engine | ≥ 1.5 (tested with 1.16) |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | Authentication against Azure | latest |
| An active **Azure subscription** | Target cloud environment | — |
| SSH client (`ssh`, `ssh-keygen`) | Generate keys and connect to the VM | OpenSSH |
| `git` | Clone/version the repository | latest |

Verify your tooling:

```bash
terraform -version
az --version
ssh -V
```

## Deployment guide

### 1. Clone the repository

```bash
git clone <repository-url>
cd azfunction-tf
```

### 2. Authenticate against Azure

```bash
az login
```

This opens a browser window to sign in. If you have access to more than one subscription, select the one you want Terraform to use:

```bash
az account list --output table
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
```

Terraform's `azurerm` provider reuses the Azure CLI session automatically — no extra credentials need to be set as environment variables for local/interactive use.

### 3. Generate an SSH key pair (for the VM)

If you don't already have one at `~/.ssh/id_rsa.pub`:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

If you use a different path or key type (e.g. `ed25519`), set `ssh_public_key_path` accordingly in your `.tfvars` file (step below).

### 4. Create your variables file

`*.tfvars` files are intentionally excluded from version control (see `.gitignore`) because they can hold environment-specific and potentially sensitive values. Create your own, for example `dev.tfvars`:

```hcl
# Function App
# NOTE: name_function is also used as the Storage Account name,
# so it must be lowercase letters/numbers only, max 24 characters.
name_function = "azfunctionmyname"
location      = "East US"

# Virtual Machine
name_vm             = "vm-myname"
vm_size             = "Standard_B1s"
admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
allowed_ssh_cidr     = "0.0.0.0/0"   # restrict this to your own IP/CIDR — see Security considerations
```

> `name_function` must be **globally unique** across Azure (it becomes the Storage Account name too), 3–24 characters, lowercase letters and digits only.

### 5. Initialize Terraform

Downloads the `azurerm` provider plugin and sets up the local backend:

```bash
terraform init
```

### 6. Validate and format the code

```bash
terraform fmt -check
terraform validate
```

### 7. Plan the deployment

Review exactly what will be created before touching real infrastructure:

```bash
terraform plan -var-file="dev.tfvars"
```

### 8. Apply the deployment

```bash
terraform apply -var-file="dev.tfvars"
```

Review the plan Terraform prints, type `yes` to confirm. Provisioning typically takes 2–5 minutes (the Function App and VM are created in parallel where possible).

On success, Terraform prints the outputs, e.g.:

```
Outputs:

url                = "https://azfunctionmyname.azurewebsites.net/api/azfunctionmyname?code=..."
vm_ip_publica      = "20.xxx.xxx.xxx"
vm_comando_ssh     = "ssh azureuser@20.xxx.xxx.xxx"
```

### 9. Verify the Function App

Call the deployed HTTP endpoint (the `url` output already includes the function key):

```bash
curl "$(terraform output -raw url)"
curl "$(terraform output -raw url)&name=Azure"
```

Expected responses:

```
This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.
```

```json
{"id":"Azure"}
```

You can also invoke and test the function directly from the **Azure Portal** → Function App → Functions → your function → *Code + Test* → *Test/Run*, using the pre-loaded `test_data` payload (`{"name": "Azure"}`).

### 10. Connect to the Virtual Machine

```bash
terraform output vm_comando_ssh
# or directly:
ssh azureuser@$(terraform output -raw vm_ip_publica)
```

The first connection will ask you to confirm the host's SSH fingerprint — type `yes`.

### 11. Destroy the infrastructure

To avoid ongoing Azure charges, tear everything down when you are done:

```bash
terraform destroy -var-file="dev.tfvars"
```

Confirm with `yes` when prompted. This removes the resource group and every resource inside it (Storage Account, Service Plan, Function App, VNet, NSG, Public IP, NIC and VM).

---

## Input variables reference

### Function App (`variables.tf`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `name_function` | `string` | — (required) | Name used for the Resource Group, Storage Account and Function App. Must be lowercase alphanumeric, ≤ 24 chars. |
| `location` | `string` | `"West Europe"` | Azure region where all resources are deployed. |

### Virtual Machine (`vm-variables.tf`)

| Variable | Type | Default | Description |
|---|---|---|---|
| `name_vm` | `string` | — (required) | Base name for the VM and its associated networking resources (VNet, subnet, NIC, public IP, NSG). |
| `vm_size` | `string` | `"Standard_B1s"` | Azure VM size/SKU. `B1s` is a low-cost burstable size, good for demos. |
| `admin_username` | `string` | `"azureuser"` | Admin/login user created on the VM. |
| `ssh_public_key_path` | `string` | `"~/.ssh/id_rsa.pub"` | Local path to the SSH **public** key installed on the VM. |
| `allowed_ssh_cidr` | `string` | `"0.0.0.0/0"` | CIDR block allowed to reach TCP/22 on the VM's NSG. |

## Outputs reference

| Output | Source file | Description |
|---|---|---|
| `url` | `outputs.tf` | Public invocation URL (including function key) of the HTTP-triggered function. |
| `vm_ip_publica` | `vm-outputs.tf` | Public IP address assigned to the VM. |
| `vm_comando_ssh` | `vm-outputs.tf` | Ready-to-use `ssh` command to connect to the VM. |

Retrieve any output at any time with:

```bash
terraform output
terraform output -raw <output_name>
```

## Managing multiple environments

Keep one `.tfvars` file per environment (all gitignored) and select it explicitly at plan/apply time:

```
├── dev.tfvars
├── stage.tfvars
├── prod.tfvars
```

```bash
terraform plan  -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

Recommendation: use smaller/cheaper SKUs (`Y1` service plan, `Standard_B1s` VM) in `dev`, and size up (Premium plan, larger VM SKU, restricted `allowed_ssh_cidr`) for `stage`/`prod`.

## State management

By default this project uses Terraform's **local backend** (`terraform.tfstate` on disk, already gitignored). For anything beyond individual experimentation, migrate to a **remote backend** so state is shared safely across a team, for example an Azure Storage Account container:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccountname"
    container_name       = "tfstate"
    key                  = "azfunction-tf.tfstate"
  }
}
```

Enable versioning and restrict access on that storage account, since the state file can contain sensitive values (connection strings, keys) in plain text.

## Security considerations

- **SSH exposure**: `allowed_ssh_cidr` defaults to `0.0.0.0/0` (open to the internet) for convenience in a lab environment. In any shared or long-lived environment, restrict it to your own public IP (`curl ifconfig.me`) or your office/VPN CIDR, e.g. `"203.0.113.10/32"`.
- **Key-based auth only**: password authentication is explicitly disabled on the VM (`disable_password_authentication = true`); never re-enable it without also removing/limiting SSH exposure.
- **Anonymous HTTP trigger**: the Azure Function uses `authLevel = "anonymous"`. Anyone with the function URL can invoke it. For anything beyond a demo, switch to `authLevel = "function"` (per-function key) or put the Function App behind Azure API Management / Easy Auth.
- **Secrets and `.tfvars`**: never commit `*.tfvars` files or `terraform.tfstate` — both are already excluded via `.gitignore`. Treat outputs like `url` (which embeds a function key) as sensitive.
- **Least privilege**: use an Azure AD service principal with only the RBAC roles needed (e.g. `Contributor` scoped to a single resource group) when running Terraform from CI/CD, instead of a broad user account.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Error: A resource with the ID ... already exists` | Resource with the same name already exists in Azure (e.g. reused `name_function`). | Choose a unique `name_function`/`name_vm`, or `terraform import` the existing resource. |
| `Error: Storage Account name must be ... alphanumeric` | `name_function` contains uppercase letters, dashes or is too long. | Use lowercase letters/digits only, ≤ 24 characters. |
| `Error: open ~/.ssh/id_rsa.pub: no such file or directory` | SSH key hasn't been generated, or path is wrong. | Run `ssh-keygen` (step 3) or fix `ssh_public_key_path`. |
| `az` commands fail with `Please run 'az login'` | Not authenticated / expired session. | Re-run `az login` and `az account set`. |
| SSH connection times out | `allowed_ssh_cidr` doesn't include your current public IP, or NSG rule not yet propagated. | Update `allowed_ssh_cidr` and re-apply; wait ~30s after apply. |
| Function returns `401`/`403` | Missing or wrong function key in the URL. | Use `terraform output -raw url`, which already includes the key. |

---

## Infrastructure as Code notes

General IaC principles and Terraform fundamentals followed in this project:

### Infrastructure as Code principles

- **Use definition files**: every IaC tool has its own format to describe infrastructure — here, Terraform's HCL (`*.tf` files).
- **Self-documenting processes and systems**: code is reused across people and time, so it must be documented well enough that others understand what each module does.
- **Version everything**: version control lets you trace every change and roll back to a known-good state if something breaks.
- **Prefer small changes**: smaller changes are easier to review and limit blast radius.
- **Keep services continuously available**: design changes so they don't require downtime.

### Benefits of Infrastructure as Code

- **Fast, on-demand provisioning**: a single definition file captures all configuration, so the same infrastructure can be recreated any number of times with minimal extra effort.
- **Automation**: once the definition exists, CI/CD tools can apply it automatically.
- **Visibility and traceability**: every change to the infrastructure is versioned and reviewable.
- **Homogeneous environments**: multiple environments can be created from the same definition, changing only a handful of parameters (see [Managing multiple environments](#managing-multiple-environments)).

### Best practices

- **Modularity**: split infrastructure into reusable modules to ease maintenance and scaling.
- **Centralized configuration**: use variables and `.tfvars` files instead of hardcoded values.
- **Safe state handling**: store `terraform.tfstate` remotely (e.g. Azure Storage with versioning) — see [State management](#state-management).
- **Code review / pull requests**: review meaningful infrastructure changes via PRs before applying them.

### Variable management in Terraform

To keep the definition file scalable and reusable, avoid hardcoded values. Terraform supports several variable types:

- `string`
- `number`
- `bool`
- `map`
- `list`

If no type is declared, Terraform infers it — but explicitly declaring the type is a best practice (see `variables.tf` and `vm-variables.tf` in this repo).

Variable values can be provided in three ways:

1. Environment variables (`TF_VAR_<name>`).
2. Command-line flags (`-var="key=value"`).
3. A `.tfvars` file (`key = value`), passed with `-var-file`.

### Destroying the infrastructure

```bash
terraform destroy -var-file="dev.tfvars" -auto-approve
```

Use `-auto-approve` with caution — it skips the interactive confirmation prompt.
