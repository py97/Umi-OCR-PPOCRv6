// ==============================================
// =============== 功能页：全局设置 ===============
// ==============================================

import QtQuick 2.15
import QtQuick.Controls 2.15

import ".."
import "../../Widgets"

TabPage {
    id: tabPage
    property QtObject confComp: qmlapp.globalConfigs.panelComponent
    property var groupList: []
    onShowPage: {
        groupList = confComp.getGroupList()
    }

    Component.onCompleted: {
        const tips = qsTr("1. 关于快捷键、OCR语言等选项，请在各个功能页中进行设置。\n2. 勾选上方“高级”按钮，可以显示更多进阶选项。")
        qmlapp.popup.messageMemory("globalConfigsKey", qsTr("小贴士"), tips)
    }

    // 单栏平铺：设置卡片直接铺在内容画布上（设计稿样式）
    Item {
        anchors.fill: parent

        // 顶部控制栏（重置 / 高级）
        Item {
            id: ctrlBarHost
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: size_.line * 1.8
            z: 1
        }

        // 配置面板容器
        Item {
            anchors.top: ctrlBarHost.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Component.onCompleted: { // 将全局设置UI的父级重定向过来
                // 就算本页面删除，全局UI也不会被删，只会丢失父级
                confComp.parent = this
                confComp.ctrlBar.parent = ctrlBarHost
                confComp.ctrlBar.anchors.fill = ctrlBarHost
            }
        }
    }

    // 字体设置面板
    FontPanel {
        anchors.fill: parent
        z: 10
    }
}
