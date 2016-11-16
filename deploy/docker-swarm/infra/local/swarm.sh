#!/usr/bin/env bash


case $@ in
  up)
    vagrant up
    vagrant ssh swarm-master -c "docker swarm init --advertise-addr 10.0.0.10"
    TOKEN=$(vagrant ssh swarm-master -c "docker swarm join-token -q worker" | tr -d '\r')
    vagrant ssh swarm-node1 -c 'docker swarm join --listen-addr 10.0.0.11 --token '"'$TOKEN'"' 10.0.0.10'
    vagrant ssh swarm-node2 -c 'docker swarm join --listen-addr 10.0.0.12 --token '"'$TOKEN'"' 10.0.0.10'
    vagrant ssh swarm-node3 -c 'docker swarm join --listen-addr 10.0.0.13 --token '"'$TOKEN'"' 10.0.0.10'
    vagrant ssh swarm-master -c "docker-compose -f /docker-swarm/docker-compose.yml pull"
    vagrant ssh swarm-master -c "docker-compose -f /docker-swarm/docker-compose.yml bundle -o dockerswarm.dab"
    vagrant ssh swarm-master -c "docker deploy dockerswarm"
    ;;
  down)
    vagrant destroy -f
    ;;
esac
