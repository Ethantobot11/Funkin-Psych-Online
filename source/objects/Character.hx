package objects;

import online.away.AnimatedSprite3D;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import tjson.TJSON as Json;
import backend.Song;
import backend.Section;
import states.stages.objects.TankmenBG;
import online.GameClient;
import flixel.addons.effects.FlxSkewedSprite;

// Well Cne imports
import sys.FileSystem;
import flixel.util.FlxSpriteUtil;
import openfl.display.Graphics;
import flixel.util.typeLimit.OneOfTwo;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import funkin.backend.scripting.HScript;
import funkin.backend.FunkinSprite;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.interfaces.IOffsetCompatible;
import funkin.backend.scripting.events.character.*;
import funkin.backend.scripting.events.sprite.*;
import funkin.backend.scripting.events.PointEvent;
import funkin.backend.scripting.events.DrawEvent;
import funkin.backend.utils.MatrixUtil;
import funkin.backend.utils.XMLUtil;
import haxe.Exception;
import haxe.io.Path;
import haxe.xml.Access;
import openfl.geom.ColorTransform;

using StringTools;
using backend.CoolUtil;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	@:optional var vocals_file:String;
	@:optional var dead_character:Null<String>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional var sound:String;
	@:optional var flip_x:Bool;
}

class Character extends FunkinMergedSprite implements IBeatReceiver implements IOffsetCompatible implements IPrePostDraw
{
	/* Codename Engine */
	public var canUseStageCamOffset:Bool = true; //StageOffsets can be disabled for cne chars, default is true
	public var groupEnabled:Bool = true; //cne doesn't have groups for chars, so you can disable this, default is true

	public var lastHit:Float = Math.NEGATIVE_INFINITY;
	public var holdTime:Float = 4;

	public var playerOffsets:Bool = false;

	public var icon:String = null;
	public var iconColor:Null<FlxColor> = null;

	public var cameraOffset:FlxPoint = FlxPoint.get(0, 0);
	public var globalOffset:FlxPoint = FlxPoint.get(0, 0);
	public var extraOffset:FlxPoint = FlxPoint.get(0, 0);

	public var xml:Access;
	public var scripts:ScriptPack;
	public var xmlImportedScripts:Array<XMLImportedScriptInfo> = [];
	public var script(default, set):Script;

	public function prepareInfos(node:Access)
		return XMLImportedScriptInfo.prepareInfos(node, scripts, (infos) -> xmlImportedScripts.push(infos));

	@:noCompletion var __stunnedTime:Float = 0;
	@:noCompletion var __lockAnimThisFrame:Bool = false;

	@:noCompletion var __switchAnims:Bool = true;

	/* PsychOnline */
	public var sprite3D:AnimatedSprite3D;

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var isMissing:Bool = false;

	public var colorTween:FlxTween;
	// uh... check if opponent is holding
	public var noteHold(default, set):Bool = false;
	function set_noteHold(v) {
		if (PlayState.isCharacterPlayer(this) && noteHold != v) {
			GameClient.send("noteHold", v);
		}
		return noteHold = v;
	}
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var vocalsFile:String = '';
	public var deadName:String = null;

	public var gameIconIndex:Int = 0;
	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	var ogPositionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	// x offset index (for multiple characters)
	public var ox:Int = 0;

	public var hasMissAnimations:Bool = true;
	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var isSkin:Bool = false;
	public var loadFailed:Bool = false;

	public var animSounds:Map<String, openfl.media.Sound> = new Map<String, openfl.media.Sound>();
	public var sound:FlxSound;

	public var modDir:String = null;

	public var animSuffix:String;

	public var onAtlasAnimationComplete:String->Void;

	public var Custom(get, set):Bool;
	
	function set_Custom(value:Bool):Bool
	{
		return this.isSkin = value;
	}

	function get_Custom():Bool
	{
		return this.isSkin;
	}

	public var custom(get,never):Bool;

	function get_custom():Bool
	{
		return this.isSkin;
	}

	function set_custom(value:Bool):Bool
	{
		return this.isSkin = value;
	}
	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static function getCharacterFile(character:String, ?instance:Character):CharacterFile {
		var characterPath:String = 'characters/' + character + '.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FunkinFileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FunkinFileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			if (instance != null)
				instance.loadFailed = true;
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		}

