// Rellax
// 0.3.4
// A module to provide smooth scrolling and parallax!
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Before starting, you must create the following Custom Properties
// in AGS Editor, for usage with Objects.
// Just click on Properties [...] and on the Edit Custom Properties screen,
// click on Edit Schema ... button, and add the two properties below:
//
// PxPos:
//    Name: PxPos
//    Description: Object's horizontal parallax
//    Type: Number
//    Default Value: 0
//
// PyPos:
//    Name: PyPos
//    Description: Object's vertical parallax
//    Type: Number
//    Default Value: 0
//
//  The number defined on Px or Py will be divided by 100 and used to increase
// the scrolling. An object with Px and Py 0 is scrolled normally, an object
// with Px and Py 100 will be fixed on the screen despite camera movement.
//
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
// based on Smooth Scrolling + Parallax Module
// by Alasdair Beckett, based on code by Steve McCrea.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


enum RellaxTweenEasingType {
  eRellaxEaseLinearTween,
  eRellaxEaseInSineTween,
  eRellaxEaseOutSineTween,
  eRellaxEaseInOutSineTween,
  eRellaxEaseInQuadTween,
  eRellaxEaseOutQuadTween,
  eRellaxEaseInOutQuadTween,
  eRellaxEaseInCubicTween,
  eRellaxEaseOutCubicTween,
  eRellaxEaseInOutCubicTween,
  eRellaxEaseInQuartTween,
  eRellaxEaseOutQuartTween,
  eRellaxEaseInOutQuartTween,
  eRellaxEaseInQuintTween,
  eRellaxEaseOutQuintTween,
  eRellaxEaseInOutQuintTween,
  eRellaxEaseInCircTween,
  eRellaxEaseOutCircTween,
  eRellaxEaseInOutCircTween,
  eRellaxEaseInExpoTween,
  eRellaxEaseOutExpoTween,
  eRellaxEaseInOutExpoTween,
  eRellaxEaseInBackTween,
  eRellaxEaseOutBackTween,
  eRellaxEaseInOutBackTween,
  eRellaxEaseInElasticTween,
  eRellaxEaseOutElasticTween,
  eRellaxEaseInOutElasticTween,
  eRellaxEaseInBounceTween,
  eRellaxEaseOutBounceTween,
  eRellaxEaseInOutBounceTween
};

struct Rellax {
  /// The character being tracked by the Game.Camera.
  import static attribute Character* TargetCharacter;
  
  /// gets/sets the camera tween type to use when the character is stopped
  import static attribute RellaxTweenEasingType EasingType;
  
  /// gets/sets the camera tween duration once the character is stopped
  import static attribute float TweenDuration;

  /// gets/sets whether Parallax is on or off.
  import static attribute bool EnableParallax;
  
  /// gets/sets whether Smooth Camera tracking is on or off.
  import static attribute bool EnableSmoothCam;

  /// Gets/sets whether to automatically setup on room load. It defaults to yes (true). Leave as this unless you really need it.
  import static attribute bool AutomaticallySetupOnRoomLoad;
  
  /// you should not call this, unless AutomaticallySetupOnRoomLoad is false, then call this at the end of your room_Load.
  import static void SetupRoomManually();

  /// if Smooth Camera is on, gets/sets whether to instantly adjust camera to target on room before fade in.
  import static attribute bool AdjustCameraOnRoomLoad;

  /// gets/sets camera horizontal offset, it's applied in the next frame as soon as possible
  import static attribute int CameraOffsetX;
  
  /// gets/sets camera vertical offset, it's applied in the next frame as soon as possible
  import static attribute int CameraOffsetY;
  
  /// gets/sets camera horizontal lookahead offset
  import static attribute int CameraLookAheadX;
  
  /// gets/sets camera vertical lookahead offset
  import static attribute int CameraLookAheadY;

  /// gets/sets the factore the camera should use when interpolating in the X axis
  import static attribute float CameraLerpFactorX;
  
  /// gets/sets the factore the camera should use when interpolating in the Y axis
  import static attribute float CameraLerpFactorY;
  
  /// gets/sets the camera window width that is centered on the player, when the target is outside of the window, the camera moves to keep it inside
  import static attribute int CameraWindowWidth;
  
  /// gets/sets the camera window height that is centered on the player, when the target is outside of the window, the camera moves to keep it inside
  import static attribute int CameraWindowHeight;
  
  /// gets/sets whether Debug overlay is shown is on or off.
  import static attribute bool DebugShow;
};
