local ircparser = dofile("mods/evaisa.streambattle/lib/ircparser.lua")
dofile( "data/scripts/perks/perk.lua" )
dofile( "data/scripts/game_helpers.lua" )
dofile_once("mods/evaisa.streambattle/files/scripts/lib/utils.lua")

local old_streaming_on_irc = _streaming_on_irc
function _streaming_on_irc(is_userstate, sender_username, message, raw)
	local lines = ircparser.split(raw, '\r\n')
	for _, line in pairs(lines) do
		if(string.match(line, "PRIVMSG") and string.sub(line, 1, 11) == "@badge-info")then
			if(line == nil or line == "" or line == "	" or line == " ")then
				return
			end
			local data = ircparser.websocketMessage(line)
			if(data ~= nil)then
				local broadcaster = false
				local mod = false
				local subscriber = false
				local turbo = false

				if(string.match(data["tags"]["badges"], "broadcaster"))then
					broadcaster = true
				end

				if(tonumber(data["tags"]["mod"]) == 1)then
					mod = true
				end
				if(tonumber(data["tags"]["subscriber"]) == 1)then
					subscriber = true
				end
				if(tonumber(data["tags"]["turbo"]) == 1)then
					turbo = true
				end

				local userdata = {
					username = data["tags"]["display-name"],
					user_id = data["tags"]["user-id"],
					message_id = data["tags"]["id"],
					broadcaster = broadcaster,
					mod = mod,
					subscriber = subscriber,
					turbo = turbo,
					color = data["tags"]["color"],
					custom_reward = data["tags"]["custom-reward-id"],
					message = message
				}
				
				local function OnTwitchMessage(userdata, message)
					
					async(function()
						if(userdata.color == "" or userdata.color == nil)then
							userdata.color = "#8f8f8f"
						end
				
						userdata.username = userdata.username:gsub("||", "")
						userdata.message = userdata.message:gsub("||", "")
				
						userdata.username = userdata.username:gsub("::", "")
						userdata.message = userdata.message:gsub("::", "")
				
						if(userdata.broadcaster == "")then
							userdata.broadcaster = false
						end
				
						if(userdata.subscriber == "")then
							userdata.subscriber = false
						end
				
						if(userdata.mod == "")then
							userdata.mod = false
						end
				
				
						userdata.message_id = userdata.message_id or tostring(Random(0, 10000000))
				
						GlobalsSetValue("streambattle_chat_message_id", GlobalsGetValue("streambattle_chat_message_id", "") .. "||" .. userdata.message_id)
						GlobalsSetValue("streambattle_chat_message_color", GlobalsGetValue("streambattle_chat_message_color", "") .. "||" .. userdata.message_id .. "::" .. userdata.color)
						GlobalsSetValue("streambattle_chat_message_name", (GlobalsGetValue("streambattle_chat_message_name", "") .. "||" .. userdata.message_id .. "::" .. userdata.username) or "")
						GlobalsSetValue("streambattle_chat_message_userid", (GlobalsGetValue("streambattle_chat_message_userid", "") .. "||" .. userdata.message_id .. "::" .. userdata.user_id) or "")
						GlobalsSetValue("streambattle_chat_message_content", (GlobalsGetValue("streambattle_chat_message_content", "") .. "||" .. userdata.message_id .. "::" .. userdata.message) or "")
						GlobalsSetValue("streambattle_chat_message_broadcaster", GlobalsGetValue("streambattle_chat_message_broadcaster", "") .. "||" .. userdata.message_id .. "::" .. tostring(userdata.broadcaster or "false"))
						GlobalsSetValue("streambattle_chat_message_subscriber", GlobalsGetValue("streambattle_chat_message_subscriber", "") .. "||" .. userdata.message_id .. "::" .. tostring(userdata.subscriber or "false"))
						GlobalsSetValue("streambattle_chat_message_moderator", GlobalsGetValue("streambattle_chat_message_moderator", "") .. "||" .. userdata.message_id .. "::" .. tostring(userdata.mod or "false"))
						GlobalsSetValue("streambattle_chat_message_frame", GlobalsGetValue("streambattle_chat_message_frame", "") .. "||" .. userdata.message_id .. "::" .. GameGetFrameNum())
					end)
				end

				OnTwitchMessage(userdata, message)

			end
		end
	end

  if (old_streaming_on_irc ~= nil) then
    old_streaming_on_irc(is_userstate, sender_username, message, raw)
  end
end
