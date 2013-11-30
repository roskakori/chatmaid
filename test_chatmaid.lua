-- Test for chatmaid.
require "./chatmaid"

local function assertStringEquals(name, actual, expected)
    assert(actual == expected, name..': "'..repr(actual)..'" ~= "'..repr(expected)..'"')
end

local function assertArrayEquals(actual, expected)
    local actualWordsText = arrayText(actual)
    local expectedWordsText = arrayText(expected)
    assert(actualWordsText == expectedWordsText, actualWordsText.." ~= "..expectedWordsText)
end

local function assertSanitized(channel, utf8text, expectedMessage, expectedAction)
    actualMessage, actualAction = sanitized(channel, utf8text)
    assertStringEquals("message", actualMessage, expectedMessage)
    assertStringEquals("action", actualAction, expectedAction)
end

print("test bit8and")
assertStringEquals("bit8and(0, 0)", bit8and(0, 0), 0)
assertStringEquals("bit8and(0xff, 0xff)", bit8and(0xff, 0xff), 0xff)
assertStringEquals("bit8and(0xff, 0x0f)", bit8and(0xff, 0x0f), 0x0f)

print("test repr()")
print(repr(nil))
print(repr("hugo"))
print(repr("hugo\r\nsepp"))

print("test trimmed()")
assertStringEquals("trimmed: empty", trimmed(""), "")
assertStringEquals("trimmed: none", trimmed("x"), "x")
assertStringEquals("trimmed: preserve middle", trimmed("x y"), "x y")
assertStringEquals("trimmed: trailing", trimmed("x "), "x")
assertStringEquals("trimmed: leading", trimmed(" x"), "x")
assertStringEquals("trimmed: both", trimmed(" x "), "x")

print("test words()")
assertArrayEquals(words("hello world, this is great!!!"), {"hello", "world", ",", "this", "is", "great", "!!!"})

print("test arraySlice()")
assertArrayEquals(arraySlice({"one", "two", "three", "four"}, 2, 3), {"two", "three"})

print("test cleanedWhitespace")
assertStringEquals("cleaned: empty", cleanedWhitespace(""), "")
assertStringEquals("cleaned: nothing", cleanedWhitespace("just some proper text"), "just some proper text")
assertStringEquals("cleaned: empty", cleanedWhitespace("   messed   up space "), "messed up space")

print("test GuessedLanguage()")
assert(GuessedLanguage("tea") == "en")
assert(GuessedLanguage("grüner Veltliner") == "de")
assert(GuessedLanguage("водка") == "ru")
assert(GuessedLanguage("Sémillon") == "fr")

print("test sanitized")
assertSanitized("zone", "hello", "hello", nil)
assertSanitized("zone", "   messed   up space ", "messed up space", "cleanup whitespace")
assertSanitized("zone", "no!!!", "no!", "cleanup punctuation")
if enableHideGerman then
    assertSanitized("zone", "für nix", nil, "hide german")
end
assertSanitized("zone", "ty", nil, "hide thanks")

print "SUCCESS: all tests passed"
