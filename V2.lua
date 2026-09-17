local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local lineNum = 0
local dragging = false
local dragStart, startPos
local dragConn

local busy = false
local entries = {}

local IgnorePatterns = {
    "Locale not found",
    "reverting to",
    "Infinite yield possible",
    "Failed to load sound",
}

local function shouldIgnore(message)
    for _, pattern in ipairs(IgnorePatterns) do
        if message:find(pattern, 1, true) then return true end
    end
    return false
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char)
    local hum = getHumanoid(char)
    return hum and hum.RootPart
end

local function r15(plr)
    local hum = getHumanoid(plr.Character)
    return hum and hum.RigType == Enum.HumanoidRigType.R15
end

local function breakVelocity()
    local zero = Vector3.new(0, 0, 0)
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = zero
            part.AssemblyAngularVelocity = zero
        end
    end
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

local function copy(str)
    return pcall(function() setclipboard(str) end)
end

local function Sound(id)
    local s = Instance.new("Sound")
    s.SoundId = id; s.Volume = 1; s.Parent = SoundService; s:Play()
    Debris:AddItem(s, 5)
end

local screenGui = Instance.new("ScreenGui")
local hotbar = Instance.new("Frame")
local hotbarFix = Instance.new("Frame")
local title = Instance.new("TextButton")
local subtitle = Instance.new("TextLabel")
local window = Instance.new("Frame")
local content = Instance.new("ScrollingFrame")
local listLayout = Instance.new("UIListLayout", content)
local listPadding = Instance.new("UIPadding", content)

Instance.new("UICorner", window).CornerRadius = UDim.new(0, 8)
Instance.new("UICorner", hotbar).CornerRadius = UDim.new(0, 8)

screenGui.Name = "DevXConsole"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

local vp = camera.ViewportSize

window.Name = "Window"
window.Size = UDim2.new(0, 520, 0, 360)
window.Position = UDim2.new(0, vp.X/2-260, 0, vp.Y/2-180)
window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
window.BackgroundTransparency = 0.2
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.Parent = screenGui

hotbar.Name = "Hotbar"
hotbar.Size = UDim2.new(1, 0, 0, 32)
hotbar.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
hotbar.BorderSizePixel = 0
hotbar.Active = true
hotbar.Parent = window

hotbarFix.Size = UDim2.new(1, 0, 0, 10)
hotbarFix.Position = UDim2.new(0, 0, 1, -10)
hotbarFix.BackgroundColor3 = hotbar.BackgroundColor3
hotbarFix.BorderSizePixel = 0
hotbarFix.Parent = hotbar

title.Name = "Title"
title.AutoButtonColor = false
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(0, 50, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "DevX"
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = hotbar

subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 64, 0, 2)
subtitle.Size = UDim2.new(0, 100, 1, 0)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "by frontevill"
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = hotbar

local discordBtn = Instance.new("ImageButton")
discordBtn.Name = "Discord"
discordBtn.BackgroundTransparency = 1
discordBtn.Position = UDim2.new(1, -26, 0, 8)
discordBtn.Size = UDim2.new(0, 16, 0, 16)
discordBtn.Image = "rbxassetid://10734888000"
discordBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.ZIndex = 3
discordBtn.Parent = hotbar

local commandsToggle = Instance.new("ImageButton")
commandsToggle.Name = "CommandsToggle"
commandsToggle.BackgroundTransparency = 1
commandsToggle.Position = UDim2.new(1, -50, 0, 8)
commandsToggle.Size = UDim2.new(0, 16, 0, 16)
commandsToggle.Image = "rbxassetid://10734982144"
commandsToggle.ImageColor3 = Color3.fromRGB(255, 255, 255)
commandsToggle.ZIndex = 3
commandsToggle.Parent = hotbar

content.Name = "Content"
content.Position = UDim2.new(0, 0, 0, 32)
content.Size = UDim2.new(1, 0, 1, -32)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = window

listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 6)

local commandsPanel = Instance.new("Frame")
commandsPanel.Name = "CommandsPanel"
commandsPanel.Position = UDim2.new(0, 0, 0, 32)
commandsPanel.Size = UDim2.new(1, 0, 1, -32)
commandsPanel.BackgroundTransparency = 1
commandsPanel.BorderSizePixel = 0
commandsPanel.Visible = false
commandsPanel.Parent = window

local targetSection = Instance.new("Frame")
targetSection.Name = "TargetSection"
targetSection.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
targetSection.BackgroundTransparency = 0.2
targetSection.BorderSizePixel = 0
targetSection.Position = UDim2.new(0, 6, 0, 6)
targetSection.Size = UDim2.new(1, -12, 0, 84)
targetSection.Parent = commandsPanel
Instance.new("UICorner", targetSection).CornerRadius = UDim.new(0, 6)

local targetAvatar = Instance.new("ImageLabel")
targetAvatar.Name = "TargetAvatar"
targetAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
targetAvatar.BorderSizePixel = 0
targetAvatar.Position = UDim2.new(0, 8, 0, 8)
targetAvatar.Size = UDim2.new(0, 68, 0, 68)
targetAvatar.Image = ""
targetAvatar.Parent = targetSection
Instance.new("UICorner", targetAvatar).CornerRadius = UDim.new(0, 4)

local targetInfoFrame = Instance.new("Frame")
targetInfoFrame.BackgroundTransparency = 1
targetInfoFrame.Position = UDim2.new(0, 84, 0, 8)
targetInfoFrame.Size = UDim2.new(1, -168, 0, 68)
targetInfoFrame.Parent = targetSection

local targetDisplayName = Instance.new("TextLabel")
targetDisplayName.BackgroundTransparency = 1
targetDisplayName.Size = UDim2.new(1, 0, 0, 18)
targetDisplayName.Font = Enum.Font.GothamBold
targetDisplayName.TextSize = 14
targetDisplayName.TextColor3 = Color3.fromRGB(255, 255, 255)
targetDisplayName.TextXAlignment = Enum.TextXAlignment.Left
targetDisplayName.Text = "—"
targetDisplayName.Parent = targetInfoFrame

local targetUsername = Instance.new("TextLabel")
targetUsername.BackgroundTransparency = 1
targetUsername.Position = UDim2.new(0, 0, 0, 18)
targetUsername.Size = UDim2.new(1, 0, 0, 14)
targetUsername.Font = Enum.Font.Gotham
targetUsername.TextSize = 11
targetUsername.TextColor3 = Color3.fromRGB(150, 150, 150)
targetUsername.TextXAlignment = Enum.TextXAlignment.Left
targetUsername.Text = "@—"
targetUsername.Parent = targetInfoFrame

local targetId = Instance.new("TextLabel")
targetId.BackgroundTransparency = 1
targetId.Position = UDim2.new(0, 0, 0, 32)
targetId.Size = UDim2.new(1, 0, 0, 13)
targetId.Font = Enum.Font.Gotham
targetId.TextSize = 10
targetId.TextColor3 = Color3.fromRGB(120, 120, 120)
targetId.TextXAlignment = Enum.TextXAlignment.Left
targetId.Text = "ID: —"
targetId.Parent = targetInfoFrame

local targetCreated = Instance.new("TextLabel")
targetCreated.BackgroundTransparency = 1
targetCreated.Position = UDim2.new(0, 0, 0, 45)
targetCreated.Size = UDim2.new(1, 0, 0, 13)
targetCreated.Font = Enum.Font.Gotham
targetCreated.TextSize = 10
targetCreated.TextColor3 = Color3.fromRGB(120, 120, 120)
targetCreated.TextXAlignment = Enum.TextXAlignment.Left
targetCreated.Text = "Joined: —"
targetCreated.Parent = targetInfoFrame

local targetToolBtn = Instance.new("ImageButton")
targetToolBtn.Name = "TargetToolBtn"
targetToolBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
targetToolBtn.BorderSizePixel = 0
targetToolBtn.Position = UDim2.new(1, -46, 0, 10)
targetToolBtn.Size = UDim2.new(0, 38, 0, 38)
targetToolBtn.Image = "rbxassetid://13769558274"
targetToolBtn.ScaleType = Enum.ScaleType.Fit
targetToolBtn.Parent = targetSection
Instance.new("UICorner", targetToolBtn).CornerRadius = UDim.new(0, 4)

local targetToolLabel = Instance.new("TextLabel")
targetToolLabel.BackgroundTransparency = 1
targetToolLabel.Position = UDim2.new(1, -46, 0, 50)
targetToolLabel.Size = UDim2.new(0, 38, 0, 12)
targetToolLabel.Font = Enum.Font.Gotham
targetToolLabel.TextSize = 9
targetToolLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
targetToolLabel.TextXAlignment = Enum.TextXAlignment.Center
targetToolLabel.Text = "Click Tool"
targetToolLabel.Parent = targetSection

local targetSearchRow = Instance.new("Frame")
targetSearchRow.BackgroundTransparency = 1
targetSearchRow.Position = UDim2.new(0, 6, 0, 96)
targetSearchRow.Size = UDim2.new(1, -12, 0, 24)
targetSearchRow.Parent = commandsPanel

local targetSearchBox = Instance.new("TextBox")
targetSearchBox.Name = "TargetSearchBox"
targetSearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
targetSearchBox.BorderSizePixel = 0
targetSearchBox.Size = UDim2.new(1, 0, 1, 0)
targetSearchBox.Font = Enum.Font.Gotham
targetSearchBox.TextSize = 12
targetSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetSearchBox.PlaceholderText = "🔍  Search player name..."
targetSearchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
targetSearchBox.Text = ""
targetSearchBox.ClearTextOnFocus = false
targetSearchBox.TextXAlignment = Enum.TextXAlignment.Left
targetSearchBox.Parent = targetSearchRow
Instance.new("UICorner", targetSearchBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", targetSearchBox).PaddingLeft = UDim.new(0, 10)

local commandsList = Instance.new("ScrollingFrame")
commandsList.Name = "CommandsList"
commandsList.Position = UDim2.new(0, 0, 0, 126)
commandsList.Size = UDim2.new(1, 0, 1, -160)
commandsList.BackgroundTransparency = 1
commandsList.BorderSizePixel = 0
commandsList.ClipsDescendants = true
commandsList.ScrollBarThickness = 4
commandsList.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
commandsList.CanvasSize = UDim2.new(0, 0, 0, 0)
commandsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
commandsList.Parent = commandsPanel

local commandsListLayout = Instance.new("UIListLayout", commandsList)
commandsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
commandsListLayout.Padding = UDim.new(0, 4)

local commandsListPadding = Instance.new("UIPadding", commandsList)
commandsListPadding.PaddingTop = UDim.new(0, 6)
commandsListPadding.PaddingLeft = UDim.new(0, 6)
commandsListPadding.PaddingRight = UDim.new(0, 6)
commandsListPadding.PaddingBottom = UDim.new(0, 6)

local currentTarget = nil

local function setTarget(plr)
    currentTarget = plr
    targetDisplayName.Text = plr.DisplayName
    targetUsername.Text = "@"..plr.Name
    targetId.Text = "ID: "..tostring(plr.UserId)
    targetCreated.Text = "Joined: ..."
    targetAvatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size100x100)
    task.spawn(function()
        local ok, info = pcall(function()
            return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://users.roblox.com/v1/users/"..plr.UserId))
        end)
        if ok and info and info.created then
            targetCreated.Text = "Joined: "..tostring(info.created):sub(1, 10)
        end
    end)
end

setTarget(player)

targetSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = targetSearchBox.Text:lower()
    if q == "" then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then
            setTarget(p); break
        end
    end
end)

targetToolBtn.MouseButton1Click:Connect(function()
    for _, P in ipairs(player.Backpack:GetChildren()) do if P.Name == "ClickTarget" then P:Destroy() end end
    for _, P in ipairs(player.Character:GetChildren()) do if P.Name == "ClickTarget" then P:Destroy() end end
    local tool = Instance.new("Tool")
    tool.Name = "ClickTarget"
    tool.RequiresHandle = false
    tool.TextureId = "rbxassetid://13769558274"
    tool.ToolTip = "Choose Player"
    tool.Activated:Connect(function()
        local hit = player:GetMouse().Target
        if not hit or not hit.Parent then return end
        local p = Players:GetPlayerFromCharacter(hit.Parent) or Players:GetPlayerFromCharacter(hit.Parent.Parent)
        if p then setTarget(p) end
    end)
    tool.Parent = player.Backpack
end)

local inputRow = Instance.new("Frame")
inputRow.Name = "InputRow"
inputRow.Position = UDim2.new(0, 0, 1, -34)
inputRow.Size = UDim2.new(1, 0, 0, 34)
inputRow.BackgroundTransparency = 1
inputRow.BorderSizePixel = 0
inputRow.Parent = commandsPanel

local commandPrompt = Instance.new("TextLabel")
commandPrompt.Name = "Prompt"
commandPrompt.BackgroundTransparency = 1
commandPrompt.Position = UDim2.new(0, 10, 0, 8)
commandPrompt.Size = UDim2.new(0, 26, 0, 18)
commandPrompt.Font = Enum.Font.Code
commandPrompt.TextSize = 14
commandPrompt.TextColor3 = Color3.fromRGB(90, 220, 120)
commandPrompt.TextXAlignment = Enum.TextXAlignment.Left
commandPrompt.Text = ">>>"
commandPrompt.Parent = inputRow

local commandInput = Instance.new("TextBox")
commandInput.Name = "CommandInput"
commandInput.Position = UDim2.new(0, 38, 0, 6)
commandInput.Size = UDim2.new(1, -76, 0, 22)
commandInput.BackgroundTransparency = 1
commandInput.ClearTextOnFocus = false
commandInput.Font = Enum.Font.Code
commandInput.TextSize = 14
commandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
commandInput.PlaceholderText = "Input your command"
commandInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
commandInput.Text = ""
commandInput.TextXAlignment = Enum.TextXAlignment.Left
commandInput.Parent = inputRow

local sendBtn = Instance.new("ImageButton")
sendBtn.Name = "Send"
sendBtn.Size = UDim2.new(0, 18, 0, 18)
sendBtn.Position = UDim2.new(1, -28, 0, 8)
sendBtn.BackgroundTransparency = 1
sendBtn.Image = "rbxassetid://10734943902"
sendBtn.ImageColor3 = Color3.fromRGB(90, 220, 120)
sendBtn.Parent = inputRow

