
-- BRONX STREETS HUB V4.3
-- Single-file menu
-- Gun Store / Bank teleport update

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
if not LP then return end

if game.GameId ~= 10763808155 then
    warn("Wrong GameId:",game.GameId)
    return
end

if _G.BronxHubCleanup then
    pcall(_G.BronxHubCleanup)
end

local pg = LP:WaitForChild("PlayerGui")
local connections = {}
local state = {}
local markers = {}
local visuals = {}
local savedPlaces = {}

local running = true
local aimHeld = false
local binding = false
local aimKey = Enum.UserInputType.MouseButton2
local aimKeyName = "Right Mouse"
local smoothness = 5
local fovRadius = 150

local oldLight = {
    brightness = Lighting.Brightness,
    ambient = Lighting.Ambient,
    clock = Lighting.ClockTime
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

local function connect(signal,fn)
    local c = signal:Connect(fn)
    table.insert(connections,c)
    return c
end

local function create(class,parent,properties)
    local obj = Instance.new(class)
    for k,v in pairs(properties or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function panel(parent,x,y,w,h,color)
    return create("Frame",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    })
end

local function round(obj,r)
    create("UICorner",obj,{
        CornerRadius = UDim.new(0,r)
    })
end

local function outline(obj,color,width)
    create("UIStroke",obj,{
        Color = color,
        Thickness = width or 1
    })
end

local function label(parent,s,x,y,w,h,size,color)
    return create("TextLabel",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1,
        Text = s,
        TextColor3 = color or C.white,
        TextSize = size,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

-- MAIN WINDOW

local gui = create("ScreenGui",pg,{
    Name = "BronxStreetsHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local overlay = create("ScreenGui",pg,{
    Name = "BronxStreetsOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50
})

local main = panel(gui,0,0,760,320,C.bg)
main.AnchorPoint = Vector2.new(.5,.5)
main.Position = UDim2.fromScale(.5,.43)
round(main,13)
outline(main,C.blue,1.6)

local scale = create("UIScale",main,{Scale=1})

local function resize()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local v = cam.ViewportSize
    scale.Scale = math.min(
        1,(v.X-20)/760,(v.Y-20)/320
    )
end

resize()

local header = panel(main,6,6,748,37,C.panel)
round(header,7)

label(header,
    "BRONX STREETS HUB | FREE 350K",
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

local content = create("ScrollingFrame",page,{
    Position = UDim2.fromOffset(12,41),
    Size = UDim2.fromOffset(346,204),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.blue,
    CanvasSize = UDim2.fromOffset(0,204)
})

local status = label(
    right,"Hub ready",6,225,186,28,10,C.muted
)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center

local function notify(message)
    status.Text = message
    print("[Bronx Hub]",message)
end

local logo1 = label(right,"BRONX",12,4,175,29,24)
logo1.TextXAlignment = Enum.TextXAlignment.Center
logo1.TextStrokeTransparency = 0

local logo2 = label(
    right,"STREETS",12,31,175,28,23,C.red
)
logo2.TextXAlignment = Enum.TextXAlignment.Center

local preview = label(
    right,"PLAYER PREVIEW",
    10,89,180,22,13,C.green
)
preview.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = panel(
    right,54,119,90,95,
    Color3.fromRGB(10,20,14)
)
outline(avatarBox,C.green,2)

local avatar = create("ImageLabel",avatarBox,{
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

-- FOV VISUAL

local circle = panel(overlay,0,0,300,300,C.purple)
circle.AnchorPoint = Vector2.new(.5,.5)
circle.BackgroundTransparency = 1
circle.Visible = false
create("UICorner",circle,{
    CornerRadius = UDim.new(1,0)
})
outline(circle,C.purple,2)

local function updateFOV()
    local m = UIS:GetMouseLocation()
    circle.Position = UDim2.fromOffset(m.X,m.Y)
    circle.Size = UDim2.fromOffset(
        fovRadius*2,fovRadius*2
    )
    circle.Visible =
        state["Combat:Show FOV"] == true
end

-- ESP SKELETON DEFINITIONS

local r15Bones = {
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

local r6Bones = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function isTarget(p)
    if p == LP then return false end

    if state["ESP:Team Check (Enemy Only)"] then
        if LP.Team and p.Team then
            return LP.Team ~= p.Team
        end
    end

    return true
end

local function makeLine()
    local f = panel(overlay,0,0,0,2,C.green)
    f.Visible = false
    table.insert(markers,f)
    return f
end

local function drawLine(f,a,b)
    local d = b-a
    local length = d.Magnitude

    f.Position = UDim2.fromOffset(
        (a.X+b.X-length)/2,
        (a.Y+b.Y-2)/2
    )
    f.Size = UDim2.fromOffset(length,2)
    f.Rotation = math.deg(math.atan2(d.Y,d.X))
    f.Visible = length > 0
end

local function clearESP()
    for _,obj in ipairs(markers) do
        obj:Destroy()
    end
    table.clear(markers)
    table.clear(visuals)
end

local function refreshESP()
    clearESP()

    for _,p in ipairs(Players:GetPlayers()) do
        if isTarget(p) and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass(
                "Humanoid"
            )
            local head = char:FindFirstChild("Head")

            if hum and head and hum.Health > 0 then
                local v = {
                    player = p,
                    character = char
                }

                if state["ESP:Player ESP"] then
                    local h = create("Highlight",char,{
                        Name = "BronxESP",
                        Adornee = char,
                        FillColor = C.red,
                        FillTransparency = .65,
                        OutlineColor = C.green,
                        DepthMode =
                            Enum.HighlightDepthMode.AlwaysOnTop
                    })
                    table.insert(markers,h)
                end

                if state["ESP:Boxes"] then
                    v.box = {
                        makeLine(),
                        makeLine(),
                        makeLine(),
                        makeLine()
                    }
                end

                if state["ESP:Skeleton"] then
                    v.bones = {}

                    local boneList =
                        hum.RigType ==
                        Enum.HumanoidRigType.R15
                        and r15Bones or r6Bones

                    for _,pair in ipairs(boneList) do
                        table.insert(v.bones,{
                            pair[1],pair[2],makeLine()
                        })
                    end
                end

                if state["ESP:Name"] or
                    state["ESP:Distance"] then

                    local bb = create("BillboardGui",pg,{
                        Adornee = head,
                        Size = UDim2.fromOffset(170,40),
                        StudsOffset = Vector3.new(0,3,0),
                        AlwaysOnTop = true
                    })

                    v.info = label(
                        bb,"",0,0,170,40,12,C.green
                    )
                    v.info.TextXAlignment =
                        Enum.TextXAlignment.Center
                    v.info.TextStrokeTransparency = .2
                    table.insert(markers,bb)
                end

                table.insert(visuals,v)
            end
        end
    end
end

local function hideESP(v)
    for _,edge in ipairs(v.box or {}) do
        edge.Visible = false
    end

    for _,bone in ipairs(v.bones or {}) do
        bone[3].Visible = false
    end
end

local function renderESP()
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _,v in ipairs(visuals) do
        local char = v.character
        local hum = char:FindFirstChildOfClass(
            "Humanoid"
        )
        local root = char:FindFirstChild(
            "HumanoidRootPart"
        )

        if not hum or hum.Health <= 0
            or not root or not isTarget(v.player) then

            hideESP(v)
            if v.info then v.info.Text = "" end
        else
            local center,visible =
                cam:WorldToViewportPoint(root.Position)

            if not visible or center.Z <= 0 then
                hideESP(v)
            else
                if v.box then
                    local top = cam:WorldToViewportPoint(
                        root.Position+Vector3.new(0,3,0)
                    )
                    local bottom = cam:WorldToViewportPoint(
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
                    local p1 = char:FindFirstChild(bone[1])
                    local p2 = char:FindFirstChild(bone[2])

                    if p1 and p2 then
                        local a,va =
                            cam:WorldToViewportPoint(p1.Position)
                        local b,vb =
                            cam:WorldToViewportPoint(p2.Position)

                        if va and vb and a.Z > 0
                            and b.Z > 0 then

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

                if state["ESP:Name"] then
                    table.insert(
                        parts,v.player.DisplayName
                    )
                end

                if state["ESP:Distance"] then
                    local myRoot =
                        LP.Character and
                        LP.Character:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if myRoot then
                        local d = (
                            myRoot.Position-root.Position
                        ).Magnitude

                        table.insert(
                            parts,
                            string.format("%.0fm",d)
                        )
                    end
                end

                v.info.Text = table.concat(parts," | ")
            end
        end
    end
end

-- CAMERA AIM CONTROLS

local function insideFOV(position)
    local cam = workspace.CurrentCamera
    if not cam then return false end

    local point,onScreen =
        cam:WorldToViewportPoint(position)

    if not onScreen or point.Z <= 0 then
        return false
    end

    local mouse = UIS:GetMouseLocation()
    local distance = (
        Vector2.new(point.X,point.Y)-mouse
    ).Magnitude

    return distance <= fovRadius,distance
end

local function visibleTarget(char,position)
    if not state["Combat:Wall Check"] then
        return true
    end

    local cam = workspace.CurrentCamera
    if not cam then return false end

    local params = RaycastParams.new()
    params.FilterType =
        Enum.RaycastFilterType.Exclude

    params.FilterDescendantsInstances =
        LP.Character and {LP.Character} or {}

    local origin = cam.CFrame.Position
    local hit = workspace:Raycast(
        origin,position-origin,params
    )

    return hit == nil or
        hit.Instance:IsDescendantOf(char)
end

local function acquireTarget()
    local best = nil
    local bestDist = math.huge

    for _,p in ipairs(Players:GetPlayers()) do
        if isTarget(p) and p.Character then
            local char = p.Character
            local hum =
                char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local inside,distance =
                    insideFOV(head.Position)

                if inside
                    and distance < bestDist
                    and visibleTarget(
                        char,head.Position
                    ) then

                    best = p
                    bestDist = distance
                end
            end
        end
    end

    return best
end

local function updateAim(dt)
    if not state["Combat:Aimbot"]
        or not aimHeld then
        return
    end

    local target = acquireTarget()
    if not target or not target.Character then
        return
    end

    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    if not insideFOV(head.Position) then
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local current = cam.CFrame
    local desired = CFrame.lookAt(
        current.Position,
        head.Position
    )

    if smoothness == 0 then
        cam.CFrame = desired
    else
        local speed = 30/(1+smoothness*3)
        local alpha = 1-math.exp(-speed*dt)
        cam.CFrame = current:Lerp(desired,alpha)
    end
end

-- UPDATED TELEPORT SYSTEM
-- First attempts an automatic lookup.
-- Saved coordinates provide a fallback.

local destinationNames = {
    ["Gun Store"] = {
        "Gun Store",
        "GunStore",
        "Gun Store Spawn",
        "GunStoreSpawn",
        "Gun Store Entrance"
    },

    ["Bank"] = {
        "Bank",
        "BankSpawn",
        "Bank Spawn",
        "Bank Entrance",
        "MainBank",
        "BigBank"
    }
}

local function normalizeName(s)
    return string.lower(
        string.gsub(s,"[^%w]","")
    )
end

local function getRoot()
    local char = LP.Character
    return char and
        char:FindFirstChild("HumanoidRootPart")
end

local function savePlace(name)
    local root = getRoot()

    if not root then
        notify("Character not found")
        return
    end

    savedPlaces[name] = root.CFrame
    notify(name.." saved")
end

local function findPlace(name)
    local names = destinationNames[name]
    if not names then return nil end

    local best = nil
    local bestScore = 0

    for _,obj in ipairs(
        workspace:GetDescendants()
    ) do
        if obj:IsA("BasePart")
            or obj:IsA("Model") then

            local objectName =
                normalizeName(obj.Name)

            for _,wanted in ipairs(names) do
                local wantedName =
                    normalizeName(wanted)

                local score = 0

                if objectName == wantedName then
                    score = 100
                elseif #wantedName >= 5
                    and string.find(
                        objectName,
                        wantedName,
                        1,
                        true
                    ) then

                    score = 35
                end

                if score > bestScore then
                    best = obj
                    bestScore = score
                end
            end
        end
    end

    return best
end

local function destinationCFrame(obj)
    if obj:IsA("Model") then
        local pivot = obj:GetPivot()
        local _,size = obj:GetBoundingBox()

        return CFrame.new(
            pivot.Position +
            Vector3.new(0,size.Y/2+5,0)
        )
    end

    return CFrame.new(
        obj.Position +
        Vector3.new(0,obj.Size.Y/2+5,0)
    )
end

local function teleportTo(name)
    local char = LP.Character
    local root = getRoot()

    if not char or not root then
        notify("Character not ready")
        return
    end

    local destination = savedPlaces[name]

    if not destination then
        local obj = findPlace(name)

        if obj then
            destination = destinationCFrame(obj)
        end
    end

    if not destination then
        notify(name.." not found. Save it first.")
        return
    end

    char:PivotTo(destination)
    notify("Teleport attempted: "..name)
end

local function teleportSpawn()
    local char = LP.Character

    local spawn =
        workspace:FindFirstChildWhichIsA(
            "SpawnLocation",true
        )

    if not spawn or not char then
        notify("Spawn not found")
        return
    end

    char:PivotTo(
        spawn.CFrame*CFrame.new(0,4,0)
    )
    notify("Spawn teleport attempted")
end

-- PLAYER MOVEMENT

local function getHumanoid()
    local char = LP.Character

    return char and
        char:FindFirstChildOfClass("Humanoid")
end

local function updateMovement()
    local hum = getHumanoid()
    if not hum then return end

    hum.WalkSpeed =
        state["Player:Speed"] and 28 or 16

    hum.UseJumpPower = true
    hum.JumpPower =
        state["Player:High Jump"] and 85 or 50
end

connect(UIS.JumpRequest,function()
    if state["Player:Infinite Jump"] then
        local hum = getHumanoid()

        if hum then
            hum:ChangeState(
                Enum.HumanoidStateType.Jumping
            )
        end
    end
end)

connect(LP.CharacterAdded,function()
    task.wait(.5)

    if running then
        updateMovement()
        refreshESP()
    end
end)

-- FEATURE CONTROLLER

local function applyFeature(category,option,on)
    local key = category..":"..option
    state[key] = on

    if category == "ESP" then
        refreshESP()

    elseif category == "Combat" then
        if option == "Silent Aim" then
            notify("Silent Aim not connected yet")
        end

    elseif category == "Player" then
        if option == "Speed"
            or option == "High Jump" then

            updateMovement()

        elseif option ~= "Infinite Jump" then
            notify(option.." needs game integration")
        end

    elseif category == "Misc" then
        if option == "Full Bright" then
            Lighting.Brightness =
                on and 5 or oldLight.brightness

            Lighting.Ambient =
                on and Color3.new(1,1,1)
                or oldLight.ambient

        elseif option == "Day Mode" then
            Lighting.ClockTime =
                on and 12 or oldLight.clock

        elseif option == "Night Mode" then
            Lighting.ClockTime =
                on and 0 or oldLight.clock
        else
            notify(option.." not connected")
        end

    elseif category == "Teleport" then
        if not on then return end

        if option == "Teleport to Spawn" then
            teleportSpawn()

        elseif option == "Teleport to Gun Store" then
            teleportTo("Gun Store")

        elseif option == "Teleport to Bank" then
            teleportTo("Bank")

        elseif option == "Save Gun Store Here" then
            savePlace("Gun Store")

        elseif option == "Save Bank Here" then
            savePlace("Bank")
        end

        -- Teleport actions are momentary,
        -- not persistent toggle states.
        state[key] = false
    end
end

-- AIM KEY BINDING

local function matchesKey(input)
    if aimKey.EnumType == Enum.KeyCode then
        return input.KeyCode == aimKey
    end

    return input.UserInputType == aimKey
end

local keyButton = nil

connect(UIS.InputBegan,function(input,processed)
    if binding then
        if input.UserInputType ==
            Enum.UserInputType.Keyboard
            and input.KeyCode ~=
            Enum.KeyCode.Unknown then

            aimKey = input.KeyCode
            aimKeyName = input.KeyCode.Name

        elseif input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.MouseButton2
            or input.UserInputType ==
            Enum.UserInputType.MouseButton3 then

            aimKey = input.UserInputType
            aimKeyName = input.UserInputType.Name
        else
            return
        end

        binding = false
        aimHeld = false

        if keyButton and keyButton.Parent then
            keyButton.Text = aimKeyName
        end
        return
    end

    if not processed and matchesKey(input) then
        aimHeld = true
    end
end)

connect(UIS.InputEnded,function(input)
    if matchesKey(input) then
        aimHeld = false
    end
end)

-- TABS

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
        "Teleport to Gun Store",
        "Teleport to Bank",
        "Save Gun Store Here",
        "Save Bank Here"
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
    local row = panel(
        content,0,y,338,30,C.row
    )
    round(row,5)

    label(row,option,11,0,270,30,12)

    local b = create("TextButton",row,{
        Position = UDim2.fromOffset(293,5),
        Size = UDim2.fromOffset(41,20),
        Text = "",
        BorderSizePixel = 0
    })
    round(b,12)

    local dot = panel(
        b,3,2,16,16,C.white
    )
    round(dot,10)

    local key = category..":"..option

    local function redraw()
        local on = state[key] == true

        b.BackgroundColor3 =
            on and C.purple
            or Color3.fromRGB(56,60,70)

        dot.Position = UDim2.fromOffset(
            on and 22 or 3,2
        )
    end

    redraw()

    b.MouseButton1Click:Connect(function()
        applyFeature(
            category,
            option,
            not state[key]
        )
        redraw()
    end)
end

local function makeSlider(name,y,min,max,get,set)
    local row = panel(
        content,0,y,338,53,C.row
    )
    round(row,5)

    label(row,name,10,2,260,23,12)

    local value = label(
        row,"",282,2,46,23,12,C.green
    )
    value.TextXAlignment =
        Enum.TextXAlignment.Right

    local track = panel(
        row,12,34,312,5,
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
        local v = get()
        local ratio =
            (v-min)/(max-min)

        fill.Size =
            UDim2.fromScale(ratio,1)

        knob.Position =
            UDim2.new(ratio,-7,-1,0)

        value.Text = tostring(v)
    end

    local dragging = false

    local function update(x)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end

        local ratio = math.clamp(
            (x-track.AbsolutePosition.X)
            /width,
            0,
            1
        )

        set(math.floor(
            min+(max-min)*ratio+.5
        ))

        redraw()
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true
            update(input.Position.X)
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

local function makeKeybind(y)
    local row = panel(
        content,0,y,338,39,C.row
    )
    round(row,5)

    label(row,"Aim Key",10,5,145,29,12)

    local b = create("TextButton",row,{
        Position = UDim2.fromOffset(165,5),
        Size = UDim2.fromOffset(160,29),
        BackgroundColor3 = C.purple,
        BorderSizePixel = 0,
        Text = aimKeyName,
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    })
    round(b,5)

    keyButton = b

    b.MouseButton1Click:Connect(function()
        binding = true
        aimHeld = false
        b.Text = "Press a key..."
    end)
end

local function showPage(name)
    pageTitle.Text = name
    binding = false
    keyButton = nil

    for _,child in ipairs(
        content:GetChildren()
    ) do
        child:Destroy()
    end

    for tab,b in pairs(tabButtons) do
        b.BackgroundColor3 =
            tab == name
            and C.selected
            or C.panel
    end

    local y = 0

    for _,option in ipairs(
        options[name] or {}
    ) do
        makeToggle(name,option,y)
        y += 33
    end

    if name == "Combat" then
        y += 6

        makeSlider(
            "Smoothness",
            y,0,20,
            function()
                return smoothness
            end,
            function(v)
                smoothness = v
            end
        )

        y += 59

        makeSlider(
            "FOV Size",
            y,20,400,
            function()
                return fovRadius
            end,
            function(v)
                fovRadius = v
            end
        )

        y += 59
        makeKeybind(y)
        y += 45
    end

    content.CanvasSize =
        UDim2.fromOffset(
            0,
            math.max(y,204)
        )
end

for i,item in ipairs(tabs) do
    local symbol,name =
        item[1],item[2]

    local b = create("TextButton",side,{
        Position = UDim2.fromOffset(
            7,5+(i-1)*35
        ),
        Size = UDim2.fromOffset(132,31),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Text = ""
    })
    round(b,6)

    label(b,symbol,10,0,24,31,17)
    label(b,name,37,0,90,31,12)

    tabButtons[name] = b

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- WINDOW CONTROLS

local function headerButton(symbol,x,callback)
    local b = create("TextButton",header,{
        Position = UDim2.fromOffset(x,3),
        Size = UDim2.fromOffset(28,29),
        BackgroundTransparency = 1,
        Text = symbol,
        TextColor3 = C.white,
        TextSize = 23
    })

    b.MouseButton1Click:Connect(callback)
end

local function cleanup()
    if not running then return end
    running = false

    RS:UnbindFromRenderStep("BronxHubV43")
    clearESP()

    for _,c in ipairs(connections) do
        c:Disconnect()
    end

    overlay:Destroy()
    gui:Destroy()
end

_G.BronxHubCleanup = cleanup

headerButton("×",711,cleanup)

local minimized = false

headerButton("−",680,function()
    minimized = not minimized

    main.Size = minimized and
        UDim2.fromOffset(760,44)
        or UDim2.fromOffset(760,320)

    side.Visible = not minimized
    page.Visible = not minimized
    right.Visible = not minimized
end)

local dragging = false
local dragStart,windowStart

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

        local d = input.Position-dragStart

        main.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset+d.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset+d.Y
        )
    end
end)

-- PLAYER UPDATES

local function watchPlayer(p)
    connect(p.CharacterAdded,function()
        task.wait(.4)
        if running then refreshESP() end
    end)

    connect(p.CharacterRemoving,function()
        task.defer(function()
            if running then refreshESP() end
        end)
    end)
end

for _,p in ipairs(
    Players:GetPlayers()
) do
    watchPlayer(p)
end

connect(Players.PlayerAdded,function(p)
    watchPlayer(p)
    task.wait(.4)

    if running then
        refreshESP()
    end
end)

connect(Players.PlayerRemoving,function()
    task.defer(function()
        if running then refreshESP() end
    end)
end)

-- RENDER

RS:BindToRenderStep(
    "BronxHubV43",
    Enum.RenderPriority.Camera.Value+1,
    function(dt)
        if not running then return end

        updateFOV()
        renderESP()
        updateAim(dt)
    end
)

showPage("Teleport")
notify("Bronx Streets Hub V4.3 loaded")
