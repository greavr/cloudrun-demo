FROM nginx:alpine

LABEL maintainer="Rgreaves@google.com"

COPY Code/ /usr/share/nginx/html

EXPOSE 80