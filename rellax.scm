AGSScriptModule    eri0o Rellax while the Camera tracks with cool parallax. rellax 0.3.3 �w  // Rellax
// 0.3.3
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
#define RLX_HALF_PI 1.570796327
#define RLX_DOUBLE_PI 6.283185307

// Custom properties for objects
// PxPos: horizontal parallax
// PyPos: vertical parallax

managed struct Vec2 {
  float x;
  float y;
  static import Vec2* New(float x, float y);
  import void Set(Vec2* pf);
};

// Target character for camera tracking
Character* _TargetCharacter;
Vec2* _TargetPos;

// Parallax objects
struct ParallaxObject {
  Object* Object;
  int RoomStartX;
  int RoomStartY;
  int ObjectOriginX;
  int ObjectOriginY;
  bool HasParallax;
  float ParallaxX;
  float ParallaxY;
};

ParallaxObject _pxo[MAX_PARALLAX_OBJS];
int _pxo_count;

// Tween Stuff
Vec2* _tween_cam_origin;
float _cam_tween_elapsed;
float _cam_tween_duration;
RellaxTweenEasingType _cam_tween_type;

// Camera window dimensions
int _cam_window_w, _cam_window_h;

// Scrolling
float _scroll_x,  _scroll_y;
Vec2* _next_cam_pos;


// Previous character position
int _prev_c_x, _prev_c_y;
int _target_stop_counter;
bool _is_target_stopped;

// Camera offsets
int _off_x, _off_y;
int _off_applied_x, _off_applied_y;

// smoothed offset
int _look_ahead_x;
int _look_ahead_y;

// Interpolation factors
float _cam_r_lerp_factor_x;
float _cam_r_lerp_factor_y;

// Current camera position
Vec2* _cam_pos;

// Partial character height
int _partial_c_height;

// used to check if room setup was done on room load
bool _roomSetupDone;

// Flags
bool _DebugShow;
bool _SmoothCamEnabled = true;
bool _ParallaxEnabled = true;
bool _AdjustCameraOnRoomLoad = true;
bool _AutomaticallySetupOnRoomLoad = true;

// Debugging objects
DynamicSprite* _debug_spr;
Overlay* _debug_ovr;

static Vec2* Vec2::New(float x, float y) {
  Vec2* p = new Vec2;
  p.x = x;
  p.y = y;
  return p;
}

void Vec2::Set(Vec2* pf) {
  this.x = pf.x;
  this.y = pf.y;
}

// Linear interpolation
float _r_lerp(float from, float to, float t) {
  return (from + (to - from) * t);
}

Vec2* _r_lerp_pf(Vec2* from, Vec2* to, float t) {
  return Vec2.New((from.x + (to.x - from.x) * t), (from.y + (to.y - from.y) * t));
}

Vec2* _r_lerp_pfex(Vec2* from, Vec2* to, float tx, float ty) {
  return Vec2.New((from.x + (to.x - from.x) * tx), (from.y + (to.y - from.y) * ty));
}

// FIX-ME: remove these
float _p, _s;

float _r_tween_EaseLinear(float t,float d) {
  return t / d;
}

float _r_tween_EaseInSine(float t,float b,float c,float d) {
  return -c * Maths.Cos((t/d) * RLX_HALF_PI) + c + b;
}
float _r_tween_EaseOutSine(float t,float b,float c,float d) {
  return c * Maths.Sin((t/d) * RLX_HALF_PI) + b;
}
float _r_tween_EaseInOutSine(float t,float b,float c,float d) {
  return (-c*0.5) * (Maths.Cos(Maths.Pi*(t/d)) -1.0) + b;
}

float _r_tween_EaseInPower(float t,float b,float c,float d,float exponent) {
  t = t / d;
  return c*Maths.RaiseToPower(t, exponent) + b;
}
float _r_tween_EaseOutPower(float t,float b,float c,float d,float exponent) {
  _s = 1.0;
  if (FloatToInt(exponent, eRoundDown) % 2 == 0) {
    c = -c;
    _s = -_s;
  }
  t = (t / d) - 1.0;
  return c*(Maths.RaiseToPower(t, exponent) + _s) + b;
}
float _r_tween_EaseInOutPower(float t,float b,float c,float d,float exponent) {
  t = t / (d*0.5);
  if (t < 1.0) return (c*0.5)*Maths.RaiseToPower(t, exponent) + b;
  _s = 2.0;
  if (FloatToInt(exponent, eRoundDown) % 2 == 0) {
    c = -c;
    _s = -2.0;
  }
  return (c*0.5)*(Maths.RaiseToPower(t - 2.0, exponent) + _s) + b;
}

