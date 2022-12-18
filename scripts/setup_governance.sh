#!/bin/bash
set -eo pipefail

function usage {
    echo ""
    echo "Setup the CCF network using Azure Keyvault certificates."
    echo ""
    echo "usage: ./setup_governance.sh --nodeAddress <IPADDRESS:PORT> --certificate_dir </sandbox_common> --app_dir </app> --members 2 --users 2 --nodes 2 "
    echo ""
    echo "  --nodeAddress        string      The IP and port of the primary CCF node"
    echo "  --certificate_dir    string      The directory where the certificates are"
    echo "  --app_dir            string      The directory where the app source code is"
    echo "  --members            int         Number of members to add"
    echo "  --users              int         Number of users to add"
    echo "  --nodes              int         Number of nodes in the network to wait for"
    echo ""
    exit 0
}

function failed {
    printf "💥 Script failed: %s\n\n" "$1"
    exit 1
}

# parse parameters

if [ $# -gt 12 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]
do
    name="${1/--/}"
    name="${name/-/_}"
    case "--$name"  in
        --nodeAddress) nodeAddress="$2"; shift;;
        --certificate_dir) certs="$2"; shift;;
        --app_dir) app_dir="$2"; shift;;
        --members) members="$2"; shift;;
        --users) users="$2"; shift;;
        --nodes) nodes="$2"; shift;;
        --help) usage; exit 0;;
        --) shift;;
    esac
    shift;
done

# validate parameters
if [ -z "${nodeAddress}" ]; then
    failed "You must supply --nodeAddress"
fi
if [ -z "${certs}" ]; then
    failed "You must supply --certificate_dir"
fi
if [ -z "${app_dir}" ]; then
    failed "You must supply --app_dir"
fi
if [ -z "${members}" ]; then
    echo "--members not set defaulting to 2"
    members=2
fi
if (($members < 1)); then
    failed "--members must be >= 1"
fi
if [ -z "${users}" ]; then
    echo "--users not set defaulting to 2"
    users=2
fi
if (($users < 1)); then
    failed "--users must be >= 1"
fi
if [ -z "${nodes}" ]; then
    echo "--nodes not set defaulting to 1"
    nodes=1
fi
if (($nodes < 1)); then
    failed "--nodes must be >= 1"
fi

##############################################
# Generic variables
##############################################
server="https://${nodeAddress}" # ccf network address


##############################################
# Activate member 0
# . service_cert.pem was already copied to $certs
# . member0 cert/key was already copied to $certs
##############################################
# echo "Getting list of members..."
curl --silent $server/gov/members --cacert $certs/service_cert.pem > /dev/null # | jq .

curl --silent "${server}/gov/ack/update_state_digest" \
    -X POST \
    --cacert $certs/service_cert.pem \
    --key $certs/member0_privk.pem \
    --cert $certs/member0_cert.pem | jq > $certs/activation.json

# echo "Show digest"
# cat $certs/activation.json | jq .

ccf_prefix=/opt/ccf/bin

$ccf_prefix/scurl.sh "${server}/gov/ack" \
    --cacert $certs/service_cert.pem \
    --signing-key $certs/member0_privk.pem \
    --signing-cert $certs/member0_cert.pem \
    --header "Content-Type: application/json" \
    --data-binary @$certs/activation.json > /dev/null # | jq .

echo "Getting list of members..."
curl --silent ${server}/gov/members --cacert $certs/service_cert.pem | jq .

##############################################
# Creating and adding members/users to network
##############################################

# create certificate files
create_certificate(){
    local certName="$1"
    local certsFolder="$2"
    cd $certsFolder
    $ccf_prefix/keygenerator.sh --name $certName --gen-enc-key
    cd -
}

#---------------------
for (( i=1; i<$members; i++ ))
do
  mid=$((i+1))
  echo "Adding Member $mid/$members: create certificate and proposal"
  cert_name="member$i"
  create_certificate "${cert_name}" "${certs}"
  ./add_member.sh --cert-file $certs/${cert_name}_cert.pem --pubk-file $certs/${cert_name}_enc_pubk.pem

  echo "Adding Member $mid/$members: submit proposal to network and vote as accepted"
  ./submit_proposal.sh --network-url  ${server} --vote-file $app_dir/scripts/vote_accept.json \
    --proposal-file $certs/set_member.json --cert $certs --num-voters $i
