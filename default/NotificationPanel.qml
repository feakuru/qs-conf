import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications

Scope {
    NotificationServer {
        id: notifServer
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        inlineReplySupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
            notif.receivedAt = new Date();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: function () {
            notifServer.trackedNotifications.values.map(notif => {
                if ((new Date() - notif.receivedAt) / 1000 > Math.max(5, notif.expireTimeout)) {
                    notif.dismiss();
                }
            });
        }
    }

    PanelWindow {
        id: notifsWindow
        focusable: false
        aboveWindows: false
        Component.onCompleted: {
            // magic 1 to prevent stealing focus on first open
            notifsWindow.aboveWindows = true;
        }
        onVisibleChanged: {
            // magic 2 to prevent stealing focus on first open
            if (visible) {
                let focusTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", notifsWindow);
                focusTimer.interval = 200;
                focusTimer.triggered.connect(() => {
                    notifsWindow.focusable = true;
                });
                focusTimer.start();
            } else {
                notifsWindow.focusable = false;
            }
        }
        anchors {
            bottom: true
            right: true
        }
        margins {
            right: 50
            bottom: 50
        }
        color: "transparent"
        implicitWidth: Math.max(200, Screen.desktopAvailableWidth / 5)
        implicitHeight: Math.min(notifServer.trackedNotifications.values.length * 270 || 1, Screen.desktopAvailableHeight / 2)
        visible: notifServer.trackedNotifications.values.length > 0

        ColumnLayout {
            id: notifsColumn
            anchors.fill: parent

            Repeater {
                id: notifsRepeater
                model: notifServer.trackedNotifications
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    color: AppConstants.focusedBgColor
                    radius: 10

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        border.color: "black"
                        border.width: 3
                        radius: 5
                        width: 30
                        height: 30
                        color: closeButton.containsMouse ? "gray" : "transparent"
                        StyledText {
                            font.pixelSize: 18
                            font.bold: true
                            text: "x"
                        }
                        MouseArea {
                            id: closeButton
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modelData.dismiss();
                            }
                        }
                    }

                    ColumnLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Image {
                                Layout.margins: 10
                                Layout.minimumWidth: 32
                                Layout.minimumHeight: 32
                                source: `image://icon/${modelData.appIcon}`
                                sourceSize.width: this.width
                                sourceSize.height: this.height
                                mipmap: true
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.minimumHeight: 22
                                Layout.margins: 10
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "FiraCode Nerd Font"
                                horizontalAlignment: Text.AlignHCenter
                                color: "white"
                                text: `${modelData.summary} | ${modelData.appName} `
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Image {
                                Layout.maximumWidth: 96
                                Layout.maximumHeight: 96
                                Layout.leftMargin: 30
                                Layout.rightMargin: 10
                                source: modelData.image
                                sourceSize.width: this.width
                                sourceSize.height: this.height
                                mipmap: true
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                anchors.centerIn: null
                                font.pixelSize: 20
                                text: modelData.body
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                color: "transparent"
                                Layout.fillWidth: true
                                Layout.minimumHeight: 30
                                TextField {
                                    visible: modelData.hasInlineReply
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    font.pixelSize: 18
                                    font.family: "FiraCode Nerd Font"
                                    placeholderText: modelData.inlineReplyPlaceholder
                                    onAccepted: {
                                        modelData.sendInlineReply(this.text);
                                    }
                                }
                            }
                            Repeater {
                                model: modelData.actions
                                delegate: Rectangle {
                                    Layout.margins: 10
                                    Layout.minimumWidth: modelData.text.length * 17
                                    Layout.minimumHeight: 28
                                    border.width: 3
                                    border.color: "black"
                                    radius: 5
                                    color: actionMouseArea.containsMouse ? "gray" : "transparent"
                                    StyledText {
                                        font.pixelSize: 18
                                        text: modelData.text
                                    }
                                    MouseArea {
                                        id: actionMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            modelData.invoke();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