float _r_tween_EaseInQuad(float t,float b,float c,float d) {
  t = (t / d);
  return c*t*t + b;
}
float _r_tween_EaseOutQuad(float t,float b,float c,float d) {
  t = (t / d);
  return -c*t*(t-2.0) + b;
}
float _r_tween_EaseInOutQuad(float t,float b,float c,float d) {
  t = t / (d*0.5);
  if (t < 1.0) return (c*0.5)*t*t + b;
  t = t - 1.0;
  return -(c*0.5)*(t*(t-2.0) - 1.0) + b;
}

float _r_tween_EaseInExpo(float t,float b,float c,float d) {
  if (t == 0.0) return b;
  return c * Maths.RaiseToPower(2.0, 10.0 * (t/d - 1.0)) + b;
}
float _r_tween_EaseOutExpo(float t,float b,float c,float d) {
  if (t == d) return b + c;
  return c * (-Maths.RaiseToPower(2.0, -10.0 * (t/d)) + 1.0) + b;
}
float _r_tween_EaseInOutExpo(float t,float b,float c,float d) {
  if (t == 0.0) return b;
  if (t == d) return b + c;
  t = t / (d*0.5);
  if (t < 1.0) return (c*0.5) * Maths.RaiseToPower(2.0, 10.0 * (t - 1.0)) + b;
  t = t - 1.0;
  return (c*0.5) * (-Maths.RaiseToPower(2.0, -10.0 * t) + 2.0) + b;
}

float _r_tween_EaseInCirc(float t,float b,float c,float d) {
  t = t / d;
  return -c * (Maths.Sqrt(1.0 - t*t) - 1.0) + b;
}
float _r_tween_EaseOutCirc(float t,float b,float c,float d) {
  t = t / d - 1.0;
  return c * Maths.Sqrt(1.0 - t*t) + b;
}
float _r_tween_EaseInOutCirc(float t,float b,float c,float d) {
  t = t / (d*0.5);
  if (t < 1.0) return -(c*0.5) * (Maths.Sqrt(1.0 - t*t) - 1.0) + b;
  t = t - 2.0;
  return (c*0.5) * (Maths.Sqrt(1.0 - t*t) + 1.0) + b;
}

float _r_tween_EaseInBack(float t,float b,float c,float d) {
  _s = 1.70158;
  t = (t / d);
  return c*t*t*((_s+1.0)*t - _s) + b;
}
float _r_tween_EaseOutBack(float t,float b,float c,float d) {
  _s = 1.70158;
  t = (t / d) - 1.0;
  return c*(t*t*((_s+1.0)*t + _s) + 1.0) + b;
}
float _r_tween_EaseInOutBack(float t,float b,float c,float d) {
  _s = 1.70158;
  t = t / (d / 2.0);
  _s = _s * 1.525;
  if (t < 1.0) return (c/2.0)*(t*t*((_s+1.0)*t - _s)) + b;
  t = t - 2.0;
  return (c/2.0)*(t*t*((_s+1.0)*t + _s) + 2.0) + b;
}

float _r_tween_EaseOutBounce(float t,float b,float c,float d) {
  t = t / d;
  if (t < (1.0 / 2.75)) return c*(7.5625*t*t) + b;
  else if (t < (2.0 / 2.75)) {
    t = t - (1.5 / 2.75);
    return c*(7.5625*t*t + 0.75) + b;
  }
  else if (t < (2.5 / 2.75)) {
    t = t - (2.25 / 2.75);
    return c*(7.5625*t*t + 0.9375) + b;
  }
  t = t - (2.625 / 2.75);
  return c*(7.5625*t*t + 0.984375) + b;
}
float _r_tween_EaseInBounce(float t,float b,float c,float d) {
  return c - _r_tween_EaseOutBounce(d - t, 0.0, c, d) + b;
}
float _r_tween_EaseInOutBounce(float t,float b,float c,float d) {
  if (t < (d / 2.0)) return _r_tween_EaseInBounce(t * 2.0, 0.0, c, d) * 0.5 + b;
  return (_r_tween_EaseOutBounce((t * 2.0) - d, 0.0, c, d) * 0.5) + (c*0.5) + b;
}

