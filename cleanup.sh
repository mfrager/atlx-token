#!/bin/bash

eval $(docker-machine env atx1)
(cd /Users/mfrager/Build/atellix/; docker-compose stop ganache)
rm -rf ganache/ganache_data/*
(cd /Users/mfrager/Build/atellix/; docker-compose up -d ganache)
rm -rf build/deployments/*
