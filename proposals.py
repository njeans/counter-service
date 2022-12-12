import json
import sys
import os
import infra.member
import infra.network
import infra.node
import infra.interfaces

if os.environ.get("deployment_location", "") == "DOCKER":
    CCF_NODE = os.environ.get("CCF_NODE", '0.0.0.0:8080')
    CCF_CERTS_DIR =  os.path.join("/app", "workspace", "sandbox_common")
    BUNDLE_PATH="/app/prop/js2/dist/bundle.json"
    CONFIG_PATH="/app/cchost_config_virtual_js.json"
else:
    CCF_NODE = os.environ.get("CCF_NODE", '0.0.0.0:8546')
    CCF_CERTS_DIR =  os.path.join(os.environ.get("PROJECT_ROOT"), "shared", "ccf", "sandbox_common")
    BUNDLE_PATH=os.path.join(os.environ.get("PROJECT_ROOT"),"counter-service", "js2", "dist", "bundle.json")
    CONFIG_PATH=os.path.join(os.environ.get("PROJECT_ROOT"),"counter-service","config","cchost_config_virtual_js.json")

CCF_SERVICE_CERT_PATH = os.path.join(CCF_CERTS_DIR, "service_cert.pem")

def set_js_app():
    host = infra.interfaces.HostSpec.from_json({"primary_rpc_interface":{"bind_address": CCF_NODE}})
    member = infra.member.Member(local_id="member0", curve=infra.network.EllipticCurve.secp384r1.name,  common_dir=CCF_CERTS_DIR, share_script=None)
    node = infra.node.Node(local_node_id=0, host=host, binary_dir=".", library_dir=".")
    node.common_dir = CCF_CERTS_DIR
    node.network_state = infra.node.NodeNetworkState.started

    with open(BUNDLE_PATH) as f:
        bundle  = json.load(f)
    set_js_app = {"actions":[{"name": "set_js_app", "args": {"bundle": bundle, "disable_bytecode_cache": False}}]}
    proposal = member.propose(node, set_js_app)

    # ballot = {"ballot": "export function vote (proposal, proposerId) { return true }"}
    # member.vote(node, proposal, ballot)

if __name__ == '__main__':
    if len(sys.argv) == 2:
        globals()[sys.argv[1]]()
    elif len(sys.argv) == 3:
        globals()[sys.argv[1]](sys.argv[2])
    else:
        set_js_app()