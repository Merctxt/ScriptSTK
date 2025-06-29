-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
repeat wait() until player

-- [🔁 Estado]
local automacaoAtiva = true
local lootsColetados = {}
local totalFarmado = 0
local rodadaAtual = 0
local tempoInicial = tick()

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

-- [🎯 HUD Inteligente]
local function criarHUD()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "AutoFarmHUD"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 240, 0, 130)
    frame.Position = UDim2.new(0, 20, 0, 480)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "📊 AutoFarm HUD"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)

    local labels = {}
    for i, nome in ipairs({"Rodada", "Farm Atual", "Total", "Tempo", "Eficiência"}) do
        local lbl = Instance.new("TextLabel", frame)
        lbl.Position = UDim2.new(0, 10, 0, 25 + (i-1)*20)
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 16
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Text = nome .. ": 0"
        labels[nome] = lbl
    end

    return function(farmRodada)
        local tempoAtual = tick() - tempoInicial
        local eficiencia = totalFarmado > 0 and (totalFarmado / (tempoAtual / 60)) or 0

        labels["Rodada"].Text = "Rodada: " .. rodadaAtual
        labels["Farm Atual"].Text = "Farm Atual: " .. farmRodada
        labels["Total"].Text = "Total: " .. totalFarmado
        labels["Tempo"].Text = string.format("Tempo: %.1f min", tempoAtual / 60)
        labels["Eficiência"].Text = string.format("Eficiência: %.1f/moedas/min", eficiencia)
    end
end

local atualizarHUD = criarHUD()

-- [🏃‍♂️ Farm]
local function executarFarm()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 10
    local coletados = 0
    local farmRodada = 0

    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            fireproximityprompt(alvo.prompt)
            lootsColetados[alvo.id] = true
            coletados += 1
            farmRodada += alvo.valor
            print("✅ Coletado:", alvo.nome, "- Valor:", alvo.valor)
            task.wait(0.8)
        end
    end

    totalFarmado += farmRodada
    rodadaAtual += 1
    atualizarHUD(farmRodada)

    if coletados > 0 then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    end
end

-- [🛡️ Anti-AFK]
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

-- [📡 Verifica servidor válido]
local function verificarServidorValido()
    return #Players:GetPlayers() >= 5
end

-- [🧠 Loop Principal]
spawn(function()
    task.wait(10)

    if not verificarServidorValido() then
        print("[Auto] Poucos jogadores. Procurando servidor...")
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, srv in ipairs(servers) do
            if srv.playing >= 5 and srv.playing < srv.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
                return
            end
        end
    end

    while automacaoAtiva do
        local settings = player:FindFirstChild("Settings")
        if settings then
            settings:SetAttribute("be_the_killer", false)
        end

        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"

        if not automacaoAtiva then break end

        if player.Team.Name == "Survivor" then
            print("[Auto] Coletando como Survivor.")
            task.wait(10)
            executarFarm()
        elseif player.Team.Name == "Killer" then
            print("[Auto] Resetando como Killer.")
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Health = 0 end
            repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
            task.wait(5)
        end

        lootsColetados = {}
        print("[Auto] Aguardando próxima rodada...")
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    end
end)
