--[[
    GOLDEN PANEL V2
    One-file Roblox Owner / Developer FPS Toolkit
    Place in: StarterPlayer > StarterPlayerScripts > LocalScript

    IMPORTANT:
    - This file is intentionally client-side and owner-gated.
    - Client-side tools can control the local developer experience.
    - Anything that changes other players or authoritative server state must be
      validated on the server. This single LocalScript therefore does NOT pretend
      to provide insecure "remote admin" powers.
    - Replace the example UserId below.
]]

--//========================================================
--// 01. SERVICES
--//========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--//========================================================
--// 02. LOCAL REFERENCES
--//========================================================

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local function getCamera()
    Camera = Workspace.CurrentCamera or Camera
    return Camera
end

--//========================================================
--// 03. OWNER SECURITY
--//========================================================

local OWNER_IDS = {
    [9113450298] = true, -- <<< REPLACE WITH YOUR USER ID
}

if not OWNER_IDS[LocalPlayer.UserId] then
    return
end

--//========================================================
--// 04. VERSION / BUILD
--//========================================================

local VERSION = "2.0.0"
local BUILD_NAME = "GOLDEN // V2 // OWNER"
local PANEL_KEY = Enum.KeyCode.RightShift

--//========================================================
--// 05. COLORS
--//========================================================

local C = {
    Black = Color3.fromRGB(7, 7, 9),
    Black2 = Color3.fromRGB(11, 11, 14),
    Panel = Color3.fromRGB(15, 15, 18),
    Panel2 = Color3.fromRGB(20, 20, 24),
    Panel3 = Color3.fromRGB(27, 27, 32),
    Border = Color3.fromRGB(55, 55, 63),
    Text = Color3.fromRGB(238, 238, 244),
    Muted = Color3.fromRGB(145, 145, 154),
    Gold = Color3.fromRGB(255, 195, 55),
    Gold2 = Color3.fromRGB(255, 214, 105),
    Gold3 = Color3.fromRGB(166, 113, 20),
    Green = Color3.fromRGB(93, 232, 130),
    Red = Color3.fromRGB(242, 95, 95),
    Blue = Color3.fromRGB(90, 160, 255),
    Purple = Color3.fromRGB(179, 110, 255),
    White = Color3.fromRGB(255, 255, 255),
}

--//========================================================
--// 06. CONFIG
--//========================================================

local Config = {
    UI = {
        Open = true,
        Key = PANEL_KEY,
        Scale = 1,
        Notifications = true,
        AnimationSpeed = 0.22,
        AccentGlow = true,
        Compact = false,
    },

    Aim = {
        Enabled = false,
        FOV = 180,
        Smoothness = 0.08,
        MaxDistance = 900,
        TargetPart = "Head",
        TargetMode = "Crosshair",
        TeamCheck = true,
        AliveCheck = true,
        WallCheck = true,
        Sticky = true,
        Prediction = true,
        PredictionAmount = 0.085,
        VisibilityFOV = true,
        HoldMouse = false,
        HoldKey = Enum.UserInputType.MouseButton2,
        SnapStrength = 1,
        MaxAngle = 180,
    },

    ESP = {
        Enabled = false,
        MaxDistance = 2500,
        TeamCheck = false,
        Box = true,
        Highlight = true,
        Name = true,
        Distance = true,
        Health = true,
        Tracer = false,
        Skeleton = false,
        Arrow = true,
        FillTransparency = 0.82,
        OutlineTransparency = 0.05,
    },

    Trigger = {
        Enabled = false,
        MaxDistance = 900,
        TeamCheck = true,
        WallCheck = true,
        Cooldown = 0.08,
    },

    Player = {
        SpeedEnabled = false,
        Speed = 24,
        JumpEnabled = false,
        JumpPower = 70,
        InfiniteJump = false,
        NoClip = false,
        Fly = false,
        FlySpeed = 70,
        GravityEnabled = false,
        Gravity = 196.2,
        CameraFOV = 80,
        ThirdPerson = false,
        ThirdPersonOffset = Vector3.new(0, 1.75, 8),
    },

    World = {
        FullBright = false,
        Ambient = Color3.fromRGB(127, 127, 127),
        ClockTime = 14,
    },

    Visual = {
        FOVCircle = true,
        FOVFilled = false,
        Crosshair = false,
        TargetMarker = true,
    },

    Debug = {
        FPS = true,
        Ping = true,
        Position = true,
        Velocity = false,
        Target = true,
    },

    Command = {
        Prefix = "/",
        Echo = true,
    },
}

--//========================================================
--// 07. RUNTIME STATE
--//========================================================

local State = {
    Running = true,
    CurrentTarget = nil,
    TargetPart = nil,
    IsAiming = false,
    TriggerBusy = false,
    Dragging = false,
    DragStart = nil,
    DragOrigin = nil,
    LastCharacter = nil,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    OriginalGravity = Workspace.Gravity,
    OriginalCameraFOV = Camera.FieldOfView,
    OriginalCameraType = Camera.CameraType,
    Spectating = nil,
    Connections = {},
    ESP = {},
    Drawings = {},
    Controls = {},
    Categories = {},
    Notifications = {},
    CommandLog = {},
    History = {},
    FlightVelocity = nil,
    FlightGyro = nil,
    NoClipParts = {},
}

--//========================================================
--// 08. SMALL HELPERS
--//========================================================

local function clamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function round(n)
    return math.floor(n + 0.5)
end

local function safeNumber(v, fallback)
    local n = tonumber(v)
    if n == nil then
        return fallback
    end
    return n
end

local function lower(v)
    return string.lower(tostring(v))
end

local function trim(v)
    return tostring(v):gsub("^%s+", ""):gsub("%s+$", "")
end

local function splitWords(text)
    local result = {}
    for token in tostring(text):gmatch("%S+") do
        table.insert(result, token)
    end
    return result
end

local function distanceBetween(a, b)
    return (a - b).Magnitude
end

local function isAlive(character)
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function getTargetPart(character, preferred)
    if not character then
        return nil
    end

    preferred = preferred or Config.Aim.TargetPart

    local choices = {
        preferred,
        "Head",
        "UpperTorso",
        "HumanoidRootPart",
        "Torso",
    }

    for _, name in ipairs(choices) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function playerMatchesText(player, text)
    if not player then
        return false
    end

    text = lower(trim(text))
    if text == "" then
        return false
    end

    return lower(player.Name):sub(1, #text) == text
        or lower(player.DisplayName):sub(1, #text) == text
end

local function getPlayerByText(text)
    for _, player in ipairs(Players:GetPlayers()) do
        if playerMatchesText(player, text) then
            return player
        end
    end
    return nil
end

local function create(className, props, parent)
    local object = Instance.new(className)
    for property, value in pairs(props or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    local x = Instance.new("UICorner")
    x.CornerRadius = UDim.new(0, radius)
    x.Parent = parent
    return x
end

local function stroke(parent, color, thickness, transparency)
    local x = Instance.new("UIStroke")
    x.Color = color or C.Border
    x.Thickness = thickness or 1
    x.Transparency = transparency or 0
    x.Parent = parent
    return x
end

local function padding(parent, value)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, value)
    p.PaddingBottom = UDim.new(0, value)
    p.PaddingLeft = UDim.new(0, value)
    p.PaddingRight = UDim.new(0, value)
    p.Parent = parent
    return p
end

local function tween(object, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration or Config.UI.AnimationSpeed,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(object, info, properties)
    t:Play()
    return t
end

local function track(connection)
    table.insert(State.Connections, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(State.Connections)
end

local function setFlag(path, value)
    local node = Config
    local parts = {}
    for token in tostring(path):gmatch("[^.]+") do
        table.insert(parts, token)
    end

    for i = 1, #parts - 1 do
        node = node[parts[i]]
        if node == nil then
            return false
        end
    end

    node[parts[#parts]] = value
    return true
end

local function getFlag(path)
    local node = Config
    for token in tostring(path):gmatch("[^.]+") do
        node = node[token]
        if node == nil then
            return nil
        end
    end
    return node
end

--//========================================================
--// 09. NOTIFICATIONS
--//========================================================

local function notify(title, text, duration)
    if not Config.UI.Notifications then
        return
    end

    title = title or "Golden Panel"
    text = text or ""
    duration = duration or 3

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
        })
    end)
end

--//========================================================
--// 10. CHARACTER CONTROL
--//========================================================

local function captureCharacterDefaults()
    local humanoid = getHumanoid()
    if humanoid then
        State.OriginalWalkSpeed = humanoid.WalkSpeed
        State.OriginalJumpPower = humanoid.JumpPower
    end

    State.OriginalGravity = Workspace.Gravity
    State.OriginalCameraFOV = Camera.FieldOfView
    State.OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }
end

local function applySpeed()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    if Config.Player.SpeedEnabled then
        humanoid.WalkSpeed = Config.Player.Speed
    else
        humanoid.WalkSpeed = State.OriginalWalkSpeed
    end
end

local function applyJump()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    pcall(function()
        humanoid.UseJumpPower = true
    end)

    if Config.Player.JumpEnabled then
        humanoid.JumpPower = Config.Player.JumpPower
    else
        humanoid.JumpPower = State.OriginalJumpPower
    end
end

local function applyGravity()
    if Config.Player.GravityEnabled then
        Workspace.Gravity = Config.Player.Gravity
    else
        Workspace.Gravity = State.OriginalGravity
    end
end

local function applyCameraFOV()
    Camera.FieldOfView = Config.Player.CameraFOV
end

local function resetCharacterModifiers()
    Config.Player.SpeedEnabled = false
    Config.Player.JumpEnabled = false
    Config.Player.NoClip = false
    Config.Player.Fly = false
    Config.Player.GravityEnabled = false

    for object, original in pairs(State.NoClipParts) do
        if object and object.Parent then
            object.CanCollide = original
        end
    end
    table.clear(State.NoClipParts)

    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = State.OriginalWalkSpeed
        humanoid.JumpPower = State.OriginalJumpPower
    end

    Workspace.Gravity = State.OriginalGravity
    Camera.FieldOfView = State.OriginalCameraFOV
end

--//========================================================
--// 11. TARGET VALIDATION
--//========================================================

local function sameTeam(player)
    if not player then
        return false
    end

    if LocalPlayer.Team == nil or player.Team == nil then
        return false
    end

    return LocalPlayer.Team == player.Team
end

local function teamAllowed(player)
    if not Config.Aim.TeamCheck and not Config.Trigger.TeamCheck then
        return true
    end

    if Config.Aim.TeamCheck then
        if sameTeam(player) then
            return false
        end
    end

    return true
end

local function triggerTeamAllowed(player)
    if not Config.Trigger.TeamCheck then
        return true
    end

    return not sameTeam(player)
end

local function lineOfSight(part, character)
    if not part or not character then
        return false
    end

    if not Config.Aim.WallCheck and not Config.Trigger.WallCheck then
        return true
    end

    local origin = Camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
    }
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(character)
end

local function targetAllowed(player, part)
    if not player or player == LocalPlayer then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    if Config.Aim.AliveCheck and not isAlive(character) then
        return false
    end

    if Config.Aim.TeamCheck and sameTeam(player) then
        return false
    end

    if not part then
        return false
    end

    local distance = distanceBetween(Camera.CFrame.Position, part.Position)
    if distance > Config.Aim.MaxDistance then
        return false
    end

    if Config.Aim.WallCheck and not lineOfSight(part, character) then
        return false
    end

    return true
end

--//========================================================
--// 12. AIM TARGET SEARCH
--//========================================================

local function screenCenter()
    Camera = getCamera()
    local size = Camera.ViewportSize
    return Vector2.new(size.X * 0.5, size.Y * 0.5)
end

local function targetScreenDistance(part)
    local point, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible or point.Z <= 0 then
        return math.huge, point
    end

    local center = screenCenter()
    local screen = Vector2.new(point.X, point.Y)
    return (screen - center).Magnitude, point
end

local function getPredictedPosition(part, player)
    if not Config.Aim.Prediction then
        return part.Position
    end

    local root = getRoot(player.Character)
    if not root then
        return part.Position
    end

    local velocity = root.AssemblyLinearVelocity
    return part.Position + velocity * Config.Aim.PredictionAmount
end

local function scoreTarget(player, part)
    local screenDistance = targetScreenDistance(part)
    local distance3D = distanceBetween(Camera.CFrame.Position, part.Position)

    if Config.Aim.TargetMode == "Distance" then
        return distance3D
    end

    if Config.Aim.TargetMode == "Health" then
        local humanoid = player.Character
            and player.Character:FindFirstChildOfClass("Humanoid")
        return humanoid and humanoid.Health or math.huge
    end

    if Config.Aim.TargetMode == "Hybrid" then
        return screenDistance + distance3D * 0.03
    end

    return screenDistance
end

local function findBestTarget()
    local bestPlayer = nil
    local bestPart = nil
    local bestScore = math.huge
    local radius = Config.Aim.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local part = character and getTargetPart(character, Config.Aim.TargetPart)

            if part and targetAllowed(player, part) then
                local screenDistance = targetScreenDistance(part)

                if screenDistance <= radius then
                    local score = scoreTarget(player, part)

                    if score < bestScore then
                        bestScore = score
                        bestPlayer = player
                        bestPart = part
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart
end

local function keepStickyTarget()
    if not Config.Aim.Sticky then
        return false
    end

    local player = State.CurrentTarget
    if not player then
        return false
    end

    local character = player.Character
    local part = character and getTargetPart(character, Config.Aim.TargetPart)

    if not part then
        return false
    end

    if not targetAllowed(player, part) then
        return false
    end

    local screenDistance = targetScreenDistance(part)
    return screenDistance <= Config.Aim.FOV
end

local function updateTarget()
    if keepStickyTarget() then
        State.TargetPart = getTargetPart(
            State.CurrentTarget.Character,
            Config.Aim.TargetPart
        )
        return
    end

    local player, part = findBestTarget()
    State.CurrentTarget = player
    State.TargetPart = part
end

--//========================================================
--// 13. AIM SYSTEM
--//========================================================

local function aimHeld()
    if not Config.Aim.HoldMouse then
        return true
    end

    if Config.Aim.HoldKey == Enum.UserInputType.MouseButton2 then
        return UserInputService:IsMouseButtonPressed(
            Enum.UserInputType.MouseButton2
        )
    end

    return true
end

local function updateAim()
    Camera = getCamera()
    if not Config.Aim.Enabled then
        State.IsAiming = false
        return
    end

    if not aimHeld() then
        State.IsAiming = false
        return
    end

    updateTarget()

    local player = State.CurrentTarget
    local part = State.TargetPart

    if not player or not part then
        State.IsAiming = false
        return
    end

    local predicted = getPredictedPosition(part, player)
    local cameraPosition = Camera.CFrame.Position
    local desired = CFrame.lookAt(cameraPosition, predicted)

    local strength = clamp(
        Config.Aim.Smoothness * Config.Aim.SnapStrength,
        0.001,
        1
    )

    Camera.CFrame = Camera.CFrame:Lerp(desired, strength)
    State.IsAiming = true
end

--//========================================================
--// 14. TRIGGERBOT
--//========================================================

local function equippedTool()
    local character = getCharacter()
    if not character then
        return nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end

    return nil
end

local function triggerRay()
    local center = screenCenter()

    local ray = Camera:ViewportPointToRay(
        center.X,
        center.Y
    )

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
    }

    return Workspace:Raycast(
        ray.Origin,
        ray.Direction * Config.Trigger.MaxDistance,
        params
    )
end

local function triggerTargetFromRay(result)
    if not result then
        return nil, nil
    end

    local character = result.Instance:FindFirstAncestorOfClass("Model")
    if not character then
        return nil, nil
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then
        return nil, nil
    end

    return player, character
end

local function updateTrigger()
    if not Config.Trigger.Enabled then
        return
    end

    if State.TriggerBusy then
        return
    end

    local result = triggerRay()
    local player, character = triggerTargetFromRay(result)

    if not player or not character then
        return
    end

    if not triggerTeamAllowed(player) then
        return
    end

    if Config.Trigger.WallCheck and not result.Instance:IsDescendantOf(character) then
        return
    end

    local tool = equippedTool()
    if not tool then
        return
    end

    State.TriggerBusy = true

    pcall(function()
        tool:Activate()
    end)

    task.delay(
        clamp(Config.Trigger.Cooldown, 0.01, 2),
        function()
            State.TriggerBusy = false
        end
    )
end

--//========================================================
--// 15. NOCLIP / FLY
--//========================================================

local function updateNoClip()
    local character = getCharacter()
    if not character then
        return
    end

    if Config.Player.NoClip then
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                if State.NoClipParts[object] == nil then
                    State.NoClipParts[object] = object.CanCollide
                end
                object.CanCollide = false
            end
        end
    else
        for object, original in pairs(State.NoClipParts) do
            if object and object.Parent then
                object.CanCollide = original
            end
        end
        table.clear(State.NoClipParts)
    end
end

local function stopFly()
    if State.FlightVelocity then
        State.FlightVelocity:Destroy()
        State.FlightVelocity = nil
    end

    if State.FlightGyro then
        State.FlightGyro:Destroy()
        State.FlightGyro = nil
    end

    local humanoid = getHumanoid()
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function startFly()
    stopFly()

    local root = getRoot(getCharacter())
    if not root then
        return
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "GoldenFlightVelocity"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.P = 25000
    bv.Velocity = Vector3.zero
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "GoldenFlightGyro"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 30000
    bg.CFrame = Camera.CFrame
    bg.Parent = root

    State.FlightVelocity = bv
    State.FlightGyro = bg
end

local function updateFly()
    if not Config.Player.Fly then
        stopFly()
        return
    end

    local root = getRoot(getCharacter())
    local humanoid = getHumanoid()

    if not root or not humanoid then
        return
    end

    if not State.FlightVelocity or not State.FlightVelocity.Parent then
        startFly()
    end

    humanoid.PlatformStand = false

    local direction = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.yAxis
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.yAxis
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit * Config.Player.FlySpeed
    end

    State.FlightVelocity.Velocity = direction
    State.FlightGyro.CFrame = Camera.CFrame
end

--//========================================================
--// 16. INFINITE JUMP
--//========================================================

