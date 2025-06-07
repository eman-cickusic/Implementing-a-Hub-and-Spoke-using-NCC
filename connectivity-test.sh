#!/bin/bash

# Google Cloud Hub and Spoke Connectivity Test Script
# This script tests network connectivity between VMs in different VPCs

set -e

echo "🧪 Google Cloud Hub and Spoke Connectivity Test"
echo "=============================================="

# Configuration variables
PROJECT_ID=$(gcloud config get-value project)
ZONE="us-central1-a"

# VM names
HUB_VM="hub-vm"
SPOKE1_VM="spoke1-vm"
SPOKE2_VM="spoke2-vm"

echo "📋 Test Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Zone: $ZONE"
echo ""

# Function to get VM internal IP
get_vm_ip() {
    local vm_name=$1
    gcloud compute instances describe $vm_name --zone=$ZONE --format='get(networkInterfaces[0].networkIP)' 2>/dev/null || echo "ERROR"
}

# Function to test connectivity
test_connectivity() {
    local source_vm=$1
    local target_ip=$2
    local target_name=$3
    local test_description=$4
    
    echo "🔍 Testing: $test_description"
    echo "   Source: $source_vm"
    echo "   Target: $target_name ($target_ip)"
    
    if [ "$target_ip" = "ERROR" ]; then
        echo "   ❌ FAILED: Cannot get target IP address"
        return 1
    fi
    
    # Test with timeout and limited packets
    if gcloud compute ssh $source_vm --zone=$ZONE --command="ping -c 3 -W 5 $target_ip" --quiet 2>/dev/null; then
        echo "   ✅ SUCCESS: Connectivity established"
        return 0
    else
        echo "   ❌ FAILED: No connectivity (expected before NCC setup)"
        return 1
    fi
}

# Function to run comprehensive connectivity test
run_connectivity_tests() {
    local test_phase=$1
    
    echo ""
    echo "🌐 $test_phase Connectivity Tests"
    echo "----------------------------------------"
    
    # Get VM IP addresses
    echo "📍 Getting VM IP addresses..."
    HUB_IP=$(get_vm_ip $HUB_VM)
    SPOKE1_IP=$(get_vm_ip $SPOKE1_VM)
    SPOKE2_IP=$(get_vm_ip $SPOKE2_VM)
    
    echo "   Hub VM IP: $HUB_IP"
    echo "   Spoke1 VM IP: $SPOKE1_IP"
    echo "   Spoke2 VM IP: $SPOKE2_IP"
    echo ""
    
    # Validate IP addresses
    if [ "$HUB_IP" = "ERROR" ] || [ "$SPOKE1_IP" = "ERROR" ] || [ "$SPOKE2_IP" = "ERROR" ]; then
        echo "❌ ERROR: Could not retrieve all VM IP addresses"
        echo "   Please ensure all VMs are running and accessible"
        return 1
    fi
    
    # Test matrix
    local tests_passed=0
    local total_tests=6
    
    echo "🔄 Running connectivity tests..."
    echo ""
    
    # Hub to Spoke1
    if test_connectivity "$HUB_VM" "$SPOKE1_IP" "Spoke1 VM" "Hub to Spoke1"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Hub to Spoke2
    if test_connectivity "$HUB_VM" "$SPOKE2_IP" "Spoke2 VM" "Hub to Spoke2"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Spoke1 to Hub
    if test_connectivity "$SPOKE1_VM" "$HUB_IP" "Hub VM" "Spoke1 to Hub"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Spoke1 to Spoke2
    if test_connectivity "$SPOKE1_VM" "$SPOKE2_IP" "Spoke2 VM" "Spoke1 to Spoke2"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Spoke2 to Hub
    if test_connectivity "$SPOKE2_VM" "$HUB_IP" "Hub VM" "Spoke2 to Hub"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Spoke2 to Spoke1
    if test_connectivity "$SPOKE2_VM" "$SPOKE1_IP" "Spoke1 VM" "Spoke2 to Spoke1"; then
        ((tests_passed++))
    fi
    echo ""
    
    # Summary
    echo "📊 $test_phase Test Results:"
    echo "   Tests Passed: $tests_passed/$total_tests"
    echo "   Success Rate: $(( tests_passed * 100 / total_tests ))%"
    
    if [ "$test_phase" = "PRE-NCC" ]; then
        if [ $tests_passed -eq 0 ]; then
            echo "   ✅ Expected result: No connectivity before NCC implementation"
        else
            echo "   ⚠️  Unexpected: Some connections working before NCC"
        fi
    else
        if [ $tests_passed -eq $total_tests ]; then
            echo "   ✅ Excellent: Full mesh connectivity achieved!"
        elif [ $tests_passed -gt 0 ]; then
            echo "   ⚠️  Partial: Some connections working, check NCC configuration"
        else
            echo "   ❌ Issue: No connectivity after NCC implementation"
        fi
    fi
    
    return $tests_passed
}

# Function to test advanced connectivity features
test_advanced_features() {
    echo ""
    echo "🔬 Advanced Connectivity Tests"
    echo "==============================="
    
    # Get VM IPs
    HUB_IP=$(get_vm_ip $HUB_VM)
    SPOKE1_IP=$(get_vm_ip $SPOKE1_VM)
    SPOKE2_IP=$(get_vm_ip $SPOKE2_VM)
    
    # Traceroute test
    echo "🛣️ Testing network path (traceroute):"
    echo "   From Spoke1 to Spoke2 via Hub..."
    
    if gcloud compute ssh $SPOKE1_VM --zone=$ZONE --command="traceroute -n -w 3 -m 10 $SPOKE2_IP" --quiet 2>/dev/null; then
        echo "   ✅ Traceroute completed successfully"
    else
        echo "   ⚠️  Traceroute may have timed out or failed"
    fi
    echo ""
    
    # Latency test
    echo "⏱️ Testing network latency:"
    echo "   Ping with timing from Spoke1 to Spoke2..."
    
    if gcloud compute ssh $SPOKE1_VM --zone=$ZONE --command="ping -c 5 -i 0.5 $SPOKE2_IP | tail -1" --quiet 2>/dev/null; then
        echo "   ✅ Latency test completed"
    else
        echo "   ⚠️  Latency test failed"
    fi
    echo ""
}

# Function to display network topology information
show_network_info() {
    echo ""
    echo "🌐 Network Topology Information"
    echo "==============================="
    
    echo "📍 VPC Networks:"
    gcloud compute networks list --filter="name:(hub-vpc OR spoke1-vpc OR spoke2-vpc)" --format="table(name,IPv4Range,description)"
    echo ""
    
    echo "🔗 Subnets:"
    gcloud compute networks subnets list --filter="name:(hub-subnet OR spoke1-subnet OR spoke2-subnet)" --format="table(name,region,range,network)"
    echo ""
    
    echo "💻 Virtual Machines:"
    gcloud compute instances list --filter="name:(hub-vm OR spoke1-vm OR spoke2-vm)" --format="table(name,zone,machineType,status,internalIP,externalIP)"
    echo ""
    
    echo "🎯 NCC Hub and Spokes:"
    if gcloud network-connectivity hubs describe my-hub >/dev/null 2>&1; then
        echo "   Hub: my-hub (Active)"
        gcloud network-connectivity spokes list --hub=my-hub --format="table(name,hub,state)" 2>/dev/null || echo "   No spokes found or error accessing spokes"
    else
        echo "   ❌ NCC Hub 'my-hub' not found"
    fi
    echo ""
}

# Function to generate test report
generate_report() {
    local pre_ncc_result=$1
    local post_ncc_result=$2
    
    echo ""
    echo "📋 Connectivity Test Report"
    echo "============================"
    echo "Date: $(date)"
    echo "Project: $PROJECT_ID"
    echo ""
    echo "Pre-NCC Results:  $pre_ncc_result/6 tests passed"
    echo "Post-NCC Results: $post_ncc_result/6 tests passed"
    echo ""
    
    if [ $pre_ncc_result -eq 0 ] && [ $post_ncc_result -eq 6 ]; then
        echo "🎉 SUCCESS: Hub-and-Spoke implementation working perfectly!"
        echo "   - No connectivity before NCC (as expected)"
        echo "   - Full connectivity after NCC implementation"
    elif [ $post_ncc_result -eq 6 ]; then
        echo "✅ SUCCESS: NCC implementation working"
        echo "   - Full connectivity achieved after NCC"
    elif [ $post_ncc_result -gt 0 ]; then
        echo "⚠️  PARTIAL SUCCESS: Some connectivity issues"
        echo "   - Check NCC spoke configuration"
        echo "   - Verify firewall rules"
    else
        echo "❌ ISSUES DETECTED: No connectivity after NCC"
        echo "   - Check NCC hub and spoke configuration"
        echo "   - Verify all VMs are running"
        echo "   - Check firewall rules"
    fi
    
    echo ""
    echo "🔧 Troubleshooting Tips:"
    echo "   - Check Network Topology in Google Cloud Console"
    echo "   - Verify NCC spoke status: gcloud network-connectivity spokes list --hub=my-hub"
    echo "   - Test VM accessibility: gcloud compute ssh [VM_NAME] --zone=$ZONE"
    echo "   - Review firewall rules: gcloud compute firewall-rules list"
}

# Main execution
main() {
    echo "Starting comprehensive connectivity testing..."
    echo ""
    
    # Show current network information
    show_network_info
    
    # Check if VMs exist and are running
    echo "🔍 Checking VM status..."
    for vm in $HUB_VM $SPOKE1_VM $SPOKE2_VM; do
        status=$(gcloud compute instances describe $vm --zone=$ZONE --format='get(status)' 2>/dev/null || echo "NOT_FOUND")
        if [ "$status" = "RUNNING" ]; then
            echo "   ✅ $vm: Running"
        else
            echo "   ❌ $vm: $status"
            if [ "$status" = "NOT_FOUND" ]; then
                echo "      Run './setup-script.sh' to create missing resources"
                exit 1
            fi
        fi
    done
    echo ""
    
    # Pre-NCC connectivity test
    run_connectivity_tests "PRE-NCC"
    pre_ncc_result=$?
    
    echo ""
    echo "⏳ Checking if NCC is configured..."
    if gcloud network-connectivity hubs describe my-hub >/dev/null 2>&1; then
        echo "   ✅ NCC Hub found, proceeding with post-NCC tests"
        
        # Wait a moment for network propagation
        echo "   ⏳ Waiting for network changes to propagate..."
        sleep 10
        
        # Post-NCC connectivity test
        run_connectivity_tests "POST-NCC"
        post_ncc_result=$?
        
        # Advanced tests if basic connectivity works
        if [ $post_ncc_result -gt 0 ]; then
            test_advanced_features
        fi
    else
        echo "   ❌ NCC Hub not found"
        echo "   Run './setup-script.sh' to create NCC configuration"
        post_ncc_result=0
    fi
    
    # Generate final report
    generate_report $pre_ncc_result $post_ncc_result
}

# Check if script is being run directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi