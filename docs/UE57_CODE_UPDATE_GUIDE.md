# UE 5.7 Code Update Guide

This guide provides specific code patterns and updates likely needed when compiling AirSim against UE 5.7.

## Common API Updates

### 1. ChaosVehicles API Changes

#### Wheel Setup (if API changed)

**Current Code** (`CarPawn.cpp`):
```cpp
void ACarPawn::setupVehicleMovementComponent()
{
    UChaosWheeledVehicleMovementComponent* movement = CastChecked<UChaosWheeledVehicleMovementComponent>(getVehicleMovementComponent());
    movement->WheelSetups.SetNum(4);

    movement->WheelSetups[0].WheelClass = UCarWheelFront::StaticClass();
    movement->WheelSetups[0].BoneName = FName("WheelFL");
    movement->WheelSetups[0].AdditionalOffset = FVector(0.f, -8.f, 0.f);
}
```

**If Deprecated**: Check UE 5.7 documentation for new wheel configuration API. Possible changes:
- `WheelSetups` might be replaced with a new array type
- Configuration may move to data assets
- Wheel class specification method may change

**Action**: Compile and check deprecation messages for guidance.

---

### 2. Scene Capture Component

#### Current Usage
```cpp
USceneCaptureComponent2D* capture_component;
```

**Potential Changes in UE 5.7**:
- Render target format specifications
- Capture source enumerations
- Post-processing settings structure

**Verification Steps**:
1. Check `USceneCaptureComponent2D` API documentation
2. Verify `TextureRenderTarget2D` creation
3. Test `CaptureSource` enum values
4. Validate post-processing material application

**Example Test**:
```cpp
// Verify scene capture still works
USceneCaptureComponent2D* capture = CreateDefaultSubobject<USceneCaptureComponent2D>(TEXT("SceneCapture"));
capture->CaptureSource = SCS_FinalColorLDR; // Verify enum still exists
```

---

### 3. Cinematic Camera Component

#### Current Usage (`PIPCamera.h`)
```cpp
class APIPCamera : public ACineCameraActor
{
    // Uses UCineCameraComponent
}
```

**Likely Stable**: CineCameraComponent received enhancements in UE 5.7 but should maintain backward compatibility.

**New Features to Consider**:
- Enhanced DOF controls
- Improved focus tracking
- New lens presets

**Verification**:
```cpp
// Test existing camera API
UCineCameraComponent* cine_comp = GetCineCameraComponent();
float focal_length = cine_comp->CurrentFocalLength;
float aperture = cine_comp->CurrentAperture;
```

---

### 4. Material Instance Dynamics

#### Current Usage
```cpp
UMaterialInstanceDynamic* material_instance;
material_instance->SetScalarParameterValue(FName("ParameterName"), value);
```

**With Substrate Materials** (Optional):
- Existing materials continue to work
- New material features available
- Enhanced layering capabilities

**No Changes Required**: Unless migrating to Substrate.

---

## Platform-Specific Updates

### Linux SDL3 Transition

**Impact**: Engine-level change, not plugin code
**Location**: Unreal Engine input system

**Verification**:
1. Test keyboard input in editor
2. Test joystick/gamepad input
3. Verify window management

**No Code Changes Expected** in AirSim plugin - UE handles SDL3 internally.

---

### Windows Platform

**Likely No Changes**: Windows most stable platform for UE updates.

**Verify**:
- DirectX 12 rendering
- DirectInput joystick support still works
- No library changes needed

---

## Deprecation Handling

### Common Deprecation Pattern

If you see deprecation warnings like:
```
warning: 'OldFunctionName' is deprecated: Use NewFunctionName instead
```

**Steps**:
1. Note the suggested replacement
2. Search codebase for all occurrences
3. Replace systematically
4. Test functionality after replacement

### Likely Deprecations

Based on UE5 progression:

