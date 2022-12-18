#!/bin/bash

if [ -z "${1}" ]; then
    echo "You must supply the number of members accepting the proposal"
    echo "example usage: ./redeploy.sh 2 "
    exit 1
fi

if [[ ${deployment_location} == "DOCKER" ]];
then
    echo "Redeploy from inside docker container"
    server=https://localhost:8080
    app_dir=/app
    certs=/sandbox_common
else 
    echo "Redeploy locally"
    server=https://localhost:8546
    app_dir=../.
    certs=../sandbox_common
fi 

cd $app_dir
npm run build

cd $app_dir/scripts
echo "Proposing Application submit proposal to network and $1 vote as accepted"
./submit_proposal.sh --network-url ${server} --vote-file $app_dir/scripts/vote_accept.json \
  --proposal-file ${app_dir}/dist/set_js_app.json --cert $certs --num-voters $1