#!/usr/bin/env python
### create file appconfig.py
### requires application & ENV id in this format
### copy the text below and adjust in appconfig.py
### applications = [('app-name', 'XXXXXX-XXXXX-XXXXX'),
#### print(applications, "printing APP and env_id")               


""" Mulesoft log collection script in json format output
"""
import requests
import json
import time
import datetime
from dateutil.relativedelta import *
import schedule
import time
import appconfig
import os
import random
import cherrypy
from threading import Thread


def unix_time_millis(timestamp):
    return round((timestamp - epoch).total_seconds() * 1000.0)


def get_logs_from_app(app_name, env_id):
    url2 = "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/{}/logs".format(app_name)
    headers2 = {
        'authorization': "{}".format(os.environ['auth_key']),
        'X-ANYPNT-ENV-ID': '{}'.format(env_id),
        'content-type': 'application/json'
    }

    data = {'deploymentId': '',
            'startTime': '{}'.format(now_string),
            'endTime': '{}'.format(earlier_string)
            }
    r = requests.request("POST", url2, data=json.dumps(data), headers=headers2)
    if len(r.text) > 3:
        return r.text
    else:
        return ""


def job():
    applications = appconfig.applications
    for app in applications:
        print(get_logs_from_app(app[0], app[1]))


class Refapp(object):
    @cherrypy.expose
    def index(self):
        return 'I didn\'t do nothing never'

    @cherrypy.expose
    def healthcheck(self):
        return 'I am an HTTP server'


def cherrypystart():
    cherrypy.config.update({
        'environment': 'production',
        'server.socket_host': '0.0.0.0',
        'server.socket_port': 8080,
        'log.screen': True
    })
    cherrypy.quickstart(Refapp())  ####cherrypy healthcheck


if __name__ == '__main__':
    t = Thread(target=cherrypystart)
    t.start()
    epoch = datetime.datetime.utcfromtimestamp(0)
    NOW = datetime.datetime.now()
    earlier = NOW + relativedelta(minutes=-10)
    now_string = unix_time_millis(NOW)
    earlier_string = unix_time_millis(earlier)

    schedule.every(10).minutes.do(job)

    while True:
        schedule.run_pending()
        time.sleep(60)
        print("the time is", datetime.datetime.now())