# Unreal Engine 5.7 Migration Guide

Comprehensive guide for migrating AirSim from UE 5.1 to UE 5.7

## Overview

This guide covers the migration of AirSim from Unreal Engine 5.1 to Unreal Engine 5.7, spanning 6 major engine releases (5.2, 5.3, 5.4, 5.5, 5.6, 5.7).

## Prerequisites

### Windows
- Visual Studio 2022 with C++, Python, and C# workloads
- Unreal Engine 5.7 (install via Epic Games Launcher)
- Windows 10 or later

### Linux
- Ubuntu 18.04 or 20.04 (22.04 not supported)
- Unreal Engine 5.7 built from source
- Clang/GCC compatible compiler
- Note: UE 5.7 uses SDL3 instead of SDL2

### macOS (Experimental)
- macOS Monterey (12) or later
- Non-Apple Silicon (M1/M2 not supported)
- Note: macOS support may be deprecated in future releases

## Migration Steps

### Step 1: Backup Current Installation
```bash
# Create backup branch
git checkout -b backup-ue51

# Return to main development branch
git checkout main
```

### Step 2: Update Project Files

#### Update .uproject Files
For Blocks environment:
```json
{
  "EngineAssociation": "5.7",
  ...
}
```

For custom environments, update all .uproject files similarly.

#### Update Plugin Descriptor
File: `Unreal/Plugins/AirSim/AirSim.uplugin`
- Plugin should remain compatible with UE 5.7
- Verify ChaosVehiclesPlugin dependency

### Step 3: Rebuild AirLib

#### Windows
```cmd
cd AirSim
clean_rebuild.bat
```

#### Linux
```bash
cd AirSim
./clean_rebuild.sh
```

### Step 4: Update Unreal Engine Installation

#### Windows
Install UE 5.7 through Epic Games Launcher.

#### Linux
Build UE 5.7 from source:
1. Clone Epic Games UnrealEngine repository
2. Follow Linux build instructions
3. Note SDL3 requirements for input system

### Step 5: Update Custom Environments

For each custom environment:
1. Update EngineAssociation in .uproject to "5.7"
2. Delete Plugins/AirSim folder
3. Copy fresh Plugins folder from AirSim/Unreal/Plugins
4. Run clean and regenerate scripts
5. Open in UE 5.7 Editor

### Step 6: Verify Build

#### Generate Project Files (Windows)
```cmd
cd Unreal/Environments/Blocks
GenerateProjectFiles.bat
```

#### Open in UE 5.7 Editor
1. Open .uproject file in UE 5.7
2. Allow module rebuild when prompted
3. Check for compilation errors
4. Review deprecation warnings

## Key Changes in UE 5.7

### Substrate Material System
- New production-ready material authoring framework
- Existing materials continue to work
- Consider migrating to Substrate for improved quality

### Linux SDL3 Transition
- SDL2 replaced with SDL3
- Input and window management updated
- Custom input code may require changes

### ChaosVehicles Updates
- Verify vehicle physics parameters
- Test multirotor and car controls
- Check suspension and wheel configurations

### Rendering Pipeline
- Enhanced performance optimizations
- Improved large-scale world handling
- Updated image capture may benefit from new features

## Testing Procedure

### Basic Functionality Test
1. Launch UE 5.7 with Blocks environment
2. Start simulation
3. Verify vehicle spawns correctly
4. Test manual controls

### API Connectivity Test
```python
python PythonClient/unreal_engine/ue57_compatibility_test.py
```

### Comprehensive Test Suite
1. Multirotor flight and controls
2. Car driving and physics
3. Camera capture all types
4. Lidar sensor functionality
5. Weather system
6. Recording features
7. Custom environment loading

## Troubleshooting

### Compilation Errors

#### Module Not Found
Verify all module names in AirSim.Build.cs match UE 5.7 module names.

#### ChaosVehicles Issues
Check ChaosVehicles plugin is enabled in .uproject and .uplugin files.

#### Linux SDL3 Errors
Ensure SDL3 development libraries are installed and accessible.

### Runtime Issues

#### Vehicle Physics Problems
1. Check vehicle blueprints for deprecated components
2. Verify ChaosWheeledVehicleMovementComponent configuration
3. Test with default vehicle parameters

#### Image Capture Failures
1. Verify camera settings in blueprints
2. Test with simple RGB capture first
3. Check render target configurations

#### API Connection Failures
1. Verify settings.json configuration
2. Check RPC port availability
3. Test with simple connection script

## Platform-Specific Notes

### Windows
- Ensure DirectX 12 compatible GPU
- Visual Studio 2022 required
- Windows SDK 10.0.19041 or later

### Linux
- SDL3 transition is most significant change
- Build UE 5.7 with compatible compiler
- Vulkan driver compatibility critical
- Ubuntu 22.04 not supported

### macOS
- Experimental support only
- May be deprecated in future
- Apple Silicon not supported

## Performance Validation

### Baseline Metrics (UE 5.1)
Document current performance:
- Average FPS in simulation
- Memory usage
- Startup time
- API response latency

### UE 5.7 Metrics
Compare after migration:
- FPS should be similar or improved
- Memory usage within 10% variance
- Startup time acceptable
- API latency unchanged

## Rollback Procedure

If migration fails:
```bash
# Return to backup branch
git checkout backup-ue51

# Reinstall UE 5.1
# Rebuild AirLib
clean_rebuild.bat  # or .sh
```

## Post-Migration Tasks

### Documentation Updates
- Update all references from UE 5.1 to UE 5.7
- Note any behavior changes
- Document new features utilized

### CI/CD Updates
- Update GitHub Actions workflows
- Verify builds on all platforms
- Update test expectations

### Communication
- Notify users of upgrade
- Provide migration timeline
- Share known issues

## Version Compatibility Matrix

| AirSim Version | UE Version | Status |
|----------------|------------|--------|
| 1.8.1 (legacy) | 4.27 | Branch: ue4.27 |
| 1.8.1 (current)| 5.1  | Legacy |
| 1.8.1+ (new)   | 5.7  | Current |

## Additional Resources

### Unreal Engine Documentation
- [UE 5.7 Release Notes](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5.7-release-notes)
- [UE 5 Migration Guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-migration-guide)
- [Substrate Materials](https://dev.epicgames.com/documentation/en-us/unreal-engine/substrate-material-system)

### AirSim Resources
- [Build Windows](docs/pages/colosseum/build_windows.md)
- [Build Linux](docs/pages/colosseum/build_linux.md)
- [Custom Environments](docs/pages/colosseum/unreal_custenv.md)

### Community Support
- Colosseum Slack Channel
- GitHub Issues
- Discussion Forums

## Known Limitations

1. Ubuntu 22.04 not supported due to Vulkan issues
2. macOS support experimental and may be deprecated
3. Apple Silicon (M1/M2) not supported
4. Some third-party plugins may need updates

## Migration Checklist

- [ ] Backup current installation
- [ ] Install UE 5.7
- [ ] Update .uproject files
- [ ] Rebuild AirLib
- [ ] Regenerate project files
- [ ] Open in UE 5.7 Editor
- [ ] Resolve compilation errors
- [ ] Test basic functionality
- [ ] Run API connectivity tests
- [ ] Test all vehicle types
- [ ] Verify camera capture
- [ ] Test sensor systems
- [ ] Performance validation
- [ ] Update documentation
- [ ] Update CI/CD
- [ ] Notify users

## Success Criteria

Migration is complete when:
- All code compiles without errors
- All tests pass
- Functional parity with UE 5.1 achieved
- Performance within acceptable range
- Documentation updated
- CI/CD operational

## Support

For assistance:
1. Review this guide thoroughly
2. Check GitHub issues for similar problems
3. Join Colosseum Slack community
4. Create new issue with detailed information
