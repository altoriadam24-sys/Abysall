
-- BRONX STREETS HUB
-- Custom menu design

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

if game.GameId ~= 10763808155 then
    warn("Wrong game!")
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("BronxStreetsHub")
if old then old:Destroy() end

local C = {
    bg = Color3.fromRGB(8, 10, 15),
    panel = Color3.fromRGB(13, 16, 22),
    row = Color3.fromRGB(20, 23, 29),
    selected = Color3.fromRGB(43, 47, 56),
    blue = Color3.fromRGB(48, 143, 255),
    purple = Color3.fromRGB(110, 46, 245),
    white = Color3.fromRGB(245, 245, 250),
    muted = Color3.fromRGB(170, 175, 187),
    green = Color3.fromRGB(0, 255, 65)
}

local gui = Instance.new("ScreenGui")
gui.Name = "BronxStreetsHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = obj
    return s
end

local function frame(parent, x, y, w, h, color)
    local f = Instance.new("Frame")
    f.Position = UDim2.fromOffset(x, y)
    f.Size = UDim2.fromOffset(w, h)
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function label(parent, text, x, y, w, h, size, color)
    local l = Instance.new("TextLabel")
    l.Position = UDim2.fromOffset(x, y)
    l.Size = UDim2.fromOffset(w, h)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or C.white
    l.TextSize = size
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- Main window
local main = frame(gui, 0, 0, 760, 320, C.bg)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.43)
corner(main, 13)
stroke(main, C.blue, 1.5)

local scale = Instance.new("UIScale")
scale.Parent = main

local function updateScale()
    local camera = workspace.CurrentCamera
    if camera then
        local v = camera.ViewportSize
        scale.Scale = math.min(1, (v.X - 24) / 760,
            (v.Y - 24) / 320)
    end
end

updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal(
        "ViewportSize"
    ):Connect(updateScale)
end

-- Top line
local topLine = frame(main, 3, 2, 754, 2, C.blue)

local header = frame(main, 5, 6, 750, 37, C.panel)
corner(header, 7)

label(header, "🔫  Bronx Streets Hub | Free 350K",
    13, 0, 590, 36, 19, C.white)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(29, 28)
close.Position = UDim2.fromOffset(711, 4)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextSize = 24
close.TextColor3 = C.white
close.Parent = header

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(25, 28)
minimize.Position = UDim2.fromOffset(681, 4)
minimize.BackgroundTransparency = 1
minimize.Text = "−"
minimize.TextSize = 23
minimize.TextColor3 = C.white
minimize.Parent = header

local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Size = minimized
        and UDim2.fromOffset(760, 44)
        or UDim2.fromOffset(760, 320)
    for _, child in ipairs(main:GetChildren()) do
        if child:IsA("Frame") and child ~= header
            and child ~= topLine then
            child.Visible = not minimized
        end
    end
end)

-- Sidebar
local sidebar = frame(main, 12, 50, 146, 257, C.panel)
corner(sidebar, 10)
stroke(sidebar, Color3.fromRGB(35, 39, 48), 1)

local tabs = {
    {"⌂", "Home"},
    {"⚔", "Combat"},
    {"◉", "ESP"},
    {"♟", "Player"},
    {"⌖", "Teleport"},
    {"⚒", "Misc"},
    {"⚙", "Settings"}
}

local page = frame(main, 170, 50, 370, 257, C.panel)
corner(page, 10)
stroke(page, Color3.fromRGB(32, 37, 46), 1)

local pageTitle = label(page, "ESP", 15, 7, 320, 30, 17)
local content = frame(page, 12, 42, 346, 205, C.panel)
content.BackgroundTransparency = 1

local tabButtons = {}
local selectedTab = "ESP"

local function makeToggle(text, y, default, callback)
    local bg = frame(content, 0, y, 346, 30, C.row)
    corner(bg, 5)
    stroke(bg, Color3.fromRGB(38, 42, 50), 0.7)

    label(bg, text, 11, 0, 268, 30, 12, C.white)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(39, 20)
    btn.Position = UDim2.fromOffset(295, 5)
    btn.BackgroundColor3 = default
        and C.purple or Color3.fromRGB(54, 58, 65)
    btn.Text = ""
    btn.Parent = bg
    corner(btn, 12)

    local circle = frame(btn, default and 21 or 3,
        2, 16, 16, C.white)
    corner(circle, 10)

    local enabled = default

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and C.purple
                or Color3.fromRGB(54, 58, 65)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.15), {
            Position = UDim2.fromOffset(
                enabled and 21 or 3, 2)
        }):Play()

        if callback then callback(enabled) end
    end)
