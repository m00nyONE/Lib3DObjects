# Lib3DObjects – Utils

This folder contains small **utility helpers** used throughout Lib3DObjects.

Right now it’s mostly **math functions** for working with 3D vectors and rotations, for example:

- vector operations (`CrossProduct3D`, `DotProduct3D`, `Normalize3D`)
- rotation matrices (`RotationMatrixYaw/Pitch/Roll`)
- 3×3 matrix operations (`MultiplyMatrices3x3`, `MultiplyMatrixVector3x3`)
- Euler angle conversions (`EulerToMatrix`, `MatrixToEuler`)
- helper rotation math (`GetRotationFromVector`)

The utilities are exposed under `lib.util` and are used by core parts of the library (for example `BaseObject:RotateAroundPoint()` and the direction vector helpers).

