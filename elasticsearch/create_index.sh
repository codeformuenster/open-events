#!/bin/bash
curl -XPUT http://localhost:9200/events -d '{
    "mappings" : {
        "event" : {
            "properties" : {
                "venue" : {
                    "properties": {
                        "location": { "type" : "geo_point" }
                    }
                }
            }
        }
    }
}';
