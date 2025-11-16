# AirSim UE 5.7 Compatibility Analysis

**Analysis Date**: 2025-11-16
**Source Version**: UE 5.1
**Target Version**: UE 5.7
**Status**: Pre-compilation analysis

## Executive Summary

AirSim (Colosseum) is already using modern UE5 APIs (Chaos physics, CineCameraActor), which provides a strong foundation for UE 5.7 compatibility. The migration primarily requires verification and minor adjustments rather than major refactoring.

## Critical Files Analyzed

### Vehicle Systems

#### Car Vehicle (`Unreal/Plugins/AirSim/Source/Vehicles/Car/`)

**CarPawn.h/cpp**
- **Base Class**: `AWheeledVehiclePawn` (UE5 vehicle pawn)
- **Movement Component**: `UChaosWheeledVehicleMovementComponent`
- **Wheel Classes**: `UChaosVehicleWheel` (front/rear)
- **Risk Level**: Medium
- **Compatibility Notes**:
  - Already using UE5 Chaos physics system
  - Wheel setup API may have minor changes
  - Check for deprecated `WheelSetups` properties
  - Verify steering, suspension, and brake configurations

**Action Items**:
1. Compile and check for deprecation warnings in ChaosVehicles API
2. Test wheel physics parameter compatibility
3. Verify `UChaosWheeledVehicleMovementComponent` properties:
   - `WheelSetups` array initialization
   - Steering configuration
   - Brake/handbrake settings
   - Engine/transmission parameters

**Potential API Changes** (5.1 → 5.7):
```cpp
// May need updates if API changed:
movement->WheelSetups[0].WheelClass = UCarWheelFront::StaticClass();
movement->WheelSetups[0].BoneName = FName("WheelFL");
movement->WheelSetups[0].AdditionalOffset = FVector(0.f, -8.f, 0.f);
```

#### Multirotor Vehicle (`Unreal/Plugins/AirSim/Source/Vehicles/Multirotor/`)

**FlyingPawn.h/cpp**
- **Base Class**: `APawn` (core Unreal class - very stable)
- **Components**: `URotatingMovementComponent`
- **Risk Level**: Low
- **Compatibility Notes**:
  - Uses fundamental Unreal APIs
  - Minimal physics dependencies
  - Component-based architecture should be stable

**Action Items**:
1. Verify component attachment APIs
2. Test rotor animation/movement
3. Check physics collision handling

### Camera and Rendering Systems

#### PIPCamera (`Unreal/Plugins/AirSim/Source/PIPCamera.h/cpp`)

**Key Dependencies**:
- **Base Class**: `ACineCameraActor` (Cinematic camera)
- **Capture Component**: `USceneCaptureComponent2D`
- **Materials**: Dynamic material instances
- **Risk Level**: Medium-High
- **Compatibility Notes**:
  - Rendering pipeline significantly enhanced in UE 5.7
  - Substrate material system introduced
  - Scene capture may have new optimizations
  - Pixel format handling may have changed

**Critical Areas**:
1. **Scene Capture**:
   ```cpp
   USceneCaptureComponent2D* capture_component
   ```
   - Verify render target configuration
   - Check texture format compatibility
   - Test capture to memory/disk

2. **Cinematic Camera**:
   ```cpp
   ACineCameraActor base class
   UCineCameraComponent
   ```
   - Lens settings API
   - Filmback settings
   - Focus controls
   - Aperture settings

3. **Material System**:
   - Dynamic material instances
   - Material parameter collections
   - Post-processing materials

**Action Items**:
1. Test all image capture types (RGB, Depth, Segmentation, etc.)
2. Verify material parameter setting/getting
3. Check CineCameraComponent API for changes
4. Test render target pixel formats
5. Evaluate Substrate material integration (optional enhancement)

#### UnrealImageCapture (`Unreal/Plugins/AirSim/Source/UnrealImageCapture.h/cpp`)

