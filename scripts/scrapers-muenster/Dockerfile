FROM ubuntu

RUN apt-get update && apt-get install -y perl cpanminus make gcc curl jq fish \
  libdatetime-perl libxml-libxml-perl

RUN cpanm -i Config::IniFiles \
  && cpanm -i XML::Feed \
  && cpanm -i Time::ParseDate \
  && cpanm -i JSON \
  && cpanm -i Digest::SHA \
  && cpanm -i DBI \
  && cpanm -i HTML::TreeBuilder::XPath

WORKDIR /usr/src/myapp
COPY . /usr/src/myapp

CMD [ "perl", "./muenster-scraper.pl" ]
