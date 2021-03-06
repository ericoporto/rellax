AGSScriptModule    eri0o Rellax while the Camera tracks with cool parallax. rellax 0.1.4 �%  // Rellax
// 0.1.4
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

#define MAX_PARALLAX_OBJS 39

Character *_TargetCharacter;

Object *_pxo[MAX_PARALLAX_OBJS];
int _pxoRoomStartX[MAX_PARALLAX_OBJS];
int _pxoRoomStartY[MAX_PARALLAX_OBJS];
int _pxoOriginX[MAX_PARALLAX_OBJS];
int _pxoOriginY[MAX_PARALLAX_OBJS];
int _pxo_count;

int _cam_window_w, _cam_window_h;
float _scroll_x,  _scroll_y;
int _next_cam_x, _next_cam_y;
int _prev_c_x, _prev_c_y;
int _off_x, _off_y;
int _look_ahead_x = 48;
int _look_ahead_y = 16;

int _partial_c_height;
int _count_still_ticks;

bool _is_doRoomSetup;
bool _SmoothCamEnabled = true;
bool _ParallaxEnabled = true;

int Lerp(float from, float to, float t) {
  return FloatToInt(from + (to - from) * t, eRoundNearest);
}

int ClampInt(int value, int min, int max) {
  if (value > max) return max;
  else if (value < min) return min;
  return value;
}

void doObjectParallax(){
  int camx = _next_cam_x;
  int camy = _next_cam_y;

  for(int i=0; i<_pxo_count; i++){
    if(_pxo[i].GetProperty("PxPos") !=0 || _pxo[i].GetProperty("PyPos") != 0) {
      float parallax_x = IntToFloat(_pxo[i].GetProperty("PxPos"))/100.0;
      float parallax_y = IntToFloat(_pxo[i].GetProperty("PyPos"))/100.0;

      _pxo[i].X=_pxoOriginX[i]+FloatToInt(IntToFloat(camx)*parallax_x);
      _pxo[i].Y=_pxoOriginY[i]+FloatToInt(IntToFloat(camy)*parallax_y);
    }
  }
}

void _enable_parallax(bool enable) { 
  _ParallaxEnabled = enable;
}

void _enable_smoothcam(bool enable) {
  if(enable == true){
    doObjectParallax();
  }

  _SmoothCamEnabled = enable;  
}

void _set_targetcharacter(Character* target) {
  _TargetCharacter = target;
}

// ---- Rellax API ------------------------------------------------------------

void set_TargetCharacter(this Rellax*, Character* target)
{
  _set_targetcharacter(target);
}

Character* get_TargetCharacter(this Rellax*)
{
  return  _TargetCharacter;
}

void set_EnableParallax(this Rellax*, bool enable)
{ 
  _enable_parallax(enable);
}

bool get_EnableParallax(this Rellax*)
{
  return _ParallaxEnabled;
}

void set_EnableSmoothCam(this Rellax*, bool enable)
{ 
  _enable_smoothcam(enable);
}

bool get_EnableSmoothCam(this Rellax*)
{
  return _SmoothCamEnabled;
}

void set_CameraOffsetX(this Rellax*, int offset_x)
{ 
  _off_x = offset_x;
}

int get_CameraOffsetX(this Rellax*)
{
  return _off_x;
}

void set_CameraOffsetY(this Rellax*, int offset_y)
{ 
  _off_y = offset_y;
}

int get_CameraOffsetY(this Rellax*)
{
  return _off_y;
}

void set_CameraLookAheadX(this Rellax*, int look_ahead_x)
{ 
  _look_ahead_x = look_ahead_x;
}

int get_CameraLookAheadX(this Rellax*)
{
  return _look_ahead_x;
}

void set_CameraLookAheadY(this Rellax*, int look_ahead_y)
{ 
  _look_ahead_y = look_ahead_y;
}

int get_CameraLookAheadY(this Rellax*)
{
  return _look_ahead_y;
}

// ----------------------------------------------------------------------------

void doSetOrigins (){
  _pxo_count=0; // Reset the total number of parallax objects to zero
  float cam_w = IntToFloat(Game.Camera.Width);
  float cam_h = IntToFloat(Game.Camera.Height);
  float room_w = IntToFloat(Room.Width);
  float room_h = IntToFloat(Room.Height);

  for(int i=0; i<Room.ObjectCount; i++){
    if (object[i].GetProperty("PxPos")!=0) {
 			_pxo[_pxo_count]=object[i];
      float parallax_x = IntToFloat(object[i].GetProperty("PxPos"))/100.0;
      float parallax_y = IntToFloat(object[i].GetProperty("PyPos"))/100.0;

      float obj_x = IntToFloat(object[i].X);
      float obj_y = IntToFloat(object[i].Y);

      // initial positions for reset
      _pxoRoomStartX[_pxo_count]= object[i].X;
      _pxoRoomStartY[_pxo_count]= object[i].Y;

      //Set origin for object:
      _pxoOriginX[_pxo_count] = object[i].X -FloatToInt(
        parallax_x*obj_x*(room_w-cam_w) / room_w );

      _pxoOriginY[_pxo_count] = object[i].Y -FloatToInt(
        parallax_y*obj_y*(room_h-cam_h) / room_h );

			if(_pxo_count<MAX_PARALLAX_OBJS) _pxo_count++;
		}
   }
  doObjectParallax();
}

