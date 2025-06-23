local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

-- Guarda servidores já testados pra evitar repetição
local triedServers = {}

-- Verifica se estamos no lobby
local function isLobbyServer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr:GetAttribute("Team") ~= "Lobby" then
            return false
        end
    end
    return true
end

-- Pega lista de servidores públicos
local function getServerList()
    local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not res.data then return {} end
    return res.data
end

-- Tenta trocar de servidor
local function hopToNextServer()
    local servers = getServerList()
    for _, srv in ipairs(servers) do
        local id = srv.id
        local players = srv.playing
        if not triedServers[id] and players > 0 and players < srv.maxPlayers then
            triedServers[id] = true
            print("Tentando servidor:", id)
            TeleportService:TeleportToPlaceInstance(PlaceId, id, Players.LocalPlayer)
            return true
        end
    end
    return false
end

-- Loop até encontrar lobby
spawn(function()
    wait(5)  -- aguarda loading completo
    while true do
        if isLobbyServer() then
            print("✅ Servidor no lobby detectado!")
            break
        else
            print("Servidor não é lobby. Fazendo hop...")
            if not hopToNextServer() then
                print("Nenhum servidor válido encontrado. Tentando de novo em 10s.")
                wait(10)
            end
            break
        end
    end
end)
