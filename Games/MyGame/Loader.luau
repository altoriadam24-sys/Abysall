
-- BRONX STREETS HUB V4
-- Complete GUI + ESP + Camera Aim Assist

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end

local GAME_ID = 10763808155

if game.GameId ~= GAME_ID then
    warn("Wrong GameId:", game.GameId)
    return
end

local pg = player:WaitForChild("PlayerGui")

for _, name in ipairs({
    "BronxStreetsHub",
    "BronxStreetsOverlay"
}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

local states = {}
local connections = {}
local markers = {}
local visuals = {}

local config = {
    Smoothness = 5,
    FOVSize = 150,
    AimKey = Enum.UserInputType.MouseButton2,
    AimKeyName = "Right Mouse",
    AimHeld = false,
    Binding = false
}

local original = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient
}

local C = {
    bg = Color3.fromRGB(9,11,17),
    panel = Color3.fromRGB(15,18,25),
    row = Color3.fromRGB(23,26,34),
    selected = Color3.fromRGB(45,49,60),
    blue = Color3.fromRGB(42,145,255),
    purple = Color3.fromRGB(116,52,245),
    white = Color3.fromRGB(245,245,250),
    muted = Color3.fromRGB(160,165,180),
    green = Color3.fromRGB(0,255,70),
    red = Color3.fromRGB(255,55,65)
}

local function round(obj,r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,r)
    c.Parent = obj
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

local function label(parent,value,x,y,w,h,size,color)
    local t = Instance.new("TextLabel")
    t.Position = UDim2.fromOffset(x,y)
    t.Size = UDim2.fromOffset(w,h)
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextSize = size
    t.TextColor3 = color or C.white
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end

local function border(obj,color,width)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = width or 1
    s.Parent = obj
end

local gui = Instance.new("ScreenGui")
gui.Name = "BronxStreetsHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local overlay = Instance.new("ScreenGui")
overlay.Name = "BronxStreetsOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.DisplayOrder = 50
overlay.Parent = pg

local main = panel(gui,0,0,760,320,C.bg)
main.AnchorPoint = Vector2.new(.5,.5)
main.Position = UDim2.fromScale(.5,.43)
round(main,13)
border(main,C.blue,1.6)

local scale = Instance.new("UIScale")
scale.Parent = main

local function resize()
    local cam = workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        scale.Scale = math.min(
            1,
            (v.X-20)/760,
            (v.Y-20)/320
        )
    end
end
resize()

local header = panel(main,6,6,748,37,C.panel)
round(header,7)

label(
    header,
    "🔫 Bronx Streets Hub | Free 350K",
    12,1,610,34,18
)

local side = panel(main,12,51,146,256,C.panel)
round(side,9)

local page = panel(main,170,51,370,256,C.panel)
round(page,9)

local right = panel(main,550,51,198,256,C.bg)
round(right,9)

local pageTitle = label(
    page,"ESP",15,7,320,26,17
)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(12,41)
content.Size = UDim2.fromOffset(346,204)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.blue
content.CanvasSize = UDim2.fromOffset(0,204)
content.Parent = page

local status = label(
    right,"",8,225,185,26,10,C.muted
)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center

local function notify(message)
    status.Text = message
    print("[Bronx Hub]",message)
end

-- Player preview
local logo = label(
    right,"BRONX",12,3,175,29,24
)
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextStrokeTransparency = 0

local logo2 = label(
    right,"STREETS",12,29,175,28,23,C.red
)
logo2.TextXAlignment = Enum.TextXAlignment.Center

local previewLabel = label(
    right,"PLAYER PREVIEW",
    10,90,180,22,13,C.green
)
previewLabel.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = panel(
    right,54,119,90,95,
    Color3.fromRGB(10,20,14)
)
border(avatarBox,C.green,2)

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

    if ok and gui.Parent then
        avatar.Image = url
    end
end)

-- Screen overlay helpers
local overlayParts = {}

local function makeLine(color)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = color
    f.Visible = false
    f.Parent = overlay
    table.insert(overlayParts,f)
    return f
end

local function drawLine(f,a,b,thickness)
    local dx = b.X-a.X
    local dy = b.Y-a.Y
    local len = math.sqrt(dx*dx+dy*dy)
    local t = thickness or 2

    f.Position = UDim2.fromOffset(
        (a.X+b.X-len)/2,
        (a.Y+b.Y-t)/2
    )
    f.Size = UDim2.fromOffset(len,t)
    f.Rotation = math.deg(math.atan2(dy,dx))
    f.Visible = len > 0
end

-- FOV circle
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(.5,.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = overlay

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1,0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = C.purple
fovStroke.Thickness = 2
fovStroke.Parent = fovCircle

local function updateFOV()
    local diameter = config.FOVSize*2
    local mouse = UIS:GetMouseLocation()

    fovCircle.Size = UDim2.fromOffset(
        diameter,diameter
    )
    fovCircle.Position = UDim2.fromOffset(
        mouse.X,mouse.Y
    )
    fovCircle.Visible =
        states["Combat:FOV Circle"] == true
end

-- ESP
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

local function isEnemy(target)
    if target == player then return false end

    if states["ESP:Team Check (Enemy Only)"] then
        if player.Team and target.Team then
            return player.Team ~= target.Team
        end
    end

    return true
end

local function clearESP()
    for _,obj in ipairs(markers) do
        obj:Destroy()
    end
    table.clear(markers)

    for _,obj in ipairs(overlayParts) do
        obj:Destroy()
    end
    table.clear(overlayParts)
    table.clear(visuals)
end

local function createESP(target)
    if not isEnemy(target) then return end

    local char = target.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")

    if not hum or not head or hum.Health <= 0 then
        return
    end

    local v = {
        target = target,
        char = char
    }

    table.insert(visuals,v)

    if states["ESP:Player ESP"] then
        local h = Instance.new("Highlight")
        h.Adornee = char
        h.FillColor = C.red
        h.FillTransparency = .65
        h.OutlineColor = C.green
        h.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        table.insert(markers,h)
    end

    if states["ESP:Boxes"] then
        v.box = {}
        for i=1,4 do
            table.insert(v.box,makeLine(C.green))
        end
    end

    if states["ESP:Skeleton"] then
        v.bones = {}

        local rig =
            hum.RigType == Enum.HumanoidRigType.R15
            and skeletonR15 or skeletonR6

        for _,pair in ipairs(rig) do
            table.insert(v.bones,{
                pair[1],pair[2],makeLine(C.green)
            })
        end
    end

    if states["ESP:Name"] or
       states["ESP:Distance"] then

        local bb = Instance.new("BillboardGui")
        bb.Adornee = head
        bb.Size = UDim2.fromOffset(160,42)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Parent = pg

        local t = label(
            bb,"",0,0,160,42,13,C.green
        )
        t.TextXAlignment = Enum.TextXAlignment.Center
        t.TextStrokeTransparency = .2

        v.info = t
        table.insert(markers,bb)
    end
end

local function refreshESP()
    clearESP()

    for _,target in ipairs(Players:GetPlayers()) do
        createESP(target)
    end
end

local function hideVisual(v)
    if v.box then
        for _,e in ipairs(v.box) do
            e.Visible = false
        end
    end

    if v.bones then
        for _,b in ipairs(v.bones) do
            b[3].Visible = false
        end
    end
end

local function renderESP()
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _,v in ipairs(visuals) do
        local char = v.char
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        if not hum or hum.Health <= 0 or
            not root or not isEnemy(v.target) then

            hideVisual(v)
            if v.info then v.info.Text = "" end

        else
            local center,visible =
                cam:WorldToViewportPoint(root.Position)

            if not visible or center.Z <= 0 then
                hideVisual(v)
            else
                if v.box then
                    local top = cam:WorldToViewportPoint(
                        root.Position+Vector3.new(0,3,0)
                    )

                    local bottom = cam:WorldToViewportPoint(
                        root.Position-Vector3.new(0,3,0)
                    )

                    local h = math.clamp(
                        math.abs(bottom.Y-top.Y),8,2000
                    )
                    local w = h*.48
                    local x = center.X-w/2
                    local y = math.min(top.Y,bottom.Y)

                    local a = Vector2.new(x,y)
                    local b = Vector2.new(x+w,y)
                    local c = Vector2.new(x+w,y+h)
                    local d = Vector2.new(x,y+h)

                    drawLine(v.box[1],a,b,2)
                    drawLine(v.box[2],b,c,2)
                    drawLine(v.box[3],c,d,2)
                    drawLine(v.box[4],d,a,2)
                end

                if v.bones then
                    for _,bone in ipairs(v.bones) do
                        local p1 = char:FindFirstChild(bone[1])
                        local p2 = char:FindFirstChild(bone[2])

                        if p1 and p2 then
                            local a,va =
                                cam:WorldToViewportPoint(
                                    p1.Position
                                )
                            local b,vb =
                                cam:WorldToViewportPoint(
                                    p2.Position
                                )

                            if va and vb and
                               a.Z > 0 and b.Z > 0 then
                                drawLine(
                                    bone[3],
                                    Vector2.new(a.X,a.Y),
                                    Vector2.new(b.X,b.Y),
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
                    local myRoot = player.Character and
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
end

-- Aim Assist
local lockedTarget = nil

local function canSeeTarget(char,position)
    if not states["Combat:Wall Check"] then
        return true
    end

    local cam = workspace.CurrentCamera
    if not cam then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local exclusions = {}

    if player.Character then
        table.insert(exclusions,player.Character)
    end

    params.FilterDescendantsInstances = exclusions

    local origin = cam.CFrame.Position
    local direction = position-origin

    local result = workspace:Raycast(
        origin,direction,params
    )

    return not result or
        result.Instance:IsDescendantOf(char)
end

local function validTarget(target)
    if not target or target == player then
        return false
    end

    if not isEnemy(target) then return false end

    local char = target.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")

    return hum ~= nil and
        head ~= nil and hum.Health > 0
end

local function acquireTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local mouse = UIS:GetMouseLocation()
    local best = nil
    local bestDistance = math.huge

    for _,target in ipairs(Players:GetPlayers()) do
        if validTarget(target) then
            local head =
                target.Character:FindFirstChild("Head")

            local point,onScreen =
                cam:WorldToViewportPoint(head.Position)

            if onScreen and point.Z > 0 then
                local dist = (
                    Vector2.new(point.X,point.Y)-mouse
                ).Magnitude

                local insideFOV =
                    not states["Combat:FOV Enabled"]
                    or dist <= config.FOVSize

                if insideFOV and
                   dist < bestDistance and
                   canSeeTarget(
                       target.Character,head.Position
                   ) then

                    best = target
                    bestDistance = dist
                end
            end
        end
    end

    return best
end

local function updateAim(dt)
    if not states["Combat:Aimbot"] then
        lockedTarget = nil
        return
    end

    if not config.AimHeld then
        lockedTarget = nil
        return
    end

    if not states["Combat:Target Lock"] or
        not validTarget(lockedTarget) then
        lockedTarget = acquireTarget()
    end

    local target = lockedTarget
    if not validTarget(target) then
        lockedTarget = nil
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local point,onScreen =
        cam:WorldToViewportPoint(head.Position)

    if not onScreen or point.Z <= 0 then
        lockedTarget = nil
        return
    end

    if states["Combat:FOV Enabled"] then
        local mouse = UIS:GetMouseLocation()
        local distance = (
            Vector2.new(point.X,point.Y)-mouse
        ).Magnitude

        if distance > config.FOVSize then
            lockedTarget = nil
            return
        end
    end

    if not canSeeTarget(
        target.Character,head.Position
    ) then
        lockedTarget = nil
        return
    end

    local current = cam.CFrame
    local desired = CFrame.lookAt(
        current.Position,head.Position
    )

    local smooth = config.Smoothness

    if smooth <= 0 then
        cam.CFrame = desired
    else
        local speed = 30/(1+smooth*3)
        local alpha = 1-math.exp(-speed*dt)
        cam.CFrame = current:Lerp(desired,alpha)
    end
end

-- Aim key binding
local function matchesAimKey(input)
    if config.AimKey.EnumType ==
        Enum.KeyCode then
        return input.KeyCode == config.AimKey
    end

    return input.UserInputType == config.AimKey
end

table.insert(connections,
    UIS.InputBegan:Connect(function(input,processed)
        if config.Binding then return end
        if processed then return end

        if matchesAimKey(input) then
            config.AimHeld = true
        end
    end)
)

table.insert(connections,
    UIS.InputEnded:Connect(function(input)
        if matchesAimKey(input) then
            config.AimHeld = false
            lockedTarget = nil
        end
    end)
)

-- Local movement
local function getHumanoid()
    local char = player.Character
    return char and
        char:FindFirstChildOfClass("Humanoid")
end

local function applyMovement()
    local hum = getHumanoid()
    if not hum then return end

    hum.WalkSpeed =
        states["Player:Speed"] and 28 or 16

    hum.UseJumpPower = true
    hum.JumpPower =
        states["Player:High Jump"] and 85 or 50
end

table.insert(connections,
    UIS.JumpRequest:Connect(function()
        if states["Player:Infinite Jump"] then
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(
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

-- Main feature controller
local function applyFeature(category,option,enabled)
    local key = category..":"..option
    states[key] = enabled

    if category == "ESP" then
        refreshESP()

    elseif category == "Combat" then
        if option == "Aimbot" and not enabled then
            lockedTarget = nil
        elseif option == "Silent Aim" then
            notify("Silent Aim requires weapon integration")
        end

    elseif category == "Player" then
        if option == "Speed" or
            option == "High Jump" then
            applyMovement()
        elseif option ~= "Infinite Jump" then
            notify(option.." requires game integration")
        end

    elseif category == "Misc" then
        if option == "Full Bright" then
            Lighting.Brightness =
                enabled and 5 or original.Brightness

            Lighting.Ambient =
                enabled and Color3.fromRGB(255,255,255)
                or original.Ambient

        elseif option == "Day Mode" then
            Lighting.ClockTime =
                enabled and 12 or original.ClockTime

        elseif option == "Night Mode" then
            Lighting.ClockTime =
                enabled and 0 or original.ClockTime
        end

    elseif category == "Teleport" then
        if enabled and option == "Teleport to Spawn" then
            local spawn =
                workspace:FindFirstChildWhichIsA(
                    "SpawnLocation",true
                )

            local root = player.Character and
                player.Character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if spawn and root then
                root.CFrame =
                    spawn.CFrame*CFrame.new(0,4,0)
            else
                notify("Spawn location not found")
            end
        elseif enabled then
            notify("Destination not configured")
        end
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
        "FOV Enabled",
        "FOV Circle",
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

local tabButtons = {}

local function makeToggle(category,option,y)
    local key = category..":"..option

    local row = panel(
        content,0,y,338,30,C.row
    )
    round(row,5)

    label(row,option,11,0,270,30,12)

    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(293,5)
    button.Size = UDim2.fromOffset(41,20)
    button.Text = ""
    button.Parent = row
    round(button,12)

    local dot = panel(
        button,3,2,16,16,C.white
    )
    round(dot,10)

    local function redraw()
        local on = states[key] == true
        button.BackgroundColor3 =
            on and C.purple
            or Color3.fromRGB(56,60,70)

        dot.Position = UDim2.fromOffset(
            on and 22 or 3,2
        )
    end

    redraw()

    button.MouseButton1Click:Connect(function()
        applyFeature(
            category,option,not states[key]
        )
        redraw()
    end)
end

-- Slider: supports mouse drag
local function makeSlider(
    name,y,minValue,maxValue,getValue,setValue
)
    local bg = panel(
        content,0,y,338,53,C.row
    )
    round(bg,5)

    local title = label(
        bg,name,10,2,270,23,12
    )

    local valueText = label(
        bg,"",286,2,44,23,12,C.green
    )
    valueText.TextXAlignment =
        Enum.TextXAlignment.Right

    local track = panel(
        bg,12,34,312,5,
        Color3.fromRGB(65,69,80)
    )
    round(track,4)

    local fill = panel(
        track,0,0,0,5,C.purple
    )
    round(fill,4)

    local knob = panel(
        track,0,-5,15,15,C.white
    )
    round(knob,8)

    local function redraw()
        local v = getValue()
        local ratio =
            (v-minValue)/(maxValue-minValue)

        fill.Size = UDim2.fromScale(ratio,1)
        knob.Position = UDim2.new(
            ratio,-7,-1,0
        )
        valueText.Text = tostring(v)
    end

    redraw()

    local dragging = false

    local function changeAt(x)
        local left = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        if width <= 0 then return end

        local ratio =
            math.clamp((x-left)/width,0,1)

        local v = math.floor(
            minValue+(maxValue-minValue)*ratio+.5
        )

        setValue(v)
        redraw()
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
            dragging = true
            changeAt(input.Position.X)
        end
    end)

    table.insert(connections,
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType ==
                Enum.UserInputType.MouseMovement then
                changeAt(input.Position.X)
            end
        end)
    )

    table.insert(connections,
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    )
end

local function makeKeybind(y)
    local bg = panel(
        content,0,y,338,39,C.row
    )
    round(bg,5)

    label(bg,"Aim Key",10,5,150,29,12)

    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(165,5)
    button.Size = UDim2.fromOffset(160,29)
    button.BackgroundColor3 = C.purple
    button.TextColor3 = C.white
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = config.AimKeyName
    button.Parent = bg
    round(button,5)

    button.MouseButton1Click:Connect(function()
        config.Binding = true
        config.AimHeld = false
        button.Text = "Press a key..."
    end)

    local connection

    connection = UIS.InputBegan:Connect(function(
        input,processed
    )
        if not config.Binding then return end

        if input.UserInputType ==
            Enum.UserInputType.Keyboard then

            if input.KeyCode == Enum.KeyCode.Unknown then
                return
            end

            config.AimKey = input.KeyCode
            config.AimKeyName = input.KeyCode.Name

        elseif input.UserInputType ==
            Enum.UserInputType.MouseButton1 or
            input.UserInputType ==
                Enum.UserInputType.MouseButton2 or
            input.UserInputType ==
                Enum.UserInputType.MouseButton3 then

            config.AimKey = input.UserInputType
            config.AimKeyName =
                input.UserInputType.Name

        else
            return
        end

        config.Binding = false
        button.Text = config.AimKeyName
    end)

    table.insert(connections,connection)
end

local function showPage(name)
    pageTitle.Text = name

    for _,child in ipairs(content:GetChildren()) do
        child:Destroy()
    end

    for tab,btn in pairs(tabButtons) do
        btn.BackgroundColor3 =
            tab == name and C.selected or C.panel
    end

    local y = 0

    for _,option in ipairs(options[name] or {}) do
        makeToggle(name,option,y)
        y += 33
    end

    if name == "Combat" then
        y += 6

        makeSlider(
            "Smoothness",y,0,20,
            function()
                return config.Smoothness
            end,
            function(v)
                config.Smoothness = v
            end
        )

        y += 59

        makeSlider(
            "FOV Size",y,20,400,
            function()
                return config.FOVSize
            end,
            function(v)
                config.FOVSize = v
            end
        )

        y += 59

        makeKeybind(y)
        y += 45
    end

    content.CanvasSize =
        UDim2.fromOffset(0,math.max(y,204))
end

for i,item in ipairs(tabs) do
    local symbol,name = item[1],item[2]

    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(
        7,5+(i-1)*35
    )
    b.Size = UDim2.fromOffset(132,31)
    b.BackgroundColor3 = C.panel
    b.Text = ""
    b.Parent = side
    round(b,6)

    label(b,symbol,10,0,24,31,17)
    label(b,name,37,0,90,31,12)

    tabButtons[name] = b

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- Render
local renderName = "BronxHubAimRender"

RunService:BindToRenderStep(
    renderName,
    Enum.RenderPriority.Camera.Value+1,
    function(dt)
        updateFOV()
        renderESP()
        updateAim(dt)
    end
)

-- Refresh players
local function watchPlayer(p)
    table.insert(connections,
        p.CharacterAdded:Connect(function()
            task.wait(.4)
            if gui.Parent then refreshESP() end
        end)
    )

    table.insert(connections,
        p.CharacterRemoving:Connect(function()
            task.defer(function()
                if gui.Parent then refreshESP() end
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
        task.wait(.4)
        if gui.Parent then refreshESP() end
    end)
)

table.insert(connections,
    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            if gui.Parent then refreshESP() end
        end)
    end)
)

-- Minimize and close
local function headerButton(symbol,x,callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(28,29)
    b.Position = UDim2.fromOffset(x,3)
    b.BackgroundTransparency = 1
    b.Text = symbol
    b.TextSize = 23
    b.TextColor3 = C.white
    b.Parent = header
    b.MouseButton1Click:Connect(callback)
    return b
end

headerButton("×",711,function()
    RunService:UnbindFromRenderStep(renderName)

    clearESP()

    for _,c in ipairs(connections) do
        c:Disconnect()
    end

    overlay:Destroy()
    gui:Destroy()
end)

local minimized = false

headerButton("−",680,function()
    minimized = not minimized

    main.Size = minimized and
        UDim2.fromOffset(760,44) or
        UDim2.fromOffset(760,320)

    side.Visible = not minimized
    page.Visible = not minimized
    right.Visible = not minimized
end)

-- Drag window
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

            local delta = input.Position-startMouse

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset+delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset+delta.Y
            )
        end
    end)
)

showPage("Combat")
notify("Bronx Streets Hub V4 loaded")
