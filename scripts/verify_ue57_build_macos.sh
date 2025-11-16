#!/bin/bash
# AirSim UE 5.7 Build Verification Script for macOS
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
PLATFORM="Mac"

echo "========================================="
echo "AirSim UE 5.7 Build Verification (macOS)"
echo "========================================="
echo ""

# macOS Warning
echo -e "${YELLOW}WARNING: macOS support is EXPERIMENTAL${NC}"
echo "- Apple Silicon (M1/M2/M3) is NOT supported"
echo "- Intel Macs only"
echo "- May be deprecated in future releases"
echo ""
read -p "Continue anyway? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Step 1: Check macOS version and architecture
echo -e "${YELLOW}[1/8] Checking macOS system...${NC}"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
echo "macOS version: $MACOS_VERSION"

if [ "$MACOS_MAJOR" -lt 11 ]; then
    echo -e "${RED}ERROR: macOS 11 (Big Sur) or later required${NC}"
    echo "Current version: $MACOS_VERSION"
    exit 1
fi
echo -e "${GREEN}✓ macOS version OK${NC}"

# Check architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    echo -e "${RED}ERROR: Apple Silicon (M1/M2/M3) is NOT supported${NC}"
    echo "AirSim UE 5.7 requires Intel Mac (x86_64)"
    exit 1
fi

if [ "$ARCH" = "x86_64" ]; then
    echo -e "${GREEN}✓ Intel Mac detected${NC}"
else
    echo -e "${YELLOW}WARNING: Unknown architecture: $ARCH${NC}"
fi

# Step 2: Check UE5 installation
echo -e "${YELLOW}[2/8] Checking UE 5.7 installation...${NC}"

if [ -z "$UE5_ROOT" ]; then
    # Try to find UE5 in common locations
    COMMON_LOCATIONS=(
        "/Users/Shared/Epic Games/UE_5.7"
        "$HOME/UnrealEngine"
        "/Applications/Epic Games/UE_5.7"
    )

    for location in "${COMMON_LOCATIONS[@]}"; do
        if [ -d "$location" ]; then
            UE5_ROOT="$location"
            echo "Found UE at: $UE5_ROOT"
            break
        fi
    done
fi

if [ -z "$UE5_ROOT" ]; then
    echo -e "${RED}ERROR: UE5_ROOT not set and UE not found in common locations${NC}"
    echo "Please set UE5_ROOT environment variable:"
    echo "  export UE5_ROOT=/path/to/UnrealEngine"
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

UE_VERSION=$(grep -oE '"MajorVersion": [0-9]+' "$UE_VERSION_FILE" | grep -oE '[0-9]+')
UE_MINOR=$(grep -oE '"MinorVersion": [0-9]+' "$UE_VERSION_FILE" | grep -oE '[0-9]+')
echo -e "${GREEN}✓ Found Unreal Engine ${UE_VERSION}.${UE_MINOR}${NC}"

if [ "$UE_VERSION" != "5" ]; then
    echo -e "${YELLOW}WARNING: Expected UE 5.x, found ${UE_VERSION}.${UE_MINOR}${NC}"
fi

# Step 3: Check Xcode and build tools
echo -e "${YELLOW}[3/8] Checking Xcode and build tools...${NC}"

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}ERROR: Xcode not found${NC}"
    echo "Install Xcode from App Store"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n1)
echo -e "${GREEN}✓ Xcode found: $XCODE_VERSION${NC}"

# Check for command line tools
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}ERROR: Xcode Command Line Tools not installed${NC}"
    echo "Install with: xcode-select --install"
    exit 1
fi
echo -e "${GREEN}✓ Xcode Command Line Tools installed${NC}"

# Check for clang
if ! command -v clang &> /dev/null; then
    echo -e "${RED}ERROR: clang not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ clang found: $(clang --version | head -n1)${NC}"

# Step 4: Check Homebrew and dependencies
echo -e "${YELLOW}[4/8] Checking dependencies...${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}WARNING: Homebrew not found${NC}"
    echo "Consider installing: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
    echo -e "${GREEN}✓ Homebrew found${NC}"

    # Check for cmake
    if ! command -v cmake &> /dev/null; then
        echo -e "${YELLOW}WARNING: cmake not found. Install with: brew install cmake${NC}"
    else
        echo -e "${GREEN}✓ cmake found: $(cmake --version | head -n1)${NC}"
    fi
fi

# Step 5: Clean previous builds
echo -e "${YELLOW}[5/8] Cleaning previous builds...${NC}"
cd "$PROJECT_ROOT"

if [ -f "clean.sh" ]; then
    ./clean.sh
    echo -e "${GREEN}✓ Clean complete${NC}"
else
    echo -e "${YELLOW}WARNING: clean.sh not found, skipping${NC}"
fi

# Step 6: Build AirLib
echo -e "${YELLOW}[6/8] Building AirLib...${NC}"

# Check if setup was run
if [ ! -d "external/rpclib" ]; then
    echo -e "${YELLOW}Running setup.sh first...${NC}"
    if [ -f "setup.sh" ]; then
        ./setup.sh
    else
        echo -e "${RED}ERROR: setup.sh not found${NC}"
        exit 1
    fi
fi

cd "$PROJECT_ROOT"
if [ -f "build.sh" ]; then
    ./build.sh
    echo -e "${GREEN}✓ AirLib build complete${NC}"
else
    echo -e "${RED}ERROR: build.sh not found${NC}"
    exit 1
fi

# Step 7: Check project file
echo -e "${YELLOW}[7/8] Checking Unreal project...${NC}"
UPROJECT_FILE="$PROJECT_ROOT/Unreal/Environments/Blocks/Blocks.uproject"

if [ ! -f "$UPROJECT_FILE" ]; then
    echo -e "${RED}ERROR: Blocks.uproject not found at $UPROJECT_FILE${NC}"
    exit 1
fi

# Check project targets UE 5.7
ENGINE_ASSOC=$(grep -oE '"EngineAssociation": "[^"]+"' "$UPROJECT_FILE" | cut -d'"' -f4)
echo "Project EngineAssociation: $ENGINE_ASSOC"
if [ "$ENGINE_ASSOC" != "5.7" ]; then
    echo -e "${YELLOW}WARNING: Project targets $ENGINE_ASSOC, expected 5.7${NC}"
fi

# Check for UnrealBuildTool
UBT="$UE5_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool"
if [ -f "$UBT" ] || [ -f "${UBT}.dll" ]; then
    echo -e "${GREEN}✓ UnrealBuildTool found${NC}"
else
    echo -e "${RED}ERROR: UnrealBuildTool not found${NC}"
    exit 1
fi

# Step 8: Build Unreal plugin
echo -e "${YELLOW}[8/8] Building AirSim Unreal plugin...${NC}"

BUILD_CMD="$UE5_ROOT/Engine/Build/BatchFiles/Mac/Build.sh"
if [ ! -f "$BUILD_CMD" ]; then
    echo -e "${RED}ERROR: Build script not found at $BUILD_CMD${NC}"
    exit 1
fi

cd "$(dirname "$UPROJECT_FILE")"

echo "Running: $BUILD_CMD Blocks Mac $BUILD_CONFIGURATION -project=$UPROJECT_FILE"
"$BUILD_CMD" Blocks Mac "$BUILD_CONFIGURATION" -project="$UPROJECT_FILE" 2>&1 | tee "$PROJECT_ROOT/build_ue57_macos.log"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Unreal plugin build SUCCEEDED${NC}"
else
    echo -e "${RED}✗ Unreal plugin build FAILED${NC}"
    echo "Check build_ue57_macos.log for details"
    exit 1
fi

# Verify plugin
echo ""
echo "========================================="
echo "Verifying plugin..."
echo "========================================="

PLUGIN_FILE="$PROJECT_ROOT/Unreal/Plugins/AirSim/AirSim.uplugin"
if [ -f "$PLUGIN_FILE" ]; then
    echo -e "${GREEN}✓ Plugin descriptor found${NC}"
else
    echo -e "${RED}ERROR: Plugin descriptor not found${NC}"
    exit 1
fi

# Check for compiled plugin binaries
PLUGIN_BINARY_DIR="$PROJECT_ROOT/Unreal/Plugins/AirSim/Binaries/Mac"
if [ -d "$PLUGIN_BINARY_DIR" ]; then
    BINARY_COUNT=$(find "$PLUGIN_BINARY_DIR" -name "*.dylib" 2>/dev/null | wc -l)
    if [ "$BINARY_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $BINARY_COUNT plugin binaries${NC}"
    else
        echo -e "${YELLOW}WARNING: No .dylib files found in $PLUGIN_BINARY_DIR${NC}"
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
echo "   open \"$UPROJECT_FILE\""
echo "   Or: $UE5_ROOT/Engine/Binaries/Mac/UnrealEditor.app/Contents/MacOS/UnrealEditor \"$UPROJECT_FILE\""
echo ""
echo "2. Run Python API tests:"
echo "   python3 \"$PROJECT_ROOT/PythonClient/unreal_engine/ue57_compatibility_test.py\""
echo ""
echo "3. Check build log for warnings:"
echo "   less \"$PROJECT_ROOT/build_ue57_macos.log\""
echo ""
echo -e "${YELLOW}Note: macOS support is experimental. Consider using Windows or Linux for production.${NC}"
echo ""
