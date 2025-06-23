local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AutoExitGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Auto Exit: ON"

local autoExitEnabled = true

toggleButton.MouseButton1Click:Connect(function()
    autoExitEnabled = not autoExitEnabled
    toggleButton.Text = "Auto Exit: " .. (autoExitEnabled and "ON" or "OFF")
end)

-- Core
local function getCharacter()
    while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
        task.wait()
    end
    return LocalPlayer.Character
end

local function teleportTo(gateway)
    if not autoExitEnabled then return end
    local hrp = getCharacter():FindFirstChild("HumanoidRootPart")
    if hrp then
        local cf = gateway:GetBoundingBox()
        hrp.CFrame = cf + Vector3.new(0, 3, 0)
        print("[AUTOEXIT] TP para:", gateway.Name)
    end
end

local function isGatewayOpen(gateway)
    local val = gateway:GetAttribute("Open") or gateway:GetAttribute("Abrir")
    if type(val) == "boolean" then return val end
    if type(val) == "number" then return val ~= 0 end
    if type(val) == "string" then return val:lower() == "true" or val == "1" end
    return false
end

-- Cache para cancelar conexões antigas
local currentConnections = {}
local currentGateways = {}

-- Monitora 1 gateway
local function monitorGateway(gateway)
    if currentGateways[gateway] then return end
    currentGateways[gateway] = true

    if isGatewayOpen(gateway) then
        teleportTo(gateway)
    end

    local function tryTeleport()
        if isGatewayOpen(gateway) then
            teleportTo(gateway)
        end
    end

    table.insert(currentConnections, gateway:GetAttributeChangedSignal("Open"):Connect(tryTeleport))
    table.insert(currentConnections, gateway:GetAttributeChangedSignal("Abrir"):Connect(tryTeleport))
end

-- Limpa tudo quando o mapa muda
local function resetAll()
    print("[AUTOEXIT] Resetando conexões e gateways antigos")
    for _, conn in pairs(currentConnections) do
        pcall(function() conn:Disconnect() end)
    end
    currentConnections = {}
    currentGateways = {}
end

-- Escaneia novo mapa
local function scan()
    resetAll()

    for _, model in Workspace:GetChildren() do
        if model:IsA("Model") and model:FindFirstChild("Exits") then
            print("[AUTOEXIT] Mapa detectado:", model.Name)
            for _, gateway in model.Exits:GetChildren() do
                if gateway:IsA("Model") and (gateway:GetAttribute("Open") ~= nil or gateway:GetAttribute("Abrir") ~= nil) then
                    monitorGateway(gateway)
                end
            end
        end
    end
end

-- Monitora surgimento de novo mapa
Workspace.ChildAdded:Connect(function(child)
    task.wait(1)
    if child:IsA("Model") and child:FindFirstChild("Exits") then
        print("[AUTOEXIT] Novo mapa carregado:", child.Name)
        scan()
    end
end)

-- Também escaneia o mapa atual ao iniciar
scan()
