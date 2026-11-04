
-- BRONX STREETS HUB V4.1
-- Complete menu / corrected FOV targeting

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

if not LP then return end
if game.GameId ~= 10763808155 then
    warn("Incorrect GameId:",game.GameId)
    return
end

-- Clean up an earlier execution
if _G.BronxHubCleanup then
    pcall(_G.BronxHubCleanup)
end

local pg = LP:WaitForChild("PlayerGui")
local links = {}
local drawings = {}
local state = {}
local targets = {}
local alive = true
local held = false
local binding = false
local selectedKey = Enum.UserInputType.MouseButton2
local keyName = "Right Mouse"
local smoothness = 5
local fovRadius = 150
local selectedPage = "ESP"
local activeSlider = nil
local oldLight = {
    brightness = Lighting.Brightness,
    ambient = Lighting.Ambient,
    clock = Lighting.ClockTime
}

local color = {
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

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(links,c)
    return c
end

local function ui(class,parent,props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(obj,r)
    ui("UICorner",obj,{
        CornerRadius = UDim.new(0,r)
    })
end

local function panel(parent,x,y,w,h,c)
    return ui("Frame",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = c,
        BorderSizePixel = 0
    })
end

local function text(parent,s,x,y,w,h,size,c)
    return ui("TextLabel",parent,{
        Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1,
        Text = s,
        TextColor3 = c or color.white,
        TextSize = size,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

local function outline(obj,c,width)
    ui("UIStroke",obj,{
        Color = c,
        Thickness = width or 1
    })
end

-- Main interface
local gui = ui("ScreenGui",pg,{
    Name = "BronxStreetsHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local overlay = ui("ScreenGui",pg,{
    Name = "BronxStreetsOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50
})

local main = panel(gui,0,0,760,320,color.bg)
main.AnchorPoint = Vector2.new(.5,.5)
main.Position = UDim2.fromScale(.5,.43)
round(main,13)
outline(main,color.blue,1.6)

local scale = ui("UIScale",main,{Scale=1})
local function resize()
    local cam = workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        scale.Scale = math.min(
            1,(v.X-20)/760,(v.Y-20)/320
        )
    end
end
resize()

local header = panel(main,6,6,748,37,color.panel)
round(header,7)
text(header,"BRONX STREETS HUB | FREE 350K",
    12,1,610,34,18)

local sidebar = panel(main,12,51,146,256,color.panel)
round(sidebar,9)

local page = panel(main,170,51,370,256,color.panel)
round(page,9)

local right = panel(main,550,51,198,256,color.bg)
round(right,9)

local pageTitle = text(page,"ESP",15,7,320,26,17)

local content = ui("ScrollingFrame",page,{
    Position = UDim2.fromOffset(12,41),
    Size = UDim2.fromOffset(346,204),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = color.blue,
    CanvasSize = UDim2.fromOffset(0,204)
})

local status = text(right,"Hub ready",
    6,225,186,28,10,color.muted)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center

local function notify(message)
    status.Text = message
    print("[Bronx Hub]",message)
end

local logo1 = text(right,"BRONX",12,4,175,29,24)
logo1.TextXAlignment = Enum.TextXAlignment.Center
logo1.TextStrokeTransparency = 0

local logo2 = text(right,"STREETS",
    12,31,175,28,23,color.red)
logo2.TextXAlignment = Enum.TextXAlignment.Center

local previewLabel = text(right,
    "PLAYER PREVIEW",10,89,180,22,13,color.green)
previewLabel.TextXAlignment = Enum.TextXAlignment.Center

local avatarBox = panel(right,54,119,90,95,
    Color3.fromRGB(10,20,14))
outline(avatarBox,color.green,2)

local avatar = ui("ImageLabel",avatarBox,{
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
    if ok and alive then avatar.Image = url end
end)

-- FOV ring, independent of the FOV restriction
local circle = panel(overlay,0,0,300,300,color.purple)
circle.AnchorPoint = Vector2.new(.5,.5)
circle.BackgroundTransparency = 1
circle.Visible = false
ui("UICorner",circle,{
    CornerRadius = UDim.new(1,0)
})
outline(circle,color.purple,2)

local function updateCircle()
    local m = UIS:GetMouseLocation()
    circle.Position = UDim2.fromOffset(m.X,m.Y)
    circle.Size = UDim2.fromOffset(
        fovRadius*2,fovRadius*2
    )
    circle.Visible = state["Combat:Show FOV"] == true
end

-- ESP rendering
local bonesR15 = {
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

local bonesR6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function enemy(p)
    if p == LP then return false end
    if state["ESP:Team Check (Enemy Only)"] then
        if LP.Team and p.Team then
            return LP.Team ~= p.Team
        end
    end
    return true
end

local function line()
    local f = panel(overlay,0,0,0,2,color.green)
    f.Visible = false
    table.insert(drawings,f)
    return f
end

local function drawLine(f,a,b)
    local d = b-a
    local len = d.Magnitude
    f.Position = UDim2.fromOffset(
        (a.X+b.X-len)/2,
        (a.Y+b.Y-2)/2
    )
    f.Size = UDim2.fromOffset(len,2)
    f.Rotation = math.deg(math.atan2(d.Y,d.X))
    f.Visible = len > 0
end

local function clearESP()
    for _,o in ipairs(drawings) do
        o:Destroy()
    end
    table.clear(drawings)
    table.clear(targets)
end

local function refreshESP()
    clearESP()

    for _,p in ipairs(Players:GetPlayers()) do
        if enemy(p) and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")

            if hum and head and hum.Health > 0 then
                local v = {p=p,char=char}

                if state["ESP:Player ESP"] then
                    local h = ui("Highlight",char,{
                        Name = "BronxESP",
                        Adornee = char,
                        FillColor = color.red,
                        FillTransparency = .65,
                        OutlineColor = color.green,
                        DepthMode =
                            Enum.HighlightDepthMode.AlwaysOnTop
                    })
                    table.insert(drawings,h)
                end

                if state["ESP:Boxes"] then
                    v.box = {line(),line(),line(),line()}
                end

                if state["ESP:Skeleton"] then
                    v.bones = {}
                    local rig = hum.RigType ==
                        Enum.HumanoidRigType.R15
                        and bonesR15 or bonesR6

                    for _,pair in ipairs(rig) do
                        table.insert(v.bones,{
                            pair[1],pair[2],line()
                        })
                    end
                end

                if state["ESP:Name"] or
                    state["ESP:Distance"] then
                    local bb = ui("BillboardGui",pg,{
                        Adornee = head,
                        Size = UDim2.fromOffset(170,40),
                        StudsOffset = Vector3.new(0,3,0),
                        AlwaysOnTop = true
                    })
                    v.info = text(bb,"",0,0,
                        170,40,12,color.green)
                    v.info.TextXAlignment =
                        Enum.TextXAlignment.Center
                    v.info.TextStrokeTransparency = .2
                    table.insert(drawings,bb)
                end

                table.insert(targets,v)
            end
        end
    end
end

local function hideVisual(v)
    for _,edge in ipairs(v.box or {}) do
        edge.Visible = false
    end
    for _,bone in ipairs(v.bones or {}) do
        bone[3].Visible = false
    end
end

local function renderESP()
    local camera = workspace.CurrentCamera
    if not camera then return end

    for _,v in ipairs(targets) do
        local char = v.char
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        if not hum or hum.Health <= 0
            or not root or not enemy(v.p) then
            hideVisual(v)
            if v.info then v.info.Text = "" end
        else
            local center,visible =
                camera:WorldToViewportPoint(root.Position)

            if not visible or center.Z <= 0 then
                hideVisual(v)
            else
                if v.box then
                    local top = camera:WorldToViewportPoint(
                        root.Position+Vector3.new(0,3,0))
                    local bottom = camera:WorldToViewportPoint(
                        root.Position-Vector3.new(0,3,0))

                    local h = math.clamp(
                        math.abs(bottom.Y-top.Y),8,2000)
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
                            camera:WorldToViewportPoint(p1.Position)
                        local b,vb =
                            camera:WorldToViewportPoint(p2.Position)
                        if va and vb and a.Z>0 and b.Z>0 then
                            drawLine(bone[3],
                                Vector2.new(a.X,a.Y),
                                Vector2.new(b.X,b.Y))
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
                    table.insert(parts,v.p.DisplayName)
                end
                if state["ESP:Distance"] then
                    local myRoot = LP.Character and
                        LP.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local dist =
                            (myRoot.Position-root.Position).Magnitude
                        table.insert(parts,
                            string.format("%.0fm",dist))
                    end
                end
                v.info.Text = table.concat(parts," | ")
            end
        end
    end
end

-- Aim targeting: targets MUST be inside the FOV
local lockedTarget = nil

local function visibleTarget(char,position)
    if not state["Combat:Wall Check"] then
        return true
    end
    local cam = workspace.CurrentCamera
    if not cam then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances =
        LP.Character and {LP.Character} or {}

    local origin = cam.CFrame.Position
    local result = workspace:Raycast(
        origin,position-origin,params)

    return result == nil or
        result.Instance:IsDescendantOf(char)
end

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

local function acquireTarget()
    local best = nil
    local bestDistance = math.huge

    for _,p in ipairs(Players:GetPlayers()) do
        if enemy(p) and p.Character then
            local char = p.Character
            local hum =
                char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local within,dist = insideFOV(head.Position)

                if within and dist < bestDistance and
                    visibleTarget(char,head.Position) then
                    best = p
                    bestDistance = dist
                end
            end
        end
    end

    return best
end

local function updateAim(dt)
    if not state["Combat:Aimbot"] or not held then
        lockedTarget = nil
        return
    end

    -- Re-evaluate targets each frame.
    -- No target outside the circle can be selected.
    lockedTarget = acquireTarget()
    if not lockedTarget then return end

    local char = lockedTarget.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    -- Final safety check before moving camera
    if not insideFOV(head.Position) then
        lockedTarget = nil
        return
    end

    if not visibleTarget(char,head.Position) then
        lockedTarget = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local current = camera.CFrame
    local desired = CFrame.lookAt(
        current.Position,head.Position)

    if smoothness == 0 then
        camera.CFrame = desired
    else
        local speed = 30/(1+smoothness*3)
        local alpha = 1-math.exp(-speed*dt)
        camera.CFrame = current:Lerp(desired,alpha)
    end
end

-- Movement and lighting
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
        local h = getHumanoid()
        if h then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

connect(LP.CharacterAdded,function()
    task.wait(.5)
    if alive then
        updateMovement()
        refreshESP()
    end
end)

local function applyFeature(category,option,on)
    local key = category..":"..option
    state[key] = on

    if category == "ESP" then
        refreshESP()

    elseif category == "Combat" then
        if option == "Aimbot" and not on then
            lockedTarget = nil
        elseif option == "Silent Aim" then
            notify("Silent Aim not connected yet")
        end

    elseif category == "Player" then
        if option=="Speed" or option=="High Jump" then
            updateMovement()
        elseif option ~= "Infinite Jump" then
            notify(option.." needs server integration")
        end

    elseif category == "Misc" then
        if option == "Full Bright" then
            Lighting.Brightness =
                on and 5 or oldLight.brightness
            Lighting.Ambient =
                on and Color3.new(1,1,1)
                or oldLight.ambient
        elseif option == "Day Mode" then
            Lighting.ClockTime = on and 12 or oldLight.clock
        elseif option == "Night Mode" then
            Lighting.ClockTime = on and 0 or oldLight.clock
        else
            notify(option.." not connected")
        end

    elseif category == "Teleport" and on then
        if option == "Teleport to Spawn" then
            local spawn = workspace:FindFirstChildWhichIsA(
                "SpawnLocation",true)
            local root = LP.Character and
                LP.Character:FindFirstChild("HumanoidRootPart")
            if spawn and root then
                root.CFrame =
                    spawn.CFrame*CFrame.new(0,4,0)
            else
                notify("Spawn not found")
            end
        else
            notify("Destination not configured")
        end
    end
end

-- Input and key selection
local function matchesKey(input)
    if selectedKey.EnumType == Enum.KeyCode then
        return input.KeyCode == selectedKey
    end
    return input.UserInputType == selectedKey
end

local keyButton = nil

connect(UIS.InputBegan,function(input,processed)
    if binding then
        if input.UserInputType ==
            Enum.UserInputType.Keyboard and
            input.KeyCode ~= Enum.KeyCode.Unknown then
            selectedKey = input.KeyCode
            keyName = input.KeyCode.Name
        elseif input.UserInputType ==
            Enum.UserInputType.MouseButton1 or
            input.UserInputType ==
            Enum.UserInputType.MouseButton2 or
            input.UserInputType ==
            Enum.UserInputType.MouseButton3 then
            selectedKey = input.UserInputType
            keyName = input.UserInputType.Name
        else
            return
        end
        binding = false
        held = false
        if keyButton and keyButton.Parent then
            keyButton.Text = keyName
        end
        return
    end

    if not processed and matchesKey(input) then
        held = true
    end
end)

connect(UIS.InputEnded,function(input)
    if matchesKey(input) then
        held = false
        lockedTarget = nil
    end
end)

-- Tabs and controls
local tabs = {
    {"⌂","Home"},{"⚔","Combat"},{"◉","ESP"},
    {"♟","Player"},{"⌖","Teleport"},
    {"⚒","Misc"},{"⚙","Settings"}
}

local options = {
    Home = {"Enable Hub","Show Player Info","Enable Effects"},
    Combat = {"Aimbot","Silent Aim","Target Lock",
        "FOV Enabled","Show FOV","Wall Check"},
    ESP = {"Player ESP","Name","Distance",
        "Boxes","Skeleton","Team Check (Enemy Only)"},
    Player = {"Speed","High Jump","Infinite Jump",
        "No Stamina","Anti Fall Damage"},
    Teleport = {"Teleport to Spawn","Teleport to Shop",
        "Teleport to Bank","Custom Location"},
    Misc = {"Full Bright","Day Mode","Night Mode","FPS Boost"},
    Settings = {"Show Notifications","Save Settings",
        "Enable Keybinds"}
}

local tabButtons = {}

local function makeToggle(category,option,y)
    local row = panel(content,0,y,338,30,color.row)
    round(row,5)
    text(row,option,11,0,270,30,12)

    local b = ui("TextButton",row,{
        Position = UDim2.fromOffset(293,5),
        Size = UDim2.fromOffset(41,20),
        Text = "",
        BorderSizePixel = 0
    })
    round(b,12)

    local dot = panel(b,3,2,16,16,color.white)
    round(dot,10)

    local key = category..":"..option

    local function redraw()
        local on = state[key] == true
        b.BackgroundColor3 =
            on and color.purple
            or Color3.fromRGB(56,60,70)
        dot.Position =
            UDim2.fromOffset(on and 22 or 3,2)
    end

    redraw()
    b.MouseButton1Click:Connect(function()
        applyFeature(category,option,not state[key])
        redraw()
    end)
end

local function makeSlider(name,y,min,max,get,set)
    local row = panel(content,0,y,338,53,color.row)
    round(row,5)
    text(row,name,10,2,260,23,12)

    local value = text(row,"",282,2,46,23,12,color.green)
    value.TextXAlignment = Enum.TextXAlignment.Right

    local track = panel(row,12,34,312,5,
        Color3.fromRGB(65,69,80))
    round(track,4)
    local fill = panel(track,0,0,0,5,color.purple)
    round(fill,4)
    local knob = panel(track,0,-5,15,15,color.white)
    round(knob,8)

    local function redraw()
        local v = get()
        local ratio = (v-min)/(max-min)
        fill.Size = UDim2.fromScale(ratio,1)
        knob.Position = UDim2.new(ratio,-7,-1,0)
        value.Text = tostring(v)
    end

    local dragging = false
    local function update(x)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local ratio = math.clamp(
            (x-track.AbsolutePosition.X)/width,0,1)
        set(math.floor(min+(max-min)*ratio+.5))
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
    local row = panel(content,0,y,338,39,color.row)
    round(row,5)
    text(row,"Aim Key",10,5,145,29,12)

    local b = ui("TextButton",row,{
        Position = UDim2.fromOffset(165,5),
        Size = UDim2.fromOffset(160,29),
        BackgroundColor3 = color.purple,
        BorderSizePixel = 0,
        Text = keyName,
        TextColor3 = color.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    })
    round(b,5)
    keyButton = b

    b.MouseButton1Click:Connect(function()
        binding = true
        held = false
        b.Text = "Press a key..."
    end)
end

local function showPage(name)
    selectedPage = name
    pageTitle.Text = name
    binding = false
    keyButton = nil

    for _,child in ipairs(content:GetChildren()) do
        child:Destroy()
    end

    for tab,b in pairs(tabButtons) do
        b.BackgroundColor3 =
            tab == name and color.selected or color.panel
    end

    local y = 0
    for _,option in ipairs(options[name] or {}) do
        makeToggle(name,option,y)
        y += 33
    end

    if name == "Combat" then
        y += 6
        makeSlider("Smoothness",y,0,20,
            function() return smoothness end,
            function(v) smoothness = v end)
        y += 59

        makeSlider("FOV Size",y,20,400,
            function() return fovRadius end,
            function(v) fovRadius = v end)
        y += 59

        makeKeybind(y)
        y += 45
    end

    content.CanvasSize =
        UDim2.fromOffset(0,math.max(y,204))
end

for i,item in ipairs(tabs) do
    local symbol,name = item[1],item[2]
    local b = ui("TextButton",sidebar,{
        Position = UDim2.fromOffset(7,5+(i-1)*35),
        Size = UDim2.fromOffset(132,31),
        BackgroundColor3 = color.panel,
        BorderSizePixel = 0,
        Text = ""
    })
    round(b,6)
    text(b,symbol,10,0,24,31,17)
    text(b,name,37,0,90,31,12)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

-- Window controls
local function headerButton(s,x,callback)
    local b = ui("TextButton",header,{
        Position = UDim2.fromOffset(x,3),
        Size = UDim2.fromOffset(28,29),
        BackgroundTransparency = 1,
        Text = s,
        TextColor3 = color.white,
        TextSize = 23
    })
    b.MouseButton1Click:Connect(callback)
end

local cleanup
cleanup = function()
    if not alive then return end
    alive = false

    if _G.BronxHubCleanup == cleanup then
        _G.BronxHubCleanup = nil
    end

    RS:UnbindFromRenderStep("BronxHubV41")
    clearESP()
    for _,c in ipairs(links) do
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
    sidebar.Visible = not minimized
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
            windowStart.X.Scale,windowStart.X.Offset+d.X,
            windowStart.Y.Scale,windowStart.Y.Offset+d.Y
        )
    end
end)

-- Character updates
local function watchPlayer(p)
    connect(p.CharacterAdded,function()
        task.wait(.4)
        if alive then refreshESP() end
    end)
    connect(p.CharacterRemoving,function()
        task.defer(function()
            if alive then refreshESP() end
        end)
    end)
end

for _,p in ipairs(Players:GetPlayers()) do
    watchPlayer(p)
end

connect(Players.PlayerAdded,function(p)
    watchPlayer(p)
    task.wait(.4)
    if alive then refreshESP() end
end)

connect(Players.PlayerRemoving,function()
    task.defer(function()
        if alive then refreshESP() end
    end)
end)

-- Main render loop
RS:BindToRenderStep(
    "BronxHubV41",
    Enum.RenderPriority.Camera.Value+1,
    function(dt)
        if not alive then return end
        updateCircle()
        renderESP()
        updateAim(dt)
    end
)

showPage("Combat")
notify("Bronx Streets Hub V4.1 loaded")
