-- [🟢 Inicialização]
repeat wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- [🔁 Estados globais]
local automacaoAtiva = true
local antiAFKEnabled = true
local lootsColetados = {}
local totalMoedas = 0
local rodadaAtual = 0
local tempoInicio = tick()

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

-- [🎯 HUD Setup]
local function criarHUD()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "AutoFarmHUD"

    local frame = Instance.new("Frame", gui)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Size = UDim2.new(0, 260, 0, 110)
    frame.Position = UDim2.new(0, 20, 0, 510)
    frame.BorderSizePixel = 0

    local titulo = Instance.new("TextLabel", frame)
    titulo.Size = UDim2.new(1, 0, 0, 25)
    titulo.BackgroundTransparency = 1
    titulo.Text = "[ STK - AutoFarm HUD ]"
    titulo.TextColor3 = Color3.fromRGB(0, 255, 0)
    titulo.Font = Enum.Font.SourceSansBold
    titulo.TextSize = 16

    local status = Instance.new("TextLabel", frame)
    status.Name = "Status"
    status.Position = UDim2.new(0, 0, 0, 25)
    status.Size = UDim2.new(1, 0, 0, 85)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.Font = Enum.Font.Code
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Text = ""

    return status
end

local hudStatus = criarHUD()

local function atualizarHUD(moedasRodada)
    local tempo = tick() - tempoInicio
    local minutos = math.max(1, tempo / 60)
    local eficiencia = math.floor(totalMoedas / minutos)

    hudStatus.Text = string.format(
        "Rodada: %d\nRodada Atual: %d moedas\nTotal Farmado: %d moedas\nTempo Total: %02d:%02d\nEficiência: %d moedas/min",
        rodadaAtual,
        moedasRodada or 0,
        totalMoedas,
        math.floor(tempo / 60),
        tempo % 60,
        eficiencia
    )
end

-- [📦 Loots]
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

-- [⚙️ Execução da coleta]
local function executarFarm()
    antiAFKEnabled = false
    local moedasRodada = 0
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local loots = buscarLootsOrdenados()
    local maxColeta = 10
    local coletados = 0

    for _, alvo in ipairs(loots) do
        if not automacaoAtiva or coletados >= maxColeta then break end
        if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
            hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.25)
            fireproximityprompt(alvo.prompt)
            lootsColetados[alvo.id] = true
            print("✅ Coletado:", alvo.nome, "- Valor:", alvo.valor)
            moedasRodada += alvo.valor
            coletados += 1
            task.wait(0.6)
        end
    end

    if coletados > 0 then
        rodadaAtual += 1
        totalMoedas += moedasRodada
        atualizarHUD(moedasRodada)

        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            print("[Auto] Reset feito.")
        end
        task.wait(6)
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    else
        print("[Auto] Nada coletado.")
    end
    antiAFKEnabled = true
end

-- [🔐 Anti-AFK]
player.Idled:Connect(function()
    if antiAFKEnabled then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

task.spawn(function()
    while true do
        task.wait(45)
        if antiAFKEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local original = hrp.CFrame
            hrp.CFrame = original * CFrame.new(0, 0, -1)
            task.wait(0.3)
            hrp.CFrame = original
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end
end)

-- [🧠 Loop Principal]
spawn(function()
    task.wait(10)
    if #Players:GetPlayers() < 5 then
        print("[Auto] Menos de 5 players. Abortando.")
        return
    end

    print("[Auto] Farm contínuo iniciado.")
    atualizarHUD(0)

    while automacaoAtiva do
        -- Garante que 'be_the_killer' esteja desativado
        local settings = player:FindFirstChild("Settings")
        if settings then
            settings:SetAttribute("be_the_killer", false)
        end

        -- Espera mudança de estado
        repeat task.wait(1) until player.Team and player.Team.Name ~= "Lobby"

        if player.Team.Name == "Survivor" then
            print("[Auto] Você é Survivor. Iniciando farm.")
            task.wait(10)
            executarFarm()
        elseif player.Team.Name == "Killer" then
            print("[Auto] Você é Killer. Resetando.")
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Health = 0 end
            repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
        end

        lootsColetados = {}
        print("[Auto] Aguardando próxima partida...")
        repeat task.wait(1) until player.Team and player.Team.Name == "Lobby"
    end
end)
