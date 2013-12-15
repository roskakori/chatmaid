# -*- coding: utf-8 -*-
-- Modifications for ChatOptions.lua
@mod "add GUI"
@after "for i, tab in ipairs(IO_Settings.Tabs) do"
@after "end"
		InterfaceOptions.StartGroup({id="CHATMAID_ENABLED", label="Chatmaid", checkbox=IO_Settings.General.ChatmaidEnabled, default=true})
		InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_FRENCH", label="Hide French", tooltip="Hide (some) chat messages in French language.", default=IO_Settings.General.ChatmaidHideFrench});
		InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_GERMAN", label="Hide German", tooltip="Hide (some) chat messages in German language.", default=IO_Settings.General.ChatmaidHideGerman});
		InterfaceOptions.AddCheckBox({id="CHATMAID_HIDE_RUSSIAN", label="Hide Russian", tooltip="Hide chat messages in Russian language.", default=IO_Settings.General.ChatmaidHideRussian});
		InterfaceOptions.AddCheckBox({id="CHATMAID_EXPLAIN_ACTIONS", label="Explain actions", tooltip="Explain actions that would have been performed on chat messages (if any).", default=IO_Settings.General.ChatmaidExplainActions});
		InterfaceOptions.StopGroup()

@mod "default settings"
@after "\tGeneral = {"
@before "\t},"
		ChatmaidEnabled = true,
		ChatmaidExplainActions = true,
		ChatmaidHideFrench = false,
		ChatmaidHideGerman = false,
		ChatmaidHideRussian = true,

@mod "handle settings events"
@after "function OnOptionChange(id, val)"
@before "\telse"
	elseif id == "CHATMAID_ENABLED" then
		IO_Settings.General.ChatmaidEnabled = val
	elseif id == "CHATMAID_EXPLAIN_ACTIONS" then
		IO_Settings.General.ChatmaidExplainActions = val
	elseif id == "CHATMAID_HIDE_FRENCH" then
		IO_Settings.General.ChatmaidHideFrench = val
	elseif id == "CHATMAID_HIDE_GERMAN" then
		IO_Settings.General.ChatmaidHideGerman = val
	elseif id == "CHATMAID_HIDE_RUSSIAN" then
		IO_Settings.General.ChatmaidHideRussian = val
