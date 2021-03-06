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
devices = get_devices_response.json()

# Devices type
ddevices_url = ncs_server + 'api/running/devices'
get_ddevices_url = ddevices_url + '?format=json&deep'
get_ddevices_response = requests.get(get_ddevices_url, verify=False, auth=(username, password))
devices_detailed = get_ddevices_response.json()

# Interfaces
def xr_interfaces(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/cisco-ios-xr:interface' + '?format=json&deep'
    get_response = requests.get(get_url, verify=False, auth=(username, password))
    get_json = get_response.json()
    return get_json

def ios_interfaces(hostname):
    get_url = devices_url + 'device/' + hostname + '/config/ios:interface' + '?format=json&deep'
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

# Get interfaces of a device
interfaces = []
address = []
def get_interfaces(hostname):
    if get_os(hostname) == 'cisco-ios-xr-id:cisco-ios-xr':
        for int_type in xr_interfaces(hostname)['tailf-ned-cisco-ios-xr:interface']:
            for item in xr_interfaces(hostname)['tailf-ned-cisco-ios-xr:interface'][int_type]:
                name = item['id']
                address = item['ipv4']
                interfaces.append(str(int_type) + str(name))
                address.append(str(address))
    elif get_os(hostname) == 'ios-id:cisco-ios':
            for int_type in ios_interfaces(hostname)['tailf-ned-cisco-ios:interface']:
                for item in ios_interfaces(hostname)['tailf-ned-cisco-ios:interface'][int_type]:
                    name = item['name']
                    interfaces.append(str(int_type) + str(name))
    return ' '.join(address)
            
#print(get_interfaces(sys.argv[1]))

print(get_interfaces('PE1'))

print (json.dumps(xr_interfaces('PE1'), indent=4, separators=(',', ': ')))

# Processing
#print (json.dumps(devices_detailed, indent=4, separators=(',', ': ')))
#print (json.dumps(ios_interfaces('CPE1'), indent=4, separators=(',', ': ')))
