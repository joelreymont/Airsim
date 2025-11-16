# UE 5.7 Testing and Validation Guide

## Prerequisites

Before testing, ensure you have:
- ✅ Unreal Engine 5.7 installed
- ✅ Visual Studio 2022 (Windows) or Clang (Linux)
- ✅ Python 3.6+
- ✅ AirSim repository cloned
- ✅ Environment variable `UE5_ROOT` set

## Testing Phases

### Phase 1: Build Verification

#### Automated Build Test

**Linux:**
```bash
export UE5_ROOT=/path/to/UnrealEngine
cd AirSim
./scripts/verify_ue57_build_linux.sh
```

**Windows:**
```cmd
set UE5_ROOT=C:\Path\To\UnrealEngine
cd AirSim
scripts\verify_ue57_build_windows.bat
```

#### Manual Build Test

**Windows:**
```cmd
# 1. Clean rebuild
clean_rebuild.bat

# 2. Open in UE Editor
"%UE5_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe" "Unreal\Environments\Blocks\Blocks.uproject"

# 3. In Editor: File → Refresh Visual Studio Project
# 4. In Editor: Build → Build Blocks
```

**Linux:**
```bash
# 1. Setup and build
./setup.sh
./build.sh

# 2. Generate project files
cd Unreal/Environments/Blocks
$UE5_ROOT/GenerateProjectFiles.sh Blocks.uproject

# 3. Build
$UE5_ROOT/Engine/Build/BatchFiles/Linux/Build.sh Blocks Linux Development
```

### Phase 2: Compilation Validation

#### Expected Warnings (Acceptable)

✅ **Acceptable warnings:**
- Deprecated function warnings (note for future cleanup)
- C4996: Function marked as deprecated
- Soft warnings about TObjectPtr
- Non-critical metadata specifier warnings

❌ **Unacceptable errors:**
- Unknown type errors
- Module not found errors
- Undefined reference errors
- Linker errors

#### Common Issues and Fixes

**Issue 1: ChaosVehicles module not found**
```
Solution: Verify ChaosVehiclesPlugin is enabled in .uplugin file
Check: Unreal/Plugins/AirSim/AirSim.uplugin
```

**Issue 2: Unknown type 'UChaosWheeledVehicleMovementComponent'**
```
Solution: Add include in CarPawn.h:
#include "ChaosWheeledVehicleMovementComponent.h"
```

**Issue 3: Scene capture component errors**
```
Solution: Check USceneCaptureComponent2D API in UE 5.7 docs
May need to update render target creation code
```

### Phase 3: Runtime Testing

#### 3.1 Plugin Load Test

**In UE Editor:**
1. Open Blocks.uproject
2. Check Output Log for errors
3. Verify AirSim plugin appears in Edit → Plugins
4. Confirm plugin is enabled and loaded

**Expected Output:**
```
LogAirSim: AirSim Module Starting for UE 5.7
LogAirSim: Plugin loaded successfully
```

#### 3.2 Vehicle Spawn Test

**Multirotor:**
1. Play in Editor (PIE)
2. Vehicle should spawn at origin
3. Check for physics warnings
4. Verify rotor components visible

**Car:**
1. Ensure car mesh loads
2. Verify wheel components attached
3. Check suspension visualization
4. Test keyboard controls (WASD)

#### 3.3 Camera Test

**In PIE:**
1. Press F1-F5 to cycle cameras
2. Verify camera switching works
3. Check for rendering artifacts
4. Test manual camera movement

### Phase 4: API Testing

#### 4.1 Python Connection Test

```python
# test_connection.py
import airsim

client = airsim.VehicleClient()
client.confirmConnection()
print("✓ Connection successful")

# Test multirotor
drone = airsim.MultirotorClient()
drone.confirmConnection()
drone.enableApiControl(True)
print("✓ Multirotor API OK")

# Test car
car = airsim.CarClient()
car.confirmConnection()
car.enableApiControl(True)
print("✓ Car API OK")
```

#### 4.2 Comprehensive API Test

```bash
python PythonClient/unreal_engine/ue57_compatibility_test.py
```

**Expected Results:**
- ✅ Connection: PASS
- ✅ Multirotor Basic: PASS
- ✅ Car Basic: PASS
- ✅ Camera Capture: PASS
- ✅ Lidar: PASS
- ✅ World API: PASS

#### 4.3 Image Capture Test

