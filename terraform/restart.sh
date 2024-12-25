#!/bin/bash
if terraform destroy --auto-approve; then
  terraform apply --auto-approve
else
  echo "terraform destroy failed. terraform apply will not be run."
  exit 1
fi