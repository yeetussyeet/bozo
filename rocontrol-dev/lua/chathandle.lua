function escape(str)
	return str:gsub("&","&amp;"):gsub("<","&lt;"):gsub("<","&gt;")
end

function RoControl_Chat(addRCTag,tagColor,username,str)
	game:GetService("TextChatService").TextChannels.RBXSystem:DisplaySystemMessage(
		string.format(
			"<font color=\"#ffffff\"><font color=\"#%s\">%s%s</font>: %s</font>",
			tagColor,
			(addRCTag and "[as " or "")..username..(addRCTag and "]" or ""),
			addRCTag and "</font> <font color=\"#FF0000\">RoControl" or "",
			escape(str)
		)
	)
end

-- handler

local chatHandlerRemote = game:GetService("ReplicatedStorage"):WaitForChild(script:GetAttribute("id"))

chatHandlerRemote.OnClientEvent:Connect(RoControl_Chat)