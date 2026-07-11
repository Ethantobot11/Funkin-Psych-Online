package mobile.openfl.controls;

class Hitbox extends InputHandler {
	public var controlID:String;
	public var showAlpha:Float = 1;

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, false);
		jsonName = data.name;
		controlID = cast data.id;
		var scaleArr:Array<Float> = data.scale != null ? cast data.scale : null;
		baseGraphic.bitmapData = createHintGraphic(scaleArr != null ? Std.int(scaleArr[0]) : 320, scaleArr != null ? Std.int(scaleArr[1]) : 720,
			data.color != null ? Std.parseInt(data.color) : 0xFFFFFFFF, false);
		baseGraphic.alpha = 0.00001;
		subGraphic.visible = false;
	}

	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):BitmapData {
		var shape = new Shape();
		shape.graphics.beginFill(Color);
		shape.graphics.lineStyle(3, Color, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.lineStyle(0, 0, 0);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		if (isLane)
			shape.graphics.beginFill(Color);
		else {
			var matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);
			shape.graphics.beginGradientFill(GradientType.RADIAL, [Color, Color], [0.6, 0], [0, 255], matrix, openfl.display.SpreadMethod.PAD,
				openfl.display.InterpolationMethod.LINEAR_RGB, 0.5);
		}
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		var bitmap = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	override public function updateInputs() {
		if (disabled)
			return;
		super.updateInputs();
		disableBright = true;
		if (checkOverlap(this)) {
			activeIDs.push(controlID);
			baseGraphic.alpha = showAlpha;
		} else
			baseGraphic.alpha = 0.00001;
	}
}
