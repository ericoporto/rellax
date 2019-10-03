# rellax
Rellax while the Camera tracks with cool parallax


Before starting, you must create the following Custom Properties
in AGS Editor, for usage with Objects.
Just click on Properties [...] and on the Edit Custom Properties screen,
click on Edit Schema ... button, and add the two properties below:

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
