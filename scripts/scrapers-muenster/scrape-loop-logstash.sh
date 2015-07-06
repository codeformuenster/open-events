#!/usr/bin/env bash

while [[ ! $(nc -zv logstash 7001 && echo $?) ]]; do sleep 2; done

while :
do
  echo "scraping to logstash."
  perl muenster-scraper.pl | cat > test2.txt
  cat test2.txt | nc -q 30 logstash 7001
  sleep 10800
done
