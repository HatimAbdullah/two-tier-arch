all: stop exportvar start exec

exportvar:
	export $$(tail -n +2 /work/creds/credentials)

start:
	docker run --env aws_access_key_id=$$aws_access_key_id --env aws_secret_access_key=$$aws_secret_key_id -it --rm -d -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/work -w /work --name pawst bryandollery/terraform-packer-aws-alpine

exec:
	docker exec -it pawst bash || true

stop:
	docker rm -f pawst 2> /dev/null || true

build:
	packer build packer.json
