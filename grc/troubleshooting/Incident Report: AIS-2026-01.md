Title: System Utility Recursion via Storage Partition Collision Severity: CRITICAL (Loss of Package Management & Binary Execution) Status: RESOLVED

1. The Anomaly (Root Cause)
The system entered a "Recursive Execution Loop" where the core library indexer (ldconfig) was replaced by a shell script that called itself infinitely.

Trigger: The 4TB NVMe partition (nvme0n1p4) was "Bind Mounted" to multiple system locations simultaneously (/home, /mnt/sovereign-storage, and /var/snap/microk8s/...).

Mechanism: When the legacy NVIDIA toolkit attempted to wrap ldconfig, the bind-mount reflected the change back into the system root, causing the wrapper script to overwrite the real binary with a pointer to itself.

Result: apt, dpkg, and sudo operations deadlocked.

2. The Remediation (The Fix)
We executed a Manual Binary Transplant to restore system sovereignty:

Isolation: Force-unmounted legacy MicroK8s paths to break the filesystem mirror.

Transplant: Manually extracted the ldconfig ELF binary from an external libc-bin package and injected it into /sbin, bypassing the corrupted wrapper.

Sanitization: Edited /etc/fstab to permanently disable the recursive bind-mounts.

Capacityproofing: Redirected /var/lib/containerd to the 4TB drive via symbolic link to prevent Root Partition Exhaustion.

3. The New Baseline (Current State)
Driver Stack: Native NVIDIA Datacenter Drivers (v570.211) via CDI (Container Device Interface).

Storage Architecture: Decoupled. System root is isolated from volatile container data.

Hardware Status: 6/6 GPUs Online (2x 3080, 2x 3060 Ti, 1x 3060, 1x 3070).
