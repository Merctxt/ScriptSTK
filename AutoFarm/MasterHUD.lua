-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

repeat wait() until Players.LocalPlayer
local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔁 Estado da Automação]
local automacaoAtiva = true
local lootsColetados = {}
local startTime = tick()
local totalFarmed = 0
local numeroRodadas = 0
local valorRodadaAtual = 0

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

-- [🖥️ HUD Inteligente]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 120)
MainFrame.Position = UDim2.new(1, -260, 0, 10)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 1, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.Font = Enum.Font.Code
TextLabel.TextSize = 14
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Text = "Carregando dados..."
TextLabel.Parent = MainFrame

spawn(function()
    while true do
        local tempo = tick() - startTime
        local minutos = math.max(tempo / 60, 0.01)
        local eficiencia = totalFarmed / minutos

        TextLabel.Text = string.format(
            "📊 Rodada: %d\n💸 Atual: %d moedas\n💰 Total: %d moedas\n⏱️ Tempo: %.1f min\n⚙️ Eficiência: %.1f moedas/min",
            numeroRodadas,
            valorRodadaAtual,
            totalFarmed,
            minutos,
            eficiencia
        )
        task.wait(1)
    end
end)

-- [📦 Buscar loots ordenados por valor]
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

-- [🏃‍♂️ Executa o farm da rodada atual]
local function executarFarm()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 10
    local coletados = 0
    local valorRodada = 0

    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            fireproximityprompt(alvo.prompt)
            lootsColetados[alvo.id] = true
            coletados += 1
            valorRodada += alvo.valor
            task.wait(0.8)
        end
    end

    if coletados > 0 then
        valorRodadaAtual = valorRodada
        totalFarmed += valorRodada
        numeroRodadas += 1
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    else
        print("[Auto] Nenhum loot coletado nesta rodada.")
    end
end

-- [✅ Valida se servidor tem players suficientes]
local function verificarServidorValido()
    return #Players:GetPlayers() >= 5
end

-- [🧠 Loop principal da automação]
spawn(function()
    task.wait(10)

    if not verificarServidorValido() then
        print("[Auto] Servidor com poucos jogadores. Pulando...")
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, srv in ipairs(servers) do
            if srv.playing >= 5 and srv.playing < srv.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, srv.id, player)
                return
            end
        end
    end

    print("[Auto] Iniciando farm contínuo neste servidor.")

    while automacaoAtiva do
        local settings = player:FindFirstChild("Settings")
        if settings then settings:SetAttribute("be_the_killer", false) end

        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"
        if not automacaoAtiva then break end

        if player.Team.Name == "Survivor" then
            task.wait(10)
            executarFarm()
        elseif player.Team.Name == "Killer" then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Health = 0 end
            repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
            task.wait(5)
        end

        lootsColetados = {}
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    end
end)
