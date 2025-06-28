-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

repeat wait() until Players.LocalPlayer
local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔄 Controle de Loop]
local triedServers = {}
local automacaoAtiva = true
local lootsColetados = {}

-- [💰 Tabela de valores dos loots]
local valoresloots = {
    old_slycer = 1000, treasure_chest = 200, gold_bars = 40, pendant = 40,
    apocalypse_helmet = 20, golden_compass = 20, golden_pocket_watch = 20,
    trophy = 7, welding_goggles = 7, laptop = 7, smartphone = 7, smartwatch = 7,
    binoculars = 7, pickaxe = 5, car_engine = 5, busted_boombox = 5, tire = 5,
    rusty_pipe = 5, rusty_cleaver = 5, shattered_bottle = 2, shattered_shades = 2,
    green_bottle = 2, gas_can = 2, lighter = 2, broken_bulb = 2,
    broken_bottle = 2, rusty_lantern = 2
}

-- [🔍 Verifica se o servidor está no lobby]
local function isLobbyServer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if not plr.Team or plr.Team.Name ~= "Lobby" then
            return false
        end
    end
    return true
end

-- [🌐 Lista de servidores públicos]
local function getServerList()
    local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not success or not res.data then return {} end
    return res.data
end

-- [⏭️ Troca para outro servidor que esteja no lobby]
local function hopToNextServer()
    local servers = getServerList()
    for _, srv in ipairs(servers) do
        local id = srv.id
        if not triedServers[id] and srv.playing < srv.maxPlayers then
            triedServers[id] = true
            print("[Auto] Tentando servidor:", id)
            TeleportService:TeleportToPlaceInstance(PlaceId, id, player)
            return true
        end
    end
    return false
end

-- [🗺️ Encontra loot spawns no mapa]
local function encontrarMapa()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("LootSpawns") then return obj end
    end
    return nil
end

-- [📦 Busca e ordena os loots disponíveis]
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

-- [🏃‍♂️ Automação de coleta + reset]
local function executarFarm()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 10 -- Limite de coletas por partida
    local coletados = 0
    
    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            fireproximityprompt(alvo.prompt)
            print("✅ Coletado:", alvo.nome, "- Valor:", alvo.valor)
            lootsColetados[alvo.id] = true
            coletados += 1
            task.wait(0.8)
        end
    end

    if coletados > 0 then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0 -- Matar o personagem para resetar
            print("[Auto] Reset feito, voltando ao lobby.")
        else
            print("[Auto] Humanoid não encontrado, não foi possível resetar.")
        end

        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
        print("[Auto] Retorno ao lobby confirmado.")
    else
        print("[Auto] Nenhum item coletado nesta partida. Ignorando reset.")
    end  
end

-- [🧠 LOOP Principal]
spawn(function()
    while automacaoAtiva do
        -- Verifica se estamos no lobby completo
        if not isLobbyServer() then
            print("[Auto] Não está no lobby, pulando servidor...")
            task.wait(15)
            hopToNextServer()
            task.wait(12)
        else
            print("[Auto] Lobby encontrado, aguardando partida...")
            
            local settings = player:FindFirstChild("Settings")
            if settings then
                settings:SetAttribute("be_the_killer", false) -- Garante que não seja o killer
                print("[Auto] Desativado 'be_the_killer'.")
            end

            local tempoEsperando = 0
            local timeoutMaximo = 60 -- Tempo máximo de espera em segundos

            while player.Team and player.Team.Name == "Lobby" and automacaoAtiva do
                task.wait(1)
                tempoEsperando += 1
                if tempoEsperando >= timeoutMaximo then
                    print("[Auto] Timeout atingido, pulando servidor...")
                    task.wait(3)
                    hopToNextServer()
                    task.wait(10)
                    break
                end
            end

            if automacaoAtiva and player.Team and player.Team.Name == "Survivor" then
                print("[Auto] Partida começou como Survivor, executando farm.")
                task.wait(10) -- Pequena pausa para garantir que o jogo esteja pronto
                executarFarm()
                task.wait(10)
                hopToNextServer()
                task.wait(10)
            else
                print("[Auto] Não é Survivor, ignorando partida.")
                task.wait(10)
                hopToNextServer()
                task.wait(10)
            end
        end
    end
end)
