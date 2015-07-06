#!/usr/bin/env bash

while [[ ! $(nc -zv logstash 7001 && echo $?) ]]; do sleep 2; done

while :
do
  echo "scraping to logstash."
  node fzw-scraper.js | cat > test2.txt
  cat test2.txt | nc -q 30 logstash 7001
  sleep 10800
done
