TERRAFORM=terraform
FLAGS=-input=false -var-file=main.tfvars

init:
	$(TERRAFORM) init $(FLAGS)

plan:
	$(TERRAFORM) plan $(FLAGS)

apply:
	$(TERRAFORM) apply $(FLAGS) -auto-approve

refresh:
	$(TERRAFORM) refresh $(FLAGS)

destroy:
	$(TERRAFORM) destroy $(FLAGS) -auto-approve

cancel-fleet-request:
	aws ec2 cancel-spot-fleet-requests \
		--spot-fleet-request-id $(shell terraform output -raw spot_fleet_request_id) \
		--terminate-instances
