import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'c-ide-app.yourname'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property string currentFilePath: ""

    Page {
        id: main
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('C-IDE')
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: units.gu(1)

            // Toolbar Row Layout
            RowLayout {
                Layout.fillWidth: true
                spacing: units.gu(1)
                Layout.preferredHeight: units.gu(3)

                Button {
                    text: "New"
                    Layout.fillWidth: true
                    onClicked: {
                        editor.text = ""
                        currentFilePath = ""
                    }
                }

                Button {
                    text: "Open"
                    Layout.fillWidth: true
                    onClicked: fileDialog.open()
                }

                Button {
                    text: "Save"
                    Layout.fillWidth: true
                    onClicked: {
                        if (currentFilePath !== "") {
                            python.call('example.save_file', [currentFilePath, editor.text])
                        } else {
                            saveDialog.open()
                        }
                    }
                }

                Button {
                    text: "Run"
                    Layout.fillWidth: true
                    onClicked: {
                        python.call("example.run_code_with_input", [editor.text, terminalInput.text], function(result) {
                            terminalOutput.text = result
                        })
                    }
                }

                // Button to toggle snippet list visibility
                Button {
                    text: "Insert Functions"
                    Layout.fillWidth: true
                    onClicked: {
                        snippetListView.visible = !snippetListView.visible
                    }
                }
            }

            // Code Editor Section
            Rectangle {
                color: "#1c1c1c"
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    id: editor
                    anchors.fill: parent
                    wrapMode: TextArea.WrapAnywhere
                    font.family: "monospace"
                    placeholderText: "# Write your Python code here"
                    color: "white"
                    font.pixelSize: 14
                }
            }

            // Snippet List Section (Initially hidden)
            Rectangle {
                color: "#1c1c1c"
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(7) // Adjusted height

                ListView {
                    id: snippetListView
                    anchors.fill: parent
                    visible: false // Initially hidden
                    model: ListModel {
                        ListElement { name: "If Statement"; snippet: "if condition:\n    # your code here\nelse:\n    # your code here" }
                        ListElement { name: "Function"; snippet: "def function_name():\n    # your code here" }
                        ListElement { name: "While Loop"; snippet: "while condition:\n    # your code here" }
                        ListElement { name: "For Loop"; snippet: "for i in range(10):\n    # your code here" }
                        ListElement { name: "Class"; snippet: "class ClassName:\n    def __init__(self):\n        # your code here" }
                        ListElement { name: "Try-Except"; snippet: "try:\n    # your code here\nexcept Exception as e:\n    print(e)" }
                        ListElement { name: "Lambda Function"; snippet: "my_function = lambda x: x + 1\nresult = my_function(5)" }
                        ListElement { name: "Import Statement"; snippet: "import os\nimport sys" }
                        ListElement { name: "Docstring Template"; snippet: "\"\"\"\n    Description of function\n    Args:\n        param1 (type): Description\n    Returns:\n        return_type: Description\n    \"\"\"" }
                    }
                    delegate: Item {
                        width: snippetListView.width
                        height: units.gu(3)

                        Rectangle {
                            width: parent.width
                            height: parent.height
                            color: "#333333"
                            border.color: "#666666"

                            Text {
                                anchors.centerIn: parent
                                text: model.name
                                color: "white"
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    insertSnippet(model.snippet)
                                    snippetListView.visible = false // Hide the list after selection
                                }
                            }
                        }
                    }
                }
            }

            // Terminal Section
            Rectangle {
                id: terminalBox
                color: "#1c1c1c"
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(20)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: units.gu(0.5)

                    ScrollView {
                        id: terminalScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Text {
                            id: terminalOutput
                            text: ""
                            color: "white"
                            wrapMode: Text.Wrap
                            font.family: "monospace"
                            font.pixelSize: 14

                            onTextChanged: {
                                Qt.callLater(function() {
                                    terminalScroll.contentItem.contentY = terminalScroll.contentItem.contentHeight
                                })
                            }
                        }
                    }

                    TextField {
                        id: terminalInput
                        Layout.fillWidth: true
                        placeholderText: "Enter command"
                        font.family: "monospace"
                        font.pixelSize: 14
                        color: "white"
                        background: Rectangle { color: "#333333" }

                        onAccepted: {
                            python.call("example.run_code_with_input", [editor.text, terminalInput.text], function(result) {
                                terminalOutput.text = result
                            })
                            terminalInput.text = ""
                        }
                    }
                }
            }

            // White Separator Line Above the Terminal Output Box
            Rectangle {
                width: parent.width
                height: 1
                color: "white"
                anchors.top: terminalBox.top // Correct anchor to position the white line above the terminal output
            }
        }

        // Python bridge
        Python {
            id: python
            Component.onCompleted: {
                addImportPath(Qt.resolvedUrl('../src/')) // location of python backend file
                importModule_sync("example")             // import functions from python backend file
            }
            onError: {
                console.log("Python error: " + traceback)
            }
        }

        // Open File Dialog
        FileDialog {
            id: fileDialog
            title: "Open Python File"
            nameFilters: ["Python files (*.py)", "All files (*)"]
            onAccepted: {
                currentFilePath = fileUrl.toString().replace("file://", "")
                python.call('example.load_file', [currentFilePath], function(result) {
                    editor.text = result
                })
            }
        }

        // Save File Dialog
        FileDialog {
            id: saveDialog
            title: "Save Python File"
            nameFilters: ["Python files (*.py)"]
            selectExisting: false
            onAccepted: {
                currentFilePath = fileUrl.toString().replace("file://", "")
                python.call('example.save_file', [currentFilePath, editor.text])
            }
        }
    }

    // Helper function to insert snippets into the editor
    function insertSnippet(snippet) {
        var cursorPos = editor.cursorPosition; // Get the current cursor position
        editor.text = editor.text.substring(0, cursorPos) + snippet + editor.text.substring(cursorPos);
        editor.cursorPosition = cursorPos + snippet.length; // Move the cursor after the inserted snippet
    }
}