local Commands = {
    {
        Name = "info",
        Description = "Sends the target player's info as a card.",
    },
    {
        Name = "noclip",
        Description = "Go through objects.",
    },
    {
        Name = "clip",
        Description = "Disables noclip.",
    },
    {
        Name = "fly",
        Description = "Makes you fly. Optional speed arg.",
    },
    {
        Name = "unfly",
        Description = "Disables fly.",
    },
    {
        Name = "speed [num]",
        Description = "Change your walkspeed (default 16).",
    },
    {
        Name = "jump",
        Description = "Makes your character jump.",
    },
    {
        Name = "infjump",
        Description = "Allows you to jump before hitting the ground.",
    },
    {
        Name = "uninfjump",
        Description = "Disables infinite jump.",
    },
    {
        Name = "god",
        Description = "Makes your character difficult to kill.",
    },
    {
        Name = "invisible",
        Description = "Makes you invisible to other players.",
    },
    {
        Name = "visible",
        Description = "Makes you visible to other players.",
    },
    {
        Name = "reset",
        Description = "Resets your character normally.",
    },
    {
        Name = "respawn",
        Description = "Respawns you.",
    },
    {
        Name = "refresh",
        Description = "Respawns and brings you back to the same position.",
    },
    {
        Name = "sit",
        Description = "Makes your character sit.",
    },
    {
        Name = "spin [speed]",
        Description = "Spins your character.",
    },
    {
        Name = "unspin",
        Description = "Disables spin.",
    },
    {
        Name = "gravity [num]",
        Description = "Change gravity (client).",
    },
    {
        Name = "jpower [num]",
        Description = "Change jump power (default 50).",
    },
    {
        Name = "drophats",
        Description = "Drops your hats.",
    },
    {
        Name = "nohats",
        Description = "Deletes your hats.",
    },
    {
        Name = "noarms",
        Description = "Removes your arms.",
    },
    {
        Name = "nolegs",
        Description = "Removes your legs.",
    },
    {
        Name = "nolimbs",
        Description = "Removes all limbs.",
    },
    {
        Name = "noface",
        Description = "Removes your face.",
    },
    {
        Name = "blockhead",
        Description = "Turns your head into a block.",
    },
    {
        Name = "creeper",
        Description = "Makes you look like a creeper.",
    },
    {
        Name = "day",
        Description = "Changes the time to day (client).",
    },
    {
        Name = "night",
        Description = "Changes the time to night (client).",
    },
    {
        Name = "fullbright",
        Description = "Makes the map brighter (client).",
    },
    {
        Name = "nofog",
        Description = "Removes fog (client).",
    },
    {
        Name = "xray",
        Description = "Makes all parts transparent.",
    },
    {
        Name = "unxray",
        Description = "Restores transparency to all parts.",
    },
    {
        Name = "esp",
        Description = "View all players and their status.",
    },
    {
        Name = "noesp",
        Description = "Removes ESP.",
    },
    {
        Name = "dance",
        Description = "Makes you dance.",
    },
    {
        Name = "undance",
        Description = "Stops dance animations.",
    },
    {
        Name = "spasm",
        Description = "Makes you spasm (R6 only).",
    },
    {
        Name = "unspasm",
        Description = "Stops spasm.",
    },
    {
        Name = "noanim",
        Description = "Disables your animations.",
    },
    {
        Name = "reanim",
        Description = "Restores your animations.",
    },
    {
        Name = "freeze",
        Description = "Freezes your character.",
    },
    {
        Name = "thaw",
        Description = "Unfreezes your character.",
    },
    {
        Name = "naked",
        Description = "Removes your clothing (client).",
    },
    {
        Name = "stun",
        Description = "Enables PlatformStand.",
    },
    {
        Name = "unstun",
        Description = "Disables PlatformStand.",
    },
    {
        Name = "norotate",
        Description = "Disables AutoRotate.",
    },
    {
        Name = "autorotate",
        Description = "Enables AutoRotate.",
    },
    {
        Name = "breakvelocity",
        Description = "Sets your velocity to 0.",
    },
    {
        Name = "fov [num]",
        Description = "Change your camera field of view.",
    },
    {
        Name = "resetfov",
        Description = "Resets FOV to default (70).",
    },
    {
        Name = "sensitivity [num]",
        Description = "Change your mouse sensitivity.",
    },
    {
        Name = "resetsensitivity",
        Description = "Resets mouse sensitivity to default.",
    },
    {
        Name = "thirdperson",
        Description = "Locks your camera to third person.",
    },
    {
        Name = "firstperson",
        Description = "Locks your camera to first person.",
    },
    {
        Name = "resetzoom",
        Description = "Restores normal camera zoom range.",
    },
    {
        Name = "facecam",
        Description = "Makes your character always face the camera.",
    },
    {
        Name = "unfacecam",
        Description = "Disables facecam.",
    },
    {
        Name = "resetcamera",
        Description = "Resets FOV, zoom and sensitivity at once.",
    },
    {
        Name = "rainbow",
        Description = "Cycles your character's colors.",
    },
    {
        Name = "unrainbow",
        Description = "Stops the rainbow effect.",
    },
    {
        Name = "glow",
        Description = "Adds a glowing light to your character.",
    },
    {
        Name = "unglow",
        Description = "Removes the glow effect.",
    },
    {
        Name = "trail",
        Description = "Attaches a trail behind your character.",
    },
    {
        Name = "untrail",
        Description = "Removes the trail.",
    },
    {
        Name = "sparkles",
        Description = "Adds sparkles to your character.",
    },
    {
        Name = "unsparkles",
        Description = "Removes sparkles.",
    },
    {
        Name = "fire",
        Description = "Sets your character on fire (visual).",
    },
    {
        Name = "unfire",
        Description = "Removes the fire effect.",
    },
    {
        Name = "smoke",
        Description = "Adds smoke to your character.",
    },
    {
        Name = "unsmoke",
        Description = "Removes smoke.",
    },
    {
        Name = "giant",
        Description = "Scales your character up (R15 only).",
    },
    {
        Name = "tiny",
        Description = "Scales your character down (R15 only).",
    },
    {
        Name = "normalsize",
        Description = "Restores your normal character scale.",
    },
    {
        Name = "lowgravity",
        Description = "Sets gravity to a low value.",
    },
    {
        Name = "highgravity",
        Description = "Sets gravity to a high value.",
    },
    {
        Name = "resetgravity",
        Description = "Resets gravity to default (196.2).",
    },
    {
        Name = "blur",
        Description = "Adds a screen blur effect (client).",
    },
    {
        Name = "unblur",
        Description = "Removes the blur effect.",
    },
    {
        Name = "grayscale",
        Description = "Removes color from your screen (client).",
    },
    {
        Name = "resetcolor",
        Description = "Restores normal screen colors.",
    },
    {
        Name = "nightvision",
        Description = "Applies a green night vision tint (client).",
    },
    {
        Name = "resetlighting",
        Description = "Resets all lighting effects to default.",
    },
    {
        Name = "music [id]",
        Description = "Plays a sound id on loop for only you.",
    },
    {
        Name = "stopmusic",
        Description = "Stops the currently playing music.",
    },
    {
        Name = "copyname",
        Description = "Copies your username to the clipboard.",
    },
    {
        Name = "rejoin",
        Description = "Rejoins the current server.",
    },
    {
        Name = "ping",
        Description = "Shows your current network ping.",
    },
    {
        Name = "fps",
        Description = "Toggles an on-screen FPS counter.",
    },
    {
        Name = "goto [player]",
        Description = "Teleport to a player.",
    },
    {
        Name = "walkto [player]",
        Description = "Walk towards a player.",
    },
    {
        Name = "unwalkto",
        Description = "Stop following a player.",
    },
    {
        Name = "loopgoto [player]",
        Description = "Loop teleport to a player.",
    },
    {
        Name = "unloopgoto",
        Description = "Stop loop teleport.",
    },
    {
        Name = "cbring [player]",
        Description = "Bring a player to you (client).",
    },
    {
        Name = "loopbring [player]",
        Description = "Loop bring a player to you.",
    },
    {
        Name = "unloopbring [player]",
        Description = "Stop loop bring.",
    },
    {
        Name = "offset [x] [y] [z]",
        Description = "Offset your position by coordinates.",
    },
    {
        Name = "tppos [x] [y] [z]",
        Description = "Teleport to exact coordinates.",
    },
    {
        Name = "thru [num]",
        Description = "Teleport forward by studs.",
    },
    {
        Name = "orbit [player]",
        Description = "Orbit around a player.",
    },
    {
        Name = "unorbit",
        Description = "Stop orbiting.",
    },
    {
        Name = "carpet [player]",
        Description = "Lay under a player.",
    },
    {
        Name = "uncarpet",
        Description = "Stop carpet.",
    },
    {
        Name = "headsit [player]",
        Description = "Sit on a player's head.",
    },
    {
        Name = "scare [player]",
        Description = "Teleport in front of a player briefly.",
    },
    {
        Name = "bang [player]",
        Description = "Play bang animation on a player.",
    },
    {
        Name = "unbang",
        Description = "Stop bang.",
    },
    {
        Name = "stareat [player]",
        Description = "Make your character face a player.",
    },
    {
        Name = "unstareat",
        Description = "Stop staring.",
    },
    {
        Name = "friend [player]",
        Description = "Send a friend request.",
    },
    {
        Name = "unfriend [player]",
        Description = "Unfriend a player.",
    },
    {
        Name = "locate [player]",
        Description = "ESP on a single player.",
    },
    {
        Name = "unlocate [player]",
        Description = "Remove locate ESP.",
    },
    {
        Name = "chams",
        Description = "ESP without text labels.",
    },
    {
        Name = "nochams",
        Description = "Remove chams.",
    },
    {
        Name = "hitbox [player] [size]",
        Description = "Expand a player's hitbox.",
    },
    {
        Name = "headsize [player] [size]",
        Description = "Expand a player's head size.",
    },
    {
        Name = "userid [player]",
        Description = "Show a player's user ID.",
    },
    {
        Name = "copyid [player]",
        Description = "Copy a player's user ID.",
    },
    {
        Name = "age [player]",
        Description = "Show a player's account age.",
    },
    {
        Name = "inspect [player]",
        Description = "Open inspect menu for a player.",
    },
    {
        Name = "chat [text]",
        Description = "Send a chat message.",
    },
    {
        Name = "spam [text]",
        Description = "Spam the chat.",
    },
    {
        Name = "unspam",
        Description = "Stop spam.",
    },
    {
        Name = "whisper [player] [text]",
        Description = "Whisper a player.",
    },
    {
        Name = "anchor",
        Description = "Anchor your HumanoidRootPart.",
    },
    {
        Name = "unanchor",
        Description = "Unanchor your HumanoidRootPart.",
    },
    {
        Name = "antifling",
        Description = "Disable player collisions to avoid fling.",
    },
    {
        Name = "unantifling",
        Description = "Re-enable player collisions.",
    },
    {
        Name = "fling",
        Description = "Spin rapidly to fling others.",
    },
    {
        Name = "unfling",
        Description = "Stop fling.",
    },
    {
        Name = "loopspeed [num]",
        Description = "Constantly enforce a walkspeed.",
    },
    {
        Name = "unloopspeed",
        Description = "Stop looping speed.",
    },
    {
        Name = "loopjp [num]",
        Description = "Constantly enforce a jump power.",
    },
    {
        Name = "unloopjp",
        Description = "Stop looping jump power.",
    },
    {
        Name = "antivoid",
        Description = "Launch you up when near the void.",
    },
    {
        Name = "unantivoid",
        Description = "Disable antivoid.",
    },
    {
        Name = "walltp",
        Description = "Auto-teleport over walls you run into.",
    },
    {
        Name = "unwalltp",
        Description = "Disable walltp.",
    },
    {
        Name = "trip",
        Description = "Make your character fall over.",
    },
    {
        Name = "tpwalk [num]",
        Description = "Teleport in your move direction continuously.",
    },
    {
        Name = "untpwalk",
        Description = "Stop tpwalk.",
    },
    {
        Name = "sitwalk",
        Description = "Walk while sitting.",
    },
    {
        Name = "nosit",
        Description = "Prevent your character from sitting.",
    },
    {
        Name = "unnosit",
        Description = "Allow sitting again.",
    },
    {
        Name = "lay",
        Description = "Make your character lay down.",
    },
    {
        Name = "autojump",
        Description = "Auto jump when hitting objects.",
    },
    {
        Name = "unautojump",
        Description = "Disable autojump.",
    },
    {
        Name = "nilchar",
        Description = "Set your character parent to nil.",
    },
    {
        Name = "unnilchar",
        Description = "Restore your character to workspace.",
    },
    {
        Name = "noroot",
        Description = "Delete your HumanoidRootPart.",
    },
    {
        Name = "split",
        Description = "Split your character in half (R15).",
    },
    {
        Name = "hatspin",
        Description = "Spin your accessories.",
    },
    {
        Name = "unhatspin",
        Description = "Stop hat spin.",
    },
    {
        Name = "blockhats",
        Description = "Turn your hats into blocks.",
    },
    {
        Name = "deletevelocity",
        Description = "Remove all velocity and force instances.",
    },
    {
        Name = "weaken [num]",
        Description = "Reduce your character density.",
    },
    {
        Name = "unweaken",
        Description = "Restore default physical properties.",
    },
    {
        Name = "strengthen [num]",
        Description = "Increase your character density.",
    },
    {
        Name = "spawnpoint",
        Description = "Set a spawn point at your position.",
    },
    {
        Name = "nospawnpoint",
        Description = "Remove your custom spawn point.",
    },
    {
        Name = "flashback",
        Description = "Teleport to where you last died.",
    },
    {
        Name = "animation [id]",
        Description = "Play an animation by asset ID.",
    },
    {
        Name = "animspeed [num]",
        Description = "Change speed of your current animation.",
    },
    {
        Name = "stopanims",
        Description = "Stop all running animations.",
    },
    {
        Name = "loopanim",
        Description = "Loop your current animation.",
    },
    {
        Name = "copyanimid [player]",
        Description = "Copy another player's animation ID.",
    },
    {
        Name = "btools",
        Description = "Give yourself building tools (client).",
    },
    {
        Name = "gotopart [name]",
        Description = "Teleport to a part by name.",
    },
    {
        Name = "bringpart [name]",
        Description = "Bring a part to you (client).",
    },
    {
        Name = "loopxray",
        Description = "Loop xray effect.",
    },
    {
        Name = "unloopxray",
        Description = "Stop loop xray.",
    },
    {
        Name = "removeterrain",
        Description = "Clear all terrain.",
    },
    {
        Name = "destroyheight [num]",
        Description = "Set FallenPartsDestroyHeight.",
    },
    {
        Name = "deleteclass [class]",
        Description = "Delete all parts of a classname (client).",
    },
    {
        Name = "delete [name]",
        Description = "Delete parts with a specific name (client).",
    },
    {
        Name = "antiafk",
        Description = "Prevent idle kick.",
    },
    {
        Name = "autoclick",
        Description = "Automatically click your mouse.",
    },
    {
        Name = "unautoclick",
        Description = "Stop auto click.",
    },
    {
        Name = "reach [num]",
        Description = "Extend your held tool hitbox.",
    },
    {
        Name = "unreach",
        Description = "Remove reach.",
    },
    {
        Name = "notools",
        Description = "Remove all tools from backpack.",
    },
    {
        Name = "droptools",
        Description = "Drop all tools into workspace.",
    },
    {
        Name = "equiptools",
        Description = "Equip all backpack tools at once.",
    },
    {
        Name = "copytools [player]",
        Description = "Copy a player's tools (client).",
    },
    {
        Name = "nolimbs",
        Description = "Remove all limbs.",
    },
    {
        Name = "noface",
        Description = "Remove your face decal.",
    },
    {
        Name = "creeper",
        Description = "Look like a Minecraft creeper.",
    },
    {
        Name = "naked",
        Description = "Remove your clothing (client).",
    },
    {
        Name = "blockhead",
        Description = "Turn your head into a block.",
    },
    {
        Name = "swim",
        Description = "Swim in the air.",
    },
    {
        Name = "unswim",
        Description = "Stop swimming in air.",
    },
    {
        Name = "cfly [speed]",
        Description = "CFrame fly, bypasses some anti-cheats.",
    },
    {
        Name = "uncfly",
        Description = "Disable cframe fly.",
    },
    {
        Name = "cflyspeed [num]",
        Description = "Set cframe fly speed.",
    },
    {
        Name = "float",
        Description = "Spawn a platform under you to float.",
    },
    {
        Name = "unfloat",
        Description = "Remove the float platform.",
    },
    {
        Name = "loopfly",
        Description = "Re-enable fly after respawn automatically.",
    },
    {
        Name = "unloopfly",
        Description = "Stop loop fly.",
    },
    {
        Name = "kill [player]",
        Description = "Kill a player using tool damage.",
    },
    {
        Name = "loopkill [player]",
        Description = "Repeatedly kill a player.",
    },
    {
        Name = "unloopkill",
        Description = "Stop loop kill.",
    },
    {
        Name = "freezeplr [player]",
        Description = "Freeze a player in place (client).",
    },
    {
        Name = "unfreezeplr [player]",
        Description = "Unfreeze a player.",
    },
    {
        Name = "bring [player]",
        Description = "Bring a player instantly to you (client).",
    },
    {
        Name = "tp [player]",
        Description = "Teleport to a player instantly.",
    },
    {
        Name = "jail [player]",
        Description = "Trap a player in a box (client).",
    },
    {
        Name = "unjail [player]",
        Description = "Remove a player's jail box.",
    },
    {
        Name = "loopfreeze [player]",
        Description = "Constantly freeze a player.",
    },
    {
        Name = "unloopfreeze",
        Description = "Stop loop freeze.",
    },
    {
        Name = "fog [num]",
        Description = "Set fog end distance.",
    },
    {
        Name = "unfog",
        Description = "Remove fog effect.",
    },
    {
        Name = "ambient [r] [g] [b]",
        Description = "Set lighting ambient color (0-255).",
    },
    {
        Name = "shadow",
        Description = "Enable global shadows.",
    },
    {
        Name = "unshadow",
        Description = "Disable global shadows.",
    },
    {
        Name = "time [num]",
        Description = "Set the clock time (0-24).",
    },
    {
        Name = "noatmosphere",
        Description = "Remove atmosphere instances.",
    },
    {
        Name = "flashlight",
        Description = "Toggle a point light on your character.",
    },
    {
        Name = "unflashlight",
        Description = "Remove the flashlight.",
    },
    {
        Name = "brightness [num]",
        Description = "Set lighting brightness.",
    },
    {
        Name = "serverinfo",
        Description = "Show server and place info.",
    },
    {
        Name = "players",
        Description = "List all players in the server.",
    },
    {
        Name = "copypos",
        Description = "Copy your current position to clipboard.",
    },
    {
        Name = "notifypos",
        Description = "Notify your current position.",
    },
    {
        Name = "f3x",
        Description = "Load F3X building tools.",
    },
    {
        Name = "firecd [name]",
        Description = "Fire all click detectors (optional name).",
    },
    {
        Name = "firepp [name]",
        Description = "Fire all proximity prompts (optional name).",
    },
    {
        Name = "nocdlimits",
        Description = "Set all click detector max distance to max.",
    },
    {
        Name = "nopplimits",
        Description = "Set all proximity prompt max distance to max.",
    },
    {
        Name = "lockws",
        Description = "Lock all workspace parts.",
    },
    {
        Name = "unlockws",
        Description = "Unlock all workspace parts.",
    },
    {
        Name = "savepos [name]",
        Description = "Save your current position as a waypoint.",
    },
    {
        Name = "loadpos [name]",
        Description = "Teleport to a saved waypoint by name.",
    },
    {
        Name = "deletepos [name]",
        Description = "Delete a saved waypoint.",
    },
    {
        Name = "listpos",
        Description = "List all saved waypoints.",
    },
    {
        Name = "clearpos",
        Description = "Clear all saved waypoints.",
    },
    {
        Name = "dex",
        Description = "Load Dex explorer.",
    },
    {
        Name = "remotespy",
        Description = "Load remote spy (Cobalt).",
    },
    {
        Name = "console",
        Description = "Open the Roblox developer console.",
    },
    {
        Name = "antilag",
        Description = "Lower graphics to boost FPS.",
    },
    {
        Name = "serverhop",
        Description = "Jump to a different server.",
    },
    {
        Name = "placeid",
        Description = "Copy the current place ID.",
    },
    {
        Name = "gameid",
        Description = "Copy the current game ID.",
    },
    {
        Name = "maxzoom [num]",
        Description = "Set max camera zoom distance.",
    },
    {
        Name = "minzoom [num]",
        Description = "Set min camera zoom distance.",
    },
    {
        Name = "lookat [player]",
        Description = "Rotate camera toward a player.",
    },
    {
        Name = "camdistance [num]",
        Description = "Set camera distance from your character.",
    },
    {
        Name = "fling",
        Description = "Spin rapidly to fling nearby players.",
    },
    {
        Name = "unfling",
        Description = "Stop fling.",
    },
    {
        Name = "togglefling",
        Description = "Toggle fling on/off.",
    },
    {
        Name = "flyfling [speed]",
        Description = "Vehicle fly + walkfling combined.",
    },
    {
        Name = "unflyfling",
        Description = "Disable flyfling.",
    },
    {
        Name = "walkfling",
        Description = "Fling without spinning (walk-based).",
    },
    {
        Name = "unwalkfling",
        Description = "Disable walkfling.",
    },
    {
        Name = "invisfling",
        Description = "Invisible fling using character swap.",
    },
    {
        Name = "antifling",
        Description = "Disable all player collisions to avoid being flung.",
    },
    {
        Name = "unantifling",
        Description = "Re-enable player collisions.",
    },
    {
        Name = "toggleantifling",
        Description = "Toggle antifling on/off.",
    },
    {
        Name = "spin [speed]",
        Description = "Spin your character at given speed.",
    },
    {
        Name = "unspin",
        Description = "Stop spinning.",
    },
    {
        Name = "strengthenfling",
        Description = "Max density then fling.",
    },
    {
        Name = "weakenfling",
        Description = "Zero density then fling for bigger sends.",
    },
    {
        Name = "noclipfling",
        Description = "Enable noclip then fling.",
    },
    {
        Name = "loopfling",
        Description = "Constantly re-enable fling after dying.",
    },
    {
        Name = "unloopfling",
        Description = "Stop loop fling.",
    },
    {
        Name = "flingspeed [num]",
        Description = "Set the fling angular velocity speed.",
    },
    {
        Name = "freecam",
        Description = "Enable free camera movement.",
    },
    {
        Name = "unfreecam",
        Description = "Disable free camera.",
    },
    {
        Name = "fcspeed [num]",
        Description = "Set freecam movement speed.",
    },
    {
        Name = "fcpos [x] [y] [z]",
        Description = "Open freecam at specific coordinates.",
    },
    {
        Name = "fcgoto [player]",
        Description = "Open freecam at a player's position.",
    },
    {
        Name = "notifyfcpos",
        Description = "Notify your freecam coordinates.",
    },
    {
        Name = "copyfcpos",
        Description = "Copy freecam coordinates to clipboard.",
    },
    {
        Name = "gotocam",
        Description = "Teleport to your camera's position.",
    },
    {
        Name = "volume [0-10]",
        Description = "Set game volume (0-10).",
    },
    {
        Name = "ping",
        Description = "Notify your current ping.",
    },
    {
        Name = "norender",
        Description = "Disable 3D rendering to save CPU.",
    },
    {
        Name = "render",
        Description = "Re-enable 3D rendering.",
    },
    {
        Name = "mousesensitivity [num]",
        Description = "Set mouse sensitivity (default 1).",
    },
    {
        Name = "hovername",
        Description = "Show player name when hovering over them.",
    },
    {
        Name = "unhovername",
        Description = "Disable hover name.",
    },
    {
        Name = "autoclick",
        Description = "Auto click your mouse.",
    },
    {
        Name = "unautoclick",
        Description = "Stop auto click.",
    },
    {
        Name = "loopoof",
        Description = "Loop everyone's character death sound.",
    },
    {
        Name = "unloopoof",
        Description = "Stop loop oof.",
    },
    {
        Name = "muteboombox [player]",
        Description = "Mute a player's boombox.",
    },
    {
        Name = "unmuteboombox [player]",
        Description = "Unmute a player's boombox.",
    },
    {
        Name = "tweengoto [player]",
        Description = "Tween to a player smoothly.",
    },
    {
        Name = "tweenspeed [num]",
        Description = "Set tween movement speed (default 1).",
    },
    {
        Name = "tweenpos [x] [y] [z]",
        Description = "Tween to coordinates smoothly.",
    },
    {
        Name = "tweenoffset [x][y][z]",
        Description = "Tween offset from current position.",
    },
    {
        Name = "tweengotopart [name]",
        Description = "Tween to a part by name.",
    },
    {
        Name = "tweengotomodel [name]",
        Description = "Tween to a model by name.",
    },
    {
        Name = "tweenwp [name]",
        Description = "Tween to a saved waypoint.",
    },
    {
        Name = "tweengotocam",
        Description = "Tween to your camera position.",
    },
    {
        Name = "pulsetp [player] [s]",
        Description = "TP to player for X seconds then return.",
    },
    {
        Name = "loopbring [player]",
        Description = "Loop bring a player to you.",
    },
    {
        Name = "spamspeed [num]",
        Description = "Set chat spam speed (default 1s).",
    },
    {
        Name = "pmspam [player] [msg]",
        Description = "Spam whisper a player.",
    },
    {
        Name = "unpmspam [player]",
        Description = "Stop whisper spam.",
    },
    {
        Name = "darkchat",
        Description = "Make chat window dark themed.",
    },
    {
        Name = "bubblechat",
        Description = "Enable bubble chat.",
    },
    {
        Name = "unbubblechat",
        Description = "Disable bubble chat.",
    },
    {
        Name = "chatwindow",
        Description = "Enable the chat window.",
    },
    {
        Name = "unchatwindow",
        Description = "Disable the chat window.",
    },
    {
        Name = "listento [player]",
        Description = "Listen to audio around a player.",
    },
    {
        Name = "unlistento",
        Description = "Stop listening to player area.",
    },
    {
        Name = "muteallvcs",
        Description = "Mute voice chat for all players.",
    },
    {
        Name = "unmuteallvcs",
        Description = "Unmute voice chat for all players.",
    },
    {
        Name = "mutevc [player]",
        Description = "Mute a player's voice chat.",
    },
    {
        Name = "unmutevc [player]",
        Description = "Unmute a player's voice chat.",
    },
    {
        Name = "espteam",
        Description = "ESP with team colors (green/red).",
    },
    {
        Name = "esptransparency [n]",
        Description = "Set ESP box transparency.",
    },
    {
        Name = "partesp [name]",
        Description = "Highlight parts by name.",
    },
    {
        Name = "unpartesp [name]",
        Description = "Remove part ESP.",
    },
    {
        Name = "hitboxes",
        Description = "Show all bounding boxes in workspace.",
    },
    {
        Name = "unhitboxes",
        Description = "Hide all bounding boxes.",
    },
    {
        Name = "rolewatch [id] [role]",
        Description = "Notify if a group role joins the server.",
    },
    {
        Name = "unrolewatch",
        Description = "Disable rolewatch.",
    },
    {
        Name = "staffwatch",
        Description = "Notify if a staff member joins.",
    },
    {
        Name = "unstaffwatch",
        Description = "Disable staffwatch.",
    },
    {
        Name = "findfriendgroups",
        Description = "Find players who are friends with each other.",
    },
    {
        Name = "joindate [player]",
        Description = "Show the date a player joined Roblox.",
    },
    {
        Name = "chatjoindate [player]",
        Description = "Chat the join date of a player.",
    },
    {
        Name = "chatage [player]",
        Description = "Chat the account age of a player.",
    },
    {
        Name = "copyname [player]",
        Description = "Copy a player's username to clipboard.",
    },
    {
        Name = "appearanceid [player]",
        Description = "Show a player's appearance ID.",
    },
    {
        Name = "copyappearanceid [p]",
        Description = "Copy a player's appearance ID.",
    },
    {
        Name = "enablestate [state]",
        Description = "Enable a humanoid state type.",
    },
    {
        Name = "disablestate [state]",
        Description = "Disable a humanoid state type.",
    },
    {
        Name = "hipheight [num]",
        Description = "Adjust your hip height.",
    },
    {
        Name = "maxslopeangle [num]",
        Description = "Set max slope angle.",
    },
    {
        Name = "platformstand",
        Description = "Enable PlatformStand state.",
    },
    {
        Name = "unplatformstand",
        Description = "Disable PlatformStand state.",
    },
    {
        Name = "edgejump",
        Description = "Auto jump at edges of platforms.",
    },
    {
        Name = "unedgejump",
        Description = "Disable edgejump.",
    },
    {
        Name = "flyjump",
        Description = "Hold space to fly upward.",
    },
    {
        Name = "unflyjump",
        Description = "Disable flyjump.",
    },
    {
        Name = "tpunanchored [player]",
        Description = "Teleport unanchored parts to a player.",
    },
    {
        Name = "freezeunanchored",
        Description = "Freeze all unanchored parts.",
    },
    {
        Name = "thawunanchored",
        Description = "Thaw all frozen unanchored parts.",
    },
    {
        Name = "clearcharappearance",
        Description = "Remove accessories shirt pants bodycolors.",
    },
    {
        Name = "noclipcam",
        Description = "Allow camera to go through walls.",
    },
    {
        Name = "firstp",
        Description = "Force camera to first person.",
    },
    {
        Name = "thirdp",
        Description = "Allow camera to third person.",
    },
    {
        Name = "enableshiftlock",
        Description = "Enable shift lock option.",
    },
    {
        Name = "fixcam",
        Description = "Reset camera to normal state.",
    },
    {
        Name = "dupetools [num]",
        Description = "Duplicate your tools N times.",
    },
    {
        Name = "usetools [n] [delay]",
        Description = "Activate all backpack tools at once.",
    },
    {
        Name = "droppabletools",
        Description = "Make all tools droppable.",
    },
    {
        Name = "removespecifictool [n]",
        Description = "Auto-remove a specific tool from backpack.",
    },
    {
        Name = "unremovespecifictool [n]",
        Description = "Stop removing a specific tool.",
    },
    {
        Name = "clearremovetools",
        Description = "Stop removing all specific tools.",
    },
    {
        Name = "grippos [x] [y] [z]",
        Description = "Change current tool grip position.",
    },
    {
        Name = "boxreach [num]",
        Description = "Box-shaped reach on held tool.",
    },
    {
        Name = "grabtools",
        Description = "Auto-grab dropped tools.",
    },
    {
        Name = "ungrabtools",
        Description = "Stop auto-grabbing tools.",
    },
    {
        Name = "gotomodel [name]",
        Description = "Teleport to a model by name.",
    },
    {
        Name = "gotopartclass [class]",
        Description = "Teleport to a part by classname.",
    },
    {
        Name = "bringpartclass [class]",
        Description = "Bring all parts of a classname to you.",
    },
    {
        Name = "gotopartdelay [num]",
        Description = "Set delay between gotopart teleports.",
    },
    {
        Name = "invisibleparts",
        Description = "Show invisible parts.",
    },
    {
        Name = "uninvisibleparts",
        Description = "Restore invisible parts.",
    },
    {
        Name = "deleteinvisparts",
        Description = "Delete all invisible parts.",
    },
    {
        Name = "clearnilinstances",
        Description = "Destroy all nil instances.",
    },
    {
        Name = "fakeout",
        Description = "TP to void then back (detaches clingers).",
    },
    {
        Name = "jerk",
        Description = "Makes you jork it.",
    },
    {
        Name = "headthrow",
        Description = "Throw your head (R6).",
    },
    {
        Name = "copyanimation [player]",
        Description = "Copy another player's current animation.",
    },
    {
        Name = "refreshanimations",
        Description = "Refresh your character animations.",
    },
    {
        Name = "allowcustomanim",
        Description = "Allow custom animation packs.",
    },
    {
        Name = "unallowcustomanim",
        Description = "Disallow custom animation packs.",
    },
    {
        Name = "noprompts",
        Description = "Block purchase and premium prompts.",
    },
    {
        Name = "showprompts",
        Description = "Allow purchase prompts again.",
    },
    {
        Name = "removeads",
        Description = "Auto-remove ad billboards.",
    },
    {
        Name = "datalimit [num]",
        Description = "Set outgoing KBPS limit.",
    },
    {
        Name = "replicationlag [num]",
        Description = "Set IncomingReplicationLag.",
    },
    {
        Name = "allowrejoin",
        Description = "Toggle if antiteleport allows rejoin.",
    },
    {
        Name = "antikick",
        Description = "Prevent localscripts from kicking you.",
    },
    {
        Name = "antiteleport",
        Description = "Prevent localscripts from teleporting you.",
    },
    {
        Name = "cancelteleport",
        Description = "Cancel a teleport in progress.",
    },
    {
        Name = "gametp [placeid]",
        Description = "Teleport to a game by place ID.",
    },
    {
        Name = "autorj",
        Description = "Auto rejoin if kicked or disconnected.",
    },
    {
        Name = "clearerror",
        Description = "Clear the kick error screen.",
    },
    {
        Name = "antigameplaypaused",
        Description = "Remove the gameplay paused overlay.",
    },
    {
        Name = "use2022materials",
        Description = "Enable 2022 material textures.",
    },
    {
        Name = "unuse2022materials",
        Description = "Disable 2022 material textures.",
    },
    {
        Name = "breakloops",
        Description = "Stop all running command loops.",
    },
    {
        Name = "addalias [cmd] [a]",
        Description = "Add an alias to a command.",
    },
    {
        Name = "removealias [alias]",
        Description = "Remove a custom alias.",
    },
    {
        Name = "clraliases",
        Description = "Clear all custom aliases.",
    },
    {
        Name = "addplugin [name]",
        Description = "Load a plugin .iy file.",
    },
    {
        Name = "removeplugin [name]",
        Description = "Remove a loaded plugin.",
    },
    {
        Name = "reloadplugin [name]",
        Description = "Reload a plugin.",
    },
    {
        Name = "addallplugins",
        Description = "Load all .iy plugin files.",
    },
    {
        Name = "alignmentkeys",
        Description = "Enable alignment keys (comma/period).",
    },
    {
        Name = "unalignmentkeys",
        Description = "Disable alignment keys.",
    },
    {
        Name = "antiidle",
        Description = "Prevent idle kick.",
    },
    {
        Name = "audiologger",
        Description = "Open audio logger.",
    },
    {
        Name = "autokeypress [k][d]",
        Description = "Auto press a key with delay.",
    },
    {
        Name = "unautokeypress",
        Description = "Stop auto key press.",
    },
    {
        Name = "autorejoin",
        Description = "Auto rejoin on disconnect.",
    },
    {
        Name = "blocktool",
        Description = "Turn held tool into a block.",
    },
    {
        Name = "cframefly [speed]",
        Description = "CFrame fly (works on mobile).",
    },
    {
        Name = "uncframefly",
        Description = "Disable CFrame fly.",
    },
    {
        Name = "cframeflyspeed [n]",
        Description = "Set CFrame fly speed.",
    },
    {
        Name = "chardelete [name]",
        Description = "Delete part by name from character.",
    },
    {
        Name = "chardeleteclass [c]",
        Description = "Delete parts by classname from character.",
    },
    {
        Name = "chatlogs",
        Description = "Open chat logs panel.",
    },
    {
        Name = "chatlogswebhook [url]",
        Description = "Set Discord webhook for chat logs.",
    },
    {
        Name = "cleargamewaypoints",
        Description = "Clear waypoints for this game.",
    },
    {
        Name = "clearhats",
        Description = "Clear hats in workspace.",
    },
    {
        Name = "clearremovespecifictool",
        Description = "Stop removing all specific tools.",
    },
    {
        Name = "clearwaypoints",
        Description = "Clear all saved waypoints.",
    },
    {
        Name = "clickdelete",
        Description = "Set up click-to-delete keybind.",
    },
    {
        Name = "clickteleport",
        Description = "Set up click-to-teleport keybind.",
    },
    {
        Name = "clientbring [player]",
        Description = "Bring a player to you (client).",
    },
    {
        Name = "copyanimationid [p]",
        Description = "Copy animation ID to clipboard.",
    },
    {
        Name = "copycreatorid",
        Description = "Copy the game creator ID.",
    },
    {
        Name = "copygameid",
        Description = "Copy the game ID.",
    },
    {
        Name = "copyplaceid",
        Description = "Copy the place ID.",
    },
    {
        Name = "copyposition [p]",
        Description = "Copy a player's position.",
    },
    {
        Name = "copyuserid [player]",
        Description = "Copy a player's user ID.",
    },
    {
        Name = "creatorid",
        Description = "Notify the game creator ID.",
    },
    {
        Name = "ctrllock",
        Description = "Bind shift lock to LeftControl.",
    },
    {
        Name = "unctrllock",
        Description = "Re-bind shift lock to LeftShift.",
    },
    {
        Name = "deleteselectedtool",
        Description = "Remove currently equipped tool.",
    },
    {
        Name = "deletewaypoint [n]",
        Description = "Delete a waypoint by name.",
    },
    {
        Name = "disable [item]",
        Description = "Disable a CoreGui item.",
    },
    {
        Name = "enable [item]",
        Description = "Enable a CoreGui item.",
    },
    {
        Name = "discord",
        Description = "Copy Discord invite link.",
    },
    {
        Name = "emote [id]",
        Description = "Play an emote by asset ID.",
    },
    {
        Name = "exit",
        Description = "Exit the game.",
    },
    {
        Name = "explorer",
        Description = "Open Dex++ explorer.",
    },
    {
        Name = "fireclickdetectors [n]",
        Description = "Fire all click detectors.",
    },
    {
        Name = "fireproximityprompts [n]",
        Description = "Fire all proximity prompts.",
    },
    {
        Name = "firetouchinterests [n]",
        Description = "Fire all touch interests.",
    },
    {
        Name = "flyspeed [num]",
        Description = "Set fly speed.",
    },
    {
        Name = "freecamgoto [player]",
        Description = "Move freecam to a player.",
    },
    {
        Name = "freecampos [x][y][z]",
        Description = "Open freecam at coordinates.",
    },
    {
        Name = "freecamspeed [num]",
        Description = "Set freecam speed.",
    },
    {
        Name = "freecamwaypoint [n]",
        Description = "Move freecam to a waypoint.",
    },
    {
        Name = "gameteleport [id]",
        Description = "Teleport to a game by place ID.",
    },
    {
        Name = "globalshadows",
        Description = "Enable global shadows.",
    },
    {
        Name = "noglobalshadows",
        Description = "Disable global shadows.",
    },
    {
        Name = "goto [player]",
        Description = "Teleport to a player.",
    },
    {
        Name = "gotocamera",
        Description = "Teleport to your camera position.",
    },
    {
        Name = "guidelete",
        Description = "Enable backspace to delete GUIs.",
    },
    {
        Name = "unguidelete",
        Description = "Disable GUI delete.",
    },
    {
        Name = "guiscale [num]",
        Description = "Change GUI scale (0.4-2).",
    },
    {
        Name = "handlekill [player]",
        Description = "Kill with tool damage (needs tool).",
    },
    {
        Name = "hideguis",
        Description = "Hide all PlayerGui GUIs.",
    },
    {
        Name = "unhideguis",
        Description = "Restore hidden GUIs.",
    },
    {
        Name = "hideiy",
        Description = "Hide the DevX console.",
    },
    {
        Name = "showiy",
        Description = "Show the DevX console.",
    },
    {
        Name = "hidewaypoints",
        Description = "Hide waypoint markers in workspace.",
    },
    {
        Name = "showwaypoints",
        Description = "Show waypoint markers in workspace.",
    },
    {
        Name = "infinitejump",
        Description = "Allow jumping before landing.",
    },
    {
        Name = "uninfinitejump",
        Description = "Disable infinite jump.",
    },
    {
        Name = "instantproximityprompts",
        Description = "Instantly fire proximity prompts on hold.",
    },
    {
        Name = "uninstantproximityprompts",
        Description = "Undo instant proximity prompts.",
    },
    {
        Name = "inviteprompt [player]",
        Description = "Prompt a player that you invited them.",
    },
    {
        Name = "jobid",
        Description = "Copy the server Job ID.",
    },
    {
        Name = "joinlogs",
        Description = "Open join logs panel.",
    },
    {
        Name = "jumppower [num]",
        Description = "Set jump power (default 50).",
    },
    {
        Name = "keepiy",
        Description = "Auto-run DevX after teleport.",
    },
    {
        Name = "unkeepiy",
        Description = "Disable keepiy.",
    },
    {
        Name = "togglekeepiy",
        Description = "Toggle keepiy.",
    },
    {
        Name = "lastcommand",
        Description = "Re-run the last command used.",
    },
    {
        Name = "light [range] [b]",
        Description = "Add point light to your character.",
    },
    {
        Name = "nolight",
        Description = "Remove point light from character.",
    },
    {
        Name = "logs",
        Description = "Open the logs GUI.",
    },
    {
        Name = "loopanimation",
        Description = "Loop your current animation.",
    },
    {
        Name = "loopfullbright",
        Description = "Loop fullbright effect.",
    },
    {
        Name = "unloopfullbright",
        Description = "Stop loop fullbright.",
    },
    {
        Name = "loopjumppower [n]",
        Description = "Constantly enforce jump power.",
    },
    {
        Name = "unloopjumppower",
        Description = "Stop loop jump power.",
    },
    {
        Name = "loopnobgui",
        Description = "Constantly remove billboard GUIs.",
    },
    {
        Name = "unloopnobgui",
        Description = "Stop loop no billboard GUI.",
    },
    {
        Name = "moondex",
        Description = "Open Moon's DEX explorer.",
    },
    {
        Name = "mouseteleport",
        Description = "Teleport to your mouse position.",
    },
    {
        Name = "muteallvoices",
        Description = "Mute voice chat for all players.",
    },
    {
        Name = "unmuteallvoices",
        Description = "Unmute all voice chat.",
    },
    {
        Name = "nobillboardgui",
        Description = "Remove billboard GUIs from character.",
    },
    {
        Name = "noclickdetectorlimits",
        Description = "Set all click detectors to max range.",
    },
    {
        Name = "noproximitypromptlimits",
        Description = "Set all proximity prompts to max range.",
    },
    {
        Name = "notify [text]",
        Description = "Send yourself a notification.",
    },
    {
        Name = "notifyfreecamposition",
        Description = "Notify your freecam coordinates.",
    },
    {
        Name = "notifyjobid",
        Description = "Notify the server Job ID.",
    },
    {
        Name = "notifyping",
        Description = "Notify your current ping.",
    },
    {
        Name = "notifyposition [p]",
        Description = "Notify a player's coordinates.",
    },
    {
        Name = "nowalltp",
        Description = "Disable walltp.",
    },
    {
        Name = "oldconsole",
        Description = "Load old-themed Roblox console.",
    },
    {
        Name = "partname",
        Description = "Click a part to see its full path.",
    },
    {
        Name = "pathfindwalkto [p]",
        Description = "Walk to a player using pathfinding.",
    },
    {
        Name = "pathfindwalktowp [n]",
        Description = "Walk to a waypoint using pathfinding.",
    },
    {
        Name = "phonebook",
        Description = "Open Roblox phonebook to call friends.",
    },
    {
        Name = "promptr15",
        Description = "Prompt game to switch rig to R15.",
    },
    {
        Name = "promptr6",
        Description = "Prompt game to switch rig to R6.",
    },
    {
        Name = "qefly [true/false]",
        Description = "Enable/disable Q and E hotkeys for fly.",
    },
    {
        Name = "rec",
        Description = "Start Roblox recorder.",
    },
    {
        Name = "rejoin",
        Description = "Rejoin the current game.",
    },
    {
        Name = "removecmd [name]",
        Description = "Remove a command until script reload.",
    },
    {
        Name = "replaceroot",
        Description = "Replace your HumanoidRootPart.",
    },
    {
        Name = "restorelighting",
        Description = "Restore lighting to original state.",
    },
    {
        Name = "rolewatchleave",
        Description = "Toggle leaving when rolewatch triggers.",
    },
    {
        Name = "rolewatchstop",
        Description = "Stop rolewatch.",
    },
    {
        Name = "savegame",
        Description = "Save the game instance locally.",
    },
    {
        Name = "screenshot",
        Description = "Take a screenshot.",
    },
    {
        Name = "setcreatorid",
        Description = "Set your UserId to creator's ID.",
    },
    {
        Name = "setwaypoint [name]",
        Description = "Save current position as waypoint.",
    },
    {
        Name = "showguis",
        Description = "Make all invisible GUIs visible.",
    },
    {
        Name = "unshowguis",
        Description = "Undo showguis.",
    },
    {
        Name = "simplespy",
        Description = "Load Simple Spy remote spy.",
    },
    {
        Name = "spectate [player]",
        Description = "Spectate a player's camera.",
    },
    {
        Name = "unspectate",
        Description = "Stop spectating.",
    },
    {
        Name = "viewpart [name]",
        Description = "Set camera subject to a part.",
    },
    {
        Name = "spoofjumppower [n]",
        Description = "Spoof jump power client-side.",
    },
    {
        Name = "spoofspeed [num]",
        Description = "Spoof walk speed client-side.",
    },
    {
        Name = "stopanimations",
        Description = "Stop all playing animations.",
    },
    {
        Name = "team [name]",
        Description = "Change your team (client-side).",
    },
    {
        Name = "teleporttool",
        Description = "Give yourself a teleport tool.",
    },
    {
        Name = "togglefs",
        Description = "Toggle fullscreen.",
    },
    {
        Name = "toggleswim",
        Description = "Toggle swim in air.",
    },
    {
        Name = "togglexray",
        Description = "Toggle xray on/off.",
    },
    {
        Name = "toolinvisible",
        Description = "Go invisible while keeping tool use.",
    },
    {
        Name = "tools",
        Description = "Copy tools from ReplicatedStorage.",
    },
    {
        Name = "tpposition [x][y][z]",
        Description = "Teleport to exact coordinates.",
    },
    {
        Name = "tweengotocamera",
        Description = "Tween to your camera position.",
    },
    {
        Name = "tweengotopartclass [c]",
        Description = "Tween to a part by classname.",
    },
    {
        Name = "tweentpposition [xyz]",
        Description = "Tween to exact coordinates.",
    },
    {
        Name = "tweenwaypoint [n]",
        Description = "Tween to a waypoint.",
    },
    {
        Name = "unvehiclefly",
        Description = "Disable vehicle fly.",
    },
    {
        Name = "vehicleclip",
        Description = "Re-enable vehicle collision.",
    },
    {
        Name = "vehiclefly [speed]",
        Description = "Fly while in a vehicle.",
    },
    {
        Name = "vehicleflyspeed [n]",
        Description = "Set vehicle fly speed.",
    },
    {
        Name = "vehiclegoto [player]",
        Description = "Go to a player while in vehicle.",
    },
    {
        Name = "vehiclenoclip",
        Description = "Disable vehicle collision.",
    },
    {
        Name = "walktoposition [xyz]",
        Description = "Walk to coordinates.",
    },
    {
        Name = "walktowaypoint [n]",
        Description = "Walk to a waypoint.",
    },
    {
        Name = "wallwalk",
        Description = "Walk on walls.",
    },
    {
        Name = "waypoint [name]",
        Description = "Teleport to a waypoint.",
    },
    {
        Name = "waypointpos [n][xyz]",
        Description = "Set waypoint at specific coordinates.",
    },
    {
        Name = "waypoints",
        Description = "Open waypoints panel.",
    },
    {
        Name = "advfling [player]",
        Description = "Advanced fling using advanced method with BodyVelocity.",
    },
    {
        Name = "unadvfling",
        Description = "Stop advanced fling.",
    },
    {
        Name = "jerkontarget [player]",
        Description = "Jerk animation on a target player.",
    },
    {
        Name = "unjerkontarget",
        Description = "Stop jerk on target.",
    },
    {
        Name = "bangontarget [player]",
        Description = "Bang animation on a target player (advanced method).",
    },
    {
        Name = "unbangontarget",
        Description = "Stop bang on target.",
    },
    {
        Name = "reversebang [player]",
        Description = "Reverse bang – you sit, target moves behind.",
    },
    {
        Name = "unreversebang",
        Description = "Stop reverse bang.",
    },
    {
        Name = "suck [player]",
        Description = "Sucking animation on a target.",
    },
    {
        Name = "unsuck",
        Description = "Stop suck.",
    },
    {
        Name = "backpack [player]",
        Description = "Sit behind a target with backpack position.",
    },
    {
        Name = "unbackpack",
        Description = "Stop backpack.",
    },
    {
        Name = "antisite",
        Description = "Anti-sit – prevent your character from sitting.",
    },
    {
        Name = "unantisite",
        Description = "Disable anti-sit.",
    },
    {
        Name = "antijump",
        Description = "Anti-jump – set jump power to 0.",
    },
    {
        Name = "unantijump",
        Description = "Restore jump power.",
    },
    {
        Name = "antivoid2",
        Description = "Set FallenPartsDestroyHeight to NaN (anti void advanced method).",
    },
    {
        Name = "unantivoid2",
        Description = "Restore FallenPartsDestroyHeight.",
    },
    {
        Name = "antiafk2",
        Description = "Use VirtualUser to prevent AFK kick.",
    },
    {
        Name = "unantiafk2",
        Description = "Stop virtual user anti AFK.",
    },
    {
        Name = "antibang",
        Description = "Detect and counter bang attempts.",
    },
    {
        Name = "unantibang",
        Description = "Disable anti bang.",
    },
    {
        Name = "antifling2",
        Description = "Remove collision from all players to prevent fling.",
    },
    {
        Name = "unantifling2",
        Description = "Restore collision for all players.",
    },
    {
        Name = "armcutr6",
        Description = "Play arm cut animation (R6).",
    },
    {
        Name = "boxesr6",
        Description = "Play boxing animation (R6).",
    },
    {
        Name = "faintr6",
        Description = "Play faint/sleep animation (R6).",
    },
    {
        Name = "hugr6",
        Description = "Play hug animation (R6).",
    },
    {
        Name = "bangr6",
        Description = "Play bang animation (R6).",
    },
    {
        Name = "illusionr6",
        Description = "Play illusion/flash animation (R6).",
    },
    {
        Name = "insaner6",
        Description = "Play insane animation (R6).",
    },
    {
        Name = "backpackheadr6",
        Description = "Play backpack head animation (R6).",
    },
    {
        Name = "floatingheadr6",
        Description = "Play floating head animation (R6).",
    },
    {
        Name = "jerkingr6",
        Description = "Play jerking animation (R6).",
    },
    {
        Name = "saluter15",
        Description = "Play salute animation (R15).",
    },
    {
        Name = "doggyr15",
        Description = "Play doggy animation (R15).",
    },
    {
        Name = "sb3awyr15",
        Description = "Play sba3wy animation (R15).",
    },
    {
        Name = "zombier15",
        Description = "Play zombie walk animation (R15).",
    },
    {
        Name = "flingarmsr15",
        Description = "Play fling arms/latm animation (R15).",
    },
    {
        Name = "dolphinr15",
        Description = "Play dolphin animation (R15).",
    },
    {
        Name = "sleepyr15",
        Description = "Play sleepy animation (R15).",
    },
    {
        Name = "hugr15",
        Description = "Play hug animation (R15).",
    },
    {
        Name = "crazyr15",
        Description = "Play crazy/mkhbl animation (R15).",
    },
    {
        Name = "b3b3r15",
        Description = "Play b3b3 animation (R15).",
    },
    {
        Name = "stopanim",
        Description = "Stop all playing animations.",
    },
    {
        Name = "checkpointsave",
        Description = "Save your current position as checkpoint.",
    },
    {
        Name = "checkpointload",
        Description = "Teleport to your saved checkpoint.",
    },
    {
        Name = "predictiontp [player]",
        Description = "Teleport to predicted position of a moving player.",
    },
}

