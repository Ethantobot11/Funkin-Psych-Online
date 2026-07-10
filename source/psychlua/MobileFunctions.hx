package psychlua;

import lime.ui.Haptic;
import flixel.util.FlxSave;
import psychlua.CustomSubstate;
import psychlua.FunkinLua;

class MobileFunctions
{
	public static function implement(funk:FunkinLua)
	{
		#if LUA_ALLOWED

        #end
		#if mobile
		funk.set("vibrate", function(duration:Null<Int>, ?period:Null<Int>)
		{
			if (period == null)
				period = 0;
			if (duration == null)
				return funk.luaTrace('vibrate: No duration specified.');
			return Haptic.vibrate(period, duration);
		});

		funk.set("touchJustPressed", ScreenUtil.touch.justPressed);
		funk.set("touchPressed", ScreenUtil.touch.pressed);
		funk.set("touchJustReleased", ScreenUtil.touch.justReleased);
		funk.set("touchPressedObject", function(object:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			if (obj == null)
			{
				funk.luaTrace('touchPressedObject: $object does not exist.');
				return false;
			}
			return ScreenUtil.touch.overlaps(obj) && ScreenUtil.touch.pressed;
		});

		funk.set("touchJustPressedObject", function(object:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			if (obj == null)
			{
				funk.luaTrace('touchJustPressedObject: $object does not exist.');
				return false;
			}
			return ScreenUtil.touch.overlaps(obj) && ScreenUtil.touch.justPressed;
		});

		funk.set("touchJustReleasedObject", function(object:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			if (obj == null)
			{
				funk.luaTrace('touchJustPressedObject: $object does not exist.');
				return false;
			}
			return ScreenUtil.touch.overlaps(obj) && ScreenUtil.touch.justReleased;
		});

		funk.set("touchOverlapsObject", function(object:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			if (obj == null)
			{
				funk.luaTrace('touchOverlapsObject: $object does not exist.');
				return false;
			}
			return ScreenUtil.touch.overlaps(obj);
		});
		#end
	}
}

#if android
class AndroidFunctions
{
	public static function implement(funk:FunkinLua)
	{
		#if LUA_ALLOWED
		var lua:State = funk.lua;

		funk.set("isDolbyAtmos", AndroidTools.isDolbyAtmos());
		funk.set("isAndroidTV", AndroidTools.isAndroidTV());
		funk.set("isTablet", AndroidTools.isTablet());
		funk.set("isChromebook", AndroidTools.isChromebook());
		funk.set("isDeXMode", AndroidTools.isDeXMode());
		funk.set("backJustPressed", FlxG.android.justPressed.BACK);
		funk.set("backPressed", FlxG.android.pressed.BACK);
		funk.set("backJustReleased", FlxG.android.justReleased.BACK);
		funk.set("menuJustPressed", FlxG.android.justPressed.MENU);
		funk.set("menuPressed", FlxG.android.pressed.MENU);
		funk.set("menuJustReleased", FlxG.android.justReleased.MENU);
		funk.set("getCurrentOrientation", () -> ScreenUtil.getCurrentOrientationAsString());
		funk.set("setOrientation", function(hint:Null<String>):Void
		{
			switch (hint.toLowerCase())
			{
				case 'portrait':
					hint = 'Portrait';
				case 'portraitupsidedown' | 'upsidedownportrait' | 'upsidedown':
					hint = 'PortraitUpsideDown';
				case 'landscapeleft' | 'leftlandscape':
					hint = 'LandscapeLeft';
				case 'landscaperight' | 'rightlandscape' | 'landscape':
					hint = 'LandscapeRight';
				default:
					hint = null;
			}
			if (hint == null)
				return funk.luaTrace('setOrientation: No orientation specified.');
			ScreenUtil.setOrientation(FlxG.stage.stageWidth, FlxG.stage.stageHeight, false, hint);
		});
		funk.set("minimizeWindow", () -> AndroidTools.minimizeWindow());
		funk.set("showToast", function(text:String, duration:Null<Int>, ?xOffset:Null<Int>, ?yOffset:Null<Int>)
		{
			if (text == null)
				return funk.luaTrace('showToast: No text specified.');
			else if (duration == null)
				return funk.luaTrace('showToast: No duration specified.');

			if (xOffset == null)
				xOffset = 0;
			if (yOffset == null)
				yOffset = 0;

			AndroidToast.makeText(text, duration, -1, xOffset, yOffset);
		});
		funk.set("isScreenKeyboardShown", () -> ScreenUtil.isScreenKeyboardShown());

		funk.set("clipboardHasText", () -> ScreenUtil.clipboardHasText());
		funk.set("clipboardGetText", () -> ScreenUtil.clipboardGetText());
		funk.set("clipboardSetText", function(text:Null<String>):Void
		{
			if (text != null) return funk.luaTrace('clipboardSetText: No text specified.');
			ScreenUtil.clipboardSetText(text);
		});

		funk.set("manualBackButton", () -> ScreenUtil.manualBackButton());

		funk.set("setActivityTitle", function(text:Null<String>):Void
		{
			if (text != null) return funk.luaTrace('setActivityTitle: No text specified.');
			ScreenUtil.setActivityTitle(text);
		});
		#end
	}
}
#end