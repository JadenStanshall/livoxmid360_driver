# livox mid 360 driver setup (wsl2)

this repo builds a ros2 humble workspace for running the livox mid 360 driver on windows 11 wsl2 (with mirrored networking). there are some networking and abi limitations that stop the livox driver form working with wsl out of the box which makes prototyping challenging on a windows laptop, so in this repo we bundle the required submodules with patch files to fix those issues and wrap the setup into a single script.

**included submodules**
- [`Livox-SDK2`](https://github.com/Livox-SDK/Livox-SDK2) — patch: spdlog abi crash fix, broadcast socket bind fix
- [`livox_ros_driver2`](https://github.com/Livox-SDK/livox_ros_driver2) — patch: detection chain bypass, wall-clock timestamps, wsl2 scheduler timing fix
- [`livox_to_pointcloud2`](https://github.com/koide3/livox_to_pointcloud2)

---

## prerequisites

**set mirrored networking for wsl2**

```ini
[wsl2]
networkingMode=mirrored
```

**install ros2 humble and build tools**:

```bash
sudo apt install ros-humble-desktop ros-humble-ament-cmake-auto
sudo apt install python3-colcon-common-extensions python3-rosdep cmake git
```

**networking**: set your adapter to `192.168.1.50 / 255.255.255.0` for device discovery. also livox defaults to `192.168.1.3`, verify with `ping 192.168.1.3` from inside wsl2.

---

## setup

```bash
git clone https://github.com/JadenStanshall/livoxmid360_driver.git ~/livox_driver
cd ~/livox_driver
bash setup.sh
```

`setup.sh` does:
1. init and clone submodules
2. apply patches
3. build and install Livox SDK
4. build ros2 workspace


---

## launch

you will probably wanna launch the file which publishes points with the custom livox message format which includes the per-point time stamps, this is helpful for deskewing, but more importantly its just what is required by most open source modules you might want to make use of.

```bash
source ~/livox_driver/install/setup.bash
ros2 launch livox_ros_driver2 msg_MID360_launch.py
```

the expected output of the driver (in addition to seeing the right messages on the specified topics) is a heartbeat printed to the terminal every 5 seconds showing packet and frame counts. you can also verify the topics are publishing:

```bash
# in a new terminal (source first)
source ~/livox_driver/install/setup.bash
ros2 topic hz /livox/lidar
ros2 topic hz /livox/imu
ros2 topic hz /livox/points  # (PointCloud2)
```

---

## use with other ros2 nodes

**must source driver workspace in any terminal environment where you need the livox points:**

```bash
source ~/livox_driver/install/setup.bash
```

**published topics:**
1. `/livox/lidar`: `livox_ros_driver2/msg/CustomMsg`
2. `/livox/points`: `sensor_msgs/msg/PointCloud2`
3. `/livox/imu`: `sensor_msgs/msg/Imu`

`/livox/points` can be consumed by `rviz2`, `pcl_ros`, or any other ros2 node expecting regular ahh point cloud data. `/livox/lidar` is livox's custom native format and includes per-point timestamps and also line ids.

with the patches applied, the `livox_to_pointcloud2` converter node is launched automatically when you launch the driver.
