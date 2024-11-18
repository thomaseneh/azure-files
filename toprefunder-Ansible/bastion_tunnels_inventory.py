#!/usr/bin/env python3
# """Provides functionality for managing connections through Azure Bastion tunnels.

# It allows users to generate an inventory of Azure hosts and their connection
# details, as well as list the tunnel processes for the current user.
# """

# import argparse
# import contextlib
# import json
# import shutil
# import subprocess
# import sys
# from pathlib import Path

# import psutil
# import yaml
# from azure.core.exceptions import ResourceNotFoundError
# from azure.identity import AzureCliCredential, CredentialUnavailableError
# from azure.mgmt.compute import ComputeManagementClient
# from azure.mgmt.network import NetworkManagementClient
# from azure.mgmt.subscription import SubscriptionClient

# try:
#     import json
# except ImportError:
#     import simplejson as json

# parser = argparse.ArgumentParser(
#     description="Ansible connections through Microsoft Azure Bastion tunnels.",
# )

# parser.add_argument(
#     "-c",
#     "--config-file",
#     help="Config file",
#     default="ansible_bastion_tunnels.yml",
# )

# parser.add_argument(
#     "-l",
#     "--list",
#     help="Print the inventory",
#     action="store_true",
# )

# parser.add_argument(
#     "-t",
#     "--list-tunnels",
#     help="List tunnel processes",
#     action="store_true",
# )

# args = parser.parse_args()

# az_command = shutil.which("az")
# if az_command is None:
#     print("The Azure CLI is not installed.")
#     sys.exit(1)


# def list_tunnels() -> str:
#     """List the tunnel processes for the current user."""
#     for proc in psutil.process_iter():
#         tunnel = [
#             "network",
#             "bastion",
#             "tunnel",
#             "--resource-group",
#             "--target-resource-id",
#         ]
#         if all(cmdline in proc.cmdline() for cmdline in tunnel):
#             print(f"Pid: {proc.pid} Process: {proc.cmdline()}")


# def generate_inventory(config: dict) -> dict:
#     """Generate the inventory."""
#     inventory = {}
#     inventory["bastion_tunnels"] = []
#     inventory["_meta"] = {}
#     inventory["_meta"]["hostvars"] = {}

#     for host, value in config["bastion_tunnels"]["hosts"].items():
#         if bastion_name(value["resource_group"]) is None:
#             print(
#                 f"A valid bastion host was not found in resource group {value['resource_group']}.",
#             )
#             sys.exit(1)
#         else:
#             bastion = bastion_name(value["resource_group"])

#         if resource_id(value["resource_group"], host) is None:
#             pass
#         else:
#             target_id = resource_id(value["resource_group"], host)

#             command = [
#                 az_command,
#                 "network",
#                 "bastion",
#                 "tunnel",
#                 "--name",
#                 bastion,
#                 "--resource-group",
#                 value["resource_group"],
#                 "--target-resource-id",
#                 target_id,
#                 "--resource-port",
#                 "22",
#                 "--port",
#                 str(value["ansible_port"]),
#             ]

#             subprocess.Popen(
#                 command,
#                 stderr=subprocess.DEVNULL,
#                 stdout=subprocess.DEVNULL,
#                 shell=False,  # noqa: S603
#             )

#             try:
#                 host_address = value["ansible_host"]
#             except KeyError:
#                 host_address = "127.0.0.1"

#             with contextlib.suppress(KeyError):
#                 inventory["_meta"]["hostvars"][host]["ansible_user"] = value[
#                     "ansible_user"
#                 ]

#             inventory["bastion_tunnels"].append(host)
#             inventory["_meta"]["hostvars"][host] = {}
#             inventory["_meta"]["hostvars"][host]["ansible_host"] = host_address
#             inventory["_meta"]["hostvars"][host]["ansible_port"] = value["ansible_port"]

#     return inventory


# def subscription_id() -> str:
#     """Get the subscription ID from Azure CLI credentials."""
#     credential = AzureCliCredential()
#     subscription_client = SubscriptionClient(credential)
#     sub_list = subscription_client.subscriptions.list()

#     for group in list(sub_list):
#         subscription_id = group.subscription_id

#     return subscription_id


# def resource_id(resource_group: str, vm_name: str) -> str:
#     """Get the resource ID of a virtual machine."""
#     client = ComputeManagementClient(
#         credential=AzureCliCredential(),
#         subscription_id=subscription_id(),
#     )

#     try:
#         response = client.virtual_machines.get(
#             resource_group_name=resource_group,
#             vm_name=vm_name,
#         )
#     except ResourceNotFoundError:
#         return None

#     resource = response.as_dict()
#     return resource["id"]


# def bastion_name(resource_group: str) -> str:
#     """Get the name of the Azure Bastion host."""
#     bastion = None