1. **Raw Pointers → TObjectPtr**
   ```cpp
   // Old (may generate soft warnings)
   AActor* MyActor;

   // New (preferred in UE5)
   TObjectPtr<AActor> MyActor;
   ```
   **Note**: This is optional optimization, not required

2. **Include Path Changes**
   ```cpp
   // If you see missing header errors, check for reorganized includes
   // UE 5.7 may have consolidated some headers
   ```

---

## Compilation Error Resolution

### Error Pattern 1: Unknown Type

```
error: unknown type name 'UChaosWheeledVehicleMovementComponent'
```

**Solution**:
1. Check if header file location changed
2. Verify module dependency in Build.cs
3. Check class was not renamed

```cpp
// Add missing include:
#include "ChaosWheeledVehicleMovementComponent.h"
```

### Error Pattern 2: Function Not Found

```
error: no member named 'OldFunction' in 'UClassName'
```

**Solution**:
1. Check UE 5.7 API documentation for class
2. Find replacement function
3. Update all call sites

### Error Pattern 3: Module Not Found

```
error: Module 'ModuleName' not found
```

**Solution**:
1. Check if module was renamed in UE 5.7
2. Update `AirSim.Build.cs` module dependencies
3. Verify module still exists in engine

---

## Testing Patterns

### After Each Fix

```cpp
// Add logging to verify functionality
UE_LOG(LogAirSim, Log, TEXT("Component initialized successfully"));
```

### Verify Vehicle Physics

```cpp
void TestVehiclePhysics()
{
    UChaosWheeledVehicleMovementComponent* movement = GetVehicleMovementComponent();
    check(movement != nullptr);
    check(movement->WheelSetups.Num() == 4); // Or whatever new API confirms wheels
    UE_LOG(LogAirSim, Log, TEXT("Vehicle physics OK"));
}
```

### Verify Camera Capture

```cpp
void TestCameraCapture()
{
    APIPCamera* camera = GetCamera("front_center");
    check(camera != nullptr);

    // Test capture
    TArray<FColor> pixels;
    camera->CaptureImage(pixels);
    check(pixels.Num() > 0);
    UE_LOG(LogAirSim, Log, TEXT("Camera capture OK: %d pixels"), pixels.Num());
}
```

---

## Performance Optimization

### UE 5.7 New Features to Leverage

1. **Nanite** (if applicable to vehicle models)
   - Automatic LOD
   - Reduced draw calls
   - Better performance for detailed meshes

2. **Lumen** (Global Illumination)
   - Better lighting quality
   - May affect camera capture appearance
   - Can be disabled for consistency

3. **Enhanced Multi-threading**
   - Physics may run on different thread
   - Verify thread-safe access to physics data

---

## Blueprint Updates

### Vehicle Blueprints

1. **BP_FlyingPawn**:
   - Open in UE 5.7 Editor
   - Fix any broken connections (red nodes)
   - Recompile blueprint
   - Test in PIE (Play In Editor)

2. **BP_CarPawn** (if exists):
   - Same procedure as above
   - Verify wheel configuration
   - Test steering/braking nodes

3. **BP_PIPCamera**:
   - Check camera component settings
   - Verify render targets
   - Test image capture functionality

### Blueprint Upgrade Process

```
1. File → Open Blueprint
2. If "Upgrade Required" dialog appears:
   - Click "Open Copy" to preserve original
   - Or "Convert In-Place" if confident
3. Compile blueprint (green checkmark)
4. Fix any errors shown in Compiler Results
5. Save blueprint
6. Test in editor
```

---

## Debugging Tips

### Enable Verbose Logging

In `DefaultEngine.ini`:
```ini
[Core.Log]
LogAirSim=Verbose
LogChaos=Verbose
LogRenderer=Verbose
```

### Check Plugin Load

```cpp
// In AirSim.cpp
void FAirSimModule::StartupModule()
{
    UE_LOG(LogAirSim, Warning, TEXT("AirSim Module Starting for UE 5.7"));
}
```

### Verify Build Configuration

