// ==============================================
// =============== 侧边导航项 ===============
// ==============================================

import QtQuick 2.15

import "../Widgets"

Rectangle {
    id: navItem

    // 可调参数
    property string icon: "" // 图标名（images/icons/ 下的 svg）
    property string title: "" // 导航标题
    property bool checked: false // 是否为当前选中页
    signal clicked()

    height: size_.navItemHeight
    radius: size_.btnRadius + 2
    color: checked ? theme.accentSoftColor : (
        navMouse.containsMouse ? theme.coverColor2 : "#00000000"
    )

    // 选中态左侧竖条
    Rectangle {
        visible: navItem.checked
        width: 3
        height: parent.height * 0.45
        radius: 1.5
        color: theme.accentColor
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: size_.spacing + 6
        anchors.rightMargin: size_.spacing
        spacing: size_.spacing + 1

        // 图标
        Icon_ {
            icon: navItem.icon
            color: navItem.checked ? theme.accentColor : theme.subTextColor
            width: size_.navIconSize
            height: size_.navIconSize
            anchors.verticalCenter: parent.verticalCenter
        }
        // 标题
        Text_ {
            text: navItem.title
            color: navItem.checked ? theme.accentColor : theme.textColor
            font.bold: navItem.checked
            font.pixelSize: size_.smallText + 1
            elide: Text.ElideRight
            width: parent.width - size_.navIconSize - size_.spacing - 1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: navItem.clicked()
    }
}