```python
import airsim
import cv2

client = airsim.VehicleClient()
client.confirmConnection()

# Test all image types
image_types = [
    airsim.ImageType.Scene,
    airsim.ImageType.DepthPlanar,
    airsim.ImageType.DepthPerspective,
    airsim.ImageType.DepthVis,
    airsim.ImageType.DisparityNormalized,
    airsim.ImageType.Segmentation,
    airsim.ImageType.SurfaceNormals,
]

for img_type in image_types:
    responses = client.simGetImages([
        airsim.ImageRequest("0", img_type, False, False)
    ])

    if len(responses) > 0 and responses[0].width > 0:
        print(f"✓ {img_type.name}: OK ({responses[0].width}x{responses[0].height})")
    else:
        print(f"✗ {img_type.name}: FAILED")
```

### Phase 5: Performance Testing

#### 5.1 FPS Benchmark

```python
import airsim
import time

client = airsim.MultirotorClient()
client.confirmConnection()
client.enableApiControl(True)
client.armDisarm(True)
client.takeoffAsync().join()

# Measure FPS
start_time = time.time()
frame_count = 0

for i in range(300):  # 300 frames
    state = client.getMultirotorState()
    frame_count += 1
    time.sleep(0.01)

elapsed = time.time() - start_time
fps = frame_count / elapsed

print(f"Average FPS: {fps:.2f}")
print(f"Expected: >30 FPS (target: 60+ FPS)")

client.landAsync().join()
client.armDisarm(False)
```

#### 5.2 Memory Usage Test

**Windows:**
```cmd
# In PIE, check Task Manager
# AirSim should use <4GB RAM for Blocks environment
```

**Linux:**
```bash
# Monitor with htop or:
ps aux | grep Unreal
```

#### 5.3 Image Capture Performance

```python
import airsim
import time

client = airsim.VehicleClient()
client.confirmConnection()

# Benchmark image capture
iterations = 100
start = time.time()

for i in range(iterations):
    responses = client.simGetImages([
        airsim.ImageRequest("0", airsim.ImageType.Scene)
    ])

elapsed = time.time() - start
fps = iterations / elapsed

print(f"Image capture rate: {fps:.2f} FPS")
print(f"Expected: >20 FPS")
```

### Phase 6: Sensor Validation

#### 6.1 Lidar Test

```python
import airsim

client = airsim.VehicleClient()
client.confirmConnection()

lidar_data = client.getLidarData()

print(f"Lidar points: {len(lidar_data.point_cloud) // 3}")
print(f"Timestamp: {lidar_data.time_stamp}")
print(f"Expected: >1000 points")

if len(lidar_data.point_cloud) > 3000:
    print("✓ Lidar OK")
else:
    print("✗ Lidar may have issues")
```

#### 6.2 IMU Test

```python
import airsim

client = airsim.MultirotorClient()
client.confirmConnection()

imu_data = client.getImuData()

print(f"Linear acceleration: {imu_data.linear_acceleration}")
print(f"Angular velocity: {imu_data.angular_velocity}")
print(f"Orientation: {imu_data.orientation}")

# Check for reasonable values
acc_mag = (imu_data.linear_acceleration.x_val**2 +
           imu_data.linear_acceleration.y_val**2 +
           imu_data.linear_acceleration.z_val**2)**0.5

if 9.0 < acc_mag < 10.5:  # Gravity ~9.8 m/s²
    print("✓ IMU OK")
else:
    print(f"✗ IMU readings unusual: {acc_mag}")
```

### Phase 7: PX4/ArduPilot Integration

#### 7.1 SITL Connection Test

**Prerequisites:**
- PX4 or ArduPilot SITL running
- MavLink connection configured

```bash
# Start PX4 SITL
cd PX4-Autopilot
make px4_sitl_default none_iris

# In another terminal, start AirSim
# Set settings.json for PX4 connection
```

**Validation:**
```python
import airsim

client = airsim.MultirotorClient()
client.confirmConnection()

# Check MavLink connection status
# Vehicle should be controllable via PX4/ArduPilot
```

### Phase 8: Stress Testing

#### 8.1 Multi-Vehicle Test

```python
import airsim

# Spawn multiple vehicles
vehicles = ["Drone1", "Drone2", "Drone3", "Drone4"]

for vehicle_name in vehicles:
    client = airsim.MultirotorClient()
    client.confirmConnection()
    # Control each vehicle

print("✓ Multi-vehicle test complete")
```

#### 8.2 Long-Duration Test

