ARG NODE_VERSION=12

FROM nvm:node AS appbuild

WORKDIR /usr/src/app

ADD ["package.json", "src", "./"]

RUN \
	source /usr/local/nvm/nvm.sh && \
	nvm install $NODE_VERSION && \
	nvm use $NODE_VERSION && \
	npm install && \
	npm run build

ENV PATH /usr/local/nvm/versions/node/v$NODE_VERSION/bin:$PATH


FROM nvm:node

WORKDIR /usr/src/app

ADD ["package.json", "src", "./"]

RUN \
	source /usr/local/nvm/nvm.sh && \
	nvm install $NODE_VERSION && \
	nvm use $NODE_VERSION && \
	npm install && \
	npm run build

COPY --from=appbuild /usr/src/app/dist ./dist

EXPOSE 4002

CMD npm start
