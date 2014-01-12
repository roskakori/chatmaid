Chatmaid
========

Chatmaid is an addon for the MMOFPS Firefall (available from
<http://www.firefallthegame.com/>) to hide or clean up unwanted messages in
public char channels.

Chatmaid wipes the chat clean from "thank you" messages that should have gone
to `/local` or `/whisper`, brings out the garbage from non English messages
that should have gone to `/army` or `/squad`, dusts of redundant exclamation
marks from overreacting players, polishes white space and tidies up a few
other things in order to make your stay in `/zone` a little more cozy.

Nevertheless it leaves your room untouched so you can still party all you want
with your mates in `/army` and `/squad`.


Features
--------

* Hides thanks (typically for revives) that would better be sent using
  `/local` or `/whisper`.
* Hides all Russian messages and also some German and French ones (provided
  they use non ASCII characters).
* Hides single character messages like `/` (typically caused by slips on the
  keyboard); common one letter abbreviations such as `y` for yes and `k` for
  ok are preserved.
* Leaves `/squad` and `/army` chat untouched so you can still thank around and
  talk Russian there.


Installation
------------

Chatmaid can be installed using
[Melder](http://forums.firefallthegame.com/community/threads/addon-manager-melder.52327/)
by visiting <http://astrekassociation.com/melder.php?id=1255421>.

For manual installation, visit the
[Chatmaid thread](http://forums.firefallthegame.com/community/threads/2868821/)
in the offical Firefall forums.

The modified files are stored in 
`C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat`.


Configuration
-------------

Chatmaid can be configured using the options dialog in game and navigating to
Interface > Chat. 

![Screenshot: Chatmaid Options](chatmaid_options.png)

"Hide French" and "Hide German" hides messages that contain non ASCII
characters common to the French or German language. For instance, the German
message "So ein Bl�dsinn!" is hidden because it contains the German Umlaut
"�". However, the also German message "So ein Unsinn!" is preserved because it
uses only ASCII.

"Hide Russian" hides messages that contain Cyrillic letters.

"Explain actions" prevents Chatmaid from actually hiding or cleaning up
messages. Instead, Chatmaid would appends a remark to messages it would have
acted upon. For example "ty" becomes "ty [hide thanks]".


Limitations
-----------
* Currently experimental (my first Firefall addon and Lua program).
* Dispite chatmaid's best effort some noise remains in the zone chat.


Version history
---------------

Version 0.2, 2014-01-01
* Added configuration to Options > Interface > Chat.
* Added support for updating in Melder. Users of version 0.1 have to upgrade
  to 0.2 manually though.
* Added "tnx" as synonym for "thanks".
* Added "?" as preserved single letter message to express confusion.

Version 0.1, 2013-12-01
* Initial public release.


License
-------

Chatmaid is distributed under the MIT License.

Copyright (c) 2013-14 Thomas Aglassinger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


Development
-----------

To build the distribution archive from scratch, you need to install:

1. Firefall.
2. Lua 5.1 (or later), available from <http://www.lua.org/download.html>.
3. Python 3.3 (or later), available from <http://www.python.org/getit/>.

You can check out the source code from
<https://bitbucket.org/roskakori/chatmaid>.

While you can build everything from integrated developer environments, the
easiest way is to use `cmd.exe` and `cd` into the folder where you just
checked out your work copy.

To execute the test cases, run:
```
lua test_chatmaid.lua
```

To build the `Chatmaid_v*.zip` and copy it to Melder's addon folder, run:
```
python build_chatmaid.py
```

If you improved the code, feel free to fork chatmaid on bitbuckt and submit a
pull request.