#     client = NetworkManagementClient(
#         credential=AzureCliCredential(),
#         subscription_id=subscription_id(),
#     )

#     response = client.bastion_hosts.list_by_resource_group(
#         resource_group_name=resource_group,
#     )

#     for item in response:
#         bastion = item.name

#         if item.enable_tunneling is False:
#             return None

#     return bastion


# if not args.list_tunnels:
#     credential = AzureCliCredential()
#     try:
#         credential.get_token("https://management.azure.com/.default")
#     except CredentialUnavailableError:
#         sys.exit(1)

#     with Path(args.config_file).open("r") as read_config:
#         if not read_config:
#             print(f"Config file {args.config_file} not found.")
#             sys.exit(1)
#         else:
#             config = yaml.safe_load(read_config)

#     inventory = generate_inventory(config)

#     if args.list:
#         json_output = json.dumps(inventory, sort_keys=True, indent=2)
#     else:
#         json_output = json.dumps(inventory, sort_keys=True)

#     print(json_output)

# if args.list_tunnels:
#     list_tunnels()
#!/usr/bin/env python3
import json
import sys
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
import sys

# Set Azure credentials
credential = DefaultAzureCredential()
subscription_id = 'a5059891-462a-4122-a34e-4731a8911cfe'
resource_group_name = 'DevOps'

# Initialize clients
compute_client = ComputeManagementClient(credential, subscription_id)
network_client = NetworkManagementClient(credential, subscription_id)

# Function to get private IPs of a VMSS instance
def get_vmss_instance_private_ips(instance):
    private_ips = []
    for nic in instance.network_profile.network_interfaces:
        nic_name = nic.id.split('/')[-1]  # Extract NIC name from NIC ID
        # Check if the NIC matches an existing NIC in your resource group
        if nic_name in ['demo-vm74_z1', 'demovm196_z1', 'ubuntu-server269_z1']:
            try:
                nic_obj = network_client.network_interfaces.get(resource_group_name, nic_name)
                for ip_config in nic_obj.ip_configurations:
                    if ip_config.private_ip_address:
                        private_ips.append(ip_config.private_ip_address)
            except Exception as e:
                print(f"Error fetching NIC details for {nic_name}: {e}")
                continue
    return private_ips

# Dynamic inventory script (example)

# Example for dynamically getting VMSS instances and their IPs
def get_vmss_instances():
    instances = []
    output = subprocess.check_output(['az', 'vmss', 'list-instances', '--resource-group', 'DevOps', '--name', 'toprefunderVMSS', '--query', "[].{Name:name, IP:privateIpAddress}"], universal_newlines=True)
    instance_data = json.loads(output)
    for instance in instance_data:
        ip_address = instance['IP']
        # Logic to determine if the VM is Windows or Linux
        if is_windows_vm(instance['Name']):
            instances.append({
                'name': instance['Name'],
                'ansible_host': ip_address,
                'ansible_user': 'testuser',  # Adjust according to your user
                'ansible_connection': 'winrm',
                'ansible_winrm_transport': 'ntlm',
                'ansible_winrm_server_cert_validation': 'ignore'
            })
        else:
            instances.append({
                'name': instance['Name'],
                'ansible_host': ip_address,
                'ansible_user': 'adminuser',  # Adjust according to your user
                'ansible_connection': 'ssh'
            })
    return instances


# Dictionary to hold VMSS instance details
vm_ips = {}

# Fetch VMSS instances
vmss_list = compute_client.virtual_machine_scale_sets.list(resource_group_name)
for vmss in vmss_list:
    vmss_name = vmss.name
    try:
        vm_instances = compute_client.virtual_machine_scale_set_vms.list(resource_group_name, vmss_name)
        for instance in vm_instances:
            instance_name = f"{vmss_name}-{instance.instance_id}"
            private_ips = get_vmss_instance_private_ips(instance)
            vm_ips[instance_name] = private_ips
    except Exception as e:
        print(f"Error fetching VMSS instances for {vmss_name}: {e}")

# Create inventory for Ansible if '--list' is passed
if len(sys.argv) > 1 and sys.argv[1] == '--list':
    inventory = {
        "all": {
            "hosts": list(vm_ips.keys())
        },
        "_meta": {
            "hostvars": {}
        }
    }

    # Populate hostvars with private IPs and other necessary data
    for instance_name, private_ips in vm_ips.items():
        inventory["_meta"]["hostvars"][instance_name] = {
            "ansible_host": private_ips[0] if private_ips else "N/A",  # Set the first private IP or 'N/A'
            "ansible_user": "testuser"  # Replace with correct user if needed
        }

    # Output inventory in JSON format for Ansible
    print(json.dumps(inventory, indent=4))
else:
    print(json.dumps({"error": "Invalid argument or no argument provided"}, indent=4))
