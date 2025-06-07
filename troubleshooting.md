# Troubleshooting Guide

## Common Issues and Solutions

### 1. Virtual Machines Not Accessible

#### Symptoms
- Cannot SSH into VMs
- VMs showing as "STOPPED" or "TERMINATED"
- Connection timeouts

#### Diagnosis
```bash
# Check VM status
gcloud compute instances list --filter="name:(hub-vm OR spoke1-vm OR spoke2-vm)"

# Check VM details
gcloud compute instances describe [VM_NAME] --zone=us-central1-a
```

#### Solutions
```bash
# Start stopped VMs
gcloud compute instances start [VM_NAME] --zone=us-central1-a

# Reset VM if needed
gcloud compute instances reset [VM_NAME] --zone=us-central1-a

# Check firewall rules for SSH access
gcloud compute firewall-rules list --filter="name:app-allow-ssh-rdp*"
```

### 2. Connectivity Issues Between Spokes

#### Symptoms
- Ping fails between spoke VMs
- 100% packet loss
- Connection refused errors

#### Diagnosis
```bash
# Test basic connectivity
gcloud compute ssh spoke1-vm --zone=us-central1-a --command="ping -c 3 [SPOKE2_IP]"

# Check NCC hub status
gcloud network-connectivity hubs describe my-hub

# Check spoke configurations
gcloud network-connectivity spokes list --hub=my-hub
```

#### Solutions

##### Check NCC Configuration
```bash
# Verify hub exists
gcloud network-connectivity hubs describe my-hub

# If hub doesn't exist, recreate it
gcloud network-connectivity hubs create my-hub --description="Hub for spoke networks"

# Recreate spokes if needed
gcloud network-connectivity spokes create spoke1 --hub=my-hub --vpc-network=projects/[PROJECT_ID]/global/networks/spoke1-vpc
gcloud network-connectivity spokes create spoke2 --hub=my-hub --vpc-network=projects/[PROJECT_ID]/global/networks/spoke2-vpc
```

##### Verify Firewall Rules
```bash
# Check ICMP rules
gcloud compute firewall-rules describe app-allow-icmp-spoke1-vpc
gcloud compute firewall-rules describe app-allow-icmp-spoke2-vpc

# If missing, recreate firewall rules
gcloud compute firewall-rules create app-allow-icmp-spoke1-vpc --network=spoke1-vpc --allow=icmp --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create app-allow-icmp-spoke2-vpc --network=spoke2-vpc --allow=icmp --source-ranges=0.0.0.0/0
```

### 3. NCC Hub Creation Failures

#### Symptoms
- "Permission denied" errors
- API not enabled errors
- Resource quota exceeded

#### Diagnosis
```bash
# Check enabled APIs
gcloud services list --enabled --filter="name:(networkconnectivity.googleapis.com OR compute.googleapis.com)"

# Check IAM permissions
gcloud projects get-iam-policy [PROJECT_ID]
```

#### Solutions
```bash
# Enable required APIs
gcloud services enable networkconnectivity.googleapis.com
gcloud services enable compute.googleapis.com

# Check project permissions (user needs Network Admin or Editor role)
gcloud projects add-iam-policy-binding [PROJECT_ID] \
    --member="user:[EMAIL]" \
    --role="roles/compute.networkAdmin"
```

### 4. VPC Network Issues

#### Symptoms
- Subnets not found
- Network creation failures
- IP allocation errors

#### Diagnosis
```bash
# List VPC networks
gcloud compute networks list

# Check subnets
gcloud compute networks subnets list

# Verify IP ranges
gcloud compute networks subnets describe [SUBNET_NAME] --region=us-central1
```

#### Solutions
```bash
# Recreate missing networks
gcloud compute networks create hub-vpc --subnet-mode=custom
gcloud compute networks create spoke1-vpc --subnet-mode=custom
gcloud compute networks create spoke2-vpc --subnet-mode=custom

# Recreate missing subnets
gcloud compute networks subnets create hub-subnet --network=hub-vpc --range=10.1.0.0/24 --region=us-central1
gcloud compute networks subnets create spoke1-subnet --network=spoke1-vpc --range=10.2.0.0/24 --region=us-central1
gcloud compute networks subnets create spoke2-subnet --network=spoke2-vpc --range=10.3.0.0/24 --region=us-central1
```

### 5. Script Execution Issues

#### Symptoms
- Permission denied when running scripts
- Command not found errors
- Syntax errors

#### Solutions
```bash
# Make scripts executable
chmod +x setup-script.sh
chmod +x connectivity-test.sh
chmod +x cleanup-script.sh

# Check script syntax
bash -n setup-script.sh

# Run with explicit bash
bash setup-script.sh
```

### 6. Google Cloud SDK Issues

#### Symptoms
- `gcloud` command not found
- Authentication errors
- Project not set

#### Solutions
```bash
# Install Google Cloud SDK (if not installed)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate
gcloud auth login

# Set project
gcloud config set project [PROJECT_ID]

# Verify configuration
gcloud config list
```

### 7. Network Topology Tool Issues

#### Symptoms
- Empty network topology view
- Missing connections
- No metrics data

