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

Run `terraform init` to install necessary Terraform packages:

```bash
  terraform init
```

Run `terraform apply` to deploy infrastructure to Aazure:

```bash
  terraform apply
```

Test the VM using the following command:

```
    curl $(az vm list-ip-addresses --name fastify-hello-world --resource-group fastifyResourceGroup --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" | jq -r):3000
```

Expected output:

```json
{
  "hello": "world"
}
```
## Install pre-commit hooks

Before you start, make sure you have the following installed on your machine:

- [Python](https://www.python.org/downloads/) (to use pip)

```bash
  pip install pre-commit
```

## Prerequisites

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

