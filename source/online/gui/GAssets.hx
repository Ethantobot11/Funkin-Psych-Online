package online.gui;

class GAssets {
	public static function image(path:String) {
		var img = Paths.image(path, null, false);
		if (img == null)
			return null;

		var ext = Paths.IMAGE_EXT;
		/*if (img.path != null && img.path.endsWith(Paths.GPU_IMAGE_EXT))
			ext = Paths.GPU_IMAGE_EXT;*/

		Paths.excludeAsset('assets/images/' + path + "." + ext);
		return img.bitmap.clone();
	}
}