#!/bin/bash

set -euo pipefail

# create trust_node json proposal file
function trust_node_proposal {
    local nodeID=$1
    local trustNodeFile=$2
    cat <<JSON > $trustNodeFile
{
  "actions": [
    {
      "name": "transition_node_to_trusted",
      "args": {
        "node_id": "$nodeID",
        "valid_from": "220101120000Z"
      }
    }
  ]
}
JSON
}

function usage {
    echo ""
    echo "Generate trust_node.json proposal for adding nodes to CCF after network open."
    echo ""
    echo "usage: ./add_node.sh --cert-file string "
    echo ""
    echo "  --cert-file   string  the certificate .pem file for the node"
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
        --cert_file) cert_file="$2"; shift;;
        --help) usage; exit 0; shift;;
        --) shift;;
    esac
    shift;
done

# validate parameters
if [ -z "${cert_file}" ]; then
	failed "Missing parameter --cert-file"
fi

certs_folder=`dirname $cert_file`

proposal_json_file="${certs_folder}/trust_node.json"
node_id=$(openssl x509 -in "$cert_file" -noout -fingerprint -sha256 | cut -d "=" -f 2 | sed 's/://g' | awk '{print tolower($0)}')

echo "Creating user json proposal file..."
trust_node_proposal $node_id $proposal_json_file

echo "proposal json file created: $proposal_json_file"
echo "node id: $node_id"
