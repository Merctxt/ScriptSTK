local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local knivesGUI = player.PlayerGui.Menus.Inventory.Content.Knives
local knivesStorage = ReplicatedStorage.Assets.Game.Knives

local selectedButton = nil
local ultimaEquipada = nil
local spoofados = {}

-- C0 baseado na faca legítima (ajustado com afastamento nas costas)
local legitC0 = CFrame.new(0.004, -0.115, 0.7) * CFrame.new(0, 0, 0,
    -0.044831, 0.641232, 0.766036,
    -0.053403, 0.764172, -0.642798,
    -0.997566, -0.069726, -0.000014)

-- CFrame para posicionar faca na mão (exemplo simples)
local handCFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)

-- Equipa faca spoofada (mão ou costas)
local function equiparFaca(itemName)
	local character = player.Character
	if not character then return end

	local knifeModel = knivesStorage:FindFirstChild(itemName)
	if not knifeModel or not knifeModel:IsA("BasePart") then
		warn("Faca não encontrada:", itemName)
		return
	end

	-- Remove spoof anterior
	if character:FindFirstChild("SpoofedItem") then
		character.SpoofedItem:Destroy()
	end

	-- Remove faca legítima
	local legit = character:FindFirstChild("KnifeAttachment")
	if legit then legit:Destroy() end

	local clone = knifeModel:Clone()
	clone.Name = "SpoofedItem"
	clone.Anchored = false
	clone.CanCollide = false
	clone.Parent = character

	local isKiller = tostring(player.Team) == "Killer"
	local targetPart = isKiller and character:FindFirstChild("RightHand") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not targetPart then
		warn("Parte de ancoragem não encontrada")
		return
	end

	local weld = Instance.new("Weld")
	weld.Name = "SpoofWeld"
	weld.Part0 = targetPart
	weld.Part1 = clone
	weld.C0 = isKiller and handCFrame or legitC0
	weld.Parent = targetPart
end

-- Aplica cor no botão
local function setCor(botao, cor)
	pcall(function() botao.ImageColor3 = cor end)
end

-- Cria botão manual se botão real não existir
local function criarBotaoManual(itemName)
	local template = knivesGUI:FindFirstChildWhichIsA("GuiButton")
	if not template then return end

	local btn = template:Clone()
	btn.Name = itemName
	btn.Visible = true

	-- Corrige nome no label (se existir)
	local itemInfo = btn:FindFirstChild("ItemInfo", true)
	if itemInfo and itemInfo:FindFirstChild("ItemName") then
		itemInfo.ItemName.Text = itemName
	end

	return btn
end

-- Procura botão baseado no ItemID (caso o nome não bata)
local function encontrarBotaoPorItemID(itemName)
	for _, btn in ipairs(knivesGUI:GetChildren()) do
		if btn:IsA("GuiButton") then
			local itemId = btn:GetAttribute("ItemID")
			if itemId and itemId:lower() == itemName:lower() then
				return btn
			end
		end
	end
	return nil
end

-- Cria spoof da faca
local function spoofarFaca(nome)
	if knivesGUI:FindFirstChild(nome) or spoofados[nome] then return end

	local original = nil

	-- Primeiro tenta achar por nome direto
	for _, btn in ipairs(knivesGUI:GetChildren()) do
		if btn:IsA("GuiButton") and btn.Name:lower():gsub("%s+", "") == nome:lower():gsub("_", "") then
			original = btn
			break
		end
	end

	-- Se não achou, tenta por ItemID
	if not original then
		original = encontrarBotaoPorItemID(nome)
	end

	local spoof = original or criarBotaoManual(nome)
	if not spoof then
		warn("Não foi possível spoofar:", nome)
		return
	end

	spoof.Name = nome
	spoof.Visible = true

	spoof.MouseEnter:Connect(function()
		setCor(spoof, Color3.fromRGB(0, 215, 255))
	end)

	spoof.MouseLeave:Connect(function()
		if selectedButton ~= spoof then
			setCor(spoof, Color3.fromRGB(240, 240, 240))
		end
	end)

	spoof.MouseButton1Click:Connect(function()
		for _, btn in ipairs(knivesGUI:GetChildren()) do
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
		equiparFaca(nome)
        ultimaEquipada = nome
	end)

	spoof.Parent = knivesGUI
	spoofados[nome] = true

	print("[SPOOFER] Spoof injetado:", nome)
end

-- Spoofar todas as facas do jogo
local function injetarTudo()
	for _, knife in ipairs(knivesStorage:GetChildren()) do
		spoofarFaca(knife.Name)
	end
end

-- Reaplica após reset
player.CharacterAdded:Connect(function(char)
	repeat wait() until char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	wait(0.25)
	selectedButton = nil
	print("[SPOOFER] Reaplicando spoof após reset")
	injetarTudo()
    if ultimaEquipada then
        wait(0.2)
        equiparFaca(ultimaEquipada)
        print("[SPOOFER] Reequipando última faca:", ultimaEquipada)
    else
        print("[SPOOFER] Nenhuma faca equipada anteriormente.")
    end
end)

-- Injeção inicial
injetarTudo()
print("[SPOOFER] Pronto. Sincronização com ItemID ativada.")
