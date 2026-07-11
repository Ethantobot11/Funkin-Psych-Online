package mobile.flixel.screen;

#if android
import lime.system.JNI;
#end

using Lambda;

#if flixel
class ScreenUtil {
	public static var swipe(default, never):SwipeUtil = new SwipeUtil();
	public static var touch(default, never):TouchUtil = new TouchUtil();
	public static var wideScreen(default, never):WideScreenMode = new WideScreenMode();

	#if android
	public static var android(default, never):AndroidUtil = new AndroidUtil();
	#end
}

class WideScreenMode extends BaseScaleMode {
	public var enabled(default, set):Bool = false;

	public static var _enabled:Bool = false;

	override function updateGameSize(Width:Int, Height:Int):Void {
		if (_enabled) {
			super.updateGameSize(Width, Height);
			return;
		}

		var ratio:Float = FlxG.width / FlxG.height;
		var realRatio:Float = Width / Height;

		if (realRatio < ratio) {
			gameSize.set(Width, Math.floor(Width / ratio));
		} else {
			gameSize.set(Math.floor(Height * ratio), Height);
		}
	}

	override function updateGamePosition():Void {
		if (_enabled)
			FlxG.game.x = FlxG.game.y = 0;
		else
			super.updateGamePosition();
	}

	private function set_enabled(value:Bool):Bool {
		_enabled = enabled = value;
		FlxG.scaleMode = new WideScreenMode();
		return value;
	}
}

class TouchUtil {
	public function new() {}

	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var instance(get, never):FlxTouch;

	public var deltaScreenX(get, never):Float;
	public var deltaScreenY(get, never):Float;
	public var pinchDelta(get, never):Float;
	public var wheel(get, never):Int;
	public var activeTouchesCount(get, never):Int;

	private var _lastScreenX:Map<Int, Float> = new Map();
	private var _lastScreenY:Map<Int, Float> = new Map();
	private var _lastPinchDistance:Float = -1;
	private var _lastTwoFingerCenterY:Float = -1;
	private var _signalsHooked:Bool = false;

	private function checkSignals():Void {
		if (!_signalsHooked && FlxG.signals != null) {
			FlxG.signals.postUpdate.add(onPostUpdate);
			_signalsHooked = true;
		}
	}

	private function onPostUpdate():Void {
		_lastScreenX.clear();
		_lastScreenY.clear();

		var activeTouches = [];
		for (touch in FlxG.touches.list) {
			if (touch != null && touch.pressed) {
				activeTouches.push(touch);
				#if (flixel < "5.9.0")
				_lastScreenX.set(touch.touchPointID, touch.screenX);
				_lastScreenY.set(touch.touchPointID, touch.screenY);
				#else
				_lastScreenX.set(touch.touchPointID, touch.viewX);
				_lastScreenY.set(touch.touchPointID, touch.viewY);
				#end
			}
		}

		if (activeTouches.length >= 2) {
			#if (flixel < "5.9.0")
			var dx = activeTouches[0].screenX - activeTouches[1].screenX;
			var dy = activeTouches[0].screenY - activeTouches[1].screenY;
			_lastTwoFingerCenterY = (activeTouches[0].screenY + activeTouches[1].screenY) / 2;
			#else
			var dx = activeTouches[0].viewX - activeTouches[1].viewX;
			var dy = activeTouches[0].viewY - activeTouches[1].viewY;
			_lastTwoFingerCenterY = (activeTouches[0].viewY + activeTouches[1].viewY) / 2;
			#end
			_lastPinchDistance = Math.sqrt(dx * dx + dy * dy);
		} else {
			_lastPinchDistance = -1;
			_lastTwoFingerCenterY = -1;
		}
	}

	inline function get_activeTouchesCount():Int {
		var count = 0;
		for (t in FlxG.touches.list) {
			if (t != null && t.pressed)
				count++;
		}
		return count;
	}

	inline function get_pinchDelta():Float {
		checkSignals();
		var activeTouches = [];
		for (t in FlxG.touches.list) {
			if (t != null && t.pressed)
				activeTouches.push(t);
		}

		if (activeTouches.length >= 2 && _lastPinchDistance != -1) {
			#if (flixel < "5.9.0")
			var dx = activeTouches[0].screenX - activeTouches[1].screenX;
			var dy = activeTouches[0].screenY - activeTouches[1].screenY;
			#else
			var dx = activeTouches[0].viewX - activeTouches[1].viewX;
			var dy = activeTouches[0].viewY - activeTouches[1].viewY;
			#end
			var currentDistance = Math.sqrt(dx * dx + dy * dy);
			return currentDistance - _lastPinchDistance;
		}
		return 0;
	}

	inline function get_wheel():Int {
		checkSignals();
		var activeTouches = [];
		for (t in FlxG.touches.list) {
			if (t != null && t.pressed)
				activeTouches.push(t);
		}

		if (activeTouches.length >= 2 && _lastTwoFingerCenterY != -1) {
			#if (flixel < "5.9.0")
			var currentCenterY = (activeTouches[0].screenY + activeTouches[1].screenY) / 2;
			#else
			var currentCenterY = (activeTouches[0].viewY + activeTouches[1].viewY) / 2;
			#end
			return Std.int(_lastTwoFingerCenterY - currentCenterY);
		}
		return 0;
	}

