package mobile.openfl.controls;

typedef Pointer = {id:Int, x:Float, y:Float, isDown:Bool, justPressed:Bool, justReleased:Bool, dead:Bool, pendingUp:Bool}

class ControlSignal {
	private var listeners:Array<(InputHandler, String) -> Void> = [];

	public function new() {}

	public function add(l:(InputHandler, String) -> Void) {
		if (!listeners.contains(l))
			listeners.push(l);
	}

	public function remove(l:(InputHandler, String) -> Void)
		listeners.remove(l);

	public function dispatch(c:InputHandler, id:String) {
		for (l in listeners)
			l(c, id);
	}
}

class InputHandler extends Sprite {
	public static var activePointers:Map<Int, Pointer> = new Map();
	public static var isMouseTracking:Bool = false;
	public static var inputsInitialized:Bool = false;

	public static function initInputs(stage:openfl.display.Stage) {
		if (inputsInitialized)
			return;
		inputsInitialized = true;
		openfl.ui.Multitouch.inputMode = openfl.ui.MultitouchInputMode.TOUCH_POINT;
		if (openfl.ui.Multitouch.supportsTouchEvents) {
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		}
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	}

	public static function updatePointersBuffer() {
		var deadKeys = [];
		for (id => p in activePointers) {
			if (p.dead)
				deadKeys.push(id);
			else if (p.pendingUp) {
				p.isDown = p.justPressed = p.pendingUp = false;
				p.justReleased = p.dead = true;
			} else
				p.justPressed = p.justReleased = false;
		}
		for (k in deadKeys)
			activePointers.remove(k);
	}

	public static function resetAllStaticInputs() {
		activePointers.clear();
		isMouseTracking = false;
	}

	private static function updatePointer(id:Int, px:Float, py:Float, isDown:Bool) {
		var p = activePointers.get(id);
		if (p == null) {
			p = {
				id: id,
				x: px,
				y: py,
				isDown: false,
				justPressed: false,
				justReleased: false,
				dead: false,
				pendingUp: false
			};
			activePointers.set(id, p);
		}
		p.x = px;
		p.y = py;
		if (isDown) {
			p.pendingUp = false;
			if (!p.isDown) {
				p.isDown = p.justPressed = true;
				p.justReleased = p.dead = false;
			}
		} else if (p.isDown)
			p.pendingUp = true;
	}

	private static function onMouseDown(e:MouseEvent) {
		isMouseTracking = true;
		updatePointer(-1, e.stageX, e.stageY, true);
	}

	private static function onMouseMove(e:MouseEvent) {
		if (isMouseTracking)
			updatePointer(-1, e.stageX, e.stageY, true);
	}

	private static function onMouseUp(e:MouseEvent) {
		isMouseTracking = false;
		updatePointer(-1, e.stageX, e.stageY, false);
	}

	private static function onTouchBegin(e:TouchEvent)
		updatePointer(e.touchPointID, e.stageX, e.stageY, true);

	private static function onTouchMove(e:TouchEvent)
		updatePointer(e.touchPointID, e.stageX, e.stageY, true);

	private static function onTouchEnd(e:TouchEvent)
		updatePointer(e.touchPointID, e.stageX, e.stageY, false);

	public var jsonName:String;
	public var activeIDs:Array<String> = [];
	public var lastActiveIDs:Array<String> = [];
	public var disabled:Bool = false;
	public var disableBright:Bool = false;
	public var showBounds:Bool = false;
	public var deadZones:Array<Sprite> = [];
	public var subOffsetX:Float = 0;
	public var subOffsetY:Float = 0;
	public var subScale:Float = 1.0;
	public var baseGraphic:Bitmap;
	public var subGraphic:Bitmap;
	public var hitboxes:Array<Sprite> = [];
	public var jsonX:Float = 0;
	public var jsonY:Float = 0;
	public var baseScale:Float = 1.0;

	private var baseColor:ColorTransform;
	private var subColor:ColorTransform;

	public var currentPointerID:Int = -1;
	public var onButtonDown:ControlSignal = new ControlSignal();
	public var onButtonUp:ControlSignal = new ControlSignal();

	public function new(jX:Float, jY:Float, showBounds:Bool) {
		super();
		this.jsonX = jX;
		this.jsonY = jY;
		this.showBounds = showBounds;
		baseGraphic = new Bitmap(null, PixelSnapping.NEVER);
		subGraphic = new Bitmap(null, PixelSnapping.NEVER);
		baseGraphic.smoothing = subGraphic.smoothing = true;
		addChild(baseGraphic);
		addChild(subGraphic);
	}

	public function parseSubGraphic(data:Dynamic):{subTex:String, subColor:String} {
		var res = {subTex: null, subColor: null};
		if (data.subgraphic != null) {
			if (Std.isOfType(data.subgraphic, String))
				res.subTex = cast data.subgraphic;
			else {
				res.subTex = data.subgraphic.texture;
				if (data.subgraphic.color != null)
					res.subColor = data.subgraphic.color;
				if (data.subgraphic.position != null) {
					subOffsetX = data.subgraphic.position[0];
					subOffsetY = data.subgraphic.position[1];
				}
				if (data.subgraphic.scale != null)
					subScale = data.subgraphic.scale;
			}
		}
		return res;
	}

	private function parseColorTransform(hexStr:String):ColorTransform {
		if (hexStr == null || hexStr == "")
			return new ColorTransform();
		var hex = hexStr;
		if (hex.startsWith("#"))
			hex = "0x" + hex.substring(1);
		else if (!hex.startsWith("0x"))
			hex = "0x" + hex;
		var colInt = Std.parseInt(hex);
		return colInt != null ? new ColorTransform(((colInt >> 16) & 0xFF) / 255.0, ((colInt >> 8) & 0xFF) / 255.0,
			(colInt & 0xFF) / 255.0) : new ColorTransform();
	}

