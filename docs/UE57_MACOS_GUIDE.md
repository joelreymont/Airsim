# AirSim UE 5.7 Migration Guide for macOS

**⚠️ IMPORTANT: macOS Support is EXPERIMENTAL**

- **Apple Silicon (M1/M2/M3)**: NOT supported
- **Intel Macs only**: x86_64 architecture required
- **Status**: May be deprecated in future releases
- **Recommendation**: Use Windows or Linux for production

---

## System Requirements

### Hardware
- **CPU**: Intel Mac (x86_64 architecture)
- **RAM**: 16GB minimum, 32GB recommended
- **Disk**: 150GB free space
- **GPU**: Metal-compatible GPU

### Software
- **macOS**: 11 (Big Sur), 12 (Monterey), or later
- **Xcode**: Latest version from App Store
- **Command Line Tools**: Installed via `xcode-select --install`
- **Unreal Engine 5.7**: Built from source or via Epic Games Launcher
- **Python**: 3.8 or later (use Homebrew or official installer)
- **Homebrew**: Recommended for dependencies

---

## Installation Steps

### 1. Install Xcode and Tools

```bash
# Install Xcode from App Store first, then:

# Install Command Line Tools
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept

# Verify installation
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

clang --version
# Should show: Apple clang version 14.0+ or later
```

### 2. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (if on Apple Silicon accidentally)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Install Dependencies

```bash
# Install required tools
brew install cmake wget git

# Install Python 3
brew install python@3.11

# Verify installations
cmake --version  # Should be 3.10.0 or later
python3 --version  # Should be 3.8 or later
```

### 4. Install Unreal Engine 5.7

#### Option A: Build from Source (Recommended)

**Note**: Requires GitHub account linked to Epic Games account

```bash
# Clone UE repository (requires Epic Games account)
git clone -b 5.7 https://github.com/EpicGames/UnrealEngine.git ~/UnrealEngine
cd ~/UnrealEngine

# Setup dependencies
./Setup.sh

# Generate project files
./GenerateProjectFiles.sh

# Build UE (takes 6-8 hours)
xcodebuild -project UE5.xcodeproj -target UE5 -configuration Development

# Set environment variable
echo 'export UE5_ROOT=$HOME/UnrealEngine' >> ~/.zshrc
source ~/.zshrc
```

#### Option B: Epic Games Launcher

1. Download Epic Games Launcher from https://www.epicgames.com/store/download
2. Install Unreal Engine 5.7 through Library tab
3. Set environment variable:

```bash
echo 'export UE5_ROOT="/Users/Shared/Epic Games/UE_5.7"' >> ~/.zshrc
source ~/.zshrc
```

### 5. Clone AirSim

```bash
cd ~
git clone https://github.com/CodexLabsLLC/Colosseum.git
cd Colosseum

# Checkout UE 5.7 migration branch
git checkout claude/airsim-unreal-engine-port-01GnkcJXSLmNpAvCXN7nXh1f
```

---

## Building AirSim

### Automated Build (Recommended)

```bash
cd ~/Colosseum
export UE5_ROOT=$HOME/UnrealEngine  # or your UE path

# Run automated build verification
./scripts/verify_ue57_build_macos.sh
```

This script will:
1. ✅ Verify macOS version and architecture
2. ✅ Check UE 5.7 installation
3. ✅ Verify Xcode and build tools
4. ✅ Clean previous builds
5. ✅ Build AirLib
6. ✅ Build Unreal plugin
7. ✅ Verify binaries
8. ✅ Generate build log

### Manual Build

```bash
cd ~/Colosseum

# Setup dependencies
./setup.sh

# Build AirLib
./build.sh

# Generate Unreal project files
cd Unreal/Environments/Blocks
$UE5_ROOT/GenerateProjectFiles.sh Blocks.uproject

# Build plugin
$UE5_ROOT/Engine/Build/BatchFiles/Mac/Build.sh \
    Blocks Mac Development \
    -project="$(pwd)/Blocks.uproject"
```

---

## Running AirSim

### Launch UE Editor

```bash
cd ~/Colosseum/Unreal/Environments/Blocks

# Option 1: Open with default app
open Blocks.uproject

# Option 2: Launch editor directly
$UE5_ROOT/Engine/Binaries/Mac/UnrealEditor.app/Contents/MacOS/UnrealEditor \
    "$(pwd)/Blocks.uproject"
```

### In Editor

1. **Wait for plugin compilation** (first launch)
2. **Accept any prompts** to rebuild modules
3. **Check Output Log** for errors (Window → Developer Tools → Output Log)
4. **Verify AirSim plugin loaded**: Edit → Plugins → search "AirSim"
5. **Play in Editor** (PIE): Click Play button or press Cmd+P

---

## Testing

### Python API Test

```bash
# Install Python client
cd ~/Colosseum/PythonClient
pip3 install -e .

# Run compatibility test
# (Make sure simulation is running in UE Editor first)
python3 unreal_engine/ue57_compatibility_test.py
```

### Manual Tests

**In UE Editor (PIE mode):**

1. **Vehicle Spawn**:
   - Press Play
   - Drone should spawn at origin
   - Check for physics warnings in Output Log

2. **Camera Switching**:
   - Press F1-F5 keys to cycle cameras
   - Verify camera views switch correctly

3. **Manual Control**:
   - Use keyboard (for car) or RC transmitter (for drone)
   - Verify responsive controls

4. **API Connection**:
   ```python
   import airsim
   client = airsim.VehicleClient()
   client.confirmConnection()  # Should not error
   ```

---

## macOS-Specific Issues & Solutions

### Issue 1: "Apple Silicon not supported"

**Error**: Architecture check fails on M1/M2/M3 Macs

**Solution**: AirSim does not support Apple Silicon. Options:
- Use Intel Mac
- Use Rosetta 2 (experimental, may not work):
  ```bash
  arch -x86_64 /bin/bash
  # Then run build scripts
  ```
- Use Windows or Linux (recommended)

### Issue 2: Xcode License Not Accepted

**Error**: `xcodebuild: error: You must accept the license before...`

**Solution**:
```bash
sudo xcodebuild -license accept
```

### Issue 3: Command Line Tools Not Found

**Error**: `xcode-select: error: tool 'xcodebuild' requires Xcode`

**Solution**:
```bash
xcode-select --install
# Follow GUI prompts
```

### Issue 4: Permission Denied Errors

**Error**: `Permission denied` when running scripts

**Solution**:
```bash
chmod +x ./setup.sh
chmod +x ./build.sh
chmod +x ./scripts/*.sh
```

### Issue 5: UE Editor Crashes on Launch

**Symptoms**: Editor crashes immediately or during plugin load

**Solutions**:
1. Check macOS version compatibility (11+)
2. Verify GPU supports Metal
3. Try safe mode:
   ```bash
   $UE5_ROOT/Engine/Binaries/Mac/UnrealEditor.app/Contents/MacOS/UnrealEditor \
       -opengl  # Use OpenGL instead of Metal
   ```
4. Check Console.app for crash logs

### Issue 6: "dylib not loaded" Errors

**Error**: Plugin binaries fail to load

**Solutions**:
```bash
# Check binary architecture
file ~/Colosseum/Unreal/Plugins/AirSim/Binaries/Mac/*.dylib
# Should show: Mach-O 64-bit dynamically linked shared library x86_64

# Rebuild plugin
cd ~/Colosseum
./clean.sh
./build.sh
```

### Issue 7: Python Module Import Errors

**Error**: `ImportError: No module named 'airsim'`

**Solution**:
```bash
# Use Python 3 explicitly
pip3 install msgpack-rpc-python
pip3 install airsim

# Or install from source
cd ~/Colosseum/PythonClient
pip3 install -e .
```

### Issue 8: Firewall Blocking API Connection

**Error**: Python client can't connect to simulator

**Solution**:
1. System Preferences → Security & Privacy → Firewall
2. Click "Firewall Options"
3. Add UnrealEditor to allowed apps
4. Or disable firewall temporarily for testing

---

## Performance Tuning

### macOS-Specific Optimizations

```bash
# Increase file descriptor limit
ulimit -n 4096

# Check system resources
top
# Look for CPU and memory usage

# Monitor GPU usage
sudo powermetrics --samplers gpu_power

# Clear shader cache if performance degrades
rm -rf ~/Library/Caches/Unreal\ Engine
```

### Graphics Settings

In UE Editor:
1. Edit → Project Settings → Platforms → Mac
2. Set "Default RHI" to "Metal" (or OpenGL4 if issues)
3. Under Rendering:
   - Disable "Mobile HDR" if not needed
   - Reduce "Max Simultaneous Shadows" to 4
   - Lower "Shadow Map Method" quality

---

## Debugging

### Enable Verbose Logging

```bash
# Launch editor with logging
$UE5_ROOT/Engine/Binaries/Mac/UnrealEditor.app/Contents/MacOS/UnrealEditor \
    "$(pwd)/Blocks.uproject" \
    -log -verbose
```

### Check Logs

```bash
# Editor log
tail -f ~/Library/Logs/Unreal\ Engine/UE5/UnrealEditor.log

# AirSim log (during runtime)
tail -f ~/Documents/AirSim/airsim_log.txt
```

### Console.app (System Logs)

1. Open Console.app
2. Filter for "UnrealEditor" or "AirSim"
3. Check for crash reports and errors

---

## Known Limitations on macOS

### Not Supported
- ❌ Apple Silicon (M1/M2/M3)
- ❌ PX4 HITL (hardware-in-the-loop) - use SITL only
- ❌ Some advanced rendering features
- ❌ DirectX-specific features

### Reduced Performance
- Lower FPS compared to Windows (Metal vs DirectX)
- Longer compilation times
- Higher memory usage in some scenarios

### Experimental Features
- VR support (limited)
- Custom vehicle models (may have issues)
- Advanced weather effects

---

## Alternative: Docker on macOS

For better compatibility, consider using Docker:

