cmake_minimum_required(VERSION 3.16)
project(MyQtApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt
find_package(Qt6 COMPONENTS Core Gui Qml Quick REQUIRED)

# Add the executable
add_executable(MyQtApp
    main.cpp
    iconchanger.cpp
    iconchanger.h
)

# Link against Qt libraries
target_link_libraries(MyQtApp PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)

# Add QML resources
qt_add_resources(MyQtApp "resources"
    PREFIX "/"
    FILES qml/main.qml assets/default_icon.png assets/new_icon.png
)
