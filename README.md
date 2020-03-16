# Minetest Telegram bridge

A bridge to relay messages from Telegram to Minetest and vice-versa.

I made this mod because the only other mode I found on the Internet required a complex setup.

## How to install

1. Install this mod like [any other mod](https://dev.minetest.net/Installing_Mods).
2. You need a Telegram bot. Create one following the [Telegram documentation](https://core.telegram.org/bots#6-botfather).
3. Open your minetest.conf file in a text editor and add this line: `telegram.token = "put here your bot's token"`. The token is the one that @BotFather gave you.
4. Ask @BotFather to disable bot privacy, to allow the bot to read any message.
5. Add the bot to the target group chat.
6. Send a message in the group chat.
7. Start the server once. You should see a chat ID in the server's log. Copy it.
8. Open again your minetest.conf file and add this line: `telegram.chat_id = "put here your chat id"`.
9. Restart the server and enjoy.