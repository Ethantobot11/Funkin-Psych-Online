package backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;

class MusicBeatState extends FlxUIState
{
	/** stops time **/
	private var theWorld:Bool = false;

	#if FEATURE_TOUCH_CONTROLS
	public var mobileManager:MobileControls;
	#end

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	public static var camBeat:FlxCamera;

	#if FEATURE_TOUCH_CONTROLS
	private var lastDPad:String;
	private var lastButton:String;
	private var lastHitbox:String;
	#end
	public static var instance:MusicBeatState;
	public function addControl(DPad:String, Button:String) {
		#if FEATURE_TOUCH_CONTROLS
		if (DPad != null && DPad != "") mobileManager.addDPad(DPad);
		if (Button != null && Button != "") mobileManager.addButton(Button);
		mobileManager.addDPadCamera();
		mobileManager.addButtonCamera();
		mobileManager.alpha = ClientPrefs.data.controlAlpha;
		lastDPad = DPad;
		lastButton = Button;
		#end
	}

	public function addHitbox(Hitbox:String) {
		#if FEATURE_TOUCH_CONTROLS
		if (Hitbox != null && Hitbox != "") mobileManager.addHitbox(Hitbox);
		mobileManager.addHitboxCamera();
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
		controls.isInSubstate = false;
		mobileManager.removeDPad();
		mobileManager.removeButton();

		mobileManager.addDPad(lastDPad);
		mobileManager.addButton(lastButton);

		mobileManager.addDPadCamera();
		mobileManager.addButtonCamera();
		#end
	}

	public function new() {
		super();
		#if FEATURE_TOUCH_CONTROLS
		mobileManager = new MobileControls();
		#end
	}

	override function create() {
		instance = this;
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		#if FEATURE_TOUCH_CONTROLS
		add(mobileManager);
		#end
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		if (theWorld)
			return super.update(elapsed);

		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

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
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

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

	// credit to https://github.com/DetectiveBaldi/FNF-PsychEngine/blob/36e982e2e3e78b9b7939ecfff06f5ffdbcd9cca6/source/backend/MusicBeatState.hx
	override function startOutro(onOutroComplete:() -> Void):Void {
		if (!FlxTransitionableState.skipNextTransIn) {
			FlxG.state.openSubState(new CustomFadeTransition(0.5, false));

			CustomFadeTransition.finishCallback = onOutroComplete;

			return;
		}

		FlxTransitionableState.skipNextTransIn = false;

		onOutroComplete();
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	public override function destroy() {
		super.destroy();
		instance = null;
	}
}
