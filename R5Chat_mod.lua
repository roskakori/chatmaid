# -*- coding: utf-8 -*-
-- Modifications for Firefall's chat module to filter messages through
-- chatmaid.
@mod "chatmaid.lua"
@after last glob "require \"?*\""
@include "chatmaid.lua"

@mod "sanitize message"
@after "function OnChatMessage(args)"
@after "\tif not IO_Settings.Channels[args.channel] then"
@after "\tend"
	-- TODO: only check if IO_Settings.General.ChatmaidEnabled is true.
	if IO_Settings.General.ChatmaidEnabled then
        chatmaidSettings = {
            cleanMultiplePunctuation = true,
            cleanupWhitespace = true,
            hideCyrillic = IO_Settings.General.ChatmaidHideCyrillic,
            hideFrench = IO_Settings.General.ChatmaidHideFrench,
            hideGeDuNo = IO_Settings.General.ChatmaidHideGeDuNo,
            hideNonAscii = IO_Settings.General.ChatmaidHideNonAscii,
            hideSingleCharacters = true,
            hideThanks = true,
        }
		text, action = sanitized(args.channel, args.text, chatmaidSettings)
		if action ~= nil then
			if IO_Settings.General.ChatmaidExplainActions then
				args.text = args.text.." ["..action.."]"
			elseif not text then
				return nil
			else
				args.text = text
			end
		end
	end
