# Minetest Matrix bridge

A bridge to relay messages from Matrix to Minetest and vice-versa.

I made this mod because the only other mode I found on the Internet required a complex setup.

## How to install

1. Install this mod like [any other mod](https://dev.minetest.net/Installing_Mods).
2. You need a Telegram bot. Create one following the [Telegram documentation](https://core.telegram.org/bots#6-botfather).
3. Ask BotFather to disable bot privacy, to allow the bot to read any message.
4. Add the bot to the target group chat and send a message.
5. Open a web browser and open this URL `https://api.telegram.org/bot<token>/getUpdates` replacing <token> with the token given to you by BotFather. You should find the correct chat id (it's a number).
6. Open your minetest.conf file in a text editor and add these 2 lines:
    1. `telegram.token = "put here your bot's token"`. The token is the one that BotFather gave you.
    2. `telegram.chat_id = "put here your chat id"`. The chat ID is the one you should have found earlier.
7. Start your Minetest server and enjoy.
