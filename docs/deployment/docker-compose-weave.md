---
layout: default
deployDoc: true
---

## Sock Shop  Docker Compose & Weave

The Weave Demo application is packaged using a [Docker Compose](https://docs.docker.com/compose/) file.

### Networking

In this version we create several isolated networks using the [Weave Docker plugin](https://www.weave.works/docs/net/latest/plugin/) and use Weave's DNS support.

### Pre-requisites

- Install [Docker](https://www.docker.com/products/overview)
- Install [Weave Scope](https://www.weave.works/install-weave-scope/)
- Install [Weave Net](https://www.weave.works/install-weave-net/)

### *(Optional)* Launch Weave Scope or Weave Cloud

Weave Scope (local instance)

    scope launch

Weave Cloud (hosted platform). Get a token by [registering here](http://cloud.weave.works/).

    scope launch --service-token=<token>

### Provision infrastructure

<!-- deploy-test-start create-infrastructure -->

    curl -L git.io/weave -o /usr/local/bin/weave
    chmod a+x /usr/local/bin/weave
    weave launch

    docker-compose up -d

<!-- deploy-test-end -->
    
### Run tests

There's a load test provided as a service in this compose file. For more information see [Load Test](#loadtest).  
It will run when the compose is started up, after a delay of 60s. This is a load test provided to simulate user traffic to the application.
This will send some traffic to the application, which will form the connection graph that you view in Scope or Weave Cloud. 

You may also choose to run the following command to check the health of the deployment.

    curl http://localhost/health?nodes=user,catalogue,queue-master,cart,shipping,payment,orders 

<!-- deploy-test-hidden run-tests

    sleep 90
    STATUS=$(curl -s -o output.txt -w "%{http_code}" http://localhost/health?nodes=user,catalogue,queue-master,cart,shipping,payment,orders)
    cat output.txt | jq -C '.'

    if [ $STATUS -ne 200 ]; then
        echo "$(tput setaf 1)DEPLOY FAILED$(tput sgr0)"
        exit 1
    fi

-->


### Cleaning up

<!-- deploy-test-start destroy-infrastructure -->

    docker-compose down
    weave stop
   
<!-- deploy-test-end -->

<!-- deploy-test-hidden destroy-infrastructure
    rm output.txt
-->
