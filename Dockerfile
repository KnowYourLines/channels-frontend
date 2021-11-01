# build stage
FROM node:lts-alpine as build-stage
ENV VUE_APP_BACKEND_URL https://channels-backend.herokuapp.com
ENV VUE_APP_FIREBASE_API_KEY AIzaSyDDEtNW4mCP6BqaegpNJZaFaepObxgwV-Q
ENV VUE_APP_FIREBASE_AUTH_DOMAIN channels-efc02.firebaseapp.com
ENV VUE_APP_FIREBASE_PROJECT_ID channels-efc02
ENV VUE_APP_FIREBASE_STORAGE_BUCKET channels-efc02.appspot.com
ENV VUE_APP_FIREBASE_MESSAGING_SENDER_ID 874229818669
ENV VUE_APP_FIREBASE_APP_ID 1:874229818669:web:25e9c168b4319945125fa4
ENV VUE_APP_FIREBASE_MEASUREMENT_ID G-T9ZBBM3GGF
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# production stage
FROM nginx:stable-alpine as production-stage
COPY nginx.conf /etc/nginx/conf.d/configfile.template
COPY --from=build-stage /app/dist /usr/share/nginx/html
ENV PORT 8080
ENV HOST 0.0.0.0
EXPOSE 8080
CMD sh -c "envsubst '\$PORT' < /etc/nginx/conf.d/configfile.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
