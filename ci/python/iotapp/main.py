from flask import Flask, jsonify, request
from flask_mongoengine import MongoEngine
from prometheus_flask_exporter import PrometheusMetrics

import os

app = Flask(__name__)
username = os.getenv('MONGO_MONGODB_USERNAME')
password = os.getenv('MONGO_MONGODB_PASSWORD')
server = os.getenv('MONGO_MONGODB_SERVER')
database = os.getenv('MONGO_MONGODB_DATABASE')
port = '27017'

app.config['MONGODB_SETTINGS'] = {
    'db': database,
    'host': "mongodb://{}:{}@{}:{}/{}?authSource=admin".format(username, password, server, port, database)
}

db = MongoEngine(app)

metrics = PrometheusMetrics(app)

class Sensors(db.Document):
    device = db.IntField()
    temperature = db.FloatField()
    humidity = db.FloatField()
    pressure = db.FloatField()
    latitude = db.FloatField()
    longitude = db.FloatField()
    altitude = db.FloatField()
    time = db.FloatField()
    analog1 = db.FloatField()
    analog2 = db.FloatField()
    digital1 = db.IntField()
    digital2 = db.IntField()

class Relays(db.Document):
    device = db.IntField()
    relay1 = db.IntField()
    relay2 = db.IntField()
    power_mode = db.IntField()
    transfer_mode = db.IntField()

@app.route('/db')
def test_page():
    startpage = Relays.objects()
    return  jsonify(startpage), 200

@app.route('/test')
def hello_page():
    return 'Hello, page from flask!'

@app.route('/getsensor/<id>')
def  get_sensors(id: str):
    sensors = Sensors.objects.first_or_404(device=id)
    return  jsonify(sensors), 200

@app.route('/getrelay/<id>')
def  get_relays(id: str):
    relays = Relays.objects.first_or_404(device=id)
    return  jsonify(relays), 200

@app.route('/setrelay/<id>', methods=["PUT"])
def update_relays(id):
    body = request.get_json()
    relays = Relays.objects.get_or_404(device=id)
    relays.update(**body)
    return True

@app.route('/setsensor/<id>', methods=['PUT'])
def update_sensors(id):
    body = request.get_json()
    sensors = Sensors.objects.get_or_404(device=id)
    sensors.update(**body)
    return True

@app.route('/addrelay/', methods=['POST'])
def add_relays():
    body = request.get_json()
    relay = Relays()
    relay.device = body.get("device")
    relay.relay1 = body.get("relay1")
    relay.relay2 = body.get("relay2")
    relay.power_mode = body.get("power_mode")
    relay.transfer_mode = body.get("transfer_mode")
    relay.save()
    return jsonify(relay), 201

@app.route('/addsensor/', methods=['POST'])
def add_sensors():
    body = request.get_json()
    sensor = Sensors()
    sensor.device = body.get("device")
    sensor.temperature = body.get("temperature")
    sensor.humidity = body.get("humidity")
    sensor.pressure = body.get("pressure")
    sensor.latitude = body.get("latitude")
    sensor.longitude = body.get("longitude")
    sensor.altitude = body.get("altitude")
    sensor.time = body.get("time")
    sensor.analog1 = body.get("analog1")
    sensor.analog2 = body.get("analog2")
    sensor.digital1 = body.get("digital1")
    sensor.digital2 = body.get("digital2")

if __name__ == "__main__":
    print("Ready to start app...")
    app.run(host='0.0.0.0', port=8088, debug=False)