**Risk Level**: Medium-High
**Dependencies**:
- Scene capture pipeline
- Texture compression
- Screenshot system
- Multiple image type rendering

**Action Items**:
1. Test `getImages()` for all ImageType variants
2. Verify screenshot capture functionality
3. Check compressed PNG generation
4. Test multi-camera capture performance

### Core Game Framework

#### AirSimGameMode (`Unreal/Plugins/AirSim/Source/AirSimGameMode.h/cpp`)

- **Base Class**: `AGameModeBase`
- **Risk Level**: Low
- **Notes**: Fundamental game mode should be stable

#### World Simulation API (`Unreal/Plugins/AirSim/Source/WorldSimApi.h/cpp`)

- **Risk Level**: Medium
- **Key Functions**:
  - Level loading/streaming
  - Object spawning
  - Pause/resume simulation
  - Weather system
  - Time of day

**Action Items**:
1. Test level loading APIs
2. Verify actor spawning
3. Test pause/resume functionality
4. Verify weather system integration

## Module Dependencies (AirSim.Build.cs)

**Current Modules** (marked in Build.cs):
```csharp
PublicDependencyModuleNames.AddRange(new string[] {
    "Core", "CoreUObject", "Engine", "InputCore",
    "ImageWrapper", "RenderCore", "RHI", "PhysicsCore",
    "AssetRegistry", "ChaosVehicles", "Landscape",
    "CinematicCamera"
});
```

**Verification Status**:
- ✅ Core, CoreUObject, Engine - Stable fundamental modules
- ✅ InputCore - Stable (Linux SDL3 change at OS level, not module level)
- ⚠️ ImageWrapper - Verify texture compression APIs
- ⚠️ RenderCore, RHI - Rendering pipeline changes, verify compatibility
- ⚠️ PhysicsCore - Minor Chaos physics updates expected
- ⚠️ ChaosVehicles - Vehicle API may have refinements
- ✅ Landscape - Stable
- ✅ CinematicCamera - Stable (enhanced features in 5.7)

**Private Modules**:
```csharp
PrivateDependencyModuleNames.AddRange(new string[] {
    "UMG", "Slate", "SlateCore", "RenderCore"
});
```

**Verification Status**:
- ✅ UMG, Slate, SlateCore - UI modules, stable
- ⚠️ RenderCore - Same as above

## Platform-Specific Considerations

### Windows
- **DirectX 12**: Primary rendering API
- **DirectInput**: Joystick support (dinput8.lib, dxguid.lib)
- **Risk**: Low
- **Notes**: Windows platform most stable for UE updates

### Linux
- **SDL3 Transition**: Major change from SDL2
- **Risk**: Medium-High
- **Critical Areas**:
  1. Input handling (keyboard, mouse, joystick)
  2. Window management
  3. OpenGL/Vulkan context creation

**Action Items**:
1. Verify UE 5.7 on Linux uses SDL3 correctly
2. Test all input methods
3. Verify Vulkan rendering
4. Test on Ubuntu 18.04 and 20.04

**Build.cs Notes**:
```cpp
if (Target.Platform == UnrealTargetPlatform.Linux)
{
    // UE 5.7 Linux: Transitioned from SDL2 to SDL3
    // Verify input/window management compatibility
}
```

### macOS
- **Risk**: High
- **Status**: Experimental, may be deprecated
- **Notes**: Apple Silicon (M1/M2) not supported
- **Recommendation**: Consider deprecating or marking as unsupported

## Known UE 5.7 Features and Impacts

### 1. Substrate Material System
- **Status**: Production-ready in 5.7
- **Impact**: Optional enhancement opportunity
- **Risk**: Low (backward compatible)
- **Recommendation**:
  - Phase 1: Keep existing materials
  - Phase 2: Evaluate Substrate for enhanced rendering quality

### 2. Procedural Content Generation (PCG)
- **Impact**: Not applicable to AirSim core
- **Note**: Users can leverage for custom environments

