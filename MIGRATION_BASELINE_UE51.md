# AirSim UE 5.1 Baseline Documentation

**Date**: 2025-11-16
**Current Version**: Unreal Engine 5.1
**Target Version**: Unreal Engine 5.7
**AirSim Plugin Version**: 1.8.1

## Current Configuration

### Engine Association
- **Blocks Environment**: UE 5.1 (`Unreal/Environments/Blocks/Blocks.uproject`)
- **Legacy Support**: UE 4.27 available on branch `ue4.27`

### Core Dependencies

#### Plugin Dependencies (AirSim.uplugin)
- ChaosVehiclesPlugin (enabled) - UE5 physics system for vehicles

#### Module Dependencies (AirSim.Build.cs)
**Public Modules**:
- Core, CoreUObject, Engine, InputCore
- ImageWrapper, RenderCore, RHI
- PhysicsCore, AssetRegistry
- ChaosVehicles (UE5 vehicle physics)
- Landscape, CinematicCamera

**Private Modules**:
- UMG, Slate, SlateCore, RenderCore

#### External Libraries
- **rpclib**: RPC communication for API
- **MavLinkCom**: MAVLink protocol for drone control
- **Eigen 3.4.0**: Linear algebra library

### Platform Support

#### Windows
- Visual Studio 2022 with VC++, Python, C#
- Windows 10 SDK 10.0.19041
- DirectInput for joystick support (dinput8.lib, dxguid.lib)

#### Linux
- Ubuntu 18.04 / 20.04 (22.04 NOT supported - Vulkan issues)
- Clang 8 for UE 4.27 compatibility
- Source-built Unreal Engine required
- SDL2 for input/window management

#### macOS (Experimental)
- Non-M1 Macs only
- macOS Monterey (12) or macOS 11
- Experimental support, may be deprecated

### Vehicle Systems

#### 1. Multirotor
- APawn-derived flying vehicle (FlyingPawn.cpp/h)
- MultirotorPawnSimApi for API bridge
- SimModeWorldMultiRotor for world simulation
- PX4/ArduPilot SITL/HITL support

#### 2. Car
- AWheeledVehiclePawn base class (CarPawn.cpp/h)
- ChaosWheeledVehicleMovementComponent (UE5 physics)
- CarWheelFront/CarWheelRear wheel physics components

#### 3. Computer Vision
- ComputerVisionPawn (camera-only mode)
- SimModeComputerVision (no physics simulation)

### Rendering & Image Capture

#### Image Capture Types
- RGB
- Depth (Planar/Perspective)
- Segmentation
- Surface Normals
- Optical Flow
- Infrared

#### Camera System
- PIPCamera: Picture-in-Picture camera system
- UnrealImageCapture: Multi-format image capture
- Post-processing materials in Content/HUDAssets/

### Sensor Systems
- UnrealLidarSensor: Lidar implementation
- UnrealDistanceSensor: Distance/proximity sensor
- UnrealSensorFactory: Factory pattern for sensor creation

### API Layer (WorldSimApi)
- World APIs: Level loading, object spawning, pause/resume
- Vehicle APIs: Movement, control, state queries
- Camera APIs: Image capture, controls, FOV settings
- Sensor APIs: Lidar, distance sensors
- Weather APIs: Weather parameters, time of day
- Recording APIs: Start/stop recording
- Debug/Visualization: Plot points, lines, transforms

### Build Configuration
- Compile Mode: HeaderOnlyWithRpc
- PCH Usage: UseExplicitOrSharedPCHs
- Exceptions: Enabled (bEnableExceptions = true)
- Platform: Win64, Linux, Mac

### Known Functionality (UE 5.1)
- ✅ Manual RC control (drones)
- ✅ Keyboard control (cars)
- ✅ Programmatic API control (Python/C++)
- ✅ Multi-camera setups
- ✅ Sensor data collection
- ✅ Weather simulation
- ✅ Recording/playback
- ✅ Custom environment support
- ✅ PX4/ArduPilot integration

## Migration Goals

### Target: Unreal Engine 5.7

#### New Features to Evaluate
1. **Substrate Material System** (Production-ready in 5.7)
   - Modular material authoring
   - Layered and blended materials
   - Physical accuracy improvements

2. **PCG (Procedural Content Generation)** (Production-ready in 5.7)
   - Graph-based procedural generation
   - Enhanced vegetation systems

3. **Enhanced MetaHuman Integration**
   - Potential for character-based simulations

4. **Performance Improvements**
   - Large-scale open world optimizations
   - Rendering pipeline enhancements

#### Breaking Changes to Address
1. **Linux SDL3 Migration** (SDL2 → SDL3)
2. **API Changes** across 6 major versions (5.2, 5.3, 5.4, 5.5, 5.6, 5.7)
3. **ChaosVehicles API Updates**
4. **Rendering Pipeline Changes**
5. **Deprecated APIs Removal**

## Success Criteria
- ✅ All code compiles on UE5.7
- ✅ Functional parity with UE5.1
- ✅ No performance regression (±5%)
- ✅ All platforms supported (Windows, Linux)
- ✅ PX4/ArduPilot integration functional
- ✅ All image capture modes working
- ✅ Documentation updated

## References
- Current README: `/home/user/Airsim/README.md`
- Plugin Descriptor: `/home/user/Airsim/Unreal/Plugins/AirSim/AirSim.uplugin`
- Build Configuration: `/home/user/Airsim/Unreal/Plugins/AirSim/Source/AirSim.Build.cs`
- Project File: `/home/user/Airsim/Unreal/Environments/Blocks/Blocks.uproject`
