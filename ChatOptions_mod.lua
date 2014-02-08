# -*- coding: utf-8 -*-
-- Modifications for ChatOptions.lua
@mod "chatmaid - add GUI"
@before "for _, channel in ipairs(C_ChannelOrder) do"
InterfaceOptions.StartGroup({id="CHATMAID_ENABLED", label="Chatmaid", checkbox=io_GlobalOptions.ChatmaidEnabled, default=io_GlobalOptions.ChatmaidEnabled})
-- FIXME #1: InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_NON_ASCII", label="Hide messages using letters outside of basic Latin alphabet", tooltip="Technically speaking: non ASCII characters", default=io_GlobalOptions.ChatmaidHideNonAscii});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_FRENCH", label="Hide messages using French alphabet", default=io_GlobalOptions.ChatmaidHideFrench});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_GEDUNO", label="Hide messages using German, Dutch or Nordic alphabet", tooltip="Also hides: Danish, Finnish, Norwegian, Swedish", default=io_GlobalOptions.ChatmaidHideGeDuNo});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_CYRILLIC", label="Hide messages using Cyrillic alphabet (e.g. Russian)", default=io_GlobalOptions.ChatmaidHideCyrillic});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_COMMON_NON_ENGLISH", label="Hide messages using common non English words", default=io_GlobalOptions.ChatmaidHideCommonNonEnglish});
InterfaceOptions.AddCheckBox({id="CHATMAID_EXPLAIN_ACTIONS", label="Explain actions", tooltip="Explain actions that would have been performed on chat messages (if any).", default=io_GlobalOptions.ChatmaidExplainActions});
InterfaceOptions.StopGroup()

@mod "chatmaid - default settings"
@after "local io_GlobalOptions = {"
@before "}"
	ChatmaidEnabled = true,
	ChatmaidExplainActions = false,
	ChatmaidHideCommonNonEnglish = false,
	ChatmaidHideCyrillic = true,
	ChatmaidHideFrench = false,
	ChatmaidHideGeDuNo = false,
	ChatmaidHideNonAscii = false,

@mod "chatmaid - expose settings"
@after "local io_GlobalOptions = {"
@after "}"
-- HACK: Globally expose local options so Chat.lua can access them.
chatmaid_GlobalOptions = io_GlobalOptions


@mod "chatmaid - handle settings events"
@before "function Option_Func.TIMESTAMP(val)"
function Option_Func.CHATMAID_ENABLED(value)
	io_GlobalOptions.ChatmaidEnabled = value
end

function Option_Func.CHATMAID_ENABLED(value)
	io_GlobalOptions.ChatmaidEnabled = value
end

function Option_Func.CHATMAID_ENABLED(value)
	io_GlobalOptions.ChatmaidEnabled = value
end

function Option_Func.CHATMAID_EXPLAIN_ACTIONS(value)
	io_GlobalOptions.ChatmaidExplainActions = value
end

function Option_Func.CHATMAID_HIDE_COMMON_NON_ENGLISH(value)
	io_GlobalOptions.ChatmaidHideCommonNonEnglish = value
end

function Option_Func.CHATMAID_HIDE_CYRILLIC(value)
	io_GlobalOptions.ChatmaidHideCyrillic = value
end

function Option_Func.CHATMAID_HIDE_FRENCH(value)
	io_GlobalOptions.ChatmaidHideFrench = value
end

function Option_Func.CHATMAID_HIDE_GEDUNO(value)
	io_GlobalOptions.ChatmaidEnabled = value
end

function Option_Func.CHATMAID_ENABLED(value)
	io_GlobalOptions.ChatmaidHideGeDuNo = value
end

function Option_Func.CHATMAID_HIDE_NON_ASCII(value)
	io_GlobalOptions.ChatmaidHideNonAscii = value
end
