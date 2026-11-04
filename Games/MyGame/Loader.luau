
-- BRONX STREETS HUB V2
-- Single-file menu with local features

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

if game.GameId ~= 10763808155 then
    warn("Wrong game ID: " .. tostring(game.GameId))
    return
end

local pg = player:WaitForChild("PlayerGui")
local previous = pg:FindFirstChild("BronxStreetsHub")
if previous then previous:Destroy() end

local connections = {}
local states = {}
local markers = {}
local original = {
    clock = Lighting.ClockTime,
    brightness = Lighting.Brightness,
    ambient = Lighting.Ambient
}

local colors = {
    bg = Color3.fromRGB(9,11,17),
    panel = Color3.fromRGB(15,18,25),
    row = Color3.fromRGB(23,26,34),
    selected = Color3.fromRGB(45,49,60),
    blue = Color3.fromRGB(42,145,255),
    purple = Color3.fromRGB(116,52,245),
    white = Color3.fromRGB(245,245,250),
    muted = Color3.fromRGB(160,165,180),
    green = Color3.fromRGB(0,255,70)
}

local gui = Instance.new("ScreenGui")
gui.Name = "BronxStreetsHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,r)
    c.Parent = obj
end

local function border(obj,col,width)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = width or 1
    s.Parent = obj
end

local function panel(parent,x,y,w,h,color)
    local f = Instance.new("Frame")
    f.Position = UDim2.fromOffset(x,y)
    f.Size = UDim2.fromOffset(w,h)
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function text(parent,value,x,y,w,h,size,color)
    local t = Instance.new("TextLabel")
    t.Position = UDim2.fromOffset(x,y)
    t.Size = UDim2.fromOffset(w,h)
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextSize = size
    t.TextColor3 = color or colors.white
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end

local main = panel(gui,0,0,760,320,colors.bg)
main.AnchorPoint = Vector2.new(.5,.5)
main.Position = UDim2.fromScale(.5,.43)
round(main,13)
border(main,colors.blue,1.6)

local scale = Instance.new("UIScale")
scale.Parent = main

local function resize()
    local cam = workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        scale.Scale = math.min(1,(v.X-20)/760,(v.Y-20)/320)
    end
end
resize()

local header = panel(main,6,6,748,37,colors.panel)
round(header,7)
text(header,"🔫 Bronx Streets Hub | Free 350K",
    12,1,610,34,18)

local function headerButton(symbol,x,callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(28,29)
    b.Position = UDim2.fromOffset(x,3)
    b.BackgroundTransparency = 1
    b.Text = symbol
    b.TextSize = 23
    b.TextColor3 = colors.white
    b.Parent = header
    b.MouseButton1Click:Connect(callback)
    return b
end

local side = panel(main,12,51,146,256,colors.panel)
round(side,9)

local page = panel(main,170,51,370,256,colors.panel)
round(page,9)

local right = panel(main,550,51,198,256,colors.bg)
round(right,9)

local pageTitle = text(page,"Home",15,7,320,26,17)
local content = panel(page,12,41,346,204,colors.panel)
content.BackgroundTransparency = 1

local status = text(right,"",8,225,185,26,10,colors.muted)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center

local function notify(message)
    status.Text = message
    print("[Bronx Hub] " .. message)
end

-- Player preview
local logo = text(right,"BRONX",12,3,175,29,24)
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextStrokeTransparency = 0

local logo2 = text(right,"STREETS",12,29,175,28,23,
    Color3.fromRGB(230,35,45))
logo2.TextXAlignment = Enum.TextXAlignment.Center

local previewLabel = text(right,"PLAYER PREVIEW",
    10,90,180,22,13,colors.green)
previewLabel.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = panel(right,54,119,90,95,
    Color3.fromRGB(10,20,14))
border(avatarBox,colors.green,2)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromScale(1,1)
avatar.BackgroundTransparency = 1
avatar.ScaleType = Enum.ScaleType.Fit
avatar.Parent = avatarBox

task.spawn(function()
    local ok,url = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.AvatarThumbnail,
            Enum.ThumbnailSize.Size150x150
        )
    end)
    if ok and gui.Parent then avatar.Image = url end
end)

-- ESP visuals: highlights, 2D boxes, and R6/R15 skeletons
local overlay = Instance.new("ScreenGui")
overlay.Name = "BronxStreetsOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.DisplayOrder = 50
overlay.Parent = pg

local markerConnections = {}
local overlayParts = {}
local targetVisuals = {}

