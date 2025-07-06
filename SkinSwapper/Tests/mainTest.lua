local player = game.Players.LocalPlayer
local replicatedKnives = game.ReplicatedStorage.Assets.Game.Knives
local knifeUI = player.PlayerGui.Menus.Inventory.Content.Knives

-- Referência a um botão real do inventário (pra servir de molde)
local templateButton = knifeUI:FindFirstChildWhichIsA("TextButton") or knifeUI:FindFirstChildWhichIsA("ImageButton")

for _, knife in pairs(replicatedKnives:GetChildren()) do
    -- Clonar o botão base
    local spoofedButton = templateButton:Clone()
    spoofedButton.Name = "Spoofed_" .. knife.Name
    spoofedButton.Visible = true

    -- Atualizar texto e imagem
    if spoofedButton:FindFirstChild("TextLabel") then
        spoofedButton.TextLabel.Text = knife.Name
    else
        spoofedButton.Text = knife.Name
    end

    if spoofedButton:FindFirstChild("ImageLabel") and knife:FindFirstChild("Texture") then
        spoofedButton.ImageLabel.Image = knife.Texture -- adaptável
    end

    -- Adiciona ao inventário visual
    spoofedButton.Parent = knifeUI

    -- Evento de equip visual
    spoofedButton.MouseButton1Click:Connect(function()
        -- Remove qualquer faca anterior fake
        local char = player.Character
        if char and char:FindFirstChild("FakeKnife") then
            char.FakeKnife:Destroy()
        end

        -- Clona e equipa visualmente
        local fakeKnife = knife:Clone()
        fakeKnife.Name = "FakeKnife"
        fakeKnife.Parent = char
        -- Coloque aqui onde posicionar, exemplo:
        -- fakeKnife.CFrame = char.RightHand.CFrame
    end)
end
