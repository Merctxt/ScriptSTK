local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

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

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "ESP_GUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 320)
Frame.Position = UDim2.new(0, 50, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local minimize = Instance.new("TextButton", Frame)
minimize.Text = "-"
minimize.Size = UDim2.new(0, 25, 0, 25)
minimize.Position = UDim2.new(1, -30, 0, 5)
minimize.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimize.TextColor3 = Color3.fromRGB(255, 255, 255)

local toggles = {
    Survivors = true,
    Killer = true,
    Lobby = false,
    NameESP = true,
    BoxESP = true,
    ShowLives = true,
    ShowLoots = true,
}

local buttonY = 35
local function createToggle(name, label)
    local btn = Instance.new("TextButton", Frame)
    btn.Name = "Toggle_" .. name
    btn.Text = label .. ": ON"
    btn.Size = UDim2.new(1, -20, 0, 25)
    btn.Position = UDim2.new(0, 10, 0, buttonY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    buttonY = buttonY + 30

    btn.MouseButton1Click:Connect(function()
        toggles[name] = not toggles[name]
        btn.Text = label .. ": " .. (toggles[name] and "ON" or "OFF")
    end)
end

createToggle("Survivors", "ESP Survivors")
createToggle("Killer", "ESP Killer")
createToggle("Lobby", "ESP Lobby")
createToggle("NameESP", "Nome ESP")
createToggle("BoxESP", "Box ESP")
createToggle("ShowLives", "ESP Vidas")
createToggle("ShowLoots", "ESP Loots")

local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in pairs(Frame:GetChildren()) do
        if child:IsA("TextButton") and child ~= minimize then
            child.Visible = not minimized
        end
    end
    Frame.Size = minimized and UDim2.new(0, 220, 0, 35) or UDim2.new(0, 220, 0, buttonY + 10)
end)

local function getTeamInfo(plr)
    local team = plr:GetAttribute("TeamID")
    if not team then return "Lobby", Color3.fromRGB(200, 200, 200) end
    if team == "Killer" then
        return "Killer", Color3.fromRGB(255, 0, 0)
    elseif team == "Survivor" then
        return "Survivor", Color3.fromRGB(0, 170, 255)
    else
        return "Lobby", Color3.fromRGB(180, 180, 180)
    end
end

local function removeESP(plr)
    if plr.Character then
        local head = plr.Character:FindFirstChild("Head")
        if head then
            local old = head:FindFirstChild("ESP_Text")
            if old then old:Destroy() end
        end
        local box = plr.Character:FindFirstChild("ESP_Box")
        if box then box:Destroy() end
    end
end

local function createESP(plr, color)
    if not plr.Character or not plr.Character:FindFirstChild("Head") or plr == LocalPlayer then return end
    local head = plr.Character.Head

    removeESP(plr)

    if toggles.NameESP then
        local gui = Instance.new("BillboardGui", head)
        gui.Name = "ESP_Text"
        gui.Size = UDim2.new(0, 100, 0, 40)
        gui.StudsOffset = Vector3.new(0, 2, 0)
        gui.AlwaysOnTop = true

        local text = Instance.new("TextLabel", gui)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        local lives = toggles.ShowLives and plr:GetAttribute("Lives")
        text.Text = plr.Name .. (lives and (" [" .. tostring(lives) .. "]") or "")
        text.TextColor3 = color
        text.TextStrokeTransparency = 0
        text.TextScaled = true
    end

    if toggles.BoxESP then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_Box"
        box.Adornee = plr.Character
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = plr.Character:GetExtentsSize()
        box.Color3 = color
        box.Transparency = 0.6
        box.Parent = plr.Character
    end
end

RunService.RenderStepped:Connect(function()
    for _, plr in pairs(Players:GetPlayers()) do
        local teamName, color = getTeamInfo(plr)

        local shouldShow =
            (teamName == "Killer" and toggles.Killer)
            or (teamName == "Survivor" and toggles.Survivors)
            or (teamName == "Lobby" and toggles.Lobby)

        if shouldShow then
            createESP(plr, color)
        else
            removeESP(plr)
        end
    end
end)

local function getLootColor(name)
    local val = valoresloots[name] or 2
    if val == 1000 then
        return Color3.fromRGB(0, 0, 0) -- preto
    elseif val == 200 or val == 40 then
        return Color3.fromRGB(255, 255, 0) -- amarelo
    elseif val == 20 then
        return Color3.fromRGB(128, 0, 128) -- roxo
    elseif val == 7 then
        return Color3.fromRGB(255, 0, 0) -- vermelho
    elseif val == 5 then
        return Color3.fromRGB(0, 0, 255) -- azul
    else
        return Color3.fromRGB(255, 255, 255) -- branco
    end
end

local function updateLootESP()
    if not toggles.ShowLoots then
        for _, obj in pairs(workspace:GetChildren()) do
            local lootSpawns = obj:FindFirstChild("LootSpawns")
            if lootSpawns then
                for _, loot in pairs(lootSpawns:GetChildren()) do
                    local esp = loot:FindFirstChild("ESP_Loot")
                    if esp then
                        esp:Destroy()
                    end
                end
            end
        end
        return
    end

    for _, obj in pairs(workspace:GetChildren()) do
        local lootSpawns = obj:FindFirstChild("LootSpawns")
        if lootSpawns then
            for _, loot in pairs(lootSpawns:GetChildren()) do
                if loot:IsA("BasePart") and not loot:FindFirstChild("ESP_Loot") then
                    local lootName = loot:GetAttribute("Loot")
                    if lootName then
                        local gui = Instance.new("BillboardGui", loot)
                        gui.Name = "ESP_Loot"
                        gui.Size = UDim2.new(0, 100, 0, 30)
                        gui.StudsOffset = Vector3.new(0, 2, 0)
                        gui.AlwaysOnTop = true

                        local label = Instance.new("TextLabel", gui)
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = lootName
                        label.TextColor3 = getLootColor(lootName)
                        label.TextStrokeTransparency = 0
                        label.TextScaled = true
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        updateLootESP()
    end
end)
