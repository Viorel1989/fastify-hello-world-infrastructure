# Infrastructure code for the fastify-hello-world repo
This repository contains the infrastructure code for deploying the [Fastify Hello world](https://github.com/Viorel1989/fastify-hello-world) application.


## Run locally

Clone the project:

```bash
  git clone https://github.com/Viorel1989/fastify-hello-world-infrastructure.git
```

Go to the project directory:

```bash
  cd fastify-hello-world-infrastructure
```

Run `terraform init` to install necessary Terraform packages and backend configuration parameters:

```bash
  terraform init \
   -backend-config="storage_account_name=your-tf-storage-account-name"
```

Run `terraform apply` to deploy infrastructure to Aazure (if no port variable is passed tf will use default):

```bash
  terraform apply -var="ssh_user=$USER" -var="source_image_name={{SOURCE_IMAGE_NAME}}"
```

Test the VM using the following command:

```
    curl http://$(az vm list-ip-addresses --name fastifyVM --resource-group fastifyResourceGroup --query "[1].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv):3000

```

Expected output:

```json
{
  "hello": "world"
}
```

Destroy the VM using the following command:

```
    terraform destroy -var="ssh_user=$USER" -var="source_image_name={{SOURCE_IMAGE_NAME}}"

```

## Install pre-commit hooks

Before you start, make sure you have the following installed on your machine:

- [Python](https://www.python.org/downloads/) (to use pip)

```bash
  pip install pre-commit
```

## Prerequisites

Storage account for terraform state file

https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli#2-configure-remote-state-storage-account

```bash
STORAGE_ACCOUNT_NAME=tfstate$(openssl rand -hex 4)
CONTAINER_NAME=tfstate

az provider register --namespace 'Microsoft.Storage'
az storage account create --resource-group fastifyResourceGroup --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
```

Precommit installed to run pre-commit hooks

```bash
pip install pre-commit
pre-commit --version
pre-commit install
```
Install tflint and trivy locally in order for tflint pre-commit hook to run

https://github.com/terraform-linters/tflint

https://github.com/aquasecurity/trivy

## Optimizations

- Installed Commitizen as pre-commit hook to ensure Semantic Versioning and Conventional Commits specifications

- Added pre-commit hooks for Terraform:

    - terraform_fmt for formatting Terraform code
    - terraform_validate for validating Terraform configuration
    - terraform_tflint for linting Terraform code
    - terraform_trivy for scanning Terraform configurations for vulnerabilities

## Acknowledgements

- [Semantic Versioning](https://semver.org/)
- [Commitizen tool](https://commitizen-tools.github.io/commitizen/)
- [Conventional commit standard](https://www.conventionalcommits.org/)
- [Pre-commit documentation](https://pre-commit.com/)

