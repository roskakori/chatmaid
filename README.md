Chatmaid
========

Chatmaid is a addon for the MMOFPS Firefall to improve the quality of conversation in
the zone chat. The features of the default configuration are:

* Hides all Russian messages (Yeah!)
* Hides thanks (typically for revives) that would be better sent using `/local` or
  `/whisper`.
* Hides single character messages like `/` (typically slips on the keyboard); common one
  letter abbreviations such as `y` for yes and `k` for ok are preserved.
* Leaves `/squad` and `/army` chat untouched so you can still thank around and talk
  Russian there.

Installation
------------

Replace
`C:\Program Files (x86)\Red 5 Studios\Firefall\system\gui\components\MainUI\Panels\R5Chat\R5Chat.lua`
with the one included.

Configuration
-------------

There is no GUI for configuration. Open the source code in a text editor (for example
Notepad) and take a look at the comments and variables in the beginning.

Limitations
-----------

* Currently experimental (my first Firefall addon and Lua program).
* No support for Melder addon manager.
* Has to be reinstalled after a Firefall patch.

