#!/usr/bin/env python3
from at_client.connections.notification.atevents import AtEvent, AtEventType
from at_client.util.encryptionutil import EncryptionUtil
from at_client.common.keys import AtKey, Metadata, SharedKey
from at_client.common import AtSign
from at_client import AtClient
import threading
import json
import queue
import RPi.GPIO as GPIO
from time import sleep, time
import Adafruit_ADS1x15
import dht11
import datetime

DHT11_PIN = 17
DC_WATER_PUMP = 4 # GPIO PIN = 4

PLANT_ATSIGN_STR = '@qt_plant'
QT_APP_ATSIGN_STR = '@qt_app'
# QT_APP_ATSIGN_STR = '@39gorilla'

plant_atsign = AtSign(PLANT_ATSIGN_STR)
qt_app_atsign = AtSign(QT_APP_ATSIGN_STR)

GPIO.setmode(GPIO.BCM)
GPIO.setup(DC_WATER_PUMP, GPIO.OUT)
adc = Adafruit_ADS1x15.ADS1115()
GAIN = 1
instance = dht11.DHT11(pin=DHT11_PIN)

def run_pump_for_seconds(seconds: int, verbose: bool = True):
    # run pump for `q_seconds`
    if(verbose):
        print('Running pump for %s seconds' % seconds)
        print('Pump ON HIGH')
    GPIO.output(DC_WATER_PUMP, GPIO.HIGH)
    sleep(seconds)
    if(verbose):
        print('Pump OFF LOW')
    GPIO.output(DC_WATER_PUMP, GPIO.LOW)
    
# flushes `notify:list` `
def clear_all_notifications(atclient: AtClient, regex: str = 'qtplant'):
    notifications = atclient.secondary_connection.execute_command('notify:list %s' %(regex), retry_on_exception=3)
    # strip `data:` from string
    notifications = str(notifications)[5:]
    print('notifications: %s' % notifications)
    # split by ,
    if notifications != 'null':
        notifications = json.loads(notifications)
        for notification in notifications:
            notification_id = notification['id']
            print('Removing notification with id `%s`' % notification_id)
            response = atclient.secondary_connection.execute_command('notify:remove:' + str(notification_id), retry_on_exception=3)
            print(response)
    else:
        return 0
    
def notify_data(client: AtClient, payload):
    timestamp = time()
    #print type of data and value
#    print("Type (%s): %s" %(type(payload), payload))
    data = {
        'type': 'sensorData',
        'timestamp': timestamp,
        'data': payload
    }

    data = json.dumps(data)
    sharedkey = SharedKey.from_string(str(qt_app_atsign) + ':sensors.qtplant' + str(plant_atsign))
    iv_nonce = EncryptionUtil.generate_iv_nonce()
    metadata = Metadata(
    #ttl = 3 second in miliseconds
        ttl=3000,
        ttr=-1,
        iv_nonce=iv_nonce,
    )
    sharedkey.metadata = metadata
    sleep(0.5)
    res = client.notify(sharedkey, data)
    print('Notification ID: %s' % res)
    print('SharedKey: %s' % sharedkey)
    print('Data: %s' % data)
    
