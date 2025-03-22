FROM python:3.10

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE 1

WORKDIR /app

COPY ./requirements.txt ./requirements.txt

RUN pip install -r requirements.txt --no-cache-dir

COPY . .

EXPOSE 8000

RUN chmod +x ./entrypoint.sh

CMD ["./entrypoint.sh"]
