#!/usr/bin/env python3
import connexion
import datetime
import logging

from connexion import NoContent
from datetime import datetime
from elasticsearch import Elasticsearch

# our memory-only pet storage
es = Elasticsearch()
EVENTS = {}

def get_events():
    return es.search(index="event") or ('Not found', 404)

def get_event(id):
    return es.get(index="event", doc_type="event", id=id) or ('Not found', 404)

def save_event(id, event):
    es.index(index="event", doc_type="event", id=id, body=event)
    return NoContent, 200

logging.basicConfig(level=logging.INFO)
app = connexion.App(__name__)
app.add_api('open-events-api.yaml')
# set the WSGI application callable to allow using uWSGI:
# uwsgi --http :8080 -w app
application = app.app

if __name__ == '__main__':
    # run our standalone gevent server
    app.run(port=8080, server='gevent')
