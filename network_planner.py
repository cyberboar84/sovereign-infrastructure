import ipaddress
import json

def generate_network_config():
    # 1. Network Constraints
    mgmt_cidr = "10.10.10.0/24"
    dhcp_start_index = 100  # The "Do Not Cross" line
    
    network = ipaddress.ip_network(mgmt_cidr)

    # 2. The "Ground Truth" (Your existing Static IPs)
    reserved_ips = {
        "pfsense_gateway": "10.10.10.1",
        "host_bridge_ip":  "10.10.10.2",   # ml-boar-84
        "mgmt_gateway_vm": "10.10.10.10",  # Ubuntu Management Node
        "ai_engine_node":  "10.10.10.20"   # deepseek-r1
    }

    # 3. Find the Next Available Static IP (Below .100)
    reserved_set = {ipaddress.IPv4Address(ip) for ip in reserved_ips.values()}
    
    windows_dc_ip = None
    
    # We scan specifically from .10 to .99 to find a gap
    for i in range(10, dhcp_start_index):
        candidate_ip = network[i]
        if candidate_ip not in reserved_set:
            windows_dc_ip = str(candidate_ip)
            print(f"[+] Found Gap for Windows DC: {windows_dc_ip}")
            break
    
    if not windows_dc_ip:
        raise ValueError("CRITICAL: No static IPs available in the 10-99 range!")

    # 4. Build Configuration
    config = {
        "network_cidr": mgmt_cidr,
        "gateway_ip": reserved_ips["pfsense_gateway"],
        "dhcp_start": str(network[dhcp_start_index]),
        "existing_nodes": reserved_ips,
        "new_infrastructure": {
            "windows_dc_ip": windows_dc_ip, 
            "ovs_bridge_name": "br-mgmt"
        }
    }

    # 5. Export for Terraform
    with open("terraform/generated.tfvars.json", "w") as f:
        json.dump(config, f, indent=4)
        print("[*] Configuration exported to terraform/generated.tfvars.json")

if __name__ == "__main__":
    generate_network_config()
