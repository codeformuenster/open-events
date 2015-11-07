!Elasticsearch Open Events Database

Example queries
```bash
curl -XGET localhost:9200/events/event/_search?pretty=true -d '
{
         "query" : {
             "match_all" : {}
         },
         "filter" : {
             "geo_distance" : {
                 "distance" : "10km",
                 "event.location.geo" : {
                     "lat" : "51.96066",
                     "lon" : "7.62613"
                 }
             }
         }
}
'
```
