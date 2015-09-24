# Open Events API 

## Install

1. Install strongloop: `[sudo] npm install -g strongloop`
2. Install node modules: `cd loopback-api/open-events;npm install`
3. `npm install loopback-connector-elastic-search --save`

## Run development version

Just as you would with any node application: 
`cd loopback-api/open-events;node .`

# Deploy to production

```bash
npm install pm2 -g
pm2 start .
```
..then it will be running on port 3000. 

## About the data

* Schema.org GeoCoordinate is not compatible with ElasticSearch geo_point type: The names cannot be "longitude" and "latitude" in the elasticsearch index. 
  * ref. https://schema.org/GeoCoordinates vs. https://www.elastic.co/guide/en/elasticsearch/guide/current/lat-lon-formats.html