```bash
# Windows
echo %UE5_ROOT%

# Linux
echo $UE5_ROOT

# Verify UE version
# In UE Editor: Help → About Unreal Editor
```

---

## Common Fixes

### Fix 1: Wheel Class Not Found

**Error**: `error: use of undeclared identifier 'UCarWheelFront'`

**Solution**:
```cpp
// Check header:
#include "CarWheelFront.h"

// Verify class definition exists:
UCLASS()
class UCarWheelFront : public UChaosVehicleWheel
{
    GENERATED_BODY()
    // ...
};
```

### Fix 2: Movement Component Null

**Error**: Runtime crash accessing vehicle movement

**Solution**:
```cpp
UChaosVehicleMovementComponent* movement = getVehicleMovementComponent();
if (!movement)
{
    UE_LOG(LogAirSim, Error, TEXT("Movement component is null!"));
    return;
}
// Use movement
```

### Fix 3: Image Capture Returns Empty

**Error**: Camera capture returns no data

**Solution**:
```cpp
// Ensure render target is valid
if (!camera->RenderTarget)
{
    // Recreate render target
    camera->RenderTarget = NewObject<UTextureRenderTarget2D>();
    camera->RenderTarget->InitAutoFormat(width, height);
}
```

---

## Module Dependency Updates

If compilation fails with missing modules:

**Check `AirSim.Build.cs`**:
```csharp
PublicDependencyModuleNames.AddRange(new string[] {
    "Core", "CoreUObject", "Engine",
    "ChaosVehicles",  // Verify this exists in UE 5.7
    // ... other modules
});
```

**Verify Module Names**:
1. Check `[UE5_ROOT]/Engine/Source/Runtime/` for module folders
2. Confirm module names match exactly
3. Check if any modules were deprecated/renamed

---

## Pre-Compilation Checklist

Before attempting to compile:

- [ ] UE 5.7 installed and verified
- [ ] Visual Studio 2022 (Windows) or compatible compiler (Linux)
- [ ] `.uproject` updated to target 5.7
- [ ] All plugin source files present
- [ ] Build.cs reviewed for module compatibility
- [ ] Backup/branch created for rollback
- [ ] Documentation reviewed
- [ ] Known issues documented

## Post-Compilation Checklist

After successful compilation:

- [ ] Plugin loads in editor without errors
- [ ] Blocks environment opens
- [ ] Vehicle spawns successfully
- [ ] Camera capture works
- [ ] Python API connects
- [ ] Basic flight/drive test passes
- [ ] No critical warnings in log
- [ ] Performance acceptable

---

## When to Seek Help

Contact community or file issues if:

1. **Compilation fails after 4+ hours of attempts**
   - Document all errors
   - Provide minimal reproduction case
   - Share UE version and platform details

2. **Runtime crashes consistently**
   - Provide call stack
   - Describe reproduction steps
   - Share project settings

3. **Performance regression > 20%**
   - Provide profiling data
   - Describe test scenario
   - Compare with UE 5.1 metrics

## Resources

- **Epic Games UE5 API**: https://dev.epicgames.com/documentation/en-us/unreal-engine/API
- **UE5 Migration Guide**: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-migration-guide
- **ChaosVehicles Plugin**: Check `[UE5_ROOT]/Engine/Plugins/Experimental/ChaosVehiclesPlugin/`
- **Colosseum Slack**: For community support
- **GitHub Issues**: For bug reports

---

## Summary

Most AirSim code should compile with minimal changes due to:
- Already using modern UE5 APIs
- Good architectural separation
- Stable core Unreal classes (APawn, AActor, etc.)

Focus compilation efforts on:
1. Vehicle physics (ChaosVehicles)
2. Camera/rendering (Scene capture, materials)
3. Platform-specific verification (especially Linux)

Expect 80% of code to compile without changes, 15% to need minor updates (includes, function names), and 5% to need careful review (vehicle physics, rendering).