def log_data(client: AtClient):
    values = [0]*4
    for i in range(4):
        values[i] = adc.read_adc(i, gain=GAIN)
    MIN = 0
    MAX = 1023
    water_level = (values[0] - MIN) / (MAX - MIN)
    soil_moisture = (values[1] - MIN) / (MAX - MIN)
    result = instance.read()
    while not result.is_valid():
        result = instance.read()
    temperature = result.temperature
    humidity = result.humidity
    timestamp = time()
    # get mm, dd, yyyy
    mm = int(datetime.datetime.fromtimestamp(timestamp).strftime('%m'))
    dd = int(datetime.datetime.fromtimestamp(timestamp).strftime('%d'))
    yyyy = int(datetime.datetime.fromtimestamp(timestamp).strftime('%Y'))
    
    timestamp_sharedkey = SharedKey.from_string(str(qt_app_atsign) + ':' + str(timestamp) + '.datapoints.qtplant' + str(plant_atsign))
    timestamp_sharedkey_data = {
        'water_level': water_level,
        'soil_moisture': soil_moisture,
        'temperature': temperature,
        'humidity': humidity,
        'timestamp': str(timestamp)
    }
    notify_data(client, timestamp_sharedkey_data)
    timestamp_sharedkey_data = json.dumps(timestamp_sharedkey_data)
    timestamp_sharedkey.metadata = Metadata(
        ttr = -1, # do not refersh, this data will never change
        ccd = True, # if plant deletes it, the app will not be able to read it
    )
    
    day_timestamps_sharedkey = SharedKey.from_string(str(qt_app_atsign) + ':' + str(mm) + '-' + str(dd) + '-' + str(yyyy) + '.days.qtplant' + str(plant_atsign))
    day_timestamps_sharedkey.metadata = Metadata(
        ttr = -1, # do not refersh, this data will never change
        ccd = True, # if plant deletes it, the app will not be able to read it
    )
    
        
    try:
        day_timestamps_sharedkey_data = client.get(day_timestamps_sharedkey)
        day_timestamps_sharedkey_data = day_timestamps_sharedkey_data[1:-1] # remove brackets
        day_timestamps_sharedkey_data = day_timestamps_sharedkey_data.split(', ') # split by comma
        day_timestamps_sharedkey_data = [float(timestamp) for timestamp in day_timestamps_sharedkey_data]
        day_timestamps_sharedkey_data.append(timestamp) # append timestamp
        day_timestamps_sharedkey_data.sort()        
    except:
        day_timestamps_sharedkey_data = [timestamp]
    day_timestamps_sharedkey_data = '[' + ', '.join([str(timestamp) for timestamp in day_timestamps_sharedkey_data]) + ']'
    
    print('Logging data to key `' + str(timestamp_sharedkey) + '` with data `' + str(timestamp_sharedkey_data) + '`')
    client.put(timestamp_sharedkey, str(timestamp_sharedkey_data))
    print('Logged.')
    
    print('Logging data to key `' + str(day_timestamps_sharedkey) + '` with data `' + str(day_timestamps_sharedkey_data) + '`')
    client.put(day_timestamps_sharedkey, day_timestamps_sharedkey_data)
    print('Logged.')
    
    
    
 
def main():    
    # start monitor on a thread
    atclient = AtClient(plant_atsign, queue=queue.Queue(maxsize=100), verbose=False)
    threading.Thread(target=atclient.start_monitor, args=("qtplant",)).start()

    while True:
        try:
            at_event = atclient.queue.get(block=False)
            event_type = at_event.event_type
            event_data = at_event.event_data
                        
            if event_type == AtEventType.UPDATE_NOTIFICATION:
                    atclient.handle_event(atclient.queue, at_event)
                    cmd = "notify:remove:" + str(event_data["id"])
                    print('executing \'%s\'' %(cmd))
                    atclient.secondary_connection.execute_command(cmd, retry_on_exception=3)
                    print('executed \'%s\'' %(cmd))
                    pass
            if event_type != AtEventType.DECRYPTED_UPDATE_NOTIFICATION:
                    continue
            try:
                decrypted_value_dict = json.loads(event_data['decryptedValue'])
            except:
                print('(1) Failed to parse `%s`' % event_data['decryptedValue'])
                continue
            
            try:
                q_type: str = decrypted_value_dict['type']
                q_timestamp: float = decrypted_value_dict['timestamp']
                q_data: dict = decrypted_value_dict['data']
                print("\nType (%s): %s" %(type(q_type), q_type))
                print("Timestamp (%s): %s" %(type(q_timestamp), q_timestamp))
                print("Data (%s): %s" %(type(q_data), q_data))
                if q_type == 'pumpWithSeconds':
                    q_seconds: int = q_data['seconds']
                    print("Seconds (%s): %s\n" %(type(q_seconds), str(q_seconds)))
                    run_pump_for_seconds(q_seconds)
                    clear_all_notifications(atclient)
            except Exception as e:
                # print(e)
                pass
        except Exception as e:
            # print(e)p
            print('No events in queue.')
            pass
        ss = datetime.datetime.now().second
        # log_data every 5 seconds
        if ss % 5 == 0:
            log_data(atclient)
            pass
        sleep(1)

if __name__ == '__main__':
    main()
