help:
  @just --list

lint:
    terraform fmt -diff -recursive -check .
    terraform init -backend=false -input=false >/dev/null
    terraform validate

format-terraform:
    terraform fmt -write -recursive .
