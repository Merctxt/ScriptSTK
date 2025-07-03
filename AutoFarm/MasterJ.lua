-- [🟢 Carregamento Inicial]
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

repeat wait() until Players.LocalPlayer
local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔁 Estado da Automação]
local automacaoAtiva = true
local lootsColetados = {}
local startTime = tick()
local numeroRodadas = 0
local valorRodadaAtual = 0
local totalInstancia = 0
local coinsInicial = player:GetAttribute("Coins") or 0

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

local function formatK(n)
	if n >= 1000 then
		return string.format("%.1fk", n / 1000)
	else
		return tostring(n)
	end
end

-- [📦 Dados locais que serão salvos]
local data = {
    TotalGanho = 0,
    monthlyGoal = 100000,
    dailyGains = {}, -- novo campo para ganhos diários
}

local function getToday()
    return os.date("%Y-%m-%d")
end

local function getDailyGoal()
    return math.floor(data.monthlyGoal / 30)
end

-- [🛠 JSON local]
local function salvarDados()
    if writefile then
        writefile("farm_data.json", HttpService:JSONEncode(data))
    end
end

local function carregarDados()
    if isfile and isfile("farm_data.json") then
        local ok, conteudo = pcall(function()
            return HttpService:JSONDecode(readfile("farm_data.json"))
        end)
        if ok and type(conteudo) == "table" then
            data = conteudo
            -- Garante que dailyGains sempre exista
            if type(data.dailyGains) ~= "table" then
                data.dailyGains = {}
            end
        end
    end
end

carregarDados()

-- [🖥️ HUD + Inputs]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "FarmHUD"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(1, -310, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- mais escuro
MainFrame.BackgroundTransparency = 0.15 -- menos transparente
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

-- Arredondar cantos
local corner = Instance.new("UICorner", MainFrame)
corner.CornerRadius = UDim.new(0, 12)

-- Botão de minimizar
local minimizeButton = Instance.new("TextButton", MainFrame)
minimizeButton.Size = UDim2.new(0, 28, 0, 28)
minimizeButton.Position = UDim2.new(1, -32, 0, 4)
minimizeButton.Text = "_"
minimizeButton.TextColor3 = Color3.new(1,1,1)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.BackgroundTransparency = 0.2
minimizeButton.Font = Enum.Font.Code
minimizeButton.TextSize = 20
local minCorner = Instance.new("UICorner", minimizeButton)
minCorner.CornerRadius = UDim.new(0, 8)

local TextLabel = Instance.new("TextLabel", MainFrame)
TextLabel.Size = UDim2.new(1, -10, 1, -60)
TextLabel.Position = UDim2.new(0, 5, 0, 5)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.Font = Enum.Font.Code
TextLabel.TextSize = 14
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Text = "Iniciando..."

local goalBox = Instance.new("TextBox", MainFrame)
goalBox.Size = UDim2.new(0, 140, 0, 25)
goalBox.Position = UDim2.new(0, 10, 1, -30)
goalBox.PlaceholderText = "Alterar meta"
goalBox.Text = tostring(data.monthlyGoal)
goalBox.ClearTextOnFocus = false
goalBox.TextColor3 = Color3.new(1,1,1)
goalBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
goalBox.Font = Enum.Font.Code
goalBox.TextSize = 14

goalBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local v = tonumber(goalBox.Text)
        if v and v > 0 then
            data.monthlyGoal = v
            salvarDados()
        end
    end
end)

local resetButton = Instance.new("TextButton", MainFrame)
resetButton.Size = UDim2.new(0, 130, 0, 25)
resetButton.Position = UDim2.new(0, 160, 1, -30)
resetButton.Text = "Zerar Dados"
resetButton.TextColor3 = Color3.new(1,1,1)
resetButton.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
resetButton.Font = Enum.Font.Code
resetButton.TextSize = 14

resetButton.MouseButton1Click:Connect(function()
    data.TotalGanho = 0
    data.monthlyGoal = 100000
    goalBox.Text = tostring(data.monthlyGoal)
    salvarDados()
end)