local function overlayFrame(color, thickness)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = color
    f.Size = UDim2.fromOffset(0, thickness or 2)
    f.Visible = false
    f.Parent = overlay
    table.insert(overlayParts, f)
    return f
end

local function lineBetween(f, a, b, thickness)
    local dx, dy = b.X - a.X, b.Y - a.Y
    local length = math.sqrt(dx*dx + dy*dy)
    local t = thickness or 2
    f.Position = UDim2.fromOffset(
        (a.X+b.X)/2-length/2,
        (a.Y+b.Y)/2-t/2
    )
    f.Size = UDim2.fromOffset(length, t)
    f.Rotation = math.deg(math.atan2(dy, dx))
    f.Visible = length > 0
end

local function clearMarkers()
    for _, connection in ipairs(markerConnections) do
        connection:Disconnect()
    end
    table.clear(markerConnections)

    for _, obj in ipairs(markers) do
        if obj then obj:Destroy() end
    end
    table.clear(markers)

    for _, obj in ipairs(overlayParts) do
        obj:Destroy()
    end
    table.clear(overlayParts)
    table.clear(targetVisuals)
end

local function isEnemy(target)
    if target == player then return false end
    if states["ESP:Team Check (Enemy Only)"] then
        -- Uses Roblox Teams; custom factions need mapping.
        if player.Team and target.Team then
            return player.Team ~= target.Team
        end
    end
    return true
end

local skeletonR15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"}
}

local skeletonR6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function createMarker(target)
    if not target.Character or not isEnemy(target) then
        return
    end

    local char = target.Character
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not head or not hum or hum.Health <= 0 then
        return
    end

    if states["ESP:Player ESP"] then
        local h = Instance.new("Highlight")
        h.Name = "BronxESP"
        h.Adornee = char
        h.FillColor = Color3.fromRGB(255,45,55)
        h.FillTransparency = .65
        h.OutlineColor = colors.green
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        table.insert(markers, h)
    end

    local visual = {
        target = target,
        character = char,
        head = head
    }
    targetVisuals[#targetVisuals+1] = visual

    if states["ESP:Boxes"] then
        visual.box = {}
        for i = 1, 4 do
            visual.box[i] = overlayFrame(colors.green, 2)
        end
    end

    if states["ESP:Skeleton"] then
        visual.bones = {}
        local pairsList =
            hum.RigType == Enum.HumanoidRigType.R15
            and skeletonR15 or skeletonR6

        for _, pair in ipairs(pairsList) do
            visual.bones[#visual.bones+1] = {
                pair[1],
                pair[2],
                overlayFrame(colors.green, 2)
            }
        end
    end

    if states["ESP:Name"] or states["ESP:Distance"] then
        local bb = Instance.new("BillboardGui")
        bb.Name = "BronxInfo"
        bb.Adornee = head
        bb.Size = UDim2.fromOffset(160,42)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Parent = pg

        local lbl = text(
            bb,"",0,0,160,42,13,colors.green
        )
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextStrokeTransparency = .2
        table.insert(markers,bb)
        visual.info = lbl
    end
end

local function refreshESP()
    clearMarkers()
    for _,target in ipairs(Players:GetPlayers()) do
        createMarker(target)
    end
end

local function hideVisual(v)
    if v.box then
        for _, edge in ipairs(v.box) do
            edge.Visible = false
        end
    end

    if v.bones then
        for _, bone in ipairs(v.bones) do
            bone[3].Visible = false
        end
    end
end

-- Update 2D ESP overlays
table.insert(connections,
    RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        for _, v in ipairs(targetVisuals) do
            local char = v.character
            local hum = char and
                char:FindFirstChildOfClass("Humanoid")
            local root = char and
                char:FindFirstChild("HumanoidRootPart")

            if not hum or hum.Health <= 0
                or not root or not isEnemy(v.target) then
                hideVisual(v)
                if v.info then v.info.Text = "" end
            else
                local center, visible =
                    camera:WorldToViewportPoint(root.Position)

                if not visible or center.Z <= 0 then
                    hideVisual(v)
                else
                    if v.box then
                        local top =
                            camera:WorldToViewportPoint(
                                root.Position + Vector3.new(0,3,0)
                            )
                        local bottom =
                            camera:WorldToViewportPoint(
                                root.Position - Vector3.new(0,3,0)
                            )

                        local height = math.clamp(
                            math.abs(bottom.Y-top.Y),8,2000
                        )
                        local width = height * .48
                        local x = center.X-width/2
                        local y = math.min(top.Y,bottom.Y)

                        local a = Vector2.new(x,y)
                        local b = Vector2.new(x+width,y)
                        local c = Vector2.new(
                            x+width,y+height
                        )
                        local d = Vector2.new(x,y+height)

                        lineBetween(v.box[1],a,b,2)
                        lineBetween(v.box[2],b,c,2)
                        lineBetween(v.box[3],c,d,2)
                        lineBetween(v.box[4],d,a,2)
                    end

                    if v.bones then
                        for _, bone in ipairs(v.bones) do
                            local partA =
                                char:FindFirstChild(bone[1])
                            local partB =
                                char:FindFirstChild(bone[2])

                            if partA and partB then
                                local aa, va =
                                    camera:WorldToViewportPoint(
                                        partA.Position
                                    )
                                local bb, vb =
                                    camera:WorldToViewportPoint(
                                        partB.Position
                                    )

                                if va and vb
                                    and aa.Z > 0
                                    and bb.Z > 0 then
                                    lineBetween(
                                        bone[3],
                                        Vector2.new(aa.X,aa.Y),
                                        Vector2.new(bb.X,bb.Y),
                                        2
                                    )
                                else
                                    bone[3].Visible = false
                                end
                            else
                                bone[3].Visible = false
                            end
                        end
                    end
                end

                if v.info then
                    local bits = {}

                    if states["ESP:Name"] then
                        table.insert(
                            bits,v.target.DisplayName
                        )
                    end

                    if states["ESP:Distance"] then
                        local myRoot =
                            player.Character and
                            player.Character:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if myRoot then
                            local d = (
                                root.Position-myRoot.Position
                            ).Magnitude

                            table.insert(
                                bits,
                                string.format("%.0fm",d)
                            )
                        end
                    end

                    v.info.Text = table.concat(bits," | ")
                end
            end
        end
    end)
)

