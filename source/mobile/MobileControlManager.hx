package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;

/**
 * A simple mobile manager for who doesn't want to create these manually
 * if you're making big projects or have a experience to how controls work, create the controls yourself
 */
class MobileControlManager {
	public var currentState:Dynamic;

	#if TOUCH_CONTROLS
	public var mobilePad:FunkinMobilePad;
	public var mobilePadCam:FlxCamera;
	public var joyStickCam:FlxCamera;
	public var joyStick:FunkinJoyStick;
	public var hitboxCam:FlxCamera;
	public var hitbox:FunkinHitbox;
	#end

	public function new(state:Dynamic):Void
	{
		this.currentState = state;
		#if TOUCH_CONTROLS
		trace("MobileControlManager initialized.");
		#else
		trace("MobileControls disabled for this build");
		#end
	}

	//for lua shit
	public function makeMobilePad(DPad:String, Action:String)
	{
		#if TOUCH_CONTROLS
		if (mobilePad != null) removeMobilePad();
		mobilePad = new FunkinMobilePad(DPad, Action, ClientPrefs.data.mobilePadAlpha);
		#end
	}

	public function addMobilePad(DPad:String, Action:String)
	{
		#if TOUCH_CONTROLS
		makeMobilePad(DPad, Action);
		currentState.add(mobilePad);
		#end
	}

	public function removeMobilePad():Void
	{
		#if TOUCH_CONTROLS
		if (mobilePad != null)
		{
			currentState.remove(mobilePad);
			mobilePad = FlxDestroyUtil.destroy(mobilePad);
		}

		if(mobilePadCam != null)
		{
			FlxG.cameras.remove(mobilePadCam);
			mobilePadCam = FlxDestroyUtil.destroy(mobilePadCam);
		}
		#end
	}

	public function addMobilePadCamera(defaultDrawTarget:Bool = false):Void
	{
		#if TOUCH_CONTROLS
		mobilePadCam = new FlxCamera();
		mobilePadCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobilePadCam, defaultDrawTarget);
		mobilePad.cameras = [mobilePadCam];
		#end
	}

	public function makeHitbox(?mode:String, ?hints:Bool) {
		#if TOUCH_CONTROLS
		if (hitbox != null) removeHitbox();
		hitbox = new FunkinHitbox(mode, hints, ClientPrefs.data.hitboxAlpha);
		#end
	}

	public function addHitbox(?mode:String, ?hints:Bool) {
		#if TOUCH_CONTROLS
		makeHitbox(mode, hints);
		currentState.add(hitbox);
		#end
	}

	public function removeHitbox():Void
	{
		#if TOUCH_CONTROLS
		if (hitbox != null)
		{
			currentState.remove(hitbox);
			hitbox = FlxDestroyUtil.destroy(hitbox);
		}

		if(hitboxCam != null)
		{
			FlxG.cameras.remove(hitboxCam);
			hitboxCam = FlxDestroyUtil.destroy(hitboxCam);
		}
		#end
	}

	public function addHitboxCamera(defaultDrawTarget:Bool = false):Void
	{
		#if TOUCH_CONTROLS
		hitboxCam = new FlxCamera();
		hitboxCam.bgColor.alpha = 0;
		FlxG.cameras.add(hitboxCam, defaultDrawTarget);
		hitbox.cameras = [hitboxCam];
		#end
	}

	public function makeJoyStick(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void, size:Float = 1):Void
	{
		#if TOUCH_CONTROLS
		if (joyStick != null) removeJoyStick();
		joyStick = new FunkinJoyStick(x, y, graphic, onMove);
		joyStick.scale.set(size, size);
		#end
	}

	public function addJoyStick(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void, size:Float = 1):Void
	{
		#if TOUCH_CONTROLS
		makeJoyStick(x, y, graphic, onMove, size);
		currentState.add(joyStick);
		#end
	}

	public function removeJoyStick():Void
	{
		#if TOUCH_CONTROLS
		if (joyStick != null)
		{
			currentState.remove(joyStick);
			joyStick = FlxDestroyUtil.destroy(joyStick);
		}

		if(joyStickCam != null)
		{
			FlxG.cameras.remove(joyStickCam);
			joyStickCam = FlxDestroyUtil.destroy(joyStickCam);
		}
		#end
	}

	public function addJoyStickCamera(defaultDrawTarget:Bool = false):Void {
		#if TOUCH_CONTROLS
		joyStickCam = new FlxCamera();
		joyStickCam.bgColor.alpha = 0;
		FlxG.cameras.add(joyStickCam, defaultDrawTarget);
		joyStick.cameras = [joyStickCam];
		#end
	}

	public function destroy():Void {
		#if TOUCH_CONTROLS
		removeMobilePad();
		removeHitbox();
		removeJoyStick();
		#end
	}
}
