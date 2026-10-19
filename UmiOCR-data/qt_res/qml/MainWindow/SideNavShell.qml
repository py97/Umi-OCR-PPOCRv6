// =====================================================
// =============== 新主界面：侧边导航 Shell ===============
// =====================================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

import "../Widgets"

Item {
    id: shell
    anchors.fill: parent

    // 当前展示页面对应的 infoList 下标
    property int currentInfoIndex: 1

    /* 导航分组。infoIndex 对应 TabPages/PagesManager.qml 的 infoList：
       1 截图OCR  2 批量OCR  3 批量文档  4 二维码  5 全局设置  6 关于 */
    property var navGroups: [
        {
            title: qsTr("功能"),
            items: [
                { infoIndex: 1, icon: "nav_screenshot", title: qsTr("截图OCR"),
                  subtitle: qsTr("屏幕截图，快捷转文字，也支持粘贴图片") },
                { infoIndex: 2, icon: "nav_images", title: qsTr("批量OCR"),
                  subtitle: qsTr("导入本地图片或文件夹，批量转换文字") },
                { infoIndex: 3, icon: "nav_doc", title: qsTr("批量文档"),
                  subtitle: qsTr("批量导入文档，提取文字或生成可搜索PDF") },
                { infoIndex: 4, icon: "nav_qr", title: qsTr("二维码"),
                  subtitle: qsTr("识别或生成二维码、条形码") },
            ]
        },
        {
            title: qsTr("其他"),
            items: [
                { infoIndex: 5, icon: "nav_settings", title: qsTr("全局设置"),
                  subtitle: qsTr("调节全局设置项，对所有页面生效") },
                { infoIndex: 6, icon: "nav_about", title: qsTr("关于"),
                  subtitle: qsTr("版本信息、项目链接与运行环境") },
            ]
        },
    ]

    // ========================= 【页面切换】 =========================

    // 导航到指定页面：已创建则直接展示，未创建则新建后展示。页面常驻不销毁，保留各页状态。
    function navTo(infoIndex) {
        const list = qmlapp.tab.pageList
        for(let i = 0; i < list.length; i++) {
            if(list[i].infoIndex === infoIndex) {
                qmlapp.tab.showTabPage(i)
                return
            }
        }
        qmlapp.tab.addTabPage(-1, infoIndex)
        qmlapp.tab.showTabPage(-1)
    }

    // 页面自身（如热键触发）切换展示页时，同步导航选中态
    Connections {
        target: qmlapp.tab
        function onShowPageIndexChanged() {
            const idx = qmlapp.tab.showPageIndex
            const list = qmlapp.tab.pageList
            if(idx >= 0 && idx < list.length) {
                const ii = list[idx].infoIndex
                if(shell.currentInfoIndex !== ii)
                    shell.currentInfoIndex = ii
            }
        }
    }

    // 取导航项信息
    function itemOf(infoIndex) {
        for(const g of shell.navGroups)
            for(const it of g.items)
                if(it.infoIndex === infoIndex)
                    return it
        return null
    }
    // 页头标题
    function titleOf(infoIndex) {
        const it = itemOf(infoIndex)
        if(it) return it.title
        const info = qmlapp.tab.infoList[infoIndex]
        return info ? info.title : ""
    }
    // 页头副标题
    function subtitleOf(infoIndex) {
        const it = itemOf(infoIndex)
        if(it) return it.subtitle
        const info = qmlapp.tab.infoList[infoIndex]
        return info ? info.intro.replace(/#/g, "").replace(/\n+/g, " ").trim() : ""
    }
    // 引擎说明文本
    function engineText() {
        let be = ""
        try {
            be = qmlapp.globalConfigs.getValue("ocr.win_x64_SimdPaddleOCR.backend") || ""
        } catch(e) {}
        if(be === "vulkan") be = "Vulkan"
        else if(be === "cpu") be = "CPU"
        else be = "自动" // auto 或未设置
        return qsTr("PP-OCRv6 · Simd · ") + be
    }
    // 取指定页面对应的 QML 实例
    function pageObjOf(infoIndex) {
        const list = qmlapp.tab.pageList
        for(let i = 0; i < list.length; i++) {
            if(list[i].infoIndex === infoIndex)
                return list[i].obj
        }
        return null
    }
    // 截图热键显示文本，如 "Alt+S"
    function hotkeyLabel() {
        let hk = ""
        try {
            const obj = pageObjOf(1)
            if(obj && obj.configsComp)
                hk = obj.configsComp.getValue("hotkey.screenshot") || ""
        } catch(e) {}
        if(!hk) return "Alt+S"
        return hk.split("+").map(s => s.charAt(0).toUpperCase() + s.slice(1)).join("+")
    }
    // 当前主题键（配置未加载完成时返回空串）
    function curThemeKey() {
        const v = qmlapp.globalConfigs.getValue("ui.theme")
        return v ? v : ""
    }

    // ========================= 【布局】 =========================

    Row {
        anchors.fill: parent
        spacing: 0

        // =============== 左侧：侧边导航栏 ===============
        Rectangle {
            id: sideBar
            width: size_.sideBarWidth
            height: parent.height
            color: theme.sideBarColor

            // 右侧与内容区的分界细线
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: theme.coverColor3
            }

            Column {
                anchors.fill: parent
                anchors.margins: size_.spacing * 1.4
                    spacing: size_.spacing * 1.2

                    // =============== Logo 区（含窗口拖拽区） ===============
                Item {
                    id: logoRow
                    width: parent.width
                    height: size_.navItemHeight + size_.smallSpacing

                    // 拖拽移动窗口
                    MouseArea {
                        anchors.fill: parent
                        onPressed: Window.window.startSystemMove()
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: size_.spacing + 2

                        // 品牌色圆角块 + 团子
                        Rectangle {
                            width: size_.line * 2.25
                            height: width
                            radius: width * 0.28
                            color: theme.accentColor
                            Image {
                                anchors.centerIn: parent
                                width: parent.width * 0.74
                                height: width
                                fillMode: Image.PreserveAspectFit
                                source: "../../images/icons/logo_dango.svg"
                            }
                        }
                        // 产品名 + 引擎
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text_ {
                                text: "Umi-OCR"
                                font.bold: true
                                font.pixelSize: size_.text + 1
                                color: theme.textColor
                            }
                            Text_ {
                                text: qsTr("PP-OCRv6 智能引擎")
                                font.pixelSize: size_.smallText
                                color: theme.subTextColor
                            }
                        }
                    }
                }

                // =============== 导航组（可滚动） ===============
                ScrollView {
                    width: parent.width
                    height: parent.height - logoRow.height - themeCard.height
                        - size_.spacing * 1.2 * 2 - size_.spacing * 1.4 * 2
                    clip: true

                    Column {
                        width: parent.width
                        spacing: size_.spacing * 1.2

                        Repeater {
                            model: shell.navGroups

                            Column {
                                width: parent.width
                                spacing: size_.smallSpacing

                                // 组标题
                                Text_ {
                                    text: modelData.title
                                    font.pixelSize: size_.smallText
                                    color: theme.faintTextColor
                                    leftPadding: size_.spacing + 6
                                    height: size_.smallLine + size_.smallSpacing * 2
                                    verticalAlignment: Text.AlignVCenter
                                }
                                // 组内导航项
                                Repeater {
                                    model: modelData.items
                                    NavItem {
                                        width: parent.width
                                        icon: modelData.icon
                                        title: modelData.title
                                        checked: shell.currentInfoIndex === modelData.infoIndex
                                        onClicked: shell.navTo(modelData.infoIndex)
                                    }
                                }
                                // 组间分隔（仅功能组后）
                                Rectangle {
                                    visible: index === 0
                                    width: parent.width
                                    height: 1
                                    color: theme.coverColor3
                                }
                            }
                        }
                    }
                }

                // =============== 底部：外观切换卡 ===============
                Rectangle {
                    id: themeCard
                    width: parent.width
                    height: size_.navItemHeight * 0.82 + size_.smallLine + size_.smallSpacing * 2 + size_.spacing * 2
                    radius: size_.baseRadius + 2
                    color: theme.cardColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: size_.spacing
                        spacing: size_.smallSpacing

                        Text_ {
                            text: qsTr("外观")
                            font.pixelSize: size_.smallText
                            color: theme.faintTextColor
                            height: size_.smallLine
                        }

                        // 浅色 / 深色 分段控制
                        Rectangle {
                            width: parent.width
                            height: size_.navItemHeight * 0.82
                            radius: size_.btnRadius
                            color: theme.panelColor

                            Row {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 0

                                Repeater {
                                    model: [
                                        { key: "Default Light", icon: "nav_sun", label: qsTr("浅色") },
                                        { key: "Default Dark", icon: "nav_moon", label: qsTr("深色") },
                                    ]

                                    Rectangle {
                                        property string curTheme: shell.curThemeKey()
                                        property bool isCur: curTheme !== "" && curTheme === modelData.key

                                        width: parent.width / 2
                                        height: parent.height
                                        radius: size_.btnRadius - 2
                                        color: isCur ? theme.cardColor : "#00000000"

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: size_.smallSpacing
                                            Icon_ {
                                                icon: modelData.icon
                                                color: isCur ? theme.accentColor : theme.subTextColor
                                                width: size_.smallLine
                                                height: size_.smallLine
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text_ {
                                                text: modelData.label
                                                font.pixelSize: size_.smallText
                                                font.bold: isCur
                                                color: isCur ? theme.accentColor : theme.subTextColor
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: qmlapp.globalConfigs.setValue("ui.theme", modelData.key)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =============== 右侧：内容区 ===============
        Item {
            width: parent.width - sideBar.width
            height: parent.height

            // =============== 页头 ===============
            Item {
                id: pageHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: size_.pageHeaderHeight + size_.line + size_.smallSpacing * 2

                // =============== 顶部条：窗口控制按钮 + 拖拽区 ===============
                Item {
                    id: headerTopStrip
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: size_.line + size_.smallSpacing * 2

                    // 拖拽移动窗口（按钮以外的空白区域）
                    MouseArea {
                        anchors.fill: parent
                        onPressed: Window.window.startSystemMove()
                    }

                    // 窗口控制按钮组（右侧）：最小化 / 最大化·还原 / 关闭
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: size_.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: [
                                { act: "min",   icon: "dash" },
                                { act: "max",   icon: "full_screen" },
                                { act: "close", icon: "win_close" },
                            ]
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: {
                                    if(!ma.containsMouse)
                                        return "#00000000"
                                    if(modelData.act === "close")
                                        return Qt.rgba(theme.noColor.r, theme.noColor.g, theme.noColor.b, 0.14)
                                    return theme.coverColor2
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon_ {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    // 最大化按钮在窗口最大化后切换为“还原”图标
                                    icon: modelData.act === "max"
                                        ? (Window.window.visibility === Window.Maximized ? "win_restore" : modelData.icon)
                                        : modelData.icon
                                    color: {
                                        if(!ma.containsMouse)
                                            return theme.subTextColor
                                        if(modelData.act === "close")
                                            return theme.noColor
                                        return theme.textColor
                                    }
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(modelData.act === "close") qmlapp.mainWin.close()
                                        else if(modelData.act === "min") Window.window.showMinimized()
                                        else {
                                            if(Window.window.visibility === Window.Maximized) Window.window.showNormal()
                                            else Window.window.showMaximized()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 拖拽移动窗口（标题与右侧按钮以外的区域）
                MouseArea {
                    anchors.top: headerTopStrip.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    onPressed: Window.window.startSystemMove()
                }

                // 标题 + 副标题
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: size_.spacing * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: size_.spacing * 1.4
                    spacing: 2
                    Text_ {
                        text: shell.titleOf(shell.currentInfoIndex)
                        font.bold: true
                        font.pixelSize: size_.largeText + 2
                        color: theme.textColor
                    }
                    Text_ {
                        text: shell.subtitleOf(shell.currentInfoIndex)
                        font.pixelSize: size_.smallText
                        color: theme.subTextColor
                    }
                }

                // 右侧：引擎芯片 + 页面操作按钮（设计稿样式）
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: size_.spacing * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: size_.spacing * 1.4
                    spacing: size_.spacing

                    // =============== 引擎芯片 ===============
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: size_.line * 2
                        width: chipRow.implicitWidth + size_.spacing * 1.8
                        radius: height / 2
                        color: theme.cardColor
                        border.width: 1
                        border.color: theme.coverColor3

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: size_.smallSpacing
                            leftPadding: size_.spacing * 0.9
                            rightPadding: size_.spacing * 0.9
                            // 运行状态点
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: theme.yesColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text_ {
                                text: shell.engineText()
                                font.pixelSize: size_.smallText
                                color: theme.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // =============== 粘贴按钮（次按钮，仅截图OCR页） ===============
                    Rectangle {
                        visible: shell.currentInfoIndex === 1
                        anchors.verticalCenter: parent.verticalCenter
                        height: size_.line * 2.1
                        width: pasteRow.implicitWidth + size_.spacing * 3
                        radius: size_.btnRadius
                        color: pasteBtnMa.containsMouse ? theme.coverColor2 : theme.cardColor
                        border.width: 1
                        border.color: theme.coverColor3

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: pasteRow
                            anchors.centerIn: parent
                            spacing: size_.smallSpacing
                            leftPadding: size_.spacing
                            rightPadding: size_.spacing
                            Icon_ {
                                icon: "nav_paste"
                                width: size_.smallLine + 2
                                height: size_.smallLine + 2
                                color: theme.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text_ {
                                text: qsTr("粘贴")
                                font.pixelSize: size_.smallText
                                color: theme.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            id: pasteBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const obj = shell.pageObjOf(1)
                                if(obj) obj.paste()
                            }
                        }
                    }

                    // =============== 截图按钮（主按钮，内嵌热键芯片，仅截图OCR页） ===============
                    Rectangle {
                        visible: shell.currentInfoIndex === 1
                        anchors.verticalCenter: parent.verticalCenter
                        height: size_.line * 2.1
                        width: shotRow.implicitWidth + size_.spacing * 3
                        radius: size_.btnRadius
                        color: shotBtnMa.containsMouse ? Qt.darker(theme.accentColor, 1.12) : theme.accentColor

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: shotRow
                            anchors.centerIn: parent
                            spacing: size_.spacing
                            leftPadding: size_.spacing * 1.2
                            rightPadding: size_.spacing * 0.8
                            Icon_ {
                                icon: "nav_screenshot"
                                width: size_.smallLine + 2
                                height: size_.smallLine + 2
                                color: theme.specialTextColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text_ {
                                text: qsTr("截图")
                                font.pixelSize: size_.smallText
                                font.bold: true
                                color: theme.specialTextColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            // 内嵌热键芯片
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: size_.smallLine + 6
                                width: hotkeyChipTxt.implicitWidth + size_.spacing
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.22)
                                Text_ {
                                    id: hotkeyChipTxt
                                    anchors.centerIn: parent
                                    text: shell.hotkeyLabel()
                                    font.pixelSize: size_.smallText - 1
                                    font.bold: true
                                    color: theme.specialTextColor
                                }
                            }
                        }
                        MouseArea {
                            id: shotBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const obj = shell.pageObjOf(1)
                                if(obj) obj.screenshot()
                            }
                        }
                    }
                }
            }

            // 页头底部分界线
            Rectangle {
                anchors.top: pageHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.coverColor3
            }

            // =============== 页面巢（PagesManager 的页组件挂载处） ===============
            Item {
                id: pageHost
                anchors.top: pageHeader.bottom
                anchors.topMargin: size_.spacing * 2
                anchors.bottomMargin: size_.spacing * 2
                anchors.leftMargin: size_.spacing * 2
                anchors.rightMargin: size_.spacing * 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                Component.onCompleted: {
                    // 将页面管理器的巢挂载到内容区
                    qmlapp.tab.page.pagesNest.parent = pageHost
                }
            }
        }
    }
}
