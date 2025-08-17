# Unraid_CPU_Power_Tuner
A Simple Script to Tune CPU Power Settings

# Unraid CPU 性能调优脚本

本项目提供了一套简单的脚本，用于在 Unraid 系统上对 CPU 的性能参数进行调节。它包含一个用于手动实时调节的**交互式脚本**，以及一段用于开机自动配置的**代码**。

---

## 方案组成

1.  **开机自动配置代码 (非交互式)**
    * **用途**: 实现持久化设置。将这段代码直接粘贴到 Unraid 的 `User Scripts` 插件中，可以实现每次开机自动应用你所配置的 CPU 参数。
    * **使用方式**: 直接复制粘贴代码到插件，无需创建独立文件。

2.  **`cpu_power_tuner_interact.sh` (交互式调节脚本)**
    * **用途**: 用于临时测试或实时调整。直接在终端中运行此脚本文件，会提供一个菜单界面，让你方便地即时更改 CPU 设置。
    * **注意**: 此脚本所做的更改在服务器重启后会失效。

---

## 安装与设置

1.  **存放交互式脚本**
    将 `cpu_power_tuner_interact.sh` 这一个文件放置在 Unraid 服务器的固定目录中，推荐使用 `/mnt/user/system/scripts/`。
    ```bash
    mkdir -p /mnt/user/system/scripts
    cd /mnt/user/system/scripts
    wget https://raw.githubusercontent.com/zhaxingyu/Unraid_CPU_Power_Tuner/refs/heads/main/cpu_power_tuner_interact.sh
    chmod +x /mnt/user/system/scripts/cpu_power_tuner_interact.sh
    ```

2.  **运行脚本**，输入你存放脚本的路径并回车：
    ```bash
    ./cpu_power_tuner_interact.sh
    ```
---

## 如何使用

你有两种方式来调整CPU设置：

### 方法一：设置开机自动生效 (推荐)

此方法将配置固化，服务器重启后自动生效。

