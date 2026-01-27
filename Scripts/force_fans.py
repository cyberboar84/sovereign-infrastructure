import os
import time

# --- CONFIG ---
TARGET_SPEED = 30  # Set this to 80 when you run models, 30 for idle
GPU_COUNT = 6
# The "Golden Key" you found in the logs
X_KEY = "/run/user/120/gdm/Xauthority"

# Setup the environment strictly for this run
os.environ["XAUTHORITY"] = X_KEY
os.environ["DISPLAY"] = ":0"

print(f"Forcing all {GPU_COUNT} GPUs to {TARGET_SPEED}%...")

for i in range(GPU_COUNT):
    # Enable Control
    os.system(f'nvidia-settings -a "[gpu:{i}]/GPUFanControlState=1" > /dev/null')
    
    # Set Speed (Covering both possible fan indices per card)
    os.system(f'nvidia-settings -a "[fan:{i*2}]/GPUTargetFanSpeed={TARGET_SPEED}" > /dev/null')
    os.system(f'nvidia-settings -a "[fan:{i*2+1}]/GPUTargetFanSpeed={TARGET_SPEED}" > /dev/null')

print("Done. Check nvidia-smi.")
