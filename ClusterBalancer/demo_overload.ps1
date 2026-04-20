# ClusterBalancer - Overload Demo Script (PowerShell)
# This demonstrates the system detecting and fixing overloaded nodes

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ClusterBalancer - Overload & Rebalancing Demo" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DemoDir = "c:\Users\kowne\Downloads\Drive\CPP Mini Project\ClusterBalancer\ClusterBalancer"
$TempYaml = "$env:TEMP\heavy-workload.yaml"
Set-Location $DemoDir

# ============================================
# STEP 1: Show current cluster state
# ============================================
Write-Host "[STEP 1] Current Cluster State" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

Write-Host "Nodes:" -ForegroundColor Green
kubectl get nodes
Write-Host ""

Write-Host "Current pod count:" -ForegroundColor Green
kubectl get pods --all-namespaces | Measure-Object | Select-Object -ExpandProperty Count | ForEach-Object { Write-Host "  Total: $_ pods" }
Write-Host ""

# ============================================
# STEP 2: Create heavy CPU workload
# ============================================
Write-Host "[STEP 2] Creating HEAVY CPU Overload" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

$HeavyWorkload = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-heavy
  namespace: default
spec:
  replicas: 10
  selector:
    matchLabels:
      app: cpu-heavy
  template:
    metadata:
      labels:
        app: cpu-heavy
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - minikube-m02
      containers:
      - name: stress
        image: alexeiled/stress-ng:latest
        args:
          - "--cpu"
          - "4"
          - "--cpu-load"
          - "100"
          - "--timeout"
          - "600s"
        resources:
          limits:
            cpu: "1800m"
            memory: "512Mi"
          requests:
            cpu: "1800m"
            memory: "256Mi"
"@

$HeavyWorkload | Out-File -FilePath $TempYaml -Encoding UTF8
Write-Host "[OK] Created SINGLE-NODE OVERLOAD scenario"
Write-Host "  📌 10 replicas x 1.8 CPU each = 18 CPU total"
Write-Host "  📌 All pods PINNED to minikube-m02 (one node)"
Write-Host "  ⚠️  This will OVERLOAD that node while others are empty!"
Write-Host "  ✅ Perfect for testing REBALANCING!"
Write-Host ""

Write-Host "Deploying workload..." -ForegroundColor Green
kubectl apply -f $TempYaml
Write-Host "[OK] Deployment created" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 3: Wait for pods to start
# ============================================
Write-Host "[STEP 3] Waiting for Pods to Start (60 seconds)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

for ($i = 1; $i -le 12; $i++) {
    $running = kubectl get pods -l app=cpu-heavy -o jsonpath='{.items[*].status.phase}' 2>&1 | Where-Object { $_ -match "Running" } | Measure-Object | Select-Object -ExpandProperty Count
    Write-Host "  [$i/12] Running pods: $running/8" -ForegroundColor Cyan
    Start-Sleep -Seconds 5
}

Write-Host ""

Write-Host "[OK] Pods are running and consuming CPU" -ForegroundColor Green
Write-Host ""
Write-Host "Waiting 30 seconds for CPU stress to ramp up to full capacity..." -ForegroundColor Cyan
for ($i = 30; $i -gt 0; $i--) {
    Write-Host -NoNewline "`r  Time remaining: ${i}s  "
    Start-Sleep -Seconds 1
}
Write-Host ""
Write-Host ""

# ============================================
# STEP 4: Show current resource usage
# ============================================
Write-Host "[STEP 4] Resource Usage (With Heavy Load)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

Write-Host "Heavy workload pods (by node):" -ForegroundColor Green
kubectl get pods -l app=cpu-heavy -o wide | Select-Object -Skip 1 | ForEach-Object { Write-Host "  $_" }
Write-Host ""

# ============================================
# STEP 5: Run ClusterBalancer monitoring
# ============================================
Write-Host "[STEP 5] Running ClusterBalancer Monitoring" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""
Write-Host "This will detect overloaded nodes (>5% CPU)" -ForegroundColor Cyan
Write-Host ""

Push-Location $DemoDir
python monitoring/monitor.py
Pop-Location

Write-Host ""

# ============================================
# STEP 6: Show what the monitoring found
# ============================================
Write-Host "[STEP 6] Analysis" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

Write-Host "If you see overloaded nodes above, here are your options:" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1: PREVIEW what would be rebalanced (no changes)" -ForegroundColor Cyan
Write-Host "  cd '$DemoDir'" -ForegroundColor Gray
Write-Host "  python scheduler/rebalance.py --dry-run" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 2: PERFORM automatic rebalancing" -ForegroundColor Cyan
Write-Host "  python scheduler/rebalance.py" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 3: MONITOR continuously to watch balancing" -ForegroundColor Cyan
Write-Host "  python monitoring/monitor.py --continuous --interval 5" -ForegroundColor Gray
Write-Host ""

# ============================================
# STEP 7: Cleanup instructions
# ============================================
Write-Host "[STEP 7] Cleanup Instructions" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

Write-Host "Remove the heavy workload:" -ForegroundColor Green
Write-Host "  kubectl delete deployment cpu-heavy" -ForegroundColor Gray
Write-Host ""

Write-Host "Check cluster returns to normal:" -ForegroundColor Green
Write-Host "  python monitoring/monitor.py" -ForegroundColor Gray
Write-Host ""

# Cleanup temp file
Remove-Item $TempYaml -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Demo Setup Complete! Ready to show overload scenario" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
