FROM mirror.gcr.io/node:20-alpine AS builder
ARG NPM_REGISTRY=https://registry.npmjs.org
RUN npm --registry $NPM_REGISTRY install npm -g

COPY package.json /package.json
COPY _common /_common
RUN npm --registry $NPM_REGISTRY install --omit=optional

COPY src /src
COPY tsconfig.json /tsconfig.json

RUN npm run build

COPY default_config.toml /dist/config.toml

RUN node /dist/app.js --version

FROM mirror.gcr.io/node:20-alpine

USER root

ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

WORKDIR /template

ENTRYPOINT [ "node" ]
CMD [ "app.js", "--config", "config.toml" ]


COPY --from=builder /dist /template

RUN chown -R node:node /template
USER node

RUN node --version && \
    npm --version && \
    cd /template && \
    npm ci && \
    node app.js -v