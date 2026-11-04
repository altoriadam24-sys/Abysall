
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("MyGame Loaded!")
print("Player:", player.Name)
print("GameId:", game.GameId)

if game.GameId ~= 10763808155 then
    warn("This menu is for a different game!")
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "MyGameHub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 220)
frame.Position = UDim2.fromScale(0.35, 0.3)
frame.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "MY GAME HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Parent = frame
