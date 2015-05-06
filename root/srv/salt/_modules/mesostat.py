#!/usr/local/bin/python
import json
import requests

def get_cluster_stats(host="127.0.0.1", port="5050"):
    return json.loads(requests.get("http://%s:%s/metrics/snapshot" % (host, port)).text)