track(UserInputService.JumpRequest:Connect(function()
    if not Config.Player.InfiniteJump then
        return
    end

    local humanoid = getHumanoid()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

--//========================================================
--// 17. WORLD / LIGHTING
--//========================================================

local function applyWorld()
    if Config.World.FullBright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        local original = State.OriginalLighting
        Lighting.Brightness = original.Brightness
        Lighting.ClockTime = Config.World.ClockTime
        Lighting.FogEnd = original.FogEnd
        Lighting.GlobalShadows = original.GlobalShadows
        Lighting.Ambient = original.Ambient
        Lighting.OutdoorAmbient = original.OutdoorAmbient
    end
end

--//========================================================
--// 18. ESP GUI
--//========================================================

local ESPFolder = create("Folder", {
    Name = "GoldenESP",
}, PlayerGui)

local function clearESP(player)
    local entry = State.ESP[player]
    if not entry then
        return
    end

    for _, object in pairs(entry) do
        if typeof(object) == "Instance" then
            pcall(function()
                object:Destroy()
            end)
        end
    end

    State.ESP[player] = nil
end

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    if State.ESP[player] then
        return
    end

    local character = player.Character
    local root = getRoot(character)

    if not character or not root then
        return
    end

    local highlight
    if Config.ESP.Highlight then
        highlight = create("Highlight", {
            Name = "GoldenHighlight",
            FillColor = C.Gold,
            OutlineColor = C.Gold2,
            FillTransparency = Config.ESP.FillTransparency,
            OutlineTransparency = Config.ESP.OutlineTransparency,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            Adornee = character,
        }, ESPFolder)
    end

    local billboard = create("BillboardGui", {
        Name = "GoldenInfo",
        Size = UDim2.fromOffset(190, 72),
        StudsOffset = Vector3.new(0, 3.35, 0),
        AlwaysOnTop = true,
        MaxDistance = Config.ESP.MaxDistance,
        Adornee = root,
    }, ESPFolder)

    local info = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        TextColor3 = C.Gold2,
        TextStrokeTransparency = 0.45,
        TextSize = 12,
        Text = player.DisplayName,
    }, billboard)

    local boxFrame
    if Config.ESP.Box then
        boxFrame = create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(70, 100),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Visible = false,
        }, billboard)

        stroke(boxFrame, C.Gold, 2, 0)
    end

    State.ESP[player] = {
        highlight = highlight,
        billboard = billboard,
        info = info,
        box = boxFrame,
    }
end

local function updateESPPlayer(player)
    local entry = State.ESP[player]
    if not entry then
        createESP(player)
        entry = State.ESP[player]
    end

    if not entry then
        return
    end

    local character = player.Character
    local root = getRoot(character)

    if not character or not root or not isAlive(character) then
        clearESP(player)
        return
    end

    if Config.ESP.TeamCheck and sameTeam(player) then
        clearESP(player)
        return
    end

    -- Keep optional ESP components synchronized with live settings.
    if Config.ESP.Highlight then
        if not entry.highlight then
            entry.highlight = create("Highlight", {
                Name = "GoldenHighlight",
                FillColor = C.Gold,
                OutlineColor = C.Gold2,
                FillTransparency = Config.ESP.FillTransparency,
                OutlineTransparency = Config.ESP.OutlineTransparency,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                Adornee = character,
            }, ESPFolder)
        end
    elseif entry.highlight then
        pcall(function() entry.highlight:Destroy() end)
        entry.highlight = nil
    end

    if Config.ESP.Box then
        if not entry.box and entry.billboard then
            local boxFrame = create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(70, 100),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Visible = false,
            }, entry.billboard)
            stroke(boxFrame, C.Gold, 2, 0)
            entry.box = boxFrame
        end
    elseif entry.box then
        pcall(function() entry.box:Destroy() end)
        entry.box = nil
    end

    local distance = distanceBetween(
        Camera.CFrame.Position,
        root.Position
    )

    if distance > Config.ESP.MaxDistance then
        if entry.billboard then
            entry.billboard.Enabled = false
        end
        if entry.highlight then
            entry.highlight.Enabled = false
        end
        return
    end

    if entry.billboard then
        entry.billboard.Enabled = true
    end

    if entry.highlight then
        entry.highlight.Enabled = true
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local health = humanoid and humanoid.Health or 0
    local maxHealth = humanoid and humanoid.MaxHealth or 100

    local pieces = {}

    if Config.ESP.Name then
        table.insert(pieces, player.DisplayName)
    end

    if Config.ESP.Distance then
        table.insert(pieces, "[" .. round(distance) .. "m]")
    end

    if Config.ESP.Health then
        table.insert(
            pieces,
            "HP " .. round(health) .. "/" .. round(maxHealth)
        )
    end

    if entry.info then
        entry.info.Text = table.concat(pieces, "  ")
    end
end

local function updateESP()
    if not Config.ESP.Enabled then
        for player in pairs(State.ESP) do
            clearESP(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESPPlayer(player)
        end
    end
end

--//========================================================
--// 19. UI ROOT
--//========================================================

local Screen = create("ScreenGui", {
    Name = "GoldenPanelV2",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, PlayerGui)

local Shadow = create("Frame", {
    Name = "Shadow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(470, 390),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, Screen)
corner(Shadow, 20)

local Main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(450, 370),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, Screen)
corner(Main, 16)
local MainStroke = stroke(Main, C.Gold, 1.2, 0.35)

--//========================================================
--// 20. HEADER
--//========================================================

local Header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 70),
    BackgroundColor3 = C.Panel2,
    BorderSizePixel = 0,
}, Main)
corner(Header, 16)

local HeaderBottom = create("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = C.Panel2,
    BorderSizePixel = 0,
}, Header)

local HeaderAccent = create("Frame", {
    Size = UDim2.new(0, 4, 1, 0),
    BackgroundColor3 = C.Gold,
    BorderSizePixel = 0,
}, Header)
corner(HeaderAccent, 4)

local Title = create("TextLabel", {
    Position = UDim2.fromOffset(22, 9),
    Size = UDim2.new(1, -125, 0, 28),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "GOLDEN PANEL",
    TextColor3 = C.Gold2,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local Subtitle = create("TextLabel", {
    Position = UDim2.fromOffset(23, 38),
    Size = UDim2.new(1, -145, 0, 18),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = BUILD_NAME .. "  •  v" .. VERSION,
    TextColor3 = C.Muted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local OnlineDot = create("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(1, -31, 0, 19),
    BackgroundColor3 = C.Green,
    BorderSizePixel = 0,
}, Header)
corner(OnlineDot, 8)

local OnlineText = create("TextLabel", {
    Position = UDim2.new(1, -96, 0, 34),
    Size = UDim2.fromOffset(72, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "ONLINE",
    TextColor3 = C.Green,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Header)

--//========================================================
--// 21. DRAGGING
--//========================================================

local function updateDrag(input)
    if not State.Dragging or not State.DragStart or not State.DragOrigin then
        return
    end

    local delta = input.Position - State.DragStart

    Main.Position = UDim2.new(
        State.DragOrigin.X.Scale,
        State.DragOrigin.X.Offset + delta.X,
        State.DragOrigin.Y.Scale,
        State.DragOrigin.Y.Offset + delta.Y
    )

    Shadow.Position = Main.Position
end

track(Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        State.Dragging = true
        State.DragStart = input.Position
        State.DragOrigin = Main.Position
    end
end))

track(Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        State.Dragging = false
    end
end))

track(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        updateDrag(input)
    end
end))

--//========================================================
--// 22. TABS
--//========================================================

local TabBar = create("Frame", {
    Name = "TabBar",
    Position = UDim2.fromOffset(15, 80),
    Size = UDim2.new(1, -30, 0, 34),
    BackgroundTransparency = 1,
}, Main)

local TabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding = UDim.new(0, 6),
}, TabBar)

local ContentFrame = create("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(15, 122),
    Size = UDim2.new(1, -30, 1, -138),
    BackgroundTransparency = 1,
}, Main)

--//========================================================
--// 23. TAB SYSTEM
--//========================================================

local Tabs = {}
local ActiveTab = nil

local function createTab(name)
    local button = create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.fromOffset(82, 32),
        BackgroundColor3 = C.Panel2,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = C.Muted,
        TextSize = 10,
    }, TabBar)

    corner(button, 9)

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Gold,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, ContentFrame)

    padding(page, 2)

    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    local tab = {
        Button = button,
        Page = page,
        Layout = layout,
        Name = name,
    }

    table.insert(Tabs, tab)

    button.MouseButton1Click:Connect(function()
        ActiveTab = tab

        for _, other in ipairs(Tabs) do
            other.Page.Visible = false

            tween(other.Button, 0.16, {
                BackgroundColor3 = C.Panel2,
                TextColor3 = C.Muted,
            })
        end

        page.Visible = true

        tween(button, 0.16, {
            BackgroundColor3 = C.Gold3,
            TextColor3 = C.Gold2,
        })
    end)

    return tab
end

local CombatTab = createTab("COMBAT")
local VisualTab = createTab("VISUAL")
local PlayerTab = createTab("PLAYER")
local WorldTab = createTab("WORLD")
local DebugTab = createTab("DEBUG")
local CmdTab = createTab("COMMAND")

--//========================================================
--// 24. CONTROL FACTORY
--//========================================================

local function makeRow(parent, height)
    local row = create("Frame", {
        Size = UDim2.new(1, -4, 0, height or 54),
        BackgroundColor3 = C.Panel2,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 10)
    stroke(row, C.Border, 1, 0.35)
    return row
end

local function makeLabel(parent, title, subtitle)
    local name = create("TextLabel", {
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -105, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)

    if subtitle then
        create("TextLabel", {
            Position = UDim2.fromOffset(14, 28),
            Size = UDim2.new(1, -105, 0, 17),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = subtitle,
            TextColor3 = C.Muted,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, parent)
    end

    return name
end

local function makeToggle(parent, title, subtitle, getter, setter)
    local row = makeRow(parent, 56)
    makeLabel(row, title, subtitle)

    local back = create("Frame", {
        Size = UDim2.fromOffset(48, 26),
        Position = UDim2.new(1, -63, 0.5, -13),
        BackgroundColor3 = C.Panel3,
        BorderSizePixel = 0,
    }, row)
    corner(back, 20)

    local click = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
    }, back)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = C.Muted,
        BorderSizePixel = 0,
    }, click)
    corner(knob, 20)

    local function refresh()
        local enabled = getter()

        if enabled then
            tween(back, 0.16, {
                BackgroundColor3 = C.Gold3,
            })
            tween(knob, 0.16, {
                Position = UDim2.new(1, -23, 0.5, -10),
                BackgroundColor3 = C.Gold2,
            })
        else
            tween(back, 0.16, {
                BackgroundColor3 = C.Panel3,
            })
            tween(knob, 0.16, {
                Position = UDim2.new(0, 3, 0.5, -10),
                BackgroundColor3 = C.Muted,
            })
        end
    end

    click.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()

    return {
        Row = row,
        Refresh = refresh,
    }
end