	public function loadElementGraphics(gName:String, sName:String, sheet:String, paths:Array<String>, cHex:String, scale:Float, ?sHex:String) {
		baseScale = scale;
		if (cHex != null && cHex != "" && !cHex.startsWith("#"))
			cHex = "#" + cHex;
		if (sHex != null && sHex != "" && !sHex.startsWith("#"))
			sHex = "#" + sHex;
		loadBitmap(baseGraphic, gName, sheet, paths);
		if (sName != null && sName != "") {
			loadBitmap(subGraphic, sName, sheet, paths);
			centerSubGraphic();
		}
		baseColor = parseColorTransform(cHex);
		subColor = parseColorTransform(sHex);
		baseGraphic.transform.colorTransform = baseColor;
		if (sHex != null && sHex != "")
			subGraphic.transform.colorTransform = subColor;
		baseGraphic.scaleX = baseGraphic.scaleY = baseScale;
		subGraphic.scaleX = subGraphic.scaleY = baseScale * subScale;
	}

	private function loadBitmap(bmp:Bitmap, name:String, sheet:String, paths:Array<String>) {
		if (sheet != null && sheet != "") {
			var iFile = FileSystem.exists(paths[1] + sheet + ".png") ? paths[1] + sheet + ".png" : paths[0] + sheet + ".png";
			var jFile = FileSystem.exists(paths[1] + sheet + ".xml") ? paths[1] + sheet + ".xml" : paths[0] + sheet + ".xml";
			bmp.bitmapData = FileSystem.getBitmapData(iFile);
			bmp.smoothing = true;
			bmp.pixelSnapping = PixelSnapping.NEVER;
			var xmlText = File.getContent(jFile);
			if (xmlText != null)
				for (node in Xml.parse(xmlText).firstElement().elementsNamed("SubTexture"))
					if (node.get("name").indexOf(name) == 0) {
						bmp.scrollRect = new Rectangle(Std.parseFloat(node.get("x")), Std.parseFloat(node.get("y")), Std.parseFloat(node.get("width")),
							Std.parseFloat(node.get("height")));
						return;
					}
		} else if (name != null) {
			bmp.bitmapData = FileSystem.getBitmapData(FileSystem.exists(paths[1] + name + ".png") ? paths[1] + name + ".png" : paths[0] + name + ".png");
			bmp.smoothing = true;
			bmp.pixelSnapping = PixelSnapping.NEVER;
		}
	}

	public function centerSubGraphic() {
		if (subGraphic.bitmapData != null) {
			subGraphic.x = (((baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width) * baseScale)
				- ((subGraphic.scrollRect != null ? subGraphic.scrollRect.width : subGraphic.bitmapData.width) * baseScale * subScale)) / 2
				+ subOffsetX;
			subGraphic.y = (((baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height) * baseScale)
				- ((subGraphic.scrollRect != null ? subGraphic.scrollRect.height : subGraphic.bitmapData.height) * baseScale * subScale)) / 2
				+ subOffsetY;
		}
	}

	public function createBoundHitbox(relX:Float, relY:Float, w:Float, h:Float):Sprite {
		var box = new Sprite();
		box.graphics.beginFill(0xFFFFFF, 0.4);
		box.graphics.drawRect(0, 0, w, h);
		box.graphics.endFill();
		box.x = relX;
		box.y = relY;
		if (!showBounds)
			box.alpha = 0;
		addChild(box);
		hitboxes.push(box);
		return box;
	}

	public function updateBoundBrightness(box:Sprite, isPressed:Bool) {
		if (!showBounds)
			return;
		box.alpha = isPressed ? 0.8 : 0.4;
		box.transform.colorTransform = isPressed ? new ColorTransform(0, 1, 0) : new ColorTransform();
	}

	public function applyBrightness(isPressed:Bool) {
		if (disableBright)
			return;
		var m = isPressed ? 0.7 : 1.0;
		baseGraphic.transform.colorTransform = new ColorTransform(baseColor.redMultiplier * m, baseColor.greenMultiplier * m, baseColor.blueMultiplier * m);
		subGraphic.transform.colorTransform = new ColorTransform(subColor.redMultiplier * m, subColor.greenMultiplier * m, subColor.blueMultiplier * m);
	}

	public function checkOverlap(rect:Sprite):Bool {
		for (p in activePointers) {
			if (p.isDown) {
				for (dz in deadZones)
					if (dz != null && dz.hitTestPoint(p.x, p.y, false))
						return false;
				if (rect.hitTestPoint(p.x, p.y, true)) {
					currentPointerID = p.id;
					return true;
				}
			}
		}
		return false;
	}

	public function updateInputs() {
		lastActiveIDs = activeIDs.copy();
		activeIDs = [];
	}

	public function checkSignals() {
		for (id in activeIDs)
			if (!lastActiveIDs.contains(id))
				onButtonDown.dispatch(this, id);
		for (id in lastActiveIDs)
			if (!activeIDs.contains(id))
				onButtonUp.dispatch(this, id);
	}

	public function pressed(id:String):Bool
		return activeIDs.contains(id);

	public function justPressed(id:String):Bool
		return activeIDs.contains(id) && !lastActiveIDs.contains(id);

	public function justReleased(id:String):Bool
		return !activeIDs.contains(id) && lastActiveIDs.contains(id);

	public function released(id:String):Bool
		return !activeIDs.contains(id);

	public function resetInputs() {
		activeIDs = [];
		lastActiveIDs = [];
		currentPointerID = -1;
		centerSubGraphic();
		applyBrightness(false);
		for (b in hitboxes)
			updateBoundBrightness(b, false);
	}
}