end

local states = {}

local function showPage(name)
    selectedTab = name
    pageTitle.Text = name

    for _, item in ipairs(content:GetChildren()) do
        item:Destroy()
    end

    for tabName, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = tabName == name
            and C.selected or C.panel
    end

    local options = {}

    if name == "ESP" then
        options = {
            "Player ESP",
            "Name",
            "Distance",
            "Boxes",
            "Skeleton",
            "Team Check (Enemy Only)"
        }
    elseif name == "Combat" then
        options = {
            "Aimbot",
            "Silent Aim",
            "Target Lock",
            "FOV Circle",
            "Smooth Aim",
            "Wall Check"
        }
    elseif name == "Player" then
        options = {
            "Speed",
            "High Jump",
            "Infinite Jump",
            "No Stamina",
            "Anti Fall Damage"
        }
    elseif name == "Teleport" then
        options = {
            "Teleport to Spawn",
            "Teleport to Shop",
            "Teleport to Bank",
            "Custom Location"
        }
    elseif name == "Misc" then
        options = {
            "Full Bright",
            "Day Mode",
            "Night Mode",
            "FPS Boost"
        }
    elseif name == "Settings" then
        options = {
            "Show Notifications",
            "Save Settings",
            "Enable Keybinds"
        }
    else
        options = {
            "Enable Hub",
            "Show Player Info",
            "Enable Effects"
        }
    end

    for i, option in ipairs(options) do
        local key = name .. ":" .. option
        makeToggle(option, (i - 1) * 33,
            states[key] or false,
            function(value)
                states[key] = value
            end)
    end
end

for i, item in ipairs(tabs) do
    local symbol, name = item[1], item[2]

    local btn = Instance.new("TextButton")
    btn.Position = UDim2.fromOffset(7, 5 + (i-1)*35)
    btn.Size = UDim2.fromOffset(132, 31)
    btn.BackgroundColor3 = C.panel
    btn.Text = ""
    btn.Parent = sidebar
    corner(btn, 6)

    label(btn, symbol, 10, 0, 23, 31, 18, C.white)
    label(btn, name, 37, 0, 88, 31, 12, C.white)

    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- Right-side player preview
local right = frame(main, 550, 50, 198, 257, C.bg)
corner(right, 9)

local logo = label(right, "BRONX", 18, 0,
    170, 32, 26, Color3.fromRGB(255, 255, 255))
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextStrokeColor3 = Color3.fromRGB(160, 0, 0)
logo.TextStrokeTransparency = 0

local logo2 = label(right, "STREETS", 15, 27,
    172, 28, 25, Color3.fromRGB(220, 30, 40))
logo2.TextXAlignment = Enum.TextXAlignment.Center
logo2.TextStrokeTransparency = 0

local previewName = label(right,
    "Player [125m]", 20, 91, 165, 25, 14, C.green)
previewName.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = frame(right, 55, 130,
    90, 105, Color3.fromRGB(10, 20, 13))
stroke(avatarBox, C.green, 2)

local avatar = Instance.new("ImageLabel")
avatar.BackgroundTransparency = 1
avatar.Size = UDim2.fromScale(1, 1)
avatar.ScaleType = Enum.ScaleType.Fit
avatar.Parent = avatarBox

local success, thumbnail = pcall(function()
    return Players:GetUserThumbnailAsync(
        player.UserId,
        Enum.ThumbnailType.AvatarThumbnail,
        Enum.ThumbnailSize.Size150x150
    )
end)

if success then
    avatar.Image = thumbnail
end

showPage("ESP")

-- Drag window with header
local dragging = false
local startPos, startInput

header.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then
        dragging = true
        startInput = input.Position
        startPos = main.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(
    function(input)
        if dragging and input.UserInputType ==
            Enum.UserInputType.MouseMovement then
            local delta = input.Position - startInput
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end
)
