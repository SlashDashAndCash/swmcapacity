FROM docker.io/library/debian:bullseye-slim

WORKDIR /usr/src/app

COPY . ./
RUN apt-get update && \
 apt-get upgrade -y && \
 apt-get install -y ruby ruby-json ruby-nokogiri ruby-pg && \
 apt-get clean

CMD ["ruby", "/usr/src/app/swmcapacity.rb"]
