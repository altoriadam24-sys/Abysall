
-- ANDRIIVKA HUB V2
-- Full standalone interface
-- Game ID: 10383565741
-- Place ID: 81748781442029

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
if not LP then return end

if game.GameId ~= 10383565741 then
    warn("ANDRIIVKA HUB: Incorrect game ID")
    return
end

if _G.AndriivkaHubCleanup then
    pcall(_G.AndriivkaHubCleanup)
end

local connections = {}
local espObjects = {}
local visuals = {}
local states = {}
local savedPositions = {}
local running = true

local config = {
    Smoothness = 5,
    FOVSize = 150,
    BulletSpeed = 500,
    GravityPercent = 100,
    Prediction = true,
    AimKey = Enum.UserInputType.MouseButton2,
    AimKeyName = "Right Mouse"
}

local aimHeld = false
local rebinding = false
local keyButton
local target

local originalLight = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    ClockTime = Lighting.ClockTime
}

local colors = {
    background = Color3.fromRGB(9,11,17),
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

local function connect(signal,callback)
    local c = signal:Connect(callback)
    table.insert(connections,c)
    return c
end

local function make(class,parent,properties)
    local object = Instance.new(class)

    for key,value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function corner(object,r)
    make("UICorner",object,{
        CornerRadius = UDim.new(0,r)
    })
end

local function stroke(object,color,width)
    make("UIStroke",object,{
        Color = color,
        Thickness = width or 1
    })
end

local function frame(parent,x,y,w,h,color)
    return make("Frame",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    })
end

