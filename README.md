# Simple script to search your Xcode project for unused images
I know there are tools for this out there, but some aren't reliable and some are $30, albeit with more options. But if you want something simple, just for searching, deleting and seeing at a glance what @2x/@1x assets are missing, this should do the trick.

It takes an argument, so you should run it like `ruby unused.rb /path_to_your_project_folder`. If you don't provide an argument, you will be prompted for one after launching.

It searches `m`, `mm`, `cpp`, `c`, `h` and `html` files by default. Easily changeable.

Default searched files are `jpg`, `png`, `jpeg`, `tiff`, `tif`, `gif`, `bmp`, `BMPf`, `ico`, `cur`, `xbm`, since these are the ones supported by the iOS SDK. Easily changeable.

It provides easily changeable exclusions, defaults being `vendor`, `default`, `icon`:

* Excluded folders will not be searched for images to be removed, but files inside them **will** be searched for occurrences of images. Best example: exclude external classes that still need to be searched for, since they might be customized with your own graphics and we don't want to delete needed files.
* Excluded images will not be searched for.  

You will be displayed a list of unused file names, then a list of to-be deleted files, with full paths. You can choose to stop here, delete them all, or delete them one by one.

Since it shows a list of file names, you can also see at glance what images are missing @2x or @1x sizes.

I tested it and re-tested it and there's a one-by-one mode, please don't go deleting everything if you're not 100% sure of what you're doing.

That's about it. Please feel free to improve or contact me for any questions. I'd be more than happy to hear from you [@rolandleth](https://twitter.com/rolandleth).
  
## License
Licensed under MIT.