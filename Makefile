run: stop start exec

up: fmt plan apply

start:
	docker run -it -d -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/work -v $$PWD/creds:/root/.aws -v terraform-plugin-cache:/plugin-cache -w /work --name pawst bryandollery/terraform-packer-aws-alpine

exec:
	docker exec -it pawst bash || true

stop:
	docker rm -f pawst 2> /dev/null || true

init:
	rm -rf .terraform ssh
	mkdir ssh
	time terraform init
	ssh-keygen -t rsa -f ./ssh/id_rsa -q -N ""

plan:
	time terraform plan -out plan.out

apply:
	time terraform apply plan.out

cnct:
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs) rm -f /home/ubuntu/id_rsa
	scp -i ssh/id_rsa ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs):~
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs) chmod 400 /home/ubuntu/id_rsa
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs)

fmt:
	time terraform fmt -recursive
