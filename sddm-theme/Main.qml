import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#00060e"

    property int sessIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userModel.lastUser !== "" ? userModel.lastUser : "asherverlee"

    Image {
        id: background
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#00060e"
        opacity: 0.3
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.08
        spacing: 4

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#f5f5f0"
            font.family: "Sans"
            font.pixelSize: 20
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
        }
        Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#f5f5f0"
            font.family: "Sans"
            font.pixelSize: 72
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "hh:mm")
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockText.text = Qt.formatTime(new Date(), "hh:mm")
            dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d")
        }
    }

    Column {
        id: loginStack
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        spacing: 14

        Rectangle {
            id: avatarFrame
            width: 96
            height: 96
            radius: 48
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            clip: true
            Image {
                anchors.fill: parent
                source: "avatar.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: userName
            color: "#f5f5f0"
            font.family: "Sans"
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            id: passwordBox
            width: 240
            height: 40
            radius: 20
            color: Qt.rgba(0, 0.02, 0.05, 0.55)
            border.color: passwordInput.activeFocus ? "#fee801" : Qt.rgba(1, 1, 1, 0.25)
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: 8
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: "#f5f5f0"
                font.family: "Sans"
                font.pixelSize: 14
                focus: true
                onAccepted: sddm.login(userName, passwordInput.text, sessIndex)
            }

            Text {
                anchors.centerIn: parent
                text: "Enter Password"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: "Sans"
                font.pixelSize: 13
                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
            }
        }

        Text {
            id: messageText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ff8a8a"
            font.family: "Sans"
            font.pixelSize: 12
            text: ""
        }
    }

    Rectangle {
        id: sessionCornerButton
        width: 32
        height: 32
        radius: 16
        color: Qt.rgba(0, 0.02, 0.05, 0.5)
        border.color: Qt.rgba(1, 1, 1, 0.2)
        border.width: 1
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16

        Text {
            anchors.centerIn: parent
            text: "⚙"
            color: "#39c4b6"
            font.pixelSize: 16
        }
        MouseArea {
            anchors.fill: parent
            onClicked: sessionMenu.visible = !sessionMenu.visible
        }
    }

    Rectangle {
        id: sessionMenu
        visible: false
        width: 220
        height: Math.min(sessionListView.count, 5) * 32 + 16
        color: Qt.rgba(0, 0.02, 0.05, 0.9)
        radius: 10
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1
        anchors.right: parent.right
        anchors.bottom: sessionCornerButton.top
        anchors.bottomMargin: 8
        anchors.margins: 16

        ListView {
            id: sessionListView
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: sessionModel
            delegate: Rectangle {
                width: parent ? parent.width : 200
                height: 32
                color: "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    color: "#f5f5f0"
                    font.family: "Sans"
                    font.pixelSize: 13
                    text: name
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        sessIndex = index
                        sessionMenu.visible = false
                    }
                }
            }
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            messageText.text = "Incorrect password, try again."
            passwordInput.text = ""
        }
        onLoginSucceeded: {
            messageText.text = ""
        }
    }
}
