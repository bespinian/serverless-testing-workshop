FROM docker.io/library/node:20-alpine

ENV NODE_ENV production
WORKDIR /usr/src/app

COPY package*.json .
COPY *.mjs .

RUN npm ci --production --ignore-scripts

USER node
CMD ["npm", "start"]
