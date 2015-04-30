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
def xr_loopback0(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/cisco-ios-xr:interface/Loopback/0' + query_format
    get_response = requests.get(get_url, verify=False, auth=(username, password))
    get_json = get_response.json()
    return get_json

def ios_loopback0(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/ios:interface/Loopback/0' + query_format
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

def get_loopback0(hostname):
    if get_os(hostname) == 'cisco-ios-xr-id:cisco-ios-xr':
            return xr_loopback0(hostname)['Loopback']['ipv4']['address']['ip']
    elif get_os(hostname) == 'ios-id:cisco-ios':
            return ios_loopback0(hostname)['Loopback']['ip']['address']['primary']['address']

print(get_loopback0(sys.argv[1]))

# Processing
#print (json.dumps(devices_detailed, indent=4, separators=(',', : ')))
#print (json.dumps(ios_interfaces('CPE1'), indent=4, separators=(',', ': ')))
