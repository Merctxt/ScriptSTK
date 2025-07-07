local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local knivesGUI = player.PlayerGui.Menus.Inventory.Content.Knives
local knivesStorage = ReplicatedStorage.Assets.Game.Knives

local selectedButton = nil

-- C0 baseado na faca legítima
local legitC0 = CFrame.new(0.004, -0.115, 0.342) * CFrame.new(0, 0, 0,
    -0.044831, 0.641232, 0.766036,
    -0.053403, 0.764172, -0.642798,
    -0.997566, -0.069726, -0.000014)

-- Equipa faca spoofada corretamente nas costas
local function equiparNasCostas(itemName)
	local knifeModel = knivesStorage:FindFirstChild(itemName)
	if not knifeModel or not knifeModel:IsA("BasePart") then
		warn("Faca não encontrada:", itemName)
		return
	end

	-- Remove spoof anterior
	if character:FindFirstChild("SpoofedItem") then
		character.SpoofedItem:Destroy()
	end

	-- Remove faca legítima ainda equipada
	local legit = character:FindFirstChild("KnifeAttachment")
	if legit then
		legit:Destroy()
	end

	-- Clona e configura a spoofada
	local clone = knifeModel:Clone()
	clone.Name = "SpoofedItem"
	clone.Anchored = false
	clone.CanCollide = false
	clone.Parent = character

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then
		warn("Torso não encontrado")
		return
	end

	local weld = Instance.new("Weld")
	weld.Name = "SpoofWeld"
	weld.Part0 = torso
	weld.Part1 = clone
	weld.C0 = legitC0
	weld.Parent = torso
end

local function setCor(botao, cor)
	pcall(function() botao.ImageColor3 = cor end)
end

-- Cria spoof do botão
local function spoofarFaca(nome)
	if knivesGUI:FindFirstChild(nome) then return end

	local original = nil
	for _, btn in pairs(knivesGUI:GetChildren()) do
		if btn:IsA("GuiButton") and btn.Name:lower():gsub("%s+", "") == nome:lower():gsub("_", "") then
			original = btn
			break
		end
	end

	if not original then
		warn("Botão real não encontrado:", nome)
		return
	end

	local spoof = original:Clone()
	spoof.Name = nome
	spoof.Visible = true

	-- Highlight ao passar o mouse
	spoof.MouseEnter:Connect(function()
		setCor(spoof, Color3.fromRGB(0, 215, 255))
	end)

	spoof.MouseLeave:Connect(function()
		if selectedButton ~= spoof then
			setCor(spoof, Color3.fromRGB(240, 240, 240))
		end
	end)

	spoof.MouseButton1Click:Connect(function()
		for _, btn in pairs(knivesGUI:GetChildren()) do
			if btn:IsA("GuiButton") then
				pcall(function()
					btn:SetAttribute("Equipped", false)
					btn.ImageColor3 = Color3.fromRGB(240, 240, 240)
				end)
			end
		end

		spoof:SetAttribute("Equipped", true)
		setCor(spoof, Color3.fromRGB(0, 255, 0))
		selectedButton = spoof
		equiparNasCostas(nome)
	end)

	spoof.Parent = knivesGUI
	print("[SPOOFER] Spoof injetado:", nome)
end

-- Injetar spoof em todas as facas
for _, knife in ipairs(knivesStorage:GetChildren()) do
	spoofarFaca(knife.Name)
end

print("[SPOOFER] Finalizado. Facas spoofadas com C0 legítimo.")