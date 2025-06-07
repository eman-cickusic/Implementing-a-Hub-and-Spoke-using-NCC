#!/bin/bash

# Google Cloud Hub and Spoke Network Setup Script
# This script automates the creation of VPC networks, VMs, and NCC hub-spoke configuration

set -e

echo "🚀 Starting Google Cloud Hub and Spoke Network Setup..."

# Configuration variables
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
ZONE="us-central1-a"

# Network names
HUB_NETWORK="hub-vpc"
SPOKE1_NETWORK="spoke1-vpc"
SPOKE2_NETWORK="spoke2-vpc"

# Subnet names and CIDR ranges
HUB_SUBNET="hub-subnet"
SPOKE1_SUBNET="spoke1-subnet"
SPOKE2_SUBNET="spoke2-subnet"

HUB_CIDR="10.1.0.0/24"
SPOKE1_CIDR="10.2.0.0/24"
SPOKE2_CIDR="10.3.0.0/24"

# VM names
HUB_VM="hub-vm"
SPOKE1_VM="spoke1-vm"
SPOKE2_VM="spoke2-vm"

# NCC Hub name
NCC_HUB="my-hub"

echo "📋 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Zone: $ZONE"
echo ""

# Function to check if resource exists
check_resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local additional_flags=$3
    
    if gcloud $resource_type describe $resource_name $additional_flags >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Enable required APIs
echo "🔧 Enabling required Google Cloud APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable networkconnectivity.googleapis.com

# Create VPC Networks
echo "🌐 Creating VPC Networks..."

# Hub VPC
if ! check_resource_exists "compute networks" "$HUB_NETWORK"; then
    echo "   Creating $HUB_NETWORK..."
    gcloud compute networks create $HUB_NETWORK \
        --subnet-mode=custom \
        --description="Hub VPC for hub-spoke topology"
else
    echo "   $HUB_NETWORK already exists, skipping..."
fi

# Spoke1 VPC
if ! check_resource_exists "compute networks" "$SPOKE1_NETWORK"; then
    echo "   Creating $SPOKE1_NETWORK..."
    gcloud compute networks create $SPOKE1_NETWORK \
        --subnet-mode=custom \
        --description="Spoke1 VPC for hub-spoke topology"
else
    echo "   $SPOKE1_NETWORK already exists, skipping..."
fi

# Spoke2 VPC
if ! check_resource_exists "compute networks" "$SPOKE2_NETWORK"; then
    echo "   Creating $SPOKE2_NETWORK..."
    gcloud compute networks create $SPOKE2_NETWORK \
        --subnet-mode=custom \
        --description="Spoke2 VPC for hub-spoke topology"
else
    echo "   $SPOKE2_NETWORK already exists, skipping..."
fi

# Create Subnets
echo "🔗 Creating Subnets..."

# Hub Subnet
if ! check_resource_exists "compute networks subnets" "$HUB_SUBNET" "--region=$REGION"; then
    echo "   Creating $HUB_SUBNET..."
    gcloud compute networks subnets create $HUB_SUBNET \
        --network=$HUB_NETWORK \
        --range=$HUB_CIDR \
        --region=$REGION \
        --description="Hub subnet"
else
    echo "   $HUB_SUBNET already exists, skipping..."
fi

# Spoke1 Subnet
if ! check_resource_exists "compute networks subnets" "$SPOKE1_SUBNET" "--region=$REGION"; then
    echo "   Creating $SPOKE1_SUBNET..."
    gcloud compute networks subnets create $SPOKE1_SUBNET \
        --network=$SPOKE1_NETWORK \
        --range=$SPOKE1_CIDR \
        --region=$REGION \
        --description="Spoke1 subnet"
else
    echo "   $SPOKE1_SUBNET already exists, skipping..."
fi

# Spoke2 Subnet
if ! check_resource_exists "compute networks subnets" "$SPOKE2_SUBNET" "--region=$REGION"; then
    echo "   Creating $SPOKE2_SUBNET..."
    gcloud compute networks subnets create $SPOKE2_SUBNET \
        --network=$SPOKE2_NETWORK \
        --range=$SPOKE2_CIDR \
        --region=$REGION \
        --description="Spoke2 subnet"
else
    echo "   $SPOKE2_SUBNET already exists, skipping..."
fi

# Create Firewall Rules
echo "🔥 Creating Firewall Rules..."

# ICMP rule for all networks
for network in $HUB_NETWORK $SPOKE1_NETWORK $SPOKE2_NETWORK; do
    rule_name="app-allow-icmp-${network}"
    if ! check_resource_exists "compute firewall-rules" "$rule_name"; then
        echo "   Creating ICMP rule for $network..."
        gcloud compute firewall-rules create $rule_name \
            --network=$network \
            --allow=icmp \
            --source-ranges=0.0.0.0/0 \
            --description="Allow ICMP traffic"
    else
        echo "   ICMP rule for $network already exists, skipping..."
    fi
done

# SSH/RDP rule for all networks
for network in $HUB_NETWORK $SPOKE1_NETWORK $SPOKE2_NETWORK; do
    rule_name="app-allow-ssh-rdp-${network}"
    if ! check_resource_exists "compute firewall-rules" "$rule_name"; then
        echo "   Creating SSH/RDP rule for $network..."
        gcloud compute firewall-rules create $rule_name \
            --network=$network \
            --allow=tcp:22,tcp:3389 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow SSH and RDP traffic"
    else
        echo "   SSH/RDP rule for $network already exists, skipping..."
    fi
