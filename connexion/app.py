#!/usr/bin/env python3
"""
Open events JSON Rest API
Uses Conexxion to serve REST API via SWAGGER file

"""

import datetime
import logging
from datetime import date, timedelta
from elasticsearch import Elasticsearch
import connexion


# global objects
ES = Elasticsearch([{'host': 'localhost', 'port': 9200}])
APP = connexion.App(__name__, specification_dir='swagger/')

# config
ES_INDEX_NAME = 'events'
ES_DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


def get_events(lat, lon, radius=10, start_date="", end_date="", query="",
               category=""):
    """Return events"""

    querystring = query

    if not start_date:
        today = date.today()
        start_date = today.strftime(ES_DATE_FORMAT)
        logging.info("start_date %s", start_date)

    if not end_date:
        future = date.today() + timedelta(days=120)
        end_date = future.strftime(ES_DATE_FORMAT)
        logging.info("end_date %s", end_date)

    query = {
        "query": {
            "bool": {
                "must": [
                    {
                        "range": {
                            "start_date": {
                                "gte": start_date,
                                "lte": end_date
                            }
                        }
                    }
                ],
                "filter": {
                    "geo_distance": {
                        "distance": "%dkm" % radius,
                        "venue.location": {
                            "lat": lat,
                            "lon": lon
                        }
                    }
                }
            }
        }
    }
    if querystring:
        query["query"]["bool"]["should"] = [
            {"match": {"title": querystring}},
            {"match": {"description": querystring}},
            {"match": {"venue.name": querystring}},
            {"match": {"tags": querystring}},
            {"match": {"category": querystring}}
        ]
        query["query"]["bool"]["minimum_should_match"] = 1

    if category:
        query["query"]["bool"]["must"].append(
            {"match": {"category": category}}
        )

    res = ES.search(index=ES_INDEX_NAME, body=query)
    logging.info(query)
    logging.info("\nGot %d Hits.", res['hits']['total'])

    response = []
    for hit in res['hits']['hits']:
        response.append(hit['_source'])

    return response


def get_event(event_id):
    """Return single event"""

    pet = ES.get(index=ES_INDEX_NAME, doc_type='event', id=event_id)
    return pet or ('Not found', 404)


def create_event(event):
    """Create  event"""
    save_event(None, event)
    return {"code": 321, "message": "Event was created"}


def save_event(event_id, event):
    """update event"""
    result = ES.index(index=ES_INDEX_NAME, doc_type='event', id=event_id,
                      body=event)
    logging.info(result)
    created = result['created']

    event['id'] = event_id

    message = "", 0
    if created:
        message = 'Creating event %s..', event_id
        event['created_date'] = datetime.datetime.utcnow()
    else:
        message = 'Updating event %s..', event_id

    return {"code": 123, "message": message}, (201 if created else 200)

APP.add_api('open-events-api.yaml', strict_validation=True,
            validate_responses=True)


logging.basicConfig(level=logging.INFO)
# set the WSGI application callable to allow using uWSGI:
# uwsgi --http :8080 -w app
application = APP.app

if __name__ == '__main__':
    # run our standalone gevent server
    APP.run(port=8080, server='gevent')
