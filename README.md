ClusterBalancer – Adaptive Workload Distribution for Kubernetes

ClusterBalancer is an automated Kubernetes workload balancing system that continuously monitors cluster resource utilization and intelligently redistributes workloads to maintain optimal performance and high availability. It detects overloaded and underutilized nodes based on CPU and memory thresholds and safely migrates pods using Kubernetes-native mechanisms.

The system integrates real-time monitoring, decision-making logic, and controlled workload migration to ensure efficient resource usage without compromising application stability.

🔧 Key Features
Real-Time Monitoring
Tracks CPU and memory usage of all nodes
Provides continuous or on-demand health checks
Example monitoring via monitor.py
Intelligent Decision Engine
Identifies:
Overloaded nodes (>70% CPU)
Underutilized nodes (<30% CPU)
Generates workload redistribution strategies
Safe Workload Migration
Uses Kubernetes scheduling for pod relocation
Supports Pod Disruption Budgets (PDB)
Includes retry and graceful termination logic
Automated Overload Simulation
Demo scripts create high CPU workloads to test balancing
Example: demo_overload.sh generates stress workloads
Configurable System
Thresholds and behavior defined in JSON config
Example config:
Continuous Monitoring Mode
Runs as a daemon with logging support
Example: continuous_monitor.py