#### Diagnosis
- Check if VMs are running
- Verify NCC configuration
- Confirm traffic is flowing

#### Solutions
```bash
# Generate traffic for metrics
gcloud compute ssh spoke1-vm --zone=us-central1-a --command="ping -c 100 [SPOKE2_IP]"

# Wait for metrics to propagate (5-10 minutes)

# Refresh Network Topology view in console
```

### 8. Resource Cleanup Issues

#### Symptoms
- Resources still exist after cleanup
- Deletion errors
- Dependencies blocking deletion

#### Solutions
```bash
# Force delete VMs
gcloud compute instances delete hub-vm spoke1-vm spoke2-vm --zone=us-central1-a --quiet

# Delete NCC spokes before hub
gcloud network-connectivity spokes delete spoke1 spoke2 --hub=my-hub --quiet

# Delete firewall rules before networks
gcloud compute firewall-rules delete app-allow-icmp-hub-vpc app-allow-ssh-rdp-hub-vpc --quiet

# Delete subnets before networks
gcloud compute networks subnets delete hub-subnet spoke1-subnet spoke2-subnet --region=us-central1 --quiet

# Finally delete networks
gcloud compute networks delete hub-vpc spoke1-vpc spoke2-vpc --quiet
```

## Diagnostic Commands

### Quick Health Check
```bash
#!/bin/bash
# Quick diagnostic script

echo "=== VM Status ==="
gcloud compute instances list --filter="name:(hub-vm OR spoke1-vm OR spoke2-vm)"

echo "=== VPC Networks ==="
gcloud compute networks list --filter="name:(hub-vpc OR spoke1-vpc OR spoke2-vpc)"

echo "=== NCC Hub ==="
gcloud network-connectivity hubs describe my-hub 2>/dev/null || echo "Hub not found"

echo "=== NCC Spokes ==="
gcloud network-connectivity spokes list --hub=my-hub 2>/dev/null || echo "No spokes found"

echo "=== Firewall Rules ==="
gcloud compute firewall-rules list --filter="name:app-allow*"
```

### Connectivity Test
```bash
#!/bin/bash
# Manual connectivity test

SPOKE1_IP=$(gcloud compute instances describe spoke1-vm --zone=us-central1-a --format='get(networkInterfaces[0].networkIP)')
SPOKE2_IP=$(gcloud compute instances describe spoke2-vm --zone=us-central1-a --format='get(networkInterfaces[0].networkIP)')

echo "Testing Spoke1 to Spoke2..."
gcloud compute ssh spoke1-vm --zone=us-central1-a --command="ping -c 3 $SPOKE2_IP"

echo "Testing Spoke2 to Spoke1..."
gcloud compute ssh spoke2-vm --zone=us-central1-a --command="ping -c 3 $SPOKE1_IP"
```

## Error Messages and Solutions

### Common Error Messages

#### "The resource 'projects/[PROJECT]/global/networks/[NETWORK]' was not found"
**Solution**: Recreate the missing VPC network using the setup script.

#### "Permission 'networkconnectivity.hubs.create' denied"
**Solution**: Ensure you have the Network Admin role or enable the Network Connectivity API.

#### "Quota 'NETWORKS' exceeded"
**Solution**: Delete unused networks or request quota increase.

#### "VM instance '[VM_NAME]' not found"
**Solution**: Check VM status and recreate if necessary.

#### "Could not SSH to the instance"
**Solution**: Check firewall rules and VM status. Ensure SSH access is allowed.

## Performance Optimization

### Network Latency
- VMs in same region typically have <1ms latency
- Cross-region traffic will have higher latency
- Use `traceroute` to identify network path issues

### VM Performance
- Use appropriate machine types for workload
- Consider using regional persistent disks
- Monitor CPU and memory usage

### Monitoring Best Practices
- Use Network Topology tool regularly
- Set up alerts for connectivity issues
- Monitor bandwidth utilization

## Prevention Tips

1. **Regular Testing**: Run connectivity tests after any network changes
2. **Documentation**: Keep network documentation updated
3. **Monitoring**: Set up proactive monitoring and alerts
4. **Backup Configurations**: Save gcloud command outputs for reference
5. **Version Control**: Keep scripts in version control
6. **Testing Environment**: Test changes in non-production first

## Getting Help

### Google Cloud Support
- Check [Google Cloud Status](https://status.cloud.google.com/)
- Review [Network Connectivity Center documentation](https://cloud.google.com/network-connectivity/docs)
- Use [Google Cloud Console support](https://console.cloud.google.com/support)

### Community Resources
- [Google Cloud Community](https://www.googlecloudcommunity.com/)
- [Stack Overflow - google-cloud-platform](https://stackoverflow.com/questions/tagged/google-cloud-platform)
- [Reddit - r/googlecloud](https://www.reddit.com/r/googlecloud/)

### Useful Links
- [VPC Network Troubleshooting](https://cloud.google.com/vpc/docs/troubleshooting)
- [Network Connectivity Center Troubleshooting](https://cloud.google.com/network-connectivity/docs/network-connectivity-center/troubleshooting)
- [Compute Engine Networking](https://cloud.google.com/compute/docs/networking)