		var rawJson = FunkinFileSystem.getText(path);
		if (rawJson == null) return null;
		return cast Json.parse(rawJson);
	}

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?isSkin:Bool = false, ?charType:String) {
		super(x, y);

		modDir = Mods.currentModDirectory;
		var pathChar:String = Paths.getPath('data/characters/$character.xml', TEXT, null, true);
		#if MODS_ALLOWED
		if (FunkinFileSystem.exists(pathChar))
		#else
		if (Assets.exists(pathChar))
		#end
		{
			if (isPlayer) healthColorArray = [0, 255, 0];
			trace("Codename Char Used");
			isCodenameChar = true;
			animOffsets_CNE = new Map<String, FlxPoint>();
			curCharacter = character != null ? character : Flags.DEFAULT_CHARACTER;
			this.isPlayer = isPlayer;
			__switchAnims = switchAnims;

			antialiasing = true;

			xml = getXMLFromCharName(this);

			if(!disableScripts)
				script = Script.create(Paths.script('data/characters/$curCharacter', null, false, ["hscript", "hsc", "hxs"]));
			if (script == null)
				script = new DummyScript(curCharacter);

			script.load();

			scripts.call("create");
			buildCharacter(xml);
			scripts.call("postCreate");
		}
		else {
			trace("Psych Char Used");
			isCodenameChar = false;
			animOffsets = new Map<String, Array<Dynamic>>();
			curCharacter = character;
			this.isPlayer = isPlayer;
			this.isSkin = isSkin;
			var library:String = null;
			switch (curCharacter) {
				// case 'your character name in case you want to hardcode them instead':

				default:
					var json:CharacterFile = getCharacterFile(curCharacter, this);
					isAnimateAtlas = false;

					var split:Array<String> = json.image.split(',');
					imageFile = split[0].trim();

					#if MODS_ALLOWED
					var modAnimToFind:String = Paths.modFolders('images/' + imageFile + '/Animation.json');
					var animToFind:String = Paths.getPath('images/' + imageFile + '/Animation.json', TEXT);
				if (FunkinFileSystem.exists(modAnimToFind) || FunkinFileSystem.exists(animToFind) || Assets.exists(animToFind))
					#else
					if (Assets.exists(Paths.getPath('images/' + imageFile + '/Animation.json', TEXT)))
					#end
					isAnimateAtlas = true;

					if (!isAnimateAtlas) {
						frames = Paths.getAtlas(imageFile);
					}
					#if flxanimate
					else
					{
						atlas = new FlxAnimate();
						atlas.showPivot = false;
						try
						{
							Paths.loadAnimateAtlas(atlas, imageFile);
						}
						catch(e:Dynamic)
						{
							FlxG.log.warn('Could not load atlas ${imageFile}: $e');
							trace('Could not load atlas ${imageFile}: $e');
						}
					}
					#end

					if (frames != null) {
						if (!loadFailed && graphic.bitmap != null && FlxG.state is PlayState && PlayState.instance.stage3D != null) {
							sprite3D = PlayState.instance.stage3D.createSprite(charType, true, graphic.bitmap);
						}

						for (_imgFile in split) {
							final imgFile = _imgFile.trim(); 
							if (!imageFile.contains(imgFile))
								imageFile += ',$imgFile';
							var daAtlas = Paths.getAtlas(imgFile);
							if (daAtlas != null)
								cast(frames, FlxAtlasFrames).addAtlas(daAtlas);
						}
					}

					if (json.scale != 1) {
						jsonScale = json.scale;
						scale.set(jsonScale, jsonScale);
						updateHitbox();
					}

					// positioning
					ogPositionArray = positionArray = json.position;
					cameraPosition = json.camera_position;

					// data
					healthIcon = json.healthicon;
					singDuration = json.sing_duration;
					flipX = (json.flip_x == true);
					if (json.flip_x == true) { //just for test
						swapLeftRightAnimations(true);
					}

					if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
						healthColorArray = json.healthbar_colors;

					vocalsFile = json.vocals_file ?? curCharacter;
				
					deadName = json.dead_character;

					// antialiasing
					noAntialiasing = (json.no_antialiasing == true);
					antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

					// animations
					animationsArray = json.animations;
					if (animationsArray != null && animationsArray.length > 0) {
						for (anim in animationsArray) {
							var animAnim:String = '' + anim.anim;
							var animName:String = '' + anim.name;
							var animFps:Int = anim.fps;
							var animLoop:Bool = !!anim.loop; // Bruh
							var animIndices:Array<Int> = anim.indices;
							var flipX:Bool = !!anim.flip_x;
							if(!isAnimateAtlas)
							{
								if (animIndices != null && animIndices.length > 0) {
									animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, flipX);
								}
								else {
									animation.addByPrefix(animAnim, animName, animFps, animLoop, flipX);
								}
							}
							#if flxanimate
							else
							{
								// no flipX in flxanimate bcs not supported bye
								if(animIndices != null && animIndices.length > 0)
									atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
								else
									atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
							}
							#end

							if (anim.offsets != null && anim.offsets.length > 1) 
								addOffsetPsych(anim.anim, anim.offsets[0], anim.offsets[1]);
							else
								addOffsetPsych(anim.anim, 0, 0);

							if (anim.sound != null) {
								var sound = Paths.sound(anim.sound);
								if (sound != null)
									animSounds.set(animAnim, sound);
							}
						}
					}
					else {
						quickAnimAdd('idle', 'BF idle dance');
					}

					setup3D();

					#if flxanimate
					if(isAnimateAtlas) copyAtlasValuesPsych();
					#end
					// trace('Loaded file to character ' + curCharacter);
			}
			originalFlipX = flipX;

			if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
			recalculateDanceIdle();
			dance();

			if (isPlayer) {
				flipX = !flipX;
			}

			if (curCharacter.endsWith('-speaker') && loadMappedAnims()) {
				// skipDance = true;
				playAnim("shoot1");
			}
		}
	}

	public function setup3D() {
		if (sprite3D != null) {
			sprite3D.addAnimationsFromFlxSprite(this);
			for (name => offset in animOffsets) {
				sprite3D.animations.get(name).setOffset(offset[0], offset[1]);
			}
			sprite3D.scaleX = jsonScale;
			sprite3D.scaleY = jsonScale;
			sprite3D.antialiasing = !noAntialiasing;
			visible = false;
		}
	}

	public var noAnimationBullshit:Bool = false;
	public var noHoldBullshit:Bool = false;

	override function update(elapsed:Float) {
		if (isCodenameChar) {
			super.update(elapsed);
			scripts.call("update", [elapsed]);
			if (stunned) {
				__stunnedTime += elapsed;
				if (__stunnedTime > Flags.STUNNED_TIME)
					stunned = false;
			}

			if (!__lockAnimThisFrame && lastAnimContext != DANCE)
				tryDance();

			__lockAnimThisFrame = false;
		}
		else
		{
			if(isAnimateAtlas) atlas.update(elapsed);
			if (sprite3D != null) {
				sprite3D.play(animation.name, animation.curAnim.curFrame, true);
			}

			if (noAnimationBullshit) {
				super.update(elapsed);
				return;
			}

			if (!debugMode && !isAnimationNull()) {
				if (heyTimer > 0) {
					heyTimer -= elapsed * (PlayState.instance?.playbackRate ?? 1);
					if (heyTimer <= 0) {
						var anim:String = getAnimationName();

						if (specialAnim && anim == 'hey' || anim == 'cheer') {
							specialAnim = false;
							dance();
						}
						heyTimer = 0;
					}
				}
				else if (specialAnim && isAnimationFinished()) {
					specialAnim = false;
					dance();
				}
				else if ((getAnimationName().endsWith('miss') || isMissing) && isAnimationFinished()) {
					dance();
					finishAnimation();
				}

				// apparently animationNotes can be null, great!
				if (animationNotes != null && animationNotes.length > 0) {
					if (Conductor.songPosition > animationNotes[0][0]) {
						var noteData:Int = 1;
						if (animationNotes[0][1] > 2)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
				}

				if (getAnimationName().startsWith('sing'))
					holdTimer += elapsed;
				else if (PlayState.isCharacterPlayer(this) || GameClient.isConnected())
					holdTimer = 0;

				if (!noHoldBullshit && holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration) {
					dance();
					holdTimer = 0;
				}

				var name:String = getAnimationName();
				if(isAnimationFinished() && animOffsets.exists('$name-loop'))
					playAnim('$name-loop');
			}
			super.update(elapsed);
		}
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = !isAnimateAtlas ? animation.curAnim.name : atlas.anim.curSymbol.name;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;
		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 
		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance() {
		if (isCodenameChar) {
			if(debugMode) return;

			var event = EventManager.get(DanceEvent).recycle(danced);
			scripts.call("onDance", [event]);
			if (event.cancelled) return;

			if (danceIdle)
				playAnim_CNE(((danced = !danced) ? 'danceLeft' : 'danceRight') + idleSuffix, DANCE);
			else
				playAnim_CNE('idle' + idleSuffix, DANCE);
		} else {
			if (!debugMode && !skipDance && !specialAnim) {
				if (danceIdle) {
					danced = !danced;

					if (danced)
						playAnim('danceRight' + idleSuffix);
					else
						playAnim('danceLeft' + idleSuffix);
				}
				else if (animOffsets.exists('idle' + idleSuffix)) {
					playAnim('idle' + idleSuffix);
				}
			}
		}
	}

	final randomDirections:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	var colorTransformBefore:Array<Float> = [1, 1, 1]; // red, green, blue
	var colorTransformWasChanged:Bool = false;

	public override function playAnim(?AnimName:String, ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Int = 0, ?Context:PlayAnimContext = NONE):Void
	{
		super.playAnim();
		if (isCodenameChar) return playAnim_CNE(AnimName, Force, Context, Reversed, Frame); //Play Anim Fix IG
		if (AnimName == null)
			return;

		if (animSuffix != null)
			AnimName += animSuffix;

		if(colorTransform != null && colorTransformWasChanged) {
			colorTransform.redMultiplier = colorTransformBefore[0];
			colorTransform.greenMultiplier = colorTransformBefore[1];
			colorTransform.blueMultiplier = colorTransformBefore[2];
		}

		specialAnim = false;
		isMissing = AnimName.endsWith("miss");

		if (AnimName == "taunt" || AnimName == "taunt-alt") {
			specialAnim = true;
			heyTimer = 1;
		}

		if (!animExists(AnimName)) {
			if ((AnimName == "taunt" || AnimName == "taunt-alt") && !animExists(AnimName)) {
				if (AnimName == "taunt-alt")
					AnimName = "hey-alt";
				else
					AnimName = "hey";
			}

			if (AnimName.endsWith("-alt") && !animExists(AnimName)) {
				AnimName = AnimName.substring(0, AnimName.length - "-alt".length);
			}
			
			if (AnimName == "hurt" && !animExists(AnimName)) {
				AnimName = 'sing' + randomDirections[FlxG.random.int(0, randomDirections.length - 1)] + 'miss';
			}

			if (AnimName == "hey" && !animExists(AnimName)) {
				if (curCharacter.startsWith("tankman")) {
					AnimName = "singUP-alt";
				}
				else {
					AnimName = "singUP";
					// specialAnim = false;
					// heyTimer = 0;
				}
			}

			if (AnimName.startsWith("sing") && !animExists(AnimName)) {
				for (anim in ['singLEFT', 'singRIGHT', 'singODD', 'singUP', 'singDOWN']) {
					if (AnimName.startsWith(anim)) {
						AnimName = anim + (AnimName.contains('miss') ? 'miss' : '');
						break;
					}
				}
			}

			if (AnimName.startsWith("singODD") && !animExists(AnimName)) {
				AnimName = 'singUP' + (AnimName.contains('miss') ? 'miss' : '');
			}

			if (AnimName.endsWith("miss") && !animExists(AnimName)) {
				AnimName = AnimName.substring(0, AnimName.length - "miss".length);

				colorTransformBefore = [colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform.blueMultiplier];
				colorTransformWasChanged = true;

				colorTransform.redMultiplier = 0.5;
				colorTransform.greenMultiplier = 0.3;
				colorTransform.blueMultiplier = 0.5;
			}
		}

		if (animSounds != null /* ?? */ && animSounds.exists(AnimName)) {
			if (sound != null) {
				sound.stop();
				sound.destroy();
				sound = null;
			}

			sound = FlxG.sound.play(animSounds.get(AnimName));
			if (sound != null) {
				sound.onComplete = () -> {
					sound.destroy();
					sound = null;
				};
			}
		}

		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		else {
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.anim.onComplete.add(() -> {
				if (onAtlasAnimationComplete != null)
					onAtlasAnimationComplete(AnimName);
			});
		}

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName)) {
			offset.set(daOffset[0], daOffset[1]);
		}

		if (curCharacter.startsWith('gf')) {
			if (AnimName == 'singLEFT') {
				danced = true;
			}
			else if (AnimName == 'singRIGHT') {
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}

		if (AnimName == 'redheadsAnim') {
			animSuffix = '-bloody';
		}
	}

	/**
	 * this nullifies the positions set in the character data
	 * and replaces them with v-slice-like positioning
	 * *unused*
	 */
	public function setPositionToFeet(v:Bool) {
		if (!v) {
			positionArray[0] = ogPositionArray[0];
			positionArray[1] = ogPositionArray[1];
			return;
		}

		positionArray[0] = -(width / 2) + ogPositionArray[0];
		positionArray[1] = -(height) + ogPositionArray[1];
	}

	public function animExists(AnimName:String) {
		return animOffsets.exists(AnimName);
	}

	function loadMappedAnims():Bool {
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		if (noteData == null)
			return false;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
		return true;
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if (settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffsetPsych(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		if(!isAnimateAtlas)
			animation.addByPrefix(name, anim, 24, false);
		#if flxanimate
		else
			atlas.anim.addBySymbol(name, anim, 24, false);
		#end
	}

	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;

	public function copyAtlasValuesPsych()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}
	
	public override function draw()
	{
		if(isAnimateAtlas)
		{
			copyAtlasValuesPsych();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function destroyAtlas()
	{
		if (atlas != null)
			atlas = FlxDestroyUtil.destroy(atlas);
	}
	#end

	override public function destroy() {
		if (isCodenameChar) {
			if(scripts != null) {
				scripts.call('destroy');
				scripts.destroy();
			}
			super.destroy();

			cameraOffset.put();
			globalOffset.put();
			extraOffset.put();
		} else {
			super.destroy();

			if (sound != null) {
				sound.stop();
				sound.destroy();
				sound = null;
			}

			#if flxanimate
			destroyAtlas();
			#end
		}
	}

	public function onCombo(from:Int, to:Int) {}
	public function onHealth(from:Float, to:Float) {}
	
	/* Codename Engine */

	@:noCompletion var __swappedLeftRightAnims:Bool = false;
	@:noCompletion var __autoInterval:Bool = false;

	public function fixChar(switchAnims:Bool = false, autoInterval:Bool = false) {
		if ((isDanceLeftDanceRight = hasAnimation_CNE("danceLeft") && hasAnimation_CNE("danceRight")) && autoInterval)
			beatInterval = 1;
		__autoInterval = autoInterval;

		// character is flipped
		if (isPlayer != playerOffsets && switchAnims)
			swapLeftRightAnimations();

		if (isPlayer) flipX = !flipX;
		__baseFlipped = flipX;
	}

	public function swapLeftRightAnimations() {
		CoolUtil.switchAnimFrames(animation.getByName('singRIGHT'), animation.getByName('singLEFT'));
		CoolUtil.switchAnimFrames(animation.getByName('singRIGHTmiss'), animation.getByName('singLEFTmiss'));

		switchOffset('singLEFT', 'singRIGHT');
		switchOffset('singLEFTmiss', 'singRIGHTmiss');

		__swappedLeftRightAnims = true;
	}

	@:noCompletion var __baseFlipped:Bool = false;
	@:noCompletion var isDanceLeftDanceRight:Bool = false;

	public function tryDance() {
		var event = new CancellableEvent();
		script.call("onTryDance", [event]);
		if (event.cancelled)
			return;

		switch (lastAnimContext) {
			case SING | MISS:
				if (lastHit + (Conductor.stepCrochet * holdTime) < Conductor.songPosition)
					dance();
			case DANCE:
				dance();
			case LOCK:
				if (getAnimName() == null)
					dance();
			default:
				if (getAnimName() == null || isAnimFinished())
					dance();
		}
	}

	/**
	 * Whenever the character should dance on beat or not.
	 */
	public var danceOnBeat:Bool = true;
	public override function beatHit(curBeat:Int) {
		if (isCodenameChar) {
			scripts.call("beatHit", [curBeat]);

			if (skipNegativeBeats && curBeat < 0) return;
			if (danceOnBeat && (curBeat + beatOffset) % (beatInterval * CoolUtil.maxInt(Math.floor(4 / MusicBeatState.stepsPerBeat), 1)) == 0 && !__lockAnimThisFrame)
				tryDance();
		}
	}

	public override function measureHit(curMeasure:Int)
		script.call("measureHit", [curMeasure]);

	public override function stepHit(curStep:Int)
		scripts.call("stepHit", [curStep]);

	@:noCompletion var __reverseDrawProcedure:Bool = false;
	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (__reverseDrawProcedure) {
			scale.x *= -1;
			var bounds:FlxRect = super.getScreenBounds(newRect, camera);
			scale.x *= -1;
			return bounds;
		}
		return super.getScreenBounds(newRect, camera);
	}

	public override function isOnScreen(?camera:FlxCamera):Bool {
		if (debugMode) return true;
		return super.isOnScreen(camera);
	}

	public function isFlippedOffsets()
		return debugMode ? false : (isPlayer != playerOffsets) != (flipX != __baseFlipped);

	var __reversePreDrawProcedure:Bool = false;

	public function preDraw() {
		if (!ghostDraw) {
			x += extraOffset.x;
			y += extraOffset.y;
		}

		if (__reversePreDrawProcedure = isFlippedOffsets()) {
			__reverseDrawProcedure = true;
			flipX = !flipX;
			scale.x *= -1;
		}
	}

	public function postDraw() {
		if (__reversePreDrawProcedure) {
			flipX = !flipX;
			scale.x *= -1;
			__reverseDrawProcedure = false;
		}

		if (!ghostDraw) {
			x -= extraOffset.x;
			y -= extraOffset.y;
		}
	}

	public var ghostDraw:Bool = false;

	public var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	public inline function getSingAnim(direction:Int, suffix:String = ""):String
		return singAnims[direction % singAnims.length] + suffix;

	/**
	 * Like `playSingAnimUnsafe` but checks if the character has the animation with the suffix part, otherwise it plays the animation without the suffix part.
	 */
	public function playSingAnim(direction:Int, suffix:String = "", Context:PlayAnimContext = SING, ?Force:Null<Bool> = null, Reversed:Bool = false, Frame:Int = 0)
	{
		var event = EventManager.get(DirectionAnimEvent).recycle(getSingAnim(direction, suffix), direction, suffix, Context, Reversed, Frame, Force);
		script.call("onPlaySingAnim", [event]);
		if (event.cancelled) return;

		playSingAnimUnsafe(event.direction, hasAnimation_CNE(event.animName) ? event.suffix : "", event.context, event.force, event.reversed, event.frame);
	}

	public function playSingAnimUnsafe(direction:Int, suffix:String = "", Context:PlayAnimContext = SING, Force:Bool = true, Reversed:Bool = false, Frame:Int = 0) {
		var event = EventManager.get(DirectionAnimEvent).recycle(getSingAnim(direction, suffix), direction, suffix, Context, Reversed, Frame, Force);
		script.call("playSingAnimUnsafe", [event]);
		if (event.cancelled) return;

		playAnim_CNE(event.animName, event.force, event.context, event.reversed, event.frame);
	}

	public override function playAnim_CNE(AnimName:String, ?Force:Bool, Context:PlayAnimContext = NONE, Reversed:Bool = false, Frame:Int = 0) {
		var event = EventManager.get(PlayAnimEvent).recycle(AnimName, Force, Reversed, Frame, Context);
		scripts.call("onPlayAnim", [event]);
		if (event.cancelled) return;

		super.playAnim_CNE(event.animName, event.force, event.context, event.reverse, event.startingFrame);

		offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
		if (event.context == SING || event.context == MISS)
			lastHit = Conductor.songPosition;
	}

	public inline function getCameraPosition() {
		var midpoint:FlxPoint = getMidpoint();
		var event = EventManager.get(PointEvent).recycle(
			midpoint.x + (isPlayer ? -100 : 150) + globalOffset.x + cameraOffset.x,
			midpoint.y - 100 + globalOffset.y + cameraOffset.y);
		scripts.call("onGetCamPos", [event]);

		midpoint.put();
		return new FlxPoint(event.x, event.y);
	}

	public dynamic function getCharacterCamPos(?pos:FlxPoint = null, ?ignoreInvisible:Bool = true):CamPosData {
		if (pos == null) pos = FlxPoint.get();
		var amount = 0;
		var cpos = getCameraPosition();
		pos.x += cpos.x;
		pos.y += cpos.y;
		amount++;
		//cpos.put(); // not actually in the pool, so no need
		if (amount > 0) {
			pos.x /= amount;
			pos.y /= amount;
		}
		return new CamPosData(pos, amount);
	}

	public inline function getCameraPositionAsPsych(?getX:Bool) {
		var midpoint:FlxPoint = getMidpoint();
		var event = EventManager.get(PointEvent).recycle(
			midpoint.x + (isPlayer ? -100 : 150) + globalOffset.x + cameraOffset.x,
			midpoint.y - 100 + globalOffset.y + cameraOffset.y);
		scripts.call("onGetCamPos", [event]);

		midpoint.put();
		return getX ? event.x : event.y;
	}

	@:noCompletion var __reverseTrailProcedure:Bool = false;

	// When using trails on characters you should do `trail.beforeCache = char.beforeTrailCache;` and `trail.afterCache = char.afterTrailCache;`
	public dynamic function beforeTrailCache()
		if (isFlippedOffsets()) {
			flipX = !flipX;
			scale.x *= -1;
			__reverseTrailProcedure = true;
		}
	
	public dynamic function afterTrailCache()
		if (__reverseTrailProcedure) {
			flipX = !flipX;
			scale.x *= -1;
			__reverseTrailProcedure = false;
		}

	public function applyXML(xml:Access) { // just for now till i remake the dumb editor
		gameOverCharacter = Character.FALLBACK_DEAD_CHARACTER;
		cameraOffset.set(0, 0);
		globalOffset.set(0, 0);
		playerOffsets = false;
		flipX = false;
		holdTime = 4;
		iconColor = null;

		animation.destroyAnimations();
		animDatas.clear();

		__baseFlipped = false;
		buildCharacter(xml);
	}

	public inline function buildCharacter(xml:Access) {
		for(node in xml.elements)
			switch(node.name) {
				case "use-extension" | "extension" | "ext":
					if (!XMLImportedScriptInfo.shouldLoadBefore(node)) continue;
					prepareInfos(node);
			}

		xml = scripts.event("onCharacterXMLParsed", EventManager.get(CharacterXMLEventMerged).recycle(this, xml)).xml;

		sprite = curCharacter;
		spriteAnimType = BEAT;
		this.xml = xml; // Modders wassup :D

		if (xml.x.exists("isPlayer")) playerOffsets = (xml.x.get("isPlayer") == "true");
		if (xml.x.exists("stageCamOffset")) canUseStageCamOffset = (xml.x.get("stageCamOffset") == "true");
		if (xml.x.exists("groupEnabled")) groupEnabled = (xml.x.get("groupEnabled") == "true");
		if (xml.x.exists("x")) globalOffset.x = Std.parseFloat(xml.x.get("x"));
		if (xml.x.exists("y")) globalOffset.y = Std.parseFloat(xml.x.get("y"));
		if (xml.x.exists("gameOverChar")) gameOverCharacter = xml.x.get("gameOverChar");
		if (xml.x.exists("camx")) cameraOffset.x = Std.parseFloat(xml.x.get("camx"));
		if (xml.x.exists("camy")) cameraOffset.y = Std.parseFloat(xml.x.get("camy"));
		if (xml.x.exists("holdTime")) holdTime = Std.parseFloat(xml.x.get("holdTime")).getDefaultFloat(4);
		if (xml.x.exists("flipX")) flipX = (xml.x.get("flipX") == "true");
		if (xml.x.exists("icon")) icon = xml.x.get("icon");
		if (xml.x.exists("color")) iconColor = FlxColor.fromString(xml.x.get("color"));
		if (xml.x.exists("scale")) {
			var scale:Float = Std.parseFloat(xml.x.get("scale")).getDefaultFloat(1);
			this.scale.set(scale, scale);
			updateHitbox();
		}
		if (xml.x.exists("antialiasing")) antialiasing = (xml.x.get("antialiasing") == "true");
		if (xml.x.exists("sprite")) sprite = xml.x.get("sprite");

		var hasInterval:Bool = xml.x.exists("interval");
		if (hasInterval) beatInterval = Std.parseInt(xml.x.get("interval"));

		loadSprite('characters/$sprite');
		for(node in xml.elements) {
			switch(node.name) {
				case "anim":
					XMLUtil.addXMLAnimation(this, node);
				case "use-extension" | "extension" | "ext":
					if (XMLImportedScriptInfo.shouldLoadBefore(node)) continue;
					prepareInfos(node);
				default:
					// nothing
			}

			scripts.event("onCharacterNodeParsed", EventManager.get(CharacterNodeEventMerged).recycle(this, node, node.name));
		}

		for (attribute in xml.x.attributes())
			if (!characterProperties.contains(attribute)) 
				extra[attribute] = xml.x.get(attribute);

		healthIcon = getIcon(); //get icon
		fixChar(__switchAnims, !hasInterval);
		recalculateDanceIdle();
		dance();

		for (info in xmlImportedScripts) if (info.shortLived) {
			var script = info.getScript();
			if (script == null) continue;

			scripts.remove(script);
			script.destroy();
		}
	}

	public static var characterProperties:Array<String> = [
		"x", "y", "sprite", "scale", "antialiasing",
		"flipX", "camx", "camy", "isPlayer", "icon",
		"color", "gameOverChar", "holdTime",
		"stageCamOffset"
	];
	public static var characterAnimProperties:Array<String> = [
		"name", "anim", "x", "y", "fps", "loop", "indices"
	];

	public inline function buildXML(?animsOrder:Array<String>):Xml {
		var xml:Xml = Xml.createElement("character");
		xml.attributeOrder = characterProperties.copy();

		if (globalOffset.x != 0) xml.set("x", Std.string(FlxMath.roundDecimal(globalOffset.x, 2)));
		if (globalOffset.y != 0) xml.set("y", Std.string(FlxMath.roundDecimal(globalOffset.y, 2)));

		if (cameraOffset.x != 0) xml.set("camx", Std.string(FlxMath.roundDecimal(cameraOffset.x, 2)));
		if (cameraOffset.y != 0) xml.set("camy", Std.string(FlxMath.roundDecimal(cameraOffset.y, 2)));

		if (holdTime != 4) xml.set("holdTime", Std.string(FlxMath.roundDecimal(holdTime, 4)));

		var realFlipped:Bool = isPlayer ? !__baseFlipped : __baseFlipped;
		if (realFlipped) xml.set("flipX", "true");
		if (icon != curCharacter) xml.set("icon", getIcon());

		if (gameOverCharacter != Character.FALLBACK_DEAD_CHARACTER) xml.set("gameOverChar", gameOverCharacter);
		if (iconColor != null) xml.set("color", iconColor.toWebString());

		if (sprite != curCharacter) xml.set("sprite", sprite);
		if (scale.x != 1) xml.set("scale", Std.string(FlxMath.roundDecimal(scale.x, 4)));
		if (!antialiasing) xml.set("antialiasing", antialiasing == true ? "true" : "false");

		if (isPlayer) xml.set("isPlayer", isPlayer == true ? "true" : "false");

		var anims:Array<AnimData> = [];
		if (animsOrder != null) {
			for (name in animsOrder)
				if (animDatas.exists(name)) anims.push(animDatas.get(name));
		} else
			anims = Lambda.array(animDatas);

		for (anim in anims) {
			var animXml:Xml = Xml.createElement('anim');
			animXml.attributeOrder = characterAnimProperties;

			animXml.set("name", anim.name);
			animXml.set("anim", anim.anim);
			if (anim.loop) animXml.set("loop", Std.string(anim.loop));
			if (FlxMath.roundDecimal(anim.fps, 2) != 24) animXml.set("fps", Std.string(FlxMath.roundDecimal(anim.fps, 2)));

			var offset:FlxPoint = getAnimOffset(anim.name);
			if (FlxMath.roundDecimal(offset.x, 2) != 0) animXml.set("x", Std.string(FlxMath.roundDecimal(offset.x, 2)));
			if (FlxMath.roundDecimal(offset.y, 2) != 0) animXml.set("y", Std.string(FlxMath.roundDecimal(offset.y, 2)));
			offset.putWeak();

			if (anim.indices.length > 0)
				animXml.set("indices", CoolUtil.formatNumberRange(anim.indices));

			xml.addChild(animXml);
		}

		for (name => val in extra)
			if (!xml.attributeOrder.contains(name)) {
				xml.attributeOrder.push(name);
				xml.set(name, Std.string(val));
			}

		this.xml = new Access(xml);

		return xml;
	}

	public inline function getIcon()
		return (icon != null) ? icon : curCharacter;

	public function getAnimOrder()
		return [for(a in xml.nodes.anim) if(a.has.name) a.att.name];

	@:noCompletion private function set_stunned(b:Bool) {
		__stunnedTime = 0;
		return stunned = b;
	}

	// ---- Backwards compat ----
	// Interval at which the character will dance (higher number = slower dance)
	@:noCompletion public var danceInterval(get, set):Int;
	@:noCompletion private function set_danceInterval(v:Int)
		return beatInterval = v;
	@:noCompletion private function get_danceInterval()
		return beatInterval;

	public static var FALLBACK_DEAD_CHARACTER:String = "bf-dead";

	private function set_script(script:Script):Script {
		if (scripts == null) (scripts = new ScriptPack("Character")).setParent(this);

		var lastIndex = scripts.scripts.indexOf(this.script);
		if(lastIndex >= 0) {
			if(script == null) // last != null && new == null
				scripts.scripts.splice(lastIndex, 1);
			else // last != null && new != null
				scripts.scripts[lastIndex] = script;
		} else if(script != null) // last == null
			scripts.insert(0, script);

		return this.script = script;
	}
	// ---- end of Backwards compat ----


	public static function getXMLFromCharName(character:OneOfTwo<String, Character>):Access {
		var char:Character = null;
		if (character is Character) {
			char = cast character;
			character = char.curCharacter;
		}

		var xml:Access = null;
		while (true) {
			var xmlPath:String = Paths.xml('characters/$character');
			if (!FunkinFileSystem.exists(xmlPath)) {
				character = DEFAULT_CHARACTER;
				if (char != null)
					char.curCharacter = character;
				continue;
			}

			var plainXML:String = FunkinFileSystem.getText(xmlPath);
			try {
				var charXML:Xml = Xml.parse(plainXML).firstElement();
				if (charXML == null) throw new Exception("Missing \"character\" node in XML.");
				xml = new Access(charXML);
			} catch (e) {
				CoolUtil.showPopUp('Error while loading character ${character}: ${e}', 'ERROR');

				character = DEFAULT_CHARACTER;
				if (char != null)
					char.curCharacter = character;
				continue;
			}
			break;
		}
		return xml;
	}

	public static function getIconFromCharName(?character:String, ?defaultIcon:String = null) {
		if(character == null) return Flags.DEFAULT_HEALTH_ICON;
		if(defaultIcon == null) defaultIcon = character;
		var icon:String = defaultIcon;

		var xml:Access = getXMLFromCharName(character);
		if (xml != null && xml.x.exists("icon")) icon = xml.x.get("icon");

		return icon;
	}
}

class CamPosData {
	/**
	 * The camera position.
	**/
	public var pos:FlxPoint;
	/**
	 * The amount of characters that was involved in the calculation.
	**/
	public var amount:Int;

	public function new(pos:FlxPoint, amount:Int) {
		this.pos = pos;
		this.amount = amount;
	}

	/**
	 * Puts the position back into the pool, making it reusable.
	**/
	public function put() {
		if(pos == null) return;
		pos.put();
		pos = null;
	}
}
