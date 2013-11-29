-- chatmaid -- improve the level of conversation in Firefalls's chat.

-- Settings

-- TODO: Hide messages with non ASCII characters
-- (which includes many non English languages).
local enableHideNonAscii = false

-- Hide certain languages?
local enableHideFrench = true
local enableHideGerman = false
local enableHideRussian = true

-- TODO: Hide plain "thanks" messages (and variants)?
local enableHideThanks = true

-- TODO: Hide messages containing no letters, for example a sole "/".
local enableHideSingleCharacters = true

-- TODO: How to deal with screaming in all upper case and redundant exclamation
-- marks.
--
-- "hide" hides such messages, "cleanup" makes them easier to read by changing
-- them to all lower case and replacing multiple exclamation marks with a
-- single one.
local handleScreaming = "cleanup"

local function Set (list)
	-- Set datatype as described in http://www.lua.org/pil/11.5.html.
	local result = {}
    for _, l in ipairs(list) do result[l] = true end
    return result
end

-- A string describing item (somewhat similar to Python's repr()).
function repr(item)
	if item == nil then
		result = "nil"
	else
		itemType = type(item)
		if type(item) == "string" then
			result = '"'
			for i = 1, item:len() do
				c = item:sub(i, i)
				code = c:byte(1)
				print("  "..code)
				if c == "\n" then
				    c = "\\n"
				elseif c == "\r" then
					c = "\\r"
				elseif c == "\t" then
					c = "\\t"
				elseif (code < 32) or (code > 127) then
					c = string.format("\\x%02x", code)
				end
				result = result..c
			end
			result = result..'"'
		else
			result = "<type:"..type(item)..">"
		end
	end
	return result
end

local function trimmed(s)
	-- Similar to s but without leading and trailing white space
	-- as described in http://lua-users.org/wiki/StringTrim.
	return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

local VALID_SINGLE_CHARACTERS = Set{
	"k", -- ok
	"n", -- no
	"y", -- yes
}

-- Unicodes for to detect certain languages.
-- See also: http://en.wikipedia.org/wiki/ISO_basic_Latin_alphabet.
local GERMAN_UNICODES = Set{
	196, -- Ä
	214, -- Ö
	220, -- Ü
	223, -- ß
	228, -- ä
	246, -- ö
	252, -- ü
}

local FRENCH_UNICODES = Set{
	156, -- œ
	224, -- à
	226, -- â
	230, -- æ
	231, -- ç
	232, -- è
	233, -- é
	234, -- ê
	235, -- ë
	238, -- î
	239, -- ï
	244, -- ô
	249, -- ù
	251, -- û
	-- 252, -- ü: excluded because it is used to detect German.
	255, -- ÿ
}

-- List of words to be considered thanks.
local THANKS = Set{
	{"danke"}, -- German
	{"merci"}, -- French
	{"thank", "you"},
	{"thanks"},
	{"thx"},
	{"thx", "u"},
	{"thx", "you"},
	{"txh"}, -- common typo
	{"ty"},
}

local function unicodes(utf8text)
	-- List of (integer) unicodes for characters found in UTF-8 encoded utf8text.
	--
	-- TODO: Convert this to an iterator.
	assert(bit32 ~= nil, "bit32 must be available; use lua 5.2+")
    local result = {}
	local resultIndex = 1
	local utf8textIndex = 1
	while utf8textIndex <= utf8text:len() do
		local code = utf8text:byte(utf8textIndex)
		-- print(resultIndex..";"..utf8textIndex..":"..code)
		if code >= 0xc0 then -- 110xxxxx
		    if code >= 0xfc then -- 1111110x
				code = bit32.band(code, 0x01)
			elseif code >= 0xf8 then -- 111110xx
				code = bit32.band(code, 0x03)
			elseif code >= 0xf0 then -- 11110xxx
				code = bit32.band(code, 0x07)
			elseif code >= 0xe0 then -- 1110xxxx
				code = bit32.band(code, 0x0f)
			else -- 110xxxxx
				code = bit32.band(code, 0x1f)
			end
			utf8textIndex = utf8textIndex + 1
			while (utf8textIndex <= utf8text:len()) and (utf8text:byte(utf8textIndex) >= 0x80) and (utf8text:byte(utf8textIndex) < 0xc0) do -- 10000000 resp. 110xxxxx
				-- print("  "..code.."*64 + "..bit32.band(utf8text:byte(utf8textIndex), 0x3f).." ("..utf8text:byte(utf8textIndex)..")")
			    code = (code * 64) + bit32.band(utf8text:byte(utf8textIndex), 0x3f) -- 00111111
				-- print("  --> "..code)
				utf8textIndex = utf8textIndex + 1
			end
		end
		result[resultIndex] = code
		utf8textIndex = utf8textIndex + 1
		resultIndex = resultIndex + 1
	end
	return result
end

local function isAscii(code)
    -- True if code indicates an ASCII character
    return (code <= 0x7f)
end

local function isCyrillic(code)
	-- True if code indicates a unicode for a Cyrillic letter.
	return (code >= 0x0400) and (code <= 0x4ff)
end

local function isUpper(text)
	-- True if text is all upper case.
	--
	-- FIXME: Add support for non ASCII letters.
	return text == text:upper()
end

local function isLetter(c)
	-- True if the first character of text is an ASCII letter or some non ASCII character.
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c:byte(1) >= 0x80)
end

local function boolText(value)
	return value and "true" or "false"
end

function arrayText(items)
	local result = "{"
	local atFirstItem = true
	for _, item in ipairs(items) do
		if atFirstItem then
			atFirstItem = false
		else
			result = result..", "
		end
		-- TODO: Quote only strings.
		-- TODO: Applay escapes on strings.
		-- TODO: Use boolText() on boolean items.
		result = result..'"'..item..'"'
	end
	result = result.."}"
	return result
end

function arraySlice(items, firstIndex, lastIndex)
	assert(items ~= nil)
	assert(firstIndex ~= nil)
	assert(firstIndex >= 1)
	if lastIndex == nil then
		lastIndex = #items
	else
		assert(lastIndex >= firstIndex)
	end

	local result = {}
	for index = firstIndex, lastIndex do
		result[index - firstIndex + 1] = items[index]
	end
	return result;
end

function words(text)
    local result = {}
	local resultIndex = 1
	for part in text:gmatch("[^%s]+") do
		local word = part:sub(1,1)
		local isLetterWord = isLetter(word)
		local partIndex = 2
		while partIndex <= #part do
			local charToExamine = part:sub(partIndex, partIndex)
			local charToExamineIsLetter = isLetter(charToExamine)
			-- print("ilw="..boolText(isLetterWord)..", c="..charToExamine..", cil="..boolText(charToExamineIsLetter)..", word="..word)
			if isLetterWord == charToExamineIsLetter then
				word = word..charToExamine
			else
				result[resultIndex] = word
				resultIndex = resultIndex + 1
				word = charToExamine
				isLetterWord = charToExamineIsLetter
			end
			partIndex = partIndex + 1
		end
		result[resultIndex] = word
		resultIndex = resultIndex + 1
	end
	return result
end

function letteredWords(words)
	local result = {}
	local resultIndex = 1
	for _, word in ipairs(words) do
		if isLetter(word:sub(1,1)) then
			result[resultIndex] = word
			resultIndex = resultIndex + 1
		end
	end
	return result
end

function plainText(text)
	-- Reduce multiple while space to single blank.
	result = text:gsub("%s+", " ")
	-- Reduce multiple exclamation and question marks to a single one.
	result = result:gsub("!+", "!"):gsub("?+", "?")
	-- Remove leading and trailing space.
	result = trimmed(result)

	return result
end

function GuessedLanguage(utf8text)
	-- A (cursory) guess for the language in which utf8text is written.
	local result = nil
	-- print("GuessedLanguage("..utf8text..")")
	local codes = unicodes(utf8text)
	local codeIndex = 1
	while (codeIndex <= #codes) and (result == nil) do
		local code = codes[codeIndex]
		if isCyrillic(code) then
			result = "ru"
		elseif FRENCH_UNICODES[code] ~= nil then
			result = "fr"
		elseif GERMAN_UNICODES[code] ~= nil then
			result = "de"
		else
			codeIndex = codeIndex + 1
		end
		-- print("  "..(result and result or "nil").." <-- "..c)
	end
	if result == nil then
	  result = "en"
	end
	return result
end

-- A tuple containing the message and actions performed on it based on the
-- channel and utf8text of the original message. If the message should be
-- hidden, it is nil. If no actions have been performed, they are nil.
function sanitized(channel, utf8text)
    -- TODO: Hide non ASCII.

	-- Hide undesired languages.
	language = GuessedLanguage(utf8text)
	if enableHideFrench and (language == "fr") then
		return nil, "hide french"
	elseif enableHideGerman and (language == "de") then
		return nil, "hide german"
	elseif enableHideRussian and (language == "ru") then
		return nil, "hide russian"
	end

	-- Hide single characters.
	if enableHideSingleCharacters and (utf8text:len() == 1) and (VALID_SINGLE_CHARACTERS[utf8text] == nil) then
		return nil, "hide single character"
	end

	messageWords = words(utf8text)
	if (channel == "zone") and enableHideThanks and (THANKS[messageWords] ~= nil) then
		return nil, "hide thanks"
	end

	-- The message was just fine.
	return utf8text, nil
end