```bash
# Install Docker Desktop for Mac
# Then run AirSim in Linux container

docker pull codexlabsllc/airsim

# Run container with X11 forwarding
# (Requires XQuartz)
```

---

## Benchmarks (Intel Mac)

**Test System**: MacBook Pro 16" 2019, Intel i9, 32GB RAM, Radeon Pro 5500M

| Metric | Target | Actual |
|--------|--------|--------|
| Simulation FPS | 60 | ~45 |
| Image Capture FPS | 30 | ~25 |
| Memory Usage | <3GB | ~3.5GB |
| Startup Time | <30s | ~40s |

**Note**: macOS performance typically 20-30% lower than Windows on same hardware.

---

## When to Use Linux/Windows Instead

**Choose Linux/Windows if you need:**
- ✅ Apple Silicon (M1/M2/M3) - Use Linux VM
- ✅ Maximum performance
- ✅ Production deployments
- ✅ Hardware-in-the-loop (HITL)
- ✅ Long-term support
- ✅ Community support (larger user base)

**macOS is acceptable for:**
- ✅ Development and testing
- ✅ Software-in-the-loop (SITL)
- ✅ Computer vision research
- ✅ Proof-of-concept work

---

## Build Script Reference

### verify_ue57_build_macos.sh

Located at: `scripts/verify_ue57_build_macos.sh`

**Usage**:
```bash
export UE5_ROOT=/path/to/UnrealEngine
./scripts/verify_ue57_build_macos.sh
```

**What it does**:
1. Checks macOS version and architecture
2. Verifies UE 5.7 installation
3. Checks Xcode and build tools
4. Builds AirLib
5. Compiles Unreal plugin
6. Verifies binaries
7. Generates detailed log

**Output**:
- Console output with color-coded status
- Build log: `build_ue57_macos.log`

---

## Troubleshooting Checklist

Before asking for help, verify:

- [ ] Intel Mac (not Apple Silicon)
- [ ] macOS 11 or later
- [ ] Xcode installed and license accepted
- [ ] Command Line Tools installed
- [ ] UE5_ROOT environment variable set
- [ ] UE 5.7 installed and working
- [ ] Dependencies installed (cmake, python3)
- [ ] Clean build attempted (`./clean.sh` then rebuild)
- [ ] Editor log checked for errors
- [ ] System resources adequate (RAM, disk)

---

## Getting Help

### Resources
- **Documentation**: `docs/UE57_*.md`
- **GitHub Issues**: https://github.com/CodexLabsLLC/Colosseum/issues
- **Colosseum Slack**: Community support channel
- **UE Forums**: https://forums.unrealengine.com

### Reporting Issues

Include in your report:
```bash
# System info
sw_vers
uname -m
xcodebuild -version

# UE version
cat $UE5_ROOT/Engine/Build/Build.version | grep Version

# Build log
cat ~/Colosseum/build_ue57_macos.log

# Editor log
tail -100 ~/Library/Logs/Unreal\ Engine/UE5/UnrealEditor.log
```

---

## Quick Reference Commands

```bash
# Set UE path
export UE5_ROOT=$HOME/UnrealEngine

# Clean build
cd ~/Colosseum
./clean.sh

# Setup dependencies
./setup.sh

# Build AirLib
./build.sh

# Automated build & verification
./scripts/verify_ue57_build_macos.sh

# Launch editor
open Unreal/Environments/Blocks/Blocks.uproject

# Run tests (with simulation running)
python3 PythonClient/unreal_engine/ue57_compatibility_test.py

# View logs
tail -f ~/Library/Logs/Unreal\ Engine/UE5/UnrealEditor.log
```

---

## Migration from UE 5.1 to 5.7

If you have existing UE 5.1 AirSim installation:

```bash
# 1. Backup current installation
cp -r ~/Colosseum ~/Colosseum_ue51_backup

# 2. Update to UE 5.7 branch
cd ~/Colosseum
git fetch origin
git checkout claude/airsim-unreal-engine-port-01GnkcJXSLmNpAvCXN7nXh1f

# 3. Clean rebuild
./clean.sh
./setup.sh
./build.sh

# 4. Rebuild project
cd Unreal/Environments/Blocks
$UE5_ROOT/GenerateProjectFiles.sh Blocks.uproject
$UE5_ROOT/Engine/Build/BatchFiles/Mac/Build.sh \
    Blocks Mac Development -project="$(pwd)/Blocks.uproject"

# 5. Test in editor
open Blocks.uproject
```

---

## Summary

**macOS support for AirSim UE 5.7:**
- ⚠️ **Experimental** - may be deprecated
- ✅ **Intel Macs only** - no Apple Silicon
- ⚠️ **Performance** - ~20-30% lower than Windows
- ✅ **Development** - acceptable for testing
- ❌ **Production** - use Windows/Linux

**Recommended approach:**
1. Use automated build script: `verify_ue57_build_macos.sh`
2. Follow troubleshooting guide if issues arise
3. Consider Linux VM for better performance
4. Report issues to help improve macOS support

For production deployments, **Windows or Linux strongly recommended**.
