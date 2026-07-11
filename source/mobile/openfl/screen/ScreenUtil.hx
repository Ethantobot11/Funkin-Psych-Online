package mobile.openfl.screen;

#if android
import lime.system.JNI;
#end

class ScreenUtil {
	public static var swipe(default, never):SwipeUtil = new SwipeUtil();
	public static var touch(default, never):TouchUtil = new TouchUtil();

	#if android
	public static var android(default, never):AndroidUtil = new AndroidUtil();
	#end

	public static function init(stage:Stage) {
		touch.init(stage);
		swipe.init(stage);
	}

	public static function enableWideScreen(stage:Stage, enabled:Bool) {
		stage.scaleMode = enabled ? StageScaleMode.EXACT_FIT : StageScaleMode.SHOW_ALL;
	}
}

typedef TouchData = {x:Float, y:Float, lastX:Float, lastY:Float, pressed:Bool, justPressed:Bool, justReleased:Bool, dead:Bool}

class TouchUtil {
	public var activeTouches:Map<Int, TouchData> = new Map();

	private var _lastPinchDistance:Float = -1;
	private var _lastTwoFingerCenterY:Float = -1;

	public function new() {}

	public function init(stage:Stage) {
		if (Multitouch.supportsTouchEvents) {
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	}

	private function onTouchBegin(e:TouchEvent) {
		activeTouches.set(e.touchPointID, {
			x: e.stageX,
			y: e.stageY,
			lastX: e.stageX,
			lastY: e.stageY,
			pressed: true,
			justPressed: true,
			justReleased: false,
			dead: false
		});
	}

	private function onTouchMove(e:TouchEvent) {
		var t = activeTouches.get(e.touchPointID);
		if (t != null) {
			t.x = e.stageX;
			t.y = e.stageY;
		}
	}

	private function onTouchEnd(e:TouchEvent) {
		var t = activeTouches.get(e.touchPointID);
		if (t != null) {
			t.pressed = false;
			t.justReleased = true;
			t.dead = true;
		}
	}

	private function onEnterFrame(e:Event) {
		for (id => t in activeTouches) {
			if (t.dead) {
				activeTouches.remove(id);
			} else {
				t.lastX = t.x;
				t.lastY = t.y;
				t.justPressed = false;
				t.justReleased = false;
			}
		}

		var activeList = [];
		for (t in activeTouches) {
			if (t.pressed)
				activeList.push(t);
		}

		if (activeList.length >= 2) {
			var dx = activeList[0].x - activeList[1].x;
			var dy = activeList[0].y - activeList[1].y;
			_lastPinchDistance = Math.sqrt(dx * dx + dy * dy);
			_lastTwoFingerCenterY = (activeList[0].y + activeList[1].y) / 2;
		} else {
			_lastPinchDistance = -1;
			_lastTwoFingerCenterY = -1;
		}
	}

	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;

	public var activeTouchesCount(get, never):Int;
	public var deltaScreenX(get, never):Float;
	public var deltaScreenY(get, never):Float;
	public var pinchDelta(get, never):Float;
	public var wheel(get, never):Int;

	inline function get_pressed():Bool {
		var res = false;
		for (t in activeTouches)
			if (t.pressed)
				res = true;
		return res;
	}

	inline function get_justPressed():Bool {
		var res = false;
		for (t in activeTouches)
			if (t.justPressed)
				res = true;
		return res;
	}

	inline function get_justReleased():Bool {
		var res = false;
		for (t in activeTouches)
			if (t.justReleased)
				res = true;
		return res;
	}

	inline function get_released():Bool {
		return !get_pressed();
	}

	inline function get_activeTouchesCount():Int {
		var count = 0;
		for (t in activeTouches)
			if (t.pressed)
				count++;
		return count;
	}

	private function getFirstTouch():TouchData {
		for (t in activeTouches) {
			if (t.pressed || t.justReleased)
				return t;
		}
		return null;
	}

	inline function get_deltaScreenX():Float {
		var t = getFirstTouch();
		if (t != null && t.pressed && !t.justPressed) {
			return t.x - t.lastX;
		}
		return 0;
	}

	inline function get_deltaScreenY():Float {
		var t = getFirstTouch();
		if (t != null && t.pressed && !t.justPressed) {
			return t.y - t.lastY;
		}
		return 0;
	}

	inline function get_pinchDelta():Float {
		var activeList = [];
		for (t in activeTouches)
			if (t.pressed)
				activeList.push(t);

		if (activeList.length >= 2 && _lastPinchDistance != -1) {
			var dx = activeList[0].x - activeList[1].x;
			var dy = activeList[0].y - activeList[1].y;
			return Math.sqrt(dx * dx + dy * dy) - _lastPinchDistance;
		}
		return 0;
	}

	inline function get_wheel():Int {
		var activeList = [];
		for (t in activeTouches)
			if (t.pressed)
				activeList.push(t);

		if (activeList.length >= 2 && _lastTwoFingerCenterY != -1) {
			var currentCenterY = (activeList[0].y + activeList[1].y) / 2;
			return Std.int(_lastTwoFingerCenterY - currentCenterY);
		}
		return 0;
	}

	public function overlaps(spr:Sprite):Bool {
		for (t in activeTouches) {
			if (t.pressed && spr.hitTestPoint(t.x, t.y, true))
				return true;
		}
		return false;
	}

	public function overlapsComplex(spr:Sprite, onTouch:Void->Void = null):Bool {
		for (t in activeTouches) {
			if (spr.hitTestPoint(t.x, t.y, true)) {
				if (t.justPressed && onTouch != null)
					onTouch();
				return true;
			}
		}
		return false;
	}

	public function overlapsUltraComplex(spr:Sprite, onTouch:Void->Void = null):Bool {
		var t = getFirstTouch();
		if (t != null) {
			var isHit = spr.hitTestPoint(t.x, t.y, true);
			if (isHit && t.justPressed) {
				if (onTouch != null)
					onTouch();
				return true;
			}
		}
		return false;
	}
}

class SwipeUtil {
	private var startTouches:Map<Int, {x:Float, y:Float}> = new Map();
	private var lastSwipeDegrees:Float = -999;

	public function new() {}

	public function init(stage:Stage) {
		if (Multitouch.supportsTouchEvents) {
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, (e:TouchEvent) -> startTouches.set(e.touchPointID, {x: e.stageX, y: e.stageY}));
			stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
			stage.addEventListener(Event.ENTER_FRAME, (e) -> lastSwipeDegrees = -999);
		}
	}

	private function onTouchEnd(e:TouchEvent) {
		var start = startTouches.get(e.touchPointID);
		if (start != null) {
			var dx = e.stageX - start.x;
			var dy = e.stageY - start.y;
			var dist = Math.sqrt(dx * dx + dy * dy);

			if (dist > 20) {
				lastSwipeDegrees = Math.atan2(dy, dx) * (180 / Math.PI);
			}
			startTouches.remove(e.touchPointID);
		}
	}

	public var UP(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var LEFT(get, never):Bool;
	public var RIGHT(get, never):Bool;

	private inline function checkSwipe(min:Float, max:Float):Bool
		return lastSwipeDegrees >= min && lastSwipeDegrees <= max;

	inline function get_UP()
		return checkSwipe(-135, -45);

	inline function get_DOWN()
		return checkSwipe(45, 135);

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