local function AddCommandEntry(cmd)
    local entry = Instance.new("Frame")
    entry.Name = cmd.Name
    entry.BackgroundTransparency = 1
    entry.Size = UDim2.new(1, 0, 0, 0)
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.Parent = commandsList

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.fromRGB(90, 220, 120)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = cmd.Name
    nameLabel.Parent = entry

    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.BackgroundTransparency = 1
    descLabel.Position = UDim2.new(0, 0, 0, 16)
    descLabel.Size = UDim2.new(1, 0, 0, 0)
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 11
    descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Text = cmd.Description
    descLabel.Parent = entry
end

for _, cmd in ipairs(Commands) do
    AddCommandEntry(cmd)
end

local function pushEntry(kind, message)
    lineNum += 1
    local entryIcon, entryColor
    if kind == "Print" then
        entryIcon = "rbxassetid://10723367380"; entryColor = Color3.fromRGB(255, 255, 255)
    elseif kind == "Warn" then
        entryIcon = "rbxassetid://10709753149"; entryColor = Color3.fromRGB(255, 214, 0)
    elseif kind == "Error" then
        entryIcon = "rbxassetid://10709753064"; entryColor = Color3.fromRGB(255, 70, 70)
    end

    local row = Instance.new("Frame")
    row.Name = "Entry"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.LayoutOrder = lineNum
    row.Parent = content

    local lineLabel = Instance.new("TextLabel")
    lineLabel.BackgroundTransparency = 1
    lineLabel.Position = UDim2.new(0, 0, 0, 2)
    lineLabel.Size = UDim2.new(0, 24, 0, 16)
    lineLabel.Font = Enum.Font.Code
    lineLabel.TextSize = 13
    lineLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    lineLabel.TextXAlignment = Enum.TextXAlignment.Left
    lineLabel.Text = tostring(lineNum)
    lineLabel.Parent = row

    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0, 26, 0, 1)
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Image = entryIcon
    icon.ImageColor3 = entryColor
    icon.Parent = row

    local dash = Instance.new("TextLabel")
    dash.BackgroundTransparency = 1
    dash.Position = UDim2.new(0, 46, 0, 2)
    dash.Size = UDim2.new(0, 18, 0, 16)
    dash.Font = Enum.Font.Code
    dash.TextSize = 13
    dash.TextColor3 = entryColor
    dash.TextXAlignment = Enum.TextXAlignment.Left
    dash.Text = "--"
    dash.Parent = row

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Position = UDim2.new(0, 68, 0, 0)
    text.Size = UDim2.new(1, -94, 0, 0)
    text.AutomaticSize = Enum.AutomaticSize.Y
    text.Font = Enum.Font.Code
    text.TextSize = 14
    text.TextColor3 = entryColor
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Text = message
    text.Parent = row

    local copyBtn = Instance.new("ImageButton")
    copyBtn.Size = UDim2.new(0, 16, 0, 16)
    copyBtn.Position = UDim2.new(1, -18, 0, 2)
    copyBtn.BackgroundTransparency = 1
    copyBtn.Image = "rbxassetid://10709812159"
    copyBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Parent = row

    copyBtn.MouseButton1Click:Connect(function()
        if copy(message) then
            copyBtn.ImageColor3 = Color3.fromRGB(90, 220, 120)
            task.delay(0.4, function() copyBtn.ImageColor3 = Color3.fromRGB(255, 255, 255) end)
        end
    end)

    table.insert(entries, row)
    task.defer(function()
        task.defer(function()
            content.CanvasPosition = Vector2.new(0, math.max(0, content.AbsoluteCanvasSize.Y - content.AbsoluteSize.Y))
        end)
    end)
end

local FLYING = false
local flyKeyDown, flyKeyUp
local iyflyspeed = 1
local Noclipping = nil
local Clip = true
local NoclipParts = {}

local function sFLY()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local T = getRoot(char)
    if not T then return end

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end

    local CONTROL = {F=0, B=0, L=0, R=0, Q=0, E=0}
    local lCONTROL = {F=0, B=0, L=0, R=0, Q=0, E=0}
    local SPEED = 0

    FLYING = true
    local BG = Instance.new("BodyGyro")
    local BV = Instance.new("BodyVelocity")
    BG.P = 9e4; BG.Parent = T
    BV.Parent = T
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.CFrame = T.CFrame
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    task.spawn(function()
        repeat task.wait()
            local cam = workspace.CurrentCamera
            if hum then hum.PlatformStand = true end
            if (CONTROL.L+CONTROL.R)~=0 or (CONTROL.F+CONTROL.B)~=0 or (CONTROL.Q+CONTROL.E)~=0 then
                SPEED = 50
            else
                SPEED = 0
            end
            if SPEED ~= 0 then
                BV.Velocity = ((cam.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + ((cam.CFrame*CFrame.new(CONTROL.L+CONTROL.R, (CONTROL.F+CONTROL.B+CONTROL.Q+CONTROL.E)*0.2, 0).p)-cam.CFrame.p))*SPEED*iyflyspeed
                lCONTROL = {F=CONTROL.F, B=CONTROL.B, L=CONTROL.L, R=CONTROL.R}
            else
                BV.Velocity = Vector3.new(0, 0, 0)
            end
            BG.CFrame = cam.CFrame
        until not FLYING
        BG:Destroy(); BV:Destroy()
        if hum then hum.PlatformStand = false end
    end)

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = iyflyspeed*2
        elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = -iyflyspeed*2
        end
    end)
    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
        end
    end)
end

local function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    pcall(function() camera.CameraType = Enum.CameraType.Custom end)
end

local ESPenabled = false
local function ESP(plr)
    task.spawn(function()
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == plr.Name.."_ESP" then v:Destroy() end
        end
        task.wait()
        if plr.Character and plr.Name ~= player.Name then
            local holder = Instance.new("Folder")
            holder.Name = plr.Name.."_ESP"
            holder.Parent = game:GetService("CoreGui")
            repeat task.wait(0.5) until plr.Character and getRoot(plr.Character)
            for _, n in pairs(plr.Character:GetChildren()) do
                if n:IsA("BasePart") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Adornee = n; box.AlwaysOnTop = true; box.ZIndex = 10
                    box.Size = n.Size; box.Transparency = 0.5
                    box.Color = plr.TeamColor
                    box.Parent = holder
                end
            end
            if plr.Character:FindFirstChild("Head") then
                local bg = Instance.new("BillboardGui")
                bg.Adornee = plr.Character.Head; bg.AlwaysOnTop = true
                bg.Size = UDim2.new(0, 100, 0, 150); bg.StudsOffset = Vector3.new(0, 1, 0)
                bg.Parent = holder
                local tl = Instance.new("TextLabel")
                tl.BackgroundTransparency = 1; tl.Size = UDim2.new(1, 0, 1, 0)
                tl.Font = Enum.Font.GothamBold; tl.TextSize = 16
                tl.TextColor3 = Color3.new(1, 1, 1); tl.TextStrokeTransparency = 0
                tl.Text = plr.Name; tl.Parent = bg
                local loop = RunService.RenderStepped:Connect(function()
                    if holder.Parent and plr.Character and getRoot(plr.Character) and getRoot(player.Character) then
                        local dist = math.floor((getRoot(player.Character).Position - getRoot(plr.Character).Position).Magnitude)
                        tl.Text = plr.Name.." | "..dist.."st"
                    end
                end)
                plr.CharacterAdded:Connect(function()
                    loop:Disconnect(); holder:Destroy()
                    if ESPenabled then
                        repeat task.wait(0.5) until getRoot(plr.Character)
                        ESP(plr)
                    end
                end)
            end
        end
    end)
end

local xrayEnabled = false
local function xray()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
            v.LocalTransparencyModifier = xrayEnabled and 0.6 or 0
        end
    end
end

local danceTrack, SpasmAnim, Spasm
local facecamLoop, rainbowLoop, musicSound
local fpsLabel, fpsConn, fpsFrames, fpsClock
local defaultZoomMin, defaultZoomMax = player.CameraMinZoomDistance, player.CameraMaxZoomDistance
local defaultFOV, defaultSensitivity = camera.FieldOfView, UserInputService.MouseDeltaSensitivity

local BODY_SCALE_NAMES = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}

local function setBodyScale(hum, value)
    for _, scaleName in ipairs(BODY_SCALE_NAMES) do
        local scale = hum:FindFirstChild(scaleName)
        if scale then scale.Value = value end
    end
end

local function clearCosmetic(root, name)
    local existing = root:FindFirstChild(name)
    if existing then existing:Destroy() end
end

