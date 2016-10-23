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



docker run --env LOG_LEVEL=ERROR -ti local/scapers-muenster fish --command "\
env LOG_LEVEL=ERROR perl muenster-scraper.pl | while read line ;\
    curl --request POST --user admin:password -sS https://elasticsearch.kube.codeformuenster.org/events-testing/event/ --data-raw (echo \$line | jq -c '.')
end"
