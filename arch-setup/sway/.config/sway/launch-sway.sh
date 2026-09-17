#!/bin/bash

# Sway launcher script
#
# IMPORTANT: Your monitors are connected to the NVIDIA GPU (card1), but Sway
# historically does not officially support proprietary NVIDIA drivers.
#
# If Sway fails to start or crashes, your options are:
# 1. Move display cables to your motherboard outputs (AMD iGPU / card0)
#    and uncomment the WLR_DRM_DEVICES line below.
# 2. Switch to the open-source nouveau driver (requires system-wide change).
# 3. Use a different Wayland compositor that supports NVIDIA (e.g. Hyprland).
#
# The environment variables below may allow Sway to run on recent NVIDIA
# drivers (550+), but stability and performance are not guaranteed.

# Disable hardware cursors — required for most NVIDIA + Wayland setups
export WLR_NO_HARDWARE_CURSORS=1

# Use NVIDIA's GBM backend
export GBM_BACKEND=nvidia-drm

# Ensure GLX uses the NVIDIA vendor library
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Optional: disable atomic modesetting if you experience flickering/artifacts
# export WLR_DRM_NO_ATOMIC=1

# Optional: allow software rendering if GPU compositing fails entirely
# export WLR_RENDERER_ALLOW_SOFTWARE=1

# If you move display cables to the AMD iGPU (motherboard outputs), uncomment:
# export WLR_DRM_DEVICES=/dev/dri/card0

exec sway --unsupported-gpu "$@"