-- Novo campo para mostrar meta diária e ganhos do dia
local dailyLabel = Instance.new("TextLabel", MainFrame)
dailyLabel.Size = UDim2.new(1, -10, 0, 20)
dailyLabel.Position = UDim2.new(0, 5, 1, -55)
dailyLabel.BackgroundTransparency = 1
dailyLabel.TextColor3 = Color3.new(1, 1, 1)
dailyLabel.Font = Enum.Font.Code
dailyLabel.TextSize = 14
dailyLabel.TextXAlignment = Enum.TextXAlignment.Left
dailyLabel.TextYAlignment = Enum.TextYAlignment.Top
dailyLabel.Text = ""

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child ~= minimizeButton and (child:IsA("TextLabel") or child:IsA("TextBox") or (child:IsA("TextButton") and child ~= minimizeButton)) then
            child.Visible = not minimized
        end
    end
    if minimized then
        MainFrame.Size = UDim2.new(0, 60, 0, 36)
    else
        MainFrame.Size = UDim2.new(0, 300, 0, 160)
    end
end)

-- [⏱️ Atualizador HUD]
local function atualizarHUD()
    local tempo = tick() - startTime
    local minutos = math.max(tempo / 60, 0.01)
    local eficiencia = totalInstancia / minutos
    local perc = math.clamp((data.TotalGanho / data.monthlyGoal) * 100, 0, 9999)
    local today = getToday()
    local dailyGain = (type(data.dailyGains) == "table" and data.dailyGains[today]) or 0
    local dailyGoal = getDailyGoal()
    dailyLabel.Text = string.format("📆 Hoje: %s/%s", formatK(dailyGain), formatK(dailyGoal))
    TextLabel.Text = string.format(
        "📊 Rodada: %d\n💸 Atual: %d moedas\n💰 Total: %d moedas\n📅 Meta: %s/%s - 🚨%.2f%% da meta\n\n⏱️ Tempo: %.1f min\n⚙️ Eficiência: %.1f moedas/min",
        numeroRodadas,
        valorRodadaAtual,
        totalInstancia,
        formatK(data.TotalGanho),
        formatK(data.monthlyGoal),
        perc,
        minutos,
        eficiencia
    )
end

task.spawn(function()
    while true do
        atualizarHUD()
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
    local coinsAntes = player:GetAttribute("Coins") or 0

    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            fireproximityprompt(alvo.prompt)
            lootsColetados[alvo.id] = true
            coletados += 1
            print(string.format("✅ Coletado: %s - Valor: %d", alvo.nome, alvo.valor))
            task.wait(1)
        end
    end

    task.wait(5)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
    task.wait(6)
    repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"

    -- Aguarda o jogador voltar ao lobby
    task.wait(5)
    local coinsDepois = player:GetAttribute("Coins") or coinsAntes
    local ganhoReal = math.max(coinsDepois - coinsAntes, 0)
    valorRodadaAtual = ganhoReal
    totalInstancia = totalInstancia + ganhoReal
    if coletados > 0 or ganhoReal > 0 then
        data.TotalGanho = coinsDepois -- agora sempre igual ao valor atual de moedas
        -- Atualiza ganho do dia
        local today = getToday()
        data.dailyGains[today] = (data.dailyGains[today] or 0) + ganhoReal
        numeroRodadas += 1
        salvarDados()
        print(string.format("[Auto] Rodada %d finalizada com %d moedas! (Real)", numeroRodadas, ganhoReal))
    else
        print("[Auto] Nenhum loot coletado nesta rodada.")
    end
    atualizarHUD()
end

-- [🧠 Loop principal da automação]
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

    print("[Auto] Iniciando farm contínuo neste servidor.")

    while automacaoAtiva do
        local settings = player:FindFirstChild("Settings")
        if settings then settings:SetAttribute("be_the_killer", false) end

        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"
        if not automacaoAtiva then break end

        if player.Team.Name == "Survivor" then
            print("[Auto] Você é Survivor. Executando farm...")
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

-- [🛡️ Anti-AFK integrado]
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Movimento leve periódico para evitar kick
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
