-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

repeat wait() until Players.LocalPlayer
local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔁 Estado da Automacao]
local automacaoAtiva = true
local lootsColetados = {}
local startTime = tick()
local totalFarmed = 0
local numeroRodadas = 0
local valorRodadaAtual = 0

-- [🔗 API Config]
local baseUrl = "https://51ad86cc-37e1-423f-9579-a9285c931f75-00-1tidytvo3z579.worf.replit.dev/player_data/" -- ALTERE para seu endpoint
local userId = tostring(player.UserId)

local playerData = {
    user_id = userId,
    total_farmed = 0,
    monthly_goal = 100000
}

-- [📡 Buscar ou Criar Dados Remotos]
do
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(baseUrl .. userId))
    end)
    if success and response then
        playerData = response
        totalFarmed = response.total_farmed or 0
    else
        local payload = HttpService:JSONEncode({ user_id = userId, total_farmed = 0, monthly_goal = 100000 })
        pcall(function()
            game:HttpPost(baseUrl, payload, Enum.HttpContentType.ApplicationJson)
        end)
    end
end

-- [💰 Tabela de valores dos loots]
local valoresloots = { old_slycer = 1000, treasure_chest = 200, gold_bars = 40, pendant = 40, apocalypse_helmet = 20, golden_compass = 20,
    golden_pocket_watch = 20, trophy = 7, welding_goggles = 7, laptop = 7, smartphone = 7, smartwatch = 7, binoculars = 7, pickaxe = 5,
    car_engine = 5, busted_boombox = 5, tire = 5, rusty_pipe = 5, rusty_cleaver = 5, shattered_bottle = 2, shattered_shades = 2,
    green_bottle = 2, gas_can = 2, lighter = 2, broken_bulb = 2, broken_bottle = 2, rusty_lantern = 2
}

-- [🖥️ HUD Inteligente]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "FarmHUD"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 270, 0, 150)
MainFrame.Position = UDim2.new(1, -280, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local TextLabel = Instance.new("TextLabel", MainFrame)
TextLabel.Size = UDim2.new(1, -10, 0, 100)
TextLabel.Position = UDim2.new(0, 5, 0, 5)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.Font = Enum.Font.Code
TextLabel.TextSize = 14
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Text = "⏳ Carregando..."

local GoalBox = Instance.new("TextBox", MainFrame)
GoalBox.Size = UDim2.new(1, -10, 0, 20)
GoalBox.Position = UDim2.new(0, 5, 0, 110)
GoalBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
GoalBox.TextColor3 = Color3.new(1,1,1)
GoalBox.PlaceholderText = "Nova meta mensal..."
GoalBox.Text = ""
GoalBox.Font = Enum.Font.Code
GoalBox.TextSize = 14

GoalBox.FocusLost:Connect(function(enter)
    if enter then
        local novoValor = tonumber(GoalBox.Text)
        if novoValor and novoValor >= 0 then
            playerData.monthly_goal = novoValor
            local payload = HttpService:JSONEncode({ total_farmed = playerData.total_farmed, monthly_goal = novoValor })
            pcall(function()
                game:HttpPost(baseUrl .. userId, payload, Enum.HttpContentType.ApplicationJson, true)
            end)
        end
    end
end)

-- [⏱️ Atualizador HUD]
task.spawn(function()
    while true do
        local tempo = tick() - startTime
        local minutos = math.max(tempo / 60, 0.01)
        local eficiencia = totalFarmed / minutos
        TextLabel.Text = string.format(
            "📊 Rodada: %d\n💸 Atual: %d moedas\n💰 Total: %d moedas\n📅 Farmado/Mês: %.1fk/%.1fk\n⏱️ Tempo: %.1f min\n⚙️ Eficiência: %.1f moedas/min",
            numeroRodadas, valorRodadaAtual, totalFarmed,
            totalFarmed/1000, (playerData.monthly_goal or 100000)/1000,
            minutos, eficiencia
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

-- [🏃 Farm automático]
local function executarFarm()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 8
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
            print(string.format("✅ Coletado: %s - Valor: %d", alvo.nome, alvo.valor))
            task.wait(1)
        end
    end

    task.wait(5)
    if coletados > 0 then
        valorRodadaAtual = valorRodada
        totalFarmed += valorRodada
        numeroRodadas += 1
        playerData.total_farmed = totalFarmed
        print(string.format("[Auto] Rodada %d finalizada com %d moedas!", numeroRodadas, valorRodada))
        local payload = HttpService:JSONEncode({ total_farmed = totalFarmed, monthly_goal = playerData.monthly_goal })
        pcall(function()
            game:HttpPost(baseUrl .. userId, payload, Enum.HttpContentType.ApplicationJson, true)
        end)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    else
        print("[Auto] Nenhum loot coletado nesta rodada.")
    end
end

-- [🔁 Loop principal]
spawn(function()
    task.wait(10)
    if #Players:GetPlayers() < 5 then
        print("[Auto] Servidor com poucos jogadores. Pulando...")
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, srv in ipairs(servers) do
            if srv.playing >= 5 and srv.playing < srv.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, srv.id, player)
                return
            end
        end
    end
    print("[Auto] Iniciando farm neste servidor.")
    while automacaoAtiva do
        local settings = player:FindFirstChild("Settings")
        if settings then settings:SetAttribute("be_the_killer", false) end
        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"
        if not automacaoAtiva then break end
        if player.Team.Name == "Survivor" then
            print("[Auto] Você é Survivor. Farmando...")
            task.wait(10)
            executarFarm()
        elseif player.Team.Name == "Killer" then
            print("[Auto] Você é Killer. Resetando...")
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

-- [🛡️ Anti-AFK]
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- [👣 Movimento anti-kick]
task.spawn(function()
    while automacaoAtiva do
        task.wait(45)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local original = hrp.CFrame
            hrp.CFrame = original * CFrame.new(0, 0, -1)
            task.wait(0.3)
            hrp.CFrame = original
        end
    end
end)
