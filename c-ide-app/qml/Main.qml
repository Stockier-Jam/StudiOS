/*
 * Copyright (C) 2025  Your FullName
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * c-ide-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
    property var openFiles: []  // Holds list of opened file names
    property bool darkMode: true
    property bool fileBarVisible: false

    property color backgroundColor: darkMode ? "#1c1c1c" : "#f0f0f0"
    property color textColor: darkMode ? "white" : "black"
    property color boxColor: darkMode ? "#333333" : "#dddddd"
    property color borderColor: darkMode ? "#666666" : "#aaaaaa"

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

            RowLayout {
                Layout.fillWidth: true
                spacing: units.gu(1)
                Layout.preferredHeight: units.gu(3)

                Button {
                    text: "New"
                    Layout.fillWidth: true
                    onClicked: {
                        editor.text = ""
                        terminalOutput.text = ""
                        terminalInput.text = ""
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

                Button {
                    text: "Insert Functions"
                    Layout.fillWidth: true
                    onClicked: snippetListView.visible = !snippetListView.visible
                }

                Button {
                    text: darkMode ? "Light Mode" : "Dark Mode"
                    Layout.fillWidth: true
                    onClicked: darkMode = !darkMode
                }
            }

            Rectangle {
                color: backgroundColor
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    id: editor
                    anchors.fill: parent
                    wrapMode: TextArea.WrapAnywhere
                    font.family: "monospace"
                    placeholderText: "# Write your Python code here"
                    color: textColor
                    font.pixelSize: 14

                    focus: true
                    Keys.onPressed: function(event){
                        if (event.text === "("){
                            event.accepted = true
                            console.log("theres a (")
                            var pos = editor.cursorPosition
                            editor.insert(pos, "()")
                            editor.cursorPosition = pos + 1
    }
                        if (event.key === Qt.Key_Space) {
                            event.accepted = true;
                            var cursorPos = editor.cursorPosition;
                            editor.insert(cursorPos, " ");
                            editor.cursorPosition = cursorPos + 1;
                        }

                        if (event.text === "'") {
                            event.accepted = true;
                            var cursorPos = editor.cursorPosition;
                            editor.insert(cursorPos, "''");
                            editor.cursorPosition = cursorPos + 1;
                        }

                        if (event.text === "\"") {
                            event.accepted = true;
                            var cursorPos = editor.cursorPosition;
                            editor.insert(cursorPos, "\"\"");
                            editor.cursorPosition = cursorPos + 1;
                        }


                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                event.accepted = true;

                                                var cursorPos = editor.cursorPosition;
                                                var fullText = editor.text;

                                                // Find the start of the current line
                                                var lastNewlineIndex = fullText.lastIndexOf("\n", cursorPos - 1);
                                                var lineStart = (lastNewlineIndex === -1) ? 0 : lastNewlineIndex + 1;
                                                var lineEnd = cursorPos;
                                                var currentLine = fullText.slice(lineStart, lineEnd);

                                                // Get indentation (spaces at the beginning of the current line)
                                                var indentation = currentLine.match(/^(\s*)/)[0];

                                                // Check if current line ends with ":"
                                                var addIndent = currentLine.trim().endsWith(":");

                                                // Optional keywords (Python-style or your own)
                                                var keywords = ["if", "for", "while", "def", "class", "switch", "case"];
                                                var trimmedLine = currentLine.trim();
                                                for (var i = 0; i < keywords.length; i++) {
                                                    if (trimmedLine.startsWith(keywords[i]) && (trimmedLine.endsWith(":")) ){
                                                        addIndent = true;
                                                        break;
                                                    }
                                                    else
                                                        addIndent = false;
                                                }

                                                // Build insert text
                                                var insertText = "\n" + indentation;
                                                if (addIndent) {
                                                    insertText += "    "; // Add extra indent
                                                }

                                                // Update text with new content
                                                var textBefore = fullText.slice(0, cursorPos);
                                                var textAfter = fullText.slice(cursorPos);
                                                editor.text = textBefore + insertText + textAfter;

                                                // Move cursor to after the insert
                                                Qt.callLater(function() {
                                                    editor.cursorPosition = cursorPos + insertText.length;
                                                });
                                            }
                                            if (event.key === Qt.Key_Space) {
                                                event.accepted = true;

                                                cursorPos = editor.cursorPosition;
                                                fullText = editor.text;


                                            }
                                    }





                }








            }

            Rectangle {
                color: backgroundColor
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(7)

                ListView {
                    id: snippetListView
                    visible: false
                    width: parent.width
                    height: parent.height
                    orientation: ListView.Horizontal
                    spacing: units.gu(1)
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

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
                        width: units.gu(18)
                        height: parent.height

                        Rectangle {
                            width: parent.width
                            height: parent.height
                            color: boxColor
                            border.color: borderColor
                            radius: units.gu(0.5)

                            Text {
                                anchors.centerIn: parent
                                text: model.name
                                color: textColor
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    insertSnippet(model.snippet)
                                    snippetListView.visible = false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "white"
            }

            Rectangle {
                id: terminalBox
                color: backgroundColor
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
                            color: textColor
                            wrapMode: Text.Wrap
                            font.family: "monospace"
                            font.pixelSize: 14

                            onTextChanged: {
                                Qt.callLater(function() {
                                    terminalScroll.contentItem.contentY = terminalScroll.contentItem.contentHeight - terminalScroll.height
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
                        color: textColor
                        background: Rectangle { color: boxColor }

                        onAccepted: {
                            python.call("example.run_code_with_input", [editor.text, terminalInput.text], function(result) {
                                terminalOutput.text = result
                            })
                            terminalInput.text = ""
                        }
                    }
                }
            }

            // File Tab Popup
            Rectangle {
                visible: fileBarVisible
                color: backgroundColor
                width: parent.width
                height: units.gu(7)
                z: 999
                border.color: borderColor

                ListView {
                    width: parent.width
                    height: parent.height
                    orientation: ListView.Horizontal
                    spacing: units.gu(1)
                    model: ListModel {
                        Component.onCompleted: {
                            if (openFiles.length === 0 && currentFilePath !== "") {
                                openFiles.push(currentFilePath)  // Prevents duplicates
                            }
                        }

                        ListElement { name: "+" }  // The "+" tab to open new files
                    }

                    delegate: Rectangle {
                        width: units.gu(14)
                        height: parent.height
                        color: boxColor
                        border.color: borderColor
                        radius: units.gu(0.5)

                        Text {
                            anchors.centerIn: parent
                            text: model.name
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (model.name === "+") {
                                    fileDialog.open()  // Open file dialog if "+" tab is clicked
                                } else {
                                    // Switch to clicked file
                                    currentFilePath = model.name
                                }
                                fileBarVisible = false  // Hide the file bar after selection
                            }
                        }
                    }
                }
            }
        }

        Python {
    id: python
    Component.onCompleted: {
        addImportPath(Qt.resolvedUrl('../src/'))
        importModule_sync("example")
    }
    onError: {
        console.log("Python error: " + traceback)
    }
}

// In the FileDialog onAccepted signal:
FileDialog {
    id: fileDialog
    title: "Open Python File"
    nameFilters: ["Python files (*.py)", "All files (*)"]
    onAccepted: {
        currentFilePath = fileUrl.toString().replace("file://", "")
        if (openFiles.indexOf(currentFilePath) === -1) {
            openFiles.push(currentFilePath)
            fileBarVisible = true
        }

        python.call('example.load_file', [currentFilePath], function(result) {
            editor.text = result  // Assign the file content to the editor
        })
    }
}


        FileDialog {
            id: saveDialog
            title: "Save Python File"
            nameFilters: ["Python files (*.py)"]
            selectExisting: false
            onAccepted: {
                currentFilePath = fileUrl.toString().replace("file://", "")
                if (openFiles.indexOf(currentFilePath) === -1) {
                    openFiles.push(currentFilePath)
                    fileBarVisible = true
                }

                python.call('example.save_file', [currentFilePath, editor.text], function(result) {
                    console.log("Save result: " + result)
                    if (result.indexOf("Error") !== -1) {
                        console.error(result)  // Log errors
                    }
                })
            }  // Correct closing brace for the onAccepted function
        }

    }

    function insertSnippet(snippet) {
        var cursorPos = editor.cursorPosition;
        editor.text = editor.text.substring(0, cursorPos) + snippet + editor.text.substring(cursorPos);
        editor.cursorPosition = cursorPos + snippet.length;
    }
}
