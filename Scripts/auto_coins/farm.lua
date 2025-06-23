local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
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

-- Interface
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false
gui.Name = "AutoLootGUI"

local botao = Instance.new("TextButton")
botao.Size = UDim2.new(0, 120, 0, 40)
botao.Position = UDim2.new(0, 20, 0, 100)
botao.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
botao.TextColor3 = Color3.fromRGB(255, 255, 255)
botao.Text = "Ativar AutoLoot"
botao.Font = Enum.Font.GothamBold
botao.TextSize = 14
botao.Parent = gui
botao.BorderSizePixel = 0
botao.BackgroundTransparency = 0.1

-- Alterna ativação
botao.MouseButton1Click:Connect(function()
    ativo = not ativo
    botao.Text = ativo and "Desativar AutoLoot" or "Ativar AutoLoot"
    botao.BackgroundColor3 = ativo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(20, 20, 20)
end)

-- Busca loot
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

-- Loop de coleta com controle da GUI
task.spawn(function()
    while true do
        if ativo then
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local loots = buscarLootsOrdenados()

                for _, alvo in ipairs(loots) do
                    if not lootsColetados[alvo.id] and alvo.prompt and alvo.prompt.Enabled then
                        hrp.CFrame = alvo.objeto.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.15)
                        fireproximityprompt(alvo.prompt)
                        print("✅ Coletado:", alvo.nome, "- Valor:", alvo.valor)
                        lootsColetados[alvo.id] = true
                        break
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
