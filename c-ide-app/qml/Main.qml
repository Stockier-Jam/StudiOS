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

    Page {
        id:main
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('C-IDE')
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: units.gu(1)

            // Toolbar
            RowLayout {
                Layout.fillWidth: true
                spacing: units.gu(1)

                Button {
                    text: "New"
                    onClicked: {
                        editor.text = ""
                        currentFilePath = ""
                    }
                }
                Button {
                    text: "Open"
                    onClicked: fileDialog.open()
                }
                Button {
                    text: "Save"
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
                    onClicked: {
                        python.call("example.run_code_with_input", [editor.text, terminalInput.text], function(result) {
                            terminalOutput.text = result
                        })
                    }
                }
            }

            // Code Editor
            TextArea {
                id: editor
                Layout.fillWidth: true
                Layout.fillHeight: true
                wrapMode: TextArea.WrapAnywhere
                font.family: "monospace"
                placeholderText: "# Write your Python code here"
                color: "white"
                background: Rectangle {
                    color: "#1c1c1c"
                }
                font.pixelSize: 14
            }
            // Terminal Section (Output + Input Together)
            Rectangle {
                id: terminalBox
                color: "#1c1c1c"
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(20)

                ColumnLayout {
                    anchors.fill: parent
                    spacing: units.gu(0.5)

                    ScrollView {
                        id: terminalScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            id: terminalOutput
                            text: ""
                            color: "white"
                            wrapMode: Text.Wrap
                            font.family: "monospace"
                            font.pixelSize: 14
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
        }



    // Python bridge
        Python {
            id: python
            Component.onCompleted: {
                addImportPath(Qt.resolvedUrl('../src/')) //location of python backend file
                importModule_sync("example")             //import functions from python backend file
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

}