```python
import airsim
import time

client = airsim.MultirotorClient()
client.confirmConnection()
client.enableApiControl(True)
client.armDisarm(True)
client.takeoffAsync().join()

# Fly for 30 minutes
start = time.time()
while time.time() - start < 1800:  # 30 minutes
    state = client.getMultirotorState()
    time.sleep(1)

    if (time.time() - start) % 300 == 0:  # Every 5 minutes
        print(f"Running for {(time.time() - start)/60:.0f} minutes")

client.landAsync().join()
client.armDisarm(False)

print("✓ Long-duration test complete")
```

## Performance Baselines

### Target Metrics (UE 5.7)

| Metric | Target | Acceptable | Concerning |
|--------|--------|------------|------------|
| Simulation FPS | 60+ | 30-60 | <30 |
| Image Capture FPS | 30+ | 20-30 | <20 |
| Memory Usage (Blocks) | <3GB | 3-4GB | >4GB |
| API Latency | <10ms | 10-50ms | >50ms |
| Startup Time | <30s | 30-60s | >60s |

### Comparison vs UE 5.1

Record and compare:
- Simulation FPS: Should be within ±5%
- Memory usage: Should be within ±10%
- Image quality: Visual inspection for regression
- API compatibility: All endpoints should work

## Test Results Documentation

### Test Report Template

```markdown
# AirSim UE 5.7 Test Report

**Date:** YYYY-MM-DD
**Tester:** Name
**Platform:** Windows/Linux
**UE Version:** 5.7.x
**AirSim Commit:** [commit hash]

## Build Results
- [ ] Clean build successful
- [ ] Plugin loads without errors
- [ ] No critical warnings

## Runtime Tests
- [ ] Multirotor spawns and flies
- [ ] Car spawns and drives
- [ ] Cameras functional
- [ ] Sensors provide data

## API Tests
- [ ] Python connection works
- [ ] All image types capture
- [ ] Lidar functional
- [ ] IMU provides data

## Performance
- Simulation FPS: ____ (target: 60+)
- Image capture FPS: ____ (target: 30+)
- Memory usage: ____ (target: <3GB)
- Startup time: ____ (target: <30s)

## Issues Found
1. [Description]
2. [Description]

## Conclusion
[ ] Ready for production
[ ] Needs fixes
[ ] Major issues found
```

## Troubleshooting

### Plugin Won't Load

```
Check:
1. .uproject EngineAssociation is "5.7"
2. Plugin is enabled in project settings
3. ChaosVehiclesPlugin dependency is met
4. Rebuild plugin binaries
```

### Vehicle Physics Issues

```
Check:
1. ChaosWheeledVehicleMovementComponent configured
2. Wheel classes set correctly
3. Physics materials assigned
4. Collision meshes present
```

### Camera/Rendering Issues

```
Check:
1. Scene capture component configuration
2. Render target creation
3. Material assignments
4. Post-processing chain
```

### API Connection Fails

```
Check:
1. settings.json in correct location
2. RPC port not blocked (41451)
3. API control enabled in settings
4. No firewall blocking connection
```

## Continuous Testing

### Automated Test Suite

Run regularly during development:

```bash
# Full test suite
python PythonClient/unreal_engine/ue57_compatibility_test.py

# Specific tests
python -m pytest tests/test_vehicles.py
python -m pytest tests/test_cameras.py
python -m pytest tests/test_sensors.py
```

### CI/CD Integration

While Unreal plugin can't be built in CI, test locally before each commit:

```bash
# Pre-commit checklist
1. Build succeeds
2. No new warnings introduced
3. Basic functionality test passes
4. No performance regression
```

## Sign-Off Checklist

Before declaring UE 5.7 migration complete:

- [ ] All code compiles without errors
- [ ] Zero critical warnings
- [ ] All vehicle types functional
- [ ] All image capture modes working
- [ ] All sensors providing data
- [ ] Python API fully functional
- [ ] Performance within acceptable range
- [ ] PX4/ArduPilot integration works
- [ ] Multi-vehicle scenarios tested
- [ ] Long-duration stability confirmed
- [ ] Documentation updated
- [ ] Known issues documented
- [ ] Community notified of release

## Support and Resources

- **Migration Guide**: docs/UE57_MIGRATION_GUIDE.md
- **Code Updates**: docs/UE57_CODE_UPDATE_GUIDE.md
- **Analysis**: docs/UE57_COMPATIBILITY_ANALYSIS.md
- **GitHub Issues**: Report problems
- **Colosseum Slack**: Community support
- **UE 5.7 Docs**: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5.7-release-notes
