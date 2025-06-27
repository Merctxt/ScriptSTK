local player = game.Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ativo = false
local cooldown = false
local fugindo = false -- flag para evitar múltiplos loops

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0, 20, 0, 100)
btn.Text = "Ativar Proteção"
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.SourceSansBold
btn.TextScaled = true

-- Tabela de valores dos loots (pode ser customizada)
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

local function buscarLootsDisponiveis()
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
    return loots
end

local function getNearestLoot()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local loots = buscarLootsDisponiveis()
    local nearest, minDist = nil, math.huge
    for _, loot in ipairs(loots) do
        local dist = (loot.objeto.Position - hrp.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = loot
        end
    end
    return nearest
end

local function fugirDoKillerLoop()
    if fugindo then return end
    fugindo = true
    task.spawn(function()
        while ativo and player:GetAttribute("InKillerProximity") == true do
            local loot = getNearestLoot()
            if loot then
                local character = player.Character or player.CharacterAdded:Wait()
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = loot.objeto.CFrame + Vector3.new(0, 3, 0)
                    print("✔️ Fugiu para loot:", loot.nome)
                end
            else
                warn("❌ Nenhum loot disponível para fugir!")
            end
            task.wait(0.2)
        end
        fugindo = false
    end)
end

-- Evento de proximidade do killer
player:GetAttributeChangedSignal("InKillerProximity"):Connect(function()
    if ativo and player:GetAttribute("InKillerProximity") == true then
        fugirDoKillerLoop()
    end
end)

-- Botão de ativar/desativar
btn.MouseButton1Click:Connect(function()
    ativo = not ativo
    btn.Text = ativo and "Desativar Proteção" or "Ativar Proteção"
    btn.BackgroundColor3 = ativo and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(255, 50, 50)
end)
