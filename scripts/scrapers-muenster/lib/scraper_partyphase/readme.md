# partyphase.de scraper
This is a ruby scraper for Partyphase Münster (http://muenster.partyphase.net).
The output format is JSON lines according to the specified API requirements.

## TODO

- Extension to allow the scraping of any available city at Partyphase

## Requirements

Bundler gem: `gem install bundler`

## Install

Run `bundle install` inside scraper_partyphase folder to install all dependencies

## How to scrape the events

run scrapers with

   `ruby scraper_partyphase.rb [file_name]`

### Run Examples

   `ruby scraper_partyphase.rb scraped_content.jsonl`
