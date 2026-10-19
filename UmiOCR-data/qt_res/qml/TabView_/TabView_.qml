// =============================================================
// =============== 水平标签组件（即标签按钮位于顶部） =============
// =============================================================

import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../TabBar_"

Rectangle {
    
    anchors.fill: parent

    // 标签页容器
    Rectangle {
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: theme.bgColor

        Component.onCompleted: {
            qmlapp.tab.page.pagesNest.parent = this
        }
    }

    // 标签栏容器
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: size_.hTabBarHeight
        // 垂直渐变：顶部略亮，底部略深
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.lighter(theme.tabBarColor, 1.06) }
            GradientStop { position: 1.0; color: theme.tabBarColor }
        }
        clip: true

        // 底部柔和阴影线
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: theme.coverColor2 }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        HTabBar { }
    }
}