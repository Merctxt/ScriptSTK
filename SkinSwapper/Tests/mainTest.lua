-- Script: inject_spoofed_items.lua
-- Objetivo: Spoofar todas as facas do jogo com visuais reais, preview 3D correto e posicionamento nas costas
-- Autor: ChatGPT para Giovanni

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- Caminhos
local guiKnives = player:WaitForChild("PlayerGui"):WaitForChild("Menus"):WaitForChild("Inventory"):WaitForChild("Content"):WaitForChild("Knives")
local knivesStorage = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Game"):WaitForChild("Knives")

local function log(msg)
    print("[SPOOFER] " .. msg)
end

-- Função util para normalizar nomes
local function normalizarNome(str)
    return string.lower(str:gsub("[%s_]+", ""))
end

-- Cria um Weld baseado em Attachment se existir
local function weldToBack(model, char)
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then return end

    model.CFrame = torso.CFrame
    model.Anchored = false

    local weld = Instance.new("Weld")
    weld.Part0 = model
    weld.Part1 = torso
    weld.C0 = CFrame.new(0, 0, 0.7) * CFrame.Angles(math.rad(90), 0, 0)
    weld.Parent = model
end

-- Mapeia botões reais do jogador por nome normalizado
local botaoRealPorNome = {}
for _, btn in ipairs(guiKnives:GetChildren()) do
    if btn:IsA("GuiObject") and btn:FindFirstChild("ItemInfo") then
        botaoRealPorNome[normalizarNome(btn.Name)] = btn
    end
end

-- Garante que só haja um preview por botão
local previewConnections = {}

local function enable3DPreview(vpf, knifeModel)
    for _, obj in ipairs(vpf:GetChildren()) do
        if not obj:IsA("UIBase") then obj:Destroy() end
    end

    local clone = knifeModel:Clone()
    clone.Name = "SpoofPreview"
    clone.Anchored = true
    clone.CFrame = CFrame.Angles(math.rad(20), math.rad(45), 0)

    local cam = Instance.new("Camera")
    vpf.CurrentCamera = cam
    cam.CFrame = CFrame.new(Vector3.new(0, 0, 3), Vector3.new())
    cam.Parent = vpf

    local modelContainer = Instance.new("Model")
    clone.Parent = modelContainer
    modelContainer.Parent = vpf

    if previewConnections[vpf] then
        previewConnections[vpf]:Disconnect()
    end

    previewConnections[vpf] = RunService.RenderStepped:Connect(function()
        if clone and clone.Parent then
            clone.CFrame = clone.CFrame * CFrame.Angles(0, math.rad(1), 0)
        end
    end)
end

-- Cria spoof baseado no botão real
local function spoofKnife(knifeName)
    if guiKnives:FindFirstChild(knifeName) then return end
    local normalized = normalizarNome(knifeName)
    local realButton = botaoRealPorNome[normalized]
    if not realButton then
        log("Botão real não encontrado para: " .. knifeName)
        return
    end

    local newButton = realButton:Clone()
    newButton.Name = knifeName
    newButton.Visible = true

    -- Preview 3D ao passar o mouse
    newButton.MouseEnter:Connect(function()
        local knifeModel = knivesStorage:FindFirstChild(knifeName)
        local vpf = newButton:FindFirstChild("Weapon", true)
        if knifeModel and vpf and vpf:IsA("ViewportFrame") then
            enable3DPreview(vpf, knifeModel)
        end
    end)

    -- Clique para equipar nas costas
    newButton.MouseButton1Click:Connect(function()
        if char:FindFirstChild("SpoofedItem") then
            char.SpoofedItem:Destroy()
        end

        local knifeModel = knivesStorage:FindFirstChild(knifeName)
        if knifeModel and knifeModel:IsA("BasePart") then
            local clone = knifeModel:Clone()
            clone.Name = "SpoofedItem"
            clone.Parent = char
            weldToBack(clone, char)
            log("Equipado nas costas: " .. knifeName)
        else
            log("Modelo não encontrado: " .. knifeName)
        end
    end)

    newButton.Parent = guiKnives
    log("Spoof criado: " .. knifeName)
end

-- Criar spoof para cada faca do jogo
for _, knife in ipairs(knivesStorage:GetChildren()) do
    spoofKnife(knife.Name)
end

log("Todas as facas spoofadas com visual real e preview 3D corrigido.")
