#!/bin/bash
# AirSim UE 5.7 Build Verification Script
# Run this script when UE 5.7 is installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
UE5_ROOT="${UE5_ROOT:-}"
BUILD_CONFIGURATION="Development"
PLATFORM="Linux"

echo "========================================="
echo "AirSim UE 5.7 Build Verification"
echo "========================================="
echo ""

# Step 1: Check UE5 installation
echo -e "${YELLOW}[1/7] Checking UE 5.7 installation...${NC}"
if [ -z "$UE5_ROOT" ]; then
    echo -e "${RED}ERROR: UE5_ROOT environment variable not set${NC}"
    echo "Please set UE5_ROOT to your Unreal Engine 5.7 installation directory"
    echo "Example: export UE5_ROOT=/home/user/UnrealEngine"
    exit 1
fi

if [ ! -d "$UE5_ROOT" ]; then
    echo -e "${RED}ERROR: UE5_ROOT directory does not exist: $UE5_ROOT${NC}"
    exit 1
fi

UE_VERSION_FILE="$UE5_ROOT/Engine/Build/Build.version"
if [ ! -f "$UE_VERSION_FILE" ]; then
    echo -e "${RED}ERROR: Cannot find UE version file at $UE_VERSION_FILE${NC}"
    exit 1
fi

UE_VERSION=$(grep -oP '"MajorVersion":\s*\K\d+' "$UE_VERSION_FILE")
UE_MINOR=$(grep -oP '"MinorVersion":\s*\K\d+' "$UE_VERSION_FILE")
echo -e "${GREEN}✓ Found Unreal Engine ${UE_VERSION}.${UE_MINOR}${NC}"

if [ "$UE_VERSION" != "5" ]; then
    echo -e "${YELLOW}WARNING: Expected UE 5.x, found ${UE_VERSION}.${UE_MINOR}${NC}"
fi

# Step 2: Check prerequisites
echo -e "${YELLOW}[2/7] Checking build prerequisites...${NC}"

# Check for clang
if ! command -v clang &> /dev/null; then
    echo -e "${RED}ERROR: clang not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ clang found: $(clang --version | head -n1)${NC}"

# Check for required libraries
REQUIRED_LIBS=("stdc++" "pthread")
for lib in "${REQUIRED_LIBS[@]}"; do
    if ldconfig -p | grep -q "lib${lib}"; then
        echo -e "${GREEN}✓ lib${lib} found${NC}"
    else
        echo -e "${RED}ERROR: lib${lib} not found${NC}"
        exit 1
    fi
done

# Step 3: Clean previous builds
echo -e "${YELLOW}[3/7] Cleaning previous builds...${NC}"
cd "$PROJECT_ROOT"
if [ -f "clean.sh" ]; then
    ./clean.sh
    echo -e "${GREEN}✓ Clean complete${NC}"
else
    echo -e "${YELLOW}WARNING: clean.sh not found, skipping${NC}"
fi

# Step 4: Build AirLib
echo -e "${YELLOW}[4/7] Building AirLib...${NC}"
cd "$PROJECT_ROOT"
if [ -f "build.sh" ]; then
    ./build.sh
    echo -e "${GREEN}✓ AirLib build complete${NC}"
else
    echo -e "${RED}ERROR: build.sh not found${NC}"
    exit 1
fi

# Step 5: Generate Unreal project files
echo -e "${YELLOW}[5/7] Generating Unreal project files...${NC}"
UPROJECT_FILE="$PROJECT_ROOT/Unreal/Environments/Blocks/Blocks.uproject"

if [ ! -f "$UPROJECT_FILE" ]; then
    echo -e "${RED}ERROR: Blocks.uproject not found at $UPROJECT_FILE${NC}"
    exit 1
fi

# Check project targets UE 5.7
ENGINE_ASSOC=$(grep -oP '"EngineAssociation":\s*"\K[^"]+' "$UPROJECT_FILE")
echo "Project EngineAssociation: $ENGINE_ASSOC"
if [ "$ENGINE_ASSOC" != "5.7" ]; then
    echo -e "${YELLOW}WARNING: Project targets $ENGINE_ASSOC, expected 5.7${NC}"
fi

# Use UE's GenerateProjectFiles script
UBT="$UE5_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool"
if [ -f "$UBT" ] || [ -f "${UBT}.dll" ]; then
    echo -e "${GREEN}✓ UnrealBuildTool found${NC}"
else
    echo -e "${RED}ERROR: UnrealBuildTool not found${NC}"
    exit 1
fi

# Step 6: Build Unreal plugin
echo -e "${YELLOW}[6/7] Building AirSim Unreal plugin...${NC}"

BUILD_CMD="$UE5_ROOT/Engine/Build/BatchFiles/Linux/Build.sh"
if [ ! -f "$BUILD_CMD" ]; then
    echo -e "${RED}ERROR: Build script not found at $BUILD_CMD${NC}"
    exit 1
fi

cd "$(dirname "$UPROJECT_FILE")"

echo "Running: $BUILD_CMD Blocks Linux $BUILD_CONFIGURATION -project=$UPROJECT_FILE"
"$BUILD_CMD" Blocks Linux "$BUILD_CONFIGURATION" -project="$UPROJECT_FILE" 2>&1 | tee "$PROJECT_ROOT/build_ue57.log"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Unreal plugin build SUCCEEDED${NC}"
else
    echo -e "${RED}✗ Unreal plugin build FAILED${NC}"
    echo "Check build_ue57.log for details"
    exit 1
fi

# Step 7: Verify plugin loads
echo -e "${YELLOW}[7/7] Verifying plugin...${NC}"

PLUGIN_FILE="$PROJECT_ROOT/Unreal/Plugins/AirSim/AirSim.uplugin"
if [ -f "$PLUGIN_FILE" ]; then
    echo -e "${GREEN}✓ Plugin descriptor found${NC}"
    cat "$PLUGIN_FILE"
else
    echo -e "${RED}ERROR: Plugin descriptor not found${NC}"
    exit 1
fi

# Check for compiled plugin binaries
PLUGIN_BINARY_DIR="$PROJECT_ROOT/Unreal/Plugins/AirSim/Binaries/Linux"
if [ -d "$PLUGIN_BINARY_DIR" ]; then
    BINARY_COUNT=$(find "$PLUGIN_BINARY_DIR" -name "*.so" | wc -l)
    if [ "$BINARY_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $BINARY_COUNT plugin binaries${NC}"
    else
        echo -e "${YELLOW}WARNING: No .so files found in $PLUGIN_BINARY_DIR${NC}"
    fi
else
    echo -e "${YELLOW}WARNING: Plugin binary directory not found${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}BUILD VERIFICATION COMPLETE${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Open project in UE 5.7 Editor:"
echo "   $UE5_ROOT/Engine/Binaries/Linux/UnrealEditor $UPROJECT_FILE"
echo ""
echo "2. Run Python API tests:"
echo "   python $PROJECT_ROOT/PythonClient/unreal_engine/ue57_compatibility_test.py"
echo ""
echo "3. Check build log for warnings:"
echo "   less $PROJECT_ROOT/build_ue57.log"
echo ""