float _r_tween_EaseInElastic(float t,float b,float c,float d) {
  if (t == 0.0) return b;
  t = t / d;
  if (t == 1.0) return b + c;
  _p = d * 0.3;
  _s = _p / 4.0;
  t = t - 1.0;
  return -(c*Maths.RaiseToPower(2.0, 10.0*t) * Maths.Sin(((t*d - _s)*RLX_DOUBLE_PI) / _p)) + b;
}
float _r_tween_EaseOutElastic(float t,float b,float c,float d) {
  if (t == 0.0) return b;
  t = t / d;
  if (t == 1.0) return b + c;
  _p = d * 0.3;
  _s = _p / 4.0;
  return ((c*Maths.RaiseToPower(2.0, -10.0*t)) * Maths.Sin(((t*d - _s)*RLX_DOUBLE_PI / _p)) + c + b);
}
float _r_tween_EaseInOutElastic(float t,float b,float c,float d) {
  if (t == 0.0) return b;
  t = t / (d * 0.5);
  if (t == 2.0) return b + c;
  _p = d * (0.3 * 1.5);
  _s = _p / 4.0;
  if (t < 1.0) {
    t = t - 1.0;
    return -0.5*(c*Maths.RaiseToPower(2.0, 10.0*t) * Maths.Sin(((t*d - _s)*RLX_DOUBLE_PI) / _p)) + b;
  }
  t = t - 1.0;
  return c*Maths.RaiseToPower(2.0, -10.0*t) * Maths.Sin(((t*d - _s)*RLX_DOUBLE_PI) / _p)*0.5 + c + b;
}

