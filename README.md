# SIST UI

A custom desktop environment inspired by the aesthetic of "Memento Mori", built with Qt/QML and Flutter.

## Overview

SIST UI is a desktop shell that provides a unique user experience with a dark, gothic, and painterly aesthetic. The core shell, including the taskbar and window management, is built with Qt/QML for performance and flexibility. Applications within the environment are built with Flutter, allowing for beautiful and high-performance UIs.

## Features

*   **"Memento Mori" Inspired UI:** A dark and beautiful UI that is a complete reproduction of the game "Memento Mori".
*   **Hybrid Architecture:** A combination of Qt/QML for the shell and Flutter for applications.
*   **Custom Taskbar:** A custom taskbar that displays open applications.
*   **Built-in Terminal:** A terminal with command templates and history.

## Getting Started

### Prerequisites

*   Flutter
*   Qt 6
*   A C++ compiler
*   make

### Build and Run

1.  **Build the Qt/QML shell:**
    ```bash
    mkdir -p shell/build
    cd shell/build
    qmake ../
    make
    ```
2.  **Run the custom session:**
    ```bash
    ./deploy.sh
    ```

This will build the shell and start the custom desktop environment.
