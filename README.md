# kubectl-err

A bird's-eye view of everything unhealthy in a Kubernetes cluster, in one screen.

## Examples

The whole cluster, one line per problem:

```
$ kubectl err
KIND         NAMESPACE    NAME                   REASON                AGE  DETAIL
Node         -            ip-10-0-3-14           NotReady              12m  Kubelet stopped posting node status.
Node         -            ip-10-0-3-14           MemoryPressure        9m   kubelet has memory pressure
Node         -            ip-10-0-2-88           SchedulingDisabled    3d   cordoned
Deployment   payments     api                    RolloutStalled        18m  ProgressDeadlineExceeded: ReplicaSet api-9f8c has timed out progressing. (updated 1/3)
Deployment   search       web                    Unavailable           7m   0/2 ready (MinimumReplicasUnavailable)
HelmRelease  flux-system  redis                  InstallFailed         2h   Helm install failed: timed out waiting for the condition
Job          batch        nightly                Failed                5h   1 failed Job has reached the specified backoff limit
Service      payments     checkout               NoEndpoints           45m  selector matches no ready pods: app=checkout,tier=web
Pod          payments     Deployment/api (x3)    ImagePullBackOff      18m  api: Back-off pulling image "registry.example.com/api:v2.0.0"
Pod          payments     checkout-7d9f8b-lm4kq  CrashLoopBackOff      3d   app: back-off 5m0s restarting failed container (restarts: 7)
Pod          batch        reindex-q8s2v          Evicted               26m  The node was low on resource: memory.
Pod          payments     ledger-0               Restarting            40s  app: restarted 4x, last exit 137 OOMKilled
Pod          search       indexer-5b7c94-2xqvz   ContainerCreating     11m  app: stuck for 11m | FailedMount: secret "index-creds" not found
Pod          search       Deployment/web (x2)    NotReady              7m   containers not ready: web
Pod          batch        bulk-import            Pending               1h   0/6 nodes are available: 6 Insufficient cpu.
Pod          default      legacy-cron-28r4t      Terminating           4d   stuck since 2026-08-30T02:11:07Z
CronJob      batch        reconcile              Suspended             19d  schedule 0 2 * * * is suspended, last run 2026-08-14T02:00:00Z
HPA          payments     api                    ScalingActive         2h   FailedGetResourceMetric: no metrics returned from resource metrics API
Ingress      payments     checkout               NoAddress             45m  no load balancer address assigned (class nginx)
Namespace    -            staging                Terminating           5d   stuck since 2026-08-28T09:41:02Z - usually a finalizer
PDB          payments     api-pdb                NoDisruptionsAllowed  30d  2/2 healthy - drains and upgrades will block
PV           -            pvc-9f2c1ab            Released              12d  claim: index-data-0
PVC          search       index-data-0           Pending               1h   storageClass: gp3-encrypted (Immediate)

23 problems in 6 namespaces
```

`-o wide` adds where the pod landed and exactly which image it is running — `*` when a collapsed
group spans several nodes:

```
$ kubectl err -o wide
KIND        NAMESPACE  NAME                 REASON            AGE  DETAIL                                        NODE          IMAGE
Deployment  payments   api                  RolloutStalled    18m  ProgressDeadlineExceeded (updated 1/3)        -             registry.example.com/api:v2.0.0
Service     payments   checkout             NoEndpoints       45m  selector matches no ready pods: app=checkout  -             -
Pod         payments   Deployment/api (x3)  ImagePullBackOff  18m  api: Back-off pulling image                   *             registry.example.com/api:v2.0.0
Pod         payments   ledger-0             Restarting        40s  app: restarted 4x, last exit 137 OOMKilled    ip-10-0-2-88  registry.example.com/ledger:1.9.3
```

## Install

```sh
kubectl krew install err
```

Or straight from source:

```sh
git clone https://github.com/vector-mj/kubectl-err.git
cd kubectl-err
sudo install -m 0755 kubectl-err /usr/local/bin/kubectl-err
kubectl err
```

Requires `kubectl` and [`jq`](https://jqlang.github.io/jq/).

## Usage

```
kubectl err [KINDS] [-n NAMESPACE] [-o wide|json] [-w] [-g SECONDS] [-e] [--full]
            [--context NAME] [--kubeconfig PATH]

  KINDS                comma-separated kinds to check, kubectl-style short names:
                       po no deploy sts ds job cj svc ing hpa pdb pvc pv ns ev crd
                       e.g. "kubectl err po,pvc,svc". Omit it to check all of them.
  -n, --namespace NS   scope namespaced resources to NS (default: all namespaces)
  -o wide, --wide      add NODE and IMAGE columns (full image:tag)
  -o json              emit the findings as JSON instead of a table
  -w, --watch          refresh every second until interrupted
  -g, --grace SECONDS  hide startup states for a pod's first SECONDS (default 60)
  -t, --timeout SECS   per-request timeout; past it the cluster is called unreachable
                       (default 10, or KUBECTL_ERR_TIMEOUT)
  -e, --events         also show Warning events from the last hour
      --full           do not truncate the DETAIL column
      --context NAME   kubectl context to use
      --kubeconfig P   kubeconfig file to use
      --version        print the version and exit
```

Exits **1** when anything unhealthy was found, **0** when clear, and **2** when the cluster
is unreachable — so a failed check never reads as a healthy one. Drop it in CI or a probe.


## What counts as unhealthy

| Kind | Flagged when |
|---|---|
| Pod | any container waiting (`CrashLoopBackOff`, `ImagePullBackOff`, `ErrImagePull`, `CreateContainerConfigError`, …); container exited non-zero (`Error`, `OOMKilled`); restarted within the last hour but momentarily up (`Restarting`); `ContainerCreating` / `PodInitializing` past the grace window; `Pending`; `Failed` / `Evicted`; `Running` but not `Ready`; stuck `Terminating` |
| Node | `Ready != True`; memory/disk/PID pressure; cordoned |
| Deployment, StatefulSet | `readyReplicas < spec.replicas`, or ready but wedged (`RolloutStalled`) |
| DaemonSet | `numberReady < desiredNumberScheduled` |
| Job | `status.failed > 0` |
| CronJob | suspended |
| Service | selector matches no ready endpoints |
| Ingress | no load balancer address |
| HPA | `AbleToScale` or `ScalingActive` false |
| PDB | `disruptionsAllowed == 0` — drains will block |
| PVC, PV | not `Bound` / not `Bound` or `Available`. A `WaitForFirstConsumer` claim sitting Pending with no pod is its design, not a fault, so it is not reported |
| Namespace | `Terminating` for over a minute |
| Flux, Argo, cert-manager, external-secrets | `Ready`/`Healthy`/`Available`/`Synced` false, when the CRD is installed |
| Event (`-e`) | `type=Warning` in the last hour |
