FROM python:3.10.0b3-alpine3.14
ENV MONGO_MONGODB_USERNAME \
    MONGO_MONGODB_PASSWORD \
    MONGO_MONGODB_SERVER \
    MONGO_MONGODB_DATABASE
WORKDIR /IOTimage
ADD iotapp/main.py /IOTimage
ADD iotapp/requirements.txt /IOTimage/
EXPOSE 8088
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python", "/IOTimage/main.py"]