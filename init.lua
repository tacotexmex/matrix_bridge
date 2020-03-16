local token = minetest.settings:get('telegram.token')
local chat_id = minetest.settings:get('telegram.chat_id')

if not token then
	error("Please set telegram.token to your bot's token in your minetest.conf.")
end
if not chat_id then
	error("Please set telegram.chat_id to the chat_id of the group in your minetest.conf.")
end

print(token)
print(chat_id)

local http_api = minetest.request_http_api()

if http_api == nil then
	error('This mods needs permission to perform HTTP requests. Please add `secure.http_mods = "telegram"` to your minetest.conf.')
end


local api_url = 'https://api.telegram.org/bot'..token..'/'
local long_polling_timeout = 600
local latest_update = 0


function getUpdates()
	minetest.log('verbose', "getUpdates with offset = "..latest_update)
	http_api.fetch({
		url = api_url..'getUpdates',
		post_data = {
			offset = latest_update,
			timeout = long_polling_timeout
		},
		timeout = long_polling_timeout + 1
	}, function (result)
		if result.succeeded and result.code == 200 then
			local parsed = minetest.parse_json(result.data)
			for _,update in pairs(parsed.result) do
				if update.update_id >= latest_update then
					minetest.log('verbose', "New update available from Telegram.")
					latest_update = update.update_id + 1
					local text = update.message.text
					if text then
						local name = update.message.from.username or update.message.from.first_name or update.message.from.id
						minetest.chat_send_all(name..': '..update.message.text)
					end
				end
			end
			minetest.after(1, getUpdates)
		elseif result.timeout then
			minetest.log('verbose', 'No more updates...')
			minetest.after(1, getUpdates)
		elseif result.code == 409 then
			minetest.log('warning', "Telegram rate limited!")
			minetest.after(10, getUpdates)
		else
			minetest.log('error', 'Could not receive updates from Telegram!')
			minetest.after(10, getUpdates)
		end
	end)
end


function sendMessage(text, disable_notification, callback)
	http_api.fetch({
		url = api_url..'sendMessage',
		post_data = {
			chat_id = chat_id,
			text = text,
			disable_notification = tostring(disable_notification),
			parse_mode = "Markdown"
		}
	}, callback)
end


function test_callback(result)
	if result.succeeded and result.code == 200 then
		local parsed = minetest.parse_json(result.data)
		minetest.log('verbose', "Message sent: "..parsed.result.text)
	else
		minetest.log('error', "error sending message: "..dump(result))
	end
end


function startup()
	sendMessage("Good Morning! The server is resurrecting from the dead. おはようございます！サーバーは死から復活しています。", false, test_callback)
end


function join(player)
	local name = "**"..player:get_player_name().."**"
	sendMessage(name.." joined the server. "..name.."さんはサーバーに参加しました。", false, test_callback)
end


function chat(name, message)
	sendMessage("**"..name.."**さんは「"..message.."」と言いました。", true, test_callback)
end


function dead(player)
	local name = "**"..player:get_player_name().."**"
	sendMessage(name.." has been confirmed dead. "..name.."さんは死亡が確認されました。", true, test_callback)
end


function leave(player)
	local name = "**"..player:get_player_name().."**"
	sendMessage(name.." left the server. "..name.."さんはサーバーを離れました。", true, test_callback)
end


function shutdown()
	sendMessage("Server is shutting down. サーバーがシャットダウンしています。", false, test_callback)
end


minetest.register_on_joinplayer(join)
minetest.register_on_chat_message(chat)
minetest.register_on_dieplayer(dead)
minetest.register_on_leaveplayer(leave)
minetest.register_on_shutdown(shutdown)


http_api.fetch({url = api_url..'getMe'}, function (result)
	if result.succeeded and result.code == 200 then
		local parsed = minetest.parse_json(result.data)
		minetest.log('info', "Starting up @"..parsed.result.username)
		startup()
		getUpdates()
	else
		minetest.log('error', "Telegram API returned an error. Is your token correct? Nothing more to do...")
	end
end)
