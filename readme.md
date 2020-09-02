
# Blaise. Lightweight bitmap editor for macOS (written in Swift)

Blaise started as a learning project for Swift but could potentially be an open source bitmap editor with enough effort. 

As I learned, image editors are actually super complicated so this project may never be completed but it was a good learning experience and could be useful in the future.

### Design principles:

- Must be fast and responsive so I use an OpenGL backend for rendering.
- Custom 2D pixel canvas so no CoreGraphics contexts for drawing shapes.

### Features I want to implement:

- Layers
- Infinite expanding canvas
- Custom brush shapes
- Proper antialiasing and sub pixel grids
