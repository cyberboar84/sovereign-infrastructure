Incident ID: AIS-TR-07

Symptom: OCI runtime create failed (exit status 127) / proc/self/fd/11 error.

Root Cause: Broken pipe in the NVIDIA pre-start hook, likely due to a path mismatch between legacy nvidia-container-runtime and the modern nvidia-container-toolkit in the containerd config.

Resolution: Reinstalled toolkit and performed a clean-slate generation of config.toml with SystemdCgroup alignment.

Security Status: RECOVERED.
