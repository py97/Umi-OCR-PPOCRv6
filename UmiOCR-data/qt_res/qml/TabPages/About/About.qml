// ===================================================
// =============== 功能页：关于 ===============
// ===================================================

import QtQuick 2.15
import QtQuick.Controls 2.15

import ".."
import "../../Widgets"

TabPage {
    id: tabPage

    ScrollView {
        anchors.fill: parent
        anchors.margins: size_.spacing * 2
        contentWidth: width
        clip: true

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: size_.spacing * 2
            clip: true

            // ==================== 主卡片：Logo + 产品名 + 版本 ====================

            Panel {
                anchors.left: parent.left
                anchors.right: parent.right
                height: mainCol.height + size_.spacing * 4

                Column {
                    id: mainCol
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: size_.spacing

                    // Logo（团子图标）
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: size_.line * 4
                        height: width
                        fillMode: Image.PreserveAspectFit
                        source: "../../../images/icons/dango_right.png"
                    }
                    // 产品名
                    Text_ {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Umi-OCR"
                        font.bold: true
                        font.pixelSize: size_.largeText + 6
                        color: theme.textColor
                    }
                    // 优化版标识
                    Text_ {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PP-OCRv6 优化版"
                        font.bold: true
                        font.pixelSize: size_.smallText
                        color: theme.accentColor
                    }
                    // 版本 + 描述
                    Text_ {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("当前版本") + " " + UmiAbout.version.string + "  ·  " + qsTr("开源、免费的离线OCR软件")
                        font.pixelSize: size_.smallText
                        color: theme.subTextColor
                    }
                }
            }

            // ==================== 三张链接卡 ====================

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: size_.spacing * 2

                Repeater {
                    model: [
                        { text: qsTr("官方网站"), url: UmiAbout.url.home,
                          desc: qsTr("项目主页与使用文档"), icon: "nav_about" },
                        { text: qsTr("插件拓展"), url: UmiAbout.url.plugins,
                          desc: qsTr("拓展插件与工具合集"), icon: "nav_images" },
                        { text: qsTr("问题反馈"), url: UmiAbout.url.issue,
                          desc: qsTr("提交异常与功能建议"), icon: "nav_settings" },
                    ]

                    // 链接卡
                    Rectangle {
                        width: (parent.width - size_.spacing * 4) / 3
                        height: size_.line * 6
                        radius: size_.panelRadius
                        color: theme.cardColor
                        border.width: 1
                        border.color: linkMa.containsMouse ? theme.accentColor : theme.coverColor3

                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - size_.spacing * 2
                            spacing: size_.smallSpacing

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: size_.smallSpacing
                                Icon_ {
                                    icon: modelData.icon
                                    width: size_.smallLine
                                    height: size_.smallLine
                                    color: theme.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text_ {
                                    text: modelData.text
                                    font.bold: true
                                    font.pixelSize: size_.text
                                    color: theme.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Text_ {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.desc
                                font.pixelSize: size_.smallText
                                color: theme.subTextColor
                            }
                        }
                        MouseArea {
                            id: linkMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            // ==================== 项目信息卡 ====================

            Panel {
                anchors.left: parent.left
                anchors.right: parent.right
                height: infoCol.height + size_.spacing * 2

                Column {
                    id: infoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: size_.spacing
                    spacing: size_.smallSpacing

                    Text_ {
                        text: qsTr("项目信息")
                        font.bold: true
                        font.pixelSize: size_.text
                        color: theme.textColor
                        height: size_.line * 2
                        verticalAlignment: Text.AlignVCenter
                    }
                    UrlList {
                        title: qsTr("发布地址")
                        urlList: [
                            {text:"Github", url:"https://github.com/hiroi-sora/Umi-OCR/releases/latest"},
                            {text:"Source Forge", url:"https://sourceforge.net/projects/umi-ocr"},
                            {text:"Lanzou (蓝奏云)", url:"https://hiroi-sora.lanzoul.com/s/umi-ocr"},
                        ]
                    }
                    UrlList {
                        title: qsTr("许可协议")
                        urlList: [
                            {text:UmiAbout.license.type, url:UmiAbout.license.url},
                        ]
                    }
                    UrlList {
                        title: qsTr("作者")
                        urlList: (() => {
                            let as = UmiAbout.authors, t = []
                            for(const i in as)
                                t.push({ text: as[i].name, url: as[i].url, })
                            return t
                        })()
                    }
                    UrlList {
                        title: qsTr("优化版维护者")
                        urlList: [
                            { text: UmiAbout.optimizer.name, url: UmiAbout.optimizer.url },
                        ]
                    }
                    UrlList {
                        title: qsTr("优化版仓库")
                        urlList: [
                            { text: "GitHub", url: UmiAbout.optimizer.url },
                        ]
                    }
                    Repeater {
                        model: UmiAbout.localization

                        UrlList {
                            anchors.leftMargin: size_.line * 2
                            textSize: size_.smallText
                            title: qsTr("译者") + " · " + UmiAbout.localization[index].language
                            urlList: (() => {
                                let as = UmiAbout.localization[index].translators, t = []
                                for(const i in as)
                                    t.push({ text: as[i].name, url: as[i].url, })
                                return t
                            })()
                        }
                    }
                }
            }

            // ==================== 运行环境信息 ====================

            Panel {
                anchors.left: parent.left
                anchors.right: parent.right
                height: envCol.height + size_.spacing * 2

                Column {
                    id: envCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: size_.spacing
                    spacing: size_.smallSpacing

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Text_ {
                            font.pixelSize: size_.smallText
                            height: size_.smallLine + size_.spacing*2
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("运行环境信息（如需请求协助，请提供给开发者）")
                            color: theme.subTextColor
                        }
                        Button_ {
                            height: size_.smallLine + size_.spacing*2
                            textSize: size_.smallText
                            text_: qsTr("复制")
                            textColor_: theme.yesColor
                            onClicked: {
                                const info = JSON.stringify(UmiAbout.app, null, 2)
                                qmlapp.utilsConnector.copyText(info)
                            }
                        }
                    }
                    Text_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: size_.line * 2
                        wrapMode: Text.WordWrap
                        font.pixelSize: size_.smallText
                        color: theme.faintTextColor
                        text: JSON.stringify(UmiAbout.app, null, 2)
                    }
                }
            }

            Item {width: 1; height: size_.smallSpacing}
        }
    }
}