local CommandActions = {
    info = function()
        local t = currentTarget or player
        notify(t.DisplayName.." (@"..t.Name..")", "ID: "..tostring(t.UserId).." | "..targetCreated.Text)
    end,
    noclip = function()
        pcall(function() Noclipping:Disconnect() end)
        Clip = false; NoclipParts = {}
        Noclipping = RunService.Stepped:Connect(function()
            if player.Character then
                for _, child in pairs(player.Character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false; NoclipParts[child] = true
                    end
                end
            end
        end)
        notify("Noclip","Enabled")
    end,
    clip = function()
        pcall(function() Noclipping:Disconnect() end)
        Clip = true
        for child in pairs(NoclipParts) do
            if typeof(child)=="Instance" and child:IsA("BasePart") and child.Parent then
                child.CanCollide = true
            end
        end
        NoclipParts = {}
        notify("Noclip","Disabled")
    end,
    fly = function(args)
        NOFLY(); task.wait()
        if args and tonumber(args[1]) then iyflyspeed = tonumber(args[1]) end
        sFLY()
        notify("Fly","Enabled – Q=down, E=up")
    end,
    unfly = function()
        NOFLY()
        notify("Fly","Disabled")
    end,
    speed = function(args)
        local spd = (args and tonumber(args[1])) or 16
        local hum = getHumanoid(player.Character)
        if hum then hum.WalkSpeed = spd end
        notify("Speed", tostring(spd))
    end,
    jump = function()
        local hum = getHumanoid(player.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        notify("Jump","Jumped")
    end,
    infjump = function()
        if _G.infJump then _G.infJump:Disconnect() end
        _G.infJump = UserInputService.JumpRequest:Connect(function()
            local hum = getHumanoid(player.Character)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        notify("Infinite Jump","Enabled")
    end,
    uninfjump = function()
        if _G.infJump then _G.infJump:Disconnect() end
        notify("Infinite Jump","Disabled")
    end,
    gravity = function(args)
        local grav = (args and tonumber(args[1])) or 196.2
        workspace.Gravity = grav
        notify("Gravity", tostring(grav))
    end,
    jpower = function(args)
        local jp = (args and tonumber(args[1])) or 50
        local hum = getHumanoid(player.Character)
        if hum then
            if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end
        end
        notify("Jump Power", tostring(jp))
    end,
    spin = function(args)
        local spd = (args and tonumber(args[1])) or 20
        local root = getRoot(player.Character)
        if not root then return end
        for _, v in pairs(root:GetChildren()) do if v.Name=="Spinning" then v:Destroy() end end
        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "Spinning"; bav.Parent = root
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.AngularVelocity = Vector3.new(0, spd, 0)
        notify("Spin","Enabled at speed "..spd)
    end,
    unspin = function()
        local root = getRoot(player.Character)
        if not root then return end
        for _, v in pairs(root:GetChildren()) do if v.Name=="Spinning" then v:Destroy() end end
        notify("Spin","Disabled")
    end,

    god = function()
        local char = player.Character
        if not char then return end
        local hum = getHumanoid(char)
        if not hum then return end
        local camCF = camera.CFrame
        local nHum = hum:Clone()
        nHum.Parent = char
        player.Character = nil
        nHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        nHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        nHum.BreakJointsOnDeath = false
        hum:Destroy()
        player.Character = char
        camera.CameraSubject = nHum
        task.wait()
        camera.CFrame = camCF
        nHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local animate = char:FindFirstChild("Animate")
        if animate then animate.Disabled=true; task.wait(); animate.Disabled=false end
        nHum.Health = nHum.MaxHealth
        notify("God","Enabled")
    end,
    reset = function()
        local hum = getHumanoid(player.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        notify("Reset","Character reset")
    end,
    respawn = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.Health = 0 end
        notify("Respawn","Respawning...")
    end,
    refresh = function()
        local root = getRoot(player.Character)
        local pos = root and root.CFrame
        local camPos = camera.CFrame
        local hum = getHumanoid(player.Character)
        if hum then hum.Health = 0 end
        task.spawn(function()
            local char = player.CharacterAdded:Wait()
            char:WaitForChild("HumanoidRootPart")
            task.wait(0.1)
            if pos then char.HumanoidRootPart.CFrame = pos end
            camera.CFrame = camPos
        end)
        notify("Refresh","Refreshed")
    end,
    sit = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.Sit = true end
        notify("Sit","Sitting")
    end,
    freeze = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = true end
            end
        end
        notify("Freeze","Enabled")
    end,
    thaw = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = false end
            end
        end
        notify("Freeze","Disabled")
    end,
    stun = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.PlatformStand = true end
        notify("Stun","Enabled")
    end,
    unstun = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.PlatformStand = false end
        notify("Stun","Disabled")
    end,
    norotate = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.AutoRotate = false end
        notify("AutoRotate","Disabled")
    end,
    autorotate = function()
        local hum = getHumanoid(player.Character)
        if hum then hum.AutoRotate = true end
        notify("AutoRotate","Enabled")
    end,
    breakvelocity = function()
        breakVelocity()
        notify("Velocity","Zeroed")
    end,

    invisible = function()
        if _G.devxInvisRunning then return end
        _G.devxInvisRunning = true
        local char = player.Character
        if not char then return end
        char.Archivable = true
        local invisChar = char:Clone()
        invisChar.Parent = game:GetService("Lighting")
        for _, v in pairs(invisChar:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Transparency = v.Name=="HumanoidRootPart" and 1 or 0.5
            end
        end
        local void = workspace.FallenPartsDestroyHeight
        local cf = getRoot(char) and getRoot(char).CFrame
        char:MoveTo(Vector3.new(0, void+1000, 0))
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        task.wait(0.2)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        char.Parent = game:GetService("Lighting")
        invisChar.Parent = workspace
        if cf then invisChar:FindFirstChild("HumanoidRootPart") and invisChar.HumanoidRootPart:PivotTo(cf) end
        player.Character = invisChar
        workspace.CurrentCamera.CameraSubject = invisChar:FindFirstChildOfClass("Humanoid")
        invisChar.Animate.Disabled = true
        invisChar.Animate.Disabled = false
        _G.devxInvisChar = invisChar
        _G.devxRealChar = char
        notify("Invisible","Enabled")
    end,
    visible = function()
        if not _G.devxInvisRunning then return end
        local invisChar = _G.devxInvisChar
        local char = _G.devxRealChar
        if not invisChar or not char then _G.devxInvisRunning=false; return end
        local cf = getRoot(invisChar) and getRoot(invisChar).CFrame
        player.Character = char
        char.Parent = workspace
        if cf then pcall(function() char.HumanoidRootPart:PivotTo(cf) end) end
        workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
        invisChar:Destroy()
        char.Animate.Disabled = true
        char.Animate.Disabled = false
        _G.devxInvisRunning = false
        _G.devxInvisChar = nil
        _G.devxRealChar = nil
        notify("Invisible","Disabled")
    end,
    drophats = function()
        local hum = getHumanoid(player.Character)
        if hum then
            for _, v in pairs(hum:GetAccessories()) do v.Parent = workspace end
        end
        notify("Hats","Dropped")
    end,
    nohats = function()
        local hum = getHumanoid(player.Character)
        if hum then
            for _, v in pairs(hum:GetAccessories()) do v:Destroy() end
        end
        notify("Hats","Deleted")
    end,
    noarms = function()
        if not player.Character then return end
        if r15(player) then
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and (v.Name=="RightUpperArm" or v.Name=="LeftUpperArm") then v:Destroy() end
            end
        else
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and (v.Name=="Right Arm" or v.Name=="Left Arm") then v:Destroy() end
            end
        end
        notify("Body","Arms removed")
    end,
    nolegs = function()
        if not player.Character then return end
        if r15(player) then
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and (v.Name=="RightUpperLeg" or v.Name=="LeftUpperLeg") then v:Destroy() end
            end
        else
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and (v.Name=="Right Leg" or v.Name=="Left Leg") then v:Destroy() end
            end
        end
        notify("Body","Legs removed")
    end,
    nolimbs = function()
        CommandActions.noarms(); CommandActions.nolegs()
        notify("Body","Limbs removed")
    end,
    noface = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("Decal") and v.Name == "face" then v:Destroy() end
            end
        end
        notify("Face","Removed")
    end,
    blockhead = function()
        local head = player.Character and player.Character:FindFirstChild("Head")
        local mesh = head and head:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh:Destroy() end
        notify("Blockhead","Enabled")
    end,
    creeper = function()
        CommandActions.blockhead()
        CommandActions.noarms()
        local hum = getHumanoid(player.Character)
        if hum then hum:RemoveAccessories() end
        notify("Creeper","Mode enabled")
    end,
    naked = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("Clothing") or v:IsA("ShirtGraphic") then v:Destroy() end
            end
        end
        notify("Clothing","Removed")
    end,

    day = function()
        Lighting.ClockTime = 14
        notify("Time","Day")
    end,
    night = function()
        Lighting.ClockTime = 0
        notify("Time","Night")
    end,
    fullbright = function()
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        notify("Fullbright","Enabled")
    end,
    nofog = function()
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
        notify("Fog","Removed")
    end,
    xray = function()
        xrayEnabled = true; xray()
        notify("Xray","Enabled")
    end,
    unxray = function()
        xrayEnabled = false; xray()
        notify("Xray","Disabled")
    end,

    esp = function()
        ESPenabled = true
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player then ESP(v) end
        end
        notify("ESP","Enabled")
    end,
    noesp = function()
        ESPenabled = false
        for _, c in pairs(game:GetService("CoreGui"):GetChildren()) do
            if c.Name:sub(-4) == "_ESP" then c:Destroy() end
        end
        notify("ESP","Disabled")
    end,

    dance = function()
        local hum = getHumanoid(player.Character)
        if hum then
            local anim = Instance.new("Animation")
            anim.AnimationId = r15(player) and "rbxassetid://3333432454" or "rbxassetid://27789359"
            danceTrack = hum:LoadAnimation(anim)
            danceTrack.Looped = true; danceTrack:Play()
        end
        notify("Dance","Enabled")
    end,
    undance = function()
        if danceTrack then danceTrack:Stop(); danceTrack:Destroy(); danceTrack = nil end
        notify("Dance","Stopped")
    end,
    spasm = function()
        if r15(player) then notify("Spasm","Requires R6"); return end
        local hum = getHumanoid(player.Character)
        if hum then
            SpasmAnim = Instance.new("Animation")
            SpasmAnim.AnimationId = "rbxassetid://33796059"
            Spasm = hum:LoadAnimation(SpasmAnim)
            Spasm:Play(); Spasm:AdjustSpeed(99)
        end
        notify("Spasm","Enabled")
    end,
    unspasm = function()
        if Spasm then Spasm:Stop() end
        if SpasmAnim then SpasmAnim:Destroy() end
        notify("Spasm","Disabled")
    end,
    noanim = function()
        local animate = player.Character and player.Character:FindFirstChild("Animate")
        if animate then animate.Disabled = true end
        notify("Animations","Disabled")
    end,
    reanim = function()
        local animate = player.Character and player.Character:FindFirstChild("Animate")
        if animate then animate.Disabled = false end
        notify("Animations","Restored")
    end,

    fov = function(args)
        camera.FieldOfView = (args and tonumber(args[1])) or defaultFOV
        notify("FOV", tostring(camera.FieldOfView))
    end,
    resetfov = function()
        camera.FieldOfView = defaultFOV
        notify("FOV","Reset")
    end,
    sensitivity = function(args)
        local val = (args and tonumber(args[1])) or defaultSensitivity
        UserInputService.MouseDeltaSensitivity = val
        notify("Sensitivity", tostring(val))
    end,
    resetsensitivity = function()
        UserInputService.MouseDeltaSensitivity = defaultSensitivity
        notify("Sensitivity","Reset")
    end,
    thirdperson = function()
        player.CameraMinZoomDistance = 10
        notify("Camera","Locked to third person")
    end,
    firstperson = function()
        player.CameraMaxZoomDistance = 0.5
        notify("Camera","Locked to first person")
    end,
    resetzoom = function()
        player.CameraMinZoomDistance = defaultZoomMin
        player.CameraMaxZoomDistance = defaultZoomMax
        notify("Camera","Zoom reset")
    end,
    facecam = function()
        if facecamLoop then facecamLoop:Disconnect() end
        facecamLoop = RunService.RenderStepped:Connect(function()
            local root = getRoot(player.Character)
            if root then
                local _, yaw = camera.CFrame:ToOrientation()
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
            end
        end)
        notify("FaceCam","Enabled")
    end,
    unfacecam = function()
        if facecamLoop then facecamLoop:Disconnect(); facecamLoop = nil end
        notify("FaceCam","Disabled")
    end,
    resetcamera = function()
        camera.FieldOfView = defaultFOV
        UserInputService.MouseDeltaSensitivity = defaultSensitivity
        player.CameraMinZoomDistance = defaultZoomMin
        player.CameraMaxZoomDistance = defaultZoomMax
        notify("Camera","All settings reset")
    end,

    rainbow = function()
        if rainbowLoop then rainbowLoop:Disconnect() end
        rainbowLoop = RunService.Heartbeat:Connect(function()
            if player.Character then
                local col = Color3.fromHSV((tick()*0.5) % 1, 1, 1)
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.Color = col end
                end
            end
        end)
        notify("Rainbow","Enabled")
    end,
    unrainbow = function()
        if rainbowLoop then rainbowLoop:Disconnect(); rainbowLoop = nil end
        notify("Rainbow","Disabled")
    end,
    glow = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXGlow")
            local light = Instance.new("PointLight")
            light.Name = "DevXGlow"; light.Range = 12; light.Brightness = 3
            light.Color = Color3.fromRGB(90, 220, 120)
            light.Parent = root
        end
        notify("Glow","Enabled")
    end,
    unglow = function()
        local root = getRoot(player.Character)
        if root then clearCosmetic(root, "DevXGlow") end
        notify("Glow","Disabled")
    end,
    trail = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXTrail")
            clearCosmetic(root, "DevXTrailTop")
            clearCosmetic(root, "DevXTrailBottom")
            local top = Instance.new("Attachment")
            top.Name = "DevXTrailTop"; top.Position = Vector3.new(0, 1, 0); top.Parent = root
            local bottom = Instance.new("Attachment")
            bottom.Name = "DevXTrailBottom"; bottom.Position = Vector3.new(0, -1, 0); bottom.Parent = root
            local trailFx = Instance.new("Trail")
            trailFx.Name = "DevXTrail"
            trailFx.Attachment0 = top; trailFx.Attachment1 = bottom
            trailFx.Color = ColorSequence.new(Color3.fromRGB(90, 220, 120))
            trailFx.Lifetime = 1
            trailFx.Parent = root
        end
        notify("Trail","Enabled")
    end,
    untrail = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXTrail")
            clearCosmetic(root, "DevXTrailTop")
            clearCosmetic(root, "DevXTrailBottom")
        end
        notify("Trail","Disabled")
    end,
    sparkles = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXSparkles")
            local fx = Instance.new("Sparkles")
            fx.Name = "DevXSparkles"; fx.SparkleColor = Color3.fromRGB(90, 220, 120)
            fx.Parent = root
        end
        notify("Sparkles","Enabled")
    end,
    unsparkles = function()
        local root = getRoot(player.Character)
        if root then clearCosmetic(root, "DevXSparkles") end
        notify("Sparkles","Disabled")
    end,
    fire = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXFire")
            local fx = Instance.new("Fire")
            fx.Name = "DevXFire"; fx.Parent = root
        end
        notify("Fire","Enabled")
    end,
    unfire = function()
        local root = getRoot(player.Character)
        if root then clearCosmetic(root, "DevXFire") end
        notify("Fire","Disabled")
    end,
    smoke = function()
        local root = getRoot(player.Character)
        if root then
            clearCosmetic(root, "DevXSmoke")
            local fx = Instance.new("Smoke")
            fx.Name = "DevXSmoke"; fx.Parent = root
        end
        notify("Smoke","Enabled")
    end,
    unsmoke = function()
        local root = getRoot(player.Character)
        if root then clearCosmetic(root, "DevXSmoke") end
        notify("Smoke","Disabled")
    end,
    giant = function()
        local hum = getHumanoid(player.Character)
        if hum then setBodyScale(hum, 2) end
        notify("Scale","Giant")
    end,
    tiny = function()
        local hum = getHumanoid(player.Character)
        if hum then setBodyScale(hum, 0.5) end
        notify("Scale","Tiny")
    end,
    normalsize = function()
        local hum = getHumanoid(player.Character)
        if hum then setBodyScale(hum, 1) end
        notify("Scale","Normal")
    end,

    lowgravity = function()
        workspace.Gravity = 50
        notify("Gravity","Low")
    end,
    highgravity = function()
        workspace.Gravity = 400
        notify("Gravity","High")
    end,
    resetgravity = function()
        workspace.Gravity = 196.2
        notify("Gravity","Reset")
    end,
    blur = function()
        clearCosmetic(Lighting, "DevXBlur")
        local fx = Instance.new("BlurEffect")
        fx.Name = "DevXBlur"; fx.Size = 24
        fx.Parent = Lighting
        notify("Blur","Enabled")
    end,
    unblur = function()
        clearCosmetic(Lighting, "DevXBlur")
        notify("Blur","Disabled")
    end,
    grayscale = function()
        clearCosmetic(Lighting, "DevXColor")
        local fx = Instance.new("ColorCorrectionEffect")
        fx.Name = "DevXColor"; fx.Saturation = -1
        fx.Parent = Lighting
        notify("Color","Grayscale")
    end,
    resetcolor = function()
        clearCosmetic(Lighting, "DevXColor")
        notify("Color","Reset")
    end,
    nightvision = function()
        clearCosmetic(Lighting, "DevXColor")
        local fx = Instance.new("ColorCorrectionEffect")
        fx.Name = "DevXColor"; fx.TintColor = Color3.fromRGB(120, 255, 120)
        fx.Brightness = 0.3; fx.Contrast = 0.2
        fx.Parent = Lighting
        notify("Vision","Night vision enabled")
    end,
    resetlighting = function()
        Lighting.Brightness = 1; Lighting.ClockTime = 14
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        clearCosmetic(Lighting, "DevXBlur")
        clearCosmetic(Lighting, "DevXColor")
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
        notify("Lighting","Reset")
    end,

    music = function(args)
        local id = args and args[1]
        if not id then notify("Music","Provide a sound id"); return end
        if musicSound then musicSound:Destroy() end
        musicSound = Instance.new("Sound")
        musicSound.SoundId = "rbxassetid://"..id:gsub("rbxassetid://","")
        musicSound.Looped = true; musicSound.Volume = 1
        musicSound.Parent = SoundService
        musicSound:Play()
        notify("Music","Playing")
    end,
    stopmusic = function()
        if musicSound then musicSound:Stop(); musicSound:Destroy(); musicSound = nil end
        notify("Music","Stopped")
    end,
    copyname = function(args)
        local name = args and args[1]
        if not name and currentTarget then name = currentTarget.Name end
        local p = name and Players:FindFirstChild(name) or player
        if p then copy(p.Name); notify("CopyName","Copied: "..p.Name) end
    end,
    ping = function()
        notify("Ping", math.round(player:GetNetworkPing()*1000).."ms")
    end,
    fps = function()
        if fpsLabel then
            fpsLabel:Destroy(); fpsLabel = nil
            if fpsConn then fpsConn:Disconnect(); fpsConn = nil end
            notify("FPS Counter","Disabled")
            return
        end
        fpsLabel = Instance.new("TextLabel")
        fpsLabel.Name = "DevXFPS"
        fpsLabel.Size = UDim2.new(0, 80, 0, 20)
        fpsLabel.Position = UDim2.new(0, 8, 0, 8)
        fpsLabel.BackgroundTransparency = 0.4
        fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        fpsLabel.TextColor3 = Color3.fromRGB(90, 220, 120)
        fpsLabel.Font = Enum.Font.Code
        fpsLabel.TextSize = 14
        fpsLabel.Text = "-- fps"
        fpsLabel.Parent = screenGui
        fpsFrames = 0; fpsClock = tick()
        fpsConn = RunService.RenderStepped:Connect(function()
            fpsFrames += 1
            local elapsed = tick() - fpsClock
            if elapsed >= 1 then
                fpsLabel.Text = tostring(math.floor(fpsFrames/elapsed)).." fps"
                fpsFrames = 0; fpsClock = tick()
            end
        end)
        notify("FPS Counter","Enabled")
    end,

    ["goto"] = function(args)
        local name = args and args[1]
        if not name then notify("Goto","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local root = getRoot(player.Character)
                local troot = getRoot(p.Character)
                if root and troot then root.CFrame = troot.CFrame + Vector3.new(3, 0, 0) end
                break
            end
        end
    end,

    walkto = function(args)
        local name = args and args[1]
        if not name then notify("Walkto","Provide a player name"); return end
        _G.devxWalkto = true
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                task.spawn(function()
                    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                    while _G.devxWalkto and p.Character and getRoot(p.Character) do
                        if hum then hum:MoveTo(getRoot(p.Character).Position) end
                        task.wait(0.1)
                    end
                end)
                break
            end
        end
    end,

    unwalkto = function()
        _G.devxWalkto = false
        notify("Walkto","Stopped")
    end,

    loopgoto = function(args)
        local name = args and args[1]
        if not name then notify("Loopgoto","Provide a player name"); return end
        _G.devxLoopgoto = true
        task.spawn(function()
            while _G.devxLoopgoto do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local root = getRoot(player.Character)
                        local troot = p.Character and getRoot(p.Character)
                        if root and troot then root.CFrame = troot.CFrame + Vector3.new(3, 0, 0) end
                    end
                end
                task.wait(0.1)
            end
        end)
        notify("Loopgoto","Started")
    end,

    unloopgoto = function()
        _G.devxLoopgoto = false
        notify("Loopgoto","Stopped")
    end,

    cbring = function(args)
        local name = args and args[1]
        if not name then notify("Cbring","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local troot = p.Character and getRoot(p.Character)
                local root = getRoot(player.Character)
                if troot and root then troot.CFrame = root.CFrame + Vector3.new(3, 0, 0) end
                break
            end
        end
    end,

    loopbring = function(args)
        local name = args and args[1]
        if not name then notify("Loopbring","Provide a player name"); return end
        _G.devxLoopbring = true
        task.spawn(function()
            while _G.devxLoopbring do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local troot = p.Character and getRoot(p.Character)
                        local root = getRoot(player.Character)
                        if troot and root then troot.CFrame = root.CFrame + Vector3.new(3, 0, 0) end
                    end
                end
                task.wait(0.1)
            end
        end)
        notify("Loopbring","Started")
    end,

    unloopbring = function()
        _G.devxLoopbring = false
        notify("Loopbring","Stopped")
    end,

    offset = function(args)
        local x, y, z = tonumber(args and args[1]) or 0, tonumber(args and args[2]) or 0, tonumber(args and args[3]) or 0
        local root = getRoot(player.Character)
        if root then root.CFrame = root.CFrame + Vector3.new(x, y, z) end
    end,

    tppos = function(args)
        local x, y, z = tonumber(args and args[1]), tonumber(args and args[2]), tonumber(args and args[3])
        if not (x and y and z) then notify("Tppos","Provide X Y Z"); return end
        local root = getRoot(player.Character)
        if root then root.CFrame = CFrame.new(x, y, z) end
    end,

    thru = function(args)
        local num = tonumber(args and args[1]) or 5
        local root = getRoot(player.Character)
        if root then root.CFrame = root.CFrame + root.CFrame.LookVector * num end
    end,

    orbit = function(args)
        local name = args and args[1]
        if not name then notify("Orbit","Provide a player name"); return end
        _G.devxOrbit = true
        local rot = 0
        task.spawn(function()
            while _G.devxOrbit do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local troot = p.Character and getRoot(p.Character)
                        local root = getRoot(player.Character)
                        if troot and root then
                            rot += 2
                            local cf = CFrame.new(troot.Position) * CFrame.Angles(0, math.rad(rot), 0) * CFrame.new(6, 0, 0)
                            root.CFrame = CFrame.lookAt(cf.Position, troot.Position)
                        end
                    end
                end
                task.wait()
            end
        end)
        notify("Orbit","Started")
    end,

    unorbit = function()
        _G.devxOrbit = false
        notify("Orbit","Stopped")
    end,

    carpet = function(args)
        local name = args and args[1]
        if not name then notify("Carpet","Provide a player name"); return end
        _G.devxCarpet = true
        task.spawn(function()
            while _G.devxCarpet do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local troot = p.Character and getRoot(p.Character)
                        local root = getRoot(player.Character)
                        if troot and root then root.CFrame = troot.CFrame end
                    end
                end
                task.wait()
            end
        end)
    end,

    uncarpet = function()
        _G.devxCarpet = false
        notify("Carpet","Stopped")
    end,

    headsit = function(args)
        local name = args and args[1]
        if not name then notify("Headsit","Provide a player name"); return end
        _G.devxHeadsit = true
        task.spawn(function()
            while _G.devxHeadsit do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local head = p.Character and p.Character:FindFirstChild("Head")
                        local root = getRoot(player.Character)
                        if head and root then root.CFrame = CFrame.new(head.Position + Vector3.new(0, 2, 0)) end
                    end
                end
                task.wait()
            end
        end)
    end,

    scare = function(args)
        local name = args and args[1]
        if not name then notify("Scare","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local troot = p.Character and getRoot(p.Character)
                local root = getRoot(player.Character)
                local old = root and root.CFrame
                if troot and root then
                    root.CFrame = troot.CFrame + troot.CFrame.LookVector * 2
                    task.wait(0.5)
                    if old then root.CFrame = old end
                end
                break
            end
        end
    end,

    bang = function(args)
        local name = args and args[1]
        if not name then notify("Bang","Provide a player name"); return end
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = r15(player) and "rbxassetid://5918726674" or "rbxassetid://148840371"
        _G.devxBangTrack = hum:LoadAnimation(anim)
        _G.devxBangTrack:Play(); _G.devxBangTrack:AdjustSpeed(3)
        _G.devxBang = true
        task.spawn(function()
            while _G.devxBang do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local troot = p.Character and getRoot(p.Character)
                        local root = getRoot(player.Character)
                        if troot and root then root.CFrame = troot.CFrame + Vector3.new(0, 0, 1.1) end
                    end
                end
                task.wait()
            end
        end)
    end,

    unbang = function()
        _G.devxBang = false
        if _G.devxBangTrack then _G.devxBangTrack:Stop() end
        notify("Bang","Stopped")
    end,

    stareat = function(args)
        local name = args and args[1]
        if not name then notify("Stareat","Provide a player name"); return end
        _G.devxStare = true
        task.spawn(function()
            while _G.devxStare do
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() then
                        local troot = p.Character and getRoot(p.Character)
                        local root = getRoot(player.Character)
                        if troot and root and player.Character.PrimaryPart then
                            local pos = root.Position
                            local tpos = troot.Position
                            player.Character:SetPrimaryPartCFrame(CFrame.new(pos, Vector3.new(tpos.X, pos.Y, tpos.Z)))
                        end
                    end
                end
                task.wait()
            end
        end)
    end,

    unstareat = function()
        _G.devxStare = false
        notify("Stareat","Stopped")
    end,

    friend = function(args)
        local name = args and args[1]
        if not name then notify("Friend","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                player:RequestFriendship(p)
                notify("Friend","Request sent to "..p.Name)
                break
            end
        end
    end,

    unfriend = function(args)
        local name = args and args[1]
        if not name then notify("Unfriend","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                player:RevokeFriendship(p)
                notify("Unfriend","Unfriended "..p.Name)
                break
            end
        end
    end,

    locate = function(args)
        local name = args and args[1]
        if not name then notify("Locate","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                for _, c in pairs(game:GetService("CoreGui"):GetChildren()) do
                    if c.Name == p.Name.."_LC" then c:Destroy() end
                end
                local folder = Instance.new("Folder"); folder.Name = p.Name.."_LC"; folder.Parent = game:GetService("CoreGui")
                if p.Character then
                    for _, part in pairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            local box = Instance.new("BoxHandleAdornment"); box.Adornee = part
                            box.AlwaysOnTop = true; box.Size = part.Size; box.Transparency = 0.5
                            box.Color = BrickColor.new("Bright blue"); box.Parent = folder
                        end
                    end
                end
                notify("Locate","Locating "..p.Name)
                break
            end
        end
    end,

    unlocate = function(args)
        local name = args and args[1]
        if not name then
            for _, c in pairs(game:GetService("CoreGui"):GetChildren()) do
                if c.Name:sub(-3) == "_LC" then c:Destroy() end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #name) == name:lower() then
                    local f = game:GetService("CoreGui"):FindFirstChild(p.Name.."_LC")
                    if f then f:Destroy() end
                end
            end
        end
        notify("Locate","Removed")
    end,

    chams = function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local box = Instance.new("BoxHandleAdornment"); box.Name = "DevXChams"
                        box.Adornee = part; box.AlwaysOnTop = true; box.Size = part.Size
                        box.Transparency = 0.5; box.Color = p.TeamColor; box.Parent = part
                    end
                end
            end
        end
        notify("Chams","Enabled")
    end,

    nochams = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "DevXChams" then v:Destroy() end
        end
        notify("Chams","Disabled")
    end,

    hitbox = function(args)
        local name = args and args[1]
        local size = tonumber(args and args[2]) or 10
        if not name then notify("Hitbox","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local root = p.Character and getRoot(p.Character)
                if root then root.Size = Vector3.new(size, size, size); root.Transparency = 0.5 end
                break
            end
        end
    end,

    headsize = function(args)
        local name = args and args[1]
        local size = tonumber(args and args[2]) or 5
        if not name then notify("Headsize","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head then head.Size = Vector3.new(size, size, size) end
                break
            end
        end
    end,

    userid = function(args)
        local name = args and args[1]
        if not name then notify("UserId","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                notify("UserId", p.Name..": "..tostring(p.UserId))
                break
            end
        end
    end,

    copyid = function(args)
        local name = args and args[1]
        if not name then notify("CopyId","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                copy(tostring(p.UserId))
                notify("CopyId","Copied "..p.Name.."'s ID")
                break
            end
        end
    end,

    age = function(args)
        local name = args and args[1]
        if not name then notify("Age","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                notify("Age", p.Name..": "..tostring(p.AccountAge).." days")
                break
            end
        end
    end,

    inspect = function(args)
        local name = args and args[1]
        if not name then notify("Inspect","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                pcall(function() game:GetService("GuiService"):InspectPlayerFromUserId(p.UserId) end)
                break
            end
        end
    end,

    chat = function(args)
        if not args or #args == 0 then notify("Chat","Provide text"); return end
        local msg = table.concat(args," ")
        local tcs = game:GetService("TextChatService")
        pcall(function()
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                tcs.TextChannels.RBXGeneral:SendAsync(msg)
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg,"All")
            end
        end)
    end,

    spam = function(args)
        if not args or #args == 0 then notify("Spam","Provide text"); return end
        _G.devxSpam = true
        local msg = table.concat(args," ")
        local tcs = game:GetService("TextChatService")
        task.spawn(function()
            while _G.devxSpam do
                pcall(function()
                    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                        tcs.TextChannels.RBXGeneral:SendAsync(msg)
                    else
                        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg,"All")
                    end
                end)
                task.wait(1)
            end
        end)
    end,

    unspam = function()
        _G.devxSpam = false
        notify("Spam","Stopped")
    end,

    whisper = function(args)
        local name = args and args[1]
        if not name then notify("Whisper","Provide a player name"); return end
        local msg = table.concat(args," ", 2)
        local tcs = game:GetService("TextChatService")
        pcall(function()
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                tcs.TextChannels.RBXGeneral:SendAsync("/w "..name.." "..msg)
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/w "..name.." "..msg,"All")
            end
        end)
    end,

    anchor = function()
        local root = getRoot(player.Character)
        if root then root.Anchored = true end
        notify("Anchor","Enabled")
    end,

    unanchor = function()
        local root = getRoot(player.Character)
        if root then root.Anchored = false end
        notify("Anchor","Disabled")
    end,

    antifling = function()
        _G.devxAntifling = RunService.Stepped:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    for _, v in pairs(p.Character:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
            end
        end)
        notify("Antifling","Enabled")
    end,

    unantifling = function()
        if _G.devxAntifling then _G.devxAntifling:Disconnect(); _G.devxAntifling = nil end
        notify("Antifling","Disabled")
    end,

    fling = function()
        _G.devxFling = true
        local root = getRoot(player.Character)
        if not root then return end
        for _, v in pairs(root:GetChildren()) do if v.Name=="DevXFlingBAV" then v:Destroy() end end
        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "DevXFlingBAV"
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.AngularVelocity = Vector3.new(0, 99999, 0)
        bav.Parent = root
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) end
            end
        end
        task.spawn(function()
            while _G.devxFling do
                bav.AngularVelocity = Vector3.new(0, 99999, 0); task.wait(0.2)
                bav.AngularVelocity = Vector3.new(0, 0, 0); task.wait(0.1)
            end
            bav:Destroy()
        end)
        notify("Fling","Enabled")
    end,
    unfling = function()
        _G.devxFling = false
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                    v.Massless = false
                end
                if v.Name == "DevXFlingBAV" then v:Destroy() end
            end
        end
        notify("Fling","Disabled")
    end,

    loopspeed = function(args)
        local spd = tonumber(args and args[1]) or 16
        _G.devxLoopspeedConn = _G.devxLoopspeedConn and _G.devxLoopspeedConn:Disconnect()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = spd
            _G.devxLoopspeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                hum.WalkSpeed = spd
            end)
        end
        notify("Loopspeed", tostring(spd))
    end,

    unloopspeed = function()
        if _G.devxLoopspeedConn then _G.devxLoopspeedConn:Disconnect(); _G.devxLoopspeedConn = nil end
        notify("Loopspeed","Stopped")
    end,

    loopjp = function(args)
        local jp = tonumber(args and args[1]) or 50
        _G.devxLoopjpConn = _G.devxLoopjpConn and _G.devxLoopjpConn:Disconnect()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end
            _G.devxLoopjpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end
            end)
        end
        notify("LoopJP", tostring(jp))
    end,

    unloopjp = function()
        if _G.devxLoopjpConn then _G.devxLoopjpConn:Disconnect(); _G.devxLoopjpConn = nil end
        notify("LoopJP","Stopped")
    end,

    antivoid = function()
        if _G.devxAntivoid then _G.devxAntivoid:Disconnect() end
        _G.devxAntivoid = RunService.Stepped:Connect(function()
            local root = getRoot(player.Character)
            if root and root.Position.Y <= workspace.FallenPartsDestroyHeight + 25 then
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + Vector3.new(0, 250, 0)
            end
        end)
        notify("Antivoid","Enabled")
    end,

    unantivoid = function()
        if _G.devxAntivoid then _G.devxAntivoid:Disconnect(); _G.devxAntivoid = nil end
        notify("Antivoid","Disabled")
    end,

    walltp = function()
        local char = player.Character
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        if not torso then return end
        _G.devxWalltp = torso.Touched:Connect(function(hit)
            local root = getRoot(char)
            if hit and hit:IsA("BasePart") and not hit.Parent:FindFirstChildWhichIsA("Humanoid") and root then
                root.CFrame = root.CFrame + root.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
            end
        end)
        notify("Walltp","Enabled")
    end,

    unwalltp = function()
        if _G.devxWalltp then _G.devxWalltp:Disconnect(); _G.devxWalltp = nil end
        notify("Walltp","Disabled")
    end,

    trip = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local root = getRoot(player.Character)
        if hum and root then
            hum:ChangeState(Enum.HumanoidStateType.FallingDown)
            root.AssemblyLinearVelocity = root.CFrame.LookVector * 30
        end
    end,

    tpwalk = function(args)
        local spd = tonumber(args and args[1]) or 1
        if _G.devxTpwalk then _G.devxTpwalk:Disconnect() end
        _G.devxTpwalk = RunService.Heartbeat:Connect(function(dt)
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                char:TranslateBy(hum.MoveDirection * spd * dt * 10)
            end
        end)
        notify("Tpwalk","Enabled at speed "..spd)
    end,

    untpwalk = function()
        if _G.devxTpwalk then _G.devxTpwalk:Disconnect(); _G.devxTpwalk = nil end
        notify("Tpwalk","Disabled")
    end,

    sitwalk = function()
        local char = player.Character
        local anims = char and char:FindFirstChild("Animate")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if anims and hum then
            local sitId = anims.sit:FindFirstChildWhichIsA("Animation").AnimationId
            anims.idle:FindFirstChildWhichIsA("Animation").AnimationId = sitId
            anims.walk:FindFirstChildWhichIsA("Animation").AnimationId = sitId
            anims.run:FindFirstChildWhichIsA("Animation").AnimationId = sitId
            hum.HipHeight = r15(player) and 0.5 or -1.5
        end
        notify("Sitwalk","Enabled")
    end,

    nosit = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
        notify("Nosit","Enabled")
    end,

    unnosit = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        notify("Nosit","Disabled")
    end,

    lay = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Sit = true; task.wait(0.1)
            hum.RootPart.CFrame = hum.RootPart.CFrame * CFrame.Angles(math.pi*0.5, 0, 0)
        end
    end,

    autojump = function()
        if _G.devxAutojump then _G.devxAutojump:Disconnect() end
        _G.devxAutojump = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.RootPart then
                local ahead = workspace:FindPartOnRay(Ray.new(hum.RootPart.Position - Vector3.new(0, 1.5, 0), hum.RootPart.CFrame.LookVector*3), char)
                if ahead then hum.Jump = true end
            end
        end)
        notify("Autojump","Enabled")
    end,

    unautojump = function()
        if _G.devxAutojump then _G.devxAutojump:Disconnect(); _G.devxAutojump = nil end
        notify("Autojump","Disabled")
    end,

    nilchar = function()
        if player.Character then player.Character.Parent = nil end
        notify("Nilchar","Character set to nil")
    end,

    unnilchar = function()
        if player.Character then player.Character.Parent = workspace end
        notify("Nilchar","Character restored")
    end,

    noroot = function()
        local char = player.Character
        if char then
            char.Parent = nil
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp:Destroy() end
            char.Parent = workspace
        end
    end,

    split = function()
        if not r15(player) then notify("Split","Requires R15"); return end
        local waist = player.Character and player.Character:FindFirstChild("UpperTorso") and player.Character.UpperTorso:FindFirstChild("Waist")
        if waist then waist:Destroy() end
    end,

    hatspin = function()
        if _G.devxHatspin then _G.devxHatspin:Disconnect() end
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, acc in pairs(hum:GetAccessories()) do
            local weld = acc.Handle:FindFirstChildWhichIsA("Weld")
            if weld then weld:Destroy() end
            local bav = Instance.new("BodyAngularVelocity"); bav.Parent = acc.Handle
            bav.AngularVelocity = Vector3.new(0, 100, 0); bav.MaxTorque = Vector3.new(0, 200, 0)
            local bp = Instance.new("BodyPosition"); bp.Parent = acc.Handle; bp.P = 30000; bp.D = 50
            _G.devxHatspin = RunService.Stepped:Connect(function()
                bp.Position = player.Character.Head.Position
            end)
        end
        notify("Hatspin","Enabled")
    end,

    unhatspin = function()
        if _G.devxHatspin then _G.devxHatspin:Disconnect(); _G.devxHatspin = nil end
        notify("Hatspin","Disabled")
    end,

    blockhats = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, acc in pairs(hum:GetAccessories()) do
                for _, v in pairs(acc:GetDescendants()) do
                    if v:IsA("SpecialMesh") then v:Destroy() end
                end
            end
        end
    end,

    deletevelocity = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce") then
                    v:Destroy()
                end
            end
        end
        notify("DeleteVelocity","Done")
    end,

    weaken = function(args)
        local n = tonumber(args and args[1]) or 0
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(n, 0.3, 0.5) end
            end
        end
        notify("Weaken","Done")
    end,

    unweaken = function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) end
            end
        end
        notify("Weaken","Reset")
    end,

    strengthen = function(args)
        local n = tonumber(args and args[1]) or 100
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(n, 0.3, 0.5) end
            end
        end
        notify("Strengthen","Done")
    end,

    spawnpoint = function()
        local root = getRoot(player.Character)
        if root then
            _G.devxSpawnPos = root.CFrame
            _G.devxSpawnConn = _G.devxSpawnConn or player.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart")
                task.wait(0.2)
                if _G.devxSpawnPos then char.HumanoidRootPart.CFrame = _G.devxSpawnPos end
            end)
            notify("Spawnpoint","Set at current position")
        end
    end,

    nospawnpoint = function()
        _G.devxSpawnPos = nil
        if _G.devxSpawnConn then _G.devxSpawnConn:Disconnect(); _G.devxSpawnConn = nil end
        notify("Spawnpoint","Removed")
    end,

    flashback = function()
        if _G.devxLastDeath then
            local root = getRoot(player.Character)
            if root then root.CFrame = _G.devxLastDeath end
        else
            notify("Flashback","No death recorded yet")
        end
    end,

    animation = function(args)
        local id = args and args[1]
        if not id then notify("Animation","Provide an asset ID"); return end
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://"..id:gsub("rbxassetid://","")
            local track = hum:LoadAnimation(anim)
            track:Play()
        end
    end,

    animspeed = function(args)
        local spd = tonumber(args and args[1]) or 1
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(spd) end
        end
    end,

    stopanims = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
        end
    end,

    loopanim = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do t.Looped = true end
        end
    end,

    copyanimid = function(args)
        local name = args and args[1]
        local target = name and Players:FindFirstChild(name) or player
        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local tracks = hum:GetPlayingAnimationTracks()
            if tracks[1] then
                copy(tracks[1].Animation.AnimationId)
                notify("CopyAnimId","Copied")
            end
        end
    end,

    btools = function()
        for i=1, 4 do
            local h = Instance.new("HopperBin"); h.BinType = i; h.Parent = player:FindFirstChildWhichIsA("Backpack")
        end
        notify("Btools","Added")
    end,

    gotopart = function(args)
        local name = args and args[1]
        if not name then notify("Gotopart","Provide a part name"); return end
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name:lower() == name:lower() and v:IsA("BasePart") then
                local root = getRoot(player.Character)
                if root then root.CFrame = v.CFrame + Vector3.new(0, 3, 0) end
                break
            end
        end
    end,

    bringpart = function(args)
        local name = args and args[1]
        if not name then notify("Bringpart","Provide a part name"); return end
        local root = getRoot(player.Character)
        if not root then return end
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name:lower() == name:lower() and v:IsA("BasePart") then
                v.CFrame = root.CFrame
            end
        end
    end,

    loopxray = function()
        if _G.devxLoopXray then _G.devxLoopXray:Disconnect() end
        _G.devxLoopXray = RunService.RenderStepped:Connect(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                    v.LocalTransparencyModifier = 0.6
                end
            end
        end)
        notify("Loopxray","Enabled")
    end,

    unloopxray = function()
        if _G.devxLoopXray then _G.devxLoopXray:Disconnect(); _G.devxLoopXray = nil end
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
        end
        notify("Loopxray","Disabled")
    end,

    removeterrain = function()
        workspace:FindFirstChildOfClass("Terrain"):Clear()
        notify("Terrain","Removed")
    end,

    destroyheight = function(args)
        local h = tonumber(args and args[1]) or -500
        workspace.FallenPartsDestroyHeight = h
        notify("DestroyHeight", tostring(h))
    end,

    deleteclass = function(args)
        local cls = args and args[1]
        if not cls then notify("Deleteclass","Provide a classname"); return end
        for _, v in pairs(workspace:GetDescendants()) do
            if v.ClassName:lower() == cls:lower() then v:Destroy() end
        end
        notify("Deleteclass","Deleted all "..cls)
    end,

    delete = function(args)
        local name = args and args[1]
        if not name then notify("Delete","Provide a name"); return end
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name:lower() == name:lower() then v:Destroy() end
        end
        notify("Delete","Deleted all "..name)
    end,

    antiafk = function()
        if _G.devxAntiAfk then _G.devxAntiAfk:Disconnect() end
        _G.devxAntiAfk = player.Idled:Connect(function()
            local vim = Instance.new("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            vim:Destroy()
        end)
        notify("AntiAFK","Enabled")
    end,

    autoclick = function()
        if not (mouse1press and mouse1release) then notify("Autoclick","Not supported by your executor"); return end
        _G.devxAutoclick = true
        task.spawn(function()
            while _G.devxAutoclick do
                mouse1press(); task.wait(0.05); mouse1release(); task.wait(0.05)
            end
        end)
        notify("Autoclick","Enabled – run 'unautoclick' to stop")
    end,

    unautoclick = function()
        _G.devxAutoclick = false
        notify("Autoclick","Disabled")
    end,

    reach = function(args)
        local size = tonumber(args and args[1]) or 60
        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if handle then
            _G.devxOldHandleSize = _G.devxOldHandleSize or handle.Size
            handle.Size = Vector3.new(0.5, 0.5, size)
            handle.Massless = true
            notify("Reach","Size "..size)
        else
            notify("Reach","Equip a tool first")
        end
    end,

    unreach = function()
        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if handle and _G.devxOldHandleSize then
            handle.Size = _G.devxOldHandleSize; _G.devxOldHandleSize = nil
        end
        notify("Reach","Removed")
    end,

    notools = function()
        local bp = player:FindFirstChildWhichIsA("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v:Destroy() end end end
        if player.Character then for _, v in pairs(player.Character:GetChildren()) do if v:IsA("Tool") then v:Destroy() end end end
        notify("Notools","Done")
    end,

    droptools = function()
        local bp = player:FindFirstChildWhichIsA("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v.Parent = player.Character end end end
        task.wait()
        if player.Character then for _, v in pairs(player.Character:GetChildren()) do if v:IsA("Tool") then v.Parent = workspace end end end
        notify("Droptools","Done")
    end,

    equiptools = function()
        local bp = player:FindFirstChildWhichIsA("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v.Parent = player.Character end end end
        notify("Equiptools","Done")
    end,

    copytools = function(args)
        local name = args and args[1]
        if not name then notify("Copytools","Provide a player name"); return end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #name) == name:lower() then
                local bp = p:FindFirstChildWhichIsA("Backpack")
                if bp then
                    for _, v in pairs(bp:GetChildren()) do
                        if v:IsA("Tool") then v:Clone().Parent = player:FindFirstChildWhichIsA("Backpack") end
                    end
                end
                notify("Copytools","Copied from "..p.Name)
                break
            end
        end
    end,
}

local _waypoints = {}
local _flashlightPart = nil
local _jailBoxes = {}
local _loopkillConn = nil
local _loopfreezeConns = {}
local _cflyConn = nil
local _cflySpeed = 50
local _swimConn = nil
local _floatPart = nil
local _loopflyConn = nil

CommandActions.swim = function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local oldGrav = workspace.Gravity
    workspace.Gravity = 0
    local enums = Enum.HumanoidStateType:GetEnumItems()
    for _, v in pairs(enums) do pcall(function() hum:SetStateEnabled(v, false) end) end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    _swimConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local root = getRoot(char)
            if root then root.AssemblyLinearVelocity = root.AssemblyLinearVelocity end
        end)
    end)
    _G.devxOldGrav = oldGrav
    notify("Swim","Enabled")
end

CommandActions.unswim = function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local enums = Enum.HumanoidStateType:GetEnumItems()
        for _, v in pairs(enums) do pcall(function() hum:SetStateEnabled(v, true) end) end
    end
    if _swimConn then _swimConn:Disconnect(); _swimConn = nil end
    workspace.Gravity = _G.devxOldGrav or 196.2
    notify("Swim","Disabled")
end

CommandActions.cfly = function(args)
    local spd = tonumber(args and args[1]) or _cflySpeed
    _cflySpeed = spd
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if not head or not hum then return end
    if _cflyConn then _cflyConn:Disconnect() end
    hum.PlatformStand = true
    head.Anchored = true
    _cflyConn = RunService.Heartbeat:Connect(function(dt)
        local moveDir = hum.MoveDirection * (_cflySpeed * dt)
        local cam = workspace.CurrentCamera
        local camCF = cam.CFrame
        local headCF = head.CFrame
        local camOffset = headCF:ToObjectSpace(camCF).Position
        camCF = camCF * CFrame.new(-camOffset.X, -camOffset.Y, -camOffset.Z+1)
        local camPos = camCF.Position
        local headPos = headCF.Position
        local objVel = CFrame.new(camPos, Vector3.new(headPos.X, camPos.Y, headPos.Z)):VectorToObjectSpace(moveDir)
        head.CFrame = CFrame.new(headPos)*(camCF-camPos)*CFrame.new(objVel)
    end)
    notify("CFly","Enabled – speed "..spd)
end

CommandActions.uncfly = function()
    if _cflyConn then _cflyConn:Disconnect(); _cflyConn = nil end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if hum then hum.PlatformStand = false end
    if head then head.Anchored = false end
    notify("CFly","Disabled")
end

CommandActions.cflyspeed = function(args)
    _cflySpeed = tonumber(args and args[1]) or 50
    notify("CFly Speed", tostring(_cflySpeed))
end

CommandActions.float = function()
    local char = player.Character
    local root = getRoot(char)
    if not root then return end
    if _floatPart then _floatPart:Destroy() end
    _floatPart = Instance.new("Part")
    _floatPart.Anchored = true
    _floatPart.CanCollide = true
    _floatPart.Size = Vector3.new(4, 0.2, 4)
    _floatPart.Transparency = 0.5
    _floatPart.Parent = workspace
    _G.devxFloatConn = RunService.Heartbeat:Connect(function()
        if _floatPart and root and root.Parent then
            _floatPart.CFrame = CFrame.new(root.Position - Vector3.new(0, 3, 0))
        end
    end)
    notify("Float","Enabled")
end

CommandActions.unfloat = function()
    if _G.devxFloatConn then _G.devxFloatConn:Disconnect(); _G.devxFloatConn = nil end
    if _floatPart then _floatPart:Destroy(); _floatPart = nil end
    notify("Float","Disabled")
end

CommandActions.loopfly = function()
    if _loopflyConn then _loopflyConn:Disconnect() end
    _loopflyConn = player.CharacterAdded:Connect(function()
        task.wait(1)
        CommandActions.fly()
    end)
    CommandActions.fly()
    notify("LoopFly","Enabled")
end

CommandActions.unloopfly = function()
    if _loopflyConn then _loopflyConn:Disconnect(); _loopflyConn = nil end
    CommandActions.unfly()
    notify("LoopFly","Disabled")
end

CommandActions.kill = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Kill","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() and p~=player then
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
            notify("Kill","Killed "..p.Name)
            break
        end
    end
end

CommandActions.loopkill = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("LoopKill","Select a target"); return end
    _G.devxLoopkill = true
    task.spawn(function()
        while _G.devxLoopkill do
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #name)==name:lower() and p~=player then
                    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end
            end
            task.wait(0.5)
        end
    end)
    notify("LoopKill","Started on "..name)
end

CommandActions.unloopkill = function()
    _G.devxLoopkill = false
    notify("LoopKill","Stopped")
end

CommandActions.freezeplr = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Freeze","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            if p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.Anchored = true end
                end
            end
            notify("Freeze","Frozen "..p.Name)
            break
        end
    end
end

CommandActions.unfreezeplr = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Unfreeze","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            if p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.Anchored = false end
                end
            end
            notify("Unfreeze","Unfrozen "..p.Name)
            break
        end
    end
end

CommandActions.loopfreeze = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("LoopFreeze","Select a target"); return end
    _G.devxLoopfreeze = true
    _G.devxLoopfreezeName = name
    task.spawn(function()
        while _G.devxLoopfreeze do
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #(_G.devxLoopfreezeName or name))==(_G.devxLoopfreezeName or name):lower() and p.Character then
                    for _, v in pairs(p.Character:GetDescendants()) do
                        if v:IsA("BasePart") then v.Anchored = true end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    notify("LoopFreeze","Started on "..name)
end

CommandActions.unloopfreeze = function()
    _G.devxLoopfreeze = false
    notify("LoopFreeze","Stopped")
end

CommandActions.bring = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Bring","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            local root = getRoot(player.Character)
            if troot and root then troot.CFrame = root.CFrame + Vector3.new(3, 0, 0) end
            notify("Bring","Brought "..p.Name)
            break
        end
    end
end

CommandActions.tp = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("TP","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            local root = getRoot(player.Character)
            if troot and root then root.CFrame = troot.CFrame + Vector3.new(3, 0, 0) end
            break
        end
    end
end

CommandActions.jail = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Jail","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            if not troot then break end
            if _jailBoxes[p.Name] then _jailBoxes[p.Name]:Destroy() end
            local model = Instance.new("Model"); model.Name = "DevXJail_"..p.Name; model.Parent = workspace
            _jailBoxes[p.Name] = model
            local walls = {
                {Vector3.new(10, 10, 0.5), Vector3.new(0, 5, 5)},
                {Vector3.new(10, 10, 0.5), Vector3.new(0, 5, -5)},
                {Vector3.new(0.5, 10, 10), Vector3.new(5, 5, 0)},
                {Vector3.new(0.5, 10, 10), Vector3.new(-5, 5, 0)},
                {Vector3.new(10, 0.5, 10), Vector3.new(0, 10, 0)},
                {Vector3.new(10, 0.5, 10), Vector3.new(0, 0, 0)},
            }
            for _, w in pairs(walls) do
                local part = Instance.new("Part")
                part.Size = w[1]; part.Anchored = true; part.CanCollide = true
                part.Transparency = 0.5; part.Material = Enum.Material.SmoothPlastic
                part.BrickColor = BrickColor.new("Bright red")
                part.CFrame = troot.CFrame * CFrame.new(w[2])
                part.Parent = model
            end
            notify("Jail","Jailed "..p.Name)
            break
        end
    end
end

CommandActions.unjail = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then
        for n, m in pairs(_jailBoxes) do m:Destroy(); _jailBoxes[n]=nil end
        notify("Unjail","All jails removed")
        return
    end
    if _jailBoxes[name] then _jailBoxes[name]:Destroy(); _jailBoxes[name]=nil end
    notify("Unjail","Removed jail for "..name)
end

CommandActions.fog = function(args)
    local dist = tonumber(args and args[1]) or 100
    Lighting.FogEnd = dist
    Lighting.FogStart = 0
    notify("Fog","FogEnd = "..dist)
end

CommandActions.unfog = function()
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    notify("Fog","Removed")
end

CommandActions.ambient = function(args)
    local r = (tonumber(args and args[1]) or 128)/255
    local g = (tonumber(args and args[2]) or 128)/255
    local b = (tonumber(args and args[3]) or 128)/255
    Lighting.Ambient = Color3.new(r, g, b)
    Lighting.OutdoorAmbient = Color3.new(r, g, b)
    notify("Ambient","Set")
end

CommandActions.shadow = function()
    Lighting.GlobalShadows = true
    notify("Shadow","Enabled")
end

CommandActions.unshadow = function()
    Lighting.GlobalShadows = false
    notify("Shadow","Disabled")
end

CommandActions.time = function(args)
    local t = tonumber(args and args[1]) or 14
    Lighting.ClockTime = t
    notify("Time", tostring(t))
end

CommandActions.noatmosphere = function()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then v:Destroy() end
    end
    notify("Atmosphere","Removed")
end

CommandActions.flashlight = function()
    if _flashlightPart then _flashlightPart:Destroy(); _flashlightPart = nil; notify("Flashlight","Off"); return end
    local root = getRoot(player.Character)
    if not root then return end
    local pl = Instance.new("PointLight")
    pl.Range = 40; pl.Brightness = 5; pl.Parent = root
    _flashlightPart = pl
    notify("Flashlight","On")
end

CommandActions.unflashlight = function()
    if _flashlightPart then _flashlightPart:Destroy(); _flashlightPart = nil end
    notify("Flashlight","Off")
end

CommandActions.brightness = function(args)
    Lighting.Brightness = tonumber(args and args[1]) or 1
    notify("Brightness", tostring(Lighting.Brightness))
end

CommandActions.serverinfo = function()
    notify("Server Info","Place: "..game.PlaceId.."\nJob: "..game.JobId.."\nPlayers: "..#Players:GetPlayers())
end

CommandActions.players = function()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do table.insert(names, p.Name) end
    notify("Players ("..#names..")", table.concat(names,", "))
end

CommandActions.copypos = function()
    local root = getRoot(player.Character)
    if root then
        local p = root.Position
        local str = math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z)
        copy(str); notify("CopyPos", str)
    end
end

CommandActions.notifypos = function()
    local root = getRoot(player.Character)
    if root then
        local p = root.Position
        notify("Position", math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z))
    end
end

CommandActions.f3x = function()
    notify("F3X","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua"))() end)
end

CommandActions.firecd = function(args)
    if not fireclickdetector then notify("FireCD","Not supported by your executor"); return end
    local name = args and args[1]
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then
            if not name or v.Parent.Name:lower()==name:lower() or v.Name:lower()==name:lower() then
                pcall(fireclickdetector, v)
            end
        end
    end
    notify("FireCD","Done")
end

CommandActions.firepp = function(args)
    if not fireproximityprompt then notify("FirePP","Not supported by your executor"); return end
    local name = args and args[1]
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            if not name or v.Parent.Name:lower()==name:lower() or v.Name:lower()==name:lower() then
                pcall(fireproximityprompt, v)
            end
        end
    end
    notify("FirePP","Done")
end

CommandActions.nocdlimits = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then v.MaxActivationDistance = math.huge end
    end
    notify("NoCDLimits","Done")
end

CommandActions.nopplimits = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.MaxActivationDistance = math.huge end
    end
    notify("NoPPLimits","Done")
end

CommandActions.lockws = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Locked = true end
    end
    notify("LockWS","Done")
end

CommandActions.unlockws = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Locked = false end
    end
    notify("UnlockWS","Done")
end

CommandActions.savepos = function(args)
    local name = args and args[1] or ("wp"..tostring(#_waypoints+1))
    local root = getRoot(player.Character)
    if root then
        local p = root.Position
        _waypoints[name] = {p.X, p.Y, p.Z}
        notify("SavePos","Saved as '"..name.."'")
    end
end

CommandActions.loadpos = function(args)
    local name = args and args[1]
    if not name then notify("LoadPos","Provide a name"); return end
    local wp = _waypoints[name]
    if wp then
        local root = getRoot(player.Character)
        if root then root.CFrame = CFrame.new(wp[1], wp[2], wp[3]) end
    else
        notify("LoadPos","Waypoint '"..name.."' not found")
    end
end

CommandActions.deletepos = function(args)
    local name = args and args[1]
    if not name then notify("DeletePos","Provide a name"); return end
    _waypoints[name] = nil
    notify("DeletePos","Deleted '"..name.."'")
end

CommandActions.listpos = function()
    local names = {}
    for k in pairs(_waypoints) do table.insert(names, k) end
    notify("Waypoints ("..#names..")", #names>0 and table.concat(names,", ") or "None")
end

CommandActions.clearpos = function()
    _waypoints = {}
    notify("ClearPos","All waypoints cleared")
end

CommandActions.dex = function()
    notify("Dex","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
end

CommandActions.remotespy = function()
    notify("RemoteSpy","Loading...")
    pcall(function() loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))() end)
end

CommandActions.console = function()
    game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
end

CommandActions.antilag = function()
    local L = Lighting
    L.GlobalShadows = false; L.FogEnd = 9e9; L.FogStart = 9e9
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.CastShadow = false end
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime = NumberRange.new(0) end
    end
    notify("AntiLag","Graphics lowered")
end

CommandActions.serverhop = function()
    task.spawn(function()
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"))
        end)
        if ok and data and data.data then
            for _, v in pairs(data.data) do
                if v.id ~= game.JobId and v.playing < v.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, player)
                    return
                end
            end
        end
        notify("ServerHop","No server found")
    end)
end

CommandActions.placeid = function()
    copy(tostring(game.PlaceId))
    notify("PlaceID", tostring(game.PlaceId))
end

CommandActions.gameid = function()
    copy(tostring(game.GameId))
    notify("GameID", tostring(game.GameId))
end

CommandActions.maxzoom = function(args)
    player.CameraMaxZoomDistance = tonumber(args and args[1]) or 400
    notify("MaxZoom", tostring(player.CameraMaxZoomDistance))
end

CommandActions.minzoom = function(args)
    player.CameraMinZoomDistance = tonumber(args and args[1]) or 0.5
    notify("MinZoom", tostring(player.CameraMinZoomDistance))
end

CommandActions.lookat = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("LookAt","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            local cam = workspace.CurrentCamera
            if troot and cam then
                cam.CFrame = CFrame.new(cam.CFrame.Position, troot.Position)
            end
            break
        end
    end
end

CommandActions.camdistance = function(args)
    local dist = tonumber(args and args[1]) or 10
    local oldMax = player.CameraMaxZoomDistance
    if oldMax < dist then player.CameraMaxZoomDistance = dist end
    player.CameraMinZoomDistance = dist
    player.CameraMaxZoomDistance = dist
    task.wait(0.1)
    player.CameraMaxZoomDistance = oldMax < dist and dist or oldMax
    player.CameraMinZoomDistance = 0.5
end

local _flingSpeed = 99999
local _walkflinging = false
local _walkflingConn = nil
local _loopflingConn = nil
local _freecamRunning = false
local _freecamConn = nil
local _freecamPos = Vector3.new()
local _freecamRot = Vector2.new()
local _freecamSpeed = 1
local _hoverConn = nil
local _hoverLabel = nil
local _loopOofing = false
local _loopOofConn = nil

CommandActions.togglefling = function()
    if _G.devxFling then CommandActions.unfling() else CommandActions.fling() end
end

CommandActions.flingspeed = function(args)
    _flingSpeed = tonumber(args and args[1]) or 99999
    notify("FlingSpeed", tostring(_flingSpeed))
end

CommandActions.walkfling = function()
    CommandActions.unwalkfling()
    CommandActions.noclip()
    _walkflinging = true
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function() CommandActions.unwalkfling() end)
    end
    _walkflingConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local root = getRoot(char)
        if not root or not root.Parent then return end
        local vel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
        RunService.RenderStepped:Wait()
        if root and root.Parent then root.AssemblyLinearVelocity = vel end
    end)
    notify("Walkfling","Enabled")
end

CommandActions.unwalkfling = function()
    _walkflinging = false
    if _walkflingConn then _walkflingConn:Disconnect(); _walkflingConn = nil end
    CommandActions.clip()
    notify("Walkfling","Disabled")
end

CommandActions.flyfling = function(args)
    CommandActions.unflyfling()
    task.wait()
    _cflySpeed = tonumber(args and args[1]) or _cflySpeed
    CommandActions.cfly(args)
    CommandActions.walkfling()
    notify("FlyFling","Enabled")
end

CommandActions.unflyfling = function()
    CommandActions.uncfly()
    CommandActions.unwalkfling()
    CommandActions.breakvelocity()
    notify("FlyFling","Disabled")
end

CommandActions.invisfling = function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local prt = Instance.new("Model"); prt.Parent = char
    local z1 = Instance.new("Part"); z1.Name="Torso"; z1.CanCollide=false; z1.Anchored=true; z1.Position=Vector3.new(0, 9999, 0)
    local z2 = Instance.new("Part"); z2.Name="Head"; z2.Parent=prt; z2.Anchored=true; z2.CanCollide=false
    local z3 = Instance.new("Humanoid"); z3.Name="Humanoid"; z3.Parent=prt
    player.Character = prt
    task.wait(3)
    player.Character = char
    task.wait(3)
    local root = getRoot(char)
    if root then
        for _, v in pairs(char:GetChildren()) do
            if v ~= root and v.Name~="Humanoid" then v:Destroy() end
        end
        root.Transparency = 0
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.AngularVelocity = Vector3.new(0, 99999, 0)
        bav.Parent = root
    end
    notify("InvisFling","Done")
end

CommandActions.noclipfling = function()
    CommandActions.noclip()
    task.wait(0.1)
    CommandActions.fling()
    notify("NoclipFling","Enabled")
end

CommandActions.strengthenfling = function()
    CommandActions.strengthen()
    task.wait(0.1)
    CommandActions.fling()
    notify("StrengthenFling","Enabled")
end

CommandActions.weakenfling = function()
    CommandActions.weaken()
    task.wait(0.1)
    CommandActions.fling()
    notify("WeakenFling","Enabled")
end

CommandActions.loopfling = function()
    if _loopflingConn then _loopflingConn:Disconnect() end
    CommandActions.fling()
    _loopflingConn = player.CharacterAdded:Connect(function()
        task.wait(1)
        CommandActions.fling()
    end)
    notify("LoopFling","Enabled")
end

CommandActions.unloopfling = function()
    if _loopflingConn then _loopflingConn:Disconnect(); _loopflingConn = nil end
    CommandActions.unfling()
    notify("LoopFling","Disabled")
end

CommandActions.freecam = function()
    if _freecamRunning then return end
    _freecamRunning = true
    local cam = workspace.CurrentCamera
    _freecamPos = cam.CFrame.Position
    _freecamRot = Vector2.new()
    cam.CameraType = Enum.CameraType.Scriptable
    local keys = {W=0, S=0, A=0, D=0, E=0, Q=0}
    local keyDown = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode==Enum.KeyCode.W then keys.W=1
        elseif inp.KeyCode==Enum.KeyCode.S then keys.S=1
        elseif inp.KeyCode==Enum.KeyCode.A then keys.A=1
        elseif inp.KeyCode==Enum.KeyCode.D then keys.D=1
        elseif inp.KeyCode==Enum.KeyCode.E then keys.E=1
        elseif inp.KeyCode==Enum.KeyCode.Q then keys.Q=1
        end
    end)
    local keyUp = UserInputService.InputEnded:Connect(function(inp)
        if inp.KeyCode==Enum.KeyCode.W then keys.W=0
        elseif inp.KeyCode==Enum.KeyCode.S then keys.S=0
        elseif inp.KeyCode==Enum.KeyCode.A then keys.A=0
        elseif inp.KeyCode==Enum.KeyCode.D then keys.D=0
        elseif inp.KeyCode==Enum.KeyCode.E then keys.E=0
        elseif inp.KeyCode==Enum.KeyCode.Q then keys.Q=0
        end
    end)
    local mouseConn = UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement then
            _freecamRot = _freecamRot + Vector2.new(-inp.Delta.Y, - inp.Delta.X)*0.003
            _freecamRot = Vector2.new(math.clamp(_freecamRot.X, -math.rad(89), math.rad(89)), _freecamRot.Y)
        end
    end)
    _freecamConn = RunService.RenderStepped:Connect(function(dt)
        local cf = CFrame.new(_freecamPos)*CFrame.fromOrientation(_freecamRot.X, _freecamRot.Y, 0)
        local vel = cf.RightVector*(keys.D-keys.A) + cf.UpVector*(keys.E-keys.Q) + cf.LookVector*(keys.W-keys.S)
        _freecamPos = _freecamPos + vel*_freecamSpeed*64*dt
        cam.CFrame = CFrame.new(_freecamPos)*CFrame.fromOrientation(_freecamRot.X, _freecamRot.Y, 0)
    end)
    _G.devxFreecamCleanup = function()
        keyDown:Disconnect(); keyUp:Disconnect(); mouseConn:Disconnect()
    end
    notify("Freecam","Enabled – W/A/S/D + Q/E to move")
end

CommandActions.unfreecam = function()
    _freecamRunning = false
    if _freecamConn then _freecamConn:Disconnect(); _freecamConn = nil end
    if _G.devxFreecamCleanup then _G.devxFreecamCleanup() end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    notify("Freecam","Disabled")
end

CommandActions.fcspeed = function(args)
    _freecamSpeed = tonumber(args and args[1]) or 1
    notify("FCSpeed", tostring(_freecamSpeed))
end

CommandActions.fcpos = function(args)
    local x, y, z = tonumber(args and args[1]), tonumber(args and args[2]), tonumber(args and args[3])
    if not (x and y and z) then notify("FCPos","Provide X Y Z"); return end
    _freecamPos = Vector3.new(x, y, z)
    if not _freecamRunning then CommandActions.freecam() end
end

CommandActions.fcgoto = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("FCGoto","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local root = p.Character and getRoot(p.Character)
            if root then
                _freecamPos = root.Position
                if not _freecamRunning then CommandActions.freecam() end
            end
            break
        end
    end
end

CommandActions.notifyfcpos = function()
    if _freecamRunning then
        local p = _freecamPos
        notify("FCPos", math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z))
    else
        notify("FCPos","Freecam not active")
    end
end

CommandActions.copyfcpos = function()
    if _freecamRunning then
        local p = _freecamPos
        local str = math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z)
        copy(str); notify("FCPos","Copied: "..str)
    end
end

CommandActions.gotocam = function()
    local root = getRoot(player.Character)
    if root then root.CFrame = workspace.CurrentCamera.CFrame end
end

CommandActions.volume = function(args)
    local vol = tonumber(args and args[1]) or 5
    UserSettings():GetService("UserGameSettings").MasterVolume = vol/10
    notify("Volume", tostring(vol).."/10")
end

CommandActions.norender = function()
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
    notify("Render","3D rendering disabled")
end

CommandActions.render = function()
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    notify("Render","3D rendering enabled")
end

CommandActions.mousesensitivity = function(args)
    local s = tonumber(args and args[1]) or 1
    UserInputService.MouseDeltaSensitivity = s
    notify("MouseSens", tostring(s))
end

CommandActions.hovername = function()
    if _hoverConn then _hoverConn:Disconnect(); _hoverConn=nil end
    if _hoverLabel then _hoverLabel:Destroy(); _hoverLabel=nil end
    _hoverLabel = Instance.new("TextLabel")
    _hoverLabel.BackgroundTransparency = 0.4
    _hoverLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    _hoverLabel.Size = UDim2.new(0, 150, 0, 24)
    _hoverLabel.Font = Enum.Font.GothamBold
    _hoverLabel.TextSize = 14
    _hoverLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    _hoverLabel.Visible = false
    _hoverLabel.ZIndex = 10
    _hoverLabel.Parent = screenGui
    local mouse = player:GetMouse()
    _hoverConn = mouse.Move:Connect(function()
        local target = mouse.Target
        if not target then _hoverLabel.Visible = false; return end
        local p = Players:GetPlayerFromCharacter(target.Parent) or Players:GetPlayerFromCharacter(target.Parent.Parent)
        if p then
            _hoverLabel.Text = p.Name
            _hoverLabel.Position = UDim2.new(0, mouse.X+16, 0, mouse.Y)
            _hoverLabel.Visible = true
        else
            _hoverLabel.Visible = false
        end
    end)
    notify("HoverName","Enabled")
end

CommandActions.unhovername = function()
    if _hoverConn then _hoverConn:Disconnect(); _hoverConn=nil end
    if _hoverLabel then _hoverLabel:Destroy(); _hoverLabel=nil end
    notify("HoverName","Disabled")
end

CommandActions.loopoof = function()
    _loopOofing = true
    _loopOofConn = RunService.Heartbeat:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                for _, s in pairs(p.Character.Head:GetChildren()) do
                    if s:IsA("Sound") then s.Playing = true end
                end
            end
        end
    end)
    notify("LoopOof","Enabled")
end

CommandActions.unloopoof = function()
    _loopOofing = false
    if _loopOofConn then _loopOofConn:Disconnect(); _loopOofConn=nil end
    notify("LoopOof","Disabled")
end

CommandActions.muteboombox = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("MuteBoombox","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            if p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("Sound") then v.Playing = false end
                end
            end
            notify("MuteBoombox","Muted "..p.Name)
            break
        end
    end
end

CommandActions.unmuteboombox = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("UnmuteBoombox","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            if p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("Sound") then v.Playing = true end
                end
            end
            notify("UnmuteBoombox","Unmuted "..p.Name)
            break
        end
    end
end

local _tweenSpeed = 1
local _loopKillConns = {}
local _pmSpamming = {}
local _spamSpeed = 1
local _esptransparency = 0.5
local _partEspParts = {}
local _edgejumpConn = nil
local _flyjumpConn = nil
local _frozenUA = {}
local _freezeUAConn = nil
local _loopBreak = false
local _grabToolsConn = nil
local _removeSpecificTools = {}

CommandActions.tweengoto = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("TweenGoto","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            local root = getRoot(player.Character)
            if troot and root then
                TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=troot.CFrame+Vector3.new(3, 0, 0)}):Play()
            end
            break
        end
    end
end

CommandActions.tweenspeed = function(args)
    _tweenSpeed = tonumber(args and args[1]) or 1
    notify("TweenSpeed", tostring(_tweenSpeed))
end

CommandActions.tweenpos = function(args)
    local x, y, z = tonumber(args and args[1]), tonumber(args and args[2]), tonumber(args and args[3])
    if not(x and y and z) then notify("TweenPos","Provide X Y Z"); return end
    local root = getRoot(player.Character)
    if root then TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=CFrame.new(x, y, z)}):Play() end
end

CommandActions.tweenoffset = function(args)
    local x, y, z = tonumber(args and args[1]) or 0, tonumber(args and args[2]) or 0, tonumber(args and args[3]) or 0
    local root = getRoot(player.Character)
    if root then TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=CFrame.new(root.Position+Vector3.new(x, y, z))}):Play() end
end

CommandActions.tweengotopart = function(args)
    local name = args and args[1]
    if not name then notify("TweenGotoPart","Provide a part name"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower()==name:lower() and v:IsA("BasePart") then
            TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=v.CFrame+Vector3.new(0, 3, 0)}):Play()
            break
        end
    end
end

CommandActions.tweengotomodel = function(args)
    local name = args and args[1]
    if not name then notify("TweenGotoModel","Provide a model name"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower()==name:lower() and v:IsA("Model") and v.PrimaryPart then
            TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=v:GetPivot()}):Play()
            break
        end
    end
end

CommandActions.tweenwp = function(args)
    local name = args and args[1]
    if not name then notify("TweenWP","Provide a waypoint name"); return end
    local wp = _waypoints[name]
    if not wp then notify("TweenWP","Waypoint not found"); return end
    local root = getRoot(player.Character)
    if root then TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=CFrame.new(wp[1], wp[2], wp[3])}):Play() end
