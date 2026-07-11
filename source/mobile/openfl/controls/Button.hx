package mobile.openfl.controls;

class Button extends InputHandler {
	public var controlID:String;

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, false);
		jsonName = data.name;
		controlID = cast data.id;
		var subData = parseSubGraphic(data);
		loadElementGraphics(data.texture, subData.subTex, data.spritesheet, [Config.BUTTON_PATH, Config.MODDED_BUTTON_PATH], data.color,
			data.scale != null ? cast data.scale : 1.0, subData.subColor);
	}

	override public function updateInputs() {
		if (disabled)
			return;
		super.updateInputs();
		if (checkOverlap(this))
			activeIDs.push(controlID);
		applyBrightness(activeIDs.length > 0);
	}
}
