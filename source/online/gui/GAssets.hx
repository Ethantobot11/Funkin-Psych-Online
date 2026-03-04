class GAssets {
	public static function image(path:String) {
		var img = Paths.image(path, null, false);
		if (img == null)
			return null;

		var ext = IMAGE_EXT;
		if (img.path != null && img.path.endsWith(GPU_IMAGE_EXT))
			ext = GPU_IMAGE_EXT;

		Paths.excludeAsset('assets/images/' + path + "." + ext);
		return img.bitmap.clone();
	}
}