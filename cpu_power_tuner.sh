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
# 作者: @zhaxingyu
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