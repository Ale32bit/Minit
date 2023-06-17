-- ESpeak module for Minit
-- Copyright (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

-- This code is based on CCSpeaks by SquidDev
-- https://github.com/SquidDev-CC/CCSpeaks

-- This module is made for SwitchCraft 3
-- A Chatbox license is required to use this module
-- Or use "guest" license

local module = {
    name = "espeak",
}

settings.define("espeak.volume", {
    description: "The volume for ESpeak TTS",
    default: 100,
    type: "number"
})

local username
local function speak(message)
    local url = "https://music.madefor.cc/tts?text=" .. textutils.urlEncode(message)
    local response, err = http.get { url = url, binary = true }
    if not response then error(err, 0) end

    local speaker = peripheral.find("speaker")
    local decoder = require("cc.audio.dfpwm").make_decoder()

    while true do
        local chunk = response.read(16 * 1024)
        if not chunk then break end

        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer, settings.get("espeak.volume")) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

local function run()
    while true do
        local _, user, msg = os.pullEvent("chat_ingame")
        if user == username then
            speak(msg)
        end
    end
end

function module.init(init)
    init.addTask(run)
end

function module.setup(neural)
    local meta = neural.getMetaOwner()
    username = meta.name
end

return module
