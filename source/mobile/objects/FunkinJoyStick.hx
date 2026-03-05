package mobile.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;
import openfl.display.BitmapData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

import mobile.JoyStick;

using StringTools;

class FunkinJoyStick extends JoyStick {
	//FNF Asset Stuff
	override private function loadObjectGraphic(object:FlxSprite, graphic:String, img:String) {
		var fixedModPath:String = graphic;
		if (!graphic.startsWith(MobileConfig.mobileFolderPath))
			graphic = MobileConfig.mobileFolderPath + graphic;

		#if mobile_controls_file_support
		var xmlPath:String = '$graphic.xml';
		var modXml:String = Paths.modFolders('mobile/$fixedModPath.xml');
		var modGraphicGPU:String = Paths.modFolders('mobile/$fixedModPath.' + Paths.GPU_IMAGE_EXT);
		var modGraphicPng:String = Paths.modFolders('mobile/$fixedModPath.png');
		var graphicGPU:String = '$graphic.' + Paths.GPU_IMAGE_EXT;
		var graphicPng:String = '$graphic.png';

		inline function loadFrom(img:String, xml:String) {
			object.loadGraphic(
				FlxGraphic.fromFrame(
					FlxAtlasFrames.fromSparrow(
						BitmapData.fromFile(img),
						File.getContent(xml)
					).getByName(img)
				)
			);
		}

		if (FileSystem.exists(modXml) && FileSystem.exists(modGraphicGPU))
			loadFrom(modGraphicGPU, modXml);
		else if (FileSystem.exists(modXml) && FileSystem.exists(modGraphicPng))
			loadFrom(modGraphicPng, modXml);
		else if (FileSystem.exists(xmlPath) && FileSystem.exists(graphicGPU))
			loadFrom(graphicGPU, xmlPath);
		else if (FileSystem.exists(xmlPath) && FileSystem.exists(graphicPng))
			loadFrom(graphicPng, xmlPath);
		else #end {
			var fallbackExt:String = null;
			for (ext in [
				Paths.GPU_IMAGE_EXT,
				Paths.IMAGE_EXT
			]) if (Assets.exists('$graphic.$ext')) {
				fallbackExt = ext;
				break;
			}

			if (fallbackExt != null)
				object.loadGraphic(
					FlxGraphic.fromFrame(
						FlxAtlasFrames.fromSparrow(
							Assets.getBitmapData('$graphic.$fallbackExt'),
							Assets.getText(xmlPath)
						).getByName(img)
					)
				);
		}
	}

	public function new(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void)
	{
		super(x, y, graphic, onMove);
	}
}