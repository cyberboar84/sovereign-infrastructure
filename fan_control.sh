#!/bin/bash

# --- CONFIGURATION ---
MIN_SPEED=50      # Raised to 50% to prevent "Zero RPM" dropout
MAX_TEMP=70
CHECK_DELAY=2     # Speed up loop to 2s to fight firmware overrides
# ---------------------

# 1. FIND KEYS
XAUTHORITY_PATH=$(ps -ef | grep /Xorg | grep -o '\-auth [^ ]*' | awk '{print $2}' | head -n 1)
if [ -z "$XAUTHORITY_PATH" ]; then
    echo "Error: Is Xorg running?"
    exit 1
fi
export DISPLAY=:0
export XAUTHORITY=$XAUTHORITY_PATH

# 2. MAIN LOOP
while true; do
    for gpu_id in {0..5}; do
        
        # Temp Logic
        CURRENT_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $gpu_id)
        
        if [ "$CURRENT_TEMP" -le 45 ]; then
             NEW_SPEED=$MIN_SPEED
        elif [ "$CURRENT_TEMP" -ge "$MAX_TEMP" ]; then
             NEW_SPEED=100
        else
             NEW_SPEED=$(( ($CURRENT_TEMP - 40) * 2 + $MIN_SPEED ))
        fi
        
        if [ "$NEW_SPEED" -gt 100 ]; then NEW_SPEED=100; fi

        # Calculate Fans (2 per GPU)
        FAN_A=$((gpu_id * 2))
        FAN_B=$((gpu_id * 2 + 1))

        # --- THE AGGRESSIVE FIX ---
        # We send the "Enable Manual Control" command EVERY loop, right before setting speed.
        # This prevents the firmware from switching back to Auto/Zero-RPM.
        nvidia-settings -a "[gpu:$gpu_id]/GPUFanControlState=1" \
                        -a "[fan:$FAN_A]/GPUTargetFanSpeed=$NEW_SPEED" \
                        -a "[fan:$FAN_B]/GPUTargetFanSpeed=$NEW_SPEED" > /dev/null 2>&1
    done
    
    sleep $CHECK_DELAY
done
