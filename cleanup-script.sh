#!/bin/bash

# Google Cloud Hub and Spoke Network Cleanup Script
# This script removes all resources created for the hub-spoke implementation

set -e

echo "🧹 Google Cloud Hub and Spoke Network Cleanup"
echo "=============================================="

# Configuration variables
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
ZONE="us-central1-a"

# Resource names
HUB_NETWORK="hub-vpc"
SPOKE1_NETWORK="spoke1-vpc"
SPOKE2_NETWORK="spoke2-vpc"

HUB_VM="hub-vm"
SPOKE1_VM="spoke1-vm"
SPOKE2_VM="spoke2-vm"

NCC_HUB="my-hub"

echo "⚠️  WARNING: This will delete all resources created for the hub-spoke lab"
echo "📋 Resources to be deleted:"
echo "   - 3 Virtual Machines"
echo "   - 3 VPC Networks and Subnets"
echo "   - Firewall Rules"
echo "   - NCC Hub and Spokes"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🗑️ Starting cleanup process..."

# Function to safely delete resource
safe_delete() {
    local resource_type=$1
    local resource_name=$2
    local additional_flags=$3
    local description=$4
    
    echo "   Deleting $description..."
    if gcloud $resource_type delete $resource_name $additional_flags --quiet 2>/dev/null; then
        echo "   ✅ Deleted: $resource_name"
    else
        echo "   ⚠️  Not found or already deleted: $resource_name"
    fi
}

# Delete Virtual Machines
echo "💻 Deleting Virtual Machines..."
safe_delete "compute instances" "$HUB_VM" "--zone=$ZONE" "Hub VM"
safe_delete "compute instances" "$SPOKE1_VM" "--zone=$ZONE" "Spoke1 VM"
safe_delete "compute instances" "$SPOKE2_VM" "--zone=$ZONE" "Spoke2 VM"

# Wait for VMs to be fully deleted
echo "⏳ Waiting for VMs to be fully deleted..."
sleep 30

# Delete NCC Spokes first (they depend on the hub)
echo "🎯 Deleting NCC Spokes..."
if gcloud network-connectivity hubs describe $NCC_HUB >/dev/null 2>&1; then
    # List and delete all spokes
    spokes=$(gcloud network-connectivity spokes list --hub=$NCC_HUB --format="value(name)" 2>/dev/null || echo "")
    if [ -n "$spokes" ]; then
        for spoke in $spokes; do
            safe_delete "network-connectivity spokes" "$spoke" "--hub=$NCC_HUB" "NCC Spoke: $spoke"
        done
    else
        echo "   ⚠️  No spokes found in hub $NCC_HUB"
    fi
    
    # Wait for spokes to be deleted
    echo "   ⏳ Waiting for spokes to be fully deleted..."
    sleep 30
    
    # Delete NCC Hub
    echo "🎯 Deleting NCC Hub..."
    safe_delete "network-connectivity hubs" "$NCC_HUB" "" "NCC Hub"
else
    echo "   ⚠️  NCC Hub $NCC_HUB not found"
fi

# Delete Firewall Rules
echo "🔥 Deleting Firewall Rules..."

# Delete ICMP rules
for network in $HUB_NETWORK $SPOKE1_NETWORK $SPOKE2_NETWORK; do
    rule_name="app-allow-icmp-${network}"
    safe_delete "compute firewall-rules" "$rule_name" "" "ICMP rule for $network"
done

# Delete SSH/RDP rules
for network in $HUB_NETWORK $SPOKE1_NETWORK $SPOKE2_NETWORK; do
    rule_name="app-allow-ssh-rdp-${network}"
    safe_delete "compute firewall-rules" "$rule_name" "" "SSH/RDP rule for $network"
done

# Delete any additional firewall rules that might exist
echo "   Checking for additional firewall rules..."
additional_rules=$(gcloud compute firewall-rules list --filter="network:(projects/$PROJECT_ID/global/networks/$HUB_NETWORK OR projects/$PROJECT_ID/global/networks/$SPOKE1_NETWORK OR projects/$PROJECT_ID/global/networks/$SPOKE2_NETWORK)" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$additional_rules" ]; then
    for rule in $additional_rules; do
        safe_delete "compute firewall-rules" "$rule" "" "Additional firewall rule: $rule"
    done
fi

# Delete Subnets
echo "🔗 Deleting Subnets..."
safe_delete "compute networks subnets" "hub-subnet" "--region=$REGION" "Hub subnet"
safe_delete "compute networks subnets" "spoke1-subnet" "--region=$REGION" "Spoke1 subnet"
safe_delete "compute networks subnets" "spoke2-subnet" "--region=$REGION" "Spoke2 subnet"

# Delete VPC Networks
echo "🌐 Deleting VPC Networks..."
safe_delete "compute networks" "$HUB_NETWORK" "" "Hub VPC"
safe_delete "compute networks" "$SPOKE1_NETWORK" "" "Spoke1 VPC"
safe_delete "compute networks" "$SPOKE2_NETWORK" "" "Spoke2 VPC"

# Verification
echo ""
echo "🔍 Verifying cleanup..."

# Check remaining VMs
remaining_vms=$(gcloud compute instances list --filter="name:(hub-vm OR spoke1-vm OR spoke2-vm)" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$remaining_vms" ]; then
    echo "   ⚠️  Some VMs still exist: $remaining_vms"
else
    echo "   ✅ All VMs deleted"
fi

# Check remaining networks
remaining_networks=$(gcloud compute networks list --filter="name:(hub-vpc OR spoke1-vpc OR spoke2-vpc)" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$remaining_networks" ]; then
    echo "   ⚠️  Some networks still exist: $remaining_networks"
else
    echo "   ✅ All VPC networks deleted"
fi

# Check remaining NCC resources
if gcloud network-connectivity hubs describe $NCC_HUB >/dev/null 2>&1; then
    echo "   ⚠️  NCC Hub still exists: $NCC_HUB"
else
    echo "   ✅ NCC Hub deleted"
fi

# Check remaining firewall rules
remaining_rules=$(gcloud compute firewall-rules list --filter="name:(app-allow-*)" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$remaining_rules" ]; then
    echo "   ⚠️  Some firewall rules still exist: $remaining_rules"
else
    echo "   ✅ All firewall rules deleted"
fi

echo ""
echo "✅ Cleanup Complete!"
echo ""
echo "📊 Cleanup Summary:"
echo "   ✓ Deleted 3 virtual machines"
echo "   ✓ Deleted NCC hub and spokes"
echo "   ✓ Deleted firewall rules"
echo "   ✓ Deleted subnets"
echo "   ✓ Deleted VPC networks"
echo ""
echo "💡 Notes:"
echo "   - Default VPC network was not modified"
echo "   - Google Cloud APIs remain enabled"
echo "   - Project billing may show small charges for resource usage"
echo ""
echo "🔄 To recreate the lab environment, run:"
echo "   ./setup-script.sh"