### 3. Enhanced Rendering Pipeline
- **Impact**: Medium
- **Areas**:
  - Improved performance for large worlds
  - Better multi-threaded rendering
  - Enhanced shadow quality
- **Action**: Performance benchmark against UE 5.1

### 4. Updated Animation System
- **Impact**: Low
- **Note**: AirSim uses minimal animation (rotor rotation)

## Compilation Verification Checklist

### Phase 1: Initial Compilation
- [ ] Open project in UE 5.7 Editor
- [ ] Allow module rebuild when prompted
- [ ] Document all compilation errors
- [ ] Document all deprecation warnings
- [ ] Create error categorization by module

### Phase 2: Error Resolution
- [ ] Fix ChaosVehicles API issues
- [ ] Fix rendering API issues
- [ ] Fix camera/scene capture issues
- [ ] Update deprecated function calls
- [ ] Resolve module dependency issues

### Phase 3: Blueprint Migration
- [ ] Open all vehicle blueprints
- [ ] Fix any broken node connections
- [ ] Update deprecated blueprint nodes
- [ ] Recompile all blueprints
- [ ] Test blueprint functionality

## Runtime Verification Checklist

### Vehicle Testing
- [ ] Multirotor spawning and physics
- [ ] Multirotor manual control
- [ ] Multirotor API control
- [ ] Car spawning and physics
- [ ] Car manual control (keyboard)
- [ ] Car API control
- [ ] Computer vision mode

### Camera Testing
- [ ] RGB image capture
- [ ] Depth planar capture
- [ ] Depth perspective capture
- [ ] Segmentation capture
- [ ] Surface normals capture
- [ ] Optical flow capture (if implemented)
- [ ] Infrared capture (if implemented)
- [ ] Multi-camera capture
- [ ] Cinematic camera controls

### Sensor Testing
- [ ] Lidar sensor
- [ ] Distance sensor
- [ ] IMU data
- [ ] GPS data
- [ ] Barometer data

### API Testing
- [ ] Python client connection
- [ ] C++ client connection
- [ ] MavLink integration (PX4/ArduPilot)
- [ ] All API endpoints functional
- [ ] Performance acceptable

### World API Testing
- [ ] Level loading
- [ ] Object spawning
- [ ] Pause/resume
- [ ] Weather system
- [ ] Time of day
- [ ] Recording functionality

## Performance Benchmarks

Compare against UE 5.1 baseline:

### Metrics to Track
1. **Simulation FPS**: Target within ±5% of baseline
2. **Memory Usage**: Target within ±10% of baseline
3. **Startup Time**: Target within ±10% of baseline
4. **Image Capture Latency**: Target within ±5% of baseline
5. **API Response Time**: Target within ±5% of baseline

### Test Scenarios
1. Single vehicle (multirotor) hovering
2. Single vehicle (car) driving
3. Multi-vehicle (4 vehicles)
4. High-resolution image capture (4K)
5. Multi-camera capture (5 cameras)
6. Lidar active scanning

## Risk Assessment Summary

| Component | Risk Level | Priority | Mitigation |
|-----------|------------|----------|------------|
| Car Physics | Medium | High | Early testing, wheel config review |
| Multirotor Physics | Low | Medium | Standard testing |
| Camera System | Medium-High | Critical | Comprehensive image capture tests |
| Rendering Pipeline | Medium | High | All image types validation |
| Linux Platform | Medium-High | High | SDL3 compatibility verification |
| macOS Platform | High | Low | Consider deprecation |
| API Layer | Low | Medium | Automated test suite |
| World Simulation | Medium | Medium | Functional testing |

## Recommended Approach

### Incremental Migration Strategy

**Option A: Direct 5.1 → 5.7** (Current Plan)
- Pros: Single migration effort
- Cons: Harder to isolate issues, larger testing scope
- Timeline: 8-12 weeks

