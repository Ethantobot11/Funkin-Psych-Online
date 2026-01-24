package funkin.backend;

import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;

/*
A Simple class the returns Codename Engine's FunkinSprite requests to FlxAnimate (used for Cyber Sensation)
*/
#if flxanimate
class FunkinSprite extends FlxAnimate
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(?x:Float = 0, ?y:Float = 0, ?path:String, ?settings:Settings)
	{
		super(x, y, path, settings);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		anim.play(name, forced, reverse, startFrame);

		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}
	
	public function loadSprite(Path:String)
	{
		Paths.loadAnimateAtlas(this, Path);
	}

	public function addOffset(name:String, x:Float, y:Float)
	{
		animOffsets.set(name, [x, y]);
	}
}
#end