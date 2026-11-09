#!/usr/bin/env python3
"""Log in to every SR Linux router in a running lab and print its software version.

Reads the node list from the topology-data.json file Containerlab writes into the
lab folder, so it needs no hand-written inventory.

    python3 show_version.py ../03-topology/clab-routed/topology-data.json
"""
import json
import sys

from netmiko import ConnectHandler  # pip install netmiko

data_file = sys.argv[1] if len(sys.argv) > 1 else "../03-topology/clab-routed/topology-data.json"
with open(data_file) as f:
    nodes = json.load(f)["nodes"]

for name, node in sorted(nodes.items()):
    if node["kind"] != "nokia_srlinux":
        continue
    conn = ConnectHandler(
        device_type="nokia_srl",
        host=node["mgmt-ipv4-address"],
        username="admin",
        password="NokiaSrl1!",
    )
    output = conn.send_command("show version")
    conn.disconnect()
    version = next((line.split(":", 1)[1].strip() for line in output.splitlines()
                    if line.startswith("Software Version")), "unknown")
    print(f"{name:6} {node['mgmt-ipv4-address']:15} SR Linux {version}")