local espNames = {
    ["Player ESP"]=true,
    ["Name"]=true,
    ["Distance"]=true,
    ["Boxes"]=true,
    ["Skeleton"]=true,
    ["Team Check (Enemy Only)"]=true
}

-- Local movement
local function humanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function applyMovement()
    local h = humanoid()
    if not h then return end

    h.WalkSpeed =
        states["Player:Speed"] and 28 or 16
    h.UseJumpPower = true
    h.JumpPower =
        states["Player:High Jump"] and 85 or 50
end

table.insert(connections,
    UIS.JumpRequest:Connect(function()
        if states["Player:Infinite Jump"] then
            local h = humanoid()
            if h then
                h:ChangeState(
                    Enum.HumanoidStateType.Jumping
                )
            end
        end
    end)
)

table.insert(connections,
    player.CharacterAdded:Connect(function()
        task.wait(.5)
        applyMovement()
    end)
)

-- Feature dispatcher
local function applyFeature(category,option,enabled)
    local key = category .. ":" .. option
    states[key] = enabled

    if category == "ESP" then
        if espNames[option] then
            refreshESP()
        else
            notify(option .. " needs additional game data")
        end

    elseif category == "Player" then
        if option == "Speed"
            or option == "High Jump" then
            applyMovement()

        elseif option == "Infinite Jump" then
            notify(
                enabled and "Infinite Jump ON"
                or "Infinite Jump OFF"
            )
        else
            notify(
                option .. " requires game integration"
            )
        end

    elseif category == "Misc" then
        if option == "Full Bright" then
            Lighting.Brightness =
                enabled and 5 or original.brightness
            Lighting.Ambient =
                enabled
                and Color3.fromRGB(255,255,255)
                or original.ambient

        elseif option == "Day Mode" then
            Lighting.ClockTime =
                enabled and 12 or original.clock

        elseif option == "Night Mode" then
            Lighting.ClockTime =
                enabled and 0 or original.clock
        else
            notify(option .. " not connected")
        end

    elseif category == "Teleport" then
        if not enabled then return end

        if option == "Teleport to Spawn" then
            local spawnPart =
                workspace:FindFirstChildWhichIsA(
                    "SpawnLocation",true
                )

            local root =
                player.Character and
                player.Character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if spawnPart and root then
                root.CFrame =
                    spawnPart.CFrame * CFrame.new(0,4,0)
                notify("Spawn teleport attempted")
            else
                notify("Spawn location not found")
            end
        else
            notify(
                "Destination not configured: " .. option
            )
        end

    elseif category == "Combat" then
        notify(
            option .. " needs weapon or NPC integration"
        )

    elseif category == "Settings" then
        notify(
            option .. (enabled and " ON" or " OFF")
        )
    end
end

