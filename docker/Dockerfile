ARG platform=sgx

# Build
FROM mcr.microsoft.com/ccf/app/dev:3.0.1-virtual as builder-virtual

FROM mcr.microsoft.com/ccf/app/dev:3.0.1-sgx as builder-sgx

# Run
FROM mcr.microsoft.com/ccf/app/run-js:3.0.1-virtual as run-virtual

FROM mcr.microsoft.com/ccf/app/run-js:3.0.1-sgx  as run-sgx

# Final
FROM run-${platform} as final
RUN apt-get update && apt-get install -y jq curl

# Python 3.8
RUN apt-get install -y \
                python3.8 \
                python3.8-dev \
                python3-pip \
                python3.8-venv \
        && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN python3.8 -m pip install -r requirements.txt
# Node 14
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
        apt-get install -y nodejs

EXPOSE 8080/tcp
EXPOSE 8081/tcp

ARG platform=virtual
ENV platform $platform
# ENV PYTHONPATH "/opt/ccf/bin"
ENV deployment_location "DOCKER"
ENV NODE_NUM "0"

# Note: libjs_generic.virtual is not included in run-js container
COPY --from=builder-virtual /opt/ccf_virtual/lib/libjs_generic.virtual.so /usr/lib/ccf
RUN cp -r /opt/ccf_${platform}  /opt/ccf
HEALTHCHECK CMD curl --fail https://localhost:8080/node/commit --cacert /sandbox_common/service_cert.pem || exit 1

WORKDIR /sandbox_common/

WORKDIR /shared/
COPY ./shared/ /shared/

COPY . /app/
COPY ./config/cchost_config_${platform}_js_docker_start.json /app/config/config_start.json
COPY ./config/cchost_config_${platform}_js_docker_join_1.json /app/config/config_join_1.json
COPY ./config/cchost_config_${platform}_js_docker_join_2.json /app/config/config_join_2.json

WORKDIR /app/
RUN npm install
RUN npm run build
WORKDIR /app/scripts
ENTRYPOINT ["./start.sh"]
CMD ["--members", "1", "--users", "2", "--nodes", "1"]
