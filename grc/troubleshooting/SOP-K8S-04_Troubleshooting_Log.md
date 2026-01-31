Event ID: AIS-TR-01

Symptom: CoreDNS pods stuck in Pending despite removal of control-plane taint.

Diagnostic: Node reported node.kubernetes.io/not-ready taint.

Root Cause Investigation: Dependency loop where CNI (Cilium) requires a Ready node to schedule, but the node requires a functional CNI to become Ready.

Resolution Path: Verification of Cilium agent logs and kubelet service restart to force CNI configuration discovery.