done

num_members=$(curl --silent $server/gov/members --cacert $certs/service_cert.pem  | jq length )
echo "Final list of $num_members members..."
curl --silent ${server}/gov/members --cacert $certs/service_cert.pem | jq .

if [ $members != $num_members ]; then
    failed "Members wrong $members != $num_members"
fi

for (( i=1; i<$members; i++ ))
do
    mid=$((i+1))
    echo "Activating Member $mid/$members"
    curl --silent "${server}/gov/ack/update_state_digest" \
        -X POST \
        --cacert $certs/service_cert.pem \
        --key "$certs/member${i}_privk.pem" \
        --cert "$certs/member${i}_cert.pem" | jq > $certs/activation.json

    # echo "Show digest"
    # cat $certs/activation.json | jq .

    $ccf_prefix/scurl.sh "${server}/gov/ack" \
        --cacert $certs/service_cert.pem \
        --signing-key "$certs/member${i}_privk.pem" \
        --signing-cert "$certs/member${i}_cert.pem" \
        --header "Content-Type: application/json" \
        --data-binary @$certs/activation.json | jq .
done

#---------------------
for (( i=0; i<$users; i++ ))
do

  echo "Adding user$i $((i+1))/$users: create certificate and proposal"
  cert_name="user$i" 
  create_certificate "${cert_name}" "${certs}"
  ./add_user.sh --cert-file $certs/${cert_name}_cert.pem

  echo "Adding user$i $((i+1))/$users: submit proposal to network and vote as accepted"
  ./submit_proposal.sh --network-url  ${server} --vote-file $app_dir/scripts/vote_accept.json \
    --proposal-file $certs/set_user.json --cert $certs --num-voters $members

done

# total=0
# max=100
num_nodes=$(curl $server/node/network/nodes --cacert $certs/service_cert.pem  | jq '.nodes | length')
while [ $nodes != $num_nodes ]
do
    t=10
    sleep $t
    # total=$((total + t))
    # if  (( $total > $max )); then 
    #   echo "timeout exceeded exiting after $total seconds"
    #   exit 1
    # fi
    num_nodes=$(curl -s $server/node/network/nodes --cacert $certs/service_cert.pem  | jq '.nodes | length')
done
echo "$nodes nodes have joined the network.."
curl --silent $server/node/network/nodes --cacert $certs/service_cert.pem  | jq .


##############################################
# Propose and Open Network
##############################################
create_open_network_proposal(){
    local certsFolder="$1"
    local service_cert=$(< ${certsFolder}/service_cert.pem sed '$!G' | paste -sd '\\n' -)

    local proposalFileName="${certsFolder}/network_open_proposal.json"
    cat <<JSON > $proposalFileName
{
  "actions": [
    {
      "name": "transition_service_to_open",
      "args": {
        "next_service_identity": "${service_cert}\n"
      }
    }
  ]
}
JSON
}

echo "Opening Network 1/2: create proposal"
create_open_network_proposal "${certs}"

echo "Opening Network 2/2: submit proposal to network and vote as accepted"
./submit_proposal.sh --network-url  ${server} --vote-file $app_dir/scripts/vote_accept.json \
  --proposal-file $certs/network_open_proposal.json --cert $certs --num-voters $members

##############################################
# Test Network
##############################################
curl --silent "${server}/node/network" --cacert $certs/service_cert.pem | jq .

##############################################
# Propose application. The json file we use
# in the proposal is generated when we build
# the application as it has all the endpoints
# defined in it.
##############################################
echo "Proposing Application 1/1: submit proposal to network and vote as accepted"
./submit_proposal.sh --network-url  ${server} --vote-file $app_dir/scripts/vote_accept.json \
  --proposal-file ${app_dir}/dist/set_js_app.json --cert $certs --num-voters $members

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Governance Completed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~*･゜ﾟ･*:.｡..｡.:*･'(*ﾟ▽ﾟ*)'･*:.｡. .｡.:*･゜ﾟ･*~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Accepting~~Requests~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
