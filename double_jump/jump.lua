local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Referência à animação original
local frontFlipAnim = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("front_flip")

-- Estado do pulo duplo
local doubleJumpEnabled = true
local canDoubleJump = false
local hasDoubleJumped = false

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

-- Função para pegar Humanoid
local function getHumanoid()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

-- Função para executar o pulo duplo
local function doDoubleJump()
	if not doubleJumpEnabled then return end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

	if humanoid then
		-- Pulo nativo (altura igual ao do jogo)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		-- Tocar animação original
		if animator and frontFlipAnim then
			local track = animator:LoadAnimation(frontFlipAnim)
			track:Play()
		end
	end
end

-- Configura os eventos de estado para controlar o segundo pulo
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

-- Reaplica quando o personagem renasce
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1) -- garante que humanoid e animator carregaram
	setupDoubleJump()
end)

-- Aplica inicialmente
setupDoubleJump()

-- Entrada do teclado para acionar o segundo pulo
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