float _r_tween_GetValue(float elapsed, float duration, RellaxTweenEasingType easingType) {
  switch(easingType)
  {
    case eRellaxEaseLinearTween: return _r_tween_EaseLinear(elapsed, duration); break;
    case eRellaxEaseInSineTween: return _r_tween_EaseInSine(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutSineTween: return _r_tween_EaseOutSine(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutSineTween: return _r_tween_EaseInOutSine(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInCubicTween: return _r_tween_EaseInPower(elapsed, 0.0, 1.0, duration, 3.0); break;
    case eRellaxEaseOutCubicTween: return _r_tween_EaseOutPower(elapsed, 0.0, 1.0, duration, 3.0); break;
    case eRellaxEaseInOutCubicTween: return _r_tween_EaseInOutPower(elapsed, 0.0, 1.0, duration, 3.0); break;
    case eRellaxEaseInQuartTween: return _r_tween_EaseInPower(elapsed, 0.0, 1.0, duration, 4.0); break;
    case eRellaxEaseOutQuartTween: return _r_tween_EaseOutPower(elapsed, 0.0, 1.0, duration, 4.0); break;
    case eRellaxEaseInOutQuartTween: return _r_tween_EaseInOutPower(elapsed, 0.0, 1.0, duration, 4.0); break;
    case eRellaxEaseInQuintTween: return _r_tween_EaseInPower(elapsed, 0.0, 1.0, duration, 5.0); break;
    case eRellaxEaseOutQuintTween: return _r_tween_EaseOutPower(elapsed, 0.0, 1.0, duration, 5.0); break;
    case eRellaxEaseInOutQuintTween: return _r_tween_EaseInOutPower(elapsed, 0.0, 1.0, duration, 5.0); break;
    case eRellaxEaseInQuadTween: return _r_tween_EaseInQuad(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutQuadTween: return _r_tween_EaseOutQuad(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutQuadTween: return _r_tween_EaseInOutQuad(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInExpoTween: return _r_tween_EaseInExpo(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutExpoTween: return _r_tween_EaseOutExpo(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutExpoTween: return _r_tween_EaseInOutExpo(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInCircTween: return _r_tween_EaseInCirc(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutCircTween: return _r_tween_EaseOutCirc(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutCircTween: return _r_tween_EaseInOutCirc(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInBackTween: return _r_tween_EaseInBack(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutBackTween: return _r_tween_EaseOutBack(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutBackTween: return _r_tween_EaseInOutBack(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInElasticTween: return _r_tween_EaseInElastic(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutElasticTween: return _r_tween_EaseOutElastic(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutElasticTween: return _r_tween_EaseInOutElastic(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInBounceTween: return _r_tween_EaseInBounce(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseOutBounceTween: return _r_tween_EaseOutBounce(elapsed, 0.0, 1.0, duration); break;
    case eRellaxEaseInOutBounceTween: return _r_tween_EaseInOutBounce(elapsed, 0.0, 1.0, duration); break;
    default: return duration;
  }
}

// Clamp integer value between min and max
int _r_clamp_int(int value, int min, int max) {
  if (value > max) return max;
  else if (value < min) return min;
  return value;
}

float _r_clamp_float(float value, float min, float max) {
  if (value > max) return max;
  else if (value < min) return min;
  return value;
}

void _r_draw_clear_rectangle(DrawingSurface* surf, int x1, int y1, int x2, int y2)
{
  surf.DrawLine(x1, y1, x2, y1);
  surf.DrawLine(x2, y1, x2, y2);
  surf.DrawLine(x1, y2, x2, y2);
  surf.DrawLine(x1, y1, x1, y2);
}

// -- HELPER FUNCTIONS --

Point* _r_get_camera_position()
{
  Point* p = new Point;
  p.x = Game.Camera.X - _off_applied_x;
  p.y = Game.Camera.Y - _off_applied_y;
  return p;
}

void _r_set_camera_position(int x, int y)
{
//  Game.Camera.SetAt(x, y);
//  return;
  Game.Camera.SetAt(x+_off_x, y+_off_y);
  _off_applied_x = _r_clamp_int(x+_off_x, 0, Room.Width - Game.Camera.Width) -x;
  _off_applied_y = _r_clamp_int(y+_off_y, 0, Room.Height - Game.Camera.Height) -y;
}

void _r_enable_parallax(bool enable) { 
  _ParallaxEnabled = enable;
}

void _r_update_target_height()
{
  ViewFrame* c_vf = Game.GetViewFrame(_TargetCharacter.NormalView, 0, 0);  
  float scaling = IntToFloat(_TargetCharacter.Scaling)/100.00;
  _partial_c_height = FloatToInt((IntToFloat(Game.SpriteHeight[c_vf.Graphic])*scaling)/3.0);  
}

void _r_set_targetcharacter(Character* target) {
  if(target.Room <= 0 && player.Room != target.Room) {
    if(_DebugShow) AbortGame("Target character must be at the same room as the player character");
    return;
  }
  
  _TargetCharacter = target;
  _r_update_target_height();
}

void _r_update_target_pos()
{
  _TargetPos.x = IntToFloat(_TargetCharacter.x);
  _TargetPos.y = IntToFloat(_TargetCharacter.y) - IntToFloat(_partial_c_height);
}

void _r_update_camera()
{  
  Point* game_camera = _r_get_camera_position();
  _next_cam_pos.x = IntToFloat(game_camera.x);
  _next_cam_pos.y = IntToFloat(game_camera.y);
  _cam_pos.Set(_next_cam_pos);
}

void _r_do_object_parallax(){
  int camx = FloatToInt(_next_cam_pos.x);
  int camy = FloatToInt(_next_cam_pos.y);

  for(int i=0; i<_pxo_count; i++){
    if(_pxo[i].HasParallax) {
      float parallax_x = _pxo[i].ParallaxX;
      float parallax_y = _pxo[i].ParallaxY;

      _pxo[i].Object.X = _pxo[i].ObjectOriginX + FloatToInt(IntToFloat(camx)*parallax_x);
      _pxo[i].Object.Y = _pxo[i].ObjectOriginY + FloatToInt(IntToFloat(camy)*parallax_y);
    }
  }
}

void _r_enable_smoothcam(bool enable) {
  if(enable == true){
    _r_do_object_parallax();
  }

  _r_update_camera();
  _SmoothCamEnabled = enable;  
}

// -- MOST RELEVANT FUNCTIONS --

void _rellax_defaults()
{  
  _off_applied_x = 0;
  _off_applied_y = 0;
  _off_x = 0;
  _off_y = 0;
  _cam_window_w = 64;
  _cam_window_h = 40;
  _look_ahead_x = 20;
  _look_ahead_y = 0;
  _cam_tween_type = eRellaxEaseOutBackTween;
  _cam_tween_elapsed = 0.0;
  _cam_tween_duration = 1.0;
  _cam_r_lerp_factor_x = 0.0125;
  _cam_r_lerp_factor_y = 0.0125;
  _r_set_targetcharacter(player);
  _r_enable_parallax(true);
  _r_enable_smoothcam(true);
  _AdjustCameraOnRoomLoad = true;
}


Vec2* _r_get_target_focus()
{
  Point* focus = new Point;
    
  switch(_TargetCharacter.Loop)
  {
    case 0: focus.y = _look_ahead_y; break; // down
    case 1: focus.x = -_look_ahead_x; break; // left
    case 2: focus.x = _look_ahead_x; break; // right
    case 3: focus.y = -_look_ahead_y; break; // up
    case 4: if(_TargetCharacter.DiagonalLoops) {focus.y = 2*_look_ahead_y/3; focus.x = 2*_look_ahead_x/3;} break; // down-right
    case 5: if(_TargetCharacter.DiagonalLoops) {focus.y = -2*_look_ahead_y/3; focus.x = 2*_look_ahead_x/3;} break; // up-right
    case 6: if(_TargetCharacter.DiagonalLoops) {focus.y = 2*_look_ahead_y/3; focus.x = -2*_look_ahead_x/3;} break; // down-left
    case 7: if(_TargetCharacter.DiagonalLoops) {focus.y = -2*_look_ahead_y/3; focus.x = -2*_look_ahead_x/3;} break; // up-left
  }
  
  Vec2* focusf = Vec2.New(IntToFloat(focus.x), IntToFloat(focus.y));
      
  return focusf;
}

// Perform camera tracking, returning a desired camera position
Vec2* _r_do_camera_tracking()
{
  Vec2* focus = _r_get_target_focus();
  Vec2* cam_target = Vec2.New(_TargetPos.x + focus.x, _TargetPos.y + focus.y);
  Point* game_camera = _r_get_camera_position();

  int cam_window_check_x = FloatToInt(cam_target.x)-Game.Camera.Width/2-game_camera.x;
  int cam_window_check_y = FloatToInt(cam_target.y)-Game.Camera.Height/2-game_camera.y;
  bool is_outside_cam_window = (cam_window_check_x <= -_cam_window_w/2) || (cam_window_check_x > _cam_window_w/2) ||
    (cam_window_check_y <= -_cam_window_h/2) || (cam_window_check_y > _cam_window_h/2);

  if(is_outside_cam_window){                      
    cam_target.x = _r_clamp_float(cam_target.x - IntToFloat(Game.Camera.Width/2), 
                               0.0, IntToFloat(Room.Width-Game.Camera.Width));                          
    cam_target.y = _r_clamp_float(cam_target.y - IntToFloat(Game.Camera.Height/2),
                               0.0, IntToFloat(Room.Height-Game.Camera.Height));
  } else {
    // the camera is inside the window, this means we don't want it to move
    cam_target.x = IntToFloat(game_camera.x);
    cam_target.y = IntToFloat(game_camera.y);
  }
  
  int c_new_x = FloatToInt(cam_target.x);
  int c_new_y = FloatToInt(cam_target.y);
  if((_prev_c_x == c_new_x) && (_prev_c_y == c_new_y)) {
    _target_stop_counter++;
  } else {
    _target_stop_counter = 0;
  }
  _is_target_stopped = _target_stop_counter > 2;
  _prev_c_x = c_new_x;
  _prev_c_y = c_new_y;
  return cam_target;
}

// debug helper function
void _r_draw_debug_overlay()
{
  if(_debug_spr == null) 
    return;
  
  DrawingSurface* surf = _debug_spr.GetDrawingSurface();
  surf.Clear();
  
  // Calculate screen coordinates for camera and target character positions, in rellax terms
  Point* cam_pos = Screen.Viewport.RoomToScreenPoint(Game.Camera.Width/2+Game.Camera.X, Game.Camera.Height/2+Game.Camera.Y, false);
  Point* target_posi = Screen.Viewport.RoomToScreenPoint(_TargetCharacter.x, _TargetCharacter.y, false);
  Vec2* target_pos = Vec2.New(IntToFloat(target_posi.x), IntToFloat(target_posi.y));
  
  surf.DrawingColor = 63811; // red
  
  // Draw rectangle of the camera window
  _r_draw_clear_rectangle(surf, 
                      cam_pos.x - _cam_window_w/2, cam_pos.y - _cam_window_h/2, 
                      cam_pos.x + _cam_window_w/2, cam_pos.y + _cam_window_h/2);
  
  // Draw line in direction that target character is facing, length matches look ahead
  Vec2* focus = _r_get_target_focus();
  surf.DrawLine(FloatToInt(target_pos.x), FloatToInt(target_pos.y), FloatToInt(target_pos.x + focus.x), FloatToInt(target_pos.y + focus.y));
  
  
  // let's draw screen limits
  surf.DrawingColor = 63935; // pink
    
  Point* top_left_limit = Screen.Viewport.RoomToScreenPoint(Game.Camera.Width/2, Game.Camera.Height/2, false);
  Point* bottom_righht_limit = Screen.Viewport.RoomToScreenPoint(Room.Width - Game.Camera.Width/2, Room.Width - Game.Camera.Height/2, false);
  _r_draw_clear_rectangle(surf, 
                      top_left_limit.x,  top_left_limit.y, 
                      bottom_righht_limit.x, bottom_righht_limit.y);
  
  // let's make sure the actual camera is positioned where we think it should be
  surf.DrawingColor = 65506; // yellow
  Point* next_posi = Screen.Viewport.RoomToScreenPoint(FloatToInt(_next_cam_pos.x), FloatToInt(_next_cam_pos.y),  false);

  surf.DrawLine(next_posi.x -2, next_posi.y -2, next_posi.x +2  ,  next_posi.y + 2);

  surf.DrawLine(next_posi.x, next_posi.y -4, next_posi.x,  next_posi.y + 4);
  surf.DrawLine(next_posi.x-4, next_posi.y, next_posi.x+4,  next_posi.y);
  surf.DrawString(5, 5, eFontNormal, "_next_cam_pos (%.2f, %.2f)", _next_cam_pos.x, _next_cam_pos.y);
    
  surf.Release();
  
  if (_debug_ovr != null) {
    _debug_ovr.Remove();
    _debug_ovr = null;
  }
  
  _debug_ovr = Overlay.CreateGraphical(0, 0, _debug_spr.Graphic, true);
  #ifdef SCRIPT_API_v360
  _debug_ovr.ZOrder = 9999999;
  #endif
}

void _r_quick_adjust_to_target()
{
  Vec2* cam_target = _r_do_camera_tracking();
  _next_cam_pos.Set(cam_target);
  _cam_pos.Set(_next_cam_pos);
  _r_set_camera_position(FloatToInt(cam_target.x), FloatToInt(cam_target.y));
}

void _r_do_smooth_camera_tracking()
{
  Vec2* cam_target = _r_do_camera_tracking();
  Point* game_camera = _r_get_camera_position();
  
  if(_is_target_stopped ) {
    if(_tween_cam_origin == null) {
      _tween_cam_origin = Vec2.New(IntToFloat(game_camera.x), IntToFloat(game_camera.y));
      _cam_tween_elapsed = 0.0;
    } else {
      if(_cam_tween_elapsed < _cam_tween_duration) {
        _cam_tween_elapsed +=  1.0/IntToFloat(GetGameSpeed()) ;
      } else {
        _cam_tween_elapsed = _cam_tween_duration;
      }
    }
  }
  else {
    _tween_cam_origin = null;
  }  

  if(FloatToInt(cam_target.x) != game_camera.x || FloatToInt(cam_target.y) != game_camera.y) 
  {
    if(_tween_cam_origin != null) 
    {
      if(_cam_tween_elapsed < _cam_tween_duration) 
      {
        float tween_factor = _r_tween_GetValue(_cam_tween_elapsed, _cam_tween_duration, _cam_tween_type);
        _next_cam_pos = _r_lerp_pf(_tween_cam_origin, cam_target, tween_factor);
      } else {
        _next_cam_pos.x = cam_target.x;
        _next_cam_pos.y = cam_target.y;
      }
    } 
    else 
    {
      if(_cam_r_lerp_factor_x > 0.025 && _cam_r_lerp_factor_y > 0.025) 
      {
        _next_cam_pos = _r_lerp_pfex(_cam_pos, cam_target, _cam_r_lerp_factor_x, _cam_r_lerp_factor_y);
      } 
      else 
      {
        float d_x = _r_clamp_float( Maths.Sqrt((_cam_pos.x-cam_target.x)*(_cam_pos.x-cam_target.x)/4.0), 1.0, 8.0);
        float d_y = _r_clamp_float( Maths.Sqrt((_cam_pos.y-cam_target.y)*(_cam_pos.y-cam_target.y)/4.0), 1.0, 8.0);        
        float clfx = 0.4/d_x;
        float clfy = 0.4/d_y; 
        
        _next_cam_pos = _r_lerp_pfex(_cam_pos, cam_target, clfx, clfy);
      }
    }
  }
}
  
void _r_enable_debug_overlay(bool enable)
{
  if (!enable && _debug_ovr != null) {
    _debug_ovr.Remove();
    _debug_ovr = null;
  }
  
  if (_debug_spr != null) {
    _debug_spr.Delete();
    _debug_spr = null;
  } 
  
  if(enable) { 
    _debug_spr = DynamicSprite.Create(Screen.Width, Screen.Height, true);    
  }
  
  _DebugShow = enable;
}

// ---- Rellax API ------------------------------------------------------------

void set_TargetCharacter(this Rellax*, Character* target)
{ 
  _r_set_targetcharacter(target);
}

Character* get_TargetCharacter(this Rellax*)
{
  return _TargetCharacter;
}

void set_EasingType(this Rellax*, RellaxTweenEasingType value)
{ 
  _cam_tween_type = value;
}

RellaxTweenEasingType get_EasingType(this Rellax*)
{
  return _cam_tween_type;
}

void set_TweenDuration(this Rellax*, float value)
{ 
  _cam_tween_duration = value;
}

float get_TweenDuration(this Rellax*)
{
  return  _cam_tween_duration;
}

void set_EnableParallax(this Rellax*, bool enable)
{ 
  _r_enable_parallax(enable);
}

bool get_EnableParallax(this Rellax*)
{
  return _ParallaxEnabled;
}

void set_DebugShow(this Rellax*, bool enable)
{ 
  _r_enable_debug_overlay(enable);
}

bool get_DebugShow(this Rellax*)
{
  return _DebugShow;
}

void set_EnableSmoothCam(this Rellax*, bool enable)
{ 
  _r_enable_smoothcam(enable);
}

bool get_EnableSmoothCam(this Rellax*)
{
  return _SmoothCamEnabled;
}

void set_AdjustCameraOnRoomLoad(this Rellax*, bool enable)
{ 
  _AdjustCameraOnRoomLoad = enable;
}

bool get_AdjustCameraOnRoomLoad(this Rellax*)
{
  return _AdjustCameraOnRoomLoad;
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

void set_CameraLerpFactorX(this Rellax*, float value)
{ 
  _cam_r_lerp_factor_x = value;
}

float get_CameraLerpFactorX(this Rellax*)
{
  return _cam_r_lerp_factor_x;
}

void set_CameraLerpFactorY(this Rellax*, float value)
{ 
  _cam_r_lerp_factor_y = value;
}

float get_CameraLerpFactorY(this Rellax*)
{
  return _cam_r_lerp_factor_y;
}

void set_CameraWindowWidth(this Rellax*, int value)
{ 
  _cam_window_w = value;
}

int get_CameraWindowWidth(this Rellax*)
{
  return _cam_window_w;
}

void set_CameraWindowHeight(this Rellax*, int value)
{ 
  _cam_window_h = value;
}

int get_CameraWindowHeight(this Rellax*)
{
  return _cam_window_h;
}

// ----------------------------------------------------------------------------

void doSetOrigins ()
{
  _pxo_count=0; // Reset the total number of parallax objects to zero
  float cam_w = IntToFloat(Game.Camera.Width);
  float cam_h = IntToFloat(Game.Camera.Height);
  float room_w = IntToFloat(Room.Width);
  float room_h = IntToFloat(Room.Height);

  for(int i=0; i<Room.ObjectCount; i++){
    bool has_parallax = object[i].GetProperty("PxPos")!=0 || object[i].GetProperty("PyPos")!=0;
     
    if (has_parallax) {
      _pxo[_pxo_count].HasParallax = has_parallax;
      // Store the object in the parallax object array
      _pxo[_pxo_count].Object = object[i];
      // Get the parallax values for the object, and it's position
      float parallax_x = IntToFloat(object[i].GetProperty("PxPos")) / 100.0;
      float parallax_y = IntToFloat(object[i].GetProperty("PyPos")) / 100.0;
      float obj_x = IntToFloat(object[i].X);
      float obj_y = IntToFloat(object[i].Y);
      
      // store pre-calculated parallax_x and y
      _pxo[_pxo_count].ParallaxX = parallax_x;
      _pxo[_pxo_count].ParallaxY = parallax_y;
      
      // Store the object's initial position for resetting later
      _pxo[_pxo_count].RoomStartX = object[i].X;
      _pxo[_pxo_count].RoomStartY = object[i].Y;
      
      // Calculate the origin position for the object
      _pxo[_pxo_count].ObjectOriginX = object[i].X - FloatToInt(parallax_x * obj_x * (room_w - cam_w) / room_w);
      _pxo[_pxo_count].ObjectOriginY = object[i].Y - FloatToInt(parallax_y * obj_y * (room_h - cam_h) / room_h);

			if(_pxo_count<MAX_PARALLAX_OBJS) _pxo_count++;
		}
  }
  
  for(int i=_pxo_count; i<MAX_PARALLAX_OBJS; i++){
    _pxo[i].Object = null;
    _pxo[i].HasParallax = false;
    _pxo[i].ParallaxX = 0.0;
    _pxo[i].ParallaxY = 0.0;
    _pxo[i].RoomStartX = 0;
    _pxo[i].RoomStartY = 0;
    _pxo[i].ObjectOriginX = 0;
    _pxo[i].ObjectOriginY = 0;
  }
  // Apply the parallax effect to the objects
  _r_do_object_parallax();
}

void doRoomSetup()
{  
  _off_applied_x = 0;
  _off_applied_y = 0;
  _tween_cam_origin = null;
  _r_set_camera_position( _r_clamp_int(_TargetCharacter.x-Game.Camera.Width/2, 
    0, Room.Width-Game.Camera.Width), _r_clamp_int(_TargetCharacter.y-Game.Camera.Height/2, 
    0, Room.Height-Game.Camera.Height));
  
  _r_update_target_pos();

  _r_update_camera();
  doSetOrigins();

  if (_ParallaxEnabled) _r_enable_parallax(true);
  else _r_enable_parallax(false);
  _roomSetupDone = true;
}

void _r_do_room_setup()
{
  if(!_roomSetupDone){
    doRoomSetup();
  }

  if(_SmoothCamEnabled && _AdjustCameraOnRoomLoad) {
    _r_quick_adjust_to_target();
  }
}
  
void set_AutomaticallySetupOnRoomLoad(this Rellax*, bool enable)
{ 
  _AutomaticallySetupOnRoomLoad = enable;
}

bool get_AutomaticallySetupOnRoomLoad(this Rellax*)
{
  return _AutomaticallySetupOnRoomLoad;
}
  
static void Rellax::SetupRoomManually()
{
  _r_do_room_setup();
}


// --- callbacks --------------------------------------------------------------

function on_event (EventType event, int data)
{ 
  if (event==eEventLeaveRoom)
  { // player exits any room
    // reset the parallax object positions
    for(int i=0; i<_pxo_count; i++){
      _pxo[i].Object.X = _pxo[i].RoomStartX;
      _pxo[i].Object.Y = _pxo[i].RoomStartY;
    }
    _roomSetupDone = false;
  }
	else if (event==eEventEnterRoomBeforeFadein) 
  { // player enters a room that's different from current
    if(_AutomaticallySetupOnRoomLoad) {
      _r_do_room_setup();
    }
  }
}

function game_start(){
  _TargetPos = new Vec2;
  _next_cam_pos = new Vec2;
  _cam_pos = new Vec2;
  System.VSync = true;
  _rellax_defaults();
}

function repeatedly_execute_always(){
  _r_update_target_pos();
  
  if(_DebugShow) _r_draw_debug_overlay();
  if(!_roomSetupDone && _AutomaticallySetupOnRoomLoad) doRoomSetup();
  if(_SmoothCamEnabled) _r_do_smooth_camera_tracking();
}

function late_repeatedly_execute_always(){
  if(_ParallaxEnabled) _r_do_object_parallax();
  if(_SmoothCamEnabled) {
    _r_set_camera_position(FloatToInt(_next_cam_pos.x), FloatToInt(_next_cam_pos.y));
    _cam_pos.Set(_next_cam_pos);
  }
  else {
    _r_update_camera();
  }
}
 �  // Rellax
// 0.3.3
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
 ���q        fj���  ej��