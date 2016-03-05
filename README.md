# PaperGram

Automatically set your iOS background to pictures straight from a user's Instagram feed.

## Contributors

supermamon <monvelasquez@gmail.com>

## Depiction

Automatically set your iOS wallpaper to pictures from an Instagram feed.

Simply select the user to use for both your lockscreen and your homescreen, and try locking and unlocking your device.

* Enable or disable for the lockscreen and homescreen separately
* Set different feeds for both the lockscreen and homescreen
* Add multiple feeds by separating them with a comma
* Activator support for changing wallpapers
* Manually cycle wallpapers from PaperGram settings
* Embed username and caption in wallpapers
* Disable wallpaper cycling on WiFi

Only supports public profiles. This should allow you to use most profiles that would include any pictures worthy of being your wallpaper.

Not affiliated with Instagram or Facebook. Compatible with iOS 9. Instagram not required.

## Changelog

### Release 1.0

* Inital release
* Choose separate feeds for both your lockscreen and homescreen

### Release 1.1.0

* Add Activator support - @supermamon
* Add a toggelable progress HUD when triggered by activator - @supermamon
* Add setting to embed username & caption in the wallpaper - @supermamon
* Add buttons to manually cycle wallpapers in the settings
* Add donate button to settings
* Reorganize settings
* Add support for multiple usernames by separating with commas
* Set two different images when using same feed & random pictures
* Add WiFi only toggle - applies to all activation methods, except manual cycling


## Building
* Setup [theos](http://iphonedevwiki.net/index.php/Theos/Setup) on your system.
* Run ```make clean package```
* The package will be available in the ```debs``` directory.

## License

GNU General Public License v3.0