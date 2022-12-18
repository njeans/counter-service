import json
import sys
import hashlib
import base64
import cryptography
from cryptography.x509 import load_pem_x509_certificate
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import ec, utils
from cryptography.hazmat.primitives import hashes
import ccf.receipt

def verify_receipt(resp_path):


    with open(resp_path) as f:
        resp = json.load(f)

    ft = bytes.fromhex(resp["leaf_components"]["hash"])
    commit_evidence_digest = hashlib.sha256(resp["leaf_components"]["commit_evidence"].encode()).digest()
    write_set_digest = bytes.fromhex(resp["leaf_components"]["write_set_digest"])
    leaf = (hashlib.sha256(write_set_digest + commit_evidence_digest + ft).hexdigest())
    root = bytes.fromhex(ccf.receipt.root(leaf, resp["proof"]))
    node_cert = resp["cert"].encode()
    sig=base64.b64decode(resp["signature"])
    cert = load_pem_x509_certificate(node_cert, default_backend())
    pk = cert.public_key()
    assert isinstance(pk, ec.EllipticCurvePublicKey)
    try:
        pk.verify(
            sig,
            root,
            ec.ECDSA(utils.Prehashed(hashes.SHA256())),
        )
        print("OK")
    except cryptography.exceptions.InvalidSignature:
        print("InvalidSignature")


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == "verify_receipt":
        globals()[sys.argv[1]](sys.argv[2])
    else:
        raise Exception("InvalidArguments")