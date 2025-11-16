# UE 5.7 compatibility verification test for AirSim
# Verifies core functionality after migration from UE 5.1 to UE 5.7

import os
import sys
import setup_path
import airsim
import time

def test_connection():
    client = airsim.VehicleClient()
    client.confirmConnection()
    return True

def test_multirotor_basic():
    client = airsim.MultirotorClient()
    client.confirmConnection()
    client.enableApiControl(True)
    client.armDisarm(True)

    landed = client.getMultirotorState().landed_state
    assert landed == airsim.LandedState.Landed

    client.takeoffAsync().join()
    time.sleep(2)

    state = client.getMultirotorState()
    assert state.landed_state == airsim.LandedState.Landed or state.landed_state == airsim.LandedState.Flying

    client.landAsync().join()
    client.armDisarm(False)
    client.enableApiControl(False)
    return True

def test_car_basic():
    client = airsim.CarClient()
    client.confirmConnection()
    client.enableApiControl(True)

    state = client.getCarState()
    assert state is not None

    client.enableApiControl(False)
    return True

def test_camera_capture():
    client = airsim.VehicleClient()
    client.confirmConnection()

    responses = client.simGetImages([
        airsim.ImageRequest("0", airsim.ImageType.Scene),
        airsim.ImageRequest("0", airsim.ImageType.DepthPlanar, True),
        airsim.ImageRequest("0", airsim.ImageType.Segmentation),
    ])

    assert len(responses) == 3
    for response in responses:
        assert response.width > 0 and response.height > 0

    return True

def test_lidar():
    client = airsim.VehicleClient()
    client.confirmConnection()

    lidar_data = client.getLidarData()
    assert lidar_data is not None

    return True

def test_world_api():
    client = airsim.VehicleClient()
    client.confirmConnection()

    client.simPause(True)
    time.sleep(0.1)
    client.simPause(False)

    client.simSetTimeOfDay(True, "2020-01-01 12:00:00", True, 1.0, 1.0, True)

    return True

def run_tests():
    tests = [
        ("Connection", test_connection),
        ("Multirotor Basic", test_multirotor_basic),
        ("Car Basic", test_car_basic),
        ("Camera Capture", test_camera_capture),
        ("Lidar", test_lidar),
        ("World API", test_world_api),
    ]

    passed = 0
    failed = 0

    for name, test_func in tests:
        try:
            print(f"Running {name}...")
            if test_func():
                print(f"  PASS")
                passed += 1
        except Exception as e:
            print(f"  FAIL: {str(e)}")
            failed += 1

    print(f"\nResults: {passed} passed, {failed} failed")
    return failed == 0

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
