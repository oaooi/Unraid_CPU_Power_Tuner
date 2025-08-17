#!/bin/bash

# ==============================================================================
# CPU 性能调节脚本
#
# 功能:
#   - 显示当前 CPU 状态
#   - 开启/关闭睿频 (Boost)
#   - 设置 CPU 调度策略 (Governor)
#   - 设置最大/最小频率
#
# 作者: @oaooi
# ==============================================================================

# --- 安全检查: 必须以 root 权限运行 ---
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 此脚本需要以 root 权限运行。"
    echo "请尝试使用 'sudo ./amd_cpu_tuner.sh' 来运行。"
    exit 1
fi

# --- 函数: 显示当前 CPU 状态 ---
function show_current_status() {
    echo "----------------------------------------"
    echo "          当前 CPU 状态"
    echo "----------------------------------------"
    
    # 从 cpu0 获取通用信息
    local GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    local BOOST_STATE=$(cat /sys/devices/system/cpu/cpu0/cpufreq/boost)
    local MAX_FREQ=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) / 1000))
    local MIN_FREQ=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) / 1000))
    local CUR_FREQ=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000))
    
    # 新增: 获取硬件真实支持的频率范围
    local HW_MAX_MHZ=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq) / 1000))
    local HW_MIN_MHZ=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq) / 1000))

    if [ "$BOOST_STATE" -eq 1 ]; then
        BOOST_STATUS="开启 (Enabled)"
    else
        BOOST_STATUS="关闭 (Disabled)"
    fi

    echo "调度策略 (Governor): $GOVERNOR"
    echo "睿频状态 (Boost)  : $BOOST_STATUS"
    echo "当前设置范围(Min/Max): ${MIN_FREQ} MHz / ${MAX_FREQ} MHz"
    echo "硬件支持范围(Min/Max): ${HW_MIN_MHZ} MHz / ${HW_MAX_MHZ} MHz"
    echo "当前频率 (Core 0) : ${CUR_FREQ} MHz"
    echo "----------------------------------------"
}

# --- 函数: 设置睿频 (Boost) ---
function set_boost() {
    read -p "你希望 开启(1) 还是 关闭(0) 睿频? [输入 1 或 0]: " choice
    case $choice in
        1)
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/boost; do echo "1" > "$cpu"; done
            echo "✅ 所有核心的睿频已开启。"
            ;;
        0)
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/boost; do echo "0" > "$cpu"; done
            echo "✅ 所有核心的睿频已关闭。"
            ;;
        *)
            echo "❌ 输入无效，操作已取消。"
            ;;
    esac
}

# --- 函数: 设置调度策略 (Governor) ---
function set_governor() {
    local available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
    echo "可用的调度策略: $available_governors"
    read -p "请输入你想要设置的策略名称: " choice

    if [[ " $available_governors " =~ " $choice " ]]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "$choice" > "$cpu"; done
        echo "✅ 所有核心的调度策略已设置为 '$choice'。"
    else
        echo "❌ 无效的策略名称，操作已取消。"
    fi
}

# --- 函数: 设置频率限制 ---
function set_frequency() {
    read -p "你希望设置 最大(max) 还是 最小(min) 频率? [输入 max 或 min]: " type
    
    if [ "$type" != "max" ] && [ "$type" != "min" ]; then
        echo "❌ 输入无效，操作已取消。"
        return
    fi

    read -p "请输入频率数值 (单位: MHz, 例如: 4000): " freq_mhz
    
    if ! [[ "$freq_mhz" =~ ^[0-9]+$ ]]; then
        echo "❌ 频率必须是数字，操作已取消。"
        return
    fi

    # --- 新增: 频率有效性检查 ---
    local freq_khz=$((freq_mhz * 1000))
    local HW_MAX_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
    local HW_MIN_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
    
    if [ "$freq_khz" -le "$HW_MAX_KHZ" ] && [ "$freq_khz" -ge "$HW_MIN_KHZ" ]; then
        # 频率有效，继续执行设置
        local target_file=""
        if [ "$type" == "max" ]; then
            target_file="scaling_max_freq"
        else
            target_file="scaling_min_freq"
        fi
        
        echo "正在将所有核心的 ${type} 频率设置为 ${freq_mhz} MHz..."
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/$target_file; do echo "$freq_khz" > "$cpu"; done
        echo "✅ 设置完成。"
    else
        # 频率无效，报错并取消
        local HW_MAX_MHZ=$((HW_MAX_KHZ / 1000))
        local HW_MIN_MHZ=$((HW_MIN_KHZ / 1000))
        echo "❌ 错误: 频率 ${freq_mhz} MHz 超出硬件支持范围 [${HW_MIN_MHZ} - ${HW_MAX_MHZ}] MHz。"
        echo "操作已取消。"
    fi
}

# --- 主菜单循环 ---
while true; do
    show_current_status
    echo "请选择要执行的操作:"
    echo "  1) 开启 / 关闭睿频 (Boost)"
    echo "  2) 设置调度策略 (Governor)"
    echo "  3) 设置最大 / 最小频率"
    echo "  q) 退出脚本"
    read -p "请输入选项 [1, 2, 3, q]: " main_choice

    case $main_choice in
        1)
            set_boost
            ;;
        2)
            set_governor
            ;;
        3)
            set_frequency
            ;;
        q|Q)
            echo "脚本已退出。"
            exit 0
            ;;
        *)
            echo "❌ 无效选项，请重新输入。"
            ;;
    esac
    echo
    read -p "按回车键继续..."
done
