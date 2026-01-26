import os
import time
import subprocess
import glob

# --- CONFIGURATION ---
CHECK_INTERVAL = 5
GPU_COUNT = 6
# Curve: (Temperature, Fan_Speed)
FAN_CURVE = [
    (0, 30), (40, 30), (50, 50), (60, 75), (70, 100), (90, 100)
]

def find_and_set_auth():
    """
    Auto-detect the XAuthority file.
    """
    # WE ADDED YOUR SPECIFIC PATH AS THE #1 CANDIDATE
    candidates = [
        "/run/user/120/gdm/Xauthority",  # <--- The Golden Key
        "/var/run/lightdm/root/:0",
        "/run/user/*/gdm/Xauthority",
        "/home/*/.Xauthority",
        "/var/lib/gdm3/.Xauthority"
    ]
    
    auth_file = None
    # Check exact paths first
    for path in candidates:
        if "*" not in path and os.path.exists(path):
            auth_file = path
            break
        # Handle wildcards if exact path fails
        elif "*" in path:
            matches = glob.glob(path)
            if matches:
                auth_file = max(matches, key=os.path.getmtime)
                break
            
    if auth_file:
        os.environ["XAUTHORITY"] = auth_file
        os.environ["DISPLAY"] = ":0"
        print(f"Auth found: {auth_file}")
        return True
    else:
        print("ERROR: No XAuthority file found.")
        return False

def get_temp(gpu_id):
    try:
        # We use strict paths for system commands
        result = subprocess.check_output(
            ["/usr/bin/nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits", "-i", str(gpu_id)]
        )
        return int(result.decode("utf-8").strip())
    except Exception:
        return 50 # Safe default

def calculate_speed(temp):
    for i in range(len(FAN_CURVE) - 1):
        t1, s1 = FAN_CURVE[i]
        t2, s2 = FAN_CURVE[i+1]
        if t1 <= temp <= t2:
            ratio = (temp - t1) / (t2 - t1)
            return int(s1 + (ratio * (s2 - s1)))
    return 100

def set_fan(gpu_id, speed):
    fan_a = gpu_id * 2
    fan_b = gpu_id * 2 + 1
    # Note: We don't use shell=True to avoid subshell overhead, but nvidia-settings needs env vars
    # so passing os.environ is critical.
    cmd = [
        "/usr/bin/nvidia-settings",
        "-a", f"[gpu:{gpu_id}]/GPUFanControlState=1",
        "-a", f"[fan:{fan_a}]/GPUTargetFanSpeed={speed}",
        "-a", f"[fan:{fan_b}]/GPUTargetFanSpeed={speed}"
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=os.environ)
    except Exception as e:
        print(f"Failed to set fan {gpu_id}: {e}")

# --- MAIN LOOP ---
if __name__ == "__main__":
    print("Starting Sovereign AI Smart Fan Control...")
    
    # Locate auth ONCE at startup
    if not find_and_set_auth():
        print("Warning: Running without explicit XAUTHORITY. If fans don't spin, check X11.")

    try:
        while True:
            for i in range(GPU_COUNT):
                t = get_temp(i)
                s = calculate_speed(t)
                set_fan(i, s)
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("Stopping.")