local function label(parent,value,x,y,w,h,size,color)
    return make("TextLabel",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = color or colors.white,
        TextSize = size,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

local function getCharacter()
    return LP.Character
end

local function getRoot()
    local character = getCharacter()
    return character and
        character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character and
        character:FindFirstChildOfClass("Humanoid")
end

local pg = LP:WaitForChild("PlayerGui")

-- WINDOW

local gui = make("ScreenGui",pg,{
    Name = "AndriivkaHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local overlay = make("ScreenGui",pg,{
    Name = "AndriivkaOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50
})

local main = frame(
    gui,0,0,760,320,colors.background
)

main.AnchorPoint = Vector2.new(.5,.5)
main.Position = UDim2.fromScale(.5,.43)
round = corner
corner(main,13)
stroke(main,colors.blue,1.6)

local uiScale = make("UIScale",main,{Scale=1})

local function resize()
    local camera = workspace.CurrentCamera

    if camera then
        local size = camera.ViewportSize

        uiScale.Scale = math.min(
            1,
            (size.X-20)/760,
            (size.Y-20)/320
        )
    end
end

resize()

local header = frame(
    main,6,6,748,37,colors.panel
)
corner(header,7)

label(
    header,"ANDRIIVKA HUB",
    12,1,610,34,18
)

local sidebar = frame(
    main,12,51,146,256,colors.panel
)
corner(sidebar,9)

local page = frame(
    main,170,51,370,256,colors.panel
)
corner(page,9)

local right = frame(
    main,550,51,198,256,colors.background
)
corner(right,9)

local pageTitle = label(
    page,"Combat",15,7,320,26,17
)

local content = make("ScrollingFrame",page,{
    Position = UDim2.fromOffset(12,41),
    Size = UDim2.fromOffset(346,204),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = colors.blue,
    CanvasSize = UDim2.fromOffset(0,204)
})

local status = label(
    right,"Hub ready",
    6,225,186,28,10,colors.muted
)

status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center

local function notify(message)
    status.Text = message
    print("[Andriivka Hub]",message)
end

local logo = label(
    right,"ANDRIIVKA",
    5,5,188,34,22
)
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextStrokeTransparency = 0

local subtitle = label(
    right,"MILITARY HUB",
    5,40,188,28,17,colors.red
)
subtitle.TextXAlignment = Enum.TextXAlignment.Center

local preview = label(
    right,"PLAYER PREVIEW",
    10,89,180,22,13,colors.green
)
preview.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = frame(
    right,54,119,90,95,
    Color3.fromRGB(10,20,14)
)
stroke(avatarBox,colors.green,2)

local avatar = make("ImageLabel",avatarBox,{
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit
})

task.spawn(function()
    local ok,url = pcall(function()
        return Players:GetUserThumbnailAsync(
            LP.UserId,
            Enum.ThumbnailType.AvatarThumbnail,
            Enum.ThumbnailSize.Size150x150
        )
    end)

    if ok and running then
        avatar.Image = url
    end
end)

-- FOV DISPLAY

local circle = frame(
    overlay,0,0,300,300,colors.purple
)

circle.AnchorPoint = Vector2.new(.5,.5)
circle.BackgroundTransparency = 1
circle.Visible = false

make("UICorner",circle,{
    CornerRadius = UDim.new(1,0)
})
stroke(circle,colors.purple,2)

local function updateCircle()
    local mouse = UIS:GetMouseLocation()

    circle.Position = UDim2.fromOffset(
        mouse.X,mouse.Y
    )

    circle.Size = UDim2.fromOffset(
        config.FOVSize*2,
        config.FOVSize*2
    )

    circle.Visible =
        states["Combat:Show FOV"] == true
end

-- ESP

local r15 = {
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

local r6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function isEnemy(player)
    if player == LP then return false end

    if states["ESP:Team Check (Enemy Only)"]
        and LP.Team and player.Team then
        return LP.Team ~= player.Team
    end

    return true
end

local function newLine()
    local object = frame(
        overlay,0,0,0,2,colors.green
    )

    object.Visible = false
    table.insert(espObjects,object)

    return object
end

local function drawLine(object,a,b)
    local difference = b-a
    local length = difference.Magnitude

    object.Position = UDim2.fromOffset(
        (a.X+b.X)/2,
        (a.Y+b.Y)/2
    )

    object.AnchorPoint = Vector2.new(.5,.5)
    object.Size = UDim2.fromOffset(length,2)
    object.Rotation = math.deg(
        math.atan2(difference.Y,difference.X)
    )
    object.Visible = length > 0
end

local function clearESP()
    for _,object in ipairs(espObjects) do
        object:Destroy()
    end

    table.clear(espObjects)
    table.clear(visuals)
end

local function refreshESP()
    clearESP()

    for _,player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if character and isEnemy(player) then
            local hum =
                character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local visual = {
                    player = player,
                    character = character
                }

                if states["ESP:Player ESP"] then
                    local highlight = make(
                        "Highlight",character,{
                            Name = "AndriivkaESP",
                            Adornee = character,
                            FillColor = colors.red,
                            FillTransparency = .65,
                            OutlineColor = colors.green,
                            DepthMode =
                                Enum.HighlightDepthMode.AlwaysOnTop
                        }
                    )

                    table.insert(espObjects,highlight)
                end

                if states["ESP:Boxes"] then
                    visual.box = {
                        newLine(),
                        newLine(),
                        newLine(),
                        newLine()
                    }
                end

                if states["ESP:Skeleton"] then
                    visual.bones = {}

                    local bones =
                        hum.RigType == Enum.HumanoidRigType.R15
                        and r15 or r6

                    for _,pair in ipairs(bones) do
                        table.insert(visual.bones,{
                            pair[1],pair[2],newLine()
                        })
                    end
                end

                if states["ESP:Name"]
                    or states["ESP:Distance"] then

                    local bb = make("BillboardGui",pg,{
                        Adornee = head,
                        Size = UDim2.fromOffset(170,40),
                        StudsOffset = Vector3.new(0,3,0),
                        AlwaysOnTop = true
                    })

                    visual.info = label(
                        bb,"",0,0,170,40,12,colors.green
                    )

                    visual.info.TextXAlignment =
                        Enum.TextXAlignment.Center

                    visual.info.TextStrokeTransparency = .2

                    table.insert(espObjects,bb)
                end

                table.insert(visuals,visual)
            end
        end
    end
end

local function hideLines(visual)
    for _,object in ipairs(visual.box or {}) do
        object.Visible = false
    end

    for _,bone in ipairs(visual.bones or {}) do
        bone[3].Visible = false
    end
end

local function renderESP()
    local camera = workspace.CurrentCamera
    if not camera then return end

    for _,v in ipairs(visuals) do
        local character = v.character
        local hum =
            character:FindFirstChildOfClass("Humanoid")
        local root =
            character:FindFirstChild("HumanoidRootPart")

        if not hum or hum.Health <= 0
            or not root or not isEnemy(v.player) then

            hideLines(v)

            if v.info then
                v.info.Text = ""
            end
        else
            local center,visible =
                camera:WorldToViewportPoint(root.Position)

            if not visible or center.Z <= 0 then
                hideLines(v)
            else
                if v.box then
                    local top =
                        camera:WorldToViewportPoint(
                            root.Position+Vector3.new(0,3,0)
                        )

                    local bottom =
                        camera:WorldToViewportPoint(
                            root.Position-Vector3.new(0,3,0)
                        )

                    local h = math.clamp(
                        math.abs(bottom.Y-top.Y),
                        8,2000
                    )

                    local w = h*.48
                    local x = center.X-w/2
                    local y = math.min(top.Y,bottom.Y)

                    local a = Vector2.new(x,y)
                    local b = Vector2.new(x+w,y)
                    local c = Vector2.new(x+w,y+h)
                    local d = Vector2.new(x,y+h)

                    drawLine(v.box[1],a,b)
                    drawLine(v.box[2],b,c)
                    drawLine(v.box[3],c,d)
                    drawLine(v.box[4],d,a)
                end

                for _,bone in ipairs(v.bones or {}) do
                    local p1 =
                        character:FindFirstChild(bone[1])

                    local p2 =
                        character:FindFirstChild(bone[2])

                    if p1 and p2 then
                        local a,va =
                            camera:WorldToViewportPoint(p1.Position)

                        local b,vb =
                            camera:WorldToViewportPoint(p2.Position)

                        if va and vb and a.Z > 0 and b.Z > 0 then
                            drawLine(
                                bone[3],
                                Vector2.new(a.X,a.Y),
                                Vector2.new(b.X,b.Y)
                            )
                        else
                            bone[3].Visible = false
                        end
                    else
                        bone[3].Visible = false
                    end
                end
            end

            if v.info then
                local parts = {}

                if states["ESP:Name"] then
                    table.insert(parts,v.player.DisplayName)
                end

                if states["ESP:Distance"] then
                    local myRoot = getRoot()

                    if myRoot then
                        local distance =
                            (myRoot.Position-root.Position).Magnitude

                        table.insert(
                            parts,
                            string.format("%.0fm",distance)
                        )
                    end
                end

                v.info.Text = table.concat(parts," | ")
            end
        end
    end
end

-- FOV TARGET VALIDATION

local function insideFOV(position)
    local camera = workspace.CurrentCamera
    if not camera then return false end

    local point,onScreen =
        camera:WorldToViewportPoint(position)

    if not onScreen or point.Z <= 0 then
        return false
    end

    local mouse = UIS:GetMouseLocation()

    local distance = (
        Vector2.new(point.X,point.Y)-mouse
    ).Magnitude

    return distance <= config.FOVSize,distance
end

local function wallVisible(character,position)
    if not states["Combat:Wall Check"] then
        return true
    end

    local camera = workspace.CurrentCamera
    if not camera then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local ownCharacter = getCharacter()

    params.FilterDescendantsInstances =
        ownCharacter and {ownCharacter} or {}

    local origin = camera.CFrame.Position

    local result = workspace:Raycast(
        origin,
        position-origin,
        params
    )

    return result == nil or
        result.Instance:IsDescendantOf(character)
end

local function acquireTarget()
    local best
    local closest = math.huge

    for _,player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if character and isEnemy(player) then
            local hum =
                character:FindFirstChildOfClass("Humanoid")

            local head =
                character:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local within,distance =
                    insideFOV(head.Position)

                if within and distance < closest
                    and wallVisible(
                        character,
                        head.Position
                    ) then

                    best = player
                    closest = distance
                end
            end
        end
    end

    return best
end

-- BALLISTIC PREDICTION
-- Values are adjustable, not verified for Andriivka.

local function predictPosition(head)
    if not config.Prediction then
        return head.Position
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return head.Position
    end

    local origin = camera.CFrame.Position
    local velocity = head.AssemblyLinearVelocity
    local bulletSpeed = math.max(config.BulletSpeed,1)

    local distance = (
        head.Position-origin
    ).Magnitude

    local travelTime = math.clamp(
        distance/bulletSpeed,
        0,2
    )

    -- Refine approximate time to moving target
    for _ = 1,3 do
        local future =
            head.Position+velocity*travelTime

        travelTime = math.clamp(
            (future-origin).Magnitude/bulletSpeed,
            0,2
        )
    end

    local futurePosition =
        head.Position+velocity*travelTime

    local gravity =
        workspace.Gravity *
        (config.GravityPercent/100)

    local correction =
        .5*gravity*travelTime*travelTime

    return futurePosition +
        Vector3.new(0,correction,0)
end

local function updateAim(dt)
    if not states["Combat:Aimbot"] or not aimHeld then
        target = nil
        return
    end

    target = acquireTarget()
    if not target then return end

    local character = target.Character
    local head = character and
        character:FindFirstChild("Head")

    if not head then
        target = nil
        return
    end

    -- Only acquire targets whose actual head is
    -- inside the FOV circle.
    if not insideFOV(head.Position) then
        target = nil
        return
    end

    if not wallVisible(character,head.Position) then
        target = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local aimPoint = predictPosition(head)

    local current = camera.CFrame
    local desired = CFrame.lookAt(
        current.Position,
        aimPoint
    )

    if config.Smoothness == 0 then
        camera.CFrame = desired
    else
        local speed =
            30/(1+config.Smoothness*3)

        local alpha =
            1-math.exp(-speed*dt)

        camera.CFrame =
            current:Lerp(desired,alpha)
    end
end

-- PLAYER MOVEMENT

local function updateMovement()
    local hum = getHumanoid()
    if not hum then return end

    hum.WalkSpeed =
        states["Player:Speed"] and 28 or 16

    hum.UseJumpPower = true

    hum.JumpPower =
        states["Player:High Jump"] and 85 or 50
end

connect(UIS.JumpRequest,function()
    if states["Player:Infinite Jump"] then
        local hum = getHumanoid()

        if hum then
            hum:ChangeState(
                Enum.HumanoidStateType.Jumping
            )
        end
    end
end)

-- TELEPORT POSITIONS

local function savePosition(name)
    local root = getRoot()

    if root then
        savedPositions[name] = root.CFrame
        notify(name.." saved")
    else
        notify("Character not ready")
    end
end

local function teleportPosition(name)
    local character = getCharacter()
    local destination = savedPositions[name]

    if not destination then
        notify("Save "..name.." first")
        return
    end

    if character then
        character:PivotTo(destination)
        notify("Teleport attempted: "..name)
    end
end

local function teleportSpawn()
    local spawn =
        workspace:FindFirstChildWhichIsA(
            "SpawnLocation",
            true
        )

    local character = getCharacter()

    if spawn and character then
        character:PivotTo(
            spawn.CFrame*CFrame.new(0,4,0)
        )
        notify("Spawn teleport attempted")
    else
        notify("Spawn not found")
    end
end

-- FEATURE CONTROLLER

local function applyFeature(category,option,on)
    local key = category..":"..option
    states[key] = on

    if category == "ESP" then
        refreshESP()

    elseif category == "Combat" then
        if option == "Prediction" then
            config.Prediction = on

        elseif option == "Silent Aim" then
            notify("Silent Aim not implemented")

        elseif option == "Aimbot" and not on then
            target = nil
        end

    elseif category == "Player" then
        if option == "Speed"
            or option == "High Jump" then

            updateMovement()

        elseif option ~= "Infinite Jump" then
            notify(option.." requires game integration")
        end

    elseif category == "Misc" then
        if option == "Full Bright" then
            Lighting.Brightness =
                on and 5 or originalLight.Brightness

            Lighting.Ambient =
                on and Color3.new(1,1,1)
                or originalLight.Ambient

        elseif option == "Day Mode" then
            Lighting.ClockTime =
                on and 12 or originalLight.ClockTime

        elseif option == "Night Mode" then
            Lighting.ClockTime =
                on and 0 or originalLight.ClockTime

        else
            notify(option.." not implemented")
        end

    elseif category == "Teleport" and on then
        if option == "Teleport to Spawn" then
            teleportSpawn()

        elseif option == "Save Position 1" then
            savePosition("Position 1")

        elseif option == "Teleport Position 1" then
            teleportPosition("Position 1")

        elseif option == "Save Position 2" then
            savePosition("Position 2")

        elseif option == "Teleport Position 2" then
            teleportPosition("Position 2")
        end

        states[key] = false
    end
end

-- INPUT

local function matchesKey(input)
    if config.AimKey.EnumType == Enum.KeyCode then
        return input.KeyCode == config.AimKey
    end

    return input.UserInputType == config.AimKey
end

connect(UIS.InputBegan,function(input,processed)
    if rebinding then
        if input.UserInputType ==
            Enum.UserInputType.Keyboard and
            input.KeyCode ~= Enum.KeyCode.Unknown then

            config.AimKey = input.KeyCode
            config.AimKeyName = input.KeyCode.Name

        elseif input.UserInputType ==
            Enum.UserInputType.MouseButton2 or
            input.UserInputType ==
            Enum.UserInputType.MouseButton3 then

            config.AimKey = input.UserInputType
            config.AimKeyName =
                input.UserInputType.Name
        else
            return
        end

        rebinding = false
        aimHeld = false

        if keyButton and keyButton.Parent then
            keyButton.Text = config.AimKeyName
        end

        return
    end

    if matchesKey(input) and
        (not processed or input.UserInputType ==
        Enum.UserInputType.MouseButton2) then

        aimHeld = true
    end
end)

connect(UIS.InputEnded,function(input)
    if matchesKey(input) then
        aimHeld = false
        target = nil
    end
end)

-- MENU

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
        "Prediction",
        "Silent Aim",
        "Target Lock",
        "FOV Enabled",
        "Show FOV",
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
        "Save Position 1",
        "Teleport Position 1",
        "Save Position 2",
        "Teleport Position 2"
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

states["Combat:Prediction"] = true
states["Combat:FOV Enabled"] = true

local tabButtons = {}

local function addToggle(category,option,y)
    local row = frame(
        content,0,y,338,30,colors.row
    )
    corner(row,5)

    label(row,option,11,0,270,30,12)

    local button = make("TextButton",row,{
        Position = UDim2.fromOffset(293,5),
        Size = UDim2.fromOffset(41,20),
        Text = "",
        BorderSizePixel = 0
    })
    corner(button,12)

    local dot = frame(
        button,3,2,16,16,colors.white
    )
    corner(dot,10)

    local key = category..":"..option

    local function redraw()
        local enabled = states[key] == true

        button.BackgroundColor3 =
            enabled and colors.purple
            or Color3.fromRGB(56,60,70)

        dot.Position = UDim2.fromOffset(
            enabled and 22 or 3,
            2
        )
    end

    redraw()

    button.MouseButton1Click:Connect(function()
        applyFeature(
            category,
            option,
            not states[key]
        )
        redraw()
    end)
end

local function addSlider(
    title,y,minimum,maximum,get,set
)
    local row = frame(
        content,0,y,338,53,colors.row
    )
    corner(row,5)

    label(row,title,10,2,260,23,12)

    local number = label(
        row,"",275,2,53,23,12,colors.green
    )
    number.TextXAlignment =
        Enum.TextXAlignment.Right

    local track = frame(
        row,12,34,312,5,
        Color3.fromRGB(65,69,80)
    )
    corner(track,4)

    local fill = frame(
        track,0,0,0,5,colors.purple
    )
    corner(fill,4)

    local knob = frame(
        track,0,-5,15,15,colors.white
    )
    corner(knob,8)

    local dragging = false

    local function redraw()
        local value = get()
        local ratio =
            (value-minimum)/(maximum-minimum)

        fill.Size =
            UDim2.fromScale(ratio,1)

        knob.Position =
            UDim2.new(ratio,-7,-1,0)

        number.Text = tostring(value)
    end

    local function update(mouseX)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end

        local ratio = math.clamp(
            (mouseX-track.AbsolutePosition.X)/width,
            0,1
        )

        set(math.floor(
            minimum+(maximum-minimum)*ratio+.5
        ))

        redraw()
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true
            update(input.Position.X)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true
        end
    end)

    connect(UIS.InputChanged,function(input)
        if dragging and input.UserInputType ==
            Enum.UserInputType.MouseMovement then

            update(input.Position.X)
        end
    end)

    connect(UIS.InputEnded,function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = false
        end
    end)

    redraw()
end

local function addKeybind(y)
    local row = frame(
        content,0,y,338,39,colors.row
    )
    corner(row,5)

    label(row,"Aim Key",10,5,145,29,12)

    local button = make("TextButton",row,{
        Position = UDim2.fromOffset(165,5),
        Size = UDim2.fromOffset(160,29),
        BackgroundColor3 = colors.purple,
        BorderSizePixel = 0,
        Text = config.AimKeyName,
        TextColor3 = colors.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    })
    corner(button,5)

    keyButton = button

    button.MouseButton1Click:Connect(function()
        rebinding = true
        aimHeld = false
        button.Text = "Press a key..."
    end)
end

local function showPage(name)
    pageTitle.Text = name
    rebinding = false
    keyButton = nil

    for _,child in ipairs(content:GetChildren()) do
        child:Destroy()
    end

    for tab,button in pairs(tabButtons) do
        button.BackgroundColor3 =
            tab == name and colors.selected
            or colors.panel
    end

    local y = 0

    for _,option in ipairs(options[name] or {}) do
        addToggle(name,option,y)
        y += 33
    end

    if name == "Combat" then
        y += 6

        addSlider(
            "Smoothness",y,0,20,
            function()
                return config.Smoothness
            end,
            function(value)
                config.Smoothness = value
            end
        )
        y += 59

        addSlider(
            "FOV Size",y,20,400,
            function()
                return config.FOVSize
            end,
            function(value)
                config.FOVSize = value
            end
        )
        y += 59

        addSlider(
            "Bullet Speed",y,100,2000,
            function()
                return config.BulletSpeed
            end,
            function(value)
                config.BulletSpeed = value
            end
        )
        y += 59

        addSlider(
            "Gravity %",y,0,200,
            function()
                return config.GravityPercent
            end,
            function(value)
                config.GravityPercent = value
            end
        )
        y += 59

        addKeybind(y)
        y += 45
    end

    content.CanvasSize = UDim2.fromOffset(
        0,math.max(y,204)
    )
end

for i,item in ipairs(tabs) do
    local symbol,name = item[1],item[2]

    local button = make("TextButton",sidebar,{
        Position = UDim2.fromOffset(
            7,5+(i-1)*35
        ),
        Size = UDim2.fromOffset(132,31),
        BackgroundColor3 = colors.panel,
        BorderSizePixel = 0,
        Text = ""
    })
    corner(button,6)

    label(button,symbol,10,0,24,31,17)
    label(button,name,37,0,90,31,12)

    tabButtons[name] = button

    button.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- WINDOW CONTROL

local function headerButton(textValue,x,callback)
    local button = make("TextButton",header,{
        Position = UDim2.fromOffset(x,3),
        Size = UDim2.fromOffset(28,29),
        BackgroundTransparency = 1,
        Text = textValue,
        TextColor3 = colors.white,
        TextSize = 23
    })

    button.MouseButton1Click:Connect(callback)
end

local cleanup

cleanup = function()
    if not running then return end

    running = false

    RS:UnbindFromRenderStep(
        "AndriivkaHubV2"
    )

    clearESP()

    for _,connection in ipairs(connections) do
        connection:Disconnect()
    end

    Lighting.Brightness = originalLight.Brightness
    Lighting.Ambient = originalLight.Ambient
    Lighting.ClockTime = originalLight.ClockTime

    overlay:Destroy()
    gui:Destroy()

    if _G.AndriivkaHubCleanup == cleanup then
        _G.AndriivkaHubCleanup = nil
    end
end

_G.AndriivkaHubCleanup = cleanup

headerButton("×",711,cleanup)

local minimized = false

headerButton("−",680,function()
    minimized = not minimized

    main.Size = minimized
        and UDim2.fromOffset(760,44)
        or UDim2.fromOffset(760,320)

    sidebar.Visible = not minimized
    page.Visible = not minimized
    right.Visible = not minimized
end)

-- DRAG

local dragging = false
local dragStart
local windowStart

header.InputBegan:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        windowStart = main.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        dragging = false
    end
end)

connect(UIS.InputChanged,function(input)
    if dragging and input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local difference =
            input.Position-dragStart

        main.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset+difference.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset+difference.Y
        )
    end
end)

-- PLAYER EVENTS

local function watchPlayer(player)
    connect(player.CharacterAdded,function()
        task.wait(.4)

        if running then
            refreshESP()
        end
    end)

    connect(player.CharacterRemoving,function()
        task.defer(function()
            if running then
                refreshESP()
            end
        end)
    end)
end

for _,player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

connect(Players.PlayerAdded,function(player)
    watchPlayer(player)

    task.wait(.4)

    if running then
        refreshESP()
    end
end)

connect(Players.PlayerRemoving,function()
    task.defer(function()
        if running then
            refreshESP()
        end
    end)
end)

connect(LP.CharacterAdded,function()
    task.wait(.5)

    if running then
        updateMovement()
        refreshESP()
    end
end)

-- RENDER LOOP

RS:BindToRenderStep(
    "AndriivkaHubV2",
    Enum.RenderPriority.Camera.Value+1,
    function(dt)
        if not running then return end

        updateCircle()
        renderESP()
        updateAim(dt)
    end
)

showPage("Combat")
notify("Andriivka Hub V2 loaded")
