# -*- coding: utf-8 -*-
-- Modifications for ChatOptions.lua
@mod "add GUI"
@after "for i, tab in ipairs(IO_Settings.Tabs) do"
@after "end"
InterfaceOptions.StartGroup({id="CHATMAID_ENABLED", label="Chatmaid", checkbox=IO_Settings.General.ChatmaidEnabled, default=true})
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_NON_ASCII", label="Hide messages using letters outside of basic Latin alphabet", tooltip="Technically speaking: non ASCII characters", default=IO_Settings.General.ChatmaidHideNonAscii});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_FRENCH", label="Hide messages using French alphabet", default=IO_Settings.General.ChatmaidHideFrench});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_GEDUNO", label="Hide messages using German, Dutch or Nordic alphabet", tooltip="Also hides: Danish, Finnish, Norwegian, Swedish", default=IO_Settings.General.ChatmaidHideGeDuNo});
InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_CYRILLIC", label="Hide messages using Cyrillic alphabet (e.g. Russian)", default=IO_Settings.General.ChatmaidHideCyrillic});
InterfaceOptions.AddCheckBox({id="CHATMAID_EXPLAIN_ACTIONS", label="Explain actions", tooltip="Explain actions that would have been performed on chat messages (if any).", default=IO_Settings.General.ChatmaidExplainActions});
InterfaceOptions.StopGroup()

@mod "default settings"
@after "\tGeneral = {"
@before "\t},"
		ChatmaidEnabled = true,
		ChatmaidExplainActions = true,
		ChatmaidHideCyrillic = true,
		ChatmaidHideFrench = false,
		ChatmaidHideGeDuNo = false,
		ChatmaidHideNonAscii = false,

@mod "handle settings events"
@after "function OnOptionChange(id, val)"
@before "\telse"
	elseif id == "CHATMAID_ENABLED" then
		IO_Settings.General.ChatmaidEnabled = val
	elseif id == "CHATMAID_EXPLAIN_ACTIONS" then
		IO_Settings.General.ChatmaidExplainActions = val
	elseif id == "CHATMAID_HIDE_CYRILLIC" then
		IO_Settings.General.ChatmaidHideCyrillic = val
	elseif id == "CHATMAID_HIDE_FRENCH" then
		IO_Settings.General.ChatmaidHideFrench = val
	elseif id == "CHATMAID_HIDE_GEDUNO" then
		IO_Settings.General.ChatmaidHideGeDuNo = val
	elseif id == "CHATMAID_HIDE_NON_ASCII" then
		IO_Settings.General.ChatmaidHideNonAscii = val
