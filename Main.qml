import QtQuick 2.15
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: ctp.base

    // ---- Catppuccin Mocha ----
    QtObject {
        id: ctp
        readonly property color base:     "#1e1e2e"
        readonly property color mantle:   "#181825"
        readonly property color crust:    "#11111b"
        readonly property color surface0: "#313244"
        readonly property color surface1: "#45475a"
        readonly property color overlay0: "#6c7086"
        readonly property color text:     "#cdd6f4"
        readonly property color subtext0: "#a6adc8"
        readonly property color blue:     "#89b4fa"
        readonly property color red:      "#f38ba8"
        readonly property color yellow:   "#f9e2af"
    }

    // ---- valores do theme.conf, com fallback ----
    readonly property color accent: config.accent ? config.accent : ctp.blue
    readonly property real  dimOp:  config.dimOpacity ? parseFloat(config.dimOpacity) : 0.55
    readonly property real  blurR:  config.blurRadius ? parseFloat(config.blurRadius) : 24

    // geometria espelhando o Hyprland
    readonly property int radius: 12
    readonly property int borderW: 2

    // =====================================================
    //  Fundo: wallpaper + blur + escurecimento
    // =====================================================
    Image {
        id: bg
        anchors.fill: parent
        source: config.background ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: root.blurR
        visible: bg.status === Image.Ready
    }

    // escurecimento — apenas quando há wallpaper
    Rectangle {
        anchors.fill: parent
        color: ctp.mantle
        opacity: root.dimOp
        visible: bg.status === Image.Ready
    }

    // fallback — gradiente Mocha quando não há wallpaper configurado
    Rectangle {
        anchors.fill: parent
        visible: bg.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0.0; color: ctp.mantle }
            GradientStop { position: 0.55; color: ctp.base }
            GradientStop { position: 1.0; color: ctp.crust }
        }
    }

    // =====================================================
    //  Relógio
    // =====================================================
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: now.value = new Date()
    }
    QtObject { id: now; property var value: new Date() }

    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: form.top
        anchors.bottomMargin: 72
        spacing: 6

        // sombra suave: garante leitura sobre áreas claras do wallpaper
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#101018"
            shadowBlur: 0.9
            shadowOpacity: 0.55
            shadowVerticalOffset: 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(now.value, "HH:mm")
            color: ctp.text
            font.family: "Noto Sans"
            font.pixelSize: 88
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: now.value.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
            color: ctp.subtext0
            font.family: "Noto Sans"
            font.pixelSize: 18
        }
    }

    // =====================================================
    //  Campo reutilizável
    // =====================================================
    component Field: Rectangle {
        id: fld
        property alias input: ti
        property string placeholder: ""
        property bool isPassword: false
        signal accepted()

        width: 340
        height: 46
        radius: root.radius
        color: Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.55)
        border.width: root.borderW
        border.color: ti.activeFocus ? root.accent : ctp.surface1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
            id: ti
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: fld.isPassword ? 44 : 16
            verticalAlignment: TextInput.AlignVCenter
            color: ctp.text
            font.family: "Noto Sans"
            font.pixelSize: 16
            selectByMouse: true
            clip: true
            echoMode: fld.isPassword ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            passwordMaskDelay: 0
            onAccepted: fld.accepted()

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: fld.placeholder
                color: ctp.overlay0
                font: parent.font
                visible: parent.text.length === 0
            }
        }
    }

    // =====================================================
    //  Formulário
    // =====================================================
    Column {
        id: form
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 40
        spacing: 12

        Field {
            id: userField
            placeholder: "usuário"
            input.text: userModel.lastUser ? userModel.lastUser : ""
            onAccepted: passField.input.forceActiveFocus()
        }

        Field {
            id: passField
            placeholder: "senha"
            isPassword: true
            onAccepted: doLogin()

            // botão →
            Rectangle {
                width: 30; height: 30; radius: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: submitArea.containsMouse
                       ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: root.accent
                    font.pixelSize: 18
                }
                MouseArea {
                    id: submitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }

        // mensagem de erro / caps lock
        Item {
            width: 340
            height: 18
            Text {
                id: msg
                anchors.horizontalCenter: parent.horizontalCenter
                color: ctp.red
                font.family: "Noto Sans"
                font.pixelSize: 13
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⇪ Caps Lock ativo"
                color: ctp.yellow
                font.family: "Noto Sans"
                font.pixelSize: 13
                visible: keyboard.capsLock && msg.text.length === 0
            }
        }
    }

    // =====================================================
    //  Rodapé: seletor de sessão + energia
    // =====================================================
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        height: 40

        // ---- seletor de sessão ----
        Rectangle {
            id: sessionBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: sessionRow.width + 28
            height: 36
            radius: root.radius
            color: sessionArea.containsMouse || sessionList.visible
                   ? Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.65)
                   : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            property int currentIndex: sessionModel.lastIndex

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: sessionModel.data(
                              sessionModel.index(sessionBtn.currentIndex, 0),
                              Qt.UserRole + 4) || "Sessão"
                    color: ctp.subtext0
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                }
                Text {
                    text: sessionList.visible ? "▴" : "▾"
                    color: ctp.overlay0
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionList.visible = !sessionList.visible
            }

            // lista aberta
            Rectangle {
                id: sessionList
                visible: false
                width: 260
                height: sessionCol.height + 12
                anchors.left: parent.left
                anchors.bottom: parent.top
                anchors.bottomMargin: 8
                radius: root.radius
                color: ctp.mantle
                border.width: 1
                border.color: ctp.surface1

                Column {
                    id: sessionCol
                    y: 6
                    width: parent.width
                    Repeater {
                        model: sessionModel
                        delegate: Rectangle {
                            width: parent.width
                            height: 36
                            color: itemArea.containsMouse
                                   ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                                   : "transparent"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 14
                                text: model.name
                                color: index === sessionBtn.currentIndex ? root.accent : ctp.text
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionBtn.currentIndex = index
                                    sessionList.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- botões de energia ----
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            component PowerBtn: Rectangle {
                property string glyph: ""
                property color hoverColor: ctp.text
                signal activated()
                width: 36; height: 36; radius: root.radius
                color: pArea.containsMouse
                       ? Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.65)
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: glyph
                    color: pArea.containsMouse ? hoverColor : ctp.overlay0
                    font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    id: pArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: activated()
                }
            }

            PowerBtn {
                glyph: "⏾"
                visible: sddm.canSuspend
                onActivated: sddm.suspend()
            }
            PowerBtn {
                glyph: "⟳"
                visible: sddm.canReboot
                onActivated: sddm.reboot()
            }
            PowerBtn {
                glyph: "⏻"
                hoverColor: ctp.red
                visible: sddm.canPowerOff
                onActivated: sddm.powerOff()
            }
        }
    }

    // =====================================================
    //  Login
    // =====================================================
    function doLogin() {
        msg.text = ""
        sddm.login(userField.input.text, passField.input.text, sessionBtn.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            msg.text = "Falha na autenticação"
            passField.input.text = ""
            passField.input.forceActiveFocus()
        }
        function onInformationMessage(message) {
            msg.text = message
        }
    }

    Component.onCompleted: {
        if (userField.input.text.length > 0)
            passField.input.forceActiveFocus()
        else
            userField.input.forceActiveFocus()
    }
}
