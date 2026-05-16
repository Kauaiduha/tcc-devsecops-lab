# Falco Setup

## Strategy

This repository uses Falco plus Falcosidekick for runtime detection in Entrega 4.

## Files

- Custom rules: [custom-rules.yaml](/l/disk0/kauaidb/TCC%20POC/falco/custom-rules.yaml:1)
- Helm values: [falco-values.yaml](/l/disk0/kauaidb/TCC%20POC/falco/falco-values.yaml:1)
- Validation helper: [../scripts/test-falco.sh](/l/disk0/kauaidb/TCC%20POC/scripts/test-falco.sh:1)

## Install or upgrade

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm upgrade --install falco falcosecurity/falco \
  -n devsecops-lab \
  -f falco/falco-values.yaml
```

This repository disables `watch_config_files` to avoid runtime failures related to inotify-based hot reload in this lab environment, and uses `falco.rules_files` naming aligned with Falco's documented configuration model.

## Validate the installation

Check the pods:

```bash
kubectl get pods -n devsecops-lab
```

## Trigger the runtime detections

```bash
scripts/test-falco.sh
```

The helper now:

- triggers the `kubectl exec` events inside the Juice Shop pod
- waits a few seconds for Falco to process the syscalls
- prints the recent Falco alerts already filtered for the lab events
- prints the recent Falcosidekick logs for quick confirmation

Optional arguments:

```bash
scripts/test-falco.sh <namespace> <pod-name> <node-bin> <wait-seconds> <since-window>
```

Expected runtime events:

- exec style process execution inside the Juice Shop container
- sensitive file read attempt such as `/etc/passwd` or the local Juice Shop SQLite file

The custom rules in this repository use Kubernetes metadata (`k8s.ns.name` and `k8s.pod.name`) to avoid overfitting on image repository or parent process details that can vary across runtimes.

## Suggested evidence

- Falco logs showing the custom alert
- Falcosidekick Web UI alert list
- terminal output from the triggering commands
