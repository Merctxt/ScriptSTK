local player = game.Players.LocalPlayer
local hrp = nil
local ativo = false
local cooldown = false
local mapaAtual = nil
local limiteMin, limiteMax = nil, nil

--// GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0, 20, 0, 100)
btn.Text = "Ativar Proteção"
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.SourceSansBold
btn.TextScaled = true

--// 1. Detectar o mapa atual dinamicamente
local function detectarMapa()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("LootSpawns") then
            return obj
        end
    end
    return nil
end

--// 2. Calcular limites do mapa (bounding box)
local function calcularLimites(mapa)
    local min = Vector3.new(math.huge, math.huge, math.huge)
    local max = Vector3.new(-math.huge, -math.huge, -math.huge)

    for _, part in ipairs(mapa:GetDescendants()) do
        if part:IsA("BasePart") then
            local pMin = part.Position - part.Size / 2
            local pMax = part.Position + part.Size / 2
            min = Vector3.new(
                math.min(min.X, pMin.X),
                math.min(min.Y, pMin.Y),
                math.min(min.Z, pMin.Z)
            )
            max = Vector3.new(
                math.max(max.X, pMax.X),
                math.max(max.Y, pMax.Y),
                math.max(max.Z, pMax.Z)
            )
        end
    end

    return min, max
end

--// 3. TP seguro dentro dos limites calculados
local function teleportarParaDentroDoMapa()
    hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not limiteMin or not limiteMax then return end

    for _ = 1, 10 do
        local x = math.random(limiteMin.X, limiteMax.X)
        local z = math.random(limiteMin.Z, limiteMax.Z)
        local origem = Vector3.new(x, limiteMax.Y + 50, z)
        local ray = Ray.new(origem, Vector3.new(0, -1000, 0))
        local hit, pos = workspace:FindPartOnRay(ray, player.Character)

        if hit and pos.Y > limiteMin.Y then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            print("✔️ Fugiu para:", pos)
            return
        end
    end

    warn("❌ Não achou posição segura no mapa.")
end

--// 4. Detectar atributo de proximidade do killer
player:GetAttributeChangedSignal("InKillerProximity"):Connect(function()
    if not ativo or cooldown then return end
    if player:GetAttribute("InKillerProximity") == true then
        cooldown = true
        teleportarParaDentroDoMapa()
        task.delay(5, function() cooldown = false end)
    end
end)

--// 5. Botão de ativar/desativar
btn.MouseButton1Click:Connect(function()
    ativo = not ativo
    btn.Text = ativo and "Desativar Proteção" or "Ativar Proteção"
    btn.BackgroundColor3 = ativo and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(255, 50, 50)

    if ativo then
        mapaAtual = detectarMapa()
        if mapaAtual then
            limiteMin, limiteMax = calcularLimites(mapaAtual)
            print("📦 Mapa identificado:", mapaAtual.Name)
        else
            warn("⚠️ Mapa não encontrado")
            ativo = false
        end
    end
end)