	function get_deltaScreenX():Float {
		checkSignals();
		var t = instance;
		if (t != null && t.pressed && !t.justPressed) {
			if (_lastScreenX.exists(t.touchPointID)) {
				#if (flixel < "5.9.0")
				return t.screenX - _lastScreenX.get(t.touchPointID);
				#else
				return t.viewX - _lastScreenX.get(t.touchPointID);
				#end
			}
		}
		return 0;
	}

	function get_deltaScreenY():Float {
		checkSignals();
		var t = instance;
		if (t != null && t.pressed && !t.justPressed) {
			if (_lastScreenY.exists(t.touchPointID)) {
				#if (flixel < "5.9.0")
				return t.screenY - _lastScreenY.get(t.touchPointID);
				#else
				return t.viewY - _lastScreenY.get(t.touchPointID);
				#end
			}
		}
		return 0;
	}

	public function overlaps(obj:FlxObject, ?cam:FlxCamera):Bool {
		for (t in FlxG.touches.list)
			if (t.overlaps(obj, cam ?? obj.camera))
				return true;
		return false;
	}

	public function overlapsComplex(spr:FlxSprite, onTouch:Void->Void = null):Bool {
		if (instance == null)
			return false;

		var cam = spr.camera ?? FlxG.camera;
		for (t in FlxG.touches.list) {
			var tPos = t.getWorldPosition(cam);
			var isHit = spr.overlapsPoint(tPos, true, cam);
			tPos.put();

			if (isHit) {
				if (t.justPressed && onTouch != null)
					onTouch();
				return true;
			}
		}
		return false;
	}

	public function overlapsUltraComplex(spr:FlxSprite, onTouch:Void->Void) {
		if (instance != null) {
			var sprPos = spr.getScreenPosition(spr.camera);
			#if (flixel < "5.9.0")
			var touchX = instance.screenX;
			var touchY = instance.screenY;
			#else
			var touchX = instance.viewX;
			var touchY = instance.viewY;
			#end
			var overlap:Bool = (touchX >= sprPos.x && touchX <= sprPos.x + spr.frameWidth && touchY >= sprPos.y && touchY <= sprPos.y + spr.frameHeight);
			if (overlap && instance.justPressed)
				onTouch();
		}
	}

	inline function get_pressed()
		return FlxG.touches.list.exists(t -> t.pressed);

	inline function get_justPressed()
		return FlxG.touches.list.exists(t -> t.justPressed);

	inline function get_justReleased()
		return FlxG.touches.list.exists(t -> t.justReleased);

	inline function get_released()
		return FlxG.touches.list.exists(t -> t.released);

	function get_instance() {
		checkSignals();
		for (touch in FlxG.touches.list) {
			if (touch != null && (touch.pressed || touch.justReleased)) {
				return touch;
			}
		}
		return null;
	}
}

class SwipeUtil {
	public function new() {}

	public var UP(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var LEFT(get, never):Bool;
	public var RIGHT(get, never):Bool;

	public function checkSwipe(min:Float, max:Float):Bool {
		#if FLX_POINTER_INPUT
		for (s in FlxG.swipes) {
			if (s != null && s.distance > 20 && s.degrees >= min && s.degrees <= max)
				return true;
		}
		#end
		return false;
	}

	inline function get_UP()
		return checkSwipe(45, 135);

	inline function get_DOWN()
		return checkSwipe(-135, -45);

	inline function get_LEFT()
		return checkSwipe(135, 180) || checkSwipe(-180, -135);

	inline function get_RIGHT()
		return checkSwipe(-45, 45);
}

#if android
class AndroidUtil #if (lime >= "8.0.0") implements JNISafety #end {
	public function new() {}

	private var _setOrient:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setOrientation', '(IIZLjava/lang/String;)V');
	private var _getOrient:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I');
	private var _isKeyboard:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'isScreenKeyboardShown', '()Z');
	private var _hasClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardHasText', '()Z');
	private var _getClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardGetText', '()Ljava/lang/String;');
	private var _setClip:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardSetText', '(Ljava/lang/String;)V');
	private var _backBtn:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'manualBackButton', '()V');
	private var _setTitle:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setActivityTitle', '(Ljava/lang/String;)Z');

	public inline function setOrientation(w:Int, h:Int, res:Bool, hint:String)
		_setOrient(w, h, res, hint);

	public inline function isScreenKeyboardShown():Bool
		return _isKeyboard();

	public inline function clipboardHasText():Bool
		return _hasClip();

	public inline function clipboardGetText():String
		return _getClip();

	public inline function clipboardSetText(s:String)
		_setClip(s);

	public inline function manualBackButton()
		_backBtn();

	public inline function setActivityTitle(t:String):Bool
		return _setTitle(t);

	public function getCurrentOrientationAsString():String {
		return switch (_getOrient()) {
			case 1: "LandscapeRight";
			case 2: "LandscapeLeft";
			case 3: "Portrait";
			case 4: "PortraitUpsideDown";
			default: "Unknown";
		}
	}
}
#end
#end
