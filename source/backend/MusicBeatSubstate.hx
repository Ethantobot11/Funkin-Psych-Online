package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	#if FEATURE_TOUCH_CONTROLS
	private var lastDPad:String;
	private var lastButton:String;
	private var lastHitbox:String;
	public var mobileManager:MobileControls;
	#end
	public static var instance:MusicBeatSubstate;
	public function new(bgColor:FlxColor = FlxColor.TRANSPARENT) {
		super(bgColor);
		instance = this;
		#if FEATURE_TOUCH_CONTROLS
		mobileManager = new MobileControls();
		#end
	}

	#if FEATURE_TOUCH_CONTROLS
	public override function create() {
		super.create();
		add(mobileManager);
	}
	#end

	public function addControl(DPad:String, Button:String) {
		#if FEATURE_TOUCH_CONTROLS
		if (DPad != null && DPad != "") mobileManager.addDPad(DPad);
		if (Button != null && Button != "") mobileManager.addButton(Button);
		mobileManager.addDPadCamera();
		mobileManager.addButtonCamera();
		mobileManager.alpha = ClientPrefs.data.controlAlpha;
		lastDPad = DPad;
		lastButton = Button;
		controls.isInSubstate = true;
		#end
	}

	public function addHitbox(Hitbox:String) {
		#if FEATURE_TOUCH_CONTROLS
		if (Hitbox != null && Hitbox != "") mobileManager.addHitbox(Hitbox);
		mobileManager.alpha = ClientPrefs.data.controlAlpha;
		lastHitbox = Hitbox;
		#end
	}

	public function checkControl(key:String, type:String) {
		#if FEATURE_TOUCH_CONTROLS
		return mobileManager.checkState(key, type) == true;
		#else
		return false;
		#end
	}

	override public function openSubState(substate:flixel.FlxSubState) {
		super.openSubState(substate);
		#if FEATURE_TOUCH_CONTROLS
		mobileManager.removeDPad();
		mobileManager.removeButton();
		#end
	}

	override public function closeSubState() {
		super.closeSubState();
		#if FEATURE_TOUCH_CONTROLS
		mobileManager.removeDPad();
		mobileManager.removeButton();

		mobileManager.addDPad(lastDPad);
		mobileManager.addButton(lastButton);

		mobileManager.addDPadCamera();
		mobileManager.addButtonCamera();
		#end
		instance = this; //funny bruh -KralOyuncu
	}

	public var cannotBeNull:Bool = false;
	override public function destroy() {
		super.destroy();
		if (!cannotBeNull) instance = null;
		cannotBeNull = false;
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

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
		FlxG.mouse.useSystemCursor = true;
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
}
