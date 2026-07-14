#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apply_patch() {
  local dir="$1"
  local patch="$2"
  cd "$dir"
  if git apply --reverse --check "$patch" 2>/dev/null; then
    echo "  (already applied, skipping)"
  else
    git apply "$patch"
  fi
  cd "$SCRIPT_DIR"
}

echo "==> Initializing submodules..."
git -C "$SCRIPT_DIR" submodule update --init --recursive

# ── Livox-SDK2 ───────────────────────────────────────────────────────────────
echo "==> Applying patches to Livox-SDK2..."
apply_patch "$SCRIPT_DIR/deps/livox_sdk2" "$SCRIPT_DIR/patches/livox_sdk2/wsl2-fixes.patch"

echo "==> Building and installing Livox-SDK2 (requires sudo)..."
mkdir -p "$SCRIPT_DIR/deps/livox_sdk2/build"
cd "$SCRIPT_DIR/deps/livox_sdk2/build"
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
sudo make install
sudo ldconfig
cd "$SCRIPT_DIR"

# ── livox_ros_driver2 ────────────────────────────────────────────────────────
echo "==> Applying patches to livox_ros_driver2..."
apply_patch "$SCRIPT_DIR/src/livox_ros_driver2" "$SCRIPT_DIR/patches/livox_ros_driver2/wsl2-fixes.patch"

if [ ! -f "$SCRIPT_DIR/src/livox_ros_driver2/package.xml" ]; then
  ln -s package_ROS2.xml "$SCRIPT_DIR/src/livox_ros_driver2/package.xml"
fi

# ── livox_to_pointcloud2 ─────────────────────────────────────────────────────
echo "==> Applying patches to livox_to_pointcloud2..."
apply_patch "$SCRIPT_DIR/src/livox_to_pointcloud2" "$SCRIPT_DIR/patches/livox_to_pointcloud2/cmake-fix.patch"

# ── ROS2 workspace build ─────────────────────────────────────────────────────
echo "==> Sourcing ROS2 Humble..."
# shellcheck disable=SC1091
set +u
source /opt/ros/humble/setup.bash
set -u

echo "==> Building ROS2 workspace..."
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DHUMBLE_ROS=humble

echo ""
echo "Setup complete."