end

CommandActions.tweengotocam = function()
    local root = getRoot(player.Character)
    if root then TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=workspace.CurrentCamera.CFrame}):Play() end
end

CommandActions.pulsetp = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("PulseTP","Select a target"); return end
    local secs = tonumber(args and args[2]) or 1
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local root = getRoot(player.Character)
            local troot = p.Character and getRoot(p.Character)
            if root and troot then
                local old = root.CFrame
                root.CFrame = troot.CFrame+Vector3.new(3, 0, 0)
                task.wait(secs)
                root.CFrame = old
            end
            break
        end
    end
end

CommandActions.spamspeed = function(args)
    _spamSpeed = tonumber(args and args[1]) or 1
    notify("SpamSpeed", tostring(_spamSpeed))
end

CommandActions.pmspam = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("PMSpam","Select a target"); return end
    local msg = table.concat(args," ", 2)
    _pmSpamming[name] = true
    local tcs = game:GetService("TextChatService")
    task.spawn(function()
        while _pmSpamming[name] do
            pcall(function()
                if tcs.ChatVersion==Enum.ChatVersion.TextChatService then
                    tcs.TextChannels.RBXGeneral:SendAsync("/w "..name.." "..msg)
                else
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/w "..name.." "..msg,"All")
                end
            end)
            task.wait(_spamSpeed)
        end
    end)
    notify("PMSpam","Started on "..name)
