-- chatmaid -- improve the level of conversation in Firefalls's chat.

-- Settings



-- TODO: How to deal with screaming in all upper case?
--
-- "hide" hides such messages, "cleanup" makes them easier to read by changing
-- them to all lower case.
local handleScreaming = "cleanup"

-- Instead of performing actions only append the proposed action to the
-- message. For example "ty" becomes "ty [hide thanks]". This is useful for
-- testing and debugging.
local enableTraceActions = true


local function Set (list)
    -- Set datatype as described in http://www.lua.org/pil/11.5.html.
    local result = {}
    for _, l in ipairs(list) do result[l] = true end
    return result
end

-- Types that repr() can show directly using tostring().
local _TOSTRINGABLE_TYPES = Set{"nil", "number" }

-- A string describing item (somewhat similar to Python's repr()).
function repr(item)
    local result
    local itemType = type(item)
    if _TOSTRINGABLE_TYPES[itemType] then
        result = tostring(item)
    elseif itemType == "string" then
        result = '"'
        for i = 1, item:len() do
            local c = item:sub(i, i)
            local code = c:byte(1)
            -- TODO: Remove: print("  "..code)
            if c == "\"" then
                c = "\\\""
            elseif c == "\\" then
                c = "\\\\"
            elseif c == "\n" then
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
    return result
end

-- Similar to s but without leading and trailing white space
-- as described in http://lua-users.org/wiki/StringTrim.
function trimmed(s)
    return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

-- Bitwise and operator for 8 bit. Lua 5.1 does not yet support bit32.band().
function bit8and(a, b)
    local result = 0
    for i = 0, 7 do
        if (a % 2)  + (b % 2) == 2 then
            result = result + 2 ^ i
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

local VALID_SINGLE_CHARACTERS = Set{
    "k", -- ok
    "n", -- no
    "r", -- ready
    "y", -- yes
    "?", -- confused
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
    "danke", -- German
    "merci", -- French
    "thank you",
    "thanks",
    "thx",
    "thx u",
    "thx you",
    "tnx",
    "txh", -- common typo
    "ty",
}

-- List of (integer) unicodes for characters found in UTF-8 encoded utf8text.
local function unicodes(utf8text)
    -- TODO: Convert this to an iterator.
    local result = {}
    local resultIndex = 1
    local utf8textIndex = 1
    while utf8textIndex <= utf8text:len() do
        local code = utf8text:byte(utf8textIndex)
        -- TODO: Remove: print(resultIndex..";"..utf8textIndex..":"..code)
        if code >= 0xc0 then -- 110xxxxx
            if code >= 0xfc then -- 1111110x
                code = bit8and(code, 0x01)
            elseif code >= 0xf8 then -- 111110xx
                code = bit8and(code, 0x03)
            elseif code >= 0xf0 then -- 11110xxx
                code = bit8and(code, 0x07)
            elseif code >= 0xe0 then -- 1110xxxx
                code = bit8and(code, 0x0f)
            else -- 110xxxxx
                code = bit8and(code, 0x1f)
            end
            utf8textIndex = utf8textIndex + 1
            while (utf8textIndex <= utf8text:len()) and (utf8text:byte(utf8textIndex) >= 0x80) and (utf8text:byte(utf8textIndex) < 0xc0) do -- 10000000 resp. 110xxxxx
                -- TODO: Remove: print("  "..code.."*64 + "..bit8and(utf8text:byte(utf8textIndex), 0x3f).." ("..utf8text:byte(utf8textIndex)..")")
                code = (code * 64) + bit8and(utf8text:byte(utf8textIndex), 0x3f) -- 00111111
                -- TODO: Remove: print("  --> "..code)
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
        -- TODO: Apply escapes on strings.
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
            -- TODO: Remove: print("ilw="..boolText(isLetterWord)..", c="..charToExamine..", cil="..boolText(charToExamineIsLetter)..", word="..word)
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

-- Similar to text but without leading, trailing and redundant whitespace.
function cleanedWhitespace(text)
    -- Reduce multiple while space to single blank.
    local result = text:gsub("%s+", " ")
    -- Remove leading and trailing space.
    result = trimmed(result)

    return result
end

-- Similar to text but without redundant exclamation and question marks.
function cleanedPunctuation(text)
    -- Reduce multiple exclamation and question marks to a single one.
    return text:gsub("!+", "!"):gsub("?+", "?")
end

function GuessedLanguage(utf8text)
    -- A (cursory) guess for the language in which utf8text is written.
    local result
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
        elseif code >= 128 then
            -- Unknown, non english language.
            result = "xx"
        else
            codeIndex = codeIndex + 1
        end
    end
    if result == nil then
      result = "en"
    end
    return result
end

-- A tuple containing the message and actions performed on it based on the
-- channel, utf8text of the original message and message. If the message
-- should be hidden, it is nil. If no actions have been performed, they are
-- nil.
--
-- Settings are a table where the following keys can be set:
--
-- * TODO: cleanupWhitespace - remove leading, trailing and redundant whitespace?
--   For example, " hello   world  " becomes "hello world"
-- * TODO: cleanMultiplePunctuation - reduce multiple exclamation and question
--   marks to a single one? For example "no!!!" becomes "no!"
-- * hideCyrillic: hide messages using Cyrillic alphabet
-- * hideFrench: hide messages using French alphabet
-- * hideGeDuNo: hide messages using German, Dutch or Nordic alphabet
-- * hideNonAscii: hide messages using non ASCII characters
-- * hideSingleCharacters: hide single characters
-- * hideThanks: hide "thank you" messages
function sanitized(channel, utf8text, settings)
    assert(channel ~= nil)
    assert(utf8text ~= nil)
    assert(settings ~= nil)

    local actions = ""
    local cleanedText = utf8text

    -- Remove leading and trailing whitespace.
    local previousText = cleanedText
    cleanedText = cleanedWhitespace(cleanedText)
    if cleanedText:len() == 0 then
        return nil, "hide empty"
    elseif cleanedText ~= previousText then
        actions = actions.."; cleanup whitespace"
    end

    previousText = cleanedText
    cleanedText = cleanedPunctuation(cleanedText)
    if cleanedText ~= previousText then
        actions = actions.."; cleanup punctuation"
    end

    -- Hide undesired languages.
    if (channel == "zone") or (channel == "local") then
        local language = GuessedLanguage(cleanedText)
        if settings.hideCyrillic and (language == "ru") then
            return nil, "hide cyrillic"
        elseif settings.hideFrench and (language == "fr") then
            return nil, "hide french"
        elseif settings.hideGeDuNo and (language == "de") then
            return nil, "hide german/dutch/nordic"
        elseif settings.hideNonAscii and (language ~= "en") then
            return nil, "hide non ascii"
        end
    end

    -- Hide single characters.
    if settings.hideSingleCharacters then
        local isSingleCharacter = (cleanedText:len() == 1)
        local isDigit = (cleanedText >= "0") and (cleanedText <= "9")
        if isSingleCharacter and not isDigit and (VALID_SINGLE_CHARACTERS[cleanedText] == nil) then
            return nil, "hide single character"
        end
    end

    if (channel == "zone") and settings.hideThanks and (THANKS[cleanedText] ~= nil) then
        return nil, "hide thanks"
    end

    -- Apart from possible cleanups, the message was just fine.
    if actions == "" then
        actions = nil
    else
        -- Remove leading "; " from actions
        assert(actions:sub(1,2) == "; ", "actions="..actions)
        actions = actions:sub(3)
    end
    return cleanedText, actions
end
