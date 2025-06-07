# Google Cloud Hub and Spoke Network Implementation with NCC

This repository contains the complete implementation guide for creating a classic hub-and-spoke network topology using Google Cloud Platform's Network Connectivity Center (NCC).

## Video

https://youtu.be/NN-ooCUafUo

## Overview

This project demonstrates how to design and implement a hub-and-spoke network architecture on Google Cloud Platform. The implementation includes three VPC networks (one central hub and two spokes) with virtual machines for connectivity testing.

## Architecture

```
    ┌─────────────┐
    │   Hub VPC   │
    │  (hub-vm)   │
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │     NCC     │
    │   my-hub    │
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │             │
┌───▼───┐    ┌───▼───┐
│Spoke1 │    │Spoke2 │
│  VPC  │    │  VPC  │
│(VM-1) │    │(VM-2) │
└───────┘    └───────┘
```

## Features

- **Hub-and-Spoke Topology**: Central hub with two spoke networks
- **Network Connectivity Center (NCC)**: Centralized connectivity management
- **VPC Networks**: Three separate VPC networks with dedicated subnets
- **VM Instances**: Test virtual machines in each network
- **Connectivity Testing**: Before and after NCC implementation
- **Network Topology Visualization**: Using Google Cloud's Network Topology tool

## Prerequisites

- Google Cloud Platform account
- Basic understanding of VPC networks and networking concepts
- Access to Google Cloud Console
- Sufficient permissions to create VPC networks, VMs, and NCC resources

## Network Components

### VPC Networks
- **hub-vpc**: Central hub network with hub-subnet
- **spoke1-vpc**: First spoke network with spoke1-subnet  
- **spoke2-vpc**: Second spoke network with spoke2-subnet

### Virtual Machines
- **hub-vm**: Virtual machine in the hub network
- **spoke1-vm**: Virtual machine in spoke1 network
- **spoke2-vm**: Virtual machine in spoke2 network

### Firewall Rules
- **app-allow-icmp**: Allows ICMP traffic for ping tests
- **app-allow-ssh-rdp**: Allows SSH and RDP access

## Implementation Steps

### 1. Environment Setup
- Access Google Cloud Console
- Navigate to the pre-configured VPC networks
- Verify firewall rules are in place

### 2. Virtual Machine Creation
```bash
# Create VMs in each VPC network
# hub-vm in hub-vpc
# spoke1-vm in spoke1-vpc  
# spoke2-vm in spoke2-vpc
```

### 3. Initial Connectivity Testing
Test connectivity between spoke networks (should fail):
```bash
# From spoke1-vm
ping <spoke2-vm-internal-ip>

# From spoke2-vm  
ping <spoke1-vm-internal-ip>
```

### 4. NCC Hub and Spoke Implementation
1. Create NCC Hub named "my-hub"
2. Add spoke1-vpc as first spoke
3. Add spoke2-vpc as second spoke
4. Configure VPC network spokes

### 5. Post-Implementation Testing
Verify connectivity after NCC setup:
```bash
# Test connectivity (should now succeed)
ping -c 3 <target-vm-internal-ip>
```

### 6. Network Topology Analysis
Use Google Cloud's Network Topology tool to visualize and monitor the network.

## Files in This Repository

- `README.md` - This comprehensive guide
- `setup-script.sh` - Automated setup script
- `connectivity-test.sh` - Connectivity testing script
- `cleanup-script.sh` - Resource cleanup script
- `architecture-diagram.md` - Detailed architecture documentation
- `troubleshooting.md` - Common issues and solutions

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/gcp-hub-spoke-ncc.git
   cd gcp-hub-spoke-ncc
   ```

2. **Set up Google Cloud environment:**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   chmod +x setup-script.sh
   ./setup-script.sh
   ```

3. **Run connectivity tests:**
   ```bash
   chmod +x connectivity-test.sh
   ./connectivity-test.sh
   ```

## Key Benefits

- **Simplified Network Management**: Centralized connectivity through NCC
- **Reduced Operational Complexity**: No need for individual VPC peering connections
- **Scalable Architecture**: Easy to add additional spokes
- **Full Mesh Connectivity**: All spokes can communicate through the hub
- **Network Monitoring**: Built-in topology visualization and metrics

## Testing Results

### Before NCC Implementation
- ❌ spoke1-vm to spoke2-vm: 100% packet loss
- ❌ spoke2-vm to spoke1-vm: 100% packet loss

### After NCC Implementation  
- ✅ spoke1-vm to spoke2-vm: Full connectivity
- ✅ spoke2-vm to spoke1-vm: Full connectivity
- ✅ All spokes connected through central hub

## Network Topology Features

The Network Topology tool provides:
- Visual representation of network infrastructure
- Traffic metrics between entities
- Inter-region traffic analysis
- Expandable/collapsible network entities
- Real-time insights and metrics

## Best Practices

1. **Security**: Use appropriate firewall rules
2. **Monitoring**: Regularly check Network Topology metrics
3. **Scaling**: Plan for additional spokes as needed
4. **Documentation**: Keep network documentation updated
5. **Testing**: Regular connectivity testing after changes

## Troubleshooting

Common issues and solutions are documented in `troubleshooting.md`.

## Cleanup

To remove all resources created in this lab:
```bash
chmod +x cleanup-script.sh
./cleanup-script.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Cloud Platform documentation
- Network Connectivity Center best practices
- Google Cloud networking community

## Support

For questions or issues:
- Create an issue in this repository
- Refer to Google Cloud documentation
- Check troubleshooting guide

---

**Note**: This implementation was tested in a Google Cloud lab environment. Adjust configurations as needed for production use.
