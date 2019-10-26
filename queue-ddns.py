
#!/usr/bin/env python
import json
import logging as log
from kombu import BrokerConnection
from kombu import Exchange
from kombu import Queue
from kombu.mixins import ConsumerMixin
from configparser import RawConfigParser

# Load our user/pass, project, message queue params from ini formatted file
cur_cwd = os.getcwd()
print(cur_cwd)
config = RawConfigParser()
config.read(cur_cwd + "/" + 'os-settings.ini')

LOG_FILE = cur_cwd + "/" + "dns-updater.log"

# MQ params and subject watches
EXCHANGE_NAME = "nova"
ROUTING_KEY = "notifications.info"
QUEUE_NAME = "dns_updater"
BROKER_URI = OS_MQ_URI
EVENT_CREATE = "compute.instance.create.end"
EVENT_DELETE = "compute.instance.delete.start"


log.basicConfig(filename=LOG_FILE, level=log.INFO,
                format='%(asctime)s %(message)s')


class DnsUpdater(ConsumerMixin):

    def __init__(self, conn):
        self.connection = conn
        return

    def get_consumers(self, consumer, channel):
        exchange = Exchange(EXCHANGE_NAME, type="topic", durable=False)
        queue = Queue(QUEUE_NAME, exchange, routing_key=ROUTING_KEY,
                      durable=False, auto_delete=True, no_ack=True)
        return [consumer(queue, callbacks=[self.on_message])]

    def on_message(self, body, message):
        try:
            self._handle_message(body)
        except Exception as e:
            log.info(repr(e))

    def _handle_message(self, body):
        log.info('Body: %r' % body)
        jbody = json.loads(body["oslo.message"])
        event_type = jbody["event_type"]
        if event_type in [EVENT_CREATE, EVENT_DELETE]:
            if event_type == EVENT_CREATE:
                handle_create(body)
            else:
                handle_delete(body)
