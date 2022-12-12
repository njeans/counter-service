import { ccf } from "@microsoft/ccf-app/global";
import * as ccfapp from "@microsoft/ccf-app";

const countKey = "countKey";
const latestHashKey = "latestHashKey";


function buf2Hex(buffer) {
  return [...new Uint8Array(buffer)]
      .map(x => x.toString(16).padStart(2, '0'))
      .join('');
}

function hex2Buf(string) {
  for (var bytes = [], c = 0; c < string.length; c += 2){
    bytes.push(parseInt(string.substr(c, 2), 16));
  }
  const buf = new ArrayBuffer(bytes.length);
  for (let i = 0; i < bytes.length; i++) {
    new DataView(buf).setUint8(i, bytes[i]);
  }
  return buf;
}

function concatBuf(buffer1, buffer2) {
  var buf = new ArrayBuffer(buffer1.byteLength + buffer2.byteLength);
  for (let i = 0; i < buffer1.byteLength; i++) {
    var tmp = new DataView(buffer1).getUint8(i);
    new DataView(buf).setUint8(i, tmp);
  }
  for (let i = 0; i < buffer2.byteLength; i++) {
    var tmp = new DataView(buffer2).getUint8(i);
    new DataView(buf).setUint8(i+buffer1.byteLength, tmp);
  }
  return buf;
};

function validate_user_id(userId) {
  // Check if user exists
  // https://microsoft.github.io/CCF/main/audit/builtin_maps.html#users-info
  const usersCerts = ccfapp.typedKv(
    "public:ccf.gov.users.certs",
    ccfapp.arrayBuffer,
    ccfapp.arrayBuffer
  );
  return usersCerts.has(userId);
}

function validate_hash(hash) {
  return hash.length == 64;
}

function isPositiveInteger(value) {
  return Number.isInteger(value) && value > 0;
}

function validate_transaction_id(transactionId) {
  // Transaction ID is composed of View ID and Sequence Number
  // https://microsoft.github.io/CCF/main/overview/glossary.html#term-Transaction-ID
  if (typeof transactionId !== "string") {
    return false;
  }
  const strNums = transactionId.split(".");
  if (strNums.length !== 2) {
    return false;
  }
  return (
    isPositiveInteger(parseInt(strNums[0])) &&
    isPositiveInteger(parseInt(strNums[1]))
  );
}

function parse_request_query(request) {
  const elements = request.query.split("&");
  const obj = {};
  for (const kv of elements) {
    const [k, v] = kv.split("=");
    obj[k] = v;
  }
  return obj;
}

export function update(request) {
  const userId = ccf.strToBuf(request.params.user_id);
  if (!validate_user_id(userId)) {
    return {
      statusCode: 404,
    };
  }
  const params = request.body.json();
  if (params.hash === undefined) {
    return { 
      statusCode: 400,
      body: { error: "Missing body parameter 'hash'" } 
    };
  }
  if (!validate_hash(params.hash)) {
    return {
      statusCode: 400,
      body: { error: "Invalid hash" } 
    };
  }
  const currentSCSTable = ccfapp.typedKv(
    request.params.user_id,
    ccfapp.string,
    ccfapp.arrayBuffer
  );

  const latest_hash = currentSCSTable.get("latestHashKey");
  if (latest_hash === undefined) {
    return {
      statusCode: 404,
      body: { error: `Record for userId: \"${request.params.user_id}\" not found` } 
    };
  }
  const combined = concatBuf(latest_hash, hex2Buf(params.hash));
  const digest = ccf.crypto.digest("SHA-256", combined);
  const new_count = parseInt(ccf.bufToStr(currentSCSTable.get(countKey))) + 1;
  const new_record_name = "hash_" + new_count.toString(); 

  currentSCSTable.set(new_record_name, digest);
  currentSCSTable.set("latestHashKey", digest);
  currentSCSTable.set(countKey, ccf.strToBuf(new_count.toString()));
  ccf.rpc.setClaimsDigest(digest);
  console.log(`update scs for ${request.params.user_id} sha256(${buf2Hex(latest_hash)}+${params.hash})->${new_record_name}:${buf2Hex(digest)}`)
  return {body: {"ft": buf2Hex(digest)}};
}

export function read(request) {
  const userId = ccf.strToBuf(request.params.user_id);
  if (!validate_user_id(userId)) {
    return {
      statusCode: 404,
    };
  }
  const currentSCSTable = ccfapp.typedKv(
    request.params.user_id,
    ccfapp.string,
    ccfapp.arrayBuffer
  );
  const record = currentSCSTable.get(latestHashKey);
  if (record === undefined) {
    return {
      statusCode: 404,
      body: { error: `Record for userId: \"${request.params.user_id}\" not found` } 
    };
  }
  console.log("read scs for", request.params.user_id, buf2Hex(record));
  return { body: {hash: buf2Hex(record)}};
}

export function new_scs(request) {
  const userId = ccf.strToBuf(request.params.user_id);
  if (!validate_user_id(userId)) {
    return {
      statusCode: 403,
    };
  }

  const params = request.body.json();
  if (params.hash === undefined) {
    return {
      statusCode: 400,
      body: { error: "Missing body parameter 'hash'" } 
    };
  }

  if (!validate_hash(params.hash)) {
    return {
      statusCode: 400,
      body: { error: "Invalid hash" } 
    };
  }
  const currentSCSTable = ccfapp.typedKv(
    request.params.user_id,
    ccfapp.string,
    ccfapp.arrayBuffer
  );

  const record = currentSCSTable.get("hash_0");
  if (record != undefined) {
    return {
      statusCode: 404,
      body: { error: `Record for userId: \"${request.params.user_id}\" already exists` } 
    };
  }

  const init_record = hex2Buf(params.hash);
  currentSCSTable.set(countKey, ccf.strToBuf("0"));
  currentSCSTable.set("hash_0", init_record);
  currentSCSTable.set(latestHashKey, init_record);

  ccf.rpc.setClaimsDigest(init_record);
  console.log("initialize new scs for", request.params.user_id, "with hash_0:", params.hash);
  return {
    statusCode: 204,
  };
}

export function receipt(request) {
  const userId = ccf.strToBuf(request.params.user_id);
  if (!validate_user_id(userId)) {
    return {
      statusCode: 404,
    };
  }
  const parsedQuery = parse_request_query(request);
  const transactionId = parsedQuery.transaction_id;
  if (!validate_transaction_id(transactionId)) {
    return {
      statusCode: 400,
      body: { error: "Invalid transaction id" } 
    };
  }

  const txNums = transactionId.split(".");
  const seqno = parseInt(txNums[1]);

  const rangeBegin = seqno;
  const rangeEnd = seqno;

  const makeHandle = (begin, end, id) => {
    const cacheKey = `${begin}-${end}-${id}`;
    const digest = ccf.crypto.digest("SHA-256", ccf.strToBuf(cacheKey));
    const handle = new DataView(digest).getUint32(0);
    return handle;
  };

  const handle = makeHandle(rangeBegin, rangeEnd, transactionId);

  const expirySeconds = 1800;
  const states = ccf.historical.getStateRange(
    handle,
    rangeBegin,
    rangeEnd,
    expirySeconds
  );

  if (states === null) {
    return {
      statusCode: 202,
      headers: {
        "retry-after": "1",
      },
      body: {error: `Historical transactions from ${rangeBegin} to ${rangeEnd} are not yet available, fetching now`},
    };
  }

  const firstKv = states[0].kv;

  const scsTable = ccfapp.typedKv(
    firstKv[request.params.user_id],
    ccfapp.string,
    ccfapp.arrayBuffer
  );

  const latest_hash = scsTable.get(latestHashKey);
  if(latest_hash === undefined) {
    return {
      statusCode: 404,
    };    
  }

  const count = parseInt(ccf.bufToStr(scsTable.get(countKey)));
  const record_name = "hash_" + count.toString(); 

  console.log(`return receipt for user ${request.params.user_id} tx_id: ${transactionId} ${record_name}: ${buf2Hex(latest_hash)}`);

  const receipt = states[0].receipt;
  const body = {
    cert: receipt.cert,
    leaf_components: {
      hash: buf2Hex(latest_hash),
      commit_evidence: receipt.leaf_components.commit_evidence,
      write_set_digest: receipt.leaf_components.write_set_digest,
    },
    node_id: receipt.node_id,
    proof: receipt.proof,
    signature: receipt.signature,
  };
  return { body: body};
}

export function reset(request) {
  const userId = ccf.strToBuf(request.params.user_id);
  if (!validate_user_id(userId)) {
    return {
      statusCode: 403,
    };
  }

  const currentSCSTable = ccfapp.typedKv(
    request.params.user_id,
    ccfapp.string,
    ccfapp.arrayBuffer
  );
  currentSCSTable.delete(countKey);
  currentSCSTable.delete("hash_0");
  currentSCSTable.delete(latestHashKey);
  console.log("reset scs for user", request.params.user_id);
  return {
    statusCode: 202,
  };
}