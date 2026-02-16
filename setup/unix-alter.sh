#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install hscript 2.6.0 --quiet
haxelib git lime https://github.com/ArkoseLabsOfficial/lime main --quiet
haxelib install openfl 9.3.3 --quiet
haxelib git flixel https://github.com/ArkoseLabsOfficial/flixel-peo peo-mobile --quiet
haxelib install flixel-addons 3.3.2 --quiet
haxelib install flixel-tools 1.5.1 --quiet
haxelib install flixel-ui 2.6.4 --quiet
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp 6546fa5c3ad1bac065f144745122ab5a6d4195ff --quiet
haxelib install tjson 1.4.0 --quiet
haxelib git SScript https://github.com/Snirozu/SScript-7.7.0 main --quiet
haxelib install hxdiscord_rpc 1.3.0 --quiet
haxelib git linc_luajit https://github.com/th2l-devs/linc_luajit main --quiet
haxelib install colyseus 0.15.2 --quiet
haxelib install colyseus-websocket 1.0.12 --quiet
haxelib install HtmlParser 3.4.0 --quiet
haxelib install UnRAR 1.0.0 --quiet
haxelib install away3d 5.0.9 --quiet
haxelib git away3d https://github.com/Snirozu/away3d master --quiet
haxelib install json2object 3.11.0 --quiet
haxelib install hxjsonast 1.1.0 --quiet
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate v4.0.0 --quiet
haxelib install lumod 2.1.0 --quiet
haxelib install actuate 1.9.0 --quiet
haxelib install compiletime 2.8.0 --quiet
haxelib git grig.audio https://github.com/Snirozu/grig.audio 162f924bdde427fc84af5b51961d2faef51f6955 --quiet
haxelib install tink_core 2.1.1 --quiet
haxelib install hxvlc 2.0.1 --quiet
haxelib git yagp https://github.com/Snirozu/yagp master --quiet
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 1966f8fbbbc509ed90d4b520f3c49c084fc92fd6 --quiet
haxelib git mobile-controls https://github.com/Prohack101010/mobile-controls-dev main --quiet
haxelib git hscript-improved https://github.com/PsychExtendedThings/hscript-improved-Psych --quiet
haxelib git extension-androidtools https://github.com/MAJigsaw77/extension-androidtools main --quiet
haxelib install tink_await 0.6.0 --quiet
echo Finished!