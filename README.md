# CCF Implementation of State Continuity Counter Service

- [CCF Implementation of State Continuity Counter Service](#ccf-implementation-of-state-continuity-counter-service)
  - [Run SCS JS app in Docker](#run-scs-js-app-in-docker)
    - [Virtual](#virtual)
      - [1 Node](#1-node)
      - [3 Nodes](#3-nodes)
    - [SGX  (untested)](#sgx--untested)
      - [1 Node](#1-node-1)
      - [3 Nodes](#3-nodes-1)
  - [Run tests](#run-tests)
    - [1 Node Network](#1-node-network)
    - [3 Node Network](#3-node-network)
  - [Update and redeploy app source code](#update-and-redeploy-app-source-code)
    - [1 Node Network](#1-node-network-1)
    - [3 Node Network](#3-node-network-1)
  - [Cleanup](#cleanup)
    - [1 Node Network](#1-node-network-2)
    - [3 Node Network](#3-node-network-2)
  - [Run SCS JS app locally (untested)](#run-scs-js-app-locally-untested)
    - [Dependencies](#dependencies)
    - [1 Node](#1-node-2)
    - [3 Node](#3-node)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>



## Run SCS JS app in Docker

### Virtual

#### 1 Node
```bash
$ docker build -t scs-virtual --build-arg platform=virtual -f docker/Dockerfile .
$ docker run -d --name scs-virtual-0 \
$	-v $(pwd)/workspace/workspace0:/workspace/workspace0 \
$	-v $(pwd)/sandbox:/sandbox_common \
$	-v $(pwd)/src:/app/src -v $(pwd)/app.json:/app/app.json \
$	-p 8546:8080 scs-virtual <optional cmd> (default: "--members 1 --users 2 --nodes 1")
$ docker logs scs-virtual-0
...
...
~~~~~~~~~~~~~~~~~~~~~Node 0 is starting the network in docker~~~~~~~~~~~~~~~~~~~~~
-- Generating identity private key and certificate for participant "member0"...
Identity curve: secp384r1
Identity private key generated at:   member0_privk.pem
Identity certificate generated at:   member0_cert.pem (to be registered in CCF)
-- Generating RSA encryption key pair for participant "member0"...
Generating RSA private key, 2048 bit long modulus (2 primes)
.............+++++
........................................................................................+++++
e is 65537 (0x010001)
writing RSA key
Encryption private key generated at:  member0_enc_privk.pem
Encryption public key generated at:   member0_enc_pubk.pem (to be registered in CCF)
2022-12-18T00:48:33.660554Z        100 [info ] ../src/host/main.cpp:125             | CCF version: ccf-3.0.1
2022-12-18T00:48:33.660606Z        100 [info ] ../src/host/main.cpp:133             | Configuration file /app/config/config_start.json:
{
  "enclave": {
    "file": "/usr/lib/ccf/libjs_generic.virtual.so",
    "platform": "Virtual",
    "type": "Virtual"
  },
  "network": {
    "node_to_node_interface": { 
      "published_address": "ccf0:8081",
      "bind_address": "localhost:8081" 
    },
    "rpc_interfaces": {
      "primary_rpc_interface": {
        "published_address": "ccf0:8080",
        "bind_address": "0.0.0.0:8080"
      }
    }
  },
  "command": {
    "type": "Start",
    "service_certificate_file": "/sandbox_common/service_cert.pem",
    "start": {
      "constitution_files": [
        "/shared/validate.js",
        "/shared/apply.js",
        "/shared/resolve.js",
        "/shared/actions.js"
      ],
      "service_configuration":
      {
        "recovery_threshold": 0,
        "maximum_node_certificate_validity_days": 365,
        "maximum_service_certificate_validity_days": 365,
        "reconfiguration_type": "OneTransaction"
      },
      "initial_service_certificate_validity_days": 365,
      "members": [
        {
          "certificate_file": "/sandbox_common/member0_cert.pem",
          "encryption_public_key_file": "/sandbox_common/member0_enc_pubk.pem"
        }
      ]
    }
  },
  "node_certificate": {
    "subject_alt_names": ["dNSName:ccf0", "dNSName:ccf1", "dNSName:ccf2", "dNSName:localhost", "iPAddress:0.0.0.0", "iPAddress:127.0.0.1"]
  },
  "output_files": {
    "node_certificate_file": "/sandbox_common/nodecert0.pem",
    "pid_file": "node.pid",
    "node_to_node_address_file": "/sandbox_common/0.node_address",
    "rpc_addresses_file" : "/sandbox_common/0.rpc_addresses"
  }
}
2022-12-18T00:48:33.660614Z        100 [info ] ../src/host/main.cpp:164             | Recovery threshold unset. Defaulting to number of initial consortium members with a public encryption key (1).
2022-12-18T00:48:33.667928Z        100 [info ] ../src/host/ledger.h:1022            | Recovered ledger entries up to 0, committed to 0
2022-12-18T00:48:33.667979Z        100 [info ] ../src/host/lfs_file_handler.h:23    | Clearing contents from existing directory ".index"
2022-12-18T00:48:33.668501Z        100 [info ] ../src/host/socket.h:45              | TCP Node Server listening on 127.0.0.1:8081
2022-12-18T00:48:33.668602Z        100 [info ] ../src/host/main.cpp:337             | Registering RPC interface primary_rpc_interface, on  0.0.0.0:8080
2022-12-18T00:48:33.668623Z        100 [info ] ../src/host/socket.h:45              | TCP RPC Client listening on 0.0.0.0:8080
2022-12-18T00:48:33.668630Z        100 [info ] ../src/host/main.cpp:351             | Registered RPC interface primary_rpc_interface, on  0.0.0.0:8080
2022-12-18T00:48:33.668691Z        100 [info ] ../src/host/main.cpp:444             | Startup host time: 2022-12-18 00:48:33
2022-12-18T00:48:33.668818Z        100 [info ] ../src/host/main.cpp:492             | Creating new node: new network (with 1 initial member(s) and 1 member(s) required for recovery)
2022-12-18T00:48:33.668825Z        100 [info ] ../src/host/main.cpp:571             | Initialising enclave: enclave_create_node
2022-12-18T00:48:33.769036Z        0   [info ] ../src/enclave/rpc_sessions.h:224    | Setting max open sessions on interface "primary_rpc_interface" (0.0.0.0:8080) to [1000, 1010] and endorsement authority to Service
2022-12-18T00:48:33.769091Z        0   [info ] ../src/node/node_state.h:1763        | Node TLS connections now accepted
2022-12-18T00:48:33.769123Z        0   [info ] ../src/consensus/aft/raft.h:1915     | Becoming leader n[bc627235893c3396bca568ff3a5100091f7c2498f24dd98bce6e05809597782c]: 2
2022-12-18T00:48:33.769129Z        0   [info ] ../src/node/node_state.h:476         | Created new node n[bc627235893c3396bca568ff3a5100091f7c2498f24dd98bce6e05809597782c]
2022-12-18T00:48:33.769284Z        100 [info ] ../src/host/main.cpp:608             | Created new node
2022-12-18T00:48:33.769446Z        100 [info ] ../src/host/main.cpp:612             | Output self-signed node certificate to /sandbox_common/nodecert0.pem
2022-12-18T00:48:33.769500Z        100 [info ] ../src/host/main.cpp:621             | Output service certificate to /sandbox_common/service_cert.pem
2022-12-18T00:48:33.769509Z        100 [info ] ../src/host/main.cpp:644             | Starting enclave thread(s)
2022-12-18T00:48:33.769564Z        100 [info ] ../src/host/main.cpp:652             | Entering event loop
2022-12-18T00:48:33.770721Z        0   [info ] ../src/enclave/main.cpp:335          | Starting thread: 0
2022-12-18T00:48:33.770742Z        0   [info ] ../src/enclave/main.cpp:342          | All threads are ready!
2022-12-18T00:48:33.781602Z -0.012 0   [info ] ../src/node/rpc/node_frontend.h:1555 | Created service
2022-12-18T00:48:34.785559Z -0.005 0   [info ] ../src/consensus/aft/raft.h:589      | Election timer has become active
2022-12-18T00:48:34.786816Z -0.006 0   [info ] ../src/node/node_state.h:1777        | Network TLS connections now accepted
...
Final list of 1 members...
{
  "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362": {
    "cert": "-----BEGIN CERTIFICATE-----\nMIIBtjCCATygAwIBAgIUaRSAiFAFE3zV5r2wQar02ZIyV0YwCgYIKoZIzj0EAwMw\nEjEQMA4GA1UEAwwHbWVtYmVyMDAeFw0yMjEyMTgwMDQ4MzNaFw0yMzEyMTgwMDQ4\nMzNaMBIxEDAOBgNVBAMMB21lbWJlcjAwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAR4\nikwiUxDKA5UTIUKIKC4mPXj+31MdD21vIhoU2E9skbkZuJBCJkG9kevwAWcq6ANJ\nNrKsQcC8+2lTeyi5W65E5WEJpQNTLp8Aq/vNBUDvo/F49uc6UJHeQNEkL0eVVfGj\nUzBRMB0GA1UdDgQWBBQYmashDE6reAavmThQLz2Y7Ul6oTAfBgNVHSMEGDAWgBQY\nmashDE6reAavmThQLz2Y7Ul6oTAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMD\nA2gAMGUCMQCd64ifvF70QDMmXmVeRlFuKrQqq40Db2dSj8GhJ8r8DftpL3BmJWTd\nBxJyfJ5tsx8CMDUkFKyJLjPRkQZnLmDHdr/hcW50GvlBGujnZqtX795g+G7uaZW+\nyEdpGuhOfVP+/w==\n-----END CERTIFICATE-----\n",
    "member_data": null,
    "public_encryption_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuTZuTndlvRqVQej/B77D\nFYUBoM6MIRPwS/la/VP45fS/a2Z686Z9igKmBUfkFcHOhLzmQRl8VmRDpQDU6PT1\npPW8fQAM7DZgQ1MPmrVrn48zUjb7GAcgueM+/9B1h5IKYeU0ZmN2UsNt2MLSzDHp\nrQceQZoJbyRyNMbGbolOlHx6ABkgAoFZtq85uZGUxSHrNNcJwzHWgdJip4+/z/y4\ndCxu8kS3VP+zwkP32nJ/kdAWJT/1D2/U03J2lsCghZTlpWxOw6Pe0cr+nEWxMS0t\ncy3gMoWidAG3aLL6AoVNvhxDfX36GOjTpXuysIepw8FGTorVUk4GRJTfrkEOCMCH\nlQIDAQAB\n-----END PUBLIC KEY-----\n",
    "status": "Active"
  }
}
Adding user0 1/2: create certificate and proposal
-- Generating identity private key and certificate for participant "user0"...
Identity curve: secp384r1
Identity private key generated at:   user0_privk.pem
Identity certificate generated at:   user0_cert.pem (to be registered in CCF)
-- Generating RSA encryption key pair for participant "user0"...
Generating RSA private key, 2048 bit long modulus (2 primes)
.........................+++++
.............................+++++
e is 65537 (0x010001)
writing RSA key
Encryption private key generated at:  user0_enc_privk.pem
Encryption public key generated at:   user0_enc_pubk.pem (to be registered in CCF)
...
user id: 7d5a944631aadea1a87b4fbf25ac15827ea20fa731e19192735b45dbe7e8fb29
Adding user0 1/2: submit proposal to network and vote as accepted
member0 voting for a793beb4a24bf03255fc8345f38df3a07edf862b254f8fa5c751ff640b6bd0af 
{
  "ballots": {
    "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362": "export function vote (proposal, proposerId) { return true }"
  },
  "final_votes": {
    "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362": true
  },
  "proposer_id": "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362",
  "state": "Accepted"
}
...
...
1 nodes have joined the network..
{
  "nodes": [
    {
      "last_written": 1,
      "node_data": null,
      "node_id": "bc627235893c3396bca568ff3a5100091f7c2498f24dd98bce6e05809597782c",
      "primary": true,
      "rpc_interfaces": {
        "primary_rpc_interface": {
          "bind_address": "0.0.0.0:8080",
          "published_address": "ccf0:8080"
        }
      },
      "status": "Trusted"
    }
  ]
}
Opening Network 1/2: create proposal
Opening Network 2/2: submit proposal to network and vote as accepted
....
{
  "current_service_create_txid": "2.1",
  "current_view": 2,
  "primary_id": "bc627235893c3396bca568ff3a5100091f7c2498f24dd98bce6e05809597782c",
  "recovery_count": 0,
  "service_certificate": "-----BEGIN CERTIFICATE-----\nMIIBuDCCAT6gAwIBAgIRAJGNGbyhbQ0wEVngcsPPEaUwCgYIKoZIzj0EAwMwFjEU\nMBIGA1UEAwwLQ0NGIE5ldHdvcmswHhcNMjIxMjE4MDA0ODMzWhcNMjMxMjE4MDA0\nODMyWjAWMRQwEgYDVQQDDAtDQ0YgTmV0d29yazB2MBAGByqGSM49AgEGBSuBBAAi\nA2IABHpmFXldwHUK5/Lyy9KI2CRvS+eOgbKa7f7S3HiUtiBEy39mzD9UeHHD1hDY\nSKYnKa+/lNrK0SC2h6aHdGrv2cHrJ6/P+ESwDBBuictgRzO+WEtS8dafyLZuwGbC\nXyy7UaNQME4wDAYDVR0TBAUwAwEB/zAdBgNVHQ4EFgQUbiUwFpMCN0AxLUQOOK+D\ntVdyw/cwHwYDVR0jBBgwFoAUbiUwFpMCN0AxLUQOOK+DtVdyw/cwCgYIKoZIzj0E\nAwMDaAAwZQIxAILc5Y5gJni2BlcWwAU2xnSuIYd1+W7y1JAM/SCXcnnENUTBP8lw\nSW+0M45xYUDyFwIwYyGJJ3Ea+tF4VW2db1DaEA7dvdV7hUk+nfzcIxjVWZkpu1r8\nToP+5gPhGvqMFNLz\n-----END CERTIFICATE-----\n",
  "service_data": null,
  "service_status": "Open"
}
Proposing Application 1/1: submit proposal to network and vote as accepted
member0 voting for 191599aff701073901a375d848653ca37b416d859be9021fc5b4e4bfce2a4d8d 
{
  "ballots": {
    "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362": "export function vote (proposal, proposerId) { return true }"
  },
  "final_votes": {
    "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362": true
  },
  "proposer_id": "6522c04702f7ee85c9c56a1694e7d5124c924740849811febd0b5abc41749362",
  "state": "Accepted"
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Governance Completed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~*･゜ﾟ･*:.｡..｡.:*･'(*ﾟ▽ﾟ*)'･*:.｡. .｡.:*･゜ﾟ･*~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Accepting~~Requests~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2022-12-18T00:48:47.031798Z        100 [info ] ../src/host/snapshots.h:273          | Committing snapshot file "snapshot_13_14.committed" [1651]
```

#### 3 Nodes
```bash
$ cd docker
$ docker-compose build
$ docker-compose up -d
```
* edit [docker-compose.yaml Line 16](docker/docker-compose.yaml#L16) to change number of members and users

### SGX  (untested)

You may need to change devices to (this includes the [docker-compose-sgx.yaml](docker/docker-compose-sgx.yaml)) ????

* `/dev/sgx_enclave` -> `/dev/sgx/enclave`
* `/dev/sgx_provision` -> `/dev/sgx/provision`

OR use only

* `/dev/isgx`


#### 1 Node
```bash
$ docker build -t scs-sgx --build-arg platform=sgx -f docker/Dockerfile .
$ docker run -d --name scs-sgx-0 -v /dev/sgx:/dev/sgx \
$ 	--device /dev/sgx_enclave:/dev/sgx_enclave \
$ 	--device /dev/sgx_provision:/dev/sgx_provision \
$	-v $(pwd)/workspace/workspace0:/workspace/workspace0 \
$	-v $(pwd)/sandbox:/sandbox_common \
$	-v $(pwd)/src:/app/src -v $(pwd)/app.json:/app/app.json \
$	-p 8546:8080 scs-sgx <optional cmd> (default: "--members 1 --users 2 --nodes 1")
```
#### 3 Nodes
```bash
$ cd docker
$ docker-compose -f docker-compose-sgx.yaml build
$ docker-compose -f docker-compose-sgx.yaml up -d
```
* edit [docker-compose-sgx.yaml Line 32](docker/docker-compose-sgx.yaml#L32) to change number of members and users


## Run tests

### 1 Node Network
```bash
$ docker exec scs-{virtual or sgx}-0 ./test_app.sh
...
...
Running tests from inside docker container


Testing /app/scs/<userid> GET path failure cases
	✅ [Pass]: /app/scs/<userid> GET fails on nonexistant user
	✅ [Pass]: /app/setup/<userid> GET fails with incorrect userid


Testing /app/setup/<userid> POST path
	✅ [Pass]: /app/setup/<userid> POST fails with incorrect userid
	✅ [Pass]: /app/setup/<userid> POST fails with inconsistant userid and credentials
	✅ [Pass]: /app/setup/<userid> POST fails with invalid hash
	✅ [Pass]: /app/setup/<userid> POST
	✅ [Pass]: /app/setup/<userid> POST fails with existing user


Testing /app/scs/<userid> GET path
	✅ [Pass]: /app/scs/<userid> GET
	✅ [Pass]: /app/scs/<userid> GET fails with inconsistant userid and credentials


Testing /app/scs/<userid> POST path
	✅ [Pass]: /app/scs/<userid> POST fails with invalid hash
	✅ [Pass]: /app/scs/<userid> POST
	✅ [Pass]: /app/scs/<userid> POST result


Testing /app/receipt/<userid> GET path
	✅ [Pass]: Verify receipt


Testing /app/reset path
	✅ [Pass]: /app/reset/<userid> fails with user credentials
	✅ [Pass]: /app/reset/<userid> with member credentials
	✅ [Pass]: /app/reset/<userid> fails when data already deleted


Testing /app/reset/<userid> GET path failures (after reset)
	✅ [Pass]: /app/reset/<userid> GET fails on nonexistant user (after reset)
```

### 3 Node Network
```bash
$ cd docker
$ docker-compose exec ccf0 ./test_app.sh
```

## Update and redeploy app source code
### 1 Node Network

```bash
$ docker exec scs-{virtual or sgx}-0 ./redeploy.sh 1
```

### 3 Node Network

```bash
$ cd docker
$ docker-compose exec ccf0 ./redeploy.sh 2 (number of majority members)
```


## Cleanup
### 1 Node Network
```bash
$ docker stop scs-{virtual or sgx}-0
$ docker rm scs-{virtual or sgx}-0
$ rm -rf $(pwd)/workspace/*
$ rm -rf $(pwd)/sandbox/*
```

### 3 Node Network
```bash
$ cd docker
$ docker-compose {-f docker-compose-sgx.yaml} down 
$ cd ..
$ rm -rf $(pwd)/workspace/*
$ rm -rf $(pwd)/sandbox/*
$ # or if you used volumes
$ docker volume rm scs_sandbox_common
$ docker volume rm scs_workspace
$ # sgx volumes
$ docker volume rm scs_sandbox_common_sgx
$ docker volume rm scs_workspace_sgx
```


## Run SCS JS app locally (untested)

### Dependencies
* nodejs 14
* python 3.8+
  * python ccf library and cryptography library
  
    ```bash
    python3.8 -m pip -r requirements.txt
    ```
* To start a test CCF network on a Linux environment, it requires [CCF to be intalled](https://microsoft.github.io/CCF/main/build_apps/install_bin.html) or you can create a CCF-enabled VM using [Creating a Virtual Machine in Azure to run CCF](https://github.com/microsoft/CCF/blob/main/getting_started/azure_vm/README.md)
  
	```bash
	ls /usr/bin/cchost

	#Virtual
	ls /opt/ccf_virtual/bin/scurl.sh
	ls /opt/ccf_virtual/lib/libjs_generic.virtual.so

	#SGX
	ls /opt/ccf_sgx/bin/scurl.sh
	ls /opt/ccf_sgx/lib/libjs_generic.enclave.so.signed
	```

### 1 Node

* Start node

```bash
$ npm install
$ npm run build
$ cd scripts
$ export platform={virtual or sgx}
$ export NODE_NUM=0
$ ./start.sh
```

* In a seperate terminal run test
```bash
$ ./test.sh
```

* Propose and redeploy app
```bash
$ ./redeploy.sh 1
```

### 3 Node

* First node

```bash
$ npm install
$ npm run build
$ cd scripts
$ export platform={virtual or sgx}
$ export NODE_NUM=0
$ ./start.sh
```

* Second & third nodes (in seperate terminals)
```bash
$ cd scripts
$ export platform={virtual or sgx}
$ export NODE_NUM=<1 or 2>
$ ./start.sh
```

* In a seperate terminal run test
```bash
$ ./test.sh
```

* Propose and redeploy app
```bash
$ ./redeploy.sh 2
```