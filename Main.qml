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
    readonly property real  dimOp:  config.dimOpacity !== undefined ? parseFloat(config.dimOpacity) : 0.55
    readonly property real  blurR:  config.blurRadius !== undefined ? parseFloat(config.blurRadius) : 24

    // geometria espelhando o Hyprland
    readonly property int radius: 10
    readonly property int borderW: 2

    // Com o renderer de software o MultiEffect (shaders) nao desenha nada:
    // sem esta guarda o wallpaper e o relogio sumiriam por completo.
    readonly property bool swRender: GraphicsInfo.api === GraphicsInfo.Software

    // estado do formulario
    property string msgText: ""
    property bool busy: false

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
        visible: root.swRender && status === Image.Ready
    }

    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: root.blurR
        visible: !root.swRender && bg.status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: ctp.mantle
        opacity: root.dimOp
    }

    // =====================================================
    //  Relogio
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
        anchors.bottomMargin: 64
        spacing: 6

        // sombra suave: garante leitura sobre areas claras do wallpaper
        // (desligada no renderer de software, senao a layer nao desenha nada)
        layer.enabled: !root.swRender
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
            font.pixelSize: 84
            font.weight: Font.Light
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: now.value.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
            color: ctp.subtext0
            font.family: "Noto Sans"
            font.pixelSize: 16
        }
    }

    // =====================================================
    //  Campo reutilizavel
    // =====================================================
    component Field: Rectangle {
        id: fld
        property alias input: ti
        property string placeholder: ""
        property bool isPassword: false
        property Item nextFocus: null
        property Item prevFocus: null
        signal accepted()

        width: 288
        height: 40
        radius: root.radius
        color: Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.55)
        border.width: root.borderW
        border.color: ti.activeFocus ? root.accent : ctp.surface1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
            id: ti
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: fld.isPassword ? 38 : 14
            verticalAlignment: TextInput.AlignVCenter
            color: ctp.text
            font.family: "Noto Sans"
            font.pixelSize: 14
            selectByMouse: true
            clip: true
            echoMode: fld.isPassword ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            passwordMaskDelay: 0
            onAccepted: fld.accepted()

            // navegacao por Tab / Shift+Tab entre os campos
            activeFocusOnTab: true
            KeyNavigation.tab: fld.nextFocus
            KeyNavigation.backtab: fld.prevFocus
            KeyNavigation.priority: KeyNavigation.BeforeItem

            // limpa a mensagem de erro assim que o usuario volta a digitar
            onTextChanged: if (root.msgText.length > 0) root.msgText = ""

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
    //  Icones de energia desenhados (sem depender de fonte)
    // =====================================================
    component PowerIcon: Canvas {
        id: ico
        property string kind: "power"   // power | reboot | suspend
        property color iconColor: "#ffffff"
        width: 18
        height: 18
        antialiasing: true

        onIconColorChanged: requestPaint()
        onKindChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var w = width, h = height
            var cx = w / 2, cy = h / 2
            var r = Math.min(w, h) / 2 - 2.5
            ctx.strokeStyle = iconColor
            ctx.fillStyle = iconColor
            ctx.lineWidth = 1.6
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (kind === "power") {
                // arco aberto no topo + haste vertical
                ctx.beginPath()
                ctx.arc(cx, cy + 0.6, r, -Math.PI / 2 + 0.62, -Math.PI / 2 - 0.62)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, cy - r - 0.4)
                ctx.lineTo(cx, cy + 0.2)
                ctx.stroke()
            } else if (kind === "reboot") {
                // arco aberto + seta tangente na ponta final
                var start = -Math.PI / 2 + 0.85
                var end = -Math.PI / 2 - 0.10
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.stroke()
                var ex = cx + r * Math.cos(end)
                var ey = cy + r * Math.sin(end)
                var tx = -Math.sin(end), ty = Math.cos(end)   // tangente (sentido do traco)
                var nx = Math.cos(end),  ny = Math.sin(end)   // radial
                var s = 3.1
                ctx.beginPath()
                ctx.moveTo(ex + tx * s * 1.15, ey + ty * s * 1.15)
                ctx.lineTo(ex + nx * s - tx * s * 0.35, ey + ny * s - ty * s * 0.35)
                ctx.lineTo(ex - nx * s - tx * s * 0.35, ey - ny * s - ty * s * 0.35)
                ctx.closePath()
                ctx.fill()
            } else {
                // lua crescente em contorno, para casar com o peso dos outros dois.
                // Tracamos o arco externo e o arco do disco que "morde" a lua,
                // ligando-os exatamente nos dois pontos de intersecao.
                var ox = r * 0.55, oy = -r * 0.30, r2 = r * 0.94
                var d = Math.sqrt(ox * ox + oy * oy)
                var aa = (d * d - r2 * r2 + r * r) / (2 * d)
                var hh = Math.sqrt(Math.max(r * r - aa * aa, 0))
                var mx = ox * aa / d, my = oy * aa / d
                var p1x = mx - hh * oy / d, p1y = my + hh * ox / d
                var p2x = mx + hh * oy / d, p2y = my - hh * ox / d
                var phi = Math.atan2(-oy, -ox)   // direcao do lado cheio da lua

                function within(a1, a2, t) {
                    var TAU = Math.PI * 2
                    var span = ((a2 - a1) % TAU + TAU) % TAU
                    var off = ((t - a1) % TAU + TAU) % TAU
                    return off <= span
                }

                var t1 = Math.atan2(p1y, p1x)
                var t2 = Math.atan2(p2y, p2x)
                var u1 = Math.atan2(p2y - oy, p2x - ox)
                var u2 = Math.atan2(p1y - oy, p1x - ox)

                ctx.beginPath()
                ctx.arc(cx, cy, r, t1, t2, !within(t1, t2, phi))
                ctx.arc(cx + ox, cy + oy, r2, u1, u2, !within(u1, u2, phi))
                ctx.closePath()
                ctx.stroke()
            }
        }
    }

    component PowerBtn: Rectangle {
        id: pbtn
        property string kind: "power"
        property string label: ""
        property color hoverColor: ctp.text
        signal activated()

        width: 34
        height: 34
        radius: root.radius
        color: pArea.containsMouse
               ? Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.75)
               : "transparent"
        border.width: 1
        border.color: pArea.containsMouse
                      ? Qt.rgba(pbtn.hoverColor.r, pbtn.hoverColor.g, pbtn.hoverColor.b, 0.35)
                      : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        scale: pArea.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        PowerIcon {
            anchors.centerIn: parent
            kind: pbtn.kind
            iconColor: pArea.containsMouse ? pbtn.hoverColor : ctp.overlay0
            Behavior on iconColor { ColorAnimation { duration: 120 } }
        }

        // rotulo que aparece no hover
        Rectangle {
            id: tip
            visible: pArea.containsMouse
            anchors.bottom: parent.top
            anchors.bottomMargin: 8
            // centralizado no botao, mas sem deixar o rotulo vazar da tela
            // (o botao de desligar fica colado na borda direita)
            x: {
                var centered = (pbtn.width - tip.width) / 2
                var globalX = pbtn.mapToItem(root, 0, 0).x + centered
                var maxX = root.width - tip.width - 10
                return globalX > maxX ? centered - (globalX - maxX) : centered
            }
            width: lbl.implicitWidth + 16
            height: 24
            radius: 6
            color: ctp.mantle
            border.width: 1
            border.color: ctp.surface1
            Text {
                id: lbl
                anchors.centerIn: parent
                text: pbtn.label
                color: ctp.subtext0
                font.family: "Noto Sans"
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: pArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pbtn.activated()
        }
    }

    // =====================================================
    //  Formulario
    // =====================================================
    Column {
        id: form
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0   // avatar ocupa o espaco que sobrava acima
        spacing: 10

        // ---- avatar do usuario, recortado na silhueta do Arch ----
        Item {
            id: avatar
            width: 160
            height: 168            // silhueta + folga antes do primeiro campo
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property string user: userField.input.text
            // tentadas em ordem; a primeira que carregar vence. o icone
            // generico do SDDM fica de fora de proposito: recortado na
            // silhueta ele vira um borrao, e a inicial resolve melhor
            // com o campo vazio a lista fica vazia: sem a guarda, o segundo
            // caminho viraria ".face.icon", que e justamente o icone generico
            readonly property var sources: user.length === 0 ? [] : [
                "file:///var/lib/AccountsService/icons/" + user,
                "file:///usr/share/sddm/faces/" + user + ".face.icon"
            ]
            property int srcIndex: 0
            onUserChanged: srcIndex = 0

            // silhueta do Arch: serve de fundo quando nao ha foto e, ao mesmo
            // tempo, de mascara para recortar a foto (o MultiEffect usa o alfa)
            Image {
                id: archShape
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: 160
                height: 160
                source: "arch-mask.png"
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 320
                sourceSize.height: 320
                smooth: true
                opacity: avImg.status === Image.Ready ? 1.0 : 0.55
                layer.enabled: true

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 30   // dentro do corpo do "A"
                    visible: avImg.status !== Image.Ready
                    text: avatar.user.length > 0 ? avatar.user.charAt(0).toUpperCase() : "?"
                    color: ctp.subtext0
                    font.family: "Noto Sans"
                    font.pixelSize: 34
                    font.weight: Font.Light
                }
            }

            Image {
                id: avImg
                anchors.fill: archShape
                source: avatar.srcIndex < avatar.sources.length
                        ? avatar.sources[avatar.srcIndex] : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 320
                sourceSize.height: 320
                asynchronous: true
                cache: true
                // no renderer de software o MultiEffect nao desenha: sobra a
                // silhueta com a inicial, em vez de o avatar sumir
                visible: false
                onStatusChanged: {
                    if (status === Image.Error && avatar.srcIndex < avatar.sources.length)
                        avatar.srcIndex++
                }
            }

            MultiEffect {
                anchors.fill: archShape
                source: avImg
                maskEnabled: true
                maskSource: archShape
                visible: !root.swRender && avImg.status === Image.Ready
            }

            // contorno acompanhando a silhueta, por cima do recorte;
            // pintado em tempo de execucao, em vez de cor fixa no PNG
            Image {
                anchors.fill: archShape
                source: "arch-outline.png"
                opacity: 0.70
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 320
                sourceSize.height: 320
                smooth: true
                visible: !root.swRender
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: ctp.subtext0
                }
            }
        }

        Field {
            id: userField
            placeholder: "usuário"
            input.text: userModel.lastUser ? userModel.lastUser : ""
            nextFocus: passField.input
            prevFocus: passField.input
            onAccepted: passField.input.forceActiveFocus()
        }

        Field {
            id: passField
            placeholder: "senha"
            isPassword: true
            nextFocus: userField.input
            prevFocus: userField.input
            onAccepted: root.doLogin()

            // botao ->
            Rectangle {
                width: 26; height: 26; radius: 7
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                color: submitArea.containsMouse
                       ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: root.accent
                    font.family: "Noto Sans"
                    font.pixelSize: 16
                }
                MouseArea {
                    id: submitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLogin()
                }
            }
        }

        // mensagem de erro / caps lock
        Item {
            width: 288
            height: 18
            Text {
                id: msg
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.msgText
                color: ctp.red
                font.family: "Noto Sans"
                font.pixelSize: 12
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⇪ Caps Lock ativo"
                color: ctp.yellow
                font.family: "Noto Sans"
                font.pixelSize: 12
                visible: keyboard.capsLock && root.msgText.length === 0
            }
        }
    }

    // fecha o seletor de sessao ao clicar em qualquer outro lugar
    MouseArea {
        anchors.fill: parent
        z: 9
        visible: sessionList.visible
        onClicked: sessionList.visible = false
    }

    // =====================================================
    //  Rodape: seletor de sessao + energia
    // =====================================================
    Item {
        z: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 26
        height: 36

        // ---- seletor de sessao ----
        Rectangle {
            id: sessionBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: sessionRow.width + 20
            height: 28
            radius: 8
            color: sessionArea.containsMouse || sessionList.visible
                   ? Qt.rgba(ctp.surface0.r, ctp.surface0.g, ctp.surface0.b, 0.65)
                   : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            property int currentIndex: sessionModel.lastIndex
            // nome preenchido pelos delegates, sem depender do numero do role
            property string currentName: ""

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 7
                Text {
                    text: sessionBtn.currentName !== "" ? sessionBtn.currentName : "Sessão"
                    color: ctp.subtext0
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                }
                Text {
                    text: sessionList.visible ? "▴" : "▾"
                    color: ctp.overlay0
                    font.family: "Noto Sans"
                    font.pixelSize: 11
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
                width: 230
                height: sessionCol.height + 10
                anchors.left: parent.left
                anchors.bottom: parent.top
                anchors.bottomMargin: 8
                radius: 10
                color: ctp.mantle
                border.width: 1
                border.color: ctp.surface1

                Column {
                    id: sessionCol
                    y: 5
                    width: parent.width
                    Repeater {
                        model: sessionModel
                        delegate: Rectangle {
                            width: sessionCol.width
                            height: 30
                            color: itemArea.containsMouse
                                   ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                                   : "transparent"

                            Component.onCompleted: {
                                if (index === sessionBtn.currentIndex)
                                    sessionBtn.currentName = model.name
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 12
                                text: model.name
                                color: index === sessionBtn.currentIndex ? root.accent : ctp.text
                                font.family: "Noto Sans"
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionBtn.currentIndex = index
                                    sessionBtn.currentName = model.name
                                    sessionList.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- botoes de energia ----
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            PowerBtn {
                kind: "suspend"
                label: "Suspender"
                visible: sddm.canSuspend
                onActivated: sddm.suspend()
            }
            PowerBtn {
                kind: "reboot"
                label: "Reiniciar"
                visible: sddm.canReboot
                onActivated: sddm.reboot()
            }
            PowerBtn {
                kind: "power"
                label: "Desligar"
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
        if (root.busy)
            return
        root.busy = true
        root.msgText = ""
        sddm.login(userField.input.text, passField.input.text, sessionBtn.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.msgText = "Falha na autenticação"
            passField.input.text = ""
            passField.input.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.busy = true
        }
        function onInformationMessage(message) {
            root.busy = false
            root.msgText = message
        }
    }

    Component.onCompleted: {
        if (userField.input.text.length > 0)
            passField.input.forceActiveFocus()
        else
            userField.input.forceActiveFocus()
    }
}
