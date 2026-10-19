// ===========================================
// =============== 组件尺寸相关 ===============
// ===========================================

import QtQuick 2.15

Item {
    // ========================= 【尺寸】 =========================

    // 全局缩放值，适配分辨率
    property real scale: 1

    // 行高
    // 主要文字
    property int line: 16 * scale
    // 较小的文字
    property int smallLine: 13 * scale
    // 较大的文字
    property int largeLine: 20 * scale

    // 文字缩放值
    property real textScale: 1 // 由下列 languageScale 控制
    // 主要文字大小
    property int text: line * textScale
    // 较小的文字大小
    property int smallText: smallLine * textScale
    // 较大的文字大小
    property int largeText: largeLine * textScale

    // 窗口圆角
    property real windowRadius: 10 * scale
    // 基础圆角
    property real baseRadius: 8 * scale
    // 按钮圆角
    property real btnRadius: baseRadius
    // 面板圆角（设计稿：卡片 12px）
    property real panelRadius: 12 * scale

    // 水平标签栏高度
    property real hTabBarHeight: line * 1.8

    // 侧边导航栏宽度
    property real sideBarWidth: 232 * scale
    // 侧边导航图标尺寸
    property real navIconSize: line * 1.25
    // 侧边导航项高度
    property real navItemHeight: line * 2.6
    // 内容页头高度
    property real pageHeaderHeight: line * 3.6

    // 常用间距（页面级边距取 spacing*2 = 20）
    property real spacing: 10 * scale
    // 小间距
    property real smallSpacing: 8 * scale

    // 语言缩放系数
    // 在相同的行高内，有些语言经过缩放可以表现更好。如英文可以比汉字的字号更小。
    // 通过在翻译文件中定义 languageScale 可以单独修改这种语言的缩放。
    property string languageScale: qsTr("1.0")
    
    Component.onCompleted: {
        const s = parseFloat(languageScale)
        if(!isNaN(s)) {
            textScale = s
        }
        else {
            console.warn("语言缩放系数无法应用：", languageScale)
        }
    }
}