# rellax
Rellax while the Camera tracks with cool parallax

[<img src="https://raw.githubusercontent.com/ericoporto/rellax/master/rellax_demo.gif" alt="rellax demo" width="640px" height="360px">](https://imgur.com/nJGnylM)


_This module uses the Camera and Viewport API from **Adventure Game Studio 3.5.0**._

### Usage

Before starting, you must create the following Custom Properties
in AGS Editor, for usage with Objects.
Just click on **`Properties [...]`** and on the **`Edit Custom Properties`** screen,
click on **`Edit Schema ...`** button, and add the two properties below:

- PxPos:
  - **`Name`:** `PxPos`
  - **`Description`:** `Object's horizontal parallax`
  - **`Type`:** `Number`
  - **`Default Value`:** `0`


- PyPos:
  - **`Name`:** `PyPos`
  - **`Description`:** `Object's vertical parallax`
  - **`Type`:** `Number`
  - **`Default Value`:** `0`

The number defined on `Px` or `Py` will be divided by 100 and used to increase
the scrolling. An object with `Px` and `Py` 0 is scrolled normally, an object
with `Px` and `Py` 100 will be fixed on the screen despite camera movement.

### Scritp API

---

#### `static attribute Character* TargetCharacter`

The character being tracked by the Game.Camera.

---

#### `static attribute bool EnableParallax`

Gets/sets whether Parallax is on or off.

---

#### `static attribute bool EnableSmoothCam`

Gets/sets whether Smooth Camera tracking is on or off.


---

#### `static attribute int CameraOffsetX`

Gets/sets the camera horizontal offset.

---

#### `static attribute int CameraOffsetY`

Gets/sets the camera vertical offset.

---

#### `static attribute int CameraLookAheadX`

Gets/sets the camera horizontal lookahead offset.

This is an additional offset that is added in the direction the target character is facing (only 4 direction support now).

---

#### `static attribute int CameraLookAheadY`

Gets/sets the camera vertical lookahead offset.

This is an additional offset that is added in the direction the target character is facing (only 4 direction support now).

---

### License

This module is created by Érico Porto and is provided with MIT License, see [LICENSE](LICENSE) for more details.

The code on this module is based on the code of Smooth Scrolling + Parallax Module
from Alasdair Beckett, which bases his code on code from Steve McCrea.

The demo game uses CC0 (Public Domain) art provided by [jetrel](https://opengameart.org/users/jetrel).
