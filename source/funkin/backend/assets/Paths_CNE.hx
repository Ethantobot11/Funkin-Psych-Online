package funkin.backend.assets;

import haxe.io.Path;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
#if SCRIPTING_ALLOWED
import funkin.backend.scripting.HScript.Script;
#end

import flash.media.Sound;

using StringTools;

/**
	 * A basic class Seperates Codename Engine Paths.hx things from original Paths.hx.
	 * Taken from original Psych Extended.
*/
class Paths_CNE {
	public static var tempFramesCache:Map<String, FlxFramesCollection> = [];

	inline static public function getSparrowAtlasAlt(key:String)
		return FlxAtlasFrames.fromSparrow('$key.png', File.getContent(key + '.xml'));

	inline static public function getPackerAtlasAlt(key:String)
		return FlxAtlasFrames.fromSpriteSheetPacker('$key.png', '$key.txt');

	inline static public function getAsepriteAtlasAlt(key:String)
		return FlxAtlasFrames.fromAseprite('$key.png', '$key.json');

	static public function image(key:String, ?library:String, checkForAtlas:Bool = false, ?ext:String) {
		if (ext == null) ext = 'png';
		if (checkForAtlas) {
			var atlasPath = Paths.getPath('images/$key/spritemap.$ext', library, true);
			var multiplePath = Paths.getPath('images/$key/1.$ext', library, true);
			if (atlasPath != null && #if MODS_ALLOWED FunkinFileSystem.exists(atlasPath) #else OpenFlAssets.exists(atlasPath) #end)
				return atlasPath.substr(0, atlasPath.length - 14);
			if (multiplePath != null && #if MODS_ALLOWED FunkinFileSystem.exists(multiplePath) #else OpenFlAssets.exists(multiplePath) #end)
				return multiplePath.substr(0, multiplePath.length - 6);
		}
		return Paths.getPath('images/$key.$ext', library, true);
	}

	/**
	 * Gets frames at specified path.
	 * @param key Path to the frames
	 * @param library (Additional) library to load the frames from.
	 */
	public static function getFrames(key:String, assetsPath:Bool = false, ?library:String, ?ext:String = null) {
		/* I think this brokes the character when song restarted
		if (tempFramesCache.exists(key)) {
			var frames = tempFramesCache[key];
			if (frames.parent != null && frames.parent.bitmap != null && frames.parent.bitmap.readable)
				return frames;
			else
				tempFramesCache.remove(key);
		}
		*/
		tempFramesCache[key] = loadFrames(key);
		return tempFramesCache[key];
	}

	/**
	 * Loads frames from a specific image path. Supports Sparrow Atlases, Packer Atlases, and multiple spritesheets.
	 * @param path Path to the image
	 * @param Unique Whenever the image should be unique in the cache
	 * @param Key Key to the image in the cache
	 * @param SkipAtlasCheck Whenever the atlas check should be skipped.
	 * @param SkipMultiCheck Whenever the multi spritesheet check should be skipped.
	 * @param Ext Extension of the image.
	 * @return FlxFramesCollection Frames
	 */
	static function loadFrames(path:String, Unique:Bool = false, Key:String = null, SkipAtlasCheck:Bool = false, SkipMultiCheck:Bool = false):FlxFramesCollection {
		var noExt = Path.withoutExtension(path);
		var atlasImage:Dynamic = null;

		if (!SkipMultiCheck && #if MODS_ALLOWED FunkinFileSystem.exists('$noExt/1.png') #else Assets.exists('$noExt/1.png') #end) {
			// MULTIPLE SPRITESHEETS!!

			var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
			var frames = MultiFramesCollection.findFrame(graphic);
			if (frames != null)
				return frames;

			trace("no frames yet for multiple atlases!!");
			var cur = 1;
			var finalFrames = new MultiFramesCollection(graphic);
			trace("Final Frames: " + finalFrames);
			while(FunkinFileSystem.exists('$noExt/$cur.png')) {
				var spr = loadFrames('$noExt/$cur.png', false, null, false, true);
				trace("spr: " + spr);
				finalFrames.addFrames(spr);
				cur++;
			}
			return finalFrames;
		} else if (FunkinFileSystem.exists(Paths.getPath('images/$noExt.xml', null, true)))
			return Paths.getSparrowAtlas(path);
		else if (FunkinFileSystem.exists('$noExt.txt'))
			return Paths_CNE.getPackerAtlasAlt(noExt);
		else if (FunkinFileSystem.exists('$noExt.json')) {
			var aSprite = Paths_CNE.getAsepriteAtlasAlt(noExt);
			return aSprite;
		}

		//var graph:FlxGraphic = FlxG.bitmap.add(path, Unique, Key);
		var graph:FlxGraphic = Paths.image(path); //use returnGraphic bc I want to use String instead of path (also, path one is buggy)
		if (graph == null)
			return null;
		return graph.imageFrame;
	}
}