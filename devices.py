import requests
import json
import sys
from pprint import pprint

# Server info
ncs_server = 'http://198.18.1.79:8080/'
username = 'admin'
password = 'admin'
query_format = '?format=json'

# Devices queries
devices_url = ncs_server + 'api/running/devices/'
get_devices_url = devices_url + query_format
get_devices_response = requests.get(get_devices_url, verify=False, auth=(username, password))
devices_basic = get_devices_response.json()

# Devices detailed
ddevices_url = ncs_server + 'api/running/devices'
get_ddevices_url = ddevices_url + '?format=json&deep'
get_ddevices_response = requests.get(get_ddevices_url, verify=False, auth=(username, password))
devices_detailed = get_ddevices_response.json()

# PE1 config
def xr_interfaces(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/cisco-ios-xr:interface' + query_format
    get_response = requests.get(get_url, verify=False, auth=(username, password))
    get_json = get_response.json()
    return get_json

def ios_interfaces(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/ios:interface' + query_format
    get_response = requests.get(get_url, verify=False, auth=(username, password))
    get_json = get_response.json()
    return get_json

# Get OS
devices_os = {}

def get_os_all():
    for item in devices_detailed['devices']['device']:
        name = item['name']
        os = item['device-type']['cli']['ned-id']
        devices_os[str(name)] = str(os)
    return devices_os
devices_os = get_os_all()

def get_os(hostname):
    return devices_os[hostname]

# Get list of devices
devices = []
def get_devices():
    for item in devices_basic['devices']['device']:
        name = str(item['name'])
        devices.append(name)
    return ' '.join(devices)
    #return devices

print(get_devices())

# Processing
#print (json.dumps(devices_detailed, indent=4, separators=(',', ': ')))
#print (json.dumps(ios_interfaces('CPE1'), indent=4, separators=(',', ': ')))
