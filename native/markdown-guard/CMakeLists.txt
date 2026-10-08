cmake_minimum_required(VERSION 3.21)
project(CouchShellMarkdownGuard LANGUAGES CXX)
find_package(Qt6 6.7 REQUIRED COMPONENTS Quick Test Network)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(markdown_guard
    URI CouchShell.Markdown
    VERSION 1.0
    OUTPUT_DIRECTORY CouchShell/Markdown
    SOURCES markdownresourceguard.h markdownresourceguard.cpp
)
target_link_libraries(markdown_guard PRIVATE Qt6::Quick)
install(TARGETS markdown_guard markdown_guardplugin
    LIBRARY DESTINATION lib/qt-6/qml/CouchShell/Markdown)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/CouchShell/Markdown/qmldir
    ${CMAKE_CURRENT_BINARY_DIR}/CouchShell/Markdown/markdown_guard.qmltypes
    DESTINATION lib/qt-6/qml/CouchShell/Markdown)
qt_add_executable(markdown-guard-test tst_markdownresourceguard.cpp markdownresourceguard.cpp markdownresourceguard.h)
target_link_libraries(markdown-guard-test PRIVATE Qt6::Quick Qt6::Test Qt6::Network)
install(TARGETS markdown-guard-test RUNTIME DESTINATION bin)