local tabs = {
    {"⌂","Home"},
    {"⚔","Combat"},
    {"◉","ESP"},
    {"♟","Player"},
    {"⌖","Teleport"},
    {"⚒","Misc"},
    {"⚙","Settings"}
}

local tabButtons = {}

local options = {
    Home = {
        "Enable Hub",
        "Show Player Info",
        "Enable Effects"
    },

    Combat = {
        "Aimbot",
        "Silent Aim",
        "Target Lock",
        "FOV Circle",
        "Smooth Aim",
        "Wall Check"
    },

    ESP = {
        "Player ESP",
        "Name",
        "Distance",
        "Boxes",
        "Skeleton",
        "Team Check (Enemy Only)"
    },

    Player = {
        "Speed",
        "High Jump",
        "Infinite Jump",
        "No Stamina",
        "Anti Fall Damage"
    },

    Teleport = {
        "Teleport to Spawn",
        "Teleport to Shop",
        "Teleport to Bank",
        "Custom Location"
    },

    Misc = {
        "Full Bright",
        "Day Mode",
        "Night Mode",
        "FPS Boost"
    },

    Settings = {
        "Show Notifications",
        "Save Settings",
        "Enable Keybinds"
    }
}

local function makeToggle(category,option,y)
    local key = category .. ":" .. option
    local row = panel(
        content,0,y,346,30,colors.row
    )
    round(row,5)
    text(row,option,11,0,270,30,12)

    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(293,5)
    button.Size = UDim2.fromOffset(41,20)
    button.Text = ""
    button.Parent = row
    round(button,12)

    local dot = panel(
        button,3,2,16,16,colors.white
    )
    round(dot,10)

    local function redraw()
        local on = states[key] == true
        button.BackgroundColor3 =
            on and colors.purple
            or Color3.fromRGB(56,60,70)
        dot.Position = UDim2.fromOffset(
            on and 22 or 3,2
        )
    end

    redraw()

    button.MouseButton1Click:Connect(function()
        local newValue = not states[key]
        applyFeature(category,option,newValue)
        redraw()
    end)
end

local function showPage(name)
    pageTitle.Text = name

    for _,item in ipairs(content:GetChildren()) do
        item:Destroy()
    end

    for tab,btn in pairs(tabButtons) do
        btn.BackgroundColor3 =
            tab == name
            and colors.selected
            or colors.panel
    end

    for i,option in ipairs(
        options[name] or {}
    ) do
        makeToggle(name,option,(i-1)*33)
    end
end

for i,item in ipairs(tabs) do
    local symbol,name = item[1],item[2]

    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(
        7,5+(i-1)*35
    )
    b.Size = UDim2.fromOffset(132,31)
    b.BackgroundColor3 = colors.panel
    b.Text = ""
    b.Parent = side
    round(b,6)

    text(b,symbol,10,0,24,31,17)
    text(b,name,37,0,90,31,12)

    tabButtons[name] = b

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- Close and minimize
local close = headerButton("×",711,function()
    clearMarkers()
    overlay:Destroy()

    for _,connection in ipairs(connections) do
        connection:Disconnect()
    end

    gui:Destroy()
end)

local minimized = false

headerButton("−",680,function()
    minimized = not minimized
    main.Size =
        minimized
        and UDim2.fromOffset(760,44)
        or UDim2.fromOffset(760,320)

    side.Visible = not minimized
    page.Visible = not minimized
    right.Visible = not minimized
end)

-- Dragging
local dragging = false
local startMouse,startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then
        dragging = true
        startMouse = input.Position
        startPosition = main.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

table.insert(connections,
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType ==
            Enum.UserInputType.MouseMovement then
            local delta =
                input.Position-startMouse

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset+delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset+delta.Y
            )
        end
    end)
)

-- Refresh markers for characters
local function watchPlayer(p)
    table.insert(connections,
        p.CharacterAdded:Connect(function()
            task.wait(.5)
            if gui.Parent then
                refreshESP()
            end
        end)
    )

    table.insert(connections,
        p.CharacterRemoving:Connect(function()
            task.defer(function()
                if gui.Parent then
                    refreshESP()
                end
            end)
        end)
    )
end

for _,p in ipairs(Players:GetPlayers()) do
    watchPlayer(p)
end

table.insert(connections,
    Players.PlayerAdded:Connect(function(p)
        watchPlayer(p)
        task.wait(.5)
        if gui.Parent then
            refreshESP()
        end
    end)
)

table.insert(connections,
    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            if gui.Parent then
                refreshESP()
            end
        end)
    end)
)

showPage("ESP")
notify("Hub V2 with Box + Skeleton loaded")
