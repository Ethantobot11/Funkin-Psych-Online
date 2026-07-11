package online.objects;

import flixel.graphics.FlxGraphic;
import flixel.FlxBasic;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class LoadingSprite extends FlxTypedGroup<FlxBasic> {
var loadBar:FlxSprite;
var tasksLength:Float = 0;

public function new(?tasksLength:Float, ?camera:FlxCamera) {
		super();
		
		var funkay = new FlxSprite();
		var _funkayGraphic = Paths.image('funkay', null, false);
		
		if (_funkayGraphic != null) {
			var astcPath = Paths.getPath('images/funkay.astc', BINARY);
			var isAstc = sys.FileSystem.exists(astcPath);

			if (isAstc) {
				funkay.loadGraphic(_funkayGraphic);
				funkay.setGraphicSize(0, FlxG.height);
				funkay.updateHitbox();
				funkay.screenCenter(X);
			} else {
				var funkayGraphic = _funkayGraphic.bitmap;
				if (funkayGraphic != null && funkayGraphic.image != null) {
					funkay.makeGraphic(FlxG.width, FlxG.height, funkayGraphic.getPixel32(0, 0), true, "_funkay");
					funkayGraphic.image.resize(Std.int(funkayGraphic.image.width * (FlxG.height / funkayGraphic.image.height)), FlxG.height);
					funkay.graphic.bitmap.copyPixels(funkayGraphic, new Rectangle(0, 0, funkay.graphic.bitmap.width, funkay.graphic.bitmap.height),
						new Point(FlxG.width / 2 - funkayGraphic.image.width / 2, 0));
				} else {
					funkay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				}
			}
		} else {
			funkay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
		
		funkay.antialiasing = ClientPrefs.data.antialiasing;
		add(funkay);

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xFFff16d2);
		loadBar.scale.x = 0;
		loadBar.visible = false;
		loadBar.screenCenter(X);
		add(loadBar);

		if (camera != null)
			cameras = [camera];

		this.tasksLength = tasksLength;
	}

    public function addProgress(remaining:Float) {
		loadBar.scale.x += 0.5 * (FlxMath.remapToRange(remaining / tasksLength, 1, 0, 0, 1) - loadBar.scale.x);
        loadBar.visible = true;
    }
}