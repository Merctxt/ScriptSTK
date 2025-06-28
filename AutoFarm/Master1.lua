-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

repeat wait() until Players.LocalPlayer
local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔁 Estado]
local automacaoAtiva = true
local lootsColetados = {}

-- [💰 Valores dos loots]
local valoresloots = {
    old_slycer = 1000, treasure_chest = 200, gold_bars = 40, pendant = 40,
    apocalypse_helmet = 20, golden_compass = 20, golden_pocket_watch = 20,
    trophy = 7, welding_goggles = 7, laptop = 7, smartphone = 7, smartwatch = 7,
    binoculars = 7, pickaxe = 5, car_engine = 5, busted_boombox = 5, tire = 5,
    rusty_pipe = 5, rusty_cleaver = 5, shattered_bottle = 2, shattered_shades = 2,
    green_bottle = 2, gas_can = 2, lighter = 2, broken_bulb = 2,
    broken_bottle = 2, rusty_lantern = 2
}

-- [📦 Busca loots ordenados por valor]
local function encontrarMapa()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("LootSpawns") then return obj end
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
        local lootName = loot:GetAttribute("Loot")
        if lootName and not lootsColetados[loot.Name] then
            local valor = valoresloots[lootName] or 0
            local prompt = loot:FindFirstChild("LootProxBlock") and loot.LootProxBlock:FindFirstChild("LootProximityPrompt")
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

    table.sort(loots, function(a, b) return a.valor > b.valor end)
    return loots
end

-- [🧹 Coleta os loots e reseta]
local function executarFarm()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 10 -- Limite de coletas por rodada
    local coletados = 0

    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            fireproximityprompt(alvo.prompt)
            lootsColetados[alvo.id] = true
            print("✅ Coletado:", alvo.nome, "- Valor:", alvo.valor)
            coletados += 1
            task.wait(0.8)
        end
    end

    if coletados > 0 then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            print("[Auto] Reset feito. Aguardando retorno ao lobby.")
        else
            print("[Auto] Humanoid não encontrado, não foi possível resetar.")
        end

        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"  
    else
        print("[Auto] Nenhum loot coletado nesta rodada.")    
    end
end

-- [🌐 Verifica se servidor tem pelo menos 5 players]
local function verificarServidorValido()
    return #Players:GetPlayers() >= 5
end

-- [🧠 Loop Principal]
spawn(function()
    task.wait(10) -- Espera inicial pra garantir que tudo carregou

    if not verificarServidorValido() then
        print("[Auto] Servidor com poucos jogadores. Pulando...")
        local servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, srv in ipairs(servers) do
            if srv.playing >= 5 and srv.playing < srv.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, srv.id, player)
                return
            end
        end
    end

    print("[Auto] Iniciando farm contínuo neste servidor.")
    while automacaoAtiva do
        -- Garante que 'be_the_killer' esteja falso
        local settings = player:FindFirstChild("Settings")
        if settings then
            settings:SetAttribute("be_the_killer", false)
        end

        -- Aguardar mudar de lobby para survivor/killer
        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"

        if not automacaoAtiva then break end

        if player.Team.Name == "Survivor" then
            print("[Auto] Você é Survivor. Executando coleta.")
            task.wait(10)
            executarFarm()
        elseif player.Team.Name == "Killer" then
            print("[Auto] Você é Killer. Resetando para próxima rodada.")
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Health = 0 end
            repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
            task.wait(5)
        end

        -- Reset estado para próxima partida
        lootsColetados = {}
        print("[Auto] Aguardando próxima rodada...")
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    end
end)
