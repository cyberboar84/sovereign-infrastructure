#!/bin/bash

# --- Sovereign AI Lab: Llama 3.1 70B Native Config ---
# Hardware: 6-GPU Heterogeneous (56GB VRAM Total)

# 1. THE MAGIC FIX: Force CUDA to match nvidia-smi order
export CUDA_DEVICE_ORDER=PCI_BUS_ID

# PATHS
MODEL_PATH="/home/ml-boar/sovereign-ai/models/Meta-Llama-3.1-70B-Instruct.Q4_K_M.gguf"
BIN_PATH="/home/ml-boar/sovereign-ai/llama.cpp/build/bin/llama-server"

# CONFIG
CTX_SIZE=8192
BATCH_SIZE=256
THREADS=12            

# TENSOR SPLIT (Matched to nvidia-smi Physical Order)
# GPU 0: 3080 (10GB)    -> 18
# GPU 1: 3060Ti (8GB)   -> 14
# GPU 2: 3060 (12GB)    -> 10  <-- We give it LESS load (Speed Optimization)
# GPU 3: 3060Ti (8GB)   -> 14
# GPU 4: 3070 (8GB)     -> 14
# GPU 5: 3080 (10GB)    -> 18

TS_SPLIT="18,14,10,14,14,18"

echo "🚀 Starting ml-boar Sovereign Lab Inference Engine..."
echo "📍 GPU Split: $TS_SPLIT (PCI_BUS_ID Ordered)"

$BIN_PATH \
  -m "$MODEL_PATH" \
  -c "$CTX_SIZE" \
  -b "$BATCH_SIZE" \
  -t "$THREADS" \
  --n-gpu-layers 81 \
  --tensor-split "$TS_SPLIT" \
  --main-gpu 0 \
  --host 0.0.0.0 \
  --port 8080 \
  --flash-attn on \
  --mlock
