# Android SDK Environment Variables
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export ANDROID_AVD_HOME=$HOME/.android/avd
# Edit ~/.bashrc.d/android.bash
# Change the emulator line in android-run to:
ANDROID_AVD_HOME=$HOME/.android/avd

# Put Android paths FIRST to override Windows SDK
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

# Aliases
alias android-list='avdmanager list avd'
alias android-devices='adb devices'

# Android Helper Functions

android-kvm-setup ()
{
  set +e
  echo "🔧 Android KVM Setup"
  echo "========================================"

  # Detect environment
  if grep -qi microsoft /proc/version; then
    echo "📍 Detected: WSL2"
    echo ""

    # WSL Setup
    echo "Step 1: Setting up Windows .wslconfig"
    echo "----------------------------------------"

    # Get Windows username
    local win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    local wslconfig_path="/mnt/c/Users/$win_user/.wslconfig"

    if [ -f "$wslconfig_path" ]; then
      echo "⚠️  .wslconfig already exists at: $wslconfig_path"
      read -p "Backup and overwrite? (y/N): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cp "$wslconfig_path" "$wslconfig_path.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✓ Backed up existing config"
      else
        echo "Skipping Windows config..."
      fi
    fi

    if [[ "$confirm" =~ ^[Yy]$ ]] || [ ! -f "$wslconfig_path" ]; then
      # Check CPU vendor
      local cpu_vendor=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
      local kvm_params=""

      if [[ "$cpu_vendor" == "GenuineIntel" ]]; then
        kvm_params="intel_iommu=on iommu=pt kvm.ignore_msrs=1 kvm-intel.nested=1 kvm-intel.ept=1"
      elif [[ "$cpu_vendor" == "AuthenticAMD" ]]; then
        kvm_params="amd_iommu=on iommu=pt kvm.ignore_msrs=1 kvm-amd.nested=1"
      fi

      cat > "$wslconfig_path" << EOF
[wsl2]
nestedVirtualization=true
kernelCommandLine=$kvm_params
EOF
echo "✓ Created .wslconfig with nested virtualization enabled"
echo "  CPU detected: $cpu_vendor"
    fi

    echo ""
    echo "Step 2: Setting up Linux permissions"
    echo "----------------------------------------"

    # Create kvm group and add user
    sudo groupadd -f kvm
    sudo usermod -a -G kvm $USER
    echo "✓ Added $USER to kvm group"

    # Create udev rule
    echo 'KERNEL=="kvm", GROUP="kvm", MODE="0660"' | sudo tee /etc/udev/rules.d/99-kvm.rules > /dev/null
    echo "✓ Created udev rule for /dev/kvm"

    # Fix current permissions
    if [ -e /dev/kvm ]; then
      sudo chown root:kvm /dev/kvm
      sudo chmod 660 /dev/kvm
      echo "✓ Fixed /dev/kvm permissions"
    fi

    echo ""
    echo "⚠️  IMPORTANT: You must restart WSL for changes to take effect!"
    echo "   From Windows PowerShell/CMD, run:"
    echo "   wsl --shutdown"
    echo ""
    echo "   Then restart your WSL terminal."

  else
    echo "📍 Detected: Native Linux (Arch)"
    echo ""

    echo "Step 1: Installing KVM packages"
    echo "----------------------------------------"

    local packages="qemu-full libvirt virt-manager edk2-ovmf dnsmasq iptables-nft"

    echo "Packages to install: $packages"
    read -p "Proceed with installation? (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      sudo pacman -S --needed $packages
      echo "✓ Packages installed"
    else
      echo "Skipping package installation..."
    fi

    echo ""
    echo "Step 2: Loading KVM modules"
    echo "----------------------------------------"

    # Detect CPU and load appropriate module
    local cpu_vendor=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')

    if [[ "$cpu_vendor" == "GenuineIntel" ]]; then
      sudo modprobe kvm_intel
      echo "✓ Loaded kvm_intel module"
    elif [[ "$cpu_vendor" == "AuthenticAMD" ]]; then
      sudo modprobe kvm_amd
      echo "✓ Loaded kvm_amd module"
    fi

    echo ""
    echo "Step 3: Setting up permissions"
    echo "----------------------------------------"

    sudo usermod -aG kvm,libvirt $USER
    echo "✓ Added $USER to kvm and libvirt groups"

    # Enable and start libvirt service
    sudo systemctl enable libvirtd
    sudo systemctl start libvirtd
    echo "✓ Enabled and started libvirtd service"

    echo ""
    echo "⚠️  Log out and back in for group changes to take effect!"
  fi

  echo ""
  echo "Step 3: Verification"
  echo "----------------------------------------"

  # Check virtualization support
  local virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
  echo "CPU virtualization support: $virt_support cores"

  # Check KVM device
  if [ -e /dev/kvm ]; then
    echo "✓ /dev/kvm exists"
    if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
      echo "✓ /dev/kvm is accessible"
    else
      echo "⚠️  /dev/kvm exists but not accessible (requires logout/restart)"
    fi
  else
    echo "⚠️  /dev/kvm does not exist (WSL requires restart)"
  fi

  # Check loaded modules
  if lsmod | grep -q kvm; then
    echo "✓ KVM modules loaded: $(lsmod | grep kvm | awk '{print $1}' | xargs)"
  else
    echo "⚠️  No KVM modules loaded (WSL requires restart)"
  fi

  echo ""
  echo "✅ KVM setup complete!"
  set -e
}