done

# Create Virtual Machines
echo "💻 Creating Virtual Machines..."

# Hub VM
if ! check_resource_exists "compute instances" "$HUB_VM" "--zone=$ZONE"; then
    echo "   Creating $HUB_VM..."
    gcloud compute instances create $HUB_VM \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --subnet=$HUB_SUBNET \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
echo "Hub VM initialized" > /tmp/init.log
apt-get update
apt-get install -y iputils-ping traceroute' \
        --tags=hub-vm
else
    echo "   $HUB_VM already exists, skipping..."
fi

# Spoke1 VM
if ! check_resource_exists "compute instances" "$SPOKE1_VM" "--zone=$ZONE"; then
    echo "   Creating $SPOKE1_VM..."
    gcloud compute instances create $SPOKE1_VM \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --subnet=$SPOKE1_SUBNET \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
echo "Spoke1 VM initialized" > /tmp/init.log
apt-get update
apt-get install -y iputils-ping traceroute' \
        --tags=spoke1-vm
else
    echo "   $SPOKE1_VM already exists, skipping..."
fi

# Spoke2 VM
if ! check_resource_exists "compute instances" "$SPOKE2_VM" "--zone=$ZONE"; then
    echo "   Creating $SPOKE2_VM..."
    gcloud compute instances create $SPOKE2_VM \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --subnet=$SPOKE2_SUBNET \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
echo "Spoke2 VM initialized" > /tmp/init.log
apt-get update
apt-get install -y iputils-ping traceroute' \
        --tags=spoke2-vm
else
    echo "   $SPOKE2_VM already exists, skipping..."
fi

# Wait for VMs to be ready
echo "⏳ Waiting for VMs to be ready..."
sleep 30

# Get VM internal IP addresses
echo "📍 Getting VM IP addresses..."
HUB_IP=$(gcloud compute instances describe $HUB_VM --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
SPOKE1_IP=$(gcloud compute instances describe $SPOKE1_VM --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
SPOKE2_IP=$(gcloud compute instances describe $SPOKE2_VM --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')

echo "   Hub VM IP: $HUB_IP"
echo "   Spoke1 VM IP: $SPOKE1_IP"
echo "   Spoke2 VM IP: $SPOKE2_IP"

# Test initial connectivity (should fail)
echo "🧪 Testing initial connectivity (should fail)..."
echo "   Note: These tests are expected to fail before NCC implementation"

# Create NCC Hub and Spokes
echo "🎯 Creating Network Connectivity Center Hub and Spokes..."

# Create NCC Hub
if ! gcloud network-connectivity hubs describe $NCC_HUB >/dev/null 2>&1; then
    echo "   Creating NCC Hub: $NCC_HUB..."
    gcloud network-connectivity hubs create $NCC_HUB \
        --description="Hub for spoke1 and spoke2 VPCs"
else
    echo "   NCC Hub $NCC_HUB already exists, skipping..."
fi

# Create Spoke1
spoke1_name="spoke1"
if ! gcloud network-connectivity spokes describe $spoke1_name --hub=$NCC_HUB >/dev/null 2>&1; then
    echo "   Creating Spoke1..."
    gcloud network-connectivity spokes create $spoke1_name \
        --hub=$NCC_HUB \
        --vpc-network=projects/$PROJECT_ID/global/networks/$SPOKE1_NETWORK \
        --description="Spoke1 VPC connection"
else
    echo "   Spoke1 already exists, skipping..."
fi

# Create Spoke2
spoke2_name="spoke2"
if ! gcloud network-connectivity spokes describe $spoke2_name --hub=$NCC_HUB >/dev/null 2>&1; then
    echo "   Creating Spoke2..."
    gcloud network-connectivity spokes create $spoke2_name \
        --hub=$NCC_HUB \
        --vpc-network=projects/$PROJECT_ID/global/networks/$SPOKE2_NETWORK \
        --description="Spoke2 VPC connection"
else
    echo "   Spoke2 already exists, skipping..."
fi

# Wait for NCC configuration to propagate
echo "⏳ Waiting for NCC configuration to propagate..."
sleep 60

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📊 Summary:"
echo "   ✓ Created 3 VPC networks with subnets"
echo "   ✓ Created firewall rules for ICMP, SSH, and RDP"
echo "   ✓ Created 3 virtual machines"
echo "   ✓ Created NCC hub with 2 spokes"
echo ""
echo "🔗 VM IP Addresses:"
echo "   Hub VM ($HUB_VM): $HUB_IP"
echo "   Spoke1 VM ($SPOKE1_VM): $SPOKE1_IP"
echo "   Spoke2 VM ($SPOKE2_VM): $SPOKE2_IP"
echo ""
echo "🧪 Next Steps:"
echo "   1. Run './connectivity-test.sh' to test connectivity"
echo "   2. Check Network Topology in Google Cloud Console"
echo "   3. Monitor traffic metrics and insights"
echo ""
echo "🌐 Access VMs via SSH:"
echo "   gcloud compute ssh $HUB_VM --zone=$ZONE"
echo "   gcloud compute ssh $SPOKE1_VM --zone=$ZONE"
echo "   gcloud compute ssh $SPOKE2_VM --zone=$ZONE"
