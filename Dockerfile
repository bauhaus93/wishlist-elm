FROM node:14

WORKDIR /usr/src/app

COPY package.json ./
RUN npm install --production

COPY . .

RUN scripts/build.sh

CMD ["npm", "start"]

