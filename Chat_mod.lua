# -*- coding: utf-8 -*-
-- Modifications for Firefall's chat module to filter messages through
-- chatmaid.
@mod "chatmaid - include chatmaid.lua"
@after last glob "require \"?*\""
@include "chatmaid.lua"

@mod "chatmaid - sanitize message"
@after "function lf.ProcessChatMessageArgs(args)"
@before "\treturn args"
	if chatmaid_GlobalOptions.ChatmaidEnabled then
        chatmaidSettings = {
            cleanMultiplePunctuation = true,
            cleanupWhitespace = true,
            hideCyrillic = chatmaid_GlobalOptions.ChatmaidHideCyrillic,
            hideFrench = chatmaid_GlobalOptions.ChatmaidHideFrench,
            hideGeDuNo = chatmaid_GlobalOptions.ChatmaidHideGeDuNo,
            -- FIXME #1: hideNonAscii = chatmaid_GlobalOptions.ChatmaidHideNonAscii,
            hideSingleCharacters = true,
            hideThanks = true,
        }
		message, action = sanitized(args.channel, args.message, chatmaidSettings)
		if action ~= nil then
			if chatmaid_GlobalOptions.ChatmaidExplainActions then
				args.message = args.message.." ["..action.."]"
			elseif not message then
				return nil
			else
				args.message = message
			end
		end
	end
