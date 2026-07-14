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
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
sudo make install
sudo ldconfig
cd "$SCRIPT_DIR"

# ── livox_ros_driver2 ────────────────────────────────────────────────────────
echo "==> Applying patches to livox_ros_driver2..."
apply_patch "$SCRIPT_DIR/src/livox_ros_driver2" "$SCRIPT_DIR/patches/livox_ros_driver2/wsl2-fixes.patch"

# ── livox_to_pointcloud2 ─────────────────────────────────────────────────────
echo "==> Applying patches to livox_to_pointcloud2..."
apply_patch "$SCRIPT_DIR/src/livox_to_pointcloud2" "$SCRIPT_DIR/patches/livox_to_pointcloud2/cmake-fix.patch"

# ── ROS2 workspace build ─────────────────────────────────────────────────────
echo "==> Sourcing ROS2 Humble..."
# shellcheck disable=SC1091
source /opt/ros/humble/setup.bash

echo "==> Building ROS2 workspace..."
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

echo ""
echo "Setup complete."
