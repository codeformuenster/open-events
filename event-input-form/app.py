import socket
import json
import sys

from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

HOST = 'logstash'
PORT = 7001

@app.route('/event', methods=['POST'])
def event():
    # FIXME! try/except
    event_json = request.get_json()
    app.logger.debug(event_json)

    try:
      sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    except socket.error, msg:
      app.logger.error(msg[1])
      abort()

    try:
      sock.connect((HOST, PORT))
    except socket.error, msg:
      app.logger.error(msg[1])
      abort

    # msg = {'@message': 'python test message', '@tags': ['python', 'test']}

    sock.send(json.dumps(event_json)+"\n")
    sock.close()
    return ""


@app.route('/', methods=['GET'])
def home():
    return render_template('index.html')


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
