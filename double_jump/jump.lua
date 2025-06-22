local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variáveis de controle
local canDoubleJump = false
local hasDoubleJumped = false
local doubleJumpEnabled = true

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "DoubleJumpGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 270)
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
toggleButton.Text = "Double Jump: ON"

toggleButton.MouseButton1Click:Connect(function()
	doubleJumpEnabled = not doubleJumpEnabled
	toggleButton.Text = "Double Jump: " .. (doubleJumpEnabled and "ON" or "OFF")
end)

-- Função pra pegar o Humanoid
local function getHumanoid()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

-- Força do segundo pulo
local function doDoubleJump()
	if not doubleJumpEnabled then return end

	local humanoid = getHumanoid()
	local hrp = humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
	end
end

-- Entrada de tecla
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode == Enum.KeyCode.Space then
		local humanoid = getHumanoid()
		local state = humanoid:GetState()

		if state == Enum.HumanoidStateType.Freefall and canDoubleJump and not hasDoubleJumped then
			hasDoubleJumped = true
			doDoubleJump()
		end
	end
end)

-- Monitora estado do Humanoid
getHumanoid().StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Freefall then
		canDoubleJump = true
	elseif newState == Enum.HumanoidStateType.Landed then
		canDoubleJump = false
		hasDoubleJumped = false
	end
end)
