-- GUI Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "ESP_GUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 240)
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

-- Minimizar
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

-- ESP Functions
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
        text.Text = plr.Name
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

-- Loop de atualização
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
