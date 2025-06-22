local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local autoSaveEnabled = true
local rescueDelay = 1.5 -- tempo de espera antes de salvar

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AutoSaveGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 330)
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
toggleButton.Text = "Auto Save: ON"

toggleButton.MouseButton1Click:Connect(function()
	autoSaveEnabled = not autoSaveEnabled
	toggleButton.Text = "Auto Save: " .. (autoSaveEnabled and "ON" or "OFF")
end)

-- Checa se o jogador está caído
local function isPlayerDowned(plr)
	local success, result = pcall(function()
		return plr:GetAttribute("Downed") or plr:GetAttribute("Crawling")
	end)
	return success and result == true
end

-- Script principal de auto save
task.spawn(function()
	while true do
		task.wait(0.5)

		if autoSaveEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					if isPlayerDowned(plr) then
						local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
						local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

						-- Espera pra não colar no killer
						task.wait(rescueDelay)

						-- Verifica se ainda precisa ser salvo
						if isPlayerDowned(plr) and autoSaveEnabled and targetHRP and myHRP then
							myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)

							while isPlayerDowned(plr) and autoSaveEnabled do
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