void doRoomSetup(){
  Game.Camera.X = ClampInt(_TargetCharacter.x-Game.Camera.Width/2, 
    0, Room.Width-Game.Camera.Width);

  Game.Camera.Y = ClampInt(_TargetCharacter.y-Game.Camera.Height/2, 
    0, Room.Height-Game.Camera.Height);

  _next_cam_x = Game.Camera.X;
  _next_cam_y = Game.Camera.Y;
  doSetOrigins();

  ViewFrame* c_vf = Game.GetViewFrame(_TargetCharacter.NormalView, 0, 0);
  float scaling = IntToFloat(GetScalingAt(_TargetCharacter.x, _TargetCharacter.y))/100.00;
  _partial_c_height = FloatToInt((IntToFloat(Game.SpriteHeight[c_vf.Graphic])*scaling)/3.0);

  if (_ParallaxEnabled) _enable_parallax(true);
  else _enable_parallax(false);
  _is_doRoomSetup = true;
}

void doSmoothCameraTracking(){
  if(_prev_c_x == _TargetCharacter.x && _prev_c_y == _TargetCharacter.y)
    _count_still_ticks++;
  else
    _count_still_ticks = 0;

  if(_TargetCharacter.x-Game.Camera.Width/2-Game.Camera.X<=-_cam_window_w/2 ||
     _TargetCharacter.x-Game.Camera.Width/2-Game.Camera.X>_cam_window_w/2 ||
     _TargetCharacter.y-Game.Camera.Height/2-Game.Camera.Y<=-_cam_window_h/2 ||
     _TargetCharacter.y-Game.Camera.Height/2-Game.Camera.Y>_cam_window_h/2 ||
     _count_still_ticks > 5){

    int x_focus=0,y_focus=0;
    if(_TargetCharacter.Loop == 2) x_focus = _look_ahead_x; // right
    else if(_TargetCharacter.Loop == 1) x_focus = -_look_ahead_x; // left
    else if(_TargetCharacter.Loop == 0) y_focus = _look_ahead_y; // down
    else if(_TargetCharacter.Loop == 3) y_focus = -_look_ahead_y; // up

    float y_multiplier;
    if(_count_still_ticks<=30) y_multiplier = IntToFloat(_count_still_ticks)*0.138 ;
    if(_count_still_ticks>30) y_multiplier = 5.0;

    _next_cam_x = Lerp(
      IntToFloat(Game.Camera.X),
      IntToFloat(ClampInt(_TargetCharacter.x + _off_x + x_focus - Game.Camera.Width/2,
                          0, Room.Width-Game.Camera.Width)),
      0.04);
    _next_cam_y = Lerp(
      IntToFloat(Game.Camera.Y),
      IntToFloat(ClampInt(_TargetCharacter.y + _off_y + y_focus - _partial_c_height - Game.Camera.Height/2,
                          0, Room.Height-Game.Camera.Height)),
      0.01*y_multiplier);

  }

  _prev_c_x = _TargetCharacter.x;
  _prev_c_y = _TargetCharacter.y;
}

// --- callbacks --------------------------------------------------------------

function on_event (EventType event, int data){
  // player exits any room
  if (event==eEventLeaveRoom){
    for(int i=0; i<_pxo_count; i++){
      _pxo[i].X=_pxoRoomStartX[i];
      _pxo[i].Y=_pxoRoomStartY[i];
    }
    _is_doRoomSetup = false;
  }

  // player enters a room that's different from current
	if (event==eEventEnterRoomBeforeFadein){
    if(!_is_doRoomSetup){
      doRoomSetup();
    }
  }
}

function game_start(){
  System.VSync = true;
  _cam_window_w = 40;
  _cam_window_h = 40;
  _set_targetcharacter(player);
  _enable_parallax(true);
  _enable_smoothcam(true);
}

function late_repeatedly_execute_always(){
  if(_SmoothCamEnabled) doSmoothCameraTracking();
  if(_ParallaxEnabled) doObjectParallax();
  if(_SmoothCamEnabled) Game.Camera.SetAt(_next_cam_x, _next_cam_y);
  else {
    _next_cam_x = Game.Camera.X;
    _next_cam_y = Game.Camera.Y;
  }
}

function repeatedly_execute_always(){
  if(!_is_doRoomSetup) doRoomSetup();
}
 _  // Rellax
// 0.1.4
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

struct Rellax {
  /// The character being tracked by the Game.Camera.
  import static attribute Character* TargetCharacter;
  
  /// gets/sets whether Parallax is on or off.
  import static attribute bool EnableParallax;
  
  /// gets/sets whether Smooth Camera tracking is on or off.
  import static attribute bool EnableSmoothCam;
    
  /// gets/sets camera horizontal offset
  import static attribute int CameraOffsetX;
  
  /// gets/sets camera vertical offset
  import static attribute int CameraOffsetY;
      
  /// gets/sets camera horizontal lookahead offset
  import static attribute int CameraLookAheadX;
  
  /// gets/sets camera vertical lookahead offset
  import static attribute int CameraLookAheadY;
};
 ���q        ej��