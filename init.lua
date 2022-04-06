local server = minetest.settings:get("matrix.server")
local token = minetest.settings:get("matrix.token")
local room = minetest.settings:get("matrix.room")
local server_name = minetest.settings:get("server_name")

if not server then
	error("Please set matrix.server to your Matrix homeserver URL in minetest.conf.")
end

if not token then
	error("Please set matrix.token to your Matrix access token in minetest.conf.")
end
if not room then
	error("Please set matrix.room to the room ID in minetest.conf.")
end

local http_api = minetest.request_http_api()

if http_api == nil then
	error('This mods needs permission to perform HTTP requests. Please add `secure.http_mods = "matrix_bridge"` to minetest.conf.')
end

local api_url = server.."/_matrix/client/r0/"
local long_polling_timeout = 300
local latest_update = ""
--GET /_matrix/client/r0/rooms/ROOM/messages?from=s345_678_333&dir=b&limit=3&filter=%7B%22contains_url%22%3Atrue%7D HTTP/1.1
local function getEvents()
	minetest.log("verbose", "sync with offset = "..latest_update)
	local from = ""
	if latest_update ~= "" then
		from = "from="..latest_update.."&"
	end
	http_api.fetch({
		url = api_url.."rooms/"..room.."/messages?"..from.."dir=b&limit=1&access_token="..token,
		post_data = {
		-- 	offset = latest_update,
		-- 	timeout = long_polling_timeout
		},
		timeout = long_polling_timeout + 10
	}, function (result)
		if result.succeeded and result.code == 200 then
			-- local parsed = minetest.parse_json(result.data)
			print ("---HÄR------------------------ "..dump(result.data))

			-- if parsed.timeline.prev_batch != latest_update then

			-- end

		-- 	for _,event in pairs(parsed.timeline.events) do
		-- 		if event.event_id != latest_update then
		-- 			minetest.log("verbose", "New update available from Telegram.")
		-- 			latest_update = update.update_id + 1
		-- 			local text = update.message.text
		-- 			if text then
		-- 				local name = update.message.from.username or update.message.from.first_name or update.message.from.id
		-- 				minetest.chat_send_all(name..": "..update.message.text)
		-- 			end
		-- 		end
		-- 	end
		-- 	minetest.after(1, getEvents)
		-- elseif result.timeout then
		-- 	minetest.log("verbose", "No more updates...")
		-- 	minetest.after(1, getEvents)
		-- elseif result.code == 409 then
		-- 	minetest.log("warning", "Telegram rate limited!")
		-- 	minetest.after(10, getEvents)
		-- else
		-- 	minetest.log("error", "Could not receive updates from Telegram!")
		-- 	minetest.after(10, getEvents)
		end
	end)
end

local function sendMessage(message, disable_notification, callback)
	http_api.fetch({
		url = api_url.."rooms/"..room.."/send/m.room.message?access_token="..token,
		post_data = minetest.write_json({
			msgtype = "m.text",
			body = message.body,
            format = "org.matrix.custom.html",
			formatted_body = message.formatted_body
		})
	}, callback)
end

local function test_callback(result)
	if result.succeeded and result.code == 200 then
		local parsed = minetest.parse_json(result.data)
		minetest.log("verbose", "Message sent: "..parsed.event_id)
	else
		minetest.log("error", "error sending message: "..parsed.event_id)
	end
end

local function hashcolor(name)
	local name_hash = name.."sixcharsminimum"
	return string.sub(minetest.sha1(name_hash), 1, 6)
end

local function startup()
	sendMessage({
		body = "Server "..server_name.." is starting up",
		formatted_body = "☀️ <em>Server "..server_name.." is starting up</em>."
	},
		false,
		test_callback
	)
end

local function join(player)
	local name = player:get_player_name()
	sendMessage({
		body = name.." joined the server.",
		formatted_body = "👊 <em><font color=#"..hashcolor(name)..">"..name.."</font> joined the server.</em>"
	},
		false,
		test_callback
	)
end

local function chat(name, message)
	sendMessage({
		body = "<"..name.."> "..message,
		formatted_body = "<strong><font color=#"..hashcolor(name)..">&lt;"..name.."&gt;</strong> "..message
	},
		true,
		test_callback
	)
end

local function dead(player)
	local name = player:get_player_name()
	sendMessage({
		body = name.." has been confirmed dead.",
		formatted_body = "💀 <em><font color=#"..hashcolor(name)..">"..name.." has been confirmed dead.</em>"
	},
		true,
		test_callback
	)
end

local function leave(player)
	local name = player:get_player_name()
	sendMessage({
		body = name.." left the server.",
		formatted_body = "👋 <em><font color=#"..hashcolor(name)..">"..name.." left the server.</em>"
	},
		true,
		test_callback
	)
end

local function shutdown()
	sendMessage({
		body = "Server "..server_name.." is shutting down.",
		formatted_body = "🌙 <em>Server "..server_name.." is shutting down.</em>"
	},
		false,
		test_callback
	)
end

minetest.register_on_joinplayer(join)
minetest.register_on_chat_message(chat)
minetest.register_on_dieplayer(dead)
minetest.register_on_leaveplayer(leave)
minetest.register_on_shutdown(shutdown)

http_api.fetch({url = api_url.."account/whoami?access_token="..token},
	function (result)
		if result.succeeded and result.code == 200 then
			local parsed = minetest.parse_json(result.data)
			minetest.log("info", "Starting up bridge through "..parsed.user_id)
			startup()
			getEvents()
		else
			minetest.log("error", "Matrix client API returned an error. Is your token correct?")
		end
	end
)