#!/usr/bin/env python3
import connexion
import datetime
import logging
import requests
from elasticsearch import Elasticsearch
from connexion import NoContent
import json

es = Elasticsearch([{'host': 'localhost', 'port': 9200}])

app = connexion.App(__name__, specification_dir='swagger/')



# our memory-only pet storage
EVENTS = {}


def get_events(lat, lon, radius=10, start_date="", end_date="", query="", category=""):
    return [1,2,3]


def get_event(id):
    pet = es.get(id)
    return pet or ('Not found', 404)


def save_event(id, event):

    es.index(index='event', doc_type='event', id=id, body=event)

    exists = 0
    event['id'] = id
    if exists:
        logging.info('Updating pet %s..', id)
    else:
        logging.info('Creating pet %s..', id)
        event['created_date'] = datetime.datetime.utcnow()
    return NoContent, (200 if exists else 201)

app.add_api('open-events-api.yaml')


logging.basicConfig(level=logging.INFO)
# set the WSGI application callable to allow using uWSGI:
# uwsgi --http :8080 -w app
application = app.app

if __name__ == '__main__':
    # run our standalone gevent server
    app.run(port=8080, server='gevent')
