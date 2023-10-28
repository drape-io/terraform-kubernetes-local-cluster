VERSION 0.7
########################
# ci
########################
ci-terraform-lint:
    FROM +terraform-deps
    COPY --dir . src/
    RUN terraform fmt -diff -recursive -check src/

########################
# Terraform
########################
terraform-deps:
    ARG TERRAFORM_VERSION="1.5.7"
    FROM hashicorp/terraform:$TERRAFORM_VERSION