#!/bin/bash

set -eo pipefail
set +x
function usage {
    echo ""
    echo "Submit a ccf proposal and automatically vote with acceptance from submitter ."
    echo ""
    echo "usage: ./submit_proposal.sh --network-url string --proposal-file string --cert string --vote-file string --num-voters 2"
    echo ""
    echo "  --network-url   string      ccf network url (example: https://ccf0:8080)"
    echo "  --proposal-file string      path to any governance proposal to submit (example: dist/set_js_app.json)"
    echo "  --cert          string      ccf network certificate file path (example: /sandbox_common)"
    echo "  --vote-file     string      The file containing the vote to cast (example /app/scripts/vote_accept.json)"
    echo "  --num-voters    int         The file containing the vote to cast (example 2)"
    echo ""
    exit 0
}

function failed {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

# parse parameters

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]
do
    name="${1/--/}"
    name="${name/-/_}"
    case "--$name"  in
        --network_url) network_url="$2"; shift;;
        --proposal_file) proposal_file="$2"; shift;;
        --vote_file) vote_file="$2"; shift;;
        --num_voters) num_voters="$2"; shift;;
        --cert) cert_dir="$2"; shift;;
        --help) usage; exit 0; shift;;
        --) shift;;
    esac
    shift;
done


if [[ -z "${network_url}" ]]; then
    failed "Missing parameter --network-url"
elif [[ -z "${proposal_file}" ]]; then
    failed "Missing parameter --proposal-file"
elif [[ -z "${cert_dir}" ]]; then
    failed "Missing parameter --cert"
elif [[ -z "${vote_file}" ]]; then
    failed "Missing parameter --vote-file"
elif [[ -z "${num_voters}" ]]; then
    failed "Missing parameter --num-voters"
fi

ccf_prefix=/opt/ccf/bin
service_cert="$cert_dir/service_cert.pem"
signing_key0="$cert_dir/member0_privk.pem"
signing_cert0="$cert_dir/member0_cert.pem"

proposal0_out=$($ccf_prefix/scurl.sh "$network_url/gov/proposals" --cacert $service_cert --signing-key $signing_key0 --signing-cert $signing_cert0 --data-binary @$proposal_file -H "content-type: application/json")
proposal0_id=$( jq -r  '.proposal_id' <<< "${proposal0_out}" )
echo $proposal0_out | jq .

for (( i=0; i<$num_voters; i++ ))
do
    echo "member${i} voting for $proposal0_id "
    signing_key="$cert_dir/member${i}_privk.pem"
    signing_cert="$cert_dir/member${i}_cert.pem"
    $ccf_prefix/scurl.sh "$network_url/gov/proposals/$proposal0_id/ballots" --cacert $service_cert --signing-key $signing_key --signing-cert $signing_cert --data-binary @$vote_file -H "content-type: application/json" &> /dev/null #| jq .
done
curl "$network_url/gov/proposals/$proposal0_id" --cacert $service_cert -H "content-type: application/json" |  jq .
