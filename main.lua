loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()


-- LocalScript: StarterPlayerScripts
-- Cycles through a list of messages, sends each to chat (with random suffix),
-- switches target every MESSAGE_INTERVAL seconds, and optionally server-hops.

-- SETTINGS
local MESSAGES = {
    "join /ɾagebaits | ",
    "join /ɾagebaits 4 nitro | ",
    "boost /ɾagebaits 4 your own msg 🤑🤑 | ",
    "/sţud 4 egirls | ", -- 1424087959103209675
    "get your own msg in /ɾagebaits !! | ",
    "gws in /sţud | " -- 1424087959103209675
}
local MESSAGE_INTERVAL    = 3     -- seconds between messages / target switches
local SUFFIX_LEN          = 5     -- random suffix length appended to each message
local MOVE_ENABLED        = true  -- whether to follow targets
local SERVER_HOP_ENABLED  = false
local SERVER_HOP_INTERVAL = 30    -- initial wait before attempting server hop (seconds)
local RETRY_TIME          = 5     -- retry teleport every X seconds if it fails

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = cloneref(game:GetService("TextChatService"))

local localPlayer = Players.LocalPlayer

-- chat function using TextChatService
local function sendChat(msg)
    local ok, err = pcall(function()
        if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
            TextChatService.TextChannels.RBXGeneral:SendAsync(msg)
        else
            error("RBXGeneral channel not available")
        end
    end)
    if not ok then
        warn("sendChat failed:", err)
    end
end

-- random suffix generator
local function randomSuffix(len)
    local chars = "abcdefghijklmnopqrstuvwxyz123456789"
    local out = ""
    for i = 1, len do
        local r = math.random(1, #chars)
        out = out .. chars:sub(r, r)
    end
    return out
end

-- movement variables
local hrp = nil
local target = nil
local bangActive = false
local bangAngle = 0
local behindOffset = 2

-- Movement loop: keep local player's HRP behind current target
RunService.RenderStepped:Connect(function(dt)
    if not MOVE_ENABLED or not bangActive or not target then return end
    if not target.Character then return end

    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    bangAngle = bangAngle + dt * 15
    local forwardBack = math.sin(bangAngle) * 1.5
    local behindCF = targetHRP.CFrame * CFrame.new(0, 0, behindOffset + forwardBack)

    if hrp then
        local ok = pcall(function() hrp.CFrame = behindCF end)
        if not ok then bangActive = false end
    end
end)

-- Chat & target cycling: iterates messages in order, cycles players
task.spawn(function()
    local messageIndex = 1
    while true do
        -- get player list snapshot
        local players = Players:GetPlayers()
        -- iterate players
        for _, plr in ipairs(players) do
            if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- set current target & hrp reference
                target = plr
                hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                bangActive = MOVE_ENABLED

                -- build and send the message (cycle messages)
                local baseMessage = MESSAGES[messageIndex] or MESSAGES[1]
                local msg = baseMessage .. " " .. randomSuffix(SUFFIX_LEN)
                sendChat(msg)

                -- advance message index (wrap)
                messageIndex = messageIndex + 1
                if messageIndex > #MESSAGES then
                    messageIndex = 1
                end

                -- wait between messages/targets
                task.wait(MESSAGE_INTERVAL)
            end
        end

        -- small pause if fewer players to avoid tight loop
        task.wait(0.25)
    end
end)

-- Server hop with retries (attempt teleport; if fails retry every RETRY_TIME seconds)
if SERVER_HOP_ENABLED then
    task.spawn(function()
        if RunService:IsStudio() then
            warn("Server hop disabled in Studio")
            return
        end

        -- initial wait before the first hop
        task.wait(SERVER_HOP_INTERVAL)

        while true do
            -- attempt to teleport to the same place (to join another server instance)
            local ok, err = pcall(function()
                TeleportService:Teleport(game.PlaceId, localPlayer)
            end)

            if ok then
                print("Teleport request invoked. Waiting for teleport to occur...")
                -- if teleport was invoked successfully the player will leave; if not, retry below
                task.wait(RETRY_TIME)
            else
                warn("Teleport failed; retrying in " .. tostring(RETRY_TIME) .. "s | error:", tostring(err))
                task.wait(RETRY_TIME)
            end
        end
    end)
end