**Option B: Staged Migration** (Recommended Alternative)
- 5.1 → 5.3 (2-3 weeks)
- 5.3 → 5.5 (2-3 weeks)
- 5.5 → 5.7 (2-3 weeks)
- Pros: Easier debugging, incremental validation, community feedback
- Cons: More releases to manage
- Timeline: 6-9 weeks + release overhead

### Immediate Next Steps

1. **Compile Against UE 5.7** (Requires UE 5.7 installation)
   - Install UE 5.7 from Epic Games Launcher (Windows) or source (Linux)
   - Open Blocks.uproject
   - Document all errors and warnings

2. **Address Compilation Errors**
   - Prioritize by module: ChaosVehicles → Rendering → Misc
   - Fix deprecated APIs
   - Update function signatures

3. **Runtime Testing**
   - Run compatibility test script
   - Execute manual test scenarios
   - Compare performance benchmarks

4. **Documentation**
   - Update API documentation for any behavior changes
   - Create upgrade notes for users
   - Document known issues

## Code Areas Requiring Manual Verification

### High Priority

**File**: `Vehicles/Car/CarPawn.cpp:88-120`
```cpp
void ACarPawn::setupVehicleMovementComponent()
{
    UChaosWheeledVehicleMovementComponent* movement = ...
    movement->WheelSetups.SetNum(4);
    // Verify WheelSetups API compatibility
}
```

**File**: `PIPCamera.cpp` (Scene capture setup)
```cpp
// Verify USceneCaptureComponent2D configuration
// Check render target creation
// Validate material assignments
```

**File**: `UnrealImageCapture.cpp` (Image capture)
```cpp
// Verify all ImageType capture paths
// Check pixel format conversions
// Validate compression algorithms
```

### Medium Priority

**File**: `WorldSimApi.cpp` (World manipulation)
```cpp
// Verify level streaming APIs
// Check actor spawning
// Validate pause/resume
```

**File**: `AirSimGameMode.cpp` (Game mode)
```cpp
// Verify game mode initialization
// Check player controller setup
```

### Low Priority

**File**: `NedTransform.cpp` (Coordinate transforms)
```cpp
// Mathematical transforms - should be stable
// Verify if using any UE geometry APIs
```

## Expected Compilation Warnings

Based on UE5 progression, expect warnings for:

1. **TObjectPtr Soft Deprecations**
   - UE5 prefers TObjectPtr<> for object references
   - May see performance hints, not errors

2. **Metadata Specifiers**
   - Some UPROPERTY metadata may have deprecations

3. **Include Header Changes**
   - Some headers reorganized between versions
   - Usually auto-fixed by UE5 tooling

4. **Experimental API Usage**
   - Features that were experimental in 5.1 may be stable in 5.7

## Success Criteria

Migration is successful when:

- ✅ All code compiles without errors
- ✅ Zero critical warnings (deprecations acceptable)
- ✅ All vehicle types functional
- ✅ All camera/image capture modes working
- ✅ All sensors providing correct data
- ✅ API connectivity working (Python/C++)
- ✅ Performance within acceptable range (±10%)
- ✅ No visual regression in rendering quality
- ✅ PX4/ArduPilot integration functional
- ✅ Documentation updated
- ✅ Test suite passing

## Rollback Plan

If critical issues found:

1. Document specific blocking issues
2. Revert to UE 5.1 (use git)
3. Consider staged migration approach
4. Engage Unreal community for support
5. File issues with Epic if engine bugs found

## Conclusion

AirSim's codebase is well-positioned for UE 5.7 migration due to:
- Already using modern UE5 APIs (Chaos physics)
- Clean architecture with good separation of concerns
- Comprehensive test coverage available
- Active development and community support

Primary risk areas are rendering pipeline changes and Linux SDL3 transition, both of which can be addressed with systematic testing and verification.

**Recommendation**: Proceed with migration, prioritizing compilation fixes, then camera/rendering validation, then comprehensive testing.
