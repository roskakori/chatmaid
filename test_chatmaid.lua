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

print("test repr()")
print(repr(nil))
print(repr("hugo"))
print(repr("hugo\r\nsepp"))

print("test words()")
assertArrayEquals(words("hello world, this is great!!!"), {"hello", "world", ",", "this", "is", "great", "!!!"})

print("test arraySlice()")
assertArrayEquals(arraySlice({"one", "two", "three", "four"}, 2, 3), {"two", "three"})

print("test GuessedLanguage()")
assert(GuessedLanguage("tea") == "en")
assert(GuessedLanguage("grüner Veltliner") == "de")
assert(GuessedLanguage("водка") == "ru")
assert(GuessedLanguage("Sémillon") == "fr")

print("test sanitized")
message, action = sanitized("zone", "hello")
assertSanitized("zone", "hello", "hello", nil)
if enableHideGerman then
    assertSanitized("zone", "für nix", nil, "hide german")
end

print "tests passed"
