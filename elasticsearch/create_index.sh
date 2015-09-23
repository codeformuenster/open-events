#!/bin/bash
curl -XPUT http://localhost:9200/events -d '{
    "mappings" : {
        "event" : {
            "properties" : {
                "location" : {
                    "properties": {
                        "geo": { "type" : "geo_point" }
                    }
                }
            }
        }
    }
}';
