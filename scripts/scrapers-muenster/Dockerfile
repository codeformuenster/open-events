FROM perl:5

RUN apt-get update && apt-get install -y netcat
WORKDIR /usr/src/myapp

COPY install.sh /usr/src/myapp/
RUN ./install.sh

COPY . /usr/src/myapp

CMD [ "perl", "./muenster-scraper.pl" ]
