# Network Architecture Diagram

## Hub and Spoke Topology Overview

```mermaid
graph TB
    subgraph "Google Cloud Project"
        subgraph "Hub VPC (10.1.0.0/24)"
            H[Hub VM<br/>10.1.0.x]
            HS[hub-subnet<br/>us-central1]
        end
        
        subgraph "Network Connectivity Center"
            NCC[NCC Hub: my-hub<br/>Centralized Connectivity]
        end
        
        subgraph "Spoke1 VPC (10.2.0.0/24)"
            S1[Spoke1 VM<br/>10.2.0.x]
            S1S[spoke1-subnet<br/>us-central1]
        end
        
        subgraph "Spoke2 VPC (10.3.0.0/24)"
            S2[Spoke2 VM<br/>10.3.0.x]
            S2S[spoke2-subnet<br/>us-central1]
        end
    end
    
    %% NCC Connections
    NCC ---|Spoke1| S1S
    NCC ---|Spoke2| S2S
    
    %% VM Connections within subnets
    H --- HS
    S1 --- S1S
    S2 --- S2S
    
    %% Styling
    classDef hubStyle fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef spokeStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef nccStyle fill:#e8f5e8,stroke:#1b5e20,stroke-width:3px
    classDef vmStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    
    class NCC nccStyle
    class H,S1,S2 vmStyle
    class HS hubStyle
    class S1S,S2S spokeStyle
```

## Detailed Network Architecture

### Network Components

#### VPC Networks
| Network | CIDR Range | Region | Purpose |
|---------|------------|--------|---------|
| hub-vpc | 10.1.0.0/24 | us-central1 | Central hub network |
| spoke1-vpc | 10.2.0.0/24 | us-central1 | First spoke network |
| spoke2-vpc | 10.3.0.0/24 | us-central1 | Second spoke network |

#### Virtual Machines
| VM Name | Network | Internal IP | Machine Type | Purpose |
|---------|---------|-------------|--------------|---------|
| hub-vm | hub-vpc | 10.1.0.x | e2-micro | Hub connectivity testing |
| spoke1-vm | spoke1-vpc | 10.2.0.x | e2-micro | Spoke1 connectivity testing |
| spoke2-vm | spoke2-vpc | 10.3.0.x | e2-micro | Spoke2 connectivity testing |

#### Firewall Rules
| Rule Name | Networks | Protocols | Ports | Purpose |
|-----------|----------|-----------|-------|---------|
| app-allow-icmp-* | All VPCs | ICMP | - | Ping connectivity testing |
| app-allow-ssh-rdp-* | All VPCs | TCP | 22, 3389 | Remote access |

### Connectivity Flow Diagram

```mermaid
sequenceDiagram
    participant S1 as Spoke1 VM
    participant NCC as NCC Hub
    participant S2 as Spoke2 VM
    participant H as Hub VM
    
    Note over S1,S2: Before NCC Implementation
    S1--xS2: ❌ Direct connection fails
    S2--xS1: ❌ Direct connection fails
    
    Note over S1,S2: After NCC Implementation
    S1->>NCC: Route to Spoke2
    NCC->>S2: Forward to Spoke2
    S2->>NCC: Route to Spoke1
    NCC->>S1: Forward to Spoke1
    
    Note over H,NCC: Hub can reach all spokes
    H->>NCC: Route to any spoke
    NCC->>S1: Forward to Spoke1
    NCC->>S2: Forward to Spoke2
```

### Traffic Flow Patterns

#### Inter-Spoke Communication (via NCC)
```
Spoke1 VM → NCC Hub → Spoke2 VM
Spoke2 VM → NCC Hub → Spoke1 VM
```

#### Hub-to-Spoke Communication
```
Hub VM → NCC Hub → Spoke1/Spoke2 VM
Spoke1/Spoke2 VM → NCC Hub → Hub VM
```

### Network Topology Visualization

#### Physical Topology
```
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Region                      │
│                      (us-central1)                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Hub VPC   │    │  Spoke1 VPC │    │  Spoke2 VPC │     │
│  │ 10.1.0.0/24 │    │ 10.2.0.0/24 │    │ 10.3.0.0/24 │     │
│  │             │    │             │    │             │     │
│  │   hub-vm    │    │  spoke1-vm  │    │  spoke2-vm  │     │
│  │  10.1.0.x   │    │   10.2.0.x  │    │   10.3.0.x  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│           │                   │                   │         │
│           └───────────────────┼───────────────────┘         │
│                               │                             │
│                    ┌─────────────────┐                     │
│                    │  NCC Hub        │                     │
│                    │   (my-hub)      │                     │
│                    │                 │                     │
│                    │  Spoke1 ←→ Hub  │                     │
│                    │  Spoke2 ←→ Hub  │                     │
│                    └─────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

#### Logical Connectivity Matrix

| Source | Destination | Before NCC | After NCC | Path |
|--------|-------------|------------|-----------|------|
| Spoke1 VM | Spoke2 VM | ❌ | ✅ | via NCC Hub |
| Spoke2 VM | Spoke1 VM | ❌ | ✅ | via NCC Hub |
| Hub VM | Spoke1 VM | ❌ | ✅ | via NCC Hub |
| Hub VM | Spoke2 VM | ❌ | ✅ | via NCC Hub |
| Spoke1 VM | Hub VM | ❌ | ✅ | via NCC Hub |
| Spoke2 VM | Hub VM | ❌ | ✅ | via NCC Hub |

### Security Architecture

#### Firewall Rules Matrix
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│   Rule      │   Hub VPC   │ Spoke1 VPC  │ Spoke2 VPC  │
├─────────────┼─────────────┼─────────────┼─────────────┤
│ ICMP Allow  │     ✅      │     ✅      │     ✅      │
│ SSH Allow   │     ✅      │     ✅      │     ✅      │
│ RDP Allow   │     ✅      │     ✅      │     ✅      │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Scalability Considerations

#### Adding New Spokes
```mermaid
graph LR
    subgraph "Current Setup"
        NCC1[NCC Hub]
        S1[Spoke1]
        S2[Spoke2]
        NCC1 --- S1
        NCC1 --- S2
    end
    
    subgraph "Scaled Setup"
        NCC2[NCC Hub]
        S3[Spoke1]
        S4[Spoke2]
        S5[Spoke3]
        S6[Spoke4]
        S7[SpokeN...]
        NCC2 --- S3
        NCC2 --- S4
        NCC2 --- S5
        NCC2 --- S6
        NCC2 --- S7
    end
```

### Monitoring and Observability

#### Key Metrics to Monitor
- **Connectivity Status**: Spoke-to-spoke ping success rate
- **Latency**: Round-trip time between spokes
- **Throughput**: Bandwidth utilization across NCC
- **Network Topology**: Visual representation of connections
- **Route Propagation**: Time for routing updates

#### Network Topology Tool Features
- Real-time network visualization
- Traffic flow analysis
- Performance metrics
- Connection health status
- Regional traffic patterns

### Benefits of This Architecture

1. **Centralized Management**: Single point of control through NCC
2. **Simplified Routing**: No complex VPC peering configurations
3. **Scalability**: Easy addition of new spokes
4. **Full Mesh Connectivity**: All spokes can communicate
5. **Reduced Operational Overhead**: Less configuration maintenance
6. **Enhanced Monitoring**: Built-in topology and metrics visualization

### Implementation Notes

- All resources are deployed in `us-central1` region
- VMs use `e2-micro` machine type for cost efficiency
- Firewall rules allow necessary traffic for testing
- NCC provides automatic route exchange between spokes
- Network topology updates reflect in real-time
