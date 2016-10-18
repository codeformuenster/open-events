
# Münster scrapers

## Install

docker build . -t scrapers

run install.pl to install necessary CPAN packages


# Run container

sudo docker run -v $PWD:/usr/src/myapp -ti scrapers bash

# Inside container

## How to scrape the events

run scrapers with

   perl muenster-scraper.pl [locationName]

### Run Examples

to scrape all locations

   perl muenster-scraper.pl

to scrape only hot jazz club

   perl muenster-scraper.pl hotjazzclub


## run production mode

to return only valid json and no debug messages, run:

    LOG_LEVEL=ERROR perl muenster-scraper.pl
