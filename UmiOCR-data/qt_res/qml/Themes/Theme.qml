// =========================================
// =============== 样式的基类 ===============
// =========================================

import QtQuick 2.15

Item {
    // 主题名称
    property string themeTitle: "Unknow theme"

    // ========================= 【颜色】 =========================

    property color tabBarColor // 标签栏
    property color bgColor // 背景
    property color textColor // 主要文字
    property color subTextColor // 次要文字
    property color faintTextColor // 弱文字（占位、提示）
    property color yesColor // 允许、成功
    property color noColor // 禁止、失败
    property color specialBgColor // 特殊背景，弹窗确认按钮
    property color specialTextColor // 特殊前景，文字、图标
    property color sideBarColor // 侧边导航栏背景
    property color cardColor // 卡片背景
    property color panelColor // 卡内嵌层背景（工具栏、选项卡栏、输入控件槽），与画布同族的暖调浅层
    property color accentColor // 品牌强调色
    property color accentSoftColor // 强调色浅底（选中态）
    // 叠加层颜色，半透明，从浅到深
    property color coverColor1 // 大部分需要突出的背景
    property color coverColor2 // 按钮悬停
    property color coverColor3 // 阴影
    property color coverColor4 // 按钮按下

    // 必要的键
    property var keys: [
        "themeTitle",
        "tabBarColor",
        "bgColor",
        "textColor",
        "subTextColor",
        "faintTextColor",
        "yesColor",
        "noColor",
        "specialBgColor",
        "specialTextColor",
        "sideBarColor",
        "cardColor",
        "panelColor",
        "accentColor",
        "accentSoftColor",
        "coverColor1",
        "coverColor2",
        "coverColor3",
        "coverColor4",
    ]
    // 默认主题 / 当前读入的主题配置
    property var all: {
        // 默认主题
        "Default Light": {
            "themeTitle": qsTr("珍珠白"),
            "tabBarColor": "#EFEDE7",
            "bgColor": "#F8F7F4",
            "textColor": "#1C1B1A",
            "subTextColor": "#6E6A63",
            "faintTextColor": "#A39E95",
            "yesColor": "#2F9E68",
            "noColor": "#C74841",
            "specialBgColor": "#3563E9",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#EFEDE7",
            "cardColor": "#F6F0E3",
            "panelColor": "#F4F0E9",
            "accentColor": "#3563E9",
            "accentSoftColor": "#E9EFFD",
            "coverColor1": "#0B000000",
            "coverColor2": "#14000000",
            "coverColor3": "#1F000000",
            "coverColor4": "#2B000000",
        },
        "Default Dark": {
            "themeTitle": qsTr("云墨黑"),
            "tabBarColor": "#232120",
            "bgColor": "#1C1B1A",
            "textColor": "#F5F3EE",
            "subTextColor": "#A39E95",
            "faintTextColor": "#6E6A63",
            "yesColor": "#4ADE80",
            "noColor": "#F87171",
            "specialBgColor": "#3563E9",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#242220",
            "cardColor": "#282623",
            "panelColor": "#302D29",
            "accentColor": "#5B82F0",
            "accentSoftColor": "#2E3B5E",
            "coverColor1": "#14FFFFFF",
            "coverColor2": "#22FFFFFF",
            "coverColor3": "#2EFFFFFF",
            "coverColor4": "#3DFFFFFF",
        },
        // 抄： https://github.com/altercation/solarized
        "Solarized Light": {
            "themeTitle": "Solarized Light",
            "tabBarColor": "#d9d2c2",
            "bgColor": "#fdf6e3",
            "textColor": "#586e75",
            "subTextColor": "#839496",
            "faintTextColor": "#93A1A1",
            "yesColor": "#48985d",
            "noColor": "#e51d09",
            "specialBgColor": "#FCF9BE",
            "specialTextColor": "#C58940",
            "sideBarColor": "#E9E2CE",
            "cardColor": "#FEFBF2",
            "panelColor": "#EEE7D4",
            "accentColor": "#268BD2",
            "accentSoftColor": "#D8E8F2",
            "coverColor1": "#11000000",
            "coverColor2": "#22000000",
            "coverColor3": "#33000000",
            "coverColor4": "#55000000"
        },
        "Solarized Dark": {
            "themeTitle": "Solarized Dark",
            "tabBarColor": "#004052",
            "bgColor": "#002b36",
            "textColor": "#93a1a1",
            "subTextColor": "#657b83",
            "faintTextColor": "#4A6570",
            "yesColor": "#6EFC39",
            "noColor": "#f14c4c",
            "specialBgColor": "#00517D",
            "specialTextColor": "#00BFFF",
            "sideBarColor": "#073642",
            "cardColor": "#0A3A46",
            "panelColor": "#0E4551",
            "accentColor": "#268BD2",
            "accentSoftColor": "#0E4A5C",
            "coverColor1": "#19FFFFFF",
            "coverColor2": "#29FFFFFF",
            "coverColor3": "#44FFFFFF",
            "coverColor4": "#55FFFFFF"
        },
        // 抄： https://github.com/Fndroid/clash_for_windows_pkg
        "Cyberpunk": {
            "themeTitle": qsTr("赛博朋克"),
            "tabBarColor": "#084A5A",
            "bgColor": "#136377",
            "textColor": "#FCEC0C",
            "subTextColor": "#CF9F0F",
            "faintTextColor": "#3E8CA0",
            "yesColor": "#6EFC39",
            "noColor": "#FF5E5E",
            "specialBgColor": "#00517D",
            "specialTextColor": "#00BFFF",
            "sideBarColor": "#0E4F5F",
            "cardColor": "#1A7186",
            "panelColor": "#1F7E93",
            "accentColor": "#FCEC0C",
            "accentSoftColor": "#1F5A68",
            "coverColor1": "#33000000",
            "coverColor2": "#29FFFFFF",
            "coverColor3": "#44FFFFFF",
            "coverColor4": "#55FFFFFF"
        },
        // Umi-OCR 美化主题
        "Aurora Blue": {
            "themeTitle": qsTr("极光蓝"),
            "tabBarColor": "#E8F1FB",
            "bgColor": "#F7FBFF",
            "textColor": "#1F3A5F",
            "subTextColor": "#5A7BA0",
            "faintTextColor": "#8AA5C4",
            "yesColor": "#22C55E",
            "noColor": "#F43F5E",
            "specialBgColor": "#3B82F6",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#E8F1FB",
            "cardColor": "#FFFFFF",
            "panelColor": "#E4EEF9",
            "accentColor": "#3B82F6",
            "accentSoftColor": "#DCEAFB",
            "coverColor1": "#11294B7A",
            "coverColor2": "#22294B7A",
            "coverColor3": "#33294B7A",
            "coverColor4": "#55294B7A"
        },
        "Sunset Orange": {
            "themeTitle": qsTr("暮光橙"),
            "tabBarColor": "#FDEBE3",
            "bgColor": "#FFF8F4",
            "textColor": "#5C3A29",
            "subTextColor": "#A0745F",
            "faintTextColor": "#C9A48E",
            "yesColor": "#22C55E",
            "noColor": "#EF4444",
            "specialBgColor": "#F97316",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#FDEBE3",
            "cardColor": "#FFFFFF",
            "panelColor": "#FBEFE6",
            "accentColor": "#F97316",
            "accentSoftColor": "#FDE3D3",
            "coverColor1": "#11945321",
            "coverColor2": "#22945321",
            "coverColor3": "#33945321",
            "coverColor4": "#55945321"
        },
        "Aurora Purple": {
            "themeTitle": qsTr("极光紫"),
            "tabBarColor": "#2A2440",
            "bgColor": "#1E1B2E",
            "textColor": "#EDE9FE",
            "subTextColor": "#A99CCB",
            "faintTextColor": "#7C6FA8",
            "yesColor": "#34D399",
            "noColor": "#FB7185",
            "specialBgColor": "#8B5CF6",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#251F3A",
            "cardColor": "#282344",
            "panelColor": "#322B52",
            "accentColor": "#8B5CF6",
            "accentSoftColor": "#3A3260",
            "coverColor1": "#22FFFFFF",
            "coverColor2": "#33FFFFFF",
            "coverColor3": "#44FFFFFF",
            "coverColor4": "#55FFFFFF"
        },
        "Forest Night": {
            "themeTitle": qsTr("森夜绿"),
            "tabBarColor": "#1E2E24",
            "bgColor": "#16241C",
            "textColor": "#E3F6E8",
            "subTextColor": "#92B89E",
            "faintTextColor": "#6E9381",
            "yesColor": "#4ADE80",
            "noColor": "#F87171",
            "specialBgColor": "#10B981",
            "specialTextColor": "#FFFFFF",
            "sideBarColor": "#1B2A21",
            "cardColor": "#1D2F25",
            "panelColor": "#24382C",
            "accentColor": "#10B981",
            "accentSoftColor": "#23443A",
            "coverColor1": "#22FFFFFF",
            "coverColor2": "#33FFFFFF",
            "coverColor3": "#44FFFFFF",
            "coverColor4": "#55FFFFFF"
        }
    }
    // 主题控制器
    property ThemeManager manager: ThemeManager{}

    // ========================= 【字体】 =========================

    // 主要UI文字字体，内容可控，可以用裁切的ttf
    property string fontFamily: "Noto Sans SC"
    // 数据显示文字字体，内容不可控，用兼容性好的系统字体
    property string dataFontFamily: "Noto Sans SC"
}
