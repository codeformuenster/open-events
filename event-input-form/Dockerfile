FROM python:2.7

WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install -r requirements.txt

COPY . /usr/src/app
EXPOSE 5000

CMD ["python", "app.py"]
