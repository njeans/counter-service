# CCF Implementation of State Continuity Counter Service
### Run JS app

```bash
$ npm  install
$ npm run build
```

### Docker

It is possible to build a runtime image of the JavaScript application via docker:

```bash
$ docker build -t ccf-app-template:js-enclave -f docker/ccf_app_js.enclave .
$ docker run --device /dev/sgx_enclave:/dev/sgx_enclave --device /dev/sgx_provision:/dev/sgx_provision -v /dev/sgx:/dev/sgx ccf-app-template:js-enclave
...
2022-01-01T12:00:00.000000Z -0.000 0   [info ] ../src/node/node_state.h:1790        | Network TLS connections now accepted

# Now the CCF service is started and member governance is needed to allow trusted users to interact with the deployed application
```

Or, for the non-SGX (a.k.a. virtual) variant:

```bash
$ docker build -t ccf-app-template:js-virtual -f docker/ccf_app_js.virtual .
$ docker run ccf-app-template:virtual
```

#### Network governance

The CCF network is started with one node and one member, you need to execute the following governance steps to initialize the network

- [Activate the network existing member to start a network governance](https://microsoft.github.io/CCF/main/governance/adding_member.html#activating-a-new-member)
- Build the application and [create a deployment proposal](https://microsoft.github.io/CCF/main/build_apps/js_app_bundle.html#deployment)
- Deploy the application proposal, [using governance calls](https://microsoft.github.io/CCF/main/governance/proposals.html#submitting-a-new-proposal)
- Create and submit [an add users proposal](https://microsoft.github.io/CCF/main/governance/open_network.html#adding-users)
- Open the network for users ([using proposal](https://microsoft.github.io/CCF/main/governance/open_network.html#opening-the-network))

### Bare VM

The application can be tested using `cchost` on Linux environment.
To start a test CCF network on a Linux environment, it requires [CCF to be intalled](https://microsoft.github.io/CCF/main/build_apps/install_bin.html) or you can create a CCF-enabled VM using [Creating a Virtual Machine in Azure to run CCF](https://github.com/microsoft/CCF/blob/main/getting_started/azure_vm/README.md)

```bash
# Start the CCF network using the cchost in

# Enclave mode
 /opt/ccf/bin/cchost --config ./config/cchost_config_enclave_js.json

# Or Virtual mode
/opt/ccf/bin/cchost --config ./config/cchost_config_virtual_js.json
...

 # Now the CCF network is started and further initialization needed before the interaction with the service
```

The CCF network is started with one node and one member, please follow the [same governance steps as Docker](#network-governance) to initialize the network and check [CCF node config file documentation](https://microsoft.github.io/CCF/main/operations/configuration.html)


### Managed CCF

The application can be tested using [Azure Managed CCF](https://techcommunity.microsoft.com/t5/azure-confidential-computing/microsoft-introduces-preview-of-azure-managed-confidential/ba-p/3648986) ``(Pre-release phase)``, you can create Azure Managed CCF serivce on your subscription, that will give you a ready CCF network

- First, create the network's initial member certificate, please check [Certificates generation](https://microsoft.github.io/CCF/main/governance/adding_member.html)
- Create a new Azure Managed CCF serivce (the initial member certificate required as input)
- Build the application and [create a deployment proposal](https://microsoft.github.io/CCF/main/build_apps/js_app_bundle.html#deployment)
- Deploy the application proposal, [using governance calls](https://microsoft.github.io/CCF/main/governance/proposals.html#creating-a-proposal)
- Create and submit [an add users proposal](https://microsoft.github.io/CCF/main/governance/proposals.html#creating-a-proposal)


## Dependencies

* nodejs 14

See the [CCF official docs](https://microsoft.github.io/CCF/main/build_apps/install_bin.html#install-ccf) for more info and [Modern JavaScript application development](https://microsoft.github.io/CCF/main/build_apps/js_app_bundle.html).