# Build
FROM mcr.microsoft.com/ccf/app/dev:3.0.0-rc2-virtual as builder

# Run
FROM mcr.microsoft.com/ccf/app/run-js:3.0.0-rc2-virtual
RUN apt-get update && apt-get install -y jq curl vim
# Python 3.8
RUN apt-get install -y \
                python3.8 \
                python3.8-dev \
                python3-pip \
                python3.8-venv \
                git \
        && rm -rf /var/lib/apt/lists/*

# Node 14
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
        apt-get install -y nodejs

# Note: libjs_generic.virtual is not included in run-js container
COPY --from=builder /opt/ccf_virtual/lib/libjs_generic.virtual.so /usr/lib/ccf

ENV deployment_location "DOCKER"
ENV PYTHONPATH "/opt/ccf_virtual/bin"

EXPOSE 8080/tcp
EXPOSE 8081/tcp

COPY . /app/

WORKDIR /app/
RUN npm install
RUN npm run build 

CMD ["/opt/ccf_virtual/bin/sandbox.sh", "--js-app-bundle", "/app/dist/", "--initial-member-count", "1", "--initial-user-count", "1", "-v", "--config-file", "/app/config/cchost_config_virtual_js.json"]