FROM openjdk:8

RUN apt-get update && \
	apt-get install -y python3-numpy && \
	apt-get install -y python3-pandas && \
	apt-get install -y python3-sklearn && \
	apt-get install -y r-base && \
	apt-get install -y maven && \
	apt-get install -y build-essential && \
	apt-get install -y libxml2-utils && \
    curl -L https://cpanmin.us | perl - App::cpanminus

WORKDIR /PPgSI

RUN R -e "install.packages('effsize',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('data.table',dependencies=TRUE, repos='http://cran.rstudio.com/')"

RUN apt install vim -y
RUN git clone https://github.com/nicolashampa/jaguar-data-flow-experiments.git

WORKDIR /PPgSI/jaguar-data-flow-experiments/scripts

RUN chmod +x coverage-comparison/*.sh
RUN chmod +x score-ranking/*.sh
RUN chmod +x utils/*.sh