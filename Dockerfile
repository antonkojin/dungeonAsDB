FROM python:3

WORKDIR /code

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# EXPOSE 8000
WORKDIR /code/webapp
# CMD [ "gunicorn", "--log-level", "debug", "-b", ":8000", "webapp.wsgi" ]
# CMD [ "python", "./manage.py", "runserver", "0.0.0.0:8000"]

