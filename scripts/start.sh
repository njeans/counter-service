#!/bin/bash

if [ -z "${NODE_NUM}" ]; then
    echo "You must set NODE_NUM environment variable"
    exit 1
fi

if [ -z "${platform}" ]; then
        echo "You must set platform environment variable to virtual or sgx"
        exit 1
fi
if [ "virtual" != "$platform" ]; then
echo
elif [ "sgx" != "$platform" ]; then
echo
else
    echo "You must set platform environment variable to virtual or sgx"
    exit 1
fi

if [[ ${NODE_NUM} == "0" ]];
then
    if [[ ${deployment_location} == "DOCKER" ]];
    then
        echo "~~~~~~~~~~~~~~~~~~~~~Node 0 is starting the network in docker~~~~~~~~~~~~~~~~~~~~~"
        ccf_addr=localhost:8080 
        sandbox_dir=/sandbox_common
        shared_dir=/shared
        config_file=/app/config/config_start.json
        workspace_dir=/workspace/workspace0
        app_dir=/app
    else 
        echo "~~~~~~~~~~~~~~~~~~~~~~Node 0 is starting the network localy~~~~~~~~~~~~~~~~~~~~~~~~"
        ccf_addr=localhost:8546 
        start_dir=$(pwd)
        sandbox_dir="$start_dir/../sandbox_common"
        shared_dir="$start_dir/../shared"
        config_file="$start_dir/../config/cchost_config_${platform}_js_local_start.json"
        workspace_dir="$start_dir/../workspace/workspace0"
        app_dir="$start_dir/../."
    fi
    mkdir -p $sandbox_dir
    rm -rf $sandbox_dir/member*
    rm -rf $sandbox_dir/user*
    rm -rf $sandbox_dir/service_cert*
    rm -rf $sandbox_dir/node_cert*
    cd $sandbox_dir
    $shared_dir/keygenerator.sh --name member0 --gen-enc-key
    mkdir -p $workspace_dir
    rm -rf $workspace_dir/*
    sleep 10 && cd $app_dir/scripts && ./setup_governance.sh --nodeAddress $ccf_addr --certificate_dir $sandbox_dir --app_dir $app_dir $@ &
    cd $workspace_dir && /usr/bin/cchost --config $config_file
else
    if [[ ${deployment_location} == "DOCKER" ]];
    then
        echo "~~~~~~~~~~~~~~~~~~~~~~Node $NODE_NUM is joining the network in docker~~~~~~~~~~~~~~~~~~~~~~"
        config_file="/app/config/config_join_${NODE_NUM}.json"
        workspace_dir="/workspace/workspace${NODE_NUM}"
    else 
        echo "~~~~~~~~~~~~~~~~~~~~~~Node $NODE_NUM is joining the network locally~~~~~~~~~~~~~~~~~~~~~~~~"
        start_dir=$(pwd)
        config_file="$start_dir/../config/cchost_config_${platform}_js_local_join_${NODE_NUM}.json"
        workspace_dir="$start_dir/../workspace/workspace${NODE_NUM}"
    fi
    mkdir -p $workspace_dir
    rm -rf $workspace_dir/*
    cd $workspace_dir
    /usr/bin/cchost --config $config_file
fi