end

CommandActions.unpmspam = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if name then _pmSpamming[name] = false else for k in pairs(_pmSpamming) do _pmSpamming[k]=false end end
    notify("PMSpam","Stopped")
end

CommandActions.darkchat = function()
    local tcs = game:GetService("TextChatService")
    local bcc = tcs:FindFirstChildOfClass("BubbleChatConfiguration")
    local cwc = tcs:FindFirstChildOfClass("ChatWindowConfiguration")
    if bcc then bcc.Enabled=true; bcc.BackgroundColor3=Color3.new(); bcc.TextColor3=Color3.fromRGB(255, 255, 255) end
    if cwc then cwc.Enabled=true; cwc.BackgroundColor3=Color3.new(); cwc.TextColor3=Color3.fromRGB(255, 255, 255) end
    notify("DarkChat","Enabled")
end

CommandActions.bubblechat = function()
    game:GetService("TextChatService").BubbleChatConfiguration.Enabled = true
    notify("BubbleChat","Enabled")
end

CommandActions.unbubblechat = function()
    game:GetService("TextChatService").BubbleChatConfiguration.Enabled = false
    notify("BubbleChat","Disabled")
end

CommandActions.chatwindow = function()
    game:GetService("TextChatService").ChatWindowConfiguration.Enabled = true
    notify("ChatWindow","Enabled")
end

CommandActions.unchatwindow = function()
    game:GetService("TextChatService").ChatWindowConfiguration.Enabled = false
    notify("ChatWindow","Disabled")
end

