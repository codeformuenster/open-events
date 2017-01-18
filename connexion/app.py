#!/usr/bin/env python3
"""
Open events JSON Rest API
Uses Conexxion to serve REST API via SWAGGER file

"""

import datetime
import logging
from elasticsearch import Elasticsearch
from datetime import date
from datetime import timedelta
import connexion

from connexion import NoContent

# global objects
ES = Elasticsearch([{'host': 'localhost', 'port': 9200}])
APP = connexion.App(__name__, specification_dir='swagger/')

# config
ES_INDEX_NAME = 'events'
ES_DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


def get_events(lat, lon, radius=10, start_date="", end_date="", query="", category=""):
    """Return the pathname of the KOS root directory."""

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
                "must": {
                    "range": {
                        "start_date": {
                            "gte": start_date,
                            "lte": end_date
                        }
                    }
                },
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

    res = ES.search(index=ES_INDEX_NAME, body=query)
    logging.info("Got %d Hits:", res['hits']['total'])
    logging.info(res)

    for hit in res['hits']['hits']:
        logging.info(hit)

    return list(res.values())


def get_event(id):
    pet = ES.get(index=ES_INDEX_NAME, doc_type='event', id=id)
    return pet or ('Not found', 404)


def create_event(event):
    save_event(None, event)


def save_event(event_id, event):

    result = ES.index(index=ES_INDEX_NAME, doc_type='event', id=event_id, body=event)
    logging.info(result)
    created = result['created']

    event['id'] = event_id

    if created:
        logging.info('Creating event %s..', event_id)
        event['created_date'] = datetime.datetime.utcnow()
    else:
        logging.info('Updating event %s..', event_id)

    return NoContent, (201 if created else 200)

APP.add_api('open-events-api.yaml')


logging.basicConfig(level=logging.INFO)
# set the WSGI application callable to allow using uWSGI:
# uwsgi --http :8080 -w app
application = APP.app

if __name__ == '__main__':
    # run our standalone gevent server
    APP.run(port=8080, server='gevent')
