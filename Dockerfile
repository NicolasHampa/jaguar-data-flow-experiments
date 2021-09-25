FROM openjdk:8

RUN apt-get update && \
	apt-get install -y python2.7 && \
	apt-get install -y python3-numpy && \
	apt-get install -y python3-pandas && \
	apt-get install -y python3-sklearn && \
	apt-get install -y vim && \
	apt-get install -y maven && \
	apt-get install -y build-essential && \
	apt-get install -y libxml2-utils && \
    curl -L https://cpanmin.us | perl - App::cpanminus

RUN mkdir -p /var/log

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.0-amd64.deb && \
    dpkg -i filebeat-7.13.0-amd64.deb

COPY filebeat.yml /etc/filebeat/filebeat.yml
RUN chmod go-w /etc/filebeat/filebeat.yml

RUN filebeat setup
RUN service filebeat start

WORKDIR /PPgSI

RUN git clone https://github.com/nicolashampa/jaguar-data-flow-experiments.git

WORKDIR /PPgSI/jaguar-data-flow-experiments

RUN chmod +x scripts/coverage-comparison/*.sh
RUN chmod +x scripts/score-ranking/*.sh
RUN chmod +x scripts/utils/*.sh