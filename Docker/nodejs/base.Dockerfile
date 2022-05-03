FROM debian:latest

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# and install dependencies
RUN apt-get update \
    && apt-get install -y curl ruby-full \
    && apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 6.11.0

RUN \
    apt-get update && apt-get install -y build-essential libssl-dev python python3 gnupg2 && \
    curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && \
    source /usr/local/nvm/nvm.sh

CMD ["bash", "-l"]