1.  **准备并修改配置代码**
    首先，**完整复制**下面的代码块。然后在任何文本编辑器中（比如记事本），根据你的需求修改代码顶部的 **“用户配置区”** 变量。

    *例如，如果你想关掉睿频，并将调度策略设为 `powersave`，就像这样修改：*
    ```bash
    SET_BOOST="off"
    SET_GOVERNOR="powersave"
    # ... 其他变量保持不变或留空
    ```

    **请复制以下所有代码：**
    ```bash
      #!/bin/bash
      
      # ==============================================================================
      # Unraid CPU POWER TUNER
      #
      # 使用方法:
      # 1. 修改下面的 "用户配置区" 中的变量值。
      # 2. 在 Unraid WebUI 中进入 "Settings" -> "User Scripts"。
      # 3. 添加一个新脚本
      # 4. 将该脚本的 Schedule (计划) 设置为 "At Startup of Array" (阵列启动时)。
      #
      # 作者: @moonlight
      # ==============================================================================
      
      
      # ##############################################################################
      #
      #                           --- 用户配置区 ---
      #
      # 说明:
      #   - 在双引号 "" 之间填入你想要的值。
      #   - 留空 "" 保留默认设置。
      #
      # ##############################################################################
      
      # 设置睿频 (Boost)
      # 可用值: "on" (开启), "off" (关闭)
      # 
      SET_BOOST=""
      
      # 设置 CPU 调度策略 (Governor)
      # 可用值: "performance", "powersave", "schedutil" (需要调度器支持)
      # 留空 "" 则不进行任何设置。
      SET_GOVERNOR=""
      
      # 设置 CPU 最大频率 (单位: MHz)
      # 例如: 填入 "4000" 代表将最大频率限制在 4000MHz (4.0GHz)。
      
      SET_MAX_FREQ_MHZ=""
      
      # 设置 CPU 最小频率 (单位: MHz)
      # 例如: 填入 "800" 代表将最小频率设置为 800MHz (0.8GHz)。
      
      SET_MIN_FREQ_MHZ=""
      
      
      # ##############################################################################
      #
      #                       --- 脚本执行区 ---
      #                  (一般来说, 你不需要修改下面的任何内容)
      #
      # ##############################################################################
      
      echo "--- [CPU POWER TUNER] 开始执行CPU参数配置 ---"
      
      # 1. 应用睿频 (Boost) 设置
      if [ -n "$SET_BOOST" ]; then
          if [ "$SET_BOOST" == "on" ]; then
              echo "正在设置睿频为: 开启 (on)"
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/boost; do echo "1" > "$cpu"; done
          elif [ "$SET_BOOST" == "off" ]; then
              echo "正在设置睿频为: 关闭 (off)"
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/boost; do echo "0" > "$cpu"; done
          else
              echo "警告: SET_BOOST 的值 '$SET_BOOST' 无效, 跳过设置。"
          fi
      else
          echo "信息: 未配置睿频 (SET_BOOST), 跳过。"
      fi
      
      # 2. 应用调度策略 (Governor) 设置
      if [ -n "$SET_GOVERNOR" ]; then
          available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
          if [[ " $available_governors " =~ " $SET_GOVERNOR " ]]; then
              echo "正在设置调度策略为: $SET_GOVERNOR"
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "$SET_GOVERNOR" > "$cpu"; done
          else
              echo "警告: 调度策略 '$SET_GOVERNOR' 无效或不受支持, 跳过设置。"
          fi
      else
          echo "信息: 未配置调度策略 (SET_GOVERNOR), 跳过。"
      fi
      
      # --- 从系统中获取硬件支持的频率范围 ---
      HW_MAX_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
      HW_MIN_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
      HW_MAX_FREQ_MHZ=$((HW_MAX_FREQ_KHZ / 1000))
      HW_MIN_FREQ_MHZ=$((HW_MIN_FREQ_KHZ / 1000))
      
      # 3. 应用最大频率设置 (带安全检查)
      if [ -n "$SET_MAX_FREQ_MHZ" ]; then
          if [[ "$SET_MAX_FREQ_MHZ" =~ ^[0-9]+$ ]]; then
              USER_MAX_KHZ=$((SET_MAX_FREQ_MHZ * 1000))
              # 检查用户设置的值是否在硬件支持的范围内
              if [ "$USER_MAX_KHZ" -le "$HW_MAX_FREQ_KHZ" ] && [ "$USER_MAX_KHZ" -ge "$HW_MIN_FREQ_KHZ" ]; then
                  echo "正在设置最大频率为: ${SET_MAX_FREQ_MHZ} MHz"
                  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo "$USER_MAX_KHZ" > "$cpu"; done
              else
                  echo "错误: 目标最大频率 ${SET_MAX_FREQ_MHZ} MHz 超出硬件支持范围 [${HW_MIN_FREQ_MHZ} - ${HW_MAX_FREQ_MHZ}] MHz，跳过此设置。"
              fi
          else
              echo "警告: SET_MAX_FREQ_MHZ 的值 '$SET_MAX_FREQ_MHZ' 不是有效的数字, 跳过设置。"
          fi
      else
          echo "信息: 未配置最大频率 (SET_MAX_FREQ_MHZ), 跳过。"
      fi
      
      # 4. 应用最小频率设置 (带安全检查)
      if [ -n "$SET_MIN_FREQ_MHZ" ]; then
          if [[ "$SET_MIN_FREQ_MHZ" =~ ^[0-9]+$ ]]; then
              USER_MIN_KHZ=$((SET_MIN_FREQ_MHZ * 1000))
              # 检查用户设置的值是否在硬件支持的范围内
              if [ "$USER_MIN_KHZ" -ge "$HW_MIN_FREQ_KHZ" ] && [ "$USER_MIN_KHZ" -le "$HW_MAX_FREQ_KHZ" ]; then
                  echo "正在设置最小频率为: ${SET_MIN_FREQ_MHZ} MHz"
                  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo "$USER_MIN_KHZ" > "$cpu"; done
              else
                  echo "错误: 目标最小频率 ${SET_MIN_FREQ_MHZ} MHz 超出硬件支持范围 [${HW_MIN_FREQ_MHZ} - ${HW_MAX_FREQ_MHZ}] MHz，跳过此设置。"
              fi
          else
              echo "警告: SET_MIN_FREQ_MHZ 的值 '$SET_MIN_FREQ_MHZ' 不是有效的数字, 跳过设置。"
          fi
      else
          echo "信息: 未配置最小频率 (SET_MIN_FREQ_MHZ), 跳过。"
      fi
      
      echo "--- [CPU POWER TUNER] 所有配置已应用完成 ---"
    ```

2.  **配置 User Scripts 插件**
    a. 在 Unraid WebUI 中，进入 **"Settings" -> "User Scripts"**。
    b. 点击 **"Add New Script"**，给脚本起一个描述性名称（例如 `CPU_Power_Settings`）。
    c. 点击新脚本最左边的图标，选择 **"Edit Script"**。
    d. 将你刚才 **复制并修改好** 的全部代码 **粘贴** 到这个编辑框中，覆盖掉原有的 `#!/bin/bash`。
    e. 点击 **"Save Changes"** 保存。
    f. 最后，在 `User Scripts` 页面主列表中，找到你刚创建的脚本，将其 **"Schedule"** 设置为 **"At Startup of Array"**。

### 方法二：手动实时调整

如果你想临时更改设置或者测试不同配置的效果，请使用 `cpu_power_tuner_interact.sh` 文件。

1.  **打开 Unraid 终端** (WebUI 右上角的 `>`\_ 图标)。
2.  **运行脚本**，输入你存放脚本的路径并回车：
    ```bash
    bash /mnt/user/system/scripts/cpu_power_tuner_interact.sh
    ```
3.  **根据菜单操作**，脚本会显示当前的 CPU 状态和可用的操作选项。

<img width="867" height="697" alt="image" src="https://github.com/user-attachments/assets/b1a42b02-3188-4e51-a0d1-ac43a134d247" />

---

## 注意事项

* 调整 CPU 的核心参数存在一定风险，可能会导致系统不稳定。请谨慎操作。
* 这些脚本主要为使用 `amd_pstate` 驱动的现代 AMD CPU 设计。
