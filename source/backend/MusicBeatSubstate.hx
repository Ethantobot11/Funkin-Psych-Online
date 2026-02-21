package backend;

import flixel.FlxSubState;
import flixel.FlxBasic;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.HScript;
#end

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;

	#if !SCRIPTING_ALLOWED
	public function new()
	{
		instance = this;
		mobileManager = new MobileControlManager(this);
		//controls.isInSubstate = true;
		super();
	}
	#end

	public var curSection:Int = 0;
	public var stepsToDo:Int = 0;

	public var lastBeat:Float = 0;
	public var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	public var curStepFloat:Float = 0;
	public var curBeatFloat:Float = 0;
	public static var stepsPerBeat:Float = 4;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	public var mobileManager:MobileControlManager;
	//makes code less messy & easier to write
	public inline function mobileButtonJustPressed(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS
		return mobileManager?.mobilePad?.justPressed(buttons);
		#else
		return false;
		#end
	}
	public inline function mobileButtonPressed(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS
		return mobileManager?.mobilePad?.pressed(buttons);
		#else
		return false;
		#end
	}
	public inline function mobileButtonJustReleased(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS
		return mobileManager?.mobilePad?.justReleased(buttons);
		#else
		return false;
		#end
	}
	public inline function mobileButtonReleased(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS
		return mobileManager?.mobilePad?.released(buttons);
		#else
		return false;
		#end
	}
	override function destroy()
	{
		if (mobileManager != null) mobileManager.destroy();

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurFloats();
		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateCurFloats():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		curStepFloat = lastChange.stepTime + ((Conductor.songPosition - lastChange.songTime) / lastChange.stepCrochet);
		curBeatFloat = curStepFloat / stepsPerBeat;
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	/**
	 * SCRIPTING STUFF
	 */
	#if SCRIPTING_ALLOWED

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: "data/states/PauseMenuSubstate.hx")
	 */
	public var stateScripts:ScriptPack;

	public var scriptsAllowed:Bool = true;

	public var scriptName:String = null;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		instance = this;
		mobileManager = new MobileControlManager(this);
		super();
		this.scriptName = scriptName;
	}

	function loadScript(?customPath:String) {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
				var filePath:String = "substates/" + scriptName;
				if (customPath != null)
					filePath = customPath;
				var path = Paths.script('data/' + filePath);
				var script = Script.create(path);
				if (script is DummyScript) {
				} else {
					script.remappedNames.set(script.fileName, '${script.fileName}');
					stateScripts.add(script);
					script.load();
					call('create');
				}
			}
		}
	}

	override function create()
	{
		loadScript();
		super.create();
	}
	#end

	public override function tryUpdate(elapsed:Float):Void
	{
		if (persistentUpdate || subState == null) {
			call("preUpdate", [elapsed]);
			update(elapsed);
			call("postUpdate", [elapsed]);
		}

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed);
		}
	}

	override function close() {
		var event = event("onClose", new CancellableEvent());
		if (!event.cancelled) {
			super.close();
			call("onClosePost");
		}
	}

	public override function createPost() {
		super.createPost();
		trace("Function should call postCreate");
		call("postCreate");
	}

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			return stateScripts.call(name, args);
		else
			trace("stateScripts is a null");
		#end
		return defaultVal;
	}

	public function setToHScript(name:String, ?variable:Dynamic) {
		// calls the function on the assigned script
		if(stateScripts != null)
			return stateScripts.set(name, variable);
	}

	//do not ask why, ask why not?
	public override function add(basic:FlxBasic):FlxBasic {
		super.add(basic);
		#if macro
		setToHScript(nameOf(basic), basic);
		#end
	}

	#if macro
	static macro function nameOf(e:Expr):Expr {
		Context.typeExpr(e);
		return switch (e.expr) {
			case EConst(CIdent(s)):
				macro $v{s};
			default:
				Context.error("nameOf requires an indentifier as argument", Context.currentPos());
		}
	}
	#end

	public function event<T:CancellableEvent>(name:String, event:T):T {
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			stateScripts.call(name, [event]);
		#end
		return event;
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}
}
