import boto3
import re
import os

from bottle import route, run

def get_blueprint_list():
  client = boto3.client('lightsail')

  blueprint_list = [] 
  for blueprint in client.get_blueprints()['blueprints']:
      blueprint_list.append(blueprint['blueprintId'])

  return blueprint_list

def get_ubuntu_blueprint_id():
    blueprint_ids = get_blueprint_list()
    ubuntu_pattern = re.compile(r'.*ubuntu*')

    ubuntu_blueprint = filter(ubuntu_pattern.search, blueprint_ids)

    return ubuntu_blueprint[0]

def get_bundle_pricing():
    client = boto3.client('lightsail')
    bundle_pricing = {}

    for bundle in client.get_bundles()['bundles']:
	bundle_pricing[bundle['bundleId']] = bundle['price']

    return bundle_pricing

def get_cheapest_bundle():
    return min(get_bundle_pricing(), key=get_bundle_pricing().get)

def generate_keypair(key_name):
  client = boto3.client('lightsail')
  key = client.create_key_pair(keyPairName=key_name)
  ssh_config = """
  IdentitiesOnly yes
  StrictHostKeyChecking no
  AddKeysToAgent yes

  User ubuntu
  ForwardAgent yes
  IdentityFile ~/.ssh/%(key)s

  Host *
    ForwardAgent yes
    StrictHostKeyChecking no
    ServerAliveInterval 90

  """ % {"key": key_name}


  private_key_filepath = os.path.expanduser("~/.ssh/" + key_name)
  public_key_filepath = os.path.expanduser("~/.ssh/" + key_name + ".pub")
  ssh_config_filepath = os.path.expanduser("~/.ssh/" + "config_" + key_name)

  private_key_file = open(private_key_filepath , 'w')
  private_key_file.write(key['privateKeyBase64'])
  private_key_file.close()
  os.chmod(private_key_filepath, 0600)

  public_key_file =  open(public_key_filepath, 'w')
  public_key_file.write(key['publicKeyBase64'])
  public_key_file.close()
  os.chmod(public_key_filepath, 0644)

  ssh_config_file = open(ssh_config_filepath, 'w')
  ssh_config_file.write(ssh_config)
  ssh_config_file.close()
  os.chmod(ssh_config_filepath, 0644)

def create_cheapest_lightsail_instance(name,zone,key_name):
    client = boto3.client('lightsail')
    names = []
    names.append(name)

    client.create_instances(instanceNames=names,\
			    availabilityZone=zone, \
			    bundleId=get_cheapest_bundle(), \
			    blueprintId=get_ubuntu_blueprint_id(), \
			    keyPairName=key_name)

    return get_ip_address_of_instance(name)

def destroy_lightsail_instance(name):
  client = boto3.client('lightsail')
  response = client.delete_instance(instanceName=name)
  return response

def get_ip_address_of_instance(instance_name):
      client = boto3.client('lightsail')
      return client.get_instance(instanceName=instance_name)["instance"]["publicIpAddress"]
