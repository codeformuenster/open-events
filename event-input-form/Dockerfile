FROM python:2.7

WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install -r requirements.txt

COPY . /usr/src/app
EXPOSE 5000

CMD ["python", "app.py"]

# $ sudo docker build -t local/event-input-form .
# $ sudo docker run -p 5000:5000 local/event-input-form
# $ xdg-open http://localhost:5000/static/index.html