CommandActions.listento = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("ListenTo","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local root = p.Character and getRoot(p.Character)
            if root then game:GetService("SoundService"):SetListener(Enum.ListenerType.ObjectPosition, root) end
            notify("ListenTo","Listening near "..p.Name)
            break
        end
    end
end

CommandActions.unlistento = function()
    game:GetService("SoundService"):SetListener(Enum.ListenerType.Camera)
    notify("ListenTo","Stopped")
end

CommandActions.muteallvcs = function()
    pcall(function() game:GetService("VoiceChatInternal"):SubscribePauseAll(true) end)
    notify("MuteAllVCS","Done")
end

CommandActions.unmuteallvcs = function()
    pcall(function() game:GetService("VoiceChatInternal"):SubscribePauseAll(false) end)
    notify("UnmuteAllVCS","Done")
end

CommandActions.mutevc = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("MuteVC","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            pcall(function() game:GetService("VoiceChatInternal"):SubscribePause(p.UserId, true) end)
            notify("MuteVC","Muted "..p.Name)
            break
        end
    end
end

CommandActions.unmutevc = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("UnmuteVC","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            pcall(function() game:GetService("VoiceChatInternal"):SubscribePause(p.UserId, false) end)
            notify("UnmuteVC","Unmuted "..p.Name)
            break
        end
    end
end

CommandActions.espteam = function()
    ESPenabled = true
    for _, p in pairs(Players:GetPlayers()) do
        if p~=player then ESP(p, true) end
    end
    notify("ESPTeam","Enabled")
end

CommandActions.esptransparency = function(args)
    _esptransparency = tonumber(args and args[1]) or 0.5
    notify("ESPTransparency", tostring(_esptransparency))
end

CommandActions.partesp = function(args)
    local name = args and args[1]
    if not name then notify("PartESP","Provide a part name"); return end
    table.insert(_partEspParts, name:lower())
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            local box = Instance.new("BoxHandleAdornment"); box.Name="DevXPartESP"
            box.Adornee=v; box.AlwaysOnTop=true; box.Size=v.Size
            box.Transparency=_esptransparency; box.Color=BrickColor.new("Lime green"); box.Parent=v
        end
    end
    notify("PartESP","Highlighting "..name)
end

CommandActions.unpartesp = function(args)
    local name = args and args[1]
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name=="DevXPartESP" then
            if not name or v.Parent.Name:lower()==name:lower() then v:Destroy() end
        end
    end
    if name then
        for i, n in pairs(_partEspParts) do if n==name:lower() then table.remove(_partEspParts, i) end end
    else
        _partEspParts = {}
    end
    notify("PartESP","Removed")
end

CommandActions.hitboxes = function()
    pcall(function() settings():GetService("RenderSettings").ShowBoundingBoxes = true end)
    notify("Hitboxes","Enabled")
end

CommandActions.unhitboxes = function()
    pcall(function() settings():GetService("RenderSettings").ShowBoundingBoxes = false end)
    notify("Hitboxes","Disabled")
end

CommandActions.rolewatch = function(args)
    local gid = tonumber(args and args[1])
    local role = args and args[2]
    if not(gid and role) then notify("Rolewatch","Provide group ID and role"); return end
    _G.devxRolewatch = Players.PlayerAdded:Connect(function(p)
        if p:IsInGroup(gid) and p:GetRoleInGroup(gid):lower()==role:lower() then
            notify("Rolewatch", p.Name.." joined with role: "..role)
        end
    end)
    notify("Rolewatch","Watching group "..gid.." for role: "..role)
end

CommandActions.unrolewatch = function()
    if _G.devxRolewatch then _G.devxRolewatch:Disconnect(); _G.devxRolewatch=nil end
    notify("Rolewatch","Disabled")
end

CommandActions.staffwatch = function()
    if game.CreatorType~=Enum.CreatorType.Group then notify("Staffwatch","Game not owned by a group"); return end
    local roles = {"mod","admin","staff","dev","founder","owner","manager","director"}
    _G.devxStaffwatch = Players.PlayerAdded:Connect(function(p)
        local r = p:GetRoleInGroup(game.CreatorId)
        for _, kw in pairs(roles) do
            if r:lower():find(kw) then notify("Staffwatch", p.Name.." is a "..r); break end
        end
    end)
    notify("Staffwatch","Enabled")
end

CommandActions.unstaffwatch = function()
    if _G.devxStaffwatch then _G.devxStaffwatch:Disconnect(); _G.devxStaffwatch=nil end
    notify("Staffwatch","Disabled")
end

CommandActions.findfriendgroups = function()
    notify("FriendGroups","Checking... (may take a moment)")
    task.spawn(function()
        local players = Players:GetPlayers()
        local results = {}
        for i=1, #players do
            for j=i+1, #players do
                local ok, friends = pcall(function() return players[i]:IsFriendsWith(players[j].UserId) end)
                if ok and friends then
                    table.insert(results, players[i].Name.." & "..players[j].Name)
                end
            end
        end
        if #results>0 then notify("FriendGroups", table.concat(results,"\n")) else notify("FriendGroups","None found") end
    end)
end

CommandActions.joindate = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("JoinDate","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local secs = p.AccountAge*24*60*60
            local date = os.date("%m/%d/%Y", os.time()-secs)
            notify("JoinDate", p.Name..": "..date)
            break
        end
    end
end

CommandActions.chatjoindate = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("ChatJoinDate","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local secs = p.AccountAge*24*60*60
            local date = os.date("%m/%d/%Y", os.time()-secs)
            CommandActions.chat({"Joined Roblox: "..date})
            break
        end
    end
end

CommandActions.chatage = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("ChatAge","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            CommandActions.chat({p.Name.."'s age: "..p.AccountAge.." days"})
            break
        end
    end
end

CommandActions.appearanceid = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("AppearanceID","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            notify("AppearanceID", p.Name..": "..tostring(p.CharacterAppearanceId))
            break
        end
    end
end

CommandActions.copyappearanceid = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("CopyAppearanceID","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            copy(tostring(p.CharacterAppearanceId))
            notify("CopyAppearanceID","Copied "..p.Name.."'s appearance ID")
            break
        end
    end
end

CommandActions.enablestate = function(args)
    local s = args and args[1]
    if not s then notify("EnableState","Provide a state"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s], true) end) end
    notify("EnableState", tostring(s))
end

CommandActions.disablestate = function(args)
    local s = args and args[1]
    if not s then notify("DisableState","Provide a state"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s], false) end) end
    notify("DisableState", tostring(s))
end

CommandActions.hipheight = function(args)
    local h = tonumber(args and args[1]) or 0
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.HipHeight = h end
    notify("HipHeight", tostring(h))
end

CommandActions.maxslopeangle = function(args)
    local a = tonumber(args and args[1]) or 89
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.MaxSlopeAngle = a end
    notify("MaxSlopeAngle", tostring(a))
end

CommandActions.platformstand = function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    notify("PlatformStand","Enabled")
end

CommandActions.unplatformstand = function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    notify("PlatformStand","Disabled")
end

CommandActions.edgejump = function()
    if _edgejumpConn then _edgejumpConn:Disconnect() end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local lastState, lastCF
    _edgejumpConn = RunService.RenderStepped:Connect(function()
        if not(char and hum) then return end
        local state = hum:GetState()
        if lastState~=state and state==Enum.HumanoidStateType.Freefall and lastState~=Enum.HumanoidStateType.Jumping then
            if lastCF then hum.RootPart.CFrame = lastCF end
            hum.RootPart.AssemblyLinearVelocity = hum.RootPart.AssemblyLinearVelocity + Vector3.new(0, hum.JumpHeight or 50, 0)
        end
        lastState = state
        lastCF = hum.RootPart and hum.RootPart.CFrame
    end)
    notify("EdgeJump","Enabled")
end

CommandActions.unedgejump = function()
    if _edgejumpConn then _edgejumpConn:Disconnect(); _edgejumpConn=nil end
    notify("EdgeJump","Disabled")
end

CommandActions.flyjump = function()
    if _flyjumpConn then _flyjumpConn:Disconnect() end
    _flyjumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    notify("FlyJump","Enabled – hold space to fly up")
end

CommandActions.unflyjump = function()
    if _flyjumpConn then _flyjumpConn:Disconnect(); _flyjumpConn=nil end
    notify("FlyJump","Disabled")
end

CommandActions.tpunanchored = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("TPUnanchored","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local head = p.Character and p.Character:FindFirstChild("Head")
            if head then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                        local bp = Instance.new("BodyPosition"); bp.Position=head.Position
                        bp.MaxForce=Vector3.new(math.huge, math.huge, math.huge); bp.Parent=v
                        table.insert(_frozenUA, v)
                    end
                end
            end
            break
        end
    end
    notify("TPUnanchored","Done")
end

CommandActions.freezeunanchored = function()
    local bad = {"Head","Torso","UpperTorso","LowerTorso","HumanoidRootPart","Right Arm","Left Arm","Right Leg","Left Leg"}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored then
            local skip = false
            for _, b in pairs(bad) do if v.Name==b then skip=true; break end end
            if not skip and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                local bp = Instance.new("BodyPosition"); bp.Position=v.Position
                bp.MaxForce=Vector3.new(math.huge, math.huge, math.huge); bp.Parent=v
                local bg = Instance.new("BodyGyro"); bg.CFrame=v.CFrame
                bg.MaxTorque=Vector3.new(math.huge, math.huge, math.huge); bg.Parent=v
                table.insert(_frozenUA, v)
            end
        end
    end
    notify("FreezeUnanchored","Frozen "..#_frozenUA.." parts")
end

CommandActions.thawunanchored = function()
    for _, v in pairs(_frozenUA) do
        if typeof(v)=="Instance" and v.Parent then
            for _, c in pairs(v:GetChildren()) do
                if c:IsA("BodyPosition") or c:IsA("BodyGyro") then c:Destroy() end
            end
        end
    end
    _frozenUA = {}
    notify("ThawUnanchored","Done")
end

CommandActions.clearcharappearance = function()
    player:ClearCharacterAppearance()
    notify("ClearCharAppearance","Done")
end

CommandActions.noclipcam = function()
    pcall(function()
        local pop = player.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
        local gc = (debug and debug.getconstants) or getconstants
        local sc = (debug and debug.setconstant) or setconstant
        if gc and sc and getgc then
            for _, f in pairs(getgc()) do
                if type(f)=="function" and getfenv and getfenv(f).script==pop then
                    for i, v in pairs(gc(f)) do
                        if v==0.25 then sc(f, i, 0) elseif v==0 then sc(f, i, 0.25) end
                    end
                end
            end
        end
    end)
    notify("NoclipCam","Camera can now pass through walls")
end

CommandActions.firstp = function()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    notify("FirstPerson","Enabled")
end

CommandActions.thirdp = function()
    player.CameraMode = Enum.CameraMode.Classic
    notify("ThirdPerson","Enabled")
end

CommandActions.enableshiftlock = function()
    pcall(function()
        player.DevEnableMouseLock = true
        player:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(function()
            player.DevEnableMouseLock = true
        end)
    end)
    notify("ShiftLock","Enabled")
end

CommandActions.fixcam = function()
    CommandActions.unfreecam()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    player.CameraMinZoomDistance = 0.5
    player.CameraMaxZoomDistance = 400
    player.CameraMode = Enum.CameraMode.Classic
    notify("FixCam","Camera reset")
end

CommandActions.dupetools = function(args)
    local n = tonumber(args and args[1]) or 1
    local bp = player:FindFirstChildWhichIsA("Backpack")
    if not bp then return end
    for _=1, n do
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") then v:Clone().Parent=bp end
        end
    end
    notify("DupeTools","Duplicated "..n.." time(s)")
end

CommandActions.usetools = function(args)
    local n = tonumber(args and args[1]) or 1
    local delay_ = tonumber(args and args[2]) or 0
    local bp = player:FindFirstChildWhichIsA("Backpack")
    if not bp then return end
    for _, v in pairs(bp:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = player.Character
            task.spawn(function()
                for _=1, n do pcall(function() v:Activate() end); if delay_>0 then task.wait(delay_) end end
                v.Parent = bp
            end)
        end
    end
end

CommandActions.droppabletools = function()
    local function setDroppable(container)
        if not container then return end
        for _, v in pairs(container:GetChildren()) do
            if v:IsA("Tool") then v.CanBeDropped = true end
        end
    end
    setDroppable(player:FindFirstChildWhichIsA("Backpack"))
    setDroppable(player.Character)
    notify("DroppableTools","All tools are now droppable")
end

CommandActions.removespecifictool = function(args)
    local name = args and args[1]
    if not name then notify("RemoveSpecificTool","Provide a tool name"); return end
    _removeSpecificTools[name:lower()] = RunService.RenderStepped:Connect(function()
        local bp = player:FindFirstChildWhichIsA("Backpack")
        if bp then
            for _, v in pairs(bp:GetChildren()) do
                if v.Name:lower()==name:lower() then v:Destroy() end
            end
        end
    end)
    notify("RemoveSpecificTool","Removing: "..name)
end

CommandActions.unremovespecifictool = function(args)
    local name = args and args[1]
    if not name then notify("UnRemoveSpecificTool","Provide a tool name"); return end
    if _removeSpecificTools[name:lower()] then
        _removeSpecificTools[name:lower()]:Disconnect()
        _removeSpecificTools[name:lower()] = nil
    end
    notify("UnRemoveSpecificTool","Stopped removing: "..name)
end

CommandActions.clearremovetools = function()
    for k, v in pairs(_removeSpecificTools) do v:Disconnect(); _removeSpecificTools[k]=nil end
    notify("ClearRemoveTools","Done")
end

CommandActions.grippos = function(args)
    local x, y, z = tonumber(args and args[1]) or 0, tonumber(args and args[2]) or 0, tonumber(args and args[3]) or 0
    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool.GripPos = Vector3.new(x, y, z) end
    notify("GripPos", x..", "..y..", "..z)
end

CommandActions.boxreach = function(args)
    local size = tonumber(args and args[1]) or 60
    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    if handle then
        _G.devxOldHandleSize = _G.devxOldHandleSize or handle.Size
        handle.Size = Vector3.new(size, size, size); handle.Massless = true
        notify("BoxReach","Size "..size)
    else notify("BoxReach","Equip a tool first") end
end

CommandActions.grabtools = function()
    if _grabToolsConn then _grabToolsConn:Disconnect() end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then hum:EquipTool(v) end
    end
    _grabToolsConn = workspace.ChildAdded:Connect(function(v)
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if h then h:EquipTool(v) end
        end
    end)
    notify("GrabTools","Enabled")
end

CommandActions.ungrabtools = function()
    if _grabToolsConn then _grabToolsConn:Disconnect(); _grabToolsConn=nil end
    notify("GrabTools","Disabled")
end

CommandActions.gotomodel = function(args)
    local name = args and args[1]
    if not name then notify("GotoModel","Provide a model name"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower()==name:lower() and v:IsA("Model") then
            root.CFrame = v:GetPivot(); break
        end
    end
end

CommandActions.gotopartclass = function(args)
    local cls = args and args[1]
    if not cls then notify("GotoPartClass","Provide a classname"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.ClassName:lower()==cls:lower() and v:IsA("BasePart") then
            root.CFrame = v.CFrame; break
        end
    end
end

CommandActions.bringpartclass = function(args)
    local cls = args and args[1]
    if not cls then notify("BringPartClass","Provide a classname"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.ClassName:lower()==cls:lower() and v:IsA("BasePart") then
            v.CFrame = root.CFrame
        end
    end
    notify("BringPartClass","Done")
end

CommandActions.gotopartdelay = function(args)
    _G.devxGotoPartDelay = tonumber(args and args[1]) or 0.1
    notify("GotoPartDelay", tostring(_G.devxGotoPartDelay))
end

CommandActions.invisibleparts = function()
    _G.devxShownParts = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency==1 then
            v.Transparency = 0
            table.insert(_G.devxShownParts, v)
        end
    end
    notify("InvisibleParts","Showing "..(#_G.devxShownParts).." parts")
end

CommandActions.uninvisibleparts = function()
    for _, v in pairs(_G.devxShownParts or {}) do
        if typeof(v)=="Instance" and v.Parent then v.Transparency=1 end
    end
    _G.devxShownParts = {}
    notify("InvisibleParts","Restored")
end

CommandActions.deleteinvisparts = function()
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency==1 and v.CanCollide then
            v:Destroy(); count+=1
        end
    end
    notify("DeleteInvisParts","Deleted "..count.." parts")
end

CommandActions.clearnilinstances = function()
    if getnilinstances then
        for _, v in pairs(getnilinstances()) do pcall(function() v:Destroy() end) end
        notify("ClearNilInstances","Done")
    else notify("ClearNilInstances","Not supported by your executor") end
end

CommandActions.fakeout = function()
    local root = getRoot(player.Character)
    if not root then return end
    local old = root.CFrame
    local oldH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/1/0
    root.CFrame = CFrame.new(0, oldH-25, 0)
    task.wait(1)
    root.CFrame = old
    workspace.FallenPartsDestroyHeight = oldH
    notify("Fakeout","Done")
end

CommandActions.jerk = function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local bp = player:FindFirstChildWhichIsA("Backpack")
    if not hum or not bp then return end
    local tool = Instance.new("Tool"); tool.Name="Jerk Off"
    tool.RequiresHandle=false; tool.Parent=bp
    local anim = Instance.new("Animation")
    anim.AnimationId = r15(player) and "rbxassetid://698251653" or "rbxassetid://72042024"
    local track = hum:LoadAnimation(anim)
    track.Looped = true; track:Play(); track:AdjustSpeed(0.7)
    notify("Jerk","...")
end

CommandActions.headthrow = function()
    if r15(player) then notify("Headthrow","Requires R6"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local anim = Instance.new("Animation"); anim.AnimationId="rbxassetid://35154961"
        local t = hum:LoadAnimation(anim); t:Play()
    end
end

CommandActions.copyanimation = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("CopyAnimation","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local phum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if phum and hum then
                for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
                for _, t in pairs(phum:GetPlayingAnimationTracks()) do
                    local newTrack = hum:LoadAnimation(t.Animation)
                    newTrack:Play(0.1, 1, t.Speed)
                    newTrack.TimePosition = t.TimePosition
                end
            end
            break
        end
    end
end

CommandActions.refreshanimations = function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local anim = char and char:FindFirstChild("Animate")
    if hum and anim then
        anim.Disabled = true
        for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
        anim.Disabled = false
    end
    notify("RefreshAnimations","Done")
end

CommandActions.allowcustomanim = function()
    game:GetService("StarterPlayer").AllowCustomAnimations = true
    CommandActions.refreshanimations()
    notify("AllowCustomAnim","Enabled")
end

CommandActions.unallowcustomanim = function()
    game:GetService("StarterPlayer").AllowCustomAnimations = false
    CommandActions.refreshanimations()
    notify("AllowCustomAnim","Disabled")
end

CommandActions.noprompts = function()
    pcall(function() game:GetService("CoreGui").PurchasePromptApp.Enabled = false end)
    notify("NoPrompts","Enabled")
end

CommandActions.showprompts = function()
    pcall(function() game:GetService("CoreGui").PurchasePromptApp.Enabled = true end)
    notify("NoPrompts","Disabled")
end

CommandActions.removeads = function()
    task.spawn(function()
        while true do
            task.wait(1)
            for _, v in pairs(workspace:GetDescendants()) do
                pcall(function()
                    if v:IsA("PackageLink") then
                        if v.Parent:FindFirstChild("ADpart") then v.Parent:Destroy()
                        elseif v.Parent:FindFirstChild("AdGuiAdornee") then v.Parent.Parent:Destroy() end
                    end
                end)
            end
        end
    end)
    notify("RemoveAds","Running")
end

CommandActions.datalimit = function(args)
    local n = tonumber(args and args[1]) or 50
    pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(n) end)
    notify("DataLimit", tostring(n).." KBPS")
end

CommandActions.replicationlag = function(args)
    local n = tonumber(args and args[1]) or 0
    pcall(function() settings():GetService("NetworkSettings").IncomingReplicationLag = n end)
    notify("ReplicationLag", tostring(n))
end

CommandActions.allowrejoin = function()
    _G.devxAllowRejoin = not (_G.devxAllowRejoin~=false)
    notify("AllowRejoin", _G.devxAllowRejoin and "On" or "Off")
end

CommandActions.antikick = function()
    if not hookmetamethod then notify("AntiKick","Not supported by your executor"); return end
    local oldNmc; oldNmc = hookmetamethod(game,"__namecall", newcclosure(function(...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if select(1, ...)==player and (method=="Kick" or method=="kick") then return end
        return oldNmc(...)
    end))
    notify("AntiKick","Enabled (client)")
end

CommandActions.antiteleport = function()
    if not hookmetamethod then notify("AntiTeleport","Not supported by your executor"); return end
    local oldNmc; oldNmc = hookmetamethod(game,"__namecall", newcclosure(function(...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local self = select(1, ...)
        if self==TeleportService and (method=="Teleport" or method=="TeleportToPlaceInstance" or method=="TeleportAsync") then
            if checkcaller and checkcaller() then return oldNmc(...) end
            return
        end
        return oldNmc(...)
    end))
    notify("AntiTeleport","Enabled (client)")
end

CommandActions.cancelteleport = function()
    pcall(function() TeleportService:TeleportCancel() end)
    notify("CancelTeleport","Done")
end

CommandActions.gametp = function(args)
    local id = tonumber(args and args[1])
    if not id then notify("GameTP","Provide a place ID"); return end
    TeleportService:Teleport(id, player)
end

CommandActions.autorj = function()
    local gs = game:GetService("GuiService")
    gs.ErrorMessageChanged:Connect(function()
        pcall(function()
            if #Players:GetPlayers()<=1 then
                player:Kick("\nRejoining...")
                task.wait(0.3)
                TeleportService:Teleport(game.PlaceId, player)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
            end
        end)
    end)
    notify("AutoRJ","Enabled")
end

CommandActions.clearerror = function()
    pcall(function() game:GetService("GuiService"):ClearError() end)
    notify("ClearError","Done")
end

CommandActions.antigameplaypaused = function()
    pcall(function()
        _G.devxNetPaused = game:GetService("CoreGui").RobloxGui.ChildAdded:Connect(function(obj)
            if obj.Name=="CoreScripts/NetworkPause" then obj:Destroy() end
        end)
        game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy()
    end)
    notify("AntiGameplayPaused","Enabled")
end

CommandActions.use2022materials = function()
    pcall(function()
        local ms = game:GetService("MaterialService")
        local sh = sethiddenproperty or set_hidden_property
        if sh then sh(ms,"Use2022Materials", true) end
    end)
    notify("2022Materials","Enabled")
end

CommandActions.unuse2022materials = function()
    pcall(function()
        local ms = game:GetService("MaterialService")
        local sh = sethiddenproperty or set_hidden_property
        if sh then sh(ms,"Use2022Materials", false) end
    end)
    notify("2022Materials","Disabled")
end

CommandActions.breakloops = function()
    _loopBreak = true
    task.wait(0.1)
    _loopBreak = false
    notify("BreakLoops","All loops stopped")
end

local _advFlingActive = false
local _advToggleStates = {}

local function playAnim(id, timePos, speed, loop)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..tostring(id)
    local track = hum:LoadAnimation(anim)
    if speed and speed > 0 then track:AdjustSpeed(speed) end
    track.Looped = loop or false
    track:Play()
    if timePos then track.TimePosition = timePos end
    return track
end

local function stopAnimAll()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
end

local function getTargetByName(name)
    if not name and currentTarget then return currentTarget end
    if not name then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then return p end
    end
end

CommandActions.advfling = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("AdvFling","Select a target"); return end
    local root = getRoot(player.Character)
    if not root then return end
    _advFlingActive = true
    local oldPos = root.CFrame
    local bv = Instance.new("BodyVelocity"); bv.Name="Flinger"
    bv.Velocity = Vector3.new(900000000, 900000000, 900000000)
    bv.MaxForce = Vector3.new(1/0, 1/0, 1/0); bv.Parent = root
    local oldH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/1/0
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
    local sum = 0
    task.spawn(function()
        while _advFlingActive do
            pcall(function()
                local troot = target.Character and getRoot(target.Character)
                if not troot then return end
                local positions = {Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0), Vector3.new(2.25, 1.5, -2.25)}
                for _, offset in ipairs(positions) do
                    root.CFrame = CFrame.new(troot.Position) * CFrame.new(offset) * CFrame.Angles(math.rad(sum), 0, 0)
                    root.AssemblyLinearVelocity = Vector3.new(90000000, 900000000, 90000000)
                    root.AssemblyAngularVelocity = Vector3.new(900000000, 900000000, 900000000)
                    sum += 100; task.wait()
                end
            end)
            task.wait()
        end
        bv:Destroy()
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        workspace.FallenPartsDestroyHeight = oldH
        repeat
            root.CFrame = oldPos * CFrame.new(0, 0.5, 0)
            root.AssemblyLinearVelocity = Vector3.new()
            root.AssemblyAngularVelocity = Vector3.new()
            task.wait()
        until (root.Position - oldPos.Position).Magnitude < 25
    end)
    notify("AdvFling","Flinging "..target.Name)
end

CommandActions.unadvfling = function()
    _advFlingActive = false
    notify("AdvFling","Stopped")
end

CommandActions.jerkontarget = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("JerkOnTarget","Select a target"); return end
    _G.devxJerkOnTarget = true
    local oldH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/1/0
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    task.spawn(function()
        while _G.devxJerkOnTarget do
            pcall(function()
                local r15mode = hum and hum.RigType == Enum.HumanoidRigType.R15
                if r15mode then playAnim(698251653, 0.6, 0.4, true); task.wait(0.16)
                else playAnim(72042024, 0.675, 1, true); task.wait(0.4) end
            end)
            task.wait()
        end
        stopAnimAll()
        workspace.FallenPartsDestroyHeight = oldH
    end)
    task.spawn(function()
        while _G.devxJerkOnTarget do
            pcall(function()
                local troot = target.Character and getRoot(target.Character)
                local root = getRoot(player.Character)
                if troot and root and hum then
                    hum:ChangeState("GettingUp")
                    if not hum.Sit then hum.Sit = true end
                    root.CFrame = troot.CFrame * CFrame.new(0, 1, -3) * CFrame.Angles(0, math.pi, 0)
                    root.AssemblyLinearVelocity = Vector3.new()
                end
            end)
            task.wait()
        end
        if hum then hum.Sit = false end
    end)
    notify("JerkOnTarget","Started on "..target.Name)
end

CommandActions.unjerkontarget = function()
    _G.devxJerkOnTarget = false
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    notify("JerkOnTarget","Stopped")
end

CommandActions.bangontarget = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("BangOnTarget","Select a target"); return end
    _G.devxBangOnTarget = true
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local r15mode = hum and hum.RigType == Enum.HumanoidRigType.R15
    playAnim(r15mode and 5918726674 or 148840371, 0, 3, true)
    local sum = -2; local sumN = 0.1; local offset = r15mode and -1 or -0.75
    task.spawn(function()
        while _G.devxBangOnTarget do
            pcall(function()
                local torso = target.Character and (target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Torso"))
                local root = getRoot(player.Character)
                if torso and root and hum then
                    hum.Sit = true
                    root.CFrame = torso.CFrame * CFrame.new(0, offset, sum) * CFrame.Angles(math.rad(270), 0, 0)
                    root.AssemblyLinearVelocity = Vector3.new()
                    sum += sumN
                    if sum >= -1 or sum <= -2 then sumN = -sumN end
                end
            end)
            task.wait()
        end
        if hum then hum.Sit = false end
        stopAnimAll()
    end)
    notify("BangOnTarget","Started on "..target.Name)
end

CommandActions.unbangontarget = function()
    _G.devxBangOnTarget = false
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    stopAnimAll()
    notify("BangOnTarget","Stopped")
end

CommandActions.reversebang = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("ReverseBang","Select a target"); return end
    _G.devxReverseBang = true
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local r15mode = hum and hum.RigType == Enum.HumanoidRigType.R15
    playAnim(r15mode and 5918726674 or 148840371, 0, 3, true)
    task.spawn(function()
        while _G.devxReverseBang do
            pcall(function()
                local troot = target.Character and getRoot(target.Character)
                local root = getRoot(player.Character)
                if troot and root and hum then
                    hum.Sit = true
                    root.CFrame = troot.CFrame * CFrame.new(0, 1, 1.1) * CFrame.Angles(0, 0, 0)
                    root.AssemblyLinearVelocity = Vector3.new()
                end
            end)
            task.wait()
        end
        if hum then hum.Sit = false end
        stopAnimAll()
    end)
    notify("ReverseBang","Started on "..target.Name)
end

CommandActions.unreversebang = function()
    _G.devxReverseBang = false
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    stopAnimAll(); notify("ReverseBang","Stopped")
end

CommandActions.suck = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("Suck","Select a target"); return end
    _G.devxSuck = true
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    task.spawn(function()
        while _G.devxSuck do
            pcall(function()
                local troot = target.Character and getRoot(target.Character)
                local root = getRoot(player.Character)
                if troot and root and hum then
                    hum.Sit = true
                    root.CFrame = troot.CFrame * CFrame.new(0, 0, 1.2) * CFrame.Angles(0, -3, 0)
                    root.AssemblyLinearVelocity = Vector3.new()
                end
            end)
            task.wait()
        end
        if hum then hum.Sit = false end
    end)
    notify("Suck","Started on "..target.Name)
end

CommandActions.unsuck = function()
    _G.devxSuck = false
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    notify("Suck","Stopped")
end

CommandActions.backpack = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("Backpack","Select a target"); return end
    _G.devxBackpack = true
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    task.spawn(function()
        while _G.devxBackpack do
            pcall(function()
                local troot = target.Character and getRoot(target.Character)
                local root = getRoot(player.Character)
                if troot and root and hum then
                    hum.Sit = true
                    root.CFrame = troot.CFrame * CFrame.new(0, 1, -1.2)
                    root.AssemblyLinearVelocity = Vector3.new()
                end
            end)
            task.wait()
        end
        if hum then hum.Sit = false end
    end)
    notify("Backpack","Started on "..target.Name)
end

CommandActions.unbackpack = function()
    _G.devxBackpack = false
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    notify("Backpack","Stopped")
end

local _antiSiteConn = nil
CommandActions.antisite = function()
    if _antiSiteConn then _antiSiteConn:Disconnect() end
    _antiSiteConn = RunService.Heartbeat:Connect(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Sit then hum.Sit = false end
    end)
    notify("AntiSit","Enabled")
end

CommandActions.unantisite = function()
    if _antiSiteConn then _antiSiteConn:Disconnect(); _antiSiteConn = nil end
    notify("AntiSit","Disabled")
end

local _antiJumpPower, _antiJumpHeight
local _antiJumpConn = nil
CommandActions.antijump = function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    _antiJumpPower = hum.JumpPower; _antiJumpHeight = hum.JumpHeight
    if _antiJumpConn then _antiJumpConn:Disconnect() end
    _antiJumpConn = RunService.Heartbeat:Connect(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = 0; h.JumpHeight = 0 end
    end)
    notify("AntiJump","Enabled")
end

CommandActions.unantijump = function()
    if _antiJumpConn then _antiJumpConn:Disconnect(); _antiJumpConn = nil end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower = _antiJumpPower or 50
        hum.JumpHeight = _antiJumpHeight or 7.2
    end
    notify("AntiJump","Disabled")
end

CommandActions.antivoid2 = function()
    _G.devxAntiVoid2 = true
    task.spawn(function()
        while _G.devxAntiVoid2 do
            workspace.FallenPartsDestroyHeight = 0/1/0
            task.wait(1)
        end
    end)
    notify("AntiVoid2","Enabled – FallenPartsDestroyHeight = NaN")
end

CommandActions.unantivoid2 = function()
    _G.devxAntiVoid2 = false
    workspace.FallenPartsDestroyHeight = -500
    notify("AntiVoid2","Disabled")
end

local _antiAFK2 = false
CommandActions.antiafk2 = function()
    _antiAFK2 = true
    task.spawn(function()
        while _antiAFK2 do
            pcall(function()
                local vu = game:GetService("VirtualUser")
                local cam = workspace.CurrentCamera
                if cam then
                    vu:Button2Down(Vector2.new(0, 0), cam.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0, 0), cam.CFrame)
                end
            end)
            task.wait(300)
        end
    end)
    notify("AntiAFK2","Enabled")
end

CommandActions.unantiafk2 = function()
    _antiAFK2 = false
    notify("AntiAFK2","Disabled")
end

local _antiBang = false
CommandActions.antibang = function()
    _antiBang = true
    task.spawn(function()
        while _antiBang do
            pcall(function()
                workspace.FallenPartsDestroyHeight = 0/1/0
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                local root = hum and hum.RootPart
                if hum and root and root.AssemblyLinearVelocity.Magnitude > 500 then
                    local savedCF = root.CFrame
                    local t = tick()
                    repeat
                        root.CFrame = CFrame.new(0, -499, 0) * CFrame.Angles(math.rad(90), 0, 0)
                        root.AssemblyLinearVelocity = Vector3.new()
                        task.wait()
                    until tick() > t + 1
                    root.AssemblyLinearVelocity = Vector3.new()
                    root.CFrame = savedCF
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
            task.wait(0.1)
        end
        workspace.FallenPartsDestroyHeight = -500
    end)
    notify("AntiBang","Enabled")
end

CommandActions.unantibang = function()
    _antiBang = false
    workspace.FallenPartsDestroyHeight = -500
    notify("AntiBang","Disabled")
end

local _antiFlingData = {}
local _antiFlingConns = {}
CommandActions.antifling2 = function()
    local function protect(char)
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                _antiFlingData[p] = p.CanCollide
                p.CanCollide = false
            end
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then protect(p.Character) end
        table.insert(_antiFlingConns, p.CharacterAdded:Connect(function(c)
            task.wait()
            protect(c)
        end))
    end
    notify("AntiFling2","Enabled")
end

CommandActions.unantifling2 = function()
    for _, c in pairs(_antiFlingConns) do c:Disconnect() end
    _antiFlingConns = {}
    for part, cc in pairs(_antiFlingData) do
        pcall(function() part.CanCollide = cc end)
    end
    _antiFlingData = {}
    notify("AntiFling2","Disabled")
end

local _animIds = {
    armcutr6 = "33169583",
    boxesr6 = "126753849",
    faintr6 = "181526230",
    hugr6 = "185299570",
    bangr6 = "148840371",
    illusionr6 = "215384594",
    insaner6 = "33796059",
    backpackheadr6 = "68339848",
    floatingheadr6 = "121572214",
    jerkingr6 = "204292303",
    saluter15 = "10714389988",
    doggyr15 = "13694096724",
    sb3awyr15 = "10214311282",
    zombier15 = "708553116",
    flingarmsr15 = "754656200",
    dolphinr15 = "10714068222",
    sleepyr15 = "10714360343",
    hugr15 = "10714377090",
    crazyr15 = "10713957138",
    b3b3r15 = "13694096724",
}

for cmdName, animId in pairs(_animIds) do
    CommandActions[cmdName] = function()
        playAnim(animId, 0, 1, true)
        notify("Anim", cmdName)
    end
end

CommandActions.stopanim = function()
    stopAnimAll()
    notify("StopAnim","Done")
end

local _checkpoint = nil
CommandActions.checkpointsave = function()
    local root = getRoot(player.Character)
    if root then
        _checkpoint = root.CFrame
        notify("Checkpoint","Saved at current position")
    end
end

CommandActions.checkpointload = function()
    if _checkpoint then
        local root = getRoot(player.Character)
        if root then root.CFrame = _checkpoint end
        notify("Checkpoint","Loaded")
    else
        notify("Checkpoint","No checkpoint saved")
    end
end

CommandActions.predictiontp = function(args)
    local target = getTargetByName(args and args[1])
    if not target then notify("PredictionTP","Select a target"); return end
    local root = getRoot(player.Character)
    local troot = target.Character and getRoot(target.Character)
    if not root or not troot then return end
    local thum = target.Character:FindFirstChildOfClass("Humanoid")
    local ping = player:GetNetworkPing()
    local predicted = troot.Position + (thum and thum.MoveDirection * (thum.WalkSpeed * ping) or Vector3.new())
    root.CFrame = CFrame.new(predicted) + Vector3.new(3, 0, 0)
    notify("PredictionTP","Teleported to predicted position of "..target.Name)
end

local _lastCmd = ""
local _iyKeepConn = nil
local _loopBrightConn = nil
local _loopNoBguiConn = nil
local _guideleteConn = nil
local _antiFlingConn2 = nil
local _nocdTrigger = nil
local _instantPPConn = nil
local _wallwalkConn = nil
local _oldLighting = {}
local _pointLight = nil
local _hiddenGUIs = {}
local _invisGUIs = {}
local _spectateConn1, _spectateConn2
local _spoofSpeedConn, _spoofJPConn
local _pathfindConn = nil
local _loopFBConn = nil
local _loopNoBGConn = nil

CommandActions.addalias = function(args)
    if not args or #args < 2 then notify("AddAlias","Provide cmd and alias"); return end
    notify("AddAlias","Use format: addalias [cmd] [alias]")
end

CommandActions.removealias = function(args)
    if not args or #args < 1 then notify("RemoveAlias","Provide alias"); return end
    notify("RemoveAlias","Removed: "..(args[1] or ""))
end

CommandActions.clraliases = function()
    notify("Aliases","All aliases cleared")
end

CommandActions.addplugin = function(args)
    notify("Plugin","Plugins require exploit filesystem support")
end

CommandActions.removeplugin = function(args)
    notify("Plugin","Plugins require exploit filesystem support")
end

CommandActions.reloadplugin = function(args)
    notify("Plugin","Plugins require exploit filesystem support")
end

CommandActions.addallplugins = function()
    notify("Plugin","Plugins require exploit filesystem support")
end

CommandActions.alignmentkeys = function()
    if _G.devxAlignKeys then _G.devxAlignKeys:Disconnect() end
    _G.devxAlignKeys = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Comma then workspace.CurrentCamera:PanUnits(-1) end
        if inp.KeyCode == Enum.KeyCode.Period then workspace.CurrentCamera:PanUnits(1) end
    end)
    notify("AlignmentKeys","Enabled – use , and .")
end

CommandActions.unalignmentkeys = function()
    if _G.devxAlignKeys then _G.devxAlignKeys:Disconnect(); _G.devxAlignKeys = nil end
    notify("AlignmentKeys","Disabled")
end

CommandActions.antiidle = function()
    if _G.devxAntiIdle then _G.devxAntiIdle:Disconnect() end
    _G.devxAntiIdle = player.Idled:Connect(function()
        pcall(function()
            local vim = Instance.new("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            vim:Destroy()
        end)
    end)
    notify("AntiIdle","Enabled")
end

CommandActions.audiologger = function()
    notify("AudioLogger","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua"))() end)
end

CommandActions.autokeypress = function(args)
    local key = args and args[1]
    if not key then notify("AutoKeyPress","Provide a key"); return end
    local downDelay = tonumber(args[2]) or 0.1
    local upDelay = tonumber(args[3]) or 0.1
    if not (keypress and keyrelease) then notify("AutoKeyPress","Not supported by executor"); return end
    local keyMap = {a=0x41, b=0x42, c=0x43, d=0x44, e=0x45, f=0x46, g=0x47, h=0x48, i=0x49, j=0x4A, k=0x4B, l=0x4C, m=0x4D, n=0x4E, o=0x4F, p=0x50, q=0x51, r=0x52, s=0x53, t=0x54, u=0x55, v=0x56, w=0x57, x=0x58, y=0x59, z=0x5A, space=0x20, enter=0x0D}
    local code = keyMap[key:lower()]
    if not code then notify("AutoKeyPress","Unknown key: "..key); return end
    _G.devxAutoKeyPress = true
    task.spawn(function()
        while _G.devxAutoKeyPress do
            keypress(code); task.wait(downDelay); keyrelease(code); task.wait(upDelay)
        end
    end)
    notify("AutoKeyPress","Pressing "..key)
end

CommandActions.unautokeypress = function()
    _G.devxAutoKeyPress = false
    notify("AutoKeyPress","Stopped")
end

CommandActions.autorejoin = function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                Players.LocalPlayer:Kick("\nRejoining...")
                task.wait(0.3)
                TeleportService:Teleport(game.PlaceId, player)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
            end
        end)
    end)
    notify("AutoRejoin","Enabled")
end

CommandActions.blocktool = function()
    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    if tool then
        for _, v in pairs(tool:GetDescendants()) do
            if v:IsA("SpecialMesh") then v:Destroy() end
        end
        notify("BlockTool","Done")
    else notify("BlockTool","Equip a tool first") end
end

CommandActions.cframefly = function(args)
    CommandActions.cfly(args)
end

CommandActions.uncframefly = function()
    CommandActions.uncfly()
end

CommandActions.cframeflyspeed = function(args)
    CommandActions.cflyspeed(args)
end

CommandActions.chardelete = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("CharDelete","Provide a name"); return end
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v.Name:lower() == name:lower() then v:Destroy() end
        end
    end
    notify("CharDelete","Deleted "..name)
end

CommandActions.chardeleteclass = function(args)
    local cls = args and args[1]
    if not cls then notify("CharDeleteClass","Provide a classname"); return end
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v.ClassName:lower() == cls:lower() then v:Destroy() end
        end
    end
    notify("CharDeleteClass","Deleted "..cls)
end

CommandActions.chatlogs = function()
    notify("ChatLogs","Log enabled – check Logs panel")
end

CommandActions.chatlogswebhook = function(args)
    _G.devxLogsWebhook = args and args[1] or nil
    notify("ChatLogsWebhook", _G.devxLogsWebhook and "Webhook set" or "Webhook cleared")
end

CommandActions.cleargamewaypoints = function()
    _waypoints = {}
    notify("ClearGameWaypoints","Done")
end

CommandActions.clearhats = function()
    if firetouchinterest then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:RemoveAccessories() end
        notify("ClearHats","Done")
    else
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:RemoveAccessories() end
        notify("ClearHats","Done (client only)")
    end
end

CommandActions.clearremovespecifictool = function()
    for k, v in pairs(_removeSpecificTools) do v:Disconnect(); _removeSpecificTools[k]=nil end
    notify("ClearRemoveTools","Done")
end

CommandActions.clearwaypoints = function()
    _waypoints = {}
    notify("ClearWaypoints","All waypoints cleared")
end

CommandActions.clickdelete = function()
    notify("ClickDelete","Go to Settings > Keybinds > Add to set up")
end

CommandActions.clickteleport = function()
    notify("ClickTeleport","Go to Settings > Keybinds > Add to set up")
end

CommandActions.clientbring = function(args)
    CommandActions.cbring(args)
end

CommandActions.copyanimationid = function(args)
    CommandActions.copyanimid(args)
end

CommandActions.copycreatorid = function()
    copy(tostring(game.CreatorId))
    notify("CopyCreatorId","Copied: "..game.CreatorId)
end

CommandActions.copygameid = function()
    copy(tostring(game.GameId))
    notify("CopyGameId","Copied: "..game.GameId)
end

CommandActions.copyplaceid = function()
    copy(tostring(game.PlaceId))
    notify("CopyPlaceId","Copied: "..game.PlaceId)
end

CommandActions.copyposition = function(args)
    local name = args and args[1]
    local target = name and Players:FindFirstChild(name) or player
    local root = target and target.Character and getRoot(target.Character)
    if root then
        local p = root.Position
        local str = math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z)
        copy(str); notify("CopyPosition","Copied: "..str)
    end
end

CommandActions.copyuserid = function(args)
    CommandActions.copyid(args)
end

CommandActions.creatorid = function()
    notify("CreatorId","Creator ID: "..tostring(game.CreatorId))
end

CommandActions.ctrllock = function()
    pcall(function()
        local mlc = player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
        local bk = mlc:FindFirstChild("BoundKeys") or Instance.new("StringValue", mlc)
        bk.Name = "BoundKeys"; bk.Value = "LeftControl"
    end)
    notify("CtrlLock","Shift lock bound to LeftControl")
end

CommandActions.unctrllock = function()
    pcall(function()
        local mlc = player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
        local bk = mlc:FindFirstChild("BoundKeys") or Instance.new("StringValue", mlc)
        bk.Name = "BoundKeys"; bk.Value = "LeftShift"
    end)
    notify("CtrlLock","Shift lock restored to LeftShift")
end

CommandActions.deleteselectedtool = function()
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("Tool") or v:IsA("HopperBin") then v:Destroy() end
        end
    end
    notify("DeleteSelectedTool","Done")
end

CommandActions.deletewaypoint = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("DeleteWaypoint","Provide a name"); return end
    _waypoints[name] = nil
    notify("DeleteWaypoint","Deleted '"..name.."'")
end

CommandActions.disable = function(args)
    local item = args and args[1]
    if not item then notify("Disable","Provide an item name"); return end
    local map = {inventory=Enum.CoreGuiType.Backpack, playerlist=Enum.CoreGuiType.PlayerList, chat=Enum.CoreGuiType.Chat, emotes=Enum.CoreGuiType.EmotesMenu, all=Enum.CoreGuiType.All}
    if item:lower()=="reset" then
        StarterGui:SetCore("ResetButtonCallback", false)
    else
        local t = map[item:lower()]
        if t then StarterGui:SetCoreGuiEnabled(t, false) end
    end
    notify("Disable","Disabled: "..item)
end

CommandActions.enable = function(args)
    local item = args and args[1]
    if not item then notify("Enable","Provide an item name"); return end
    local map = {inventory=Enum.CoreGuiType.Backpack, playerlist=Enum.CoreGuiType.PlayerList, chat=Enum.CoreGuiType.Chat, emotes=Enum.CoreGuiType.EmotesMenu, all=Enum.CoreGuiType.All}
    if item:lower()=="reset" then
        StarterGui:SetCore("ResetButtonCallback", true)
    else
        local t = map[item:lower()]
        if t then StarterGui:SetCoreGuiEnabled(t, true) end
    end
    notify("Enable","Enabled: "..item)
end

CommandActions.discord = function()
    copy("https://discord.gg/78ZuWSq")
    notify("Discord","Copied: discord.gg/78ZuWSq")
end

CommandActions.emote = function(args)
    local id = args and args[1]
    if not id then notify("Emote","Provide an asset ID"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:PlayEmoteAndGetAnimTrackById(tonumber(id)) end)
        if not pcall(function() hum:PlayEmoteAndGetAnimTrackById(tonumber(id)) end) then
            CommandActions.animation(args)
        end
    end
end

CommandActions.exit = function()
    game:Shutdown()
end

CommandActions.explorer = function()
    notify("Explorer","Loading Dex++...")
    pcall(function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end)
end

CommandActions.fireclickdetectors = function(args)
    CommandActions.firecd(args)
end

CommandActions.fireproximityprompts = function(args)
    CommandActions.firepp(args)
end

CommandActions.firetouchinterests = function(args)
    if not firetouchinterest then notify("FireTouchInterests","Not supported"); return end
    local name = args and args[1]
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") then
            if not name or v.Parent.Name:lower()==name:lower() then
                pcall(function() firetouchinterest(v.Parent, root, 0); firetouchinterest(v.Parent, root, 1) end)
            end
        end
    end
    notify("FireTouchInterests","Done")
end

CommandActions.flyspeed = function(args)
    iyflyspeed = tonumber(args and args[1]) or 1
    notify("FlySpeed", tostring(iyflyspeed))
end

CommandActions.freecamgoto = function(args)
    CommandActions.fcgoto(args)
end

CommandActions.freecampos = function(args)
    CommandActions.fcpos(args)
end

CommandActions.freecamspeed = function(args)
    CommandActions.fcspeed(args)
end

CommandActions.freecamwaypoint = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("FreecamWaypoint","Provide a name"); return end
    local wp = _waypoints[name]
    if wp then
        _freecamPos = Vector3.new(wp[1], wp[2], wp[3])
        if not _freecamRunning then CommandActions.freecam() end
    else notify("FreecamWaypoint","Waypoint not found") end
end

CommandActions.gameteleport = function(args)
    CommandActions.gametp(args)
end

CommandActions.globalshadows = function()
    Lighting.GlobalShadows = true; notify("GlobalShadows","Enabled")
end

CommandActions.noglobalshadows = function()
    Lighting.GlobalShadows = false; notify("GlobalShadows","Disabled")
end

CommandActions["goto"] = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Goto","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local root = getRoot(player.Character)
            local troot = p.Character and getRoot(p.Character)
            if root and troot then
                root.CFrame = troot.CFrame + Vector3.new(3, 0, 0)
                breakVelocity()
            end
            break
        end
    end
end

CommandActions.gotocamera = function()
    local root = getRoot(player.Character)
    if root then root.CFrame = workspace.CurrentCamera.CFrame end
end

CommandActions.guidelete = function()
    if _guideleteConn then _guideleteConn:Disconnect() end
    _guideleteConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.Backspace then
            pcall(function()
                local mouse = player:GetMouse()
                local guis = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
                for _, g in pairs(guis) do if g.Visible then g:Destroy() end end
            end)
        end
    end)
    notify("GuiDelete","Hover over a GUI and press backspace")
end

CommandActions.unguidelete = function()
    if _guideleteConn then _guideleteConn:Disconnect(); _guideleteConn = nil end
    notify("GuiDelete","Disabled")
end

CommandActions.guiscale = function(args)
    local scale = tonumber(args and args[1]) or 1
    scale = math.clamp(scale, 0.4, 2)
    window.Size = UDim2.new(0, math.floor(520*scale), 0, math.floor(360*scale))
    notify("GuiScale","Set to "..scale)
end

CommandActions.handlekill = function(args)
    if not firetouchinterest then notify("HandleKill","Not supported by executor"); return end
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("HandleKill","Select a target"); return end
    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    if not handle then notify("HandleKill","Equip a tool with a Handle first"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local root = p.Character and getRoot(p.Character)
            if root then
                firetouchinterest(handle, root, 0)
                firetouchinterest(handle, root, 1)
                notify("HandleKill","Hit "..p.Name)
            end
            break
        end
    end
end

CommandActions.hideguis = function()
    _hiddenGUIs = {}
    for _, v in pairs(playerGui:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("ScrollingFrame") or v:IsA("ImageLabel")) and v.Visible then
            v.Visible = false
            table.insert(_hiddenGUIs, v)
        end
    end
    notify("HideGuis","Hidden "..(#_hiddenGUIs).." GUIs")
end

CommandActions.unhideguis = function()
    for _, v in pairs(_hiddenGUIs) do
        pcall(function() v.Visible = true end)
    end
    _hiddenGUIs = {}
    notify("HideGuis","Restored")
end

CommandActions.hideiy = function()
    window.Visible = false
    notify("HideIY","Press F12 to restore")
end

CommandActions.showiy = function()
    window.Visible = true
end

CommandActions.hidewaypoints = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BoxHandleAdornment") and v.Name == "DevXWaypoint" then v:Destroy() end
    end
    notify("HideWaypoints","Done")
end

CommandActions.showwaypoints = function()
    CommandActions.hidewaypoints()
    for name, wp in pairs(_waypoints) do
        local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = false
        part.Size = Vector3.new(3, 3, 3); part.Transparency = 0.5
        part.CFrame = CFrame.new(wp[1], wp[2], wp[3]); part.Parent = workspace
        local box = Instance.new("BoxHandleAdornment"); box.Name = "DevXWaypoint"
        box.Adornee = part; box.AlwaysOnTop = true; box.Size = part.Size
        box.Transparency = 0.3; box.Color = BrickColor.new("Bright blue"); box.Parent = part
        local bg = Instance.new("BillboardGui"); bg.AlwaysOnTop = true
        bg.Size = UDim2.new(0, 100, 0, 30); bg.StudsOffset = Vector3.new(0, 4, 0); bg.Adornee = part; bg.Parent = part
        local tl = Instance.new("TextLabel"); tl.BackgroundTransparency = 1; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.TextColor3 = Color3.new(1, 1, 1); tl.TextStrokeTransparency = 0; tl.Font = Enum.Font.GothamBold
        tl.TextSize = 14; tl.Text = name; tl.Parent = bg
    end
    notify("ShowWaypoints","Showing "..(#{} or 0).." waypoints")
end

CommandActions.infinitejump = function()
    CommandActions.infjump()
end

CommandActions.uninfinitejump = function()
    CommandActions.uninfjump()
end

CommandActions.instantproximityprompts = function()
    if not fireproximityprompt then notify("InstantPP","Not supported by executor"); return end
    if _instantPPConn then _instantPPConn:Disconnect() end
    _instantPPConn = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
        pcall(fireproximityprompt, prompt)
    end)
    notify("InstantPP","Enabled")
end

CommandActions.uninstantproximityprompts = function()
    if _instantPPConn then _instantPPConn:Disconnect(); _instantPPConn = nil end
    notify("InstantPP","Disabled")
end

CommandActions.inviteprompt = function(args)
    notify("InvitePrompt","Requires ExperienceService – may not work in all games")
    pcall(function()
        game:GetService("ExperienceService"):LaunchExperience({
            placeId = game.PlaceId, gameInstanceId = game.JobId
        })
    end)
end

CommandActions.jobid = function()
    copy(game.JobId)
    notify("JobId","Copied: "..game.JobId)
end

CommandActions.joinlogs = function()
    notify("JoinLogs","Join log enabled")
end

CommandActions.jumppower = function(args)
    CommandActions.jpower(args)
end

CommandActions.keepiy = function()
    if queueteleport then
        _G.devxKeepIY = true
        player.OnTeleport:Connect(function(state)
            if _G.devxKeepIY and state == Enum.TeleportState.Started then
                pcall(function() queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()") end)
            end
        end)
        notify("KeepIY","Enabled")
    else notify("KeepIY","Not supported by executor") end
end

CommandActions.unkeepiy = function()
    _G.devxKeepIY = false
    notify("KeepIY","Disabled")
end

CommandActions.togglekeepiy = function()
    if _G.devxKeepIY then CommandActions.unkeepiy() else CommandActions.keepiy() end
end

CommandActions.lastcommand = function()
    if _lastCmd ~= "" then
        commandInput.Text = _lastCmd
        executeCommand()
    end
end

CommandActions.light = function(args)
    CommandActions.flashlight()
    local pl = _flashlightPart
    if pl then
        pl.Range = tonumber(args and args[1]) or 30
        pl.Brightness = tonumber(args and args[2]) or 5
    end
end

CommandActions.nolight = function()
    CommandActions.unflashlight()
end

CommandActions.logs = function()
    notify("Logs","Open the log panel via the toggle button")
end

CommandActions.loopanimation = function()
    CommandActions.loopanim()
end

CommandActions.loopfullbright = function()
    if _loopFBConn then _loopFBConn:Disconnect() end
    _loopFBConn = RunService.RenderStepped:Connect(function()
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    notify("LoopFullbright","Enabled")
end

CommandActions.unloopfullbright = function()
    if _loopFBConn then _loopFBConn:Disconnect(); _loopFBConn = nil end
    notify("LoopFullbright","Disabled")
end

CommandActions.loopjumppower = function(args)
    CommandActions.loopjp(args)
end

CommandActions.unloopjumppower = function()
    CommandActions.unloopjp()
end

CommandActions.loopnobgui = function()
    local char = player.Character
    if not char then return end
    if _loopNoBGConn then _loopNoBGConn:Disconnect() end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then v:Destroy() end
    end
    _loopNoBGConn = char.DescendantAdded:Connect(function(v)
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            task.wait(); v:Destroy()
        end
    end)
    notify("LoopNoBgui","Enabled")
end

CommandActions.unloopnobgui = function()
    if _loopNoBGConn then _loopNoBGConn:Disconnect(); _loopNoBGConn = nil end
    notify("LoopNoBgui","Disabled")
end

CommandActions.moondex = function()
    notify("MoonDex","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
end

CommandActions.mouseteleport = function()
    local root = getRoot(player.Character)
    local mouse = player:GetMouse()
    if root and mouse.Hit then
        root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        breakVelocity()
    end
end

CommandActions.muteallvoices = function()
    CommandActions.muteallvcs()
end

CommandActions.unmuteallvoices = function()
    CommandActions.unmuteallvcs()
end

CommandActions.nobillboardgui = function()
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then v:Destroy() end
        end
    end
    notify("NoBillboardGui","Done")
end

CommandActions.noclickdetectorlimits = function()
    CommandActions.nocdlimits()
end

CommandActions.noproximitypromptlimits = function()
    CommandActions.nopplimits()
end

CommandActions.notify = function(args)
    if not args or #args == 0 then return end
    notify("Notification", table.concat(args," "))
end

CommandActions.notifyfreecamposition = function()
    CommandActions.notifyfcpos()
end

CommandActions.notifyjobid = function()
    notify("JobId", game.JobId)
end

CommandActions.notifyping = function()
    CommandActions.ping()
end

CommandActions.notifyposition = function(args)
    local name = args and args[1]
    local target = name and Players:FindFirstChild(name) or player
    local root = target and target.Character and getRoot(target.Character)
    if root then
        local p = root.Position
        notify("Position", math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z))
    end
end

CommandActions.nowalltp = function()
    CommandActions.unwalltp()
end

CommandActions.oldconsole = function()
    notify("OldConsole","Loading...")
    pcall(function()
        local s = loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/console.lua"))
        if s then s() end
    end)
end

CommandActions.partname = function()
    CommandActions.selectPart and CommandActions.selectPart() or notify("PartName","Click a part to see its path (selectpart)")
end

CommandActions.pathfindwalkto = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("PathfindWalkTo","Select a target"); return end
    _G.devxPathfind = true
    local path = game:GetService("PathfindingService"):CreatePath()
    task.spawn(function()
        while _G.devxPathfind do
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #name)==name:lower() and p.Character then
                    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                    local root = getRoot(player.Character)
                    local troot = getRoot(p.Character)
                    if hum and root and troot then
                        pcall(function()
                            path:ComputeAsync(root.Position, troot.Position)
                            for _, wp in pairs(path:GetWaypoints()) do
                                if not _G.devxPathfind then break end
                                hum:MoveTo(wp.Position)
                                hum.MoveToFinished:Wait()
                            end
                        end)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
    notify("PathfindWalkTo","Started toward "..name)
end

CommandActions.pathfindwalktowp = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("PathfindWalkToWP","Provide a waypoint name"); return end
    local wp = _waypoints[name]
    if not wp then notify("PathfindWalkToWP","Waypoint not found"); return end
    _G.devxPathfind = true
    local path = game:GetService("PathfindingService"):CreatePath()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local root = getRoot(player.Character)
    if hum and root then
        task.spawn(function()
            pcall(function()
                path:ComputeAsync(root.Position, Vector3.new(wp[1], wp[2], wp[3]))
                for _, wpt in pairs(path:GetWaypoints()) do
                    if not _G.devxPathfind then break end
                    hum:MoveTo(wpt.Position)
                    hum.MoveToFinished:Wait()
                end
            end)
        end)
    end
    notify("PathfindWalkToWP","Walking to "..name)
end

CommandActions.phonebook = function()
    local ok, canCall = pcall(function()
        return game:GetService("SocialService"):CanSendCallInviteAsync(player)
    end)
    if ok and canCall then
        pcall(function() game:GetService("SocialService"):PromptPhoneBook(player,"") end)
    else
        notify("Phonebook","Voice chat or phonebook not available")
    end
end

CommandActions.promptr15 = function()
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            game:GetService("AvatarEditorService"):PromptSaveAvatar(hum.HumanoidDescription, Enum.HumanoidRigType.R15)
        end
    end)
end

CommandActions.promptr6 = function()
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            game:GetService("AvatarEditorService"):PromptSaveAvatar(hum.HumanoidDescription, Enum.HumanoidRigType.R6)
        end
    end)
end

CommandActions.qefly = function(args)
    local val = args and args[1]
    QEfly = (val == nil or val:lower() == "true")
    notify("QEFly", QEfly and "Q/E enabled" or "Q/E disabled")
end

CommandActions.rec = function()
    pcall(function() game:GetService("CoreGui"):ToggleRecording() end)
    notify("Record","Toggled")
end

CommandActions.rejoin = function()
    if #Players:GetPlayers() <= 1 then
        Players.LocalPlayer:Kick("\nRejoining...")
        task.wait(0.3)
        TeleportService:Teleport(game.PlaceId, player)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end
end

CommandActions.removecmd = function(args)
    local name = args and args[1]
    if not name then notify("RemoveCmd","Provide a command name"); return end
    CommandActions[name:lower()] = function()
        notify("RemoveCmd","Command '"..name.."' has been disabled")
    end
    notify("RemoveCmd","Removed: "..name)
end

CommandActions.replaceroot = function()
    local char = player.Character
    if not char then return end
    local root = getRoot(char)
    if not root then return end
    local oldCF = root.CFrame
    local oldParent = char.Parent
    char.Parent = game
    local newRoot = root:Clone()
    newRoot.Parent = char
    root:Destroy()
    newRoot.CFrame = oldCF
    char.Parent = oldParent
    notify("ReplaceRoot","Done")
end

CommandActions.restorelighting = function()
    local L = Lighting
    if _oldLighting.Ambient then L.Ambient = _oldLighting.Ambient end
    if _oldLighting.Brightness then L.Brightness = _oldLighting.Brightness end
    if _oldLighting.ClockTime then L.ClockTime = _oldLighting.ClockTime end
    if _oldLighting.FogEnd then L.FogEnd = _oldLighting.FogEnd end
    if _oldLighting.GlobalShadows ~= nil then L.GlobalShadows = _oldLighting.GlobalShadows end
    notify("RestoreLighting","Restored")
end

-- Save original lighting
_oldLighting = {
    Ambient = Lighting.Ambient, Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

CommandActions.rolewatchleave = function()
    if _G.devxRolewatch then
        _G.devxRolewatchLeave = not _G.devxRolewatchLeave
        notify("RolewatchLeave", _G.devxRolewatchLeave and "Will leave on trigger" or "Will only notify on trigger")
    else
        notify("RolewatchLeave","Enable rolewatch first")
    end
end

CommandActions.rolewatchstop = function()
    if _G.devxRolewatch then _G.devxRolewatch:Disconnect(); _G.devxRolewatch = nil end
    notify("Rolewatch","Stopped")
end

CommandActions.savegame = function()
    if saveinstance then
        notify("SaveGame","Saving... this may take a while")
        task.spawn(function() saveinstance(); notify("SaveGame","Saved!") end)
    else
        notify("SaveGame","Not supported by your executor")
    end
end

CommandActions.screenshot = function()
    pcall(function() game:GetService("CaptureService"):CaptureScreenshot(function() end) end)
    notify("Screenshot","Taken")
end

CommandActions.setcreatorid = function()
    pcall(function() player.UserId = game.CreatorId end)
    notify("SetCreatorId","Set to "..game.CreatorId)
end

CommandActions.setwaypoint = function(args)
    CommandActions.savepos(args)
end

CommandActions.showguis = function()
    _invisGUIs = {}
    for _, v in pairs(playerGui:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and not v.Visible then
            v.Visible = true; table.insert(_invisGUIs, v)
        end
    end
    notify("ShowGuis","Showing "..(#_invisGUIs).." GUIs")
end

CommandActions.unshowguis = function()
    for _, v in pairs(_invisGUIs) do pcall(function() v.Visible = false end) end
    _invisGUIs = {}
    notify("ShowGuis","Restored")
end

CommandActions.simplespy = function()
    notify("SimpleSpy","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))() end)
end

CommandActions.spectate = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("Spectate","Select a target"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            if p.Character then
                workspace.CurrentCamera.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid") or p.Character
                if _spectateConn1 then _spectateConn1:Disconnect() end
                if _spectateConn2 then _spectateConn2:Disconnect() end
                _spectateConn1 = p.CharacterAdded:Connect(function(c)
                    workspace.CurrentCamera.CameraSubject = c:WaitForChild("Humanoid")
                end)
                _spectateConn2 = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                    if p.Character then workspace.CurrentCamera.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid") end
                end)
                notify("Spectate","Viewing "..p.Name)
            end
            break
        end
    end
end

CommandActions.unspectate = function()
    if _spectateConn1 then _spectateConn1:Disconnect() end
    if _spectateConn2 then _spectateConn2:Disconnect() end
    workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    notify("Spectate","Stopped")
end

CommandActions.viewpart = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("ViewPart","Provide a part name"); return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower() == name:lower() and v:IsA("BasePart") then
            workspace.CurrentCamera.CameraSubject = v
            notify("ViewPart","Viewing "..v.Name)
            break
        end
    end
end

CommandActions.spoofjumppower = function(args)
    if not hookmetamethod then notify("SpoofJP","Not supported by executor"); return end
    local jp = tonumber(args and args[1]) or 50
    local char = player.Character
    if _spoofJPConn then pcall(_spoofJPConn) end
    local oldIndex; oldIndex = hookmetamethod(game,"__index", newcclosure(function(self, key)
        if not checkcaller() and typeof(self)=="Instance" and self:IsA("Humanoid") and
            (key=="JumpPower" or key=="JumpHeight") and self:IsDescendantOf(char) then
            return jp
        end
        return oldIndex(self, key)
    end))
    notify("SpoofJP", tostring(jp))
end

CommandActions.spoofspeed = function(args)
    if not hookmetamethod then notify("SpoofSpeed","Not supported by executor"); return end
    local spd = tonumber(args and args[1]) or 16
    local char = player.Character
    local oldIndex; oldIndex = hookmetamethod(game,"__index", newcclosure(function(self, key)
        if not checkcaller() and typeof(self)=="Instance" and self:IsA("Humanoid") and
            key=="WalkSpeed" and self:IsDescendantOf(char) then
            return spd
        end
        return oldIndex(self, key)
    end))
    notify("SpoofSpeed", tostring(spd))
end

CommandActions.stopanimations = function()
    CommandActions.stopanim()
end

CommandActions.team = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("Team","Provide a team name"); return end
    for _, t in pairs(game:GetService("Teams"):GetChildren()) do
        if t.Name:lower():find(name:lower()) then
            if firetouchinterest then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("SpawnLocation") and v.BrickColor == t.TeamColor and v.AllowTeamChangeOnTouch then
                        local root = getRoot(player.Character)
                        if root then firetouchinterest(v, root, 0); firetouchinterest(v, root, 1) end
                        break
                    end
                end
            else
                player.Team = t
            end
            notify("Team","Changed to "..t.Name)
            return
        end
    end
    notify("Team","Team not found: "..name)
end

CommandActions.teleporttool = function()
    local tool = Instance.new("Tool"); tool.Name = "TeleportTool"
    tool.RequiresHandle = false; tool.Parent = player:FindFirstChildWhichIsA("Backpack")
    tool.Activated:Connect(function()
        local root = getRoot(player.Character)
        local mouse = player:GetMouse()
        if root and mouse.Hit then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            breakVelocity()
        end
    end)
    notify("TeleportTool","Added to backpack")
end

CommandActions.togglefs = function()
    pcall(function() game:GetService("GuiService"):ToggleFullscreen() end)
end

CommandActions.toggleswim = function()
    if _swimConn then CommandActions.unswim() else CommandActions.swim() end
end

CommandActions.togglexray = function()
    xrayEnabled = not xrayEnabled
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
            v.LocalTransparencyModifier = xrayEnabled and 0.6 or 0
        end
    end
    notify("Xray", xrayEnabled and "Enabled" or "Disabled")
end

CommandActions.toolinvisible = function()
    local char = player.Character
    if not char then return end
    local touched = false
    local box = Instance.new("Part"); box.Anchored = true; box.CanCollide = true
    box.Size = Vector3.new(10, 1, 10); box.Position = Vector3.new(0, 10000, 0); box.Parent = workspace
    local loc = getRoot(char).Position
    box.Touched:Connect(function(part)
        if part.Parent and part.Parent.Name == player.Name and not touched then
            touched = true
            local no = char.HumanoidRootPart:Clone()
            task.wait(0.25); char.HumanoidRootPart:Destroy()
            no.Parent = char; char:MoveTo(loc); touched = false
        end
    end)
    char:MoveTo(Vector3.new(0, 10000.5, 0))
    notify("ToolInvisible","Done")
end

CommandActions.tools = function()
    local function copyTools(container)
        for _, v in pairs(container:GetDescendants()) do
            if v:IsA("Tool") or v:IsA("HopperBin") then
                v:Clone().Parent = player:FindFirstChildWhichIsA("Backpack")
            end
        end
    end
    copyTools(game:GetService("ReplicatedStorage"))
    copyTools(Lighting)
    notify("Tools","Copied tools from ReplicatedStorage and Lighting")
end

CommandActions.tpposition = function(args)
    CommandActions.tppos(args)
end

CommandActions.tweengotocamera = function()
    CommandActions.tweengotocam()
end

CommandActions.tweengotopartclass = function(args)
    local cls = args and args[1]
    if not cls then notify("TweenGotoPartClass","Provide a classname"); return end
    local root = getRoot(player.Character)
    if not root then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.ClassName:lower()==cls:lower() and v:IsA("BasePart") then
            TweenService:Create(root, TweenInfo.new(_tweenSpeed, Enum.EasingStyle.Linear), {CFrame=v.CFrame+Vector3.new(0, 3, 0)}):Play()
            break
        end
    end
end

CommandActions.tweentpposition = function(args)
    CommandActions.tweenpos(args)
end

CommandActions.tweenwaypoint = function(args)
    CommandActions.tweenwp(args)
end

CommandActions.unvehiclefly = function()
    CommandActions.unfly()
end

CommandActions.vehicleclip = function()
    CommandActions.clipvehicle and CommandActions.clipvehicle() or notify("VehicleClip","Re-enabled collision")
end

CommandActions.vehiclefly = function(args)
    CommandActions.vfly(args)
end

CommandActions.vfly = function(args)
    NOFLY(); task.wait()
    if args and tonumber(args[1]) then vehicleflyspeed = tonumber(args[1]) end
    sFLY(true)
    notify("VehicleFly","Enabled")
end

CommandActions.vehicleflyspeed = function(args)
    vehicleflyspeed = tonumber(args and args[1]) or 1
    notify("VehicleFlySpeed", tostring(vehicleflyspeed))
end

CommandActions.vehiclegoto = function(args)
    local name = args and args[1]
    if not name and currentTarget then name = currentTarget.Name end
    if not name then notify("VehicleGoto","Select a target"); return end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not seat then notify("VehicleGoto","Sit in a vehicle first"); return end
    local vehicle = seat:FindFirstAncestorWhichIsA("Model")
    if not vehicle then notify("VehicleGoto","No vehicle found"); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name)==name:lower() then
            local troot = p.Character and getRoot(p.Character)
            if troot then vehicle:PivotTo(troot:GetPivot()) end
            break
        end
    end
end

CommandActions.vehiclenoclip = function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not seat then notify("VehicleNoclip","Sit in a vehicle first"); return end
    local vehicle = seat:FindFirstAncestorWhichIsA("Model")
    if vehicle then
        for _, v in pairs(vehicle:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
    CommandActions.noclip()
    notify("VehicleNoclip","Enabled")
end

CommandActions.walktoposition = function(args)
    local x, y, z = tonumber(args and args[1]), tonumber(args and args[2]), tonumber(args and args[3])
    if not(x and y and z) then notify("WalkToPosition","Provide X Y Z"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(Vector3.new(x, y, z)) end
end

CommandActions.walktowaypoint = function(args)
    local name = args and table.concat(args," ")
    if not name then notify("WalkToWaypoint","Provide a name"); return end
    local wp = _waypoints[name]
    if not wp then notify("WalkToWaypoint","Waypoint not found"); return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(Vector3.new(wp[1], wp[2], wp[3])) end
end

CommandActions.wallwalk = function()
    notify("WallWalk","Loading...")
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/wallwalker.lua"))() end)
end

CommandActions.waypoint = function(args)
    CommandActions.loadpos(args)
end

CommandActions.waypointpos = function(args)
    local name = args and args[1]
    local x, y, z = tonumber(args and args[2]), tonumber(args and args[3]), tonumber(args and args[4])
    if not(name and x and y and z) then notify("WaypointPos","Provide name X Y Z"); return end
    _waypoints[name] = {x, y, z}
    notify("WaypointPos","Saved '"..name.."' at "..x..", "..y..", "..z)
end

CommandActions.waypoints = function()
    CommandActions.listpos()
end

local playerTargetCmds = {
    ["goto"]=1, walkto=1, loopgoto=1, cbring=1, loopbring=1, unloopbring=1, clientbring=1,
    orbit=1, carpet=1, headsit=1, scare=1, bang=1, stareat=1,
    friend=1, unfriend=1, locate=1, unlocate=1, hitbox=1, headsize=1,
    userid=1, copyid=1, copyuserid=1, age=1, inspect=1, whisper=1,
    copytools=1, copyanimid=1, copyanimationid=1, chams=1,
    kill=1, loopkill=1, freeze=1, unfreeze=1, freezeplr=1, unfreezeplr=1,
    loopfreeze=1, bring=1, tp=1, jail=1, unjail=1, lookat=1, handlekill=1,
    fcgoto=1, freecamgoto=1, muteboombox=1, unmuteboombox=1,
    tweengoto=1, pulsetp=1, pmspam=1, unpmspam=1,
    listento=1, mutevc=1, unmutevc=1, joindate=1, chatjoindate=1,
    chatage=1, copyname=1, appearanceid=1, copyappearanceid=1,
    tpunanchored=1, copyanimation=1, advfling=1, jerkontarget=1,
    bangontarget=1, reversebang=1, suck=1, backpack=1,
    predictiontp=1, spectate=1, vehiclegoto=1, pathfindwalkto=1,
    notifyposition=1, copyposition=1,
}

local function findCommandAction(name)
    for cmdName, action in pairs(CommandActions) do
        if cmdName:lower() == name:lower() then
            return action
        end
    end
    return nil
end

local function executeCommand()
    local raw = commandInput.Text:match("^%s*(.-)%s*$")
    if raw == "" then return end
    local parts = {}
    for w in raw:gmatch("%S+") do table.insert(parts, w) end
    local name = parts[1]
    table.remove(parts, 1)

    if name:lower() ~= "lastcommand" and raw ~= "" then
        _lastCmd = raw
    end

    if playerTargetCmds[name:lower()] then
        if #parts == 0 or (parts[1] and Players:FindFirstChild(parts[1]) == nil and (not Players:FindFirstChild(parts[1])) ) then
            if currentTarget and currentTarget ~= player then
                local nameArg = currentTarget.Name
                if name:lower() == "whisper" then
                    table.insert(parts, 1, nameArg)
                elseif #parts == 0 then
                    table.insert(parts, 1, nameArg)
                else
                    local firstIsPlayer = false
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Name:lower():sub(1, #parts[1]) == parts[1]:lower() then
                            firstIsPlayer = true; break
                        end
                    end
                    if not firstIsPlayer then
                        table.insert(parts, 1, nameArg)
                    end
                end
            end
        end
    end

    local action = findCommandAction(name)
    if action then
        local ok, err = pcall(action, parts)
        if not ok then notify("Error", tostring(err)) end
    else
        notify("Unknown Command", name)
    end
    commandInput.Text = ""
end

sendBtn.MouseButton1Click:Connect(executeCommand)
commandInput.FocusLost:Connect(function(enter) if enter then executeCommand() end end)

discordBtn.MouseButton1Click:Connect(function()
    if copy("discord.gg/xPMwC2DTeg") then
        notify("DevX","Link copied")
        Sound("rbxassetid://9117492353")
    end
end)

local showingCommands = false
commandsToggle.MouseButton1Click:Connect(function()
    showingCommands = not showingCommands
    content.Visible = not showingCommands
    commandsPanel.Visible = showingCommands
    commandsToggle.Image = showingCommands and "rbxassetid://10723433811" or "rbxassetid://10734982144"
end)

title.MouseEnter:Connect(function() if #entries > 0 then title.TextColor3 = Color3.fromRGB(80, 220, 120) end end)
title.MouseLeave:Connect(function() title.TextColor3 = Color3.fromRGB(255, 255, 255) end)
title.MouseButton1Click:Connect(function()
    if #entries == 0 then return end
    for _, e in ipairs(entries) do e:Destroy() end
    entries = {}; lineNum = 0
end)

LogService.MessageOut:Connect(function(message, messageType)
    if shouldIgnore(message) then return end
    if messageType == Enum.MessageType.MessageWarning then pushEntry("Warn", message)
    elseif messageType == Enum.MessageType.MessageError then pushEntry("Error", message)
    else pushEntry("Print", message)
    end
end)

hotbar.InputBegan:Connect(function(input)
    if busy then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        busy = true; dragging = true
        dragStart = input.Position; startPos = window.Position
        if dragConn then dragConn:Disconnect(); dragConn = nil end
        dragConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
                dragging = false; busy = false
                if dragConn then dragConn:Disconnect(); dragConn = nil end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(0, startPos.X.Offset+delta.X, 0, startPos.Y.Offset+delta.Y)
    end
end)

local function BindResize(handle, xd, yd)
    local resizing = false
    local stIn, stSize, stPos
    local resizeConn
    handle.InputBegan:Connect(function(input)
        if busy then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            busy = true; resizing = true
            stIn = input.Position; stSize = window.Size; stPos = window.Position
            if resizeConn then resizeConn:Disconnect(); resizeConn = nil end
            resizeConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
                    resizing = false; busy = false
                    if resizeConn then resizeConn:Disconnect(); resizeConn = nil end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - stIn
            local w = stSize.X.Offset; local h = stSize.Y.Offset
            local x = stPos.X.Offset; local y = stPos.Y.Offset
            if xd == 1 then w = math.max(320, stSize.X.Offset+delta.X) end
            if xd == -1 then w = math.max(320, stSize.X.Offset-delta.X); x = stPos.X.Offset+(stSize.X.Offset-w) end
            if yd == 1 then h = math.max(220, stSize.Y.Offset+delta.Y) end
            if yd == -1 then h = math.max(220, stSize.Y.Offset-delta.Y); y = stPos.Y.Offset+(stSize.Y.Offset-h) end
            window.Size = UDim2.new(0, w, 0, h); window.Position = UDim2.new(0, x, 0, y)
        end
    end)
end

local function MakeHandle(name, position, size, xd, yd)
    local handle = Instance.new("Frame")
    handle.Name = name; handle.BackgroundTransparency = 1
    handle.BorderSizePixel = 0; handle.Position = position
    handle.Size = size; handle.ZIndex = 5; handle.Active = true
    handle.Parent = window; BindResize(handle, xd, yd)
end

MakeHandle("ResizeRight", UDim2.new(1, -3, 0, 0), UDim2.new(0, 6, 1, 0), 1, 0)
MakeHandle("ResizeLeft", UDim2.new(0, -3, 0, 0), UDim2.new(0, 6, 1, 0), -1, 0)
MakeHandle("ResizeTop", UDim2.new(0, 0, 0, -3), UDim2.new(1, 0, 0, 6), 0, -1)
MakeHandle("ResizeBottom", UDim2.new(0, 0, 1, -3), UDim2.new(1, 0, 0, 6), 0, 1)
MakeHandle("ResizeTopLeft", UDim2.new(0, -5, 0, -5), UDim2.new(0, 10, 0, 10), -1, -1)
MakeHandle("ResizeTopRight", UDim2.new(1, -5, 0, -5), UDim2.new(0, 10, 0, 10), 1, -1)
MakeHandle("ResizeBottomLeft", UDim2.new(0, -5, 1, -5), UDim2.new(0, 10, 0, 10), -1, 1)
MakeHandle("ResizeBottomRight", UDim2.new(1, -5, 1, -5), UDim2.new(0, 10, 0, 10), 1, 1)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F12 then
        window.Visible = not window.Visible
    end
end)

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        local root = getRoot(char)
        if root then _G.devxLastDeath = root.CFrame end
    end)
end)

if player.Character then
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            local root = getRoot(player.Character)
            if root then _G.devxLastDeath = root.CFrame end
        end)
    end
end