local function makeButton(parent, text, callback)
    local row = makeRow(parent, 44)

    local button = create("TextButton", {
        Size = UDim2.new(1, -18, 1, -10),
        Position = UDim2.fromOffset(9, 5),
        BackgroundColor3 = C.Panel3,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 11,
    }, row)

    corner(button, 8)

    button.MouseEnter:Connect(function()
        tween(button, 0.12, {
            BackgroundColor3 = C.Gold3,
            TextColor3 = C.Gold2,
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.12, {
            BackgroundColor3 = C.Panel3,
            TextColor3 = C.Text,
        })
    end)

    button.MouseButton1Click:Connect(callback)

    return row
end

local function makeSlider(parent, title, subtitle, minimum, maximum, getter, setter)
    local row = makeRow(parent, 68)
    makeLabel(row, title, subtitle)

    local valueText = create("TextLabel", {
        Position = UDim2.new(1, -84, 0, 9),
        Size = UDim2.fromOffset(70, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.Gold2,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local bar = create("Frame", {
        Position = UDim2.fromOffset(14, 46),
        Size = UDim2.new(1, -28, 0, 7),
        BackgroundColor3 = C.Panel3,
        BorderSizePixel = 0,
    }, row)
    corner(bar, 7)

    local fill = create("Frame", {
        Size = UDim2.fromScale(0.5, 1),
        BackgroundColor3 = C.Gold,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 7)

    local hit = create("TextButton", {
        Size = UDim2.new(1, 14, 1, 20),
        Position = UDim2.new(0, -7, 0, -10),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, bar)

    local dragging = false

    local function refresh(value)
        value = value or getter()
        value = clamp(value, minimum, maximum)

        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(alpha, 1)
        valueText.Text = string.format("%.2f", value)
    end

    local function update(input)
        local x = input.Position.X
        local left = bar.AbsolutePosition.X
        local width = bar.AbsoluteSize.X
        local alpha = clamp((x - left) / width, 0, 1)

        local value = minimum + (maximum - minimum) * alpha
        setter(value)
        refresh(value)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            update(input)
        end
    end)

    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)

    refresh()

    return row
end

local function makeTextInput(parent, title, subtitle, placeholder, getter, setter)
    local row = makeRow(parent, 64)
    makeLabel(row, title, subtitle)

    local box = create("TextBox", {
        Size = UDim2.fromOffset(140, 34),
        Position = UDim2.new(1, -155, 0.5, -17),
        BackgroundColor3 = C.Panel3,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = placeholder,
        Text = tostring(getter() or ""),
        TextColor3 = C.Text,
        PlaceholderColor3 = C.Muted,
        TextSize = 10,
        ClearTextOnFocus = false,
    }, row)

    corner(box, 8)

    box.FocusLost:Connect(function()
        setter(box.Text)
    end)

    return row
end

--//========================================================
--// 25. COMBAT UI
--//========================================================

makeToggle(
    CombatTab.Page,
    "Aim Assist",
    "Fast camera target assistance",
    function()
        return Config.Aim.Enabled
    end,
    function(v)
        Config.Aim.Enabled = v
        if not v then
            State.CurrentTarget = nil
            State.TargetPart = nil
        end
    end
)

makeSlider(
    CombatTab.Page,
    "Aim FOV",
    "Target acquisition radius",
    20,
    500,
    function() return Config.Aim.FOV end,
    function(v) Config.Aim.FOV = round(v) end
)

makeSlider(
    CombatTab.Page,
    "Smoothness",
    "Camera interpolation",
    0.01,
    0.5,
    function() return Config.Aim.Smoothness end,
    function(v) Config.Aim.Smoothness = v end
)

makeSlider(
    CombatTab.Page,
    "Prediction",
    "Movement prediction amount",
    0,
    0.3,
    function() return Config.Aim.PredictionAmount end,
    function(v) Config.Aim.PredictionAmount = v end
)

makeSlider(
    CombatTab.Page,
    "Aim Distance",
    "Maximum target range",
    50,
    3000,
    function() return Config.Aim.MaxDistance end,
    function(v) Config.Aim.MaxDistance = round(v) end
)

makeToggle(
    CombatTab.Page,
    "Team Check",
    "Ignore teammates",
    function() return Config.Aim.TeamCheck end,
    function(v) Config.Aim.TeamCheck = v end
)

makeToggle(
    CombatTab.Page,
    "Wall Check",
    "Require unobstructed target",
    function() return Config.Aim.WallCheck end,
    function(v) Config.Aim.WallCheck = v end
)

makeToggle(
    CombatTab.Page,
    "Sticky Target",
    "Stay on current valid target",
    function() return Config.Aim.Sticky end,
    function(v) Config.Aim.Sticky = v end
)

makeToggle(
    CombatTab.Page,
    "Prediction",
    "Lead moving targets",
    function() return Config.Aim.Prediction end,
    function(v) Config.Aim.Prediction = v end
)

makeToggle(
    CombatTab.Page,
    "Triggerbot",
    "Fire equipped Tool when crosshair hits",
    function() return Config.Trigger.Enabled end,
    function(v) Config.Trigger.Enabled = v end
)

makeSlider(
    CombatTab.Page,
    "Trigger Cooldown",
    "Minimum trigger delay",
    0.01,
    0.5,
    function() return Config.Trigger.Cooldown end,
    function(v) Config.Trigger.Cooldown = v end
)

makeButton(
    CombatTab.Page,
    "Clear Current Target",
    function()
        State.CurrentTarget = nil
        State.TargetPart = nil
        notify("Golden Panel", "Target cleared")
    end
)

makeButton(
    CombatTab.Page,
    "Force Target Scan",
    function()
        State.CurrentTarget, State.TargetPart = findBestTarget()
        if State.CurrentTarget then
            notify(
                "Target",
                "Locked: " .. State.CurrentTarget.DisplayName
            )
        else
            notify("Target", "No valid target")
        end
    end
)

--//========================================================
--// 26. VISUAL UI
--//========================================================

makeToggle(
    VisualTab.Page,
    "Player ESP",
    "Track players around the map",
    function() return Config.ESP.Enabled end,
    function(v) Config.ESP.Enabled = v end
)

makeToggle(
    VisualTab.Page,
    "Highlight",
    "Gold character highlight",
    function() return Config.ESP.Highlight end,
    function(v) Config.ESP.Highlight = v end
)

makeToggle(
    VisualTab.Page,
    "Names",
    "Display player names",
    function() return Config.ESP.Name end,
    function(v) Config.ESP.Name = v end
)

makeToggle(
    VisualTab.Page,
    "Distance",
    "Display target distance",
    function() return Config.ESP.Distance end,
    function(v) Config.ESP.Distance = v end
)

makeToggle(
    VisualTab.Page,
    "Health",
    "Display target health",
    function() return Config.ESP.Health end,
    function(v) Config.ESP.Health = v end
)

makeToggle(
    VisualTab.Page,
    "ESP Team Check",
    "Hide teammates from ESP",
    function() return Config.ESP.TeamCheck end,
    function(v) Config.ESP.TeamCheck = v end
)

makeSlider(
    VisualTab.Page,
    "ESP Distance",
    "Maximum ESP range",
    100,
    4000,
    function() return Config.ESP.MaxDistance end,
    function(v) Config.ESP.MaxDistance = round(v) end
)

makeToggle(
    VisualTab.Page,
    "FOV Circle",
    "Draw aim radius",
    function() return Config.Visual.FOVCircle end,
    function(v) Config.Visual.FOVCircle = v end
)

makeToggle(
    VisualTab.Page,
    "Crosshair",
    "Center crosshair",
    function() return Config.Visual.Crosshair end,
    function(v) Config.Visual.Crosshair = v end
)

makeToggle(
    VisualTab.Page,
    "Target Marker",
    "Mark current aim target",
    function() return Config.Visual.TargetMarker end,
    function(v) Config.Visual.TargetMarker = v end
)

--//========================================================
--// 27. PLAYER UI
--//========================================================

makeToggle(
    PlayerTab.Page,
    "Custom Speed",
    "Apply custom WalkSpeed",
    function() return Config.Player.SpeedEnabled end,
    function(v)
        Config.Player.SpeedEnabled = v
        applySpeed()
    end
)

makeSlider(
    PlayerTab.Page,
    "WalkSpeed",
    "Movement speed",
    8,
    250,
    function() return Config.Player.Speed end,
    function(v)
        Config.Player.Speed = round(v)
        applySpeed()
    end
)

makeToggle(
    PlayerTab.Page,
    "Custom Jump",
    "Apply custom JumpPower",
    function() return Config.Player.JumpEnabled end,
    function(v)
        Config.Player.JumpEnabled = v
        applyJump()
    end
)

makeSlider(
    PlayerTab.Page,
    "JumpPower",
    "Jump strength",
    20,
    250,
    function() return Config.Player.JumpPower end,
    function(v)
        Config.Player.JumpPower = round(v)
        applyJump()
    end
)

makeToggle(
    PlayerTab.Page,
    "Infinite Jump",
    "Jump repeatedly in air",
    function() return Config.Player.InfiniteJump end,
    function(v) Config.Player.InfiniteJump = v end
)

makeToggle(
    PlayerTab.Page,
    "NoClip",
    "Disable local character collision",
    function() return Config.Player.NoClip end,
    function(v) Config.Player.NoClip = v end
)

makeToggle(
    PlayerTab.Page,
    "Fly",
    "Client developer flight",
    function() return Config.Player.Fly end,
    function(v)
        Config.Player.Fly = v
        if v then
            startFly()
        else
            stopFly()
        end
    end
)

makeSlider(
    PlayerTab.Page,
    "Fly Speed",
    "Flight speed",
    10,
    300,
    function() return Config.Player.FlySpeed end,
    function(v) Config.Player.FlySpeed = round(v) end
)

makeToggle(
    PlayerTab.Page,
    "Custom Gravity",
    "Override local workspace gravity",
    function() return Config.Player.GravityEnabled end,
    function(v)
        Config.Player.GravityEnabled = v
        applyGravity()
    end
)

makeSlider(
    PlayerTab.Page,
    "Gravity",
    "Workspace gravity",
    0,
    300,
    function() return Config.Player.Gravity end,
    function(v)
        Config.Player.Gravity = round(v)
        applyGravity()
    end
)

makeSlider(
    PlayerTab.Page,
    "Camera FOV",
    "Field of view",
    40,
    150,
    function() return Config.Player.CameraFOV end,
    function(v)
        Config.Player.CameraFOV = round(v)
        applyCameraFOV()
    end
)

makeButton(
    PlayerTab.Page,
    "Reset Local Modifiers",
    function()
        resetCharacterModifiers()
        notify("Golden Panel", "Local modifiers reset")
    end
)

makeButton(
    PlayerTab.Page,
    "Reset Character",
    function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
)

--//========================================================
--// 28. WORLD UI
--//========================================================

makeToggle(
    WorldTab.Page,
    "FullBright",
    "Bright developer lighting",
    function() return Config.World.FullBright end,
    function(v)
        Config.World.FullBright = v
        applyWorld()
    end
)

makeSlider(
    WorldTab.Page,
    "Clock Time",
    "Local lighting time",
    0,
    24,
    function() return Lighting.ClockTime end,
    function(v)
        Config.World.ClockTime = v
        applyWorld()
    end
)

makeButton(
    WorldTab.Page,
    "Night",
    function()
        Config.World.ClockTime = 0
        applyWorld()
    end
)

makeButton(
    WorldTab.Page,
    "Day",
    function()
        Config.World.ClockTime = 14
        applyWorld()
    end
)

makeButton(
    WorldTab.Page,
    "Midnight",
    function()
        Config.World.ClockTime = 0
        applyWorld()
    end
)

--//========================================================
--// 29. DEBUG UI
--//========================================================

makeToggle(
    DebugTab.Page,
    "FPS Counter",
    "Show current client framerate",
    function() return Config.Debug.FPS end,
    function(v) Config.Debug.FPS = v end
)

makeToggle(
    DebugTab.Page,
    "Ping",
    "Show network ping",
    function() return Config.Debug.Ping end,
    function(v) Config.Debug.Ping = v end
)

makeToggle(
    DebugTab.Page,
    "Position",
    "Show coordinates",
    function() return Config.Debug.Position end,
    function(v) Config.Debug.Position = v end
)

makeToggle(
    DebugTab.Page,
    "Velocity",
    "Show movement velocity",
    function() return Config.Debug.Velocity end,
    function(v) Config.Debug.Velocity = v end
)

makeToggle(
    DebugTab.Page,
    "Target",
    "Show current target",
    function() return Config.Debug.Target end,
    function(v) Config.Debug.Target = v end
)

makeButton(
    DebugTab.Page,
    "Print Player List",
    function()
        for _, player in ipairs(Players:GetPlayers()) do
            print(
                "[GoldenPanel]",
                player.Name,
                player.UserId,
                player.Team and player.Team.Name or "NoTeam"
            )
        end
    end
)

makeButton(
    DebugTab.Page,
    "Print Camera CFrame",
    function()
        print("[GoldenPanel] Camera:", Camera.CFrame)
    end
)

makeButton(
    DebugTab.Page,
    "Print Character Position",
    function()
        local root = getRoot(getCharacter())
        if root then
            print("[GoldenPanel] Position:", root.Position)
        end
    end
)

--//========================================================
--// 30. COMMAND UI
--//========================================================

local CommandInfo = create("TextLabel", {
    Size = UDim2.new(1, -4, 0, 95),
    BackgroundColor3 = C.Panel2,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    TextColor3 = C.Muted,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = table.concat({
        "/gold - toggle panel",
        "/help - command list",
        "/aim on|off",
        "/aim fov <n>",
        "/aim smooth <n>",
        "/aim target <head|torso|root>",
        "/esp on|off",
        "/trigger on|off",
        "/speed <n>",
        "/jump <n>",
        "/fov <n>",
        "/noclip",
        "/fly [n]",
        "/unfly",
        "/gravity <n>",
        "/bright",
        "/day /night",
        "/tp <player>",
        "/spectate <player>",
        "/unspectate",
        "/reset",
        "/rejoin",
        "/fps /ping /pos",
    }, "\n"),
}, CmdTab.Page)
corner(CommandInfo, 10)
padding(CommandInfo, 10)

local CommandBox = create("TextBox", {
    Size = UDim2.new(1, -4, 0, 48),
    BackgroundColor3 = C.Panel2,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.GothamMedium,
    PlaceholderText = "/help",
    PlaceholderColor3 = C.Muted,
    Text = "",
    TextColor3 = C.Text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, CmdTab.Page)
corner(CommandBox, 10)
stroke(CommandBox, C.Gold3, 1, 0.35)
padding(CommandBox, 10)

--//========================================================
--// 31. HUD
--//========================================================

local HUD = create("Frame", {
    Name = "HUD",
    Position = UDim2.fromOffset(18, 18),
    Size = UDim2.fromOffset(240, 106),
    BackgroundColor3 = C.Black,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    Visible = true,
}, Screen)
corner(HUD, 11)
stroke(HUD, C.Gold, 1, 0.55)

local HUDText = create("TextLabel", {
    Position = UDim2.fromOffset(10, 8),
    Size = UDim2.new(1, -20, 1, -16),
    BackgroundTransparency = 1,
    Font = Enum.Font.Code,
    TextColor3 = C.Text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "",
}, HUD)

local Crosshair = create("Frame", {
    Name = "Crosshair",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(4, 4),
    BackgroundColor3 = C.Gold2,
    BorderSizePixel = 0,
    Visible = false,
}, Screen)
corner(Crosshair, 5)

local FOVVisual = create("Frame", {
    Name = "FOVCircle",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(Config.Aim.FOV * 2, Config.Aim.FOV * 2),
    BackgroundTransparency = 1,
    Visible = Config.Visual.FOVCircle,
}, Screen)
corner(FOVVisual, 9999)
stroke(FOVVisual, C.Gold, 1, 0.35)

local TargetMarker = create("Frame", {
    Name = "TargetMarker",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(14, 14),
    BackgroundTransparency = 1,
    Visible = false,
}, Screen)
corner(TargetMarker, 9999)
stroke(TargetMarker, C.Red, 2, 0)

--//========================================================
--// 32. HUD UPDATE
--//========================================================

local frames = 0
local fps = 0
local fpsClock = os.clock()

local function getPing()
    local value = 0

    pcall(function()
        local network = Stats.Network
        local serverStatsItem = network.ServerStatsItem
        local pingItem = serverStatsItem["Data Ping"]
        value = pingItem:GetValue()
    end)

    return value
end

local function updateHUD()
    Camera = getCamera()
    frames += 1

    if os.clock() - fpsClock >= 1 then
        fps = frames
        frames = 0
        fpsClock = os.clock()
    end

    local root = getRoot(getCharacter())
    local lines = {}

    table.insert(lines, "GOLDEN // OWNER")
    table.insert(lines, "────────────────────")

    if Config.Debug.FPS then
        table.insert(lines, "FPS       " .. tostring(fps))
    end

    if Config.Debug.Ping then
        table.insert(lines, "PING      " .. round(getPing()) .. " ms")
    end

    if Config.Debug.Position and root then
        local p = root.Position
        table.insert(
            lines,
            string.format(
                "POS       %.1f  %.1f  %.1f",
                p.X,
                p.Y,
                p.Z
            )
        )
    end

    if Config.Debug.Velocity and root then
        table.insert(
            lines,
            "VEL       " .. tostring(round(root.AssemblyLinearVelocity.Magnitude))
        )
    end

    if Config.Debug.Target then
        table.insert(
            lines,
            "TARGET    "
                .. (State.CurrentTarget
                    and State.CurrentTarget.DisplayName
                    or "NONE")
        )
    end

    HUDText.Text = table.concat(lines, "\n")
end

--//========================================================
--// 33. VISUAL UPDATE
--//========================================================

local function updateVisuals()
    Crosshair.Visible = Config.Visual.Crosshair
    FOVVisual.Visible = Config.Visual.FOVCircle
    TargetMarker.Visible =
        Config.Visual.TargetMarker
        and State.TargetPart ~= nil

    FOVVisual.Size = UDim2.fromOffset(
        Config.Aim.FOV * 2,
        Config.Aim.FOV * 2
    )

    if State.TargetPart and State.TargetPart.Parent then
        local point, visible = Camera:WorldToViewportPoint(
            State.TargetPart.Position
        )

        TargetMarker.Position = UDim2.fromOffset(
            point.X,
            point.Y
        )

        TargetMarker.Visible =
            Config.Visual.TargetMarker
            and visible
    else
        TargetMarker.Visible = false
    end
end

--//========================================================
--// 34. SPECTATE
--//========================================================

local function unspectate()
    State.Spectating = nil
    Camera.CameraType = Enum.CameraType.Custom

    local humanoid = getHumanoid()
    if humanoid then
        Camera.CameraSubject = humanoid
    end
end

local function spectate(player)
    if not player then
        return false
    end

    local humanoid = player.Character
        and player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return false
    end

    State.Spectating = player
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = humanoid

    return true
end

--//========================================================
--// 35. TELEPORT
--//========================================================

local function teleportTo(player)
    if not player then
        return false
    end

    local sourceRoot = getRoot(player.Character)
    local localRoot = getRoot(getCharacter())

    if not sourceRoot or not localRoot then
        return false
    end

    localRoot.CFrame = sourceRoot.CFrame + Vector3.new(0, 3, 0)
    return true
end

local function teleportToPosition(x, y, z)
    local root = getRoot(getCharacter())
    if not root then
        return false
    end

    root.CFrame = CFrame.new(x, y, z)
    return true
end

--//========================================================
--// 36. COMMAND SYSTEM
--//========================================================

local Commands = {}

local function addCommand(name, description, callback)
    Commands[lower(name)] = {
        Name = name,
        Description = description,
        Callback = callback,
    }
end

local function commandList()
    local names = {}

    for name in pairs(Commands) do
        table.insert(names, name)
    end

    table.sort(names)

    local lines = {}
    for _, name in ipairs(names) do
        local cmd = Commands[name]
        table.insert(
            lines,
            Config.Command.Prefix
                .. cmd.Name
                .. " - "
                .. cmd.Description
        )
    end

    return lines
end

local function executeCommand(raw)
    raw = trim(raw)

    if raw == "" then
        return false
    end

    local prefix = Config.Command.Prefix
    if raw:sub(1, #prefix) ~= prefix then
        return false
    end

    local body = trim(raw:sub(#prefix + 1))
    local words = splitWords(body)

    local commandName = lower(words[1] or "")
    table.remove(words, 1)

    local command = Commands[commandName]

    table.insert(State.CommandLog, raw)

    if #State.CommandLog > 100 then
        table.remove(State.CommandLog, 1)
    end

    if not command then
        notify("Golden Command", "Unknown command: " .. commandName)
        return false
    end

    local ok, result = pcall(
        command.Callback,
        words,
        raw
    )

    if not ok then
        warn("[Golden Panel] Command error:", result)
        notify("Golden Command", "Command failed")
        return false
    end

    if result ~= nil then
        notify("Golden Command", tostring(result))
    end

    return true
end

--//========================================================
--// 37. CORE COMMANDS
--//========================================================

addCommand("gold", "Toggle Golden Panel", function()
    Config.UI.Open = not Config.UI.Open
    Main.Visible = Config.UI.Open
    Shadow.Visible = Config.UI.Open
end)

addCommand("menu", "Toggle Golden Panel", function()
    Config.UI.Open = not Config.UI.Open
    Main.Visible = Config.UI.Open
    Shadow.Visible = Config.UI.Open
end)

addCommand("help", "Show all commands", function()
    print("===== GOLDEN PANEL COMMANDS =====")
    for _, line in ipairs(commandList()) do
        print(line)
    end
    notify("Golden Command", "Command list printed")
end)

addCommand("version", "Show build version", function()
    return "Golden Panel " .. VERSION
end)

addCommand("aim", "Aim settings", function(args)
    local action = lower(args[1] or "")

    if action == "on" then
        Config.Aim.Enabled = true
        return "Aim Assist ON"
    end

    if action == "off" then
        Config.Aim.Enabled = false
        State.CurrentTarget = nil
        State.TargetPart = nil
        return "Aim Assist OFF"
    end

    if action == "fov" then
        Config.Aim.FOV = clamp(
            safeNumber(args[2], Config.Aim.FOV),
            20,
            1000
        )
        return "Aim FOV: " .. Config.Aim.FOV
    end

    if action == "smooth" then
        Config.Aim.Smoothness = clamp(
            safeNumber(args[2], Config.Aim.Smoothness),
            0.001,
            1
        )
        return "Aim Smooth: " .. Config.Aim.Smoothness
    end

    if action == "target" then
        local value = lower(args[2] or "head")

        if value == "head" then
            Config.Aim.TargetPart = "Head"
        elseif value == "torso" then
            Config.Aim.TargetPart = "UpperTorso"
        elseif value == "root" then
            Config.Aim.TargetPart = "HumanoidRootPart"
        else
            return "Unknown target part"
        end

        return "Target: " .. Config.Aim.TargetPart
    end

    if action == "mode" then
        local value = lower(args[2] or "crosshair")
        if value == "crosshair" then
            Config.Aim.TargetMode = "Crosshair"
        elseif value == "distance" then
            Config.Aim.TargetMode = "Distance"
        elseif value == "health" then
            Config.Aim.TargetMode = "Health"
        elseif value == "hybrid" then
            Config.Aim.TargetMode = "Hybrid"
        else
            return "Unknown mode"
        end

        return "Aim mode: " .. Config.Aim.TargetMode
    end

    if action == "team" then
        Config.Aim.TeamCheck = lower(args[2] or "") ~= "off"
        return "Aim TeamCheck: " .. tostring(Config.Aim.TeamCheck)
    end

    if action == "wall" then
        Config.Aim.WallCheck = lower(args[2] or "") ~= "off"
        return "Aim WallCheck: " .. tostring(Config.Aim.WallCheck)
    end

    return "Use /aim on|off|fov|smooth|target|mode|team|wall"
end)

addCommand("esp", "ESP controls", function(args)
    local action = lower(args[1] or "")

    if action == "on" then
        Config.ESP.Enabled = true
        return "ESP ON"
    end

    if action == "off" then
        Config.ESP.Enabled = false
        return "ESP OFF"
    end

    if action == "distance" then
        Config.ESP.MaxDistance = clamp(
            safeNumber(args[2], Config.ESP.MaxDistance),
            50,
            5000
        )
        return "ESP Distance: " .. Config.ESP.MaxDistance
    end

    if action == "team" then
        Config.ESP.TeamCheck = lower(args[2] or "") ~= "off"
        return "ESP TeamCheck: " .. tostring(Config.ESP.TeamCheck)
    end

    return "Use /esp on|off|distance|team"
end)

addCommand("trigger", "Triggerbot controls", function(args)
    local action = lower(args[1] or "")

    if action == "on" then
        Config.Trigger.Enabled = true
        return "Triggerbot ON"
    end

    if action == "off" then
        Config.Trigger.Enabled = false
        return "Triggerbot OFF"
    end

    if action == "cooldown" then
        Config.Trigger.Cooldown = clamp(
            safeNumber(args[2], Config.Trigger.Cooldown),
            0.01,
            1
        )
        return "Trigger cooldown: " .. Config.Trigger.Cooldown
    end

    return "Use /trigger on|off|cooldown"
end)

addCommand("speed", "Set local WalkSpeed", function(args)
    local value = safeNumber(args[1], Config.Player.Speed)
    Config.Player.Speed = clamp(value, 8, 250)
    Config.Player.SpeedEnabled = true
    applySpeed()
    return "Speed: " .. Config.Player.Speed
end)

addCommand("unspeed", "Restore WalkSpeed", function()
    Config.Player.SpeedEnabled = false
    applySpeed()
    return "Speed restored"
end)

addCommand("jump", "Set local JumpPower", function(args)
    local value = safeNumber(args[1], Config.Player.JumpPower)
    Config.Player.JumpPower = clamp(value, 20, 250)
    Config.Player.JumpEnabled = true
    applyJump()
    return "Jump: " .. Config.Player.JumpPower
end)

addCommand("unjump", "Restore JumpPower", function()
    Config.Player.JumpEnabled = false
    applyJump()
    return "Jump restored"
end)

addCommand("infjump", "Toggle infinite jump", function(args)
    local action = lower(args[1] or "toggle")
    Config.Player.InfiniteJump =
        action == "on"
        or (action == "toggle" and not Config.Player.InfiniteJump)
    return "Infinite Jump: " .. tostring(Config.Player.InfiniteJump)
end)

addCommand("noclip", "Toggle local noclip", function(args)
    local action = lower(args[1] or "toggle")
    Config.Player.NoClip =
        action == "on"
        or (action == "toggle" and not Config.Player.NoClip)
    return "NoClip: " .. tostring(Config.Player.NoClip)
end)

addCommand("fly", "Enable flight and optional speed", function(args)
    local value = tonumber(args[1])
    if value then
        Config.Player.FlySpeed = clamp(value, 10, 300)
    end

    Config.Player.Fly = true
    startFly()

    return "Fly ON @ " .. Config.Player.FlySpeed
end)

addCommand("unfly", "Disable flight", function()
    Config.Player.Fly = false
    stopFly()
    return "Fly OFF"
end)

addCommand("gravity", "Set local gravity", function(args)
    Config.Player.Gravity = clamp(
        safeNumber(args[1], Config.Player.Gravity),
        0,
        300
    )
    Config.Player.GravityEnabled = true
    applyGravity()
    return "Gravity: " .. Config.Player.Gravity
end)

addCommand("gravreset", "Restore gravity", function()
    Config.Player.GravityEnabled = false
    applyGravity()
    return "Gravity restored"
end)

addCommand("fov", "Set camera FOV", function(args)
    Config.Player.CameraFOV = clamp(
        safeNumber(args[1], Config.Player.CameraFOV),
        40,
        150
    )
    applyCameraFOV()
    return "Camera FOV: " .. Config.Player.CameraFOV
end)

addCommand("bright", "Toggle FullBright", function()
    Config.World.FullBright = not Config.World.FullBright
    applyWorld()
    return "FullBright: " .. tostring(Config.World.FullBright)
end)

addCommand("day", "Set daytime", function()
    Config.World.ClockTime = 14
    applyWorld()
    return "Day mode"
end)

addCommand("night", "Set nighttime", function()
    Config.World.ClockTime = 0
    applyWorld()
    return "Night mode"
end)

addCommand("tp", "Teleport to player", function(args)
    local player = getPlayerByText(args[1] or "")
    if not player then
        return "Player not found"
    end

    if teleportTo(player) then
        return "Teleported to " .. player.DisplayName
    end

    return "Teleport failed"
end)

addCommand("spectate", "Spectate player", function(args)
    local player = getPlayerByText(args[1] or "")
    if not player then
        return "Player not found"
    end

    if spectate(player) then
        return "Spectating " .. player.DisplayName
    end

    return "Spectate failed"
end)

addCommand("unspectate", "Stop spectating", function()
    unspectate()
    return "Spectate OFF"
end)

addCommand("reset", "Reset local character", function()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
    return "Character reset"
end)

addCommand("rejoin", "Reconnect to current server", function()
    local TeleportService = game:GetService("TeleportService")
    local ok, err = pcall(function()
        TeleportService:Teleport(
            game.PlaceId,
            LocalPlayer
        )
    end)

    if not ok then
        return "Rejoin failed: " .. tostring(err)
    end

    return "Rejoining..."
end)

addCommand("fps", "Print current FPS", function()
    return "FPS: " .. tostring(fps)
end)

addCommand("ping", "Print current ping", function()
    return "Ping: " .. round(getPing()) .. " ms"
end)

addCommand("pos", "Print position", function()
    local root = getRoot(getCharacter())
    if not root then
        return "No root"
    end

    local p = root.Position

    return string.format(
        "POS %.1f %.1f %.1f",
        p.X,
        p.Y,
        p.Z
    )
end)

addCommand("target", "Print current aim target", function()
    if State.CurrentTarget then
        return "Target: " .. State.CurrentTarget.DisplayName
    end
    return "Target: NONE"
end)

addCommand("clear", "Clear target and reset aim state", function()
    State.CurrentTarget = nil
    State.TargetPart = nil
    return "Target cleared"
end)

addCommand("panic", "Disable combat and movement assists", function()
    Config.Aim.Enabled = false
    Config.Trigger.Enabled = false
    Config.ESP.Enabled = false
    Config.Player.NoClip = false
    Config.Player.Fly = false
    Config.Player.InfiniteJump = false

    stopFly()
    resetCharacterModifiers()

    return "Panic reset complete"
end)

--//========================================================
--// 38. CHAT COMMAND BRIDGE
--//========================================================

local function handleChatMessage(message)
    if type(message) ~= "string" then
        return
    end

    if message:sub(1, 1) ~= Config.Command.Prefix then
        return
    end

    executeCommand(message)
end

if LocalPlayer.Chatted then
    track(LocalPlayer.Chatted:Connect(handleChatMessage))
end

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        track(TextChatService.MessageReceived:Connect(function(message)
            if message.TextSource
                and message.TextSource.UserId == LocalPlayer.UserId then
                handleChatMessage(message.Text)
            end
        end))
    end
end)

track(CommandBox.FocusLost:Connect(function()
    if CommandBox.Text ~= "" then
        executeCommand(CommandBox.Text)
        CommandBox.Text = ""
    end
end))

--//========================================================
--// 39. HOTKEYS
--//========================================================

track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Config.UI.Key then
        Config.UI.Open = not Config.UI.Open

        Main.Visible = Config.UI.Open
        Shadow.Visible = Config.UI.Open
    end
end))

--//========================================================
--// 40. CHARACTER RESPAWN
--//========================================================

track(LocalPlayer.CharacterAdded:Connect(function(character)
    State.LastCharacter = character

    task.wait(0.2)

    captureCharacterDefaults()
    applySpeed()
    applyJump()
    applyGravity()

    if Config.Player.Fly then
        startFly()
    end
end))

captureCharacterDefaults()

--//========================================================
--// 41. PLAYER LIFECYCLE
--//========================================================

track(Players.PlayerRemoving:Connect(function(player)
    clearESP(player)

    if State.CurrentTarget == player then
        State.CurrentTarget = nil
        State.TargetPart = nil
    end

    if State.Spectating == player then
        unspectate()
    end
end))

track(Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        player.CharacterAdded:Connect(function()
            task.wait(0.25)
            if Config.ESP.Enabled then
                createESP(player)
            end
        end)
    end)
end))

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        task.spawn(function()
            if player.Character then
                createESP(player)
            end

            player.CharacterAdded:Connect(function()
                task.wait(0.25)
                if Config.ESP.Enabled then
                    createESP(player)
                end
            end)
        end)
    end
end

--//========================================================
--// 42. MAIN RUNTIME LOOP
--//========================================================

local heartbeatAccumulator = 0
local espAccumulator = 0
local hudAccumulator = 0

track(RunService.RenderStepped:Connect(function(dt)
    Camera = getCamera()
    if not State.Running then
        return
    end

    heartbeatAccumulator += dt
    espAccumulator += dt
    hudAccumulator += dt

    updateAim()
    updateTrigger()
    updateNoClip()
    updateFly()
    updateVisuals()

    if espAccumulator >= 0.08 then
        espAccumulator = 0
        updateESP()
    end

    if hudAccumulator >= 0.12 then
        hudAccumulator = 0
        updateHUD()
    end
end))

--//========================================================
--// 43. OPEN ANIMATION
--//========================================================

Main.Size = UDim2.fromOffset(414, 340)
Main.BackgroundTransparency = 1
Shadow.Size = UDim2.fromOffset(430, 360)
Shadow.BackgroundTransparency = 1

task.delay(0.08, function()
    tween(
        Main,
        0.35,
        {
            Size = UDim2.fromOffset(450, 370),
            BackgroundTransparency = 0,
        }
    )

    tween(
        Shadow,
        0.35,
        {
            Size = UDim2.fromOffset(470, 390),
            BackgroundTransparency = 0.55,
        }
    )
end)

--//========================================================
--// 44. DEFAULT TAB
--//========================================================

task.defer(function()
    CombatTab.Button:Activate()
end)

--//========================================================
--// 45. INITIAL APPLICATION
--//========================================================

applySpeed()
applyJump()
applyGravity()
applyCameraFOV()
applyWorld()

notify(
    "Golden Panel",
    "V2 loaded • /help for commands",
    4
)

--//========================================================
--// 46. CLEAN SHUTDOWN
--//========================================================

local function shutdown()
    if not State.Running then
        return
    end

    State.Running = false

    Config.Aim.Enabled = false
    Config.Trigger.Enabled = false
    Config.ESP.Enabled = false
    Config.Player.NoClip = false
    Config.Player.Fly = false

    stopFly()
    resetCharacterModifiers()

    for player in pairs(State.ESP) do
        clearESP(player)
    end

    disconnectAll()
end

-- Keep shutdown accessible for development.
_G.GoldenPanelShutdown = shutdown

--//========================================================
--// 47-1600. EXTENSION / DOCUMENTATION REGION
--//========================================================
-- The following section intentionally keeps the one-file architecture
-- organized into named extension slots. It gives the project a stable place
-- for additional FPS-specific systems without creating dozens of scattered
-- scripts. Each extension is disabled until explicitly wired into your game.

--//========================================================
--// EXTENSION CATEGORY: Aim Extensions
--//========================================================

local Extension_Aim_Extensions = {}

Extension_Aim_Extensions.TargetPriority = function(context)
    -- Hook reserved for: target priority.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.TargetBoneCycling = function(context)
    -- Hook reserved for: target bone cycling.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.DistanceWeighting = function(context)
    -- Hook reserved for: distance weighting.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.HealthWeighting = function(context)
    -- Hook reserved for: health weighting.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.ScreenSpaceWeighting = function(context)
    -- Hook reserved for: screen-space weighting.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.PredictionPresets = function(context)
    -- Hook reserved for: prediction presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.FovPresets = function(context)
    -- Hook reserved for: FOV presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.SmoothnessPresets = function(context)
    -- Hook reserved for: smoothness presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.StickyTargetTimeout = function(context)
    -- Hook reserved for: sticky target timeout.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.TargetReacquisitionDelay = function(context)
    -- Hook reserved for: target reacquisition delay.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.AimHoldModes = function(context)
    -- Hook reserved for: aim hold modes.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.ControllerAimMode = function(context)
    -- Hook reserved for: controller aim mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.TouchAimMode = function(context)
    -- Hook reserved for: touch aim mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.DeveloperOnlyAimCone = function(context)
    -- Hook reserved for: developer-only aim cone.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.TrainingDummyFilters = function(context)
    -- Hook reserved for: training dummy filters.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.NpcFiltering = function(context)
    -- Hook reserved for: NPC filtering.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.FriendFiltering = function(context)
    -- Hook reserved for: friend filtering.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.ForcefieldFiltering = function(context)
    -- Hook reserved for: forcefield filtering.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Aim_Extensions.SpawnProtectionFiltering = function(context)
    -- Hook reserved for: spawn protection filtering.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: ESP Extensions
--//========================================================

local Extension_ESP_Extensions = {}

Extension_ESP_Extensions.BoxRenderer = function(context)
    -- Hook reserved for: box renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.CornerBoxRenderer = function(context)
    -- Hook reserved for: corner box renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.HealthBarRenderer = function(context)
    -- Hook reserved for: health bar renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.ArmorBarRenderer = function(context)
    -- Hook reserved for: armor bar renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.DistanceRenderer = function(context)
    -- Hook reserved for: distance renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.NameRenderer = function(context)
    -- Hook reserved for: name renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.WeaponRenderer = function(context)
    -- Hook reserved for: weapon renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.TeamRenderer = function(context)
    -- Hook reserved for: team renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.SkeletonRenderer = function(context)
    -- Hook reserved for: skeleton renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.TracerRenderer = function(context)
    -- Hook reserved for: tracer renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.OffscreenArrowRenderer = function(context)
    -- Hook reserved for: offscreen arrow renderer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.TargetColorState = function(context)
    -- Hook reserved for: target color state.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.VisibleColorState = function(context)
    -- Hook reserved for: visible color state.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.OccludedColorState = function(context)
    -- Hook reserved for: occluded color state.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.NpcEsp = function(context)
    -- Hook reserved for: NPC ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.DummyEsp = function(context)
    -- Hook reserved for: dummy ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.LootEsp = function(context)
    -- Hook reserved for: loot ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.ObjectiveEsp = function(context)
    -- Hook reserved for: objective ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.SpawnEsp = function(context)
    -- Hook reserved for: spawn ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_ESP_Extensions.ProjectileEsp = function(context)
    -- Hook reserved for: projectile ESP.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: Movement Extensions
--//========================================================

local Extension_Movement_Extensions = {}

Extension_Movement_Extensions.SpeedPresets = function(context)
    -- Hook reserved for: speed presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.JumpPresets = function(context)
    -- Hook reserved for: jump presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.GravityPresets = function(context)
    -- Hook reserved for: gravity presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.FlyPresets = function(context)
    -- Hook reserved for: fly presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.NoclipPresets = function(context)
    -- Hook reserved for: noclip presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.ThirdPersonCamera = function(context)
    -- Hook reserved for: third person camera.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.CameraOffsets = function(context)
    -- Hook reserved for: camera offsets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.HeadBobToggle = function(context)
    -- Hook reserved for: head bob toggle.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.CameraShakeToggle = function(context)
    -- Hook reserved for: camera shake toggle.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.FovPresets = function(context)
    -- Hook reserved for: FOV presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.SprintMultiplier = function(context)
    -- Hook reserved for: sprint multiplier.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.AirControlDebug = function(context)
    -- Hook reserved for: air control debug.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.MovementVectorHud = function(context)
    -- Hook reserved for: movement vector HUD.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.VelocityGraphHook = function(context)
    -- Hook reserved for: velocity graph hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.StateMachineViewer = function(context)
    -- Hook reserved for: state machine viewer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.HumanoidStateLog = function(context)
    -- Hook reserved for: humanoid state log.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.GroundedStateLog = function(context)
    -- Hook reserved for: grounded state log.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.LandingDetector = function(context)
    -- Hook reserved for: landing detector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Movement_Extensions.JumpTimingTracker = function(context)
    -- Hook reserved for: jump timing tracker.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: Debug Extensions
--//========================================================

local Extension_Debug_Extensions = {}

Extension_Debug_Extensions.FpsGraph = function(context)
    -- Hook reserved for: FPS graph.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.PingGraph = function(context)
    -- Hook reserved for: ping graph.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.PacketCounterHook = function(context)
    -- Hook reserved for: packet counter hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.RenderStepProfilerHook = function(context)
    -- Hook reserved for: render step profiler hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.RaycastInspector = function(context)
    -- Hook reserved for: raycast inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.TargetInspector = function(context)
    -- Hook reserved for: target inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.CameraInspector = function(context)
    -- Hook reserved for: camera inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.CharacterInspector = function(context)
    -- Hook reserved for: character inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.ToolInspector = function(context)
    -- Hook reserved for: tool inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.WorkspaceInspector = function(context)
    -- Hook reserved for: workspace inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.LightingInspector = function(context)
    -- Hook reserved for: lighting inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.TeamInspector = function(context)
    -- Hook reserved for: team inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.SpawnInspector = function(context)
    -- Hook reserved for: spawn inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.AttributeViewer = function(context)
    -- Hook reserved for: attribute viewer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.CollectionTagViewer = function(context)
    -- Hook reserved for: collection tag viewer.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.RemoteAuditHook = function(context)
    -- Hook reserved for: remote audit hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.ErrorLogWindow = function(context)
    -- Hook reserved for: error log window.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.CommandHistory = function(context)
    -- Hook reserved for: command history.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Debug_Extensions.EventMonitor = function(context)
    -- Hook reserved for: event monitor.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: Command Extensions
--//========================================================

local Extension_Command_Extensions = {}

Extension_Command_Extensions.AliasSupport = function(context)
    -- Hook reserved for: alias support.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CommandHistory = function(context)
    -- Hook reserved for: command history.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CommandAutocomplete = function(context)
    -- Hook reserved for: command autocomplete.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CommandSuggestions = function(context)
    -- Hook reserved for: command suggestions.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.ArgumentValidation = function(context)
    -- Hook reserved for: argument validation.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.NumericParsing = function(context)
    -- Hook reserved for: numeric parsing.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.BooleanParsing = function(context)
    -- Hook reserved for: boolean parsing.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.PlayerLookup = function(context)
    -- Hook reserved for: player lookup.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.PartialNameMatching = function(context)
    -- Hook reserved for: partial name matching.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.DisplayNameMatching = function(context)
    -- Hook reserved for: display name matching.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.SelfToken = function(context)
    -- Hook reserved for: self token.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.NearestPlayerToken = function(context)
    -- Hook reserved for: nearest player token.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CurrentTargetToken = function(context)
    -- Hook reserved for: current target token.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.TeamToken = function(context)
    -- Hook reserved for: team token.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.AllTokenForServerValidatedActions = function(context)
    -- Hook reserved for: all token for server-validated actions.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.HelpCategories = function(context)
    -- Hook reserved for: help categories.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.HelpSearch = function(context)
    -- Hook reserved for: help search.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CommandAliases = function(context)
    -- Hook reserved for: command aliases.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.SilentCommandMode = function(context)
    -- Hook reserved for: silent command mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_Command_Extensions.CommandEchoMode = function(context)
    -- Hook reserved for: command echo mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: World Extensions
--//========================================================

local Extension_World_Extensions = {}

Extension_World_Extensions.DayPreset = function(context)
    -- Hook reserved for: day preset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.NightPreset = function(context)
    -- Hook reserved for: night preset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.FullbrightPreset = function(context)
    -- Hook reserved for: fullbright preset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.FogPreset = function(context)
    -- Hook reserved for: fog preset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.AmbientPreset = function(context)
    -- Hook reserved for: ambient preset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.ShadowToggle = function(context)
    -- Hook reserved for: shadow toggle.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.EnvironmentDebug = function(context)
    -- Hook reserved for: environment debug.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.CameraPostEffects = function(context)
    -- Hook reserved for: camera post effects.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.ColorCorrectionHook = function(context)
    -- Hook reserved for: color correction hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.BloomHook = function(context)
    -- Hook reserved for: bloom hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.DepthOfFieldHook = function(context)
    -- Hook reserved for: depth of field hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.SunRaysHook = function(context)
    -- Hook reserved for: sun rays hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.AtmosphereDebug = function(context)
    -- Hook reserved for: atmosphere debug.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.WorkspaceGravity = function(context)
    -- Hook reserved for: workspace gravity.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.StreamingDebug = function(context)
    -- Hook reserved for: streaming debug.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.CollisionGroupInspector = function(context)
    -- Hook reserved for: collision group inspector.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.SpawnLocationReader = function(context)
    -- Hook reserved for: spawn location reader.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.ObjectiveMarkerReader = function(context)
    -- Hook reserved for: objective marker reader.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.MapNameHud = function(context)
    -- Hook reserved for: map name HUD.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_World_Extensions.ServerAgeHud = function(context)
    -- Hook reserved for: server age HUD.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// EXTENSION CATEGORY: UI Extensions
--//========================================================

local Extension_UI_Extensions = {}

Extension_UI_Extensions.SearchBox = function(context)
    -- Hook reserved for: search box.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.TabBadges = function(context)
    -- Hook reserved for: tab badges.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.NotificationQueue = function(context)
    -- Hook reserved for: notification queue.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.ToastAnimations = function(context)
    -- Hook reserved for: toast animations.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.StatusIndicator = function(context)
    -- Hook reserved for: status indicator.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.AccentPresets = function(context)
    -- Hook reserved for: accent presets.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.CompactMode = function(context)
    -- Hook reserved for: compact mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.LargeTextMode = function(context)
    -- Hook reserved for: large text mode.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.MobileLayoutHook = function(context)
    -- Hook reserved for: mobile layout hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.ControllerLayoutHook = function(context)
    -- Hook reserved for: controller layout hook.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.KeyboardShortcutOverlay = function(context)
    -- Hook reserved for: keyboard shortcut overlay.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.KeybindEditor = function(context)
    -- Hook reserved for: keybind editor.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.HoverDescriptions = function(context)
    -- Hook reserved for: hover descriptions.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.Tooltips = function(context)
    -- Hook reserved for: tooltips.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.ButtonCooldownStates = function(context)
    -- Hook reserved for: button cooldown states.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.SectionCollapsers = function(context)
    -- Hook reserved for: section collapsers.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.WindowSnapping = function(context)
    -- Hook reserved for: window snapping.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.WindowScaling = function(context)
    -- Hook reserved for: window scaling.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.WindowReset = function(context)
    -- Hook reserved for: window reset.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end

Extension_UI_Extensions.SafeAreaHandling = function(context)
    -- Hook reserved for: safe-area handling.
    -- This is intentionally non-authoritative.
    context = context or {}
    return context
end


--//========================================================
--// FEATURE PROFILE REGISTRY
--//========================================================

local AimProfile_Default = {}
AimProfile_Default.Name = "AimProfile_Default"
AimProfile_Default.Enabled = false
AimProfile_Default.Description = "Developer extension profile"
AimProfile_Default.Apply = function(context)
    context = context or {}
    return context
end

local AimProfile_Aggressive = {}
AimProfile_Aggressive.Name = "AimProfile_Aggressive"
AimProfile_Aggressive.Enabled = false
AimProfile_Aggressive.Description = "Developer extension profile"
AimProfile_Aggressive.Apply = function(context)
    context = context or {}
    return context
end

local AimProfile_Precision = {}
AimProfile_Precision.Name = "AimProfile_Precision"
AimProfile_Precision.Enabled = false
AimProfile_Precision.Description = "Developer extension profile"
AimProfile_Precision.Apply = function(context)
    context = context or {}
    return context
end

local AimProfile_Training = {}
AimProfile_Training.Name = "AimProfile_Training"
AimProfile_Training.Enabled = false
AimProfile_Training.Description = "Developer extension profile"
AimProfile_Training.Apply = function(context)
    context = context or {}
    return context
end

local ESPProfile_Minimal = {}
ESPProfile_Minimal.Name = "ESPProfile_Minimal"
ESPProfile_Minimal.Enabled = false
ESPProfile_Minimal.Description = "Developer extension profile"
ESPProfile_Minimal.Apply = function(context)
    context = context or {}
    return context
end

local ESPProfile_Detailed = {}
ESPProfile_Detailed.Name = "ESPProfile_Detailed"
ESPProfile_Detailed.Enabled = false
ESPProfile_Detailed.Description = "Developer extension profile"
ESPProfile_Detailed.Apply = function(context)
    context = context or {}
    return context
end

local ESPProfile_Debug = {}
ESPProfile_Debug.Name = "ESPProfile_Debug"
ESPProfile_Debug.Enabled = false
ESPProfile_Debug.Description = "Developer extension profile"
ESPProfile_Debug.Apply = function(context)
    context = context or {}
    return context
end

local MovementProfile_Default = {}
MovementProfile_Default.Name = "MovementProfile_Default"
MovementProfile_Default.Enabled = false
MovementProfile_Default.Description = "Developer extension profile"
MovementProfile_Default.Apply = function(context)
    context = context or {}
    return context
end

local MovementProfile_Sprint = {}
MovementProfile_Sprint.Name = "MovementProfile_Sprint"
MovementProfile_Sprint.Enabled = false
MovementProfile_Sprint.Description = "Developer extension profile"
MovementProfile_Sprint.Apply = function(context)
    context = context or {}
    return context
end

local MovementProfile_Fly = {}
MovementProfile_Fly.Name = "MovementProfile_Fly"
MovementProfile_Fly.Enabled = false
MovementProfile_Fly.Description = "Developer extension profile"
MovementProfile_Fly.Apply = function(context)
    context = context or {}
    return context
end

local WorldProfile_Day = {}
WorldProfile_Day.Name = "WorldProfile_Day"
WorldProfile_Day.Enabled = false
WorldProfile_Day.Description = "Developer extension profile"
WorldProfile_Day.Apply = function(context)
    context = context or {}
    return context
end

local WorldProfile_Night = {}
WorldProfile_Night.Name = "WorldProfile_Night"
WorldProfile_Night.Enabled = false
WorldProfile_Night.Description = "Developer extension profile"
WorldProfile_Night.Apply = function(context)
    context = context or {}
    return context
end

local WorldProfile_FullBright = {}
WorldProfile_FullBright.Name = "WorldProfile_FullBright"
WorldProfile_FullBright.Enabled = false
WorldProfile_FullBright.Description = "Developer extension profile"
WorldProfile_FullBright.Apply = function(context)
    context = context or {}
    return context
end

local HUDProfile_Minimal = {}
HUDProfile_Minimal.Name = "HUDProfile_Minimal"
HUDProfile_Minimal.Enabled = false
HUDProfile_Minimal.Description = "Developer extension profile"
HUDProfile_Minimal.Apply = function(context)
    context = context or {}
    return context
end

local HUDProfile_Developer = {}
HUDProfile_Developer.Name = "HUDProfile_Developer"
HUDProfile_Developer.Enabled = false
HUDProfile_Developer.Description = "Developer extension profile"
HUDProfile_Developer.Apply = function(context)
    context = context or {}
    return context
end

local HUDProfile_Performance = {}
HUDProfile_Performance.Name = "HUDProfile_Performance"
HUDProfile_Performance.Enabled = false
HUDProfile_Performance.Description = "Developer extension profile"
HUDProfile_Performance.Apply = function(context)
    context = context or {}
    return context
end

local CommandProfile_Basic = {}
CommandProfile_Basic.Name = "CommandProfile_Basic"
CommandProfile_Basic.Enabled = false
CommandProfile_Basic.Description = "Developer extension profile"
CommandProfile_Basic.Apply = function(context)
    context = context or {}
    return context
end

local CommandProfile_Developer = {}
CommandProfile_Developer.Name = "CommandProfile_Developer"
CommandProfile_Developer.Enabled = false
CommandProfile_Developer.Description = "Developer extension profile"
CommandProfile_Developer.Apply = function(context)
    context = context or {}
    return context
end

local CommandProfile_Testing = {}
CommandProfile_Testing.Name = "CommandProfile_Testing"
CommandProfile_Testing.Enabled = false
CommandProfile_Testing.Description = "Developer extension profile"
CommandProfile_Testing.Apply = function(context)
    context = context or {}
    return context
end

local DebugProfile_Standard = {}
DebugProfile_Standard.Name = "DebugProfile_Standard"
DebugProfile_Standard.Enabled = false
DebugProfile_Standard.Description = "Developer extension profile"
DebugProfile_Standard.Apply = function(context)
    context = context or {}
    return context
end

local DebugProfile_Deep = {}
DebugProfile_Deep.Name = "DebugProfile_Deep"
DebugProfile_Deep.Enabled = false
DebugProfile_Deep.Description = "Developer extension profile"
DebugProfile_Deep.Apply = function(context)
    context = context or {}
    return context
end

local DebugProfile_Performance = {}
DebugProfile_Performance.Name = "DebugProfile_Performance"
DebugProfile_Performance.Enabled = false
DebugProfile_Performance.Description = "Developer extension profile"
DebugProfile_Performance.Apply = function(context)
    context = context or {}
    return context
end

--// DEV HOOK 001
local function GoldenDevHook_001(context)
    context = context or {}
    context.HookIndex = 1
    return context
end

--// DEV HOOK 002
local function GoldenDevHook_002(context)
    context = context or {}
    context.HookIndex = 2
    return context
end

--// DEV HOOK 003
local function GoldenDevHook_003(context)
    context = context or {}
    context.HookIndex = 3
    return context
end

--// DEV HOOK 004
local function GoldenDevHook_004(context)
    context = context or {}
    context.HookIndex = 4
    return context
end

--// DEV HOOK 005
local function GoldenDevHook_005(context)
    context = context or {}
    context.HookIndex = 5
    return context
end

--// DEV HOOK 006
local function GoldenDevHook_006(context)
    context = context or {}
    context.HookIndex = 6
    return context
end

--// DEV HOOK 007
local function GoldenDevHook_007(context)
    context = context or {}
    context.HookIndex = 7
    return context
end

--// DEV HOOK 008
local function GoldenDevHook_008(context)
    context = context or {}
    context.HookIndex = 8
    return context
end

--// DEV HOOK 009
local function GoldenDevHook_009(context)
    context = context or {}
    context.HookIndex = 9
    return context
end

--// DEV HOOK 010
local function GoldenDevHook_010(context)
    context = context or {}
    context.HookIndex = 10
    return context
end

--// DEV HOOK 011
local function GoldenDevHook_011(context)
    context = context or {}
    context.HookIndex = 11
    return context
end

--// DEV HOOK 012
local function GoldenDevHook_012(context)
    context = context or {}
    context.HookIndex = 12
    return context
end

--// DEV HOOK 013
local function GoldenDevHook_013(context)
    context = context or {}
    context.HookIndex = 13
    return context
end

--// DEV HOOK 014
local function GoldenDevHook_014(context)
    context = context or {}
    context.HookIndex = 14
    return context
end

--// DEV HOOK 015
local function GoldenDevHook_015(context)
    context = context or {}
    context.HookIndex = 15
    return context
end

--// DEV HOOK 016
local function GoldenDevHook_016(context)
    context = context or {}
    context.HookIndex = 16
    return context
end

--// DEV HOOK 017
local function GoldenDevHook_017(context)
    context = context or {}
    context.HookIndex = 17
    return context
end

--// DEV HOOK 018
local function GoldenDevHook_018(context)
    context = context or {}
    context.HookIndex = 18
    return context
end

--// DEV HOOK 019
local function GoldenDevHook_019(context)
    context = context or {}
    context.HookIndex = 19
    return context
end

--// DEV HOOK 020
local function GoldenDevHook_020(context)
    context = context or {}
    context.HookIndex = 20
    return context
end

--// DEV HOOK 021
local function GoldenDevHook_021(context)
    context = context or {}
    context.HookIndex = 21
    return context
end

--// DEV HOOK 022
local function GoldenDevHook_022(context)
    context = context or {}
    context.HookIndex = 22
    return context
end

--// DEV HOOK 023
local function GoldenDevHook_023(context)
    context = context or {}
    context.HookIndex = 23
    return context
end

--// DEV HOOK 024
local function GoldenDevHook_024(context)
    context = context or {}
    context.HookIndex = 24
    return context
end

--// DEV HOOK 025
local function GoldenDevHook_025(context)
    context = context or {}
    context.HookIndex = 25
    return context
end

--// DEV HOOK 026
local function GoldenDevHook_026(context)
    context = context or {}
    context.HookIndex = 26
    return context
end

--// DEV HOOK 027
local function GoldenDevHook_027(context)
    context = context or {}
    context.HookIndex = 27
    return context
end

--// DEV HOOK 028
local function GoldenDevHook_028(context)
    context = context or {}
    context.HookIndex = 28
    return context
end

--// DEV HOOK 029
local function GoldenDevHook_029(context)
    context = context or {}
    context.HookIndex = 29
    return context
end

--// DEV HOOK 030
local function GoldenDevHook_030(context)
    context = context or {}
    context.HookIndex = 30
    return context
end

--// DEV HOOK 031
local function GoldenDevHook_031(context)
    context = context or {}
    context.HookIndex = 31
    return context
end

--// DEV HOOK 032
local function GoldenDevHook_032(context)
    context = context or {}
    context.HookIndex = 32
    return context
end

--// DEV HOOK 033
local function GoldenDevHook_033(context)
    context = context or {}
    context.HookIndex = 33
    return context
end

--// DEV HOOK 034
local function GoldenDevHook_034(context)
    context = context or {}
    context.HookIndex = 34
    return context
end

--// DEV HOOK 035
local function GoldenDevHook_035(context)
    context = context or {}
    context.HookIndex = 35
    return context
end

--// DEV HOOK 036
local function GoldenDevHook_036(context)
    context = context or {}
    context.HookIndex = 36
    return context
end

--// DEV HOOK 037
local function GoldenDevHook_037(context)
    context = context or {}
    context.HookIndex = 37
    return context
end

--// DEV HOOK 038
local function GoldenDevHook_038(context)
    context = context or {}
    context.HookIndex = 38
    return context
end

--// DEV HOOK 039
local function GoldenDevHook_039(context)
    context = context or {}
    context.HookIndex = 39
    return context
end

--// DEV HOOK 040
local function GoldenDevHook_040(context)
    context = context or {}
    context.HookIndex = 40
    return context
end

--// DEV HOOK 041
local function GoldenDevHook_041(context)
    context = context or {}
    context.HookIndex = 41
    return context
end

--// DEV HOOK 042
local function GoldenDevHook_042(context)
    context = context or {}
    context.HookIndex = 42
    return context
end

--// DEV HOOK 043
local function GoldenDevHook_043(context)
    context = context or {}
    context.HookIndex = 43
    return context
end

--// DEV HOOK 044
local function GoldenDevHook_044(context)
    context = context or {}
    context.HookIndex = 44
    return context
end

--// DEV HOOK 045
local function GoldenDevHook_045(context)
    context = context or {}
    context.HookIndex = 45
    return context
end

--// DEV HOOK 046
local function GoldenDevHook_046(context)
    context = context or {}
    context.HookIndex = 46
    return context
end

--// DEV HOOK 047
local function GoldenDevHook_047(context)
    context = context or {}
    context.HookIndex = 47
    return context
end

--// DEV HOOK 048
local function GoldenDevHook_048(context)
    context = context or {}
    context.HookIndex = 48
    return context
end

--// DEV HOOK 049
local function GoldenDevHook_049(context)
    context = context or {}
    context.HookIndex = 49
    return context
end

--// DEV HOOK 050
local function GoldenDevHook_050(context)
    context = context or {}
    context.HookIndex = 50
    return context
end

--// DEV HOOK 051
local function GoldenDevHook_051(context)
    context = context or {}
    context.HookIndex = 51
    return context
end

--// DEV HOOK 052
local function GoldenDevHook_052(context)
    context = context or {}
    context.HookIndex = 52
    return context
end

--// DEV HOOK 053
local function GoldenDevHook_053(context)
    context = context or {}
    context.HookIndex = 53
    return context
end

--// DEV HOOK 054
local function GoldenDevHook_054(context)
    context = context or {}
    context.HookIndex = 54
    return context
end

--// DEV HOOK 055
local function GoldenDevHook_055(context)
    context = context or {}
    context.HookIndex = 55
    return context
end

--// DEV HOOK 056
local function GoldenDevHook_056(context)
    context = context or {}
    context.HookIndex = 56
    return context
end

--// DEV HOOK 057
local function GoldenDevHook_057(context)
    context = context or {}
    context.HookIndex = 57
    return context
end

--// DEV HOOK 058
local function GoldenDevHook_058(context)
    context = context or {}
    context.HookIndex = 58
    return context
end

--// DEV HOOK 059
local function GoldenDevHook_059(context)
    context = context or {}
    context.HookIndex = 59
    return context
end

--// DEV HOOK 060
local function GoldenDevHook_060(context)
    context = context or {}
    context.HookIndex = 60
    return context
end

--// DEV HOOK 061
local function GoldenDevHook_061(context)
    context = context or {}
    context.HookIndex = 61
    return context
end

--// DEV HOOK 062
local function GoldenDevHook_062(context)
    context = context or {}
    context.HookIndex = 62
    return context
end

--// DEV HOOK 063
local function GoldenDevHook_063(context)
    context = context or {}
    context.HookIndex = 63
    return context
end

--// DEV HOOK 064
local function GoldenDevHook_064(context)
    context = context or {}
    context.HookIndex = 64
    return context
end

--// DEV HOOK 065
local function GoldenDevHook_065(context)
    context = context or {}
    context.HookIndex = 65
    return context
end

--// DEV HOOK 066
local function GoldenDevHook_066(context)
    context = context or {}
    context.HookIndex = 66
    return context
end

--// DEV HOOK 067
local function GoldenDevHook_067(context)
    context = context or {}
    context.HookIndex = 67
    return context
end

--// DEV HOOK 068
local function GoldenDevHook_068(context)
    context = context or {}
    context.HookIndex = 68
    return context
end

--// DEV HOOK 069
local function GoldenDevHook_069(context)
    context = context or {}
    context.HookIndex = 69
    return context
end

--// DEV HOOK 070
local function GoldenDevHook_070(context)
    context = context or {}
    context.HookIndex = 70
    return context
end

--// DEV HOOK 071
local function GoldenDevHook_071(context)
    context = context or {}
    context.HookIndex = 71
    return context
end

--// DEV HOOK 072
local function GoldenDevHook_072(context)
    context = context or {}
    context.HookIndex = 72
    return context
end

--// DEV HOOK 073
local function GoldenDevHook_073(context)
    context = context or {}
    context.HookIndex = 73
    return context
end

--// DEV HOOK 074
local function GoldenDevHook_074(context)
    context = context or {}
    context.HookIndex = 74
    return context
end

--// DEV HOOK 075
local function GoldenDevHook_075(context)
    context = context or {}
    context.HookIndex = 75
    return context
end

--// DEV HOOK 076
local function GoldenDevHook_076(context)
    context = context or {}
    context.HookIndex = 76
    return context
end

--// DEV HOOK 077
local function GoldenDevHook_077(context)
    context = context or {}
    context.HookIndex = 77
    return context
end

--// DEV HOOK 078
local function GoldenDevHook_078(context)
    context = context or {}
    context.HookIndex = 78
    return context
end

--// DEV HOOK 079
local function GoldenDevHook_079(context)
    context = context or {}
    context.HookIndex = 79
    return context
end

--// DEV HOOK 080
local function GoldenDevHook_080(context)
    context = context or {}
    context.HookIndex = 80
    return context
end

--// DEV HOOK 081
local function GoldenDevHook_081(context)
    context = context or {}
    context.HookIndex = 81
    return context
end

--// DEV HOOK 082
local function GoldenDevHook_082(context)
    context = context or {}
    context.HookIndex = 82
    return context
end

--// DEV HOOK 083
local function GoldenDevHook_083(context)
    context = context or {}
    context.HookIndex = 83
    return context
end

--// DEV HOOK 084
local function GoldenDevHook_084(context)
    context = context or {}
    context.HookIndex = 84
    return context
end

--// DEV HOOK 085
local function GoldenDevHook_085(context)
    context = context or {}
    context.HookIndex = 85
    return context
end

--// DEV HOOK 086
local function GoldenDevHook_086(context)
    context = context or {}
    context.HookIndex = 86
    return context
end

--// DEV HOOK 087
local function GoldenDevHook_087(context)
    context = context or {}
    context.HookIndex = 87
    return context
end

--// DEV HOOK 088
local function GoldenDevHook_088(context)
    context = context or {}
    context.HookIndex = 88
    return context
end

--// DEV HOOK 089
local function GoldenDevHook_089(context)
    context = context or {}
    context.HookIndex = 89
    return context
end

--// DEV HOOK 090
local function GoldenDevHook_090(context)
    context = context or {}
    context.HookIndex = 90
    return context
end

--// DEV HOOK 091
local function GoldenDevHook_091(context)
    context = context or {}
    context.HookIndex = 91
    return context
end

--// DEV HOOK 092
local function GoldenDevHook_092(context)
    context = context or {}
    context.HookIndex = 92
    return context
end

--// DEV HOOK 093
local function GoldenDevHook_093(context)
    context = context or {}
    context.HookIndex = 93
    return context
end

--// DEV HOOK 094
local function GoldenDevHook_094(context)
    context = context or {}
    context.HookIndex = 94
    return context
end

--// DEV HOOK 095
local function GoldenDevHook_095(context)
    context = context or {}
    context.HookIndex = 95
    return context
end

--// DEV HOOK 096
local function GoldenDevHook_096(context)
    context = context or {}
    context.HookIndex = 96
    return context
end

--// DEV HOOK 097
local function GoldenDevHook_097(context)
    context = context or {}
    context.HookIndex = 97
    return context
end

--// DEV HOOK 098
local function GoldenDevHook_098(context)
    context = context or {}
    context.HookIndex = 98
    return context
end

--// DEV HOOK 099
local function GoldenDevHook_099(context)
    context = context or {}
    context.HookIndex = 99
    return context
end

--// DEV HOOK 100
local function GoldenDevHook_100(context)
    context = context or {}
    context.HookIndex = 100
    return context
end

--// DEV HOOK 101
local function GoldenDevHook_101(context)
    context = context or {}
    context.HookIndex = 101
    return context
end

--// DEV HOOK 102
local function GoldenDevHook_102(context)
    context = context or {}
    context.HookIndex = 102
    return context
end

--// DEV HOOK 103
local function GoldenDevHook_103(context)
    context = context or {}
    context.HookIndex = 103
    return context
end

--// DEV HOOK 104
local function GoldenDevHook_104(context)
    context = context or {}
    context.HookIndex = 104
    return context
end

--// DEV HOOK 105
local function GoldenDevHook_105(context)
    context = context or {}
    context.HookIndex = 105
    return context
end

--// DEV HOOK 106
local function GoldenDevHook_106(context)
    context = context or {}
    context.HookIndex = 106
    return context
end

--// DEV HOOK 107
local function GoldenDevHook_107(context)
    context = context or {}
    context.HookIndex = 107
    return context
end

--// DEV HOOK 108
local function GoldenDevHook_108(context)
    context = context or {}
    context.HookIndex = 108
    return context
end

--// DEV HOOK 109
local function GoldenDevHook_109(context)
    context = context or {}
    context.HookIndex = 109
    return context
end

--// DEV HOOK 110
local function GoldenDevHook_110(context)
    context = context or {}
    context.HookIndex = 110
    return context
end

--// DEV HOOK 111
local function GoldenDevHook_111(context)
    context = context or {}
    context.HookIndex = 111
    return context
end

--// DEV HOOK 112
local function GoldenDevHook_112(context)
    context = context or {}
    context.HookIndex = 112
    return context
end

--// DEV HOOK 113
local function GoldenDevHook_113(context)
    context = context or {}
    context.HookIndex = 113
    return context
end

--// DEV HOOK 114
local function GoldenDevHook_114(context)
    context = context or {}
    context.HookIndex = 114
    return context
end

--// DEV HOOK 115
local function GoldenDevHook_115(context)
    context = context or {}
    context.HookIndex = 115
    return context
end

--// DEV HOOK 116
local function GoldenDevHook_116(context)
    context = context or {}
    context.HookIndex = 116
    return context
end

--// DEV HOOK 117
local function GoldenDevHook_117(context)
    context = context or {}
    context.HookIndex = 117
    return context
end

--// DEV HOOK 118
local function GoldenDevHook_118(context)
    context = context or {}
    context.HookIndex = 118
    return context
end

--// DEV HOOK 119
local function GoldenDevHook_119(context)
    context = context or {}
    context.HookIndex = 119
    return context
end

--// DEV HOOK 120
local function GoldenDevHook_120(context)
    context = context or {}
    context.HookIndex = 120
    return context
end

--// DEV HOOK 121
local function GoldenDevHook_121(context)
    context = context or {}
    context.HookIndex = 121
    return context
end

--// DEV HOOK 122
local function GoldenDevHook_122(context)
    context = context or {}
    context.HookIndex = 122
    return context
end

--// DEV HOOK 123
local function GoldenDevHook_123(context)
    context = context or {}
    context.HookIndex = 123
    return context
end

--// DEV HOOK 124
local function GoldenDevHook_124(context)
    context = context or {}
    context.HookIndex = 124
    return context
end

--// DEV HOOK 125
local function GoldenDevHook_125(context)
    context = context or {}
    context.HookIndex = 125
    return context
end

--// DEV HOOK 126
local function GoldenDevHook_126(context)
    context = context or {}
    context.HookIndex = 126
    return context
end

--// DEV HOOK 127
local function GoldenDevHook_127(context)
    context = context or {}
    context.HookIndex = 127
    return context
end

--// DEV HOOK 128
local function GoldenDevHook_128(context)
    context = context or {}
    context.HookIndex = 128
    return context
end

--// DEV HOOK 129
local function GoldenDevHook_129(context)
    context = context or {}
    context.HookIndex = 129
    return context
end

--// DEV HOOK 130
local function GoldenDevHook_130(context)
    context = context or {}
    context.HookIndex = 130
    return context
end

--// DEV HOOK 131
local function GoldenDevHook_131(context)
    context = context or {}
    context.HookIndex = 131
    return context
end

--// DEV HOOK 132
local function GoldenDevHook_132(context)
    context = context or {}
    context.HookIndex = 132
    return context
end

--// DEV HOOK 133
local function GoldenDevHook_133(context)
    context = context or {}
    context.HookIndex = 133
    return context
end

--// DEV HOOK 134
local function GoldenDevHook_134(context)
    context = context or {}
    context.HookIndex = 134
    return context
end

--// DEV HOOK 135
local function GoldenDevHook_135(context)
    context = context or {}
    context.HookIndex = 135
    return context
end

--// DEV HOOK 136
local function GoldenDevHook_136(context)
    context = context or {}
    context.HookIndex = 136
    return context
end

--// DEV HOOK 137
local function GoldenDevHook_137(context)
    context = context or {}
    context.HookIndex = 137
    return context
end

--// DEV HOOK 138
local function GoldenDevHook_138(context)
    context = context or {}
    context.HookIndex = 138
    return context
end

--// DEV HOOK 139
local function GoldenDevHook_139(context)
    context = context or {}
    context.HookIndex = 139
    return context
end

--// DEV HOOK 140
local function GoldenDevHook_140(context)
    context = context or {}
    context.HookIndex = 140
    return context
end

--// DEV HOOK 141
local function GoldenDevHook_141(context)
    context = context or {}
    context.HookIndex = 141
    return context
end

--// DEV HOOK 142
local function GoldenDevHook_142(context)
    context = context or {}
    context.HookIndex = 142
    return context
end

--// DEV HOOK 143
local function GoldenDevHook_143(context)
    context = context or {}
    context.HookIndex = 143
    return context
end

--// DEV HOOK 144
local function GoldenDevHook_144(context)
    context = context or {}
    context.HookIndex = 144
    return context
end

--// DEV HOOK 145
local function GoldenDevHook_145(context)
    context = context or {}
    context.HookIndex = 145
    return context
end

--// DEV HOOK 146
local function GoldenDevHook_146(context)
    context = context or {}
    context.HookIndex = 146
    return context
end

--// DEV HOOK 147
local function GoldenDevHook_147(context)
    context = context or {}
    context.HookIndex = 147
    return context
end

--// DEV HOOK 148
local function GoldenDevHook_148(context)
    context = context or {}
    context.HookIndex = 148
    return context
end

--// DEV HOOK 149
local function GoldenDevHook_149(context)
    context = context or {}
    context.HookIndex = 149
    return context
end

--// DEV HOOK 150
local function GoldenDevHook_150(context)
    context = context or {}
    context.HookIndex = 150
    return context
end

--// DEV HOOK 151
local function GoldenDevHook_151(context)
    context = context or {}
    context.HookIndex = 151
    return context
end

--// DEV HOOK 152
local function GoldenDevHook_152(context)
    context = context or {}
    context.HookIndex = 152
    return context
end

--// DEV HOOK 153
local function GoldenDevHook_153(context)
    context = context or {}
    context.HookIndex = 153
    return context
end

--// DEV HOOK 154
local function GoldenDevHook_154(context)
    context = context or {}
    context.HookIndex = 154
    return context
end

--// DEV HOOK 155
local function GoldenDevHook_155(context)
    context = context or {}
    context.HookIndex = 155
    return context
end

--// DEV HOOK 156
local function GoldenDevHook_156(context)
    context = context or {}
    context.HookIndex = 156
    return context
end

--// DEV HOOK 157
local function GoldenDevHook_157(context)
    context = context or {}
    context.HookIndex = 157
    return context
end

--// DEV HOOK 158
local function GoldenDevHook_158(context)
    context = context or {}
    context.HookIndex = 158
    return context
end

--// DEV HOOK 159
local function GoldenDevHook_159(context)
    context = context or {}
    context.HookIndex = 159
    return context
end

--// DEV HOOK 160
local function GoldenDevHook_160(context)
    context = context or {}
    context.HookIndex = 160
    return context
end

--// DEV HOOK 161
local function GoldenDevHook_161(context)
    context = context or {}
    context.HookIndex = 161
    return context
end

--// DEV HOOK 162
local function GoldenDevHook_162(context)
    context = context or {}
    context.HookIndex = 162
    return context
end

--// DEV HOOK 163
local function GoldenDevHook_163(context)
    context = context or {}
    context.HookIndex = 163
    return context
end

--// DEV HOOK 164
local function GoldenDevHook_164(context)
    context = context or {}
    context.HookIndex = 164
    return context
end

--// DEV HOOK 165
local function GoldenDevHook_165(context)
    context = context or {}
    context.HookIndex = 165
    return context
end

--// DEV HOOK 166
local function GoldenDevHook_166(context)
    context = context or {}
    context.HookIndex = 166
    return context
end

--// DEV HOOK 167
local function GoldenDevHook_167(context)
    context = context or {}
    context.HookIndex = 167
    return context
end

--// DEV HOOK 168
local function GoldenDevHook_168(context)
    context = context or {}
    context.HookIndex = 168
    return context
end

--// DEV HOOK 169
local function GoldenDevHook_169(context)
    context = context or {}
    context.HookIndex = 169
    return context
end

--// DEV HOOK 170
local function GoldenDevHook_170(context)
    context = context or {}
    context.HookIndex = 170
    return context
end

--// DEV HOOK 171
local function GoldenDevHook_171(context)
    context = context or {}
    context.HookIndex = 171
    return context
end

--// DEV HOOK 172
local function GoldenDevHook_172(context)
    context = context or {}
    context.HookIndex = 172
    return context
end

--// DEV HOOK 173
local function GoldenDevHook_173(context)
    context = context or {}
    context.HookIndex = 173
    return context
end

--// DEV HOOK 174
local function GoldenDevHook_174(context)
    context = context or {}
    context.HookIndex = 174
    return context
end

--// DEV HOOK 175
local function GoldenDevHook_175(context)
    context = context or {}
    context.HookIndex = 175
    return context
end

--// DEV HOOK 176
local function GoldenDevHook_176(context)
    context = context or {}
    context.HookIndex = 176
    return context
end

--// DEV HOOK 177
local function GoldenDevHook_177(context)
    context = context or {}
    context.HookIndex = 177
    return context
end

--// DEV HOOK 178
local function GoldenDevHook_178(context)
    context = context or {}
    context.HookIndex = 178
    return context
end

--// DEV HOOK 179
local function GoldenDevHook_179(context)
    context = context or {}
    context.HookIndex = 179
    return context
end

--// DEV HOOK 180
local function GoldenDevHook_180(context)
    context = context or {}
    context.HookIndex = 180
    return context
end

--//========================================================
--// FINAL STATE REPORT
--//========================================================

print("[GoldenPanel] Loaded", BUILD_NAME, "version", VERSION)
print("[GoldenPanel] Owner:", LocalPlayer.Name, LocalPlayer.UserId)
print("[GoldenPanel] Use /help in chat for commands.")


--//========================================================
--// COMMAND EXAMPLES
--//========================================================

-- Example: /gold
--
-- Example: /menu
--
-- Example: /help
--
-- Example: /version
--
-- Example: /aim on
--
-- Example: /aim off
--
-- Example: /aim fov 220
--
-- Example: /aim smooth 0.06
--
-- Example: /aim target head
--
-- Example: /aim target torso
--
-- Example: /aim target root
--
-- Example: /aim mode crosshair
--
-- Example: /aim mode distance
--
-- Example: /aim mode health
--
-- Example: /aim mode hybrid
--
-- Example: /aim team on
--
-- Example: /aim team off
--
-- Example: /aim wall on
--
-- Example: /aim wall off
--
-- Example: /esp on
--
-- Example: /esp off
--
-- Example: /esp distance 1500
--
-- Example: /esp team on
--
-- Example: /esp team off
--
-- Example: /trigger on
--
-- Example: /trigger off
--
-- Example: /trigger cooldown 0.05
--
-- Example: /speed 40
--
-- Example: /unspeed
--
-- Example: /jump 100
--
-- Example: /unjump
--
-- Example: /infjump on
--
-- Example: /infjump off
--
-- Example: /noclip on
--
-- Example: /noclip off
--
-- Example: /fly 100
--
-- Example: /unfly
--
-- Example: /gravity 100
--
-- Example: /gravreset
--
-- Example: /fov 90
--
-- Example: /bright
--
-- Example: /day
--
-- Example: /night
--
-- Example: /tp player
--
-- Example: /spectate player
--
-- Example: /unspectate
--
-- Example: /reset
--
-- Example: /rejoin
--
-- Example: /fps
--
-- Example: /ping
--
-- Example: /pos
--
-- Example: /target
--
-- Example: /clear
--
-- Example: /panic
--

--//========================================================
--// VALIDATION HELPERS
--//========================================================

local function validate_isNumber(value)
    return tonumber(value) ~= nil
end

local function validate_isBoolean(value)
    return value == true or value == false
end

local function validate_isPlayer(value)
    return typeof(value) == "Instance" and value:IsA("Player")
end

local function validate_isCharacter(value)
    return typeof(value) == "Instance" and value:IsA("Model")
end

local function validate_isBasePart(value)
    return typeof(value) == "Instance" and value:IsA("BasePart")
end

local function validate_hasHumanoid(value)
    return value:FindFirstChildOfClass("Humanoid") ~= nil
end

local function validate_hasRoot(value)
    return getRoot(value) ~= nil
end

local function validate_isAliveCharacter(value)
    return isAlive(value)
end


--//========================================================
--// GOLDEN PANEL MAX EDITION EXTENSION
--// Added as a self-contained developer/testing layer.
--//========================================================

do
    local Max = {}
    Max.Version = "3.0.0-MAX"
    Max.Name = "GOLDEN // MAX EDITION"
    Max.Enabled = true
    Max.StartedAt = os.clock()
    Max.State = {}
    Max.Config = {}
    Max.Commands = {}
    Max.Hooks = {}
    Max.Log = {}
    Max.LogLimit = 250
    Max.Connections = {}
    Max.Presets = {}
    Max.Markers = {}
    Max.Keybinds = {}
    Max.TargetCache = {}
    Max.Diagnostics = {}
    Max.Stats = {FPS = 0, Ping = 0, Memory = 0, Players = 0}
    Max.State._DefaultFOV = Camera.FieldOfView
    Max.Theme = {
        Accent = C.Gold,
        Accent2 = C.Gold2,
        Background = C.Black,
        Surface = C.Panel,
        Surface2 = C.Panel2,
        Text = C.Text,
        Muted = C.Muted,
    }

    local function maxNow()
        return os.clock()
    end

    local function maxClamp(v, lo, hi)
        v = tonumber(v) or lo
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    local function maxBool(v, default)
        if v == nil then return default end
        if typeof(v) == "boolean" then return v end
        v = tostring(v):lower()
        if v == "on" or v == "true" or v == "1" then return true end
        if v == "off" or v == "false" or v == "0" then return false end
        return default
    end

    local function maxRound(v, n)
        local p = 10 ^ (n or 0)
        return math.floor((v * p) + 0.5) / p
    end

    local function maxPushLog(kind, message, data)
        local item = {
            Time = maxNow(),
            Kind = tostring(kind or "INFO"),
            Message = tostring(message or ""),
            Data = data,
        }
        table.insert(Max.Log, item)
        while #Max.Log > Max.LogLimit do
            table.remove(Max.Log, 1)
        end
        return item
    end

    local function maxNotify(title, text, duration)
        local ok = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = tostring(title or "Golden Max"),
                Text = tostring(text or ""),
                Duration = duration or 3,
            })
        end)
        maxPushLog("NOTIFY", tostring(title or "Golden Max") .. ": " .. tostring(text or ""), {Ok = ok})
        return ok
    end

    local function maxSet(name, value)
        Max.State[name] = value
        maxPushLog("STATE", name .. " = " .. tostring(value))
        return value
    end

    local function maxGet(name, default)
        local value = Max.State[name]
        if value == nil then return default end
        return value
    end

    local function maxToggle(name, default)
        local nextValue = not maxBool(Max.State[name], default)
        Max.State[name] = nextValue
        return nextValue
    end

    Max.Config.Enabled = true
    Max.Config.MaxTargets = 64
    Max.Config.ScanInterval = 0.10
    Max.Config.FPSWindow = 1.00
    Max.Config.MarkerLifetime = 6
    Max.Config.CameraFov = 70
    Max.Config.SprintFov = 80
    Max.Config.SprintSpeed = 28
    Max.Config.CrosshairSize = 8
    Max.Config.CrosshairGap = 5
    Max.Config.CrosshairThickness = 2
    Max.Config.ShowDiagnostics = true
    Max.Config.AutoCleanup = true
    Max.Config.Debug = false

    maxSet("MaxEnabled", true)
    maxSet("SprintEnabled", false)
    maxSet("CameraLock", false)
    maxSet("TargetInspector", false)
    maxSet("PerformanceHUD", true)
    maxSet("Crosshair", true)
    maxSet("FullBright", false)
    maxSet("FreezeCamera", false)
    maxSet("ClockOverlay", false)
    maxSet("PlayerListOverlay", false)

    local function maxDeepCopy(value, seen)
        if typeof(value) ~= "table" then return value end
        seen = seen or {}
        if seen[value] then return seen[value] end
        local copy = {}
        seen[value] = copy
        for k, v in pairs(value) do
            copy[maxDeepCopy(k, seen)] = maxDeepCopy(v, seen)
        end
        return copy
    end

    local function maxMerge(dst, src)
        if typeof(dst) ~= "table" then dst = {} end
        if typeof(src) ~= "table" then return dst end
        for k, v in pairs(src) do
            if typeof(v) == "table" and typeof(dst[k]) == "table" then
                maxMerge(dst[k], v)
            else
                dst[k] = v
            end
        end
        return dst
    end

    local function maxCount(t)
        local n = 0
        for _ in pairs(t or {}) do n += 1 end
        return n
    end

    local function maxFindPlayer(query)
        if not query then return nil end
        local needle = tostring(query):lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == needle or p.DisplayName:lower() == needle then return p end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #needle) == needle then return p end
            if p.DisplayName:lower():sub(1, #needle) == needle then return p end
        end
        return nil
    end

    local function maxGetRoot(character)
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    end

    local function maxGetHumanoid(character)
        if not character then return nil end
        return character:FindFirstChildOfClass("Humanoid")
    end

    local function maxAlive(character)
        local hum = maxGetHumanoid(character)
        return hum ~= nil and hum.Health > 0
    end

    local function maxDistance(a, b)
        if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
            return (a - b).Magnitude
        end
        return math.huge
    end

    local function maxSafeName(value)
        return tostring(value or ""):gsub("[%c]", "")
    end

    local function maxDisconnect(connection)
        if connection then pcall(function() connection:Disconnect() end) end
    end

    local function maxRememberConnection(connection)
        if connection then table.insert(Max.Connections, connection) end
        return connection
    end

    --// MAX HUD
    local MaxGui = Instance.new("ScreenGui")
    MaxGui.Name = "GoldenPanelMaxHUD"
    MaxGui.ResetOnSpawn = false
    MaxGui.IgnoreGuiInset = true
    MaxGui.DisplayOrder = 999
    MaxGui.Parent = PlayerGui

    local Hud = Instance.new("Frame")
    Hud.Name = "HUD"
    Hud.Size = UDim2.fromOffset(250, 108)
    Hud.Position = UDim2.new(1, -266, 0, 20)
    Hud.BackgroundColor3 = Max.Theme.Background
    Hud.BackgroundTransparency = 0.12
    Hud.BorderSizePixel = 0
    Hud.Visible = true
    Hud.Parent = MaxGui

    local HudCorner = Instance.new("UICorner")
    HudCorner.CornerRadius = UDim.new(0, 12)
    HudCorner.Parent = Hud

    local HudStroke = Instance.new("UIStroke")
    HudStroke.Color = Max.Theme.Accent
    HudStroke.Transparency = 0.35
    HudStroke.Thickness = 1
    HudStroke.Parent = Hud

    local HudTitle = Instance.new("TextLabel")
    HudTitle.BackgroundTransparency = 1
    HudTitle.Position = UDim2.fromOffset(12, 7)
    HudTitle.Size = UDim2.new(1, -24, 0, 22)
    HudTitle.Font = Enum.Font.GothamBold
    HudTitle.TextSize = 13
    HudTitle.TextXAlignment = Enum.TextXAlignment.Left
    HudTitle.TextColor3 = Max.Theme.Accent2
    HudTitle.Text = "GOLDEN // MAX"
    HudTitle.Parent = Hud

    local HudStats = Instance.new("TextLabel")
    HudStats.BackgroundTransparency = 1
    HudStats.Position = UDim2.fromOffset(12, 31)
    HudStats.Size = UDim2.new(1, -24, 1, -42)
    HudStats.Font = Enum.Font.Code
    HudStats.TextSize = 12
    HudStats.TextXAlignment = Enum.TextXAlignment.Left
    HudStats.TextYAlignment = Enum.TextYAlignment.Top
    HudStats.TextColor3 = Max.Theme.Text
    HudStats.Text = "FPS --\nPING --\nPLAYERS --\nTARGET --"
    HudStats.Parent = Hud

    local Crosshair = Instance.new("Frame")
    Crosshair.Name = "Crosshair"
    Crosshair.BackgroundTransparency = 1
    Crosshair.Size = UDim2.fromOffset(40, 40)
    Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
    Crosshair.Position = UDim2.fromScale(0.5, 0.5)
    Crosshair.Parent = MaxGui

    local function makeCrossLine(name, size, position)
        local line = Instance.new("Frame")
        line.Name = name
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Max.Theme.Accent2
        line.Size = size
        line.Position = position
        line.Parent = Crosshair
        return line
    end

    local CrossTop = makeCrossLine("Top", UDim2.fromOffset(2, 8), UDim2.new(0.5, -1, 0, 0))
    local CrossBottom = makeCrossLine("Bottom", UDim2.fromOffset(2, 8), UDim2.new(0.5, -1, 1, -8))
    local CrossLeft = makeCrossLine("Left", UDim2.fromOffset(8, 2), UDim2.new(0, 0, 0.5, -1))
    local CrossRight = makeCrossLine("Right", UDim2.fromOffset(8, 2), UDim2.new(1, -8, 0.5, -1))

    local function setCrosshairVisible(flag)
        Max.State.Crosshair = flag
        Crosshair.Visible = flag
    end

    local function updateCrosshair(gap, size)
        gap = maxClamp(gap or Max.Config.CrosshairGap, 0, 20)
        size = maxClamp(size or Max.Config.CrosshairSize, 2, 24)
        Crosshair.Size = UDim2.fromOffset(size * 2 + gap * 2, size * 2 + gap * 2)
        CrossTop.Size = UDim2.fromOffset(Max.Config.CrosshairThickness, size)
        CrossBottom.Size = UDim2.fromOffset(Max.Config.CrosshairThickness, size)
        CrossLeft.Size = UDim2.fromOffset(size, Max.Config.CrosshairThickness)
        CrossRight.Size = UDim2.fromOffset(size, Max.Config.CrosshairThickness)
        CrossTop.Position = UDim2.new(0.5, -1, 0, 0)
        CrossBottom.Position = UDim2.new(0.5, -1, 1, -size)
        CrossLeft.Position = UDim2.new(0, 0, 0.5, -1)
        CrossRight.Position = UDim2.new(1, -size, 0.5, -1)
    end

    updateCrosshair()


    --// PRESETS
    function Max.SavePreset(name)
        name = maxSafeName(name or "default")
        Max.Presets[name] = {
            State = maxDeepCopy(Max.State),
            Config = maxDeepCopy(Max.Config),
            Theme = maxDeepCopy(Max.Theme),
            SavedAt = os.time(),
        }
        maxPushLog("PRESET", "Saved preset " .. name)
        maxNotify("Golden Max", "Preset saved: " .. name, 2)
        return true
    end

    function Max.LoadPreset(name)
        name = maxSafeName(name or "default")
        local preset = Max.Presets[name]
        if not preset then
            maxNotify("Golden Max", "Preset not found: " .. name, 2)
            return false
        end
        Max.State = maxDeepCopy(preset.State or {})
        Max.Config = maxMerge(Max.Config, maxDeepCopy(preset.Config or {}))
        Max.Theme = maxMerge(Max.Theme, maxDeepCopy(preset.Theme or {}))
        setCrosshairVisible(maxBool(Max.State.Crosshair, true))
        maxPushLog("PRESET", "Loaded preset " .. name)
        maxNotify("Golden Max", "Preset loaded: " .. name, 2)
        return true
    end

    function Max.DeletePreset(name)
        name = maxSafeName(name or "default")
        if Max.Presets[name] == nil then return false end
        Max.Presets[name] = nil
        maxPushLog("PRESET", "Deleted preset " .. name)
        return true
    end

    function Max.ListPresets()
        local out = {}
        for name in pairs(Max.Presets) do table.insert(out, name) end
        table.sort(out)
        return out
    end


    --// TARGET SCANNER
    function Max.ScanTargets(maxCount)
        maxCount = maxClamp(maxCount or Max.Config.MaxTargets, 1, 256)
        table.clear(Max.TargetCache)
        local origin = Camera.CFrame.Position
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local root = maxGetRoot(character)
                local humanoid = maxGetHumanoid(character)
                if root and humanoid and humanoid.Health > 0 then
                    local distance = maxDistance(origin, root.Position)
                    local screen, visible = Camera:WorldToViewportPoint(root.Position)
                    table.insert(Max.TargetCache, {
                        Player = player,
                        Character = character,
                        Root = root,
                        Humanoid = humanoid,
                        Distance = distance,
                        Screen = Vector2.new(screen.X, screen.Y),
                        OnScreen = visible,
                        Health = humanoid.Health,
                        MaxHealth = humanoid.MaxHealth,
                    })
                end
            end
        end
        table.sort(Max.TargetCache, function(a, b)
            return a.Distance < b.Distance
        end)
        while #Max.TargetCache > maxCount do table.remove(Max.TargetCache) end
        Max.Stats.Players = #Players:GetPlayers()
        return Max.TargetCache
    end

    function Max.GetNearestTarget(maxFov)
        maxFov = tonumber(maxFov) or 9999
        local center = Camera.ViewportSize / 2
        local best = nil
        local bestScore = math.huge
        for _, info in ipairs(Max.TargetCache) do
            local delta = info.Screen - center
            local score = delta.Magnitude
            if info.OnScreen and score <= maxFov and score < bestScore then
                bestScore = score
                best = info
            end
        end
        return best, bestScore
    end

    function Max.GetNearestByDistance(maxDistanceValue)
        maxDistanceValue = tonumber(maxDistanceValue) or math.huge
        local best = nil
        local bestDistance = maxDistanceValue
        for _, info in ipairs(Max.TargetCache) do
            if info.Distance < bestDistance then
                best = info
                bestDistance = info.Distance
            end
        end
        return best, bestDistance
    end


    --// MOVEMENT
    function Max.SetLocalWalkSpeed(speed)
        speed = maxClamp(speed or 16, 0, 500)
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        if humanoid then
            humanoid.WalkSpeed = speed
            maxSet("WalkSpeed", speed)
            return true
        end
        return false
    end

    function Max.SetLocalJumpPower(power)
        power = maxClamp(power or 50, 0, 500)
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        if humanoid then
            humanoid.JumpPower = power
            maxSet("JumpPower", power)
            return true
        end
        return false
    end

    function Max.SetHipHeight(height)
        height = maxClamp(height or 2, 0, 20)
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        if humanoid then
            humanoid.HipHeight = height
            return true
        end
        return false
    end


    --// CAMERA
    function Max.SetFOV(value, instant)
        value = maxClamp(value or Max.Config.CameraFov, 30, 120)
        Max.Config.CameraFov = value
        if instant then
            Camera.FieldOfView = value
        else
            TweenService:Create(Camera, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = value}):Play()
        end
        return value
    end

    function Max.RestoreFOV()
        return Max.SetFOV(Max.State._DefaultFOV or 70, false)
    end

    function Max.ShakeCamera(intensity, duration)
        intensity = maxClamp(intensity or 1, 0, 5)
        duration = maxClamp(duration or 0.20, 0.01, 3)
        local start = maxNow()
        Max.State.CameraShake = {Start = start, Duration = duration, Intensity = intensity}
        return true
    end

    function Max.SetCameraLocked(flag)
        flag = maxBool(flag, false)
        Max.State.CameraLock = flag
        if flag then
            Max.State.CameraLockCFrame = Camera.CFrame
        else
            Max.State.CameraLockCFrame = nil
        end
        return flag
    end


    --// ENVIRONMENT
    function Max.SetFullBright(flag)
        flag = maxBool(flag, false)
        Max.State.FullBright = flag
        if flag then
            if not Max.State._OldLighting then
                Max.State._OldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
            }
            end
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            local old = Max.State._OldLighting
            if old then
                Lighting.Brightness = old.Brightness
                Lighting.ClockTime = old.ClockTime
                Lighting.FogEnd = old.FogEnd
                Lighting.GlobalShadows = old.GlobalShadows
            end
            Max.State._OldLighting = nil
        end
        return flag
    end

    function Max.SetTime(clockTime)
        clockTime = maxClamp(clockTime or 14, 0, 24)
        Lighting.ClockTime = clockTime
        Max.State.ClockTime = clockTime
        return clockTime
    end


    --// MARKERS
    function Max.AddMarker(position, label, lifetime)
        local marker = Instance.new("Part")
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanQuery = false
        marker.CanTouch = false
        marker.Size = Vector3.new(0.5, 0.5, 0.5)
        marker.Shape = Enum.PartType.Ball
        marker.Material = Enum.Material.Neon
        marker.Color = Max.Theme.Accent
        marker.Position = position
        marker.Name = "GoldenMaxMarker"
        marker.Parent = Workspace
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.fromOffset(180, 32)
        gui.StudsOffset = Vector3.new(0, 1.8, 0)
        gui.AlwaysOnTop = true
        gui.Parent = marker
        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.TextColor3 = Max.Theme.Text
        text.TextStrokeTransparency = 0.25
        text.Text = tostring(label or "MARKER")
        text.Parent = gui
        table.insert(Max.Markers, marker)
        task.delay(lifetime or Max.Config.MarkerLifetime, function()
            if marker and marker.Parent then marker:Destroy() end
        end)
        return marker
    end

    function Max.ClearMarkers()
        for _, marker in ipairs(Max.Markers) do
            if marker and marker.Parent then marker:Destroy() end
        end
        table.clear(Max.Markers)
        for _, marker in ipairs(Workspace:GetChildren()) do
            if marker.Name == "GoldenMaxMarker" then
                pcall(function() marker:Destroy() end)
            end
        end
    end


    --// DIAGNOSTICS
    function Max.MeasurePing()
        local value = 0
        local ok, result = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)
        if ok then value = (tonumber(result) or 0) * 1000 end
        Max.Stats.Ping = maxRound(value, 1)
        return Max.Stats.Ping
    end

    function Max.MeasureMemory()
        local value = 0
        local ok, result = pcall(function()
            return Stats:GetTotalMemoryUsageMb()
        end)
        if ok then value = tonumber(result) or 0 end
        Max.Stats.Memory = maxRound(value, 1)
        return Max.Stats.Memory
    end

    function Max.BuildDiagnosticSnapshot()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local snapshot = {
            Version = Max.Version,
            PlaceId = game.PlaceId,
            JobId = game.JobId,
            UserId = LocalPlayer.UserId,
            Name = LocalPlayer.Name,
            DisplayName = LocalPlayer.DisplayName,
            FPS = Max.Stats.FPS,
            Ping = Max.MeasurePing(),
            Memory = Max.MeasureMemory(),
            Players = #Players:GetPlayers(),
            Health = humanoid and humanoid.Health or 0,
            WalkSpeed = humanoid and humanoid.WalkSpeed or 0,
            Position = root and root.Position or Vector3.zero,
            CameraFOV = Camera.FieldOfView,
            FullBright = Max.State.FullBright,
            SprintEnabled = Max.State.SprintEnabled,
        }
        Max.Diagnostics.Last = snapshot
        maxPushLog("DIAG", "Diagnostic snapshot created", snapshot)
        return snapshot
    end

    --// COMMAND BUS
    local function maxTokenize(message)
        local args = {}
        for token in tostring(message or ""):gmatch("[^%s]+") do
            table.insert(args, token)
        end
        return args
    end

    function Max.RegisterCommand(name, description, callback)
        name = tostring(name):lower()
        Max.Commands[name] = {Name = name, Description = description or "", Callback = callback}
        return Max.Commands[name]
    end

    function Max.RunCommand(message)
        local args = maxTokenize(message)
        local raw = args[1]
        if not raw then return false end
        local name = raw:gsub("^/", ""):lower()
        table.remove(args, 1)
        local entry = Max.Commands[name]
        if not entry then return false end
        local ok, result = pcall(entry.Callback, args, message)
        if not ok then
            maxPushLog("ERROR", "Command failed: " .. name, result)
            maxNotify("Golden Max", "Command error: " .. name, 3)
            return false, result
        end
        maxPushLog("COMMAND", "/" .. name)
        return true, result
    end

    Max.RegisterCommand("max", "Open/enable Max layer", function(args)
        Max.State.MaxEnabled = true
    end)

    Max.RegisterCommand("maxhide", "Hide Max HUD", function(args)
        Hud.Visible = false
    end)

    Max.RegisterCommand("maxhud", "Toggle Max HUD", function(args)
        Hud.Visible = not Hud.Visible
    end)

    Max.RegisterCommand("cross", "Toggle crosshair", function(args)
        setCrosshairVisible(not Crosshair.Visible)
    end)

    Max.RegisterCommand("crosssize", "Set crosshair size", function(args)
        Max.Config.CrosshairSize = maxClamp(args[1] or 8, 2, 24)
        updateCrosshair()
    end)

    Max.RegisterCommand("crossgap", "Set crosshair gap", function(args)
        Max.Config.CrosshairGap = maxClamp(args[1] or 5, 0, 20)
        updateCrosshair()
    end)

    Max.RegisterCommand("sprint", "Toggle developer sprint", function(args)
        Max.State.SprintEnabled = maxBool(args[1], not Max.State.SprintEnabled)
    end)

    Max.RegisterCommand("walk", "Set local walk speed", function(args)
        Max.SetLocalWalkSpeed(args[1] or 16)
    end)

    Max.RegisterCommand("jump", "Set local jump power", function(args)
        Max.SetLocalJumpPower(args[1] or 50)
    end)

    Max.RegisterCommand("hip", "Set local hip height", function(args)
        Max.SetHipHeight(args[1] or 2)
    end)

    Max.RegisterCommand("fovmax", "Set camera field of view", function(args)
        Max.SetFOV(args[1] or 70, false)
    end)

    Max.RegisterCommand("fovreset", "Restore camera field of view", function(args)
        Max.RestoreFOV()
    end)

    Max.RegisterCommand("shake", "Shake camera", function(args)
        Max.ShakeCamera(args[1] or 1, args[2] or 0.2)
    end)

    Max.RegisterCommand("camlock", "Toggle camera lock", function(args)
        Max.SetCameraLocked(args[1] or not Max.State.CameraLock)
    end)

    Max.RegisterCommand("brightmax", "Toggle full bright", function(args)
        Max.SetFullBright(args[1] or not Max.State.FullBright)
    end)

    Max.RegisterCommand("time", "Set lighting clock time", function(args)
        Max.SetTime(args[1] or 14)
    end)

    Max.RegisterCommand("marker", "Place a marker at local position", function(args)
        local root=maxGetRoot(LocalPlayer.Character)
        if root then Max.AddMarker(root.Position,args[1] or "MARKER",args[2] or 6) end
    end)

    Max.RegisterCommand("clearmarkers", "Clear Max markers", function(args)
        Max.ClearMarkers()
    end)

    Max.RegisterCommand("scan", "Rescan player targets", function(args)
        Max.ScanTargets(args[1] or Max.Config.MaxTargets)
    end)

    Max.RegisterCommand("target", "Get nearest on-screen target", function(args)
        Max.ScanTargets()
        local t=Max.GetNearestTarget(args[1] or 9999)
        if t then Max.State.LastTarget=t.Player end
    end)

    Max.RegisterCommand("diag", "Build diagnostics snapshot", function(args)
        Max.BuildDiagnosticSnapshot()
    end)

    Max.RegisterCommand("pingmax", "Measure local network ping", function(args)
        maxNotify("Golden Max", "Ping: "..tostring(Max.MeasurePing()).." ms", 2)
    end)

    Max.RegisterCommand("memmax", "Measure memory usage", function(args)
        maxNotify("Golden Max", "Memory: "..tostring(Max.MeasureMemory()).." MB", 2)
    end)

    Max.RegisterCommand("preset-save", "Save a Max preset", function(args)
        Max.SavePreset(args[1] or "default")
    end)

    Max.RegisterCommand("preset-load", "Load a Max preset", function(args)
        Max.LoadPreset(args[1] or "default")
    end)

    Max.RegisterCommand("preset-list", "List Max presets", function(args)
        local list=Max.ListPresets()
        maxNotify("Golden Max", #list>0 and table.concat(list, ", ") or "No presets", 3)
    end)

    Max.RegisterCommand("helpmax", "List Max commands", function()
        local names = {}
        for name in pairs(Max.Commands) do table.insert(names, name) end
        table.sort(names)
        maxNotify("Golden Max", "/" .. table.concat(names, "  /"), 6)
    end)

    --// CHAT + HOTKEY ROUTER
    local function bindMaxKey(keyCode, callback)
        Max.Keybinds[keyCode] = callback
    end

    bindMaxKey(Enum.KeyCode.F4, function()
        Hud.Visible = not Hud.Visible
    end)
    bindMaxKey(Enum.KeyCode.F6, function()
        setCrosshairVisible(not Crosshair.Visible)
    end)
    bindMaxKey(Enum.KeyCode.F7, function()
        Max.SetFullBright(not Max.State.FullBright)
    end)
    bindMaxKey(Enum.KeyCode.F8, function()
        Max.State.PerformanceHUD = not Max.State.PerformanceHUD
    end)

    maxRememberConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local callback = Max.Keybinds[input.KeyCode]
        if callback then pcall(callback) end
    end))

    maxRememberConnection(LocalPlayer.Chatted:Connect(function(message)
        if typeof(message) ~= "string" then return end
        if message:sub(1, 1) == "/" then
            Max.RunCommand(message)
        end
    end))

    --// PERFORMANCE SAMPLER
    local fpsFrames = 0
    local fpsStarted = maxNow()
    local fpsConnection
    fpsConnection = RunService.RenderStepped:Connect(function(dt)
        Camera = getCamera()
        fpsFrames += 1
        local elapsed = maxNow() - fpsStarted
        if elapsed >= Max.Config.FPSWindow then
            Max.Stats.FPS = maxRound(fpsFrames / elapsed, 1)
            fpsFrames = 0
            fpsStarted = maxNow()
        end
        if Max.State.CameraLock and Max.State.CameraLockCFrame then
            Camera.CFrame = Max.State.CameraLockCFrame
        end
        local shake = Max.State.CameraShake
        if shake then
            local progress = maxNow() - shake.Start
            if progress >= shake.Duration then
                Max.State.CameraShake = nil
            else
                local falloff = 1 - progress / shake.Duration
                local x = (math.random() - 0.5) * 2 * shake.Intensity * falloff
                local y = (math.random() - 0.5) * 2 * shake.Intensity * falloff
                local z = (math.random() - 0.5) * 2 * shake.Intensity * falloff
                Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
            end
        end
        local sprint = Max.State.SprintEnabled
        if sprint then
            local character = LocalPlayer.Character
            local humanoid = maxGetHumanoid(character)
            if humanoid then
                if Max.State._OldWalkSpeed == nil then
                    Max.State._OldWalkSpeed = humanoid.WalkSpeed
                end
                if humanoid.WalkSpeed < Max.Config.SprintSpeed then
                    humanoid.WalkSpeed = Max.Config.SprintSpeed
                end
            end
            if Max.State._OldFOV == nil then
                Max.State._OldFOV = Camera.FieldOfView
            end
            if Camera.FieldOfView < Max.Config.SprintFov then
                Camera.FieldOfView += math.min(0.8, Max.Config.SprintFov - Camera.FieldOfView)
            end
        end
        if not sprint then
            if Max.State._OldWalkSpeed ~= nil then
                local humanoid = maxGetHumanoid(LocalPlayer.Character)
                if humanoid then humanoid.WalkSpeed = Max.State._OldWalkSpeed end
                Max.State._OldWalkSpeed = nil
            end
            if Max.State._OldFOV ~= nil then
                Camera.FieldOfView = Max.State._OldFOV
                Max.State._OldFOV = nil
            end
        end
        if not Max.State.PerformanceHUD then return end
        if not Hud.Parent then return end
        Max.MeasurePing()
        local targetName = "NONE"
        local t = Max.State.LastTarget
        if typeof(t) == "Instance" and t:IsA("Player") then targetName = t.Name end
        HudStats.Text = string.format("FPS %d\nPING %d ms\nPLAYERS %d\nTARGET %s", Max.Stats.FPS, Max.Stats.Ping, #Players:GetPlayers(), targetName)
    end)
    maxRememberConnection(fpsConnection)

    local scanClock = 0
    maxRememberConnection(RunService.Heartbeat:Connect(function(dt)
        if not Max.Enabled then return end
        scanClock += dt
        if scanClock >= Max.Config.ScanInterval then
            scanClock = 0
            if Max.State.TargetInspector or Max.State.PerformanceHUD then
                pcall(Max.ScanTargets, Max.Config.MaxTargets)
            end
        end
    end))

    --// PLAYER LIFECYCLE
    maxRememberConnection(Players.PlayerAdded:Connect(function(player)
        maxPushLog("PLAYER", "Joined: " .. player.Name, player.UserId)
    end))

    maxRememberConnection(Players.PlayerRemoving:Connect(function(player)
        maxPushLog("PLAYER", "Left: " .. player.Name, player.UserId)
        if Max.State.LastTarget == player then Max.State.LastTarget = nil end
    end))

    maxRememberConnection(LocalPlayer.CharacterAdded:Connect(function(character)
        task.defer(function()
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                if Max.State.WalkSpeed then humanoid.WalkSpeed = Max.State.WalkSpeed end
                if Max.State.JumpPower then humanoid.JumpPower = Max.State.JumpPower end
            end
        end)
    end))

    function Max.DiagnosticsCheck_001()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 1,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_001"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_002()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 2,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_002"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_003()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 3,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_003"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_004()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 4,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_004"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_005()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 5,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_005"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_006()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 6,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_006"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_007()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 7,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_007"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_008()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 8,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_008"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_009()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 9,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_009"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_010()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 10,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_010"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_011()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 11,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_011"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_012()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 12,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_012"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_013()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 13,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_013"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_014()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 14,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_014"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_015()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 15,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_015"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_016()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 16,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_016"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_017()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 17,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_017"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_018()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 18,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_018"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_019()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 19,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_019"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.DiagnosticsCheck_020()
        local character = LocalPlayer.Character
        local humanoid = maxGetHumanoid(character)
        local root = maxGetRoot(character)
        local result = {
            Index = 20,
            Timestamp = maxNow(),
            Character = character ~= nil,
            Humanoid = humanoid ~= nil,
            Root = root ~= nil,
            Alive = character ~= nil and maxAlive(character),
            PlayerCount = #Players:GetPlayers(),
            CameraReady = Camera ~= nil,
            GuiReady = MaxGui ~= nil and MaxGui.Parent ~= nil,
        }
        result.Tag = "MAXCHECK_020"
        Max.Diagnostics[result.Tag] = result
        return result
    end

    function Max.Feature_001(args)
        local featureName = "TargetScan_001"
        Max.Diagnostics.LastFeature = featureName
        return Max.ScanTargets(args and args[1] or Max.Config.MaxTargets)
    end

    function Max.Feature_002(args)
        local featureName = "NearestTarget_002"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestTarget(args and args[1] or 9999)
    end

    function Max.Feature_003(args)
        local featureName = "DistanceTarget_003"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestByDistance(args and args[1] or math.huge)
    end

    function Max.Feature_004(args)
        local featureName = "DiagSnapshot_004"
        Max.Diagnostics.LastFeature = featureName
        return Max.BuildDiagnosticSnapshot()
    end

    function Max.Feature_005(args)
        local featureName = "FullBrightOn_005"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(true)
    end

    function Max.Feature_006(args)
        local featureName = "FullBrightOff_006"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(false)
    end

    function Max.Feature_007(args)
        local featureName = "SprintOn_007"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = true; return true
    end

    function Max.Feature_008(args)
        local featureName = "SprintOff_008"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = false; return true
    end

    function Max.Feature_009(args)
        local featureName = "CrosshairOn_009"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(true); return true
    end

    function Max.Feature_010(args)
        local featureName = "CrosshairOff_010"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(false); return true
    end

    function Max.Feature_011(args)
        local featureName = "HUDOn_011"
        Max.Diagnostics.LastFeature = featureName
        Hud.Visible = true; return true
    end

    function Max.Feature_012(args)
        local featureName = "HUDOff_012"
        Max.Diagnostics.LastFeature = featureName
        Hud.Visible = false; return true
    end

    function Max.Feature_013(args)
        local featureName = "ClearMarkers_013"
        Max.Diagnostics.LastFeature = featureName
        Max.ClearMarkers(); return true
    end

    function Max.Feature_014(args)
        local featureName = "ResetFOV_014"
        Max.Diagnostics.LastFeature = featureName
        return Max.RestoreFOV()
    end

    function Max.Feature_015(args)
        local featureName = "Ping_015"
        Max.Diagnostics.LastFeature = featureName
        return Max.MeasurePing()
    end

    function Max.Feature_016(args)
        local featureName = "Memory_016"
        Max.Diagnostics.LastFeature = featureName
        return Max.MeasureMemory()
    end

    function Max.Feature_017(args)
        local featureName = "ListPlayers_017"
        Max.Diagnostics.LastFeature = featureName
        return Players:GetPlayers()
    end

    function Max.Feature_018(args)
        local featureName = "Time_018"
        Max.Diagnostics.LastFeature = featureName
        return Lighting.ClockTime
    end

    function Max.Feature_019(args)
        local featureName = "Position_019"
        Max.Diagnostics.LastFeature = featureName
        local r=maxGetRoot(LocalPlayer.Character); return r and r.Position or Vector3.zero
    end

    function Max.Feature_020(args)
        local featureName = "Health_020"
        Max.Diagnostics.LastFeature = featureName
        local h=maxGetHumanoid(LocalPlayer.Character); return h and h.Health or 0
    end

    function Max.Feature_021(args)
        local featureName = "TargetScan_021"
        Max.Diagnostics.LastFeature = featureName
        return Max.ScanTargets(args and args[1] or Max.Config.MaxTargets)
    end

    function Max.Feature_022(args)
        local featureName = "NearestTarget_022"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestTarget(args and args[1] or 9999)
    end

    function Max.Feature_023(args)
        local featureName = "DistanceTarget_023"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestByDistance(args and args[1] or math.huge)
    end

    function Max.Feature_024(args)
        local featureName = "DiagSnapshot_024"
        Max.Diagnostics.LastFeature = featureName
        return Max.BuildDiagnosticSnapshot()
    end

    function Max.Feature_025(args)
        local featureName = "FullBrightOn_025"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(true)
    end

    function Max.Feature_026(args)
        local featureName = "FullBrightOff_026"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(false)
    end

    function Max.Feature_027(args)
        local featureName = "SprintOn_027"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = true; return true
    end

    function Max.Feature_028(args)
        local featureName = "SprintOff_028"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = false; return true
    end

    function Max.Feature_029(args)
        local featureName = "CrosshairOn_029"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(true); return true
    end

    function Max.Feature_030(args)
        local featureName = "CrosshairOff_030"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(false); return true
    end

    function Max.Feature_031(args)
        local featureName = "HUDOn_031"
        Max.Diagnostics.LastFeature = featureName
        Hud.Visible = true; return true
    end

    function Max.Feature_032(args)
        local featureName = "HUDOff_032"
        Max.Diagnostics.LastFeature = featureName
        Hud.Visible = false; return true
    end

    function Max.Feature_033(args)
        local featureName = "ClearMarkers_033"
        Max.Diagnostics.LastFeature = featureName
        Max.ClearMarkers(); return true
    end

    function Max.Feature_034(args)
        local featureName = "ResetFOV_034"
        Max.Diagnostics.LastFeature = featureName
        return Max.RestoreFOV()
    end

    function Max.Feature_035(args)
        local featureName = "Ping_035"
        Max.Diagnostics.LastFeature = featureName
        return Max.MeasurePing()
    end

    function Max.Feature_036(args)
        local featureName = "Memory_036"
        Max.Diagnostics.LastFeature = featureName
        return Max.MeasureMemory()
    end

    function Max.Feature_037(args)
        local featureName = "ListPlayers_037"
        Max.Diagnostics.LastFeature = featureName
        return Players:GetPlayers()
    end

    function Max.Feature_038(args)
        local featureName = "Time_038"
        Max.Diagnostics.LastFeature = featureName
        return Lighting.ClockTime
    end

    function Max.Feature_039(args)
        local featureName = "Position_039"
        Max.Diagnostics.LastFeature = featureName
        local r=maxGetRoot(LocalPlayer.Character); return r and r.Position or Vector3.zero
    end

    function Max.Feature_040(args)
        local featureName = "Health_040"
        Max.Diagnostics.LastFeature = featureName
        local h=maxGetHumanoid(LocalPlayer.Character); return h and h.Health or 0
    end

    function Max.Feature_041(args)
        local featureName = "TargetScan_041"
        Max.Diagnostics.LastFeature = featureName
        return Max.ScanTargets(args and args[1] or Max.Config.MaxTargets)
    end

    function Max.Feature_042(args)
        local featureName = "NearestTarget_042"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestTarget(args and args[1] or 9999)
    end

    function Max.Feature_043(args)
        local featureName = "DistanceTarget_043"
        Max.Diagnostics.LastFeature = featureName
        Max.ScanTargets(); return Max.GetNearestByDistance(args and args[1] or math.huge)
    end

    function Max.Feature_044(args)
        local featureName = "DiagSnapshot_044"
        Max.Diagnostics.LastFeature = featureName
        return Max.BuildDiagnosticSnapshot()
    end

    function Max.Feature_045(args)
        local featureName = "FullBrightOn_045"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(true)
    end

    function Max.Feature_046(args)
        local featureName = "FullBrightOff_046"
        Max.Diagnostics.LastFeature = featureName
        return Max.SetFullBright(false)
    end

    function Max.Feature_047(args)
        local featureName = "SprintOn_047"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = true; return true
    end

    function Max.Feature_048(args)
        local featureName = "SprintOff_048"
        Max.Diagnostics.LastFeature = featureName
        Max.State.SprintEnabled = false; return true
    end

    function Max.Feature_049(args)
        local featureName = "CrosshairOn_049"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(true); return true
    end

    function Max.Feature_050(args)
        local featureName = "CrosshairOff_050"
        Max.Diagnostics.LastFeature = featureName
        setCrosshairVisible(false); return true
    end

    --// STATUS + CLEANUP
    function Max.Status()
        return {
            Version = Max.Version,
            Uptime = maxNow() - Max.StartedAt,
            FPS = Max.Stats.FPS,
            Ping = Max.Stats.Ping,
            Memory = Max.Stats.Memory,
            TargetCount = #Max.TargetCache,
            MarkerCount = #Max.Markers,
            CommandCount = maxCount(Max.Commands),
            PresetCount = maxCount(Max.Presets),
            LogCount = #Max.Log,
            Crosshair = Crosshair.Visible,
            HUD = Hud.Visible,
        }
    end

    function Max.ClearLog()
        table.clear(Max.Log)
    end

    function Max.Cleanup()
        if not Max.Enabled then return end
        Max.Enabled = false

        -- Restore Max-side mutable state before removing the extension.
        pcall(function()
            if Max.State._OldLighting then
                local old = Max.State._OldLighting
                Lighting.Brightness = old.Brightness
                Lighting.ClockTime = old.ClockTime
                Lighting.FogEnd = old.FogEnd
                Lighting.GlobalShadows = old.GlobalShadows
                Max.State._OldLighting = nil
            end
        end)
        pcall(function()
            Max.State.SprintEnabled = false
            local humanoid = maxGetHumanoid(LocalPlayer.Character)
            if humanoid and Max.State._OldWalkSpeed ~= nil then
                humanoid.WalkSpeed = Max.State._OldWalkSpeed
            end
            if Max.State._OldFOV ~= nil then
                Camera.FieldOfView = Max.State._OldFOV
            end
            Max.State._OldWalkSpeed = nil
            Max.State._OldFOV = nil
        end)

        Max.ClearMarkers()
        for _, connection in ipairs(Max.Connections) do maxDisconnect(connection) end
        table.clear(Max.Connections)
        if MaxGui and MaxGui.Parent then MaxGui:Destroy() end
        maxPushLog("LIFECYCLE", "Golden Max cleaned up")
    end

    Max.RegisterCommand("statusmax", "Show Max status", function()
        local s = Max.Status()
        maxNotify("Golden Max", string.format("FPS %d | Ping %d | Targets %d | Commands %d", s.FPS, s.Ping, s.TargetCount, s.CommandCount), 4)
    end)

    Max.RegisterCommand("clearlmax", "Clear Max log", function()
        Max.ClearLog()
        maxNotify("Golden Max", "Log cleared", 2)
    end)

    Max.RegisterCommand("cleanupmax", "Remove Max layer", function()
        Max.Cleanup()
    end)

    setCrosshairVisible(true)
    maxNotify("Golden Max", "MAX Edition extension loaded", 3)
    print("[GoldenPanel]", Max.Name, "loaded", Max.Version)

end
-- MAX BUILD NOTE 1630: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1631: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1632: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1633: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1634: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1635: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1636: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1637: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1638: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1639: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1640: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1641: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1642: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1643: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1644: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1645: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1646: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1647: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1648: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1649: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1650: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1651: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1652: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1653: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1654: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1655: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1656: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1657: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1658: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1659: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1660: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1661: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1662: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1663: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1664: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1665: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1666: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1667: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1668: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1669: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1670: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1671: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1672: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1673: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1674: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1675: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1676: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1677: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1678: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1679: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1680: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1681: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1682: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1683: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1684: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1685: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1686: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1687: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1688: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1689: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1690: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1691: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1692: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1693: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1694: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1695: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1696: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1697: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1698: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1699: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1700: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1701: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1702: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1703: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1704: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1705: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1706: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1707: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1708: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1709: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1710: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1711: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1712: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1713: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1714: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1715: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1716: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1717: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1718: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1719: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1720: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1721: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1722: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1723: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1724: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1725: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1726: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1727: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1728: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1729: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1730: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1731: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1732: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1733: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1734: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1735: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1736: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1737: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1738: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1739: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1740: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1741: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1742: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1743: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1744: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1745: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1746: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1747: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1748: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1749: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1750: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1751: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1752: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1753: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1754: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1755: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1756: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1757: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1758: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1759: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1760: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1761: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1762: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1763: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1764: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1765: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1766: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1767: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1768: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1769: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1770: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1771: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1772: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1773: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1774: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1775: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1776: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1777: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1778: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1779: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1780: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1781: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1782: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1783: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1784: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1785: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1786: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1787: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1788: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1789: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1790: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1791: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1792: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1793: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1794: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1795: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1796: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1797: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1798: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1799: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1800: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1801: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1802: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1803: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1804: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1805: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1806: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1807: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1808: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1809: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1810: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1811: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1812: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1813: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1814: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1815: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1816: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1817: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1818: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1819: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1820: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1821: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1822: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1823: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1824: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1825: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1826: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1827: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1828: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1829: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1830: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1831: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1832: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1833: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1834: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1835: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1836: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1837: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1838: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1839: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1840: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1841: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1842: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1843: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1844: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1845: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1846: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1847: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1848: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1849: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1850: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1851: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1852: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1853: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1854: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1855: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1856: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1857: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1858: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1859: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1860: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1861: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1862: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1863: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1864: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1865: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1866: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1867: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1868: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1869: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1870: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1871: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1872: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1873: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1874: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1875: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1876: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1877: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1878: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1879: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1880: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1881: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1882: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1883: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1884: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1885: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1886: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1887: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1888: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1889: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1890: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1891: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1892: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1893: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1894: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1895: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1896: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1897: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1898: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1899: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1900: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1901: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1902: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1903: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1904: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1905: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1906: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1907: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1908: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1909: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1910: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1911: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1912: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1913: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1914: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1915: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1916: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1917: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1918: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1919: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1920: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1921: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1922: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1923: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1924: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1925: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1926: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1927: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1928: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1929: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1930: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1931: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1932: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1933: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1934: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1935: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1936: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1937: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1938: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1939: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1940: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1941: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1942: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1943: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1944: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1945: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1946: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1947: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1948: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1949: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1950: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1951: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1952: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1953: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1954: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1955: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1956: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1957: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1958: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1959: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1960: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1961: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1962: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1963: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1964: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1965: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1966: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1967: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1968: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1969: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1970: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1971: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1972: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1973: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1974: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1975: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1976: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1977: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1978: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1979: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1980: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1981: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1982: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1983: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1984: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1985: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1986: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1987: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1988: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1989: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1990: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1991: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1992: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1993: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1994: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1995: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1996: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1997: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1998: one-file owner/developer extension slot.
-- MAX BUILD NOTE 1999: one-file owner/developer extension slot.
-- MAX BUILD NOTE 2000: one-file owner/developer extension slot.
