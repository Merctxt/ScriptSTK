-- GUI Unificada GVNX
local MainGui = Instance.new("ScreenGui", game.CoreGui)
MainGui.Name = "GVNX_UnifiedGUI"

local MainFrame = Instance.new("Frame", MainGui)
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -60, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "GVNX Universal GUI"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 16
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = UDim2.new(0, 40, 1, -4)
MinimizeBtn.Position = UDim2.new(1, -42, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -40)
ContentFrame.Position = UDim2.new(0, 10, 0, 35)
ContentFrame.BackgroundTransparency = 1

local toggles = {
    {var = "AntiAFK", label = "Anti-AFK", color = Color3.fromRGB(50, 150, 50)},
    {var = "AutoLoot", label = "Auto Loot", color = Color3.fromRGB(150, 50, 150)},
    {var = "AutoExit", label = "Auto Exit", color = Color3.fromRGB(50, 50, 150)},
    {var = "AutoSave", label = "Auto Save", color = Color3.fromRGB(150, 150, 50)},
    {var = "DoubleJump", label = "Double Jump", color = Color3.fromRGB(50, 150, 150)}
}

_G.AntiAFK = true
_G.AutoLoot = false
_G.AutoExit = true
_G.AutoSave = true
_G.DoubleJump = true

local yOffset = 0
for _, t in ipairs(toggles) do
    local btn = Instance.new("TextButton", ContentFrame)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, yOffset)
    btn.BackgroundColor3 = t.color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Text = t.label .. ": " .. (_G[t.var] and "ON" or "OFF")
    btn.MouseButton1Click:Connect(function()
        _G[t.var] = not _G[t.var]
        btn.Text = t.label .. ": " .. (_G[t.var] and "ON" or "OFF")
        btn.BackgroundColor3 = _G[t.var] and t.color or Color3.fromRGB(40, 40, 40)
    end)
    yOffset = yOffset + 40
end

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 260, 0, 30) or UDim2.new(0, 260, 0, 320)
end)

-- Anti-AFK Script
-- This script prevents the player from being kicked for inactivity by simulating movement and clicks.

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local interval = 45 -- segundos entre ações

-- Simula clique ao ser detectado como inativo
LocalPlayer.Idled:Connect(function()
	if _G.AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		task.wait(0.1)
		VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	end
end)

-- Movimento visível + clique virtual de tempos em tempos
task.spawn(function()
	while true do
		task.wait(interval)
		if _G.AntiAFK and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local original = hrp.CFrame
			-- Movimento leve visível
			hrp.CFrame = original * CFrame.new(0, 0, -1)
			task.wait(0.3)
			hrp.CFrame = original
			-- Extra: simulação de clique para garantir
			VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end
	end
end)

-- Auto Loot Script
-- This script automatically collects items dropped by players in the game.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
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

task.spawn(function()
    while true do
        if _G.AutoLoot then
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

-- Auto Exit Script
-- This script automatically exits the game when the player clicks a button in the GUI.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function getCharacter()
    while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
        task.wait()
    end
    return LocalPlayer.Character
end

local function teleportTo(gateway)
    if not _G.AutoExit then return end
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

local currentConnections = {}
local currentGateways = {}

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

local function resetAll()
    print("[AUTOEXIT] Resetando conexões e gateways antigos")
    for _, conn in pairs(currentConnections) do
        pcall(function() conn:Disconnect() end)
    end
    currentConnections = {}
    currentGateways = {}
end

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

Workspace.ChildAdded:Connect(function(child)
    task.wait(1)
    if child:IsA("Model") and child:FindFirstChild("Exits") then
        print("[AUTOEXIT] Novo mapa carregado:", child.Name)
        scan()
    end
end)

scan()

-- Auto Save Script
-- This script automatically saves the player's lives in the round.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local rescueDelay = 1.5 -- tempo de espera antes de salvar

local function isPlayerDowned(plr)
	local success, result = pcall(function()
		return plr:GetAttribute("Downed") or plr:GetAttribute("Crawling")
	end)
	return success and result == true
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if _G.AutoSave and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					if isPlayerDowned(plr) then
						local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
						local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						task.wait(rescueDelay)
						if isPlayerDowned(plr) and _G.AutoSave and targetHRP and myHRP then
							myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)
							while isPlayerDowned(plr) and _G.AutoSave do
								task.wait(0.2)
								if targetHRP and myHRP then
									myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)
								else
									break
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- Double Jump Script
-- This script allows the player to perform a double jump in the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local frontFlipAnim = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("front_flip")
local canDoubleJump = false
local hasDoubleJumped = false

local function getHumanoid()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

local function doDoubleJump()
	if not _G.DoubleJump then return end
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		if animator and frontFlipAnim then
			local track = animator:LoadAnimation(frontFlipAnim)
			track:Play()
		end
	end
end

local function setupDoubleJump()
	local humanoid = getHumanoid()
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Freefall then
			canDoubleJump = true
		elseif newState == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			hasDoubleJumped = false
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	setupDoubleJump()
end)
setupDoubleJump()

UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode == Enum.KeyCode.Space then
		local humanoid = getHumanoid()
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall and canDoubleJump and not hasDoubleJumped then
			hasDoubleJumped = true
			doDoubleJump()
		end
	end
end)
