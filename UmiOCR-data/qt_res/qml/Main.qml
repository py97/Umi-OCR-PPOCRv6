// =====================================
// =============== 主窗口 ===============
// =====================================

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import Qt.labs.settings 1.1
import MissionConnector 1.0 // Python任务连接器
import KeyMouseConnector 1.0 // 键盘/鼠标连接器
import UtilsConnector 1.0 // 通用连接器

import "Themes"
import "TabView_"
import "Configs"
import "EventBus"
import "Popup_"
import "MainWindow"
import "ImageManager"

Window {
    id: mainWindowRoot
    visibility: Window.Hidden // 在 MainWindowManager 中启用可见性
    // 无边框窗口：去除系统标题栏，改由软件自绘 macOS 风格窗口控制（红黄绿）与拖拽
    property bool isMainWindowTop: false
    // 无边框顶层窗口：
    // - FramelessWindowHint 实现无边框
    // - WindowSystemMenuHint + WindowMinimizeButtonHint + WindowMaximizeButtonHint
    //   让 Qt 将其视为普通应用窗口并向 Windows 任务栏注册按钮，
    //   否则纯 Frameless 窗口不会出现在任务栏（Win11 24H2 实测）
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | (isMainWindowTop?Qt.WindowStaysOnTopHint:0)

    width: 1240
    height: 800
    minimumWidth: 720
    minimumHeight: 480
    color: "#00000000"
    title: UmiAbout.fullname
    
    // ========================= 【控制】 =========================

    // 全局样式，通过 theme 来访问
    property Theme theme: Theme{}
    // 全局尺寸，通过 size_ 来访问
    property Size_ size_: Size_{}

    // 全局单例，通过 qmlapp. 来访问
    Item {
        id: qmlapp

        // 普通全局单例
        TabViewManager { id: tab }  // 标签页逻辑管理器
        ImageManager { id: imageManager }  // 图片管理器
        MissionConnector { id: msnConnector } // 任务连接器
        PubSub { id: pubSub } // 全局事件发布/订阅
        KeyMouseConnector { id:keyMouse } // 鼠标/键盘
        UtilsConnector { id:utilsConnector } // 通用连接器
        AsynFilesLoader { id:asynFilesLoader } // 异步文件加载器

        // 必须先初始化的单例，onCompleted顺序从下往上
        MainWindowManager { id:mainWin; mainWin:mainWindowRoot } // 主窗管理
        SystemTray { id:systemTray } // 系统托盘
        PopupManager { id: popup }  // 弹窗管理器
        GlobalConfigs { id: globalConfigs }  // 全局设置

        property alias asynFilesLoader: asynFilesLoader
        property alias imageManager: imageManager
        property alias globalConfigs: globalConfigs
        property alias tab: tab
        property alias popup: popup
        property alias msnConnector: msnConnector
        property alias pubSub: pubSub
        property alias keyMouse: keyMouse
        property alias utilsConnector: utilsConnector
        property alias systemTray: systemTray
        property alias mainWin: mainWin
        property bool enabledEffect: false // 全局是否启用动画

        Component.onCompleted: {
            // 延时加载标签页
            Qt.callLater(()=>{
                qmlapp.tab.init()
            })
        }
    }

    onClosing: { // 窗口关闭事件
        close.accepted = false // 阻止原生事件
        mainWin.close() // 调用主窗管理器的关闭
    }

    // ========================= 【布局】 =========================

    // 主窗口的容器，兼做边框
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: "#00000000"
        radius: size_.windowRadius // 窗口圆角
        focus: true

        // Esc 关闭窗口
        Keys.enabled: true
        Keys.onEscapePressed: {
            // 如果设置了关闭窗口后隐藏到托盘区，则关闭窗口
            if(qmlapp.globalConfigs.getValue("window.closeWin2Hide")) {
                mainWindowRoot.visibility = Window.Hidden
            }
            // 否则，最小化窗口，以兼容没有托盘区的平台
            else {
                mainWindowRoot.visibility = Window.Minimized
            }
            // TODO： Deiban 平台测试！
        }

        // 为了防止主窗启动不显示时，内容的宽度初始值为0，先让内容挂到固定宽度的Item下
        Item {
            width: 1240
            height: 800
            property alias mainWidth: mainContainer.width
            onMainWidthChanged: { // 主窗恢复显示时，再让内容挂回主窗
                if(mainUI.parent !== mainContainer)
                    mainUI.parent = mainContainer
            }

            // 主窗口的内容
            Rectangle {
                id: mainUI
                anchors.fill: parent
                anchors.margins: 0 // 透明边框宽度

                // 设计稿：暖中性画布纯色
                color: theme.bgColor
                radius: size_.windowRadius // 窗口圆角

                // 侧边导航主界面
                SideNavShell { }

                // 裁切子元素，并应用圆角
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: mainUI.width
                        height: mainUI.height
                        radius: size_.windowRadius
                    }
                }
            }

        }

        // ============== 无边框窗口：边缘缩放控制 ==============
        Item {
            anchors.fill: parent
            MouseArea { // 左
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 4; cursorShape: Qt.SizeHorCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.LeftEdge)
            }
            MouseArea { // 右
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 4; cursorShape: Qt.SizeHorCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.RightEdge)
            }
            MouseArea { // 上
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 4; cursorShape: Qt.SizeVerCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.TopEdge)
            }
            MouseArea { // 下
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                height: 4; cursorShape: Qt.SizeVerCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.BottomEdge)
            }
            MouseArea { // 左上角
                anchors.left: parent.left; anchors.top: parent.top
                width: 10; height: 10; cursorShape: Qt.SizeFDiagCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
            }
            MouseArea { // 右上角
                anchors.right: parent.right; anchors.top: parent.top
                width: 10; height: 10; cursorShape: Qt.SizeBDiagCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.TopEdge | Qt.RightEdge)
            }
            MouseArea { // 左下角
                anchors.left: parent.left; anchors.bottom: parent.bottom
                width: 10; height: 10; cursorShape: Qt.SizeBDiagCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
            }
            MouseArea { // 右下角
                anchors.right: parent.right; anchors.bottom: parent.bottom
                width: 10; height: 10; cursorShape: Qt.SizeFDiagCursor
                onPressed: mainWindowRoot.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
            }
        }
    }
}