local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local antiAFKEnabled = true
local interval = 45 -- segundos entre ações

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AntiAFK_CompleteGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 510)
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
toggleButton.Text = "Anti-AFK: ON"

toggleButton.MouseButton1Click:Connect(function()
	antiAFKEnabled = not antiAFKEnabled
	toggleButton.Text = "Anti-AFK: " .. (antiAFKEnabled and "ON" or "OFF")
end)

-- Simula clique ao ser detectado como inativo
LocalPlayer.Idled:Connect(function()
	if antiAFKEnabled then
		VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		task.wait(0.1)
		VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	end
end)

-- Movimento visível + clique virtual de tempos em tempos
task.spawn(function()
	while true do
		task.wait(interval)

		if antiAFKEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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
