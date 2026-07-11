package mobile.openfl.controls;

class DPad extends InputHandler {
	public var controlIDs:Array<String> = [];

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, data.showbounds == true);
		jsonName = data.name;
		controlIDs = cast data.id;
		var subData = parseSubGraphic(data);
		loadElementGraphics(data.texture, subData.subTex, data.spritesheet, [Config.DPAD_PATH, Config.MODDED_DPAD_PATH], data.color,
			data.scale != null ? cast data.scale : 1.0, subData.subColor);

		var bW = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width;
		var bH = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height;
		if (data.offset != null && data.hitbox != null) {
			for (i in 0...controlIDs.length)
				createBoundHitbox(((bW * baseScale) / 2)
					+ (data.offset[i][0] * baseScale)
					- ((data.hitbox[i][0] * baseScale) / 2),
					((bH * baseScale) / 2)
					+ (data.offset[i][1] * baseScale)
					- ((data.hitbox[i][1] * baseScale) / 2), data.hitbox[i][0] * baseScale,
					data.hitbox[i][1] * baseScale);
		}
	}

	override public function updateInputs() {
		if (disabled)
			return;
		super.updateInputs();
		var anyPressed = false;
		for (i in 0...hitboxes.length) {
			var isPressed = checkOverlap(hitboxes[i]);
			if (isPressed) {
				activeIDs.push(controlIDs[i]);
				anyPressed = true;
			}
			updateBoundBrightness(hitboxes[i], isPressed);
		}
		applyBrightness(anyPressed);
	}
}
