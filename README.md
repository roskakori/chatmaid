Chatmaid
========

Chatmaid is an addon for the MMOFPS Firefall <http://www.firefallthegame.com/>
to improve the quality of conversation in the zone chat.

Chatmaid wipes the chat clean from "thank you" messages that should have gone
to `local` or `/whisper`, brings out the trash from non English messages that
should have gone to `/army` or `/squad`, dusts of redundant exclamation marks
from raging players, polishes white space and tidies up a few other things in
order to make you feel more comfortable in `/zone`.

Nevertheless it leaves your room untouched so you can still party all you want
with your mates in `/army` and `/squad`.


Features
--------

* Hides all Russian messages and also some German and French ones (provided
  they use non ASCII characters).
* Hides thanks (typically for revives) that would better be sent using
  `/local` or `/whisper`.
* Hides single character messages like `/` (typically slips on the keyboard);
  common one letter abbreviations such as `y` for yes and `k` for ok are
  preserved.
* Leaves `/squad` and `/army` chat untouched so you can still thank around and
  talk Russian there.


Installation
------------

Replace
`C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\R5Chat.lua`
with the one included in the ZIP archive.


Configuration
-------------

There is no GUI for configuration. Open the source code in a text editor (for
example Notepad) and take a look at the comments and variables in the
beginning.


Limitations
-----------

* Currently experimental (my first Firefall addon and Lua program).
* Dispite chatmaid's best effort some noise remains in the zone chat.
* As every Lua addon, chatmaid does not support the  Melder addon manager and
  has to be reinstalled after a Firefall patch.


  License
-------

Chatmaid is distributed under the MIT License. The source code is available
from <https://bitbucket.org/roskakori/chatmaid>.

Copyright (c) 2013 Thomas Aglassinger

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
