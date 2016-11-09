---
layout: default
deployDoc: true
---

## Sock Shop via Docker Swarm(Single-Node)

Please refer to the [new Docker Swarm introduction](http://container-solutions.com/hail-new-docker-swarm/)

### Blockers

Currently, new Docker Swarm does not support running containers in privileged mode.
Maybe it will be allowed in the future.
Please refer to the issue [1030](https://github.com/docker/swarmkit/issues/1030#issuecomment-232299819).
This prevents running Weave Scope in a normal way, since it needs privileged mode.
A work around exists documented [here](https://github.com/weaveworks/scope-global-swarm-service)

Running global plugins is not supported either.

### Pre-requisities

* Docker
* Vagrant
* Virtualbox
* Packer
* Terraform

### Docker Swarm (Single-Node)

* Put your docker into the swarm mode
* Navigate to <a href="http://localhost" target="_blank">http://localhost</a> to verify that the demo works.

<!-- deploy-test-start pre-install -->

    docker swarm init  
    docker-compose pull
    docker-compose bundle
    docker deploy dockerswarm


### Docker Swarm (Multi-Node)

    1) AWS
        packer build -only=amazon-ebs packer/packer.json
        terraform plan terraform/aws
        terraform apply terraform/aws
    2) gcloud
        packer build -only=googlecompute packer/packer.json
        terraform plan terraform/gcloud
        terraform apply terraform/gcloud
    3) Local
        packer build -only=virtualbox-iso local packer/packer.json
        terraform plan terraform/local
        terraform apply terraform/local

<!-- deploy-test-end -->

### Run tests

There's a load test provided as a service in this compose file. For more information see [Load Test](#loadtest).  
It will run when the compose is started up, after a delay of 60s. This is a load test provided to simulate user traffic to the application.
This will send some traffic to the application, which will form the connection graph that you view in Scope or Weave Cloud. 

You may also choose to run the following command to check the health of the deployment.

<!-- deploy-test-start run-tests -->

    i=0
    STATUS=0
    while [ $STATUS -ne 200 ] || [ $i -lt 5 ]; do
        sleep 60
        STATUS=$(curl -4 -s -o output.txt -w "%{http_code}" http://localhost/health?nodes=user,catalogue,cart,shipping,payment,orders)
        i=$((i+1))
    done

    cat output.txt | jq && rm output.txt

    if [ $STATUS -ne 200 ]; then
        echo "$(tput setaf 1)DEPLOY FAILED$(tput sgr0)"
        exit 1
    fi

<!-- deploy-test-end -->

### Cleaning up

<!-- deploy-test-start destroy-infrastructure -->

    docker stack rm dockerswarm
    rm output.txt

<!-- deploy-test-end -->
