package mobile.openfl.controls;

class MobileControls extends Sprite {
	public var designWidth:Float = 1280;
	public var designHeight:Float = 720;
	public var controls:Array<InputHandler> = [];
	public var buttons:Array<Button> = [];
	public var dpads:Array<DPad> = [];
	public var joysticks:Array<Joystick> = [];
	public var hitboxes:Array<Hitbox> = [];

	public function new(designW:Float = 1280, designH:Float = 720) {
		super();
		this.designWidth = designW;
		this.designHeight = designH;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(e:Event) {
		InputHandler.initInputs(stage);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(Event.DEACTIVATE, onFocusLost);
		stage.addEventListener(Event.MOUSE_LEAVE, onFocusLost);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		onResize(null);
	}

	private function onFocusLost(e:Event)
		resetAllInputs();

	public function getHitboxFromName(n:String) {
		for (b in hitboxes)
			if (b != null && b.jsonName == n)
				return b;
		return null;
	}

	public function getDPadFromName(n:String) {
		for (b in dpads)
			if (b != null && b.jsonName == n)
				return b;
		return null;
	}

	public function getJoyStickFromName(n:String) {
		for (b in joysticks)
			if (b != null && b.jsonName == n)
				return b;
		return null;
	}

	public function getButtonFromName(n:String) {
		for (b in buttons)
			if (b != null && b.jsonName == n)
				return b;
		return null;
	}

	private function loadJson(n:String, mod:String, reg:String):ControlsJsonDef {
		var p = FileSystem.exists(mod + n + ".json") ? mod + n + ".json" : reg + n + ".json";
		var r = File.getContent(p);
		return r != null ? Json.parse(r) : null;
	}

	public function addButton(name:String) {
		if (buttons.length > 0)
			removeButton();
		var p = loadJson(name, Config.MODDED_BUTTON_JSON, Config.BUTTON_JSON);
		if (p != null && p.buttons != null)
			for (d in p.buttons) {
				var b = new Button(d);
				addControl(b);
				buttons.push(b);
			}
		onResize(null);
	}

	public function addDPad(name:String) {
		if (dpads.length > 0)
			removeDPad();
		var p = loadJson(name, Config.MODDED_DPAD_JSON, Config.DPAD_JSON);
		if (p != null && p.dpads != null)
			for (d in p.dpads) {
				var b = new DPad(d);
				addControl(b);
				dpads.push(b);
			}
		onResize(null);
	}

	public function addJoyStick(name:String) {
		if (joysticks.length > 0)
			removeJoyStick();
		var p = loadJson(name, Config.MODDED_JOYSTICK_JSON, Config.JOYSTICK_JSON);
		if (p != null && p.joysticks != null)
			for (d in p.joysticks) {
				var b = new Joystick(d);
				addControl(b);
				joysticks.push(b);
			}
		onResize(null);
	}

	public function addHitbox(name:String) {
		if (hitboxes.length > 0)
			removeHitbox();
		var p = loadJson(name, Config.MODDED_HITBOX_JSON, Config.HITBOX_JSON);
		if (p != null && p.hitboxes != null)
			for (d in p.hitboxes) {
				var b = new Hitbox(d);
				addControl(b);
				hitboxes.push(b);
			}
		onResize(null);
	}

	private function addControl(c:InputHandler) {
		controls.push(c);
		addChild(c);
	}

	public function removeButton() {
		for (b in buttons) {
			controls.remove(b);
			if (contains(b))
				removeChild(b);
		}
		buttons = [];
	}

	public function removeDPad() {
		for (b in dpads) {
			controls.remove(b);
			if (contains(b))
				removeChild(b);
		}
		dpads = [];
	}

	public function removeJoyStick() {
		for (b in joysticks) {
			controls.remove(b);
			if (contains(b))
				removeChild(b);
		}
		joysticks = [];
	}

	public function removeHitbox() {
		for (b in hitboxes) {
			controls.remove(b);
			if (contains(b))
				removeChild(b);
		}
		hitboxes = [];
	}

	public function clearControls() {
		removeButton();
		removeDPad();
		removeJoyStick();
		removeHitbox();
		resetAllInputs();
	}

	public function destroy() {
		clearControls();
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		if (stage != null) {
			stage.removeEventListener(Event.RESIZE, onResize);
			stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
			stage.removeEventListener(Event.MOUSE_LEAVE, onFocusLost);
		}
	}

	private function onResize(e:Event) {
		if (stage == null)
			return;
		var r = Math.min(stage.stageWidth / designWidth, stage.stageHeight / designHeight);
		var oX = (stage.stageWidth - (designWidth * r)) / 2;
		var oY = (stage.stageHeight - (designHeight * r)) / 2;
		for (c in controls) {
			c.scaleX = c.scaleY = r;
			c.x = oX + (c.jsonX * r);
			c.y = oY + (c.jsonY * r);
		}
	}

	private function onEnterFrame(e:Event) {
		for (c in controls) {
			c.updateInputs();
			c.checkSignals();
		}
		InputHandler.updatePointersBuffer();
	}

	public function checkState(id:String, state:String = "pressed"):Bool {
		var isAny = (id == "any" || id == null);
		for (c in controls) {
			if (c == null || c.disabled)
				continue;
			if (isAny) {
				switch (state.toLowerCase()) {
					case "pressed":
						if (c.activeIDs.length > 0)
							return true;
					case "justpressed":
						for (a in c.activeIDs)
							if (!c.lastActiveIDs.contains(a))
								return true;
					case "justreleased":
						for (l in c.lastActiveIDs)
							if (!c.activeIDs.contains(l))
								return true;
					case "released":
						if (c.activeIDs.length == 0)
							return true;
				}
			} else {
				switch (state.toLowerCase()) {
					case "pressed":
						if (c.pressed(id))
							return true;
					case "justpressed":
						if (c.justPressed(id))
							return true;
					case "justreleased":
						if (c.justReleased(id))
							return true;
					case "released":
						if (c.released(id))
							return true;
				}
			}
		}
		return false;
	}

	public function resetAllInputs() {
		for (c in controls)
			c.resetInputs();
		InputHandler.resetAllStaticInputs();
	}
}