android-browse () 
{ 
  set +e;
  local packages=$(sdkmanager --list 2> /dev/null | grep -v "^Info:" | grep -v "^Loading" | fzf --multi --height=40% --border --prompt="Select packages to install: ");
  if [ -n "$packages" ]; then
    echo "$packages" | awk '{print $1}' | xargs -r sdkmanager;
  else
    echo "No packages selected.";
  fi;
  set -e
}

android-images () 
{ 
  sdkmanager --list 2> /dev/null | grep --color=auto "system-images" | fzf --height=40% --border --prompt="Browse system images: "
}

android-emulators () 
{ 
  avdmanager list avd | grep --color=auto "Name:" | sed 's/.*Name: //'
}

android-run() {
  set +e
  local avd=$(avdmanager list avd | grep "Name:" | sed 's/.*Name: //' | fzf --height=40% --border --prompt="Select emulator to run: ")
  if [ -n "$avd" ]; then
    pkill -f emulator 2>/dev/null
    pkill -f qemu 2>/dev/null
    pkill -f scrcpy 2>/dev/null
    sleep 1

    local config_file="$HOME/.android/avd/$avd.avd/config.ini"
    if [ -f "$config_file" ]; then
      sed -i 's/^hw.keyboard=.*/hw.keyboard=yes/' "$config_file" || echo "hw.keyboard=yes" >> "$config_file"
    fi

    echo "Starting emulator: $avd"

    # Use hardware rendering (faster)
    ANDROID_AVD_HOME="$HOME/.android/avd" \
      VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/dzn_icd.json \
      emulator -avd "$avd" \
      -gpu host \
      -no-snapshot \
      -no-window \
      -memory 4096 &

    EMULATOR_PID=$!  # Capture the PID

    echo "Waiting for boot..."
    adb wait-for-device

    while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
      sleep 2
      echo -n "."
    done
    echo ""

    sleep 3

    # Launch scrcpy with performance settings
    echo "Launching scrcpy..."
    scrcpy --window-title "$avd" \
      --max-size 1920 \
      --max-fps 30 \
      --video-bit-rate 4M \
      --no-audio \
      --stay-awake 
  else
    echo "No emulator selected."
  fi
  kill $EMULATOR_PID
  set -e
}

android-create () 
{ 
  set +e;
  echo "Step 1/3: Select a system image";
  echo "----------------------------------------";
  local image=$(sdkmanager --list 2> /dev/null | grep "system-images" | grep -v "^Info:" | fzf --height=40% --border --prompt="Select system image: ");
  if [ -z "$image" ]; then
    echo "No image selected. Cancelled.";
    set -e;
    return 0;
  fi;
  image=$(echo "$image" | awk '{print $1}');
  echo "";
  echo "Step 2/3: Installing system image";
  echo "----------------------------------------";
  echo "Installing $image...";
  sdkmanager "$image";
  if [ $? -ne 0 ]; then
    echo "Failed to install system image.";
    set -e;
    return 1;
  fi;
  echo "";
  echo "Step 3/3: Create emulator";
  echo "----------------------------------------";
  read -p "Enter emulator name (e.g., Pixel_8): " avd_name;
  if [ -z "$avd_name" ]; then
    echo "No name provided. Cancelled.";
    set -e;
    return 0;
  fi;
  echo "";
  echo "Select a device profile:";
  local device_selection=$(avdmanager list device 2> /dev/null | awk '
  /^id:/ { 
    # Extract numeric id and string id
    match($0, /id: ([0-9]+) or "([^"]+)"/, arr)
    id_num = arr[1]
    id_str = arr[2]
    getline  # Read next line (Name)
    match($0, /Name: (.+)/, name_arr)
    device_name = name_arr[1]
    if (id_str != "") {
      printf "%s | %s\n", id_str, device_name
    }
}
' | fzf --height=40% --border --prompt="Select device profile: ");
if [ -z "$device_selection" ]; then
  echo "No device selected. Cancelled.";
  set -e;
  return 0;
fi;
local device=$(echo "$device_selection" | awk -F' \\| ' '{print $1}');
echo "";
echo "Creating emulator '$avd_name' with device profile '$device'...";
avdmanager create avd -n "$avd_name" -k "$image" -d "$device";
if [ $? -eq 0 ]; then
  echo "";
  echo "✓ Emulator '$avd_name' created successfully!";
  echo "";
  echo "Run it with: android-run";
  echo "Or directly: emulator -avd $avd_name";
else
  echo "✗ Failed to create emulator";
  set -e;
  return 1;
fi;
set -e
}

android-delete () 
{ 
  set +e;
  local avd=$(avdmanager list avd | grep "Name:" | sed 's/.*Name: //' | fzf --height=40% --border --prompt="Select emulator to delete: ");
  if [ -z "$avd" ]; then
    echo "No emulator selected.";
    set -e;
    return 0;
  fi;
  echo "";
  read -p "Are you sure you want to delete '$avd'? (y/N): " confirm;
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    avdmanager delete avd -n "$avd";
    if [ $? -eq 0 ]; then
      echo "✓ Deleted emulator: $avd";
    else
      echo "✗ Failed to delete emulator";
      set -e;
      return 1;
    fi;
  else
    echo "Cancelled.";
  fi;
  set -e
}
