FROM node:18-alpine as build
WORKDIR /app
# ENV PATH /app/node_modules/.bin:$PATH
COPY package.json ./
COPY package-lock.json ./
RUN npm ci
COPY . ./
RUN npm run build

FROM pierrezemb/gostatic
# COPY ./dist/ /srv/http/
COPY --from=build /app/dist /srv/http/
ENTRYPOINT ["/goStatic"]
