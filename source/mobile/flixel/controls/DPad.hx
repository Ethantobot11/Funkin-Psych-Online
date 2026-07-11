package mobile.flixel.controls;

#if flixel
class DPad extends InputHandler {
	public var controlIDs:Array<String> = [];

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, data.showbounds == true);
		jsonName = data.name;
		controlIDs = cast data.id;
		var subData = parseSubGraphic(data);
		loadElementGraphics(data.texture, subData.subTex, data.spritesheet, [Config.DPAD_PATH, Config.MODDED_DPAD_PATH], data.color,
			data.scale != null ? cast data.scale : 1.0, subData.subColor);

		if (data.offset != null && data.hitbox != null) {
			for (i in 0...controlIDs.length) {
				createBoundHitbox((baseGraphic.width / 2) + data.offset[i][0] - (data.hitbox[i][0] / 2),
					(baseGraphic.height / 2) + data.offset[i][1] - (data.hitbox[i][1] / 2), data.hitbox[i][0], data.hitbox[i][1]);
			}
		}
	}

	override public function updateInputs() {
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
#end
