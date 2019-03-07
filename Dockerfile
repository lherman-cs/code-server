FROM node:8.9.3

# Install VS Code's deps. These are the only two it seems we need.
RUN apt-get update
RUN apt-get install -y libxkbfile-dev libsecret-1-dev

# Ensure latest yarn.
RUN npm install -g yarn
# In the future, we can use https://github.com/yarnpkg/rfcs/pull/53 to make it use the node_modules
# directly which should be faster.
WORKDIR /src
COPY . .
RUN yarn --frozen-lockfile

RUN yarn task vscode:install
RUN yarn task build:copy-vscode
RUN yarn task build:web
RUN yarn task build:bootstrap-fork
RUN yarn task build:default-extensions


RUN yarn task build:server:bundle
RUN yarn task build:app:browser
RUN yarn task build:server:binary:package

# We deploy with ubuntu so that devs have a familiar environemnt.
FROM ubuntu:18.10
RUN apt-get update
RUN apt-get install -y openssl
RUN apt-get install -y net-tools
WORKDIR /root/project
COPY --from=0 /src/packages/server/cli-linux-x64   /usr/local/bin/code-server
EXPOSE 8443
# Unfortunately `.` does not work with code-server.
CMD code-server $PWD