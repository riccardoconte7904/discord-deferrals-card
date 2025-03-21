-- preloading the card json string
local CardJson = json.encode(CardTemplate)

-- function for showing the card, waits until the action button is clicked
local function showDiscordCard(def)
    Wait(0); local p = promise.new()
    def.presentCard(CardJson, function(_data, _rawData) return p:resolve('ok') end)

    return Citizen.Await(p)
end

-- function where the api call happens
local function checkDiscordPresence(user_id)
    Wait(0); local p = promise.new()
    PerformHttpRequest(("https://discord.com/api/guilds/%s/members/%s"):format(GUILD_ID, user_id),
        function(response_code) return p:resolve(tostring(response_code) or 'false'); end, 'GET', '',
        {["Content-Type"] = "application/json", ["Authorization"] = TOKEN}
    )

    local resp = Citizen.Await(p)
    return resp == '200'
end

-- function where the actual checking happens, based on the api call
-- repeats until the api returns true (status code 200).
local function updateDeferrals(def, uid)
    local isInDiscord = false

    repeat
        def.update("🔎 We're checking your presence on our Discord server...")
        Wait(1500) -- Can be edited if you want the text to stay for more/less time

        isInDiscord = checkDiscordPresence(uid)

        if isInDiscord == false then
            showDiscordCard(def)
        end
    until isInDiscord

    Wait(0); return def.done()
end

-- main event
AddEventHandler("playerConnecting", function(name, setKickReason, def)
    local player = source
    local discordId
    local identifiers = GetPlayerIdentifiers(player)

    def.defer()
    Wait(0) -- mandatory wait, idk why

    for _, v in pairs(identifiers) do
        if string.find(v, "discord") then
            discordId = v
            break
        end
    end

    if not discordId then
        def.done("Seems like you didn't link a Discord account to FiveM. Try linking your account and restart the game!")
        return
    end

    updateDeferrals(def, discordId)
end)