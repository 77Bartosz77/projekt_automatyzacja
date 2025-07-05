FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install && npm install express
COPY server.js ./
CMD node server.js