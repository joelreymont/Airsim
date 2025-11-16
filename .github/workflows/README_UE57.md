# GitHub Actions Workflows for UE 5.7

## Overview

The CI/CD workflows need updating to support Unreal Engine 5.7. Currently, the workflows build AirLib, Unity, ROS, and GazeboDrone but do not build the Unreal plugin (as it requires UE installation).

## Current Workflows

1. **test_ubuntu.yml** - Ubuntu 18.04 and 20.04 builds
2. **test_windows.yml** - Windows builds
3. **test_macos.yml** - macOS builds
4. **test_docs.yml** - Documentation builds
5. **clang_format.yml** - Code formatting checks

## UE 5.7 Impact

### Minimal Impact Workflows

These workflows build AirLib and other components **independent** of Unreal Engine:
- All platform test workflows (ubuntu, windows, macos)
- Build AirLib (C++ core)
- Unity builds
- ROS/ROS2 builds
- GazeboDrone builds

**Action Required**: None or minimal (version documentation)

### Not Currently CI-Tested

**Unreal Plugin Compilation**: Currently NOT tested in CI because:
1. Requires full UE installation (~100GB+)
2. Long build times (hours)
3. License/authentication requirements
4. GitHub Actions resource constraints

## Recommendations

### Option 1: Continue Current Approach (Recommended)

**Strategy**: Keep existing CI for AirLib/Unity/ROS, document UE 5.7 requirements

**Pros**:
- No CI infrastructure changes needed
- Fast feedback on AirLib changes
- Maintains current test coverage

**Cons**:
- Unreal plugin compilation not automatically verified
- UE-specific regressions only caught manually

**Implementation**:
- Update documentation to reference UE 5.7
- Add manual testing checklist
- Community relies on local testing

### Option 2: Add Unreal Build Workflow (Advanced)

**Strategy**: Add dedicated workflow for Unreal plugin compilation

**Requirements**:
- Self-hosted runner with UE 5.7 installed
- ~150GB disk space per runner
- Windows and Linux runners
- Longer build times (1-2 hours)

**Example Workflow** (reference only):
```yaml
name: Unreal Plugin Build (UE 5.7)

on: [pull_request] # Only on PRs to save resources

jobs:
  unreal-windows:
    runs-on: [self-hosted, windows, ue5.7]
    steps:
      - uses: actions/checkout@v3
      - name: Build Unreal Plugin
        run: |
          # Assumes UE5.7 installed at C:\UE5.7
          cd Unreal/Environments/Blocks
          "C:\UE5.7\Engine\Build\BatchFiles\Build.bat" Blocks Win64 Development
```

**Pros**:
- Automatic verification of UE compilation
- Catch UE-specific issues early

**Cons**:
- Requires self-hosted infrastructure
- Significant resource overhead
- Complex setup and maintenance

### Option 3: Nightly Unreal Builds (Compromise)

**Strategy**: Run UE compilation only on nightly schedule, not every commit

**Implementation**:
- Use GitHub scheduled workflows
- Run on self-hosted or cloud runners
- Report results to Slack/Discord

**Pros**:
- Regular verification without per-commit overhead
- Manageable resource usage

**Cons**:
- Delayed feedback (up to 24 hours)
- Still requires runner infrastructure

## Proposed Documentation Updates

### Update test_ubuntu.yml

Add comment documenting UE version:
```yaml
# This workflow builds AirLib, Unity, ROS, and GazeboDrone
# It does NOT build the Unreal plugin which requires UE 5.7 installation
# For Unreal plugin verification, see docs/UE57_MIGRATION_GUIDE.md
```

### Update test_windows.yml

Similar documentation update as Ubuntu.

### Update test_macos.yml

Add note about experimental macOS support:
```yaml
# Note: macOS support is experimental and may be deprecated
# Focus on Windows and Linux platforms
```

### Update README with CI Status

Update main README.md:
```markdown
## Build Status

**Note**: CI builds test AirLib, Unity, and ROS components.
Unreal Engine 5.7 plugin compilation requires manual testing.
See [UE 5.7 Migration Guide](docs/UE57_MIGRATION_GUIDE.md).
```

## Unreal Build Verification (Manual)

Since UE builds are not in CI, establish manual verification process:

### Pre-Merge Checklist

Before merging UE-related PRs:
- [ ] Code compiles on Windows with UE 5.7
- [ ] Code compiles on Linux with UE 5.7
- [ ] No new warnings introduced
- [ ] Basic functionality tested
- [ ] Reviewer has verified on their machine

### Verification Script

Create `scripts/verify_ue57_build.sh`:
```bash
#!/bin/bash
# Verify UE 5.7 plugin builds

set -e

echo "Verifying UE 5.7 build..."

# Check UE installation
if [ ! -d "$UE5_ROOT" ]; then
    echo "Error: UE5_ROOT not set or directory does not exist"
    exit 1
fi

# Clean build
./clean.sh

# Rebuild AirLib
./build.sh

# Generate Unreal project files (platform-specific)
# This would need to call UE's project file generator

echo "Build verification complete"
```

## Future Enhancements

### When Resources Allow

1. **Self-Hosted Runners**:
   - Set up Windows runner with UE 5.7
   - Set up Linux runner with UE 5.7
   - Configure secure access

2. **Cloud Runners**:
   - Investigate AWS/Azure virtual machines
   - Pre-configure with UE 5.7
   - Use only for release branches

3. **Plugin Marketplace**:
   - Submit to Unreal Marketplace
   - Leverage Epic's validation system
   - Automatic compatibility verification

## Implementation Plan

### Phase 1: Documentation (Immediate)
- ✅ Update workflow files with UE 5.7 comments
- ✅ Create this README
- ✅ Document manual verification process

### Phase 2: Enhanced Testing (Optional)
- [ ] Set up self-hosted runners
- [ ] Create UE build workflow
- [ ] Configure nightly builds
- [ ] Set up result notifications

### Phase 3: Automation (Future)
- [ ] Automated UE version testing (5.7, 5.8, etc.)
- [ ] Performance regression detection
- [ ] Visual regression testing

## Current Status

**AirLib/Unity/ROS**: Automated CI testing ✅
**Unreal Plugin**: Manual testing required ⚠️

This is acceptable because:
1. AirLib (core simulation) is platform-independent
2. Unreal plugin is primarily integration layer
3. Community testing provides good coverage
4. Manual verification catches UE-specific issues

## Conclusion

**Recommendation**: Proceed with Option 1 (current approach) with enhanced documentation.

**Rationale**:
- Cost-effective
- Maintains fast CI feedback
- Leverages community testing
- Can upgrade to Option 2/3 if resources become available

**Action Items**:
1. Update existing workflows with documentation
2. Create manual verification checklist
3. Establish community testing guidelines
4. Plan for future self-hosted runners if needed
