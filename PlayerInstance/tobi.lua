-- Script de automação total para STK
-- Tudo em um único arquivo!

-- Serviços Roblox
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

-- =====================
-- Funções de Player.lua
-- =====================
local triedServers = {}

local function isLobbyServer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr:GetAttribute("Team") ~= "Lobby" then
            return false
        end
    end
    return true
end

local function getServerList()
    local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not res.data then return {} end
    return res.data
end

local function hopToNextServer()
    local servers = getServerList()
    for _, srv in ipairs(servers) do
        local id = srv.id
        local players = srv.playing
        if not triedServers[id] and players > 0 and players < srv.maxPlayers then
            triedServers[id] = true
            print("[tobi] Tentando servidor:", id)
            TeleportService:TeleportToPlaceInstance(PlaceId, id, LocalPlayer)
            return true
        end
    end
    return false
end

-- Aguarda todos os jogadores ficarem no lobby
local function aguardarLobby()
    while not isLobbyServer() do
        print("[tobi] Não está no lobby, fazendo hoop...")
        hopToNextServer()
        wait(10)
    end
    print("[tobi] Servidor no lobby!")
end

-- Aguarda início da partida (status Survivor)
local function aguardarPartida()
    print("[tobi] Aguardando início da partida...")
    while LocalPlayer:GetAttribute("Team") == "Lobby" do
        wait(1)
    end
    print("[tobi] Partida começou!")
end

-- =====================
-- Funções de Loot.lua
-- =====================
local ativo = false
local valoresloots = {
    old_slycer = 1000,
    treasure_chest = 200,
    gold_bars = 40,
    pendant = 40,
    apocalypse_helmet = 20,
    golden_compass = 20,
    golden_pocket_watch = 20,
    trophy = 7,
    welding_goggles = 7,
    laptop = 7,
    smartphone = 7,
    smartwatch = 7,
    binoculars = 7,
    pickaxe = 5,
    car_engine = 5,
    busted_boombox = 5,
    tire = 5,
    rusty_pipe = 5,
    rusty_cleaver = 5,
    shattered_bottle = 2,
    shattered_shades = 2,
    green_bottle = 2,
    gas_can = 2,
    lighter = 2,
    broken_bulb = 2,
    broken_bottle = 2,
    rusty_lantern = 2,
}

local lootsColetados = {}

local function encontrarMapa()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("LootSpawns") then
            return obj
        end
    end
    return nil
end

local function buscarLootsOrdenados()
    local mapa = encontrarMapa()
    if not mapa then return {} end
    local lootSpawns = mapa:FindFirstChild("LootSpawns")
    if not lootSpawns then return {} end
    local loots = {}
    for _, loot in ipairs(lootSpawns:GetChildren()) do
        if not lootsColetados[loot.Name] then
            local lootName = loot:GetAttribute("Loot")
            if lootName then
                local valor = valoresloots[lootName] or 0
                local proxBlock = loot:FindFirstChild("LootProxBlock")
                local prompt = proxBlock and proxBlock:FindFirstChild("LootProximityPrompt")
                if prompt and prompt.Enabled then
                    table.insert(loots, {
                        objeto = loot,
                        prompt = prompt,
                        valor = valor,
                        nome = lootName,
                        id = loot.Name
                    })
                end
            end
        end
    end
    table.sort(loots, function(a, b)
        return a.valor > b.valor
    end)
    return loots
end

local function contarLootsColetados()
    local count = 0
    for _, _ in pairs(lootsColetados) do
        count = count + 1
    end
    return count
end

local function autoLoot()
    ativo = true
    print("[tobi] AutoLoot ativado!")
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local loots = buscarLootsOrdenados()
    for _, alvo in ipairs(loots) do
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.15)
            fireproximityprompt(alvo.prompt)
            print("[tobi] Coletado:", alvo.nome, "- Valor:", alvo.valor)
            lootsColetados[alvo.id] = true
            task.wait(1)
        end
    end
    ativo = false
end

-- Faz auto reset (método simples)
local function autoReset()
    print("[tobi] Resetando personagem...")
    LocalPlayer.Character:BreakJoints()
end

-- =====================
-- Loop principal
-- =====================
while true do
    aguardarLobby()
    aguardarPartida()
    autoLoot()
    wait(2) -- Pequeno delay pós-loot
    autoReset()
    wait(5) -- Aguarda voltar ao lobby
    hopToNextServer()
    wait(10)
end
