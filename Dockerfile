FROM debian:jessie

MAINTAINER PharaohKJ <kato@phalanxware.com>

RUN export DEBIAN_FRONTEND=noninteractive LANG
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git ruby make
RUN apt-get clean
RUN git clone -b release https://github.com/PharaohKJ/RTWatcher.git
RUN gem install bundle
RUN cd /RTWatcher && bundle install
ADD config.yml /RTWatcher/
WORKDIR /RTWatcher/

CMD "/bin/bash"
