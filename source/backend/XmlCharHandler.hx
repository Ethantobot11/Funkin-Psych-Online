package backend;

// System Imports
import haxe.xml.Access;
import haxe.Exception;
import openfl.utils.Assets;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.util.FlxColor;
import flixel.math.FlxPoint;

using StringTools;

/**
 * XmlCharHandler
 * Extends FunkinSprite (Codename Backend) to add Character-specific logic 
 * (XML Parsing, Scripts, Global Offsets) for Psych Engine.
 */
class XmlCharHandler extends FunkinSprite {
	
	// --- CNE SPECIFIC VARIABLES ---
	public var scripts:ScriptPack;
	public var script(default, set):Script;
	public var xml:Access;
	public var isCNELoaded:Bool = false;

	// Character Data
	public var curCharacter:String = 'bf';
	public var isPlayer:Bool = false;
	
	// CNE Offset System
	public var playerOffsets:Bool = false; // If true, offsets are designed for BF position
	public var globalOffset:FlxPoint = new FlxPoint(0, 0);

	// Script Helper for Psych Compatibility
	public var isSkin:Bool = false;
	public var Custom(get, set):Bool;
	function set_Custom(value:Bool):Bool { return this.isSkin = value; }
	function get_Custom():Bool { return this.isSkin; }
	public var custom(get, never):Bool;
	function get_custom():Bool { return this.isSkin; }

	public function new(x:Float, y:Float) {
		super(x, y);
		scripts = new ScriptPack([]);
	}

	// --- CNE LOADING LOGIC ---

	/**
	 * Tries to load the character using the CNE XML system.
	 * Returns true if successful.
	 */
	public function attemptCNELoad(character:String):Bool {
		xml = getXMLFromCharName(character);
		if (xml == null) return false;

		this.curCharacter = character;

		// 1. Load Script
		var scriptPathName = 'characters/$character';
		#if MODS_ALLOWED
		var scriptPath = Paths.modFolders(scriptPathName + '.hx');
		if (!FunkinFileSystem.exists(scriptPath)) scriptPath = Paths.getPreloadPath(scriptPathName + '.hx');
		#else
		var scriptPath = Paths.getPreloadPath(scriptPathName + '.hx');
		#end

		if (FunkinFileSystem.exists(scriptPath)) {
			script = Script.create(scriptPath);
		}
		
		if (script == null) script = new DummyScript(character);
		
		scripts.add(script);
		script.load();
		scripts.call("create");

		// 2. Build from XML (Using FunkinSprite methods)
		buildFromXML(xml);
		
		isCNELoaded = true;
		scripts.call("postCreate");
		return true;
	}

	function buildFromXML(xml:Access) {
		// Basic Properties
		if (xml.has.x) x += Std.parseFloat(xml.att.x);
		if (xml.has.y) y += Std.parseFloat(xml.att.y);
		
		// Sprite Loading
		if (xml.has.sprite) {
			loadSprite(xml.att.sprite);
		}

		if (xml.has.flipX) flipX = (xml.att.flipX == "true");
		if (xml.has.scale) {
			var s = Std.parseFloat(xml.att.scale);
			scale.set(s, s);
		}
		
		if (xml.has.playerOffsets) playerOffsets = (xml.att.playerOffsets == "true");

		// Animations
		for (anim in xml.nodes.anim) {
			var name = anim.att.name; // Logical name (e.g. idle)
			var animName = anim.att.anim; // XML/Atlas name (e.g. BF_idle)
			var fps = anim.has.fps ? Std.parseInt(anim.att.fps) : 24;
			
			// XMLAnimType Detection
			var animType:XMLAnimType = NONE;
			if (anim.has.loop) {
				animType = (anim.att.loop == "true") ? LOOP : NONE;
			}
			if (anim.has.type) {
				animType = XMLAnimType.fromString(anim.att.type);
			}

			var forced = anim.has.forced ? (anim.att.forced == "true") : false;
			
			// Indices
			var indices:Array<Int> = null;
			if (anim.has.indices) {
				indices = [];
				var strIndices = anim.att.indices.split(",");
				for (i in strIndices) indices.push(Std.parseInt(i));
			}

			var ox = anim.has.x ? Std.parseFloat(anim.att.x) : 0.0;
			var oy = anim.has.y ? Std.parseFloat(anim.att.y) : 0.0;

			// Add to FunkinSprite
			addAnim(name, animName, fps, false, forced, indices, ox, oy, animType);
		}
	}

	public static function getXMLFromCharName(character:String):Access {
		var xml:Access = null;
		var characterPath:String = 'characters/' + character + '.xml';
		
		#if MODS_ALLOWED
		var xmlPath:String = Paths.modFolders(characterPath);
		if (!FunkinFileSystem.exists(xmlPath)) xmlPath = Paths.getPreloadPath(characterPath);
		if (FunkinFileSystem.exists(xmlPath))
		#else
		var xmlPath:String = Paths.getPreloadPath(characterPath);
		if (Assets.exists(xmlPath))
		#end
		{
			try {
				var plainXML:String = FunkinFileSystem.getText(xmlPath);
				xml = new Access(Xml.parse(plainXML).firstElement());
			} catch (e) {
				trace('Error loading XML for $character: $e');
				return null;
			}
		}
		return xml;
	}

	// --- SCRIPT HOOKS & OVERRIDES ---
	override function update(elapsed:Float) {
		if (scripts != null) scripts.call("update", [elapsed]);
		super.update(elapsed);
		if (scripts != null) scripts.call("postUpdate", [elapsed]);
	}

	override function destroy() {
		if (scripts != null) {
			scripts.call('destroy');
			scripts.destroy();
		}
		super.destroy();
	}

	override public function beatHit(curBeat:Int) {
		if (scripts != null) scripts.call("beatHit", [curBeat]);
		super.beatHit(curBeat); 
	}

	override public function stepHit(curStep:Int) {
		if (scripts != null) scripts.call("stepHit", [curStep]);
		super.stepHit(curStep);
	}

	// PlayAnim Override: Script Events & Global Offsets
	override public function playAnim(AnimName:String, ?Force:Null<Bool>, Context:PlayAnimContext = NONE, Reversed:Bool = false, Frame:Int = 0):Void {
		// Script Hook
		if (scripts != null) {
			var f:Bool = (Force == null) ? false : Force;
			var event = new PlayAnimEvent(AnimName, f, Reversed, Frame);
			event.context = Context;
			scripts.call("onPlayAnim", [event]);
			
			if (event.cancelled) return;
			
			AnimName = event.animName;
			Force = event.force;
			Reversed = event.reverse;
			Frame = event.startingFrame;
			Context = event.context;
		}

		super.playAnim(AnimName, Force, Context, Reversed, Frame);

		frameOffset.x += globalOffset.x;
		frameOffset.y += globalOffset.y;
	}
}
