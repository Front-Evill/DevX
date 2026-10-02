local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local SocialService = game:GetService("SocialService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AnimState, EmoteState, CommandActions, Commands, targetCmds, targetCreated, playAnim, stopAnimAll
local camera = workspace.CurrentCamera

while not camera do
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	camera = workspace.CurrentCamera
end

local Colors = {
	white = Color3.fromRGB(255,255,255), gray30 = Color3.fromRGB(30,30,30), gray35 = Color3.fromRGB(35,35,35),
	gray90 = Color3.fromRGB(90,90,90), gray120 = Color3.fromRGB(120,120,120), gray150 = Color3.fromRGB(150,150,150),
	gray200 = Color3.fromRGB(200,200,200),
}

local Theme = { accent = Colors.white, outline = Colors.white, listeners = {} }

function Theme.bind(fn) table.insert(Theme.listeners, fn) end

function Theme.refresh()
	for _, fn in ipairs(Theme.listeners) do pcall(fn) end
end

function Theme.textOn(c)
	return (0.299 * c.R + 0.587 * c.G + 0.114 * c.B) > 0.6 and Color3.fromRGB(20,20,20) or Colors.white
end

function Theme.mark(btn, selected)
	btn.BackgroundColor3 = selected and Theme.accent or Colors.gray30
	btn.BackgroundTransparency = selected and 0.15 or 0.1
	btn.TextColor3 = selected and Theme.textOn(Theme.accent) or Colors.white
end

local Settings = {
	toggleKey = Enum.KeyCode.F12, sound = true, currentTab = "logs", oldLighting = {}, lastCmd = "",
	opts = {
		emoteStopMove = true, emoteStopJump = true, emoteSpeed = 1, emoteLoop = false,
		animKeep = true, cmdShortcuts = true, cmdFilter = true, logScroll = true, cmdResume = true,
	},
	resume = {},
	conns = {},
	ran = {},
	fav = { anims = {}, emotes = {}, counter = 0, file = "DevX/favorites.json", animBtns = {}, emoteBtns = {} },
	icons = {
		["FrontEvill-settings"] = "rbxassetid://10734950309",
		["FrontEvill-palette"] = "rbxassetid://10734910430",
		["FrontEvill-paintbrush"] = "rbxassetid://10734910187",
		["FrontEvill-pipette"] = "rbxassetid://10734922497",
		["FrontEvill-contrast"] = "rbxassetid://10709811939",
		["FrontEvill-scaling"] = "rbxassetid://10734942072",
		["FrontEvill-wand-2"] = "rbxassetid://10747376349",
		["FrontEvill-gauge"] = "rbxassetid://10723395708",
		["FrontEvill-refresh-cw"] = "rbxassetid://10734933222",
		["FrontEvill-sliders-horizontal"] = "rbxassetid://10734963191",
		["FrontEvill-keyboard"] = "rbxassetid://10723416765",
		["FrontEvill-volume-2"] = "rbxassetid://10747375679",
		["FrontEvill-person-standing"] = "rbxassetid://10734920149",
		["FrontEvill-plane"] = "rbxassetid://10734922971",
		["FrontEvill-rocket"] = "rbxassetid://10734934585",
		["FrontEvill-move-horizontal"] = "rbxassetid://10734899414",
		["FrontEvill-folder-open"] = "rbxassetid://10723386277",
		["FrontEvill-file-json"] = "rbxassetid://10723364435",
		["FrontEvill-save"] = "rbxassetid://10734941499",
		["FrontEvill-file-plus"] = "rbxassetid://10723365877",
		["FrontEvill-download"] = "rbxassetid://10723344270",
		["FrontEvill-edit-3"] = "rbxassetid://10723345088",
		["FrontEvill-trash-2"] = "rbxassetid://10747362241",
		["FrontEvill-rotate-ccw"] = "rbxassetid://10734940376",
		["FrontEvill-play-circle"] = "rbxassetid://10734923214",
		["FrontEvill-circle"] = "rbxassetid://10709798174",
		["FrontEvill-star"] = "rbxassetid://10734966248",
		["FrontEvill-party-popper"] = "rbxassetid://10734918735",
		["FrontEvill-terminal"] = "rbxassetid://10734982144",
		["FrontEvill-scroll"] = "rbxassetid://10734943448",
		["FrontEvill-arrow-up"] = "rbxassetid://10709768939",
		["FrontEvill-arrow-down"] = "rbxassetid://10709767827",
		["FrontEvill-repeat"] = "rbxassetid://10734933966",
		["FrontEvill-command"] = "rbxassetid://10709811365",
		["FrontEvill-search"] = "rbxassetid://10734943674",
	},
}

function Settings.link(conn)
	table.insert(Settings.conns, conn)
	return conn
end

function Settings.icon(name)
	return Settings.icons["FrontEvill-" .. name] or Settings.icons["FrontEvill-circle"]
end

local ESPenabled = false

local lineNum = 0
local dragging = false
local dragStart, startPos
local dragConn

local busy = false
local executeCommand
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

local DISCORD_LINK = "discord.gg/xPMwC2DTeg"
local PING_SOUND = "rbxasset://sounds/electronicpingshort.wav"

local function notify(title, text)
	if text == nil then title, text = nil, title end
	local body = tostring(text)
	local label = title ~= nil and tostring(title) or ""
	if label ~= "" and label:lower() ~= "devx" then
		body = label .. ": " .. body
	end
	local buf = getgenv().devxNoteBuf
	if buf and buf.thread == coroutine.running() then
		buf.body = body
		return
	end
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "DEVX", Text = body, Duration = 4 })
	end)
	if Settings.sound then
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = PING_SOUND
			s.Volume = 1
			s.Parent = SoundService
			s:Play()
			Debris:AddItem(s, 5)
		end)
	end
end

local function copy(str)
	return pcall(function() setclipboard(str) end)
end

pcall(function()
	if getgenv().devxUnload then getgenv().devxUnload() end
	local previous = playerGui:FindFirstChild("DevXConsole")
	if previous then previous:Destroy() end
end)

local screenGui   = Instance.new("ScreenGui")
local hotbar      = Instance.new("Frame")
local hotbarFix   = Instance.new("Frame")
local title       = Instance.new("TextButton")
local subtitle    = Instance.new("TextLabel")
local window      = Instance.new("Frame")
local content     = Instance.new("ScrollingFrame")
local listLayout  = Instance.new("UIListLayout", content)
local listPadding = Instance.new("UIPadding", content)

Instance.new("UICorner", window).CornerRadius  = UDim.new(0, 8)
Instance.new("UICorner", hotbar).CornerRadius  = UDim.new(0, 8)

screenGui.Name            = "DevXConsole"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.DisplayOrder    = 999
screenGui.Parent          = playerGui
screenGui.AutoLocalize    = false
screenGui.DescendantAdded:Connect(function(d)
	if d:IsA("GuiBase2d") then d.AutoLocalize = false end
end)

local vp = camera.ViewportSize

window.Name                 = "Window"
window.Size                 = UDim2.new(0, 520, 0, 360)
window.Position             = UDim2.new(0, vp.X/2-260, 0, vp.Y/2-180)
window.BackgroundColor3     = Color3.fromRGB(0,0,0)
window.BackgroundTransparency = 0.2
window.BorderSizePixel      = 0
window.ClipsDescendants     = true
window.Parent               = screenGui

hotbar.Name              = "Hotbar"
hotbar.Size              = UDim2.new(1,0,0,32)
hotbar.BackgroundColor3  = Color3.fromRGB(48,48,48)
hotbar.BorderSizePixel   = 0
hotbar.Active            = true
hotbar.Parent            = window

hotbarFix.Size            = UDim2.new(1,0,0,10)
hotbarFix.Position        = UDim2.new(0,0,1,-10)
hotbarFix.BackgroundColor3 = hotbar.BackgroundColor3
hotbarFix.BorderSizePixel = 0
hotbarFix.Parent          = hotbar

title.Name               = "Title"
title.AutoButtonColor    = false
title.BackgroundTransparency = 1
title.Position           = UDim2.new(0,10,0,0)
title.Size               = UDim2.new(0,50,1,0)
title.Font               = Enum.Font.GothamBold
title.Text               = "DevX"
title.TextSize           = 16
title.TextColor3         = Colors.white
title.TextXAlignment     = Enum.TextXAlignment.Left
title.ZIndex             = 3
title.Parent             = hotbar

subtitle.Name            = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position        = UDim2.new(0,80,0,2)
subtitle.Size            = UDim2.new(0,100,1,0)
subtitle.Font            = Enum.Font.Gotham
subtitle.Text            = "by frontevill"
subtitle.TextSize        = 11
subtitle.TextColor3      = Color3.fromRGB(140,140,140)
subtitle.TextXAlignment  = Enum.TextXAlignment.Left
subtitle.Parent          = hotbar

Settings.logo = Instance.new("ImageLabel")
Settings.logo.Name = "Logo"
Settings.logo.BackgroundTransparency = 1
Settings.logo.Position = UDim2.new(0,52,0,5)
Settings.logo.Size = UDim2.new(0,22,0,22)
Settings.logo.ScaleType = Enum.ScaleType.Fit
Settings.logo.Visible = false
Settings.logo.ZIndex = 3
Settings.logo.Parent = hotbar

task.spawn(function()
	local ids = {"90435766266035", "79794454808049"}
	local forms = {
		"rbxassetid://%s",
		"http://www.roblox.com/asset/?id=%s",
		"https://www.roblox.com/asset/?id=%s",
		"rbxthumb://type=Asset&id=%s&w=150&h=150",
	}
	local function try(url)
		Settings.logo.Image = url
		pcall(function() game:GetService("ContentProvider"):PreloadAsync({Settings.logo}) end)
		if Settings.logo.IsLoaded then
			Settings.logo.Visible = true
			return true
		end
		return false
	end
	for _, id in ipairs(ids) do
		local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		for _, obj in ipairs(ok and objects or {}) do
			if obj:IsA("Decal") or obj:IsA("Texture") then
				local texture = obj.Texture
				if texture ~= "" and try(texture) then return end
			end
		end
		for _, form in ipairs(forms) do
			if try(string.format(form, id)) then return end
		end
	end
	Settings.logo.Image = ""
	warn("DevX: the logo image could not be loaded")
end)

Settings.arts = {
	[==[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡄⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⢀⣄⠀⠀⠀⢀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⢀⣾⣿⣦⠀⠀⣾⣿⣧⡀⠀⠀⠀⠀⣰⣿⣿⡄⠀⢠⣿⣿⣆⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣠⣿⡀⠀⠀⠀⣾⣿⣿⣿⡆⢰⣿⣿⣿⣷⡀⠀⠀⣸⣿⣿⣿⣷⠀⣾⣿⣿⣿⣆⠀⠀⠀⣸⣷⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣰⣿⣿⣧⡀⠀⣸⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣷⠀⢰⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⣿⡀⠀⣰⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣾⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣷⡄⢸⣿⣿⣿⣿⣿⠇⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢻⣿⣿⣿⣿⣿⢀⣼⣧⠀⠀⠀
⣴⣶⣸⣿⣿⣾⣿⣿⣿⣿⣿⡄⢿⣿⣿⣿⣿⡇⢿⣿⣿⣿⣿⣿⠀⢹⣿⣿⣿⣿⣿⠏⢹⣿⣿⣿⣿⠇⢸⣿⣿⣿⣿⣿⣼⣿⣿⣰⣿⡄
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠈⢿⣿⣿⣿⠁⠈⠛⢿⣿⣿⠟⠀⠈⢿⣿⣿⠿⠋⠀⢸⣿⣿⣿⠋⣠⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣷
⣿⣿⡟⣿⣿⣯⣿⣿⣿⣿⣿⣿⡗⠀⠉⠙⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠀⠀⣿⣿⣿⣿⣿⣿⡇⣿⣿⡿⣿⣿⡿
⢻⣿⣧⢹⣿⣿⠸⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⢀⣿⣿⢃⣿⣿⠃
⠀⠻⣿⡆⠙⠿⡄⢻⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠃⠼⠟⢁⣼⡿⠋⠀
⠀⠀⠈⠉⠀⠀⠀⠀⢻⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣷⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣤⡶⢀⣠⢀⣾⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣷⡀⣀⠀⢦⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣾⣿⣡⣿⡇⣼⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣇⢹⣿⡜⣿⣧⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢸⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⠄⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⡀⠠⣿⣿⣿⣿⣿⣼⣿⣿⣿⣿⡇⠀⠀⠀⠀
⠀⠀⠀⠀⢸⣿⡿⣿⣿⣿⣿⣿⣿⣿⠃⣼⣿⣿⣷⢀⣴⣾⣿⣷⡀⢠⣾⣿⣷⣦⠀⣿⣿⣿⣦⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠛⠁⣿⡿⢹⣿⣿⣿⣿⢸⣿⣿⣿⣿⣾⣿⣿⣿⣿⡇⣼⣿⣿⣿⣿⣷⣿⣿⣿⣿⡇⣿⣿⣿⣿⡟⢿⣿⠉⠛⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠉⠀⢸⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡧⣿⣿⣿⣿⡇⠀⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⡿⠁⠘⣿⣿⣿⣿⢿⣿⣿⣿⣿⠃⠸⣿⣿⣿⣿⡿⣿⣿⣿⣿⠁⠙⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠁⠀⠀⢹⣿⣿⣿⠈⣿⣿⣿⠟⠀⠀⢻⣿⣿⣿⠀⣿⣿⣿⠇⠀⠀⠘⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡿⠁⠀⠸⡿⠋⠀⠀⠀⠀⠹⣿⠃⠀⠘⢿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]==],
	[==[
            .                                                      .         
        .n                   .                 .                  n.         
  .   .dP                  dP                   9b                 9b.    .  
 4    qXb         .       dX                     Xb       .        dXp     t 
dX.    9Xb      .dXb    __                         __    dXb.     dXP     .Xb
9XXb._       _.dXXXXb dXXXXbo.                 .odXXXXb dXXXXb._       _.dXXP
 9XXXXXXXXXXXXXXXXXXXVXXXXXXXXOo.           .oOXXXXXXXXVXXXXXXXXXXXXXXXXXXXP 
  `9XXXXXXXXXXXXXXXXXXXXX'~   ~`OOO8b   d8OOO'~   ~`XXXXXXXXXXXXXXXXXXXXXP'  
    `9XXXXXXXXXXXP' `9XX'          `98v8P'          `XXP' `9XXXXXXXXXXXP'    
        ~~~~~~~       9X.          .db|db.          .XP       ~~~~~~~        
                        )b.  .dbo.dP'`v'`9b.odb.  .dX(                       
                      ,dXXXXXXXXXXXb     dXXXXXXXXXXXb.                      
                     dXXXXXXXXXXXP'   .   `9XXXXXXXXXXXb                     
                    dXXXXXXXXXXXXb   d|b   dXXXXXXXXXXXXb                    
                    9XXb'   `XXXXXb.dX|Xb.dXXXXX'   `dXXP                    
                     `'      9XXXXXX(   )XXXXXXP      `'                     
                              XXXX X.`v'.X XXXX                              
                              XP^X'`b   d'`X^XX                              
                              X. 9  `   '  P )X                              
                              `b  `       '  d'                              
                               `             '                               ]==],
	[==[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀⢢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢘⡄⠀⠀⠀⠀⢃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⠀⠀⠀⠀⢨⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡸⠀⠀⠀⠀⠀⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⢁⠂⠀⠀⠀⠀⠀⢠⣆⠀⠀⠀⠀⠀⢀⠔⠉⠠⠉⠰⡘⢠⠍⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⣰⠎⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠎⠀⠀⠀⠁⠀⢯⢄⠴⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠺⠆⠈⠃⣮⡁⠀⠀⠀⢀⡞⢀⠀⠀⠀⠀⠀⠯⠇⠀⡀⠀⠀⠀⠸⡧⢛⠩⠑⡀⢠⣸⠀⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠟⠀⣸⡷⠀⠀⠀⡼⠀⠀⢡⠀⠀⣤⣤⠀⠀⠨⣿⠆⠀⠀⠀⠑⠤⠤⠜⠁⢰⠃⠐⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠘⣗⠀⠀⠠⡇⠀⠀⢸⠀⣠⠌⠉⠀⠀⠀⠀⠀⠀⠾⠀⠀⠀⠀⠀⡂⡞⠄⡸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⠋⠀⠶⡀⠀⠀⠀⠀⢻⡄⠀⠀⢗⡀⠀⣸⠀⠰⡲⠀⠿⠀⠀⠀⣴⡵⠀⠀⠀⠀⠀⢐⡜⡀⣁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠸⠆⠠⣶⠀⠠⠶⠠⣦⠈⢳⣠⠀⠈⣆⠀⡯⠀⠀⣦⠀⡈⢀⣤⡄⠀⠀⠀⠀⠀⠀⢠⠞⠊⠀⠀⠈⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡆⠀⠀⢀⣤⡀⢖⡄⠀⠀⠀⠀⠹⣆⡀⠙⡂⢰⡀⠀⠀⣠⣷⣆⠉⠐⠀⠻⠗⠀⠀⡰⠋⢀⡔⠀⢲⡀⠀⣏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠐⢷⣀⠀⠈⠋⠀⣀⠀⠀⠀⠀⣁⡐⢈⡳⡂⠹⡄⢧⢂⣸⠹⢋⢠⢣⢳⣠⠀⠀⣡⠎⠀⠀⠘⣧⢒⠘⢀⡠⠋⢀⡀⣀⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠘⣿⢦⡀⠀⠀⠘⠁⠀⠠⢸⣿⡍⠻⠒⢿⣦⠹⡄⢻⡟⠀⠘⡀⠘⣠⡣⣠⠞⠁⠀⠀⠀⠀⢈⠈⢉⠁⠀⠀⠈⢁⠙⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⠶⡼⣕⠲⠦⢤⣀⣀⠘⢿⡵⡂⠀⠀⠉⠑⢎⣿⠁⠀⠀⠀⡆⣿⢾⡫⠠⣀⣤⡴⠿⢛⠿⡿⣿⠆⠀⣀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢶⣬⡳⣲⠢⣍⢳⡀⣷⠁⠀⡀⠀⠀⠄⢿⡀⠀⠀⠠⠁⣿⢽⣴⠿⠛⠁⠀⠈⠀⣰⡷⢁⠔⡪⠂⠐⢀⣨⠖⠂⠉⠉⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠍⠉⢛⠳⢔⣧⠘⣧⠀⢄⠀⡀⠀⠚⡷⠁⠀⠀⣰⣿⠏⠑⠠⠀⠀⠀⠠⣪⢟⣴⣗⣁⠦⠴⠛⣉⢀⡀⢤⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⡠⢴⡲⣞⢲⣒⡲⢤⡤⢬⢆⡙⠷⡌⠳⣄⠂⠀⠀⠂⠶⡄⢠⣆⡿⠁⠀⠀⠀⢠⠔⠈⡡⢃⠊⠔⠀⠁⠐⠊⠽⣂⠉⠈⠑⠨⡺⡄⡀⠀
⠀⠀⠀⠀⠀⢠⠜⣃⣨⡧⡽⠞⠙⠓⠚⠑⠘⠚⠓⠤⡵⢠⣛⡲⣦⡀⢤⡔⣷⡜⣿⣡⡀⠐⠀⢀⢨⣠⣖⣑⠚⠶⢶⡶⢖⡤⠤⣄⠉⠐⠂⠐⠂⠓⠳⣅⠀
⠀⠀⠀⠀⣠⣿⠲⠋⠁⠀⢀⡤⣲⠲⠆⢶⠻⠖⢚⡴⠞⠉⠈⠀⠍⠻⣛⢯⣽⣻⡣⠯⠴⣶⠍⠉⠉⠀⠊⠉⠉⢟⣶⣌⡳⣬⡛⣦⠝⡄⠀⠀⠀⠀⠀⠀⠑
⢀⣀⠤⠞⠋⠁⠀⠀⢀⠔⠃⡡⠴⣱⠖⠉⠠⣰⣏⡤⠊⡀⠚⢁⠀⠐⣴⢯⣭⣾⢮⢮⡹⢶⠆⠀⠐⢀⠀⠈⠀⢢⣘⡹⣿⣿⡝⢶⣽⢻⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡠⠋⣤⣪⡴⠋⠁⠀⠠⣺⣿⠝⣀⢀⡠⢉⣀⣠⣦⣴⠿⢻⠃⠡⠁⢌⠢⡂⠴⢄⠠⠤⠄⠴⠦⣔⣺⣿⣯⡙⠆⢻⣾⠀⠀⠀⢠⠀⠀⠀
⠀⠀⠀⠀⣀⣴⣿⡿⠞⠋⠁⠀⠀⠐⠑⠀⣿⣯⣴⢾⢿⣿⢿⣿⣿⢿⠏⠠⠁⡐⠀⡀⠰⠌⢷⣦⣶⡧⣤⡶⠚⢛⢛⠋⢩⢲⠀⠀⢸⡇⠀⠀⣀⡀⠃⠀⠀
⠀⠈⠉⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⢨⡴⢇⣧⡁⠒⠛⠹⣹⡿⢋⢿⣾⡇⣘⡀⠄⠀⠄⠁⡚⠼⢟⠮⣿⡹⢺⣧⣛⢊⢁⣀⠁⠸⠛⠜⣀⠀⢀⡉⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⡏⠘⢇⢸⠏⠀⣬⡾⣿⣹⢛⣦⣾⢿⣌⢇⡘⠄⠘⡀⣷⣿⣃⠀⠈⠳⣏⣀⠙⡲⣌⠋⠉⣎⠆⠀⣉⡴⠊⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠙⠃⠀⠞⠂⠀⠀⢻⣆⣀⣀⡠⣾⡟⠀⡀⠿⢦⡙⢫⢼⢟⣾⣶⢣⣰⢿⣾⠟⠈⠹⢦⡀⠙⣮⢥⠀⠨⡳⣜⠁⡖⢆⠲⠃⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠠⣾⡇⠀⠀⠀⠀⠈⠉⠉⣸⡟⢀⢙⠋⠀⢈⣁⡘⠛⠐⠹⣻⣿⢿⣿⠏⠀⠀⠀⠠⢿⡀⢈⢧⠓⠀⠘⠝⣷⣌⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⡀⣿⠁⡀⠀⠀⠀⠈⠋⠂⠀⠀⠀⠁⠙⠹⠘⠀⠀⠀⠀⠀⠙⡇⠀⢹⣧⠀⠀⠈⢌⣿⡆⢃⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣌⡁⣷⠉⠤⠤⢠⡴⠶⣶⣤⠀⠀⠀⠀⠀⠀⠀⠀⢲⠆⣤⡟⠀⡇⠀⢈⢻⡄⠀⠀⠀⢻⣷⡜⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣷⢻⡀⠀⠢⢺⣩⡇⠀⢹⡆⠀⠀⠀⠀⠀⠀⠀⠐⢆⡉⠡⠞⠀⠀⠘⣸⡇⠀⠀⠀⠀⣿⣱⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⡼⠳⣤⣀⠄⣂⣀⡤⠚⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⢰⣿⡇⠆⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠁⢏⠨⣯⠉⠹⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠁⠀⠀⠀⢸⣿⠄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣾⠋⠀⠀⠀⠀⣾⡿⠌⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠇⠀⠀⠀⠀⠀⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠖⠉⠀⠀⠀⠀⠀⢀⣾⣿⠂⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⢤⣾⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢤⣤⣶⡿⠞⠟⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]==],
}

Settings.art = Instance.new("TextLabel")
Settings.art.Name = "Backdrop"
Settings.art.BackgroundTransparency = 1
Settings.art.AnchorPoint = Vector2.new(0.5,0.5)
Settings.art.Position = UDim2.new(0.5,0,0.5,16)
Settings.art.Size = UDim2.new(0.72,0,0.86,0)
Settings.art.Font = Enum.Font.Code
Settings.art.TextScaled = true
Settings.art.TextWrapped = false
Settings.art.TextColor3 = Theme.accent
Settings.art.TextTransparency = 0.7
Settings.art.TextXAlignment = Enum.TextXAlignment.Center
Settings.art.TextYAlignment = Enum.TextYAlignment.Center
Settings.art.Text = Settings.arts[Random.new():NextInteger(1, #Settings.arts)]
Settings.art.ZIndex = 0
Settings.art.Parent = window

local discordBtn = Instance.new("ImageButton")
discordBtn.Name              = "Discord"
discordBtn.BackgroundTransparency = 1
discordBtn.Position          = UDim2.new(1,-26,0,8)
discordBtn.Size              = UDim2.new(0,16,0,16)
discordBtn.Image             = "rbxassetid://10734888000"
discordBtn.ImageColor3       = Colors.white
discordBtn.ZIndex            = 3
discordBtn.Parent            = hotbar

local SIDE_W = 90
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.new(0,0,0,32)
sidebar.Size = UDim2.new(0,SIDE_W,1,-32)
sidebar.BackgroundColor3 = Color3.fromRGB(20,20,20)
sidebar.BackgroundTransparency = 0.15
sidebar.BorderSizePixel = 0
sidebar.Parent = window

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

function sideTab(icon, label, order)
	local btn = Instance.new("TextButton")
	btn.Name = "Row_" .. label
	btn.LayoutOrder = order
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.new(1,0,0,40)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 3
	btn.Parent = sidebar

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.BackgroundTransparency = 1
	iconLabel.Position = UDim2.new(0,14,0,0)
	iconLabel.Size = UDim2.new(0,20,1,0)
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 15
	iconLabel.TextColor3 = Colors.gray120
	iconLabel.Text = icon
	iconLabel.ZIndex = 3
	iconLabel.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0,40,0,0)
	nameLabel.Size = UDim2.new(1,-48,1,0)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Colors.gray120
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = label
	nameLabel.ZIndex = 3
	nameLabel.Parent = btn

	local underline = Instance.new("Frame")
	underline.Name = "Underline"
	underline.BackgroundColor3 = Theme.accent
	underline.BorderSizePixel = 0
	underline.Position = UDim2.new(0,10,1,-2)
	underline.Size = UDim2.new(1,-20,0,2)
	underline.Visible = false
	underline.ZIndex = 4
	underline.Parent = btn

	return btn, underline
end

local tabLogs, tabLogsUnderline = sideTab("L", "Logs", 1)
local tabCmds, tabCmdsUnderline = sideTab("C", "Cmds", 2)

Settings.tab = Instance.new("ImageButton")
Settings.tab.Name = "TabSettings"
Settings.tab.BackgroundTransparency = 1
Settings.tab.Position = UDim2.new(1,-50,0,8)
Settings.tab.Size = UDim2.new(0,16,0,16)
Settings.tab.Image = Settings.icon("settings")
Settings.tab.ImageColor3 = Colors.gray200
Settings.tab.ZIndex = 3
Settings.tab.Parent = hotbar

Settings.tabUnderline = Instance.new("Frame")
Settings.tabUnderline.BackgroundColor3 = Theme.accent
Settings.tabUnderline.BorderSizePixel = 0
Settings.tabUnderline.Position = UDim2.new(1,-52,1,-2)
Settings.tabUnderline.Size = UDim2.new(0,20,0,2)
Settings.tabUnderline.ZIndex = 4
Settings.tabUnderline.Visible = false
Settings.tabUnderline.Parent = hotbar

content.Name                  = "Content"
content.Position              = UDim2.new(0,SIDE_W,0,32)
content.Size                  = UDim2.new(1,-SIDE_W,1,-32)
content.BackgroundTransparency = 1
content.BorderSizePixel       = 0
content.ClipsDescendants      = true
content.ScrollBarThickness    = 4
content.ScrollBarImageColor3  = Colors.gray90
content.CanvasSize            = UDim2.new(0,0,0,0)
content.AutomaticCanvasSize   = Enum.AutomaticSize.Y
content.Parent                = window

listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0,4)
listPadding.PaddingTop    = UDim.new(0,6)
listPadding.PaddingLeft   = UDim.new(0,8)
listPadding.PaddingRight  = UDim.new(0,8)
listPadding.PaddingBottom = UDim.new(0,6)

local commandsPanel = Instance.new("Frame")
commandsPanel.Name               = "CommandsPanel"
commandsPanel.Position           = UDim2.new(0,SIDE_W,0,32)
commandsPanel.Size               = UDim2.new(1,-SIDE_W,1,-32)
commandsPanel.BackgroundTransparency = 1
commandsPanel.BorderSizePixel    = 0
commandsPanel.Visible            = false
commandsPanel.Parent             = window

local Outline = { list = {}, conn = nil, animate = true }

function Outline.refresh()
	for _, e in ipairs(Outline.list) do
		e.stroke.Color = Theme.outline
		e.grad.Enabled = Outline.animate
		e.stroke.Transparency = Outline.animate and 0 or 0.55
	end
end

function Outline.add(btn, owner)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "DevXOutline"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Theme.outline
	stroke.Thickness = 1.5
	stroke.Parent = btn

	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.35, 0.75),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.65, 0.75),
		NumberSequenceKeypoint.new(1, 0.75),
	})
	grad.Parent = stroke

	table.insert(Outline.list, {grad = grad, owner = owner, stroke = stroke})
	grad.Enabled = Outline.animate
	stroke.Transparency = Outline.animate and 0 or 0.55

	btn.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), {Thickness = 2.5}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
	end)

	if not Outline.conn then
		Outline.conn = RunService.Heartbeat:Connect(function()
			if not window.Visible or not Outline.animate then return end
			local rot = (tick() * 140) % 360
			Outline.frames = (Outline.frames or 0) + 1
			if Outline.frames % 180 == 0 then
				for i = #Outline.list, 1, -1 do
					if not Outline.list[i].grad:IsDescendantOf(window) then table.remove(Outline.list, i) end
				end
			end
			for _, e in ipairs(Outline.list) do
				if e.owner.Visible then e.grad.Rotation = rot end
			end
		end)
	end
end

local commandsList = Instance.new("ScrollingFrame")
commandsList.Name                = "CommandsList"
commandsList.Position            = UDim2.new(0,0,0,6)
commandsList.Size                = UDim2.new(1,0,1,-40)
commandsList.BackgroundTransparency = 1
commandsList.BorderSizePixel     = 0
commandsList.ClipsDescendants    = true
commandsList.ScrollBarThickness  = 4
commandsList.ScrollBarImageColor3 = Colors.gray90
commandsList.CanvasSize          = UDim2.new(0,0,0,0)
commandsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
commandsList.Parent              = commandsPanel

local commandsListLayout = Instance.new("UIListLayout", commandsList)
commandsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
commandsListLayout.Padding   = UDim.new(0,4)

local commandsListPadding = Instance.new("UIPadding", commandsList)
commandsListPadding.PaddingTop    = UDim.new(0,6)
commandsListPadding.PaddingLeft   = UDim.new(0,6)
commandsListPadding.PaddingRight  = UDim.new(0,6)
commandsListPadding.PaddingBottom = UDim.new(0,6)

local inputRow = Instance.new("Frame")
inputRow.Name                = "InputRow"
inputRow.Position            = UDim2.new(0,0,1,-34)
inputRow.Size                = UDim2.new(1,0,0,34)
inputRow.BackgroundTransparency = 1
inputRow.BorderSizePixel     = 0
inputRow.Parent              = commandsPanel

local commandPrompt = Instance.new("TextLabel")
commandPrompt.Name           = "Prompt"
commandPrompt.BackgroundTransparency = 1
commandPrompt.Position       = UDim2.new(0,10,0,8)
commandPrompt.Size           = UDim2.new(0,26,0,18)
commandPrompt.Font           = Enum.Font.Code
commandPrompt.TextSize       = 14
commandPrompt.TextColor3     = Theme.accent
commandPrompt.TextXAlignment = Enum.TextXAlignment.Left
commandPrompt.Text           = ">>>"
commandPrompt.Parent         = inputRow

local commandInput = Instance.new("TextBox")
commandInput.Name            = "CommandInput"
commandInput.Position        = UDim2.new(0,38,0,6)
commandInput.Size            = UDim2.new(1,-76,0,22)
commandInput.BackgroundTransparency = 1
commandInput.ClearTextOnFocus = false
commandInput.Font            = Enum.Font.Code
commandInput.TextSize        = 14
commandInput.TextColor3      = Colors.white
commandInput.PlaceholderText = "Input your command"
commandInput.PlaceholderColor3 = Colors.gray120
commandInput.Text            = ""
commandInput.TextXAlignment  = Enum.TextXAlignment.Left
commandInput.Parent          = inputRow

local sendBtn = Instance.new("ImageButton")
sendBtn.Name            = "Send"
sendBtn.Size            = UDim2.new(0,18,0,18)
sendBtn.Position        = UDim2.new(1,-28,0,8)
sendBtn.BackgroundTransparency = 1
sendBtn.Image           = "rbxassetid://10734943902"
sendBtn.ImageColor3     = Theme.accent
sendBtn.Parent          = inputRow

local function AddCommandEntry(cmd)
	local entry = Instance.new("Frame")
	entry.Name              = cmd.Name
	entry.BackgroundTransparency = 1
	entry.Size              = UDim2.new(1,0,0,0)
	entry.AutomaticSize     = Enum.AutomaticSize.Y
	entry.Parent            = commandsList

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name          = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size          = UDim2.new(1,0,0,16)
	nameLabel.Font          = Enum.Font.GothamBold
	nameLabel.TextSize      = 13
	nameLabel.TextColor3    = Theme.accent
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text          = cmd.Name
	nameLabel.Parent        = entry

	local descLabel = Instance.new("TextLabel")
	descLabel.Name          = "Description"
	descLabel.BackgroundTransparency = 1
	descLabel.Position      = UDim2.new(0,0,0,16)
	descLabel.Size          = UDim2.new(1,0,0,0)
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.Font          = Enum.Font.Gotham
	descLabel.TextSize      = 11
	descLabel.TextColor3    = Colors.gray150
	descLabel.TextWrapped   = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Text          = cmd.Description
	descLabel.Parent        = entry
	return entry
end

local CmdSearch = { entries = {}, aliases = {} }

CmdSearch.empty = Instance.new("TextLabel")
CmdSearch.empty.Name = "NoResults"
CmdSearch.empty.BackgroundTransparency = 1
CmdSearch.empty.Size = UDim2.new(1,0,0,24)
CmdSearch.empty.LayoutOrder = 1000000
CmdSearch.empty.Font = Enum.Font.Gotham
CmdSearch.empty.TextSize = 12
CmdSearch.empty.TextColor3 = Colors.gray150
CmdSearch.empty.Text = "No matching commands"
CmdSearch.empty.Visible = false
CmdSearch.empty.Parent = commandsList

function CmdSearch.filter()
	local q = ""
	if Settings.opts.cmdFilter then q = (commandInput.Text:match("^%s*(%S*)") or ""):lower() end
	local shown = 0
	for _, e in ipairs(CmdSearch.entries) do
		if q == "" then
			e.frame.Visible = true
			e.frame.LayoutOrder = e.index
			shown += 1
		elseif e.base:sub(1, #q) == q then
			e.frame.Visible = true
			e.frame.LayoutOrder = (e.base == q) and (e.index - 1000000) or (#e.base * 1000 + e.index)
			shown += 1
		else
			e.frame.Visible = false
		end
	end
	CmdSearch.empty.Visible = shown == 0
	commandsList.CanvasPosition = Vector2.new(0, 0)
end

commandInput:GetPropertyChangedSignal("Text"):Connect(CmdSearch.filter)

local function pushEntry(kind, message)
	lineNum += 1
	local entryIcon, entryColor
	if kind == "Print" then
		entryIcon = "rbxassetid://10723367380"; entryColor = Colors.white
	elseif kind == "Warn" then
		entryIcon = "rbxassetid://10709753149"; entryColor = Color3.fromRGB(255,214,0)
	elseif kind == "Error" then
		entryIcon = "rbxassetid://10709753064"; entryColor = Color3.fromRGB(255,70,70)
	end

	local row = Instance.new("Frame")
	row.Name              = "Entry"
	row.BackgroundTransparency = 1
	row.Size              = UDim2.new(1,0,0,0)
	row.AutomaticSize     = Enum.AutomaticSize.Y
	row.LayoutOrder       = lineNum
	row.Parent            = content

	local lineLabel = Instance.new("TextLabel")
	lineLabel.BackgroundTransparency = 1
	lineLabel.Position    = UDim2.new(0,0,0,2)
	lineLabel.Size        = UDim2.new(0,24,0,16)
	lineLabel.Font        = Enum.Font.Code
	lineLabel.TextSize    = 13
	lineLabel.TextColor3  = Colors.gray150
	lineLabel.TextXAlignment = Enum.TextXAlignment.Left
	lineLabel.Text        = tostring(lineNum)
	lineLabel.Parent      = row

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Position         = UDim2.new(0,26,0,1)
	icon.Size             = UDim2.new(0,16,0,16)
	icon.Image            = entryIcon
	icon.ImageColor3      = entryColor
	icon.Parent           = row

	local dash = Instance.new("TextLabel")
	dash.BackgroundTransparency = 1
	dash.Position         = UDim2.new(0,46,0,2)
	dash.Size             = UDim2.new(0,18,0,16)
	dash.Font             = Enum.Font.Code
	dash.TextSize         = 13
	dash.TextColor3       = entryColor
	dash.TextXAlignment   = Enum.TextXAlignment.Left
	dash.Text             = "--"
	dash.Parent           = row

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position         = UDim2.new(0,68,0,0)
	text.Size             = UDim2.new(1,-94,0,0)
	text.AutomaticSize    = Enum.AutomaticSize.Y
	text.Font             = Enum.Font.Code
	text.TextSize         = 14
	text.TextColor3       = entryColor
	text.TextWrapped      = true
	text.TextXAlignment   = Enum.TextXAlignment.Left
	text.TextYAlignment   = Enum.TextYAlignment.Top
	text.Text             = message
	text.Parent           = row

	local copyBtn = Instance.new("ImageButton")
	copyBtn.Size          = UDim2.new(0,16,0,16)
	copyBtn.Position      = UDim2.new(1,-18,0,2)
	copyBtn.BackgroundTransparency = 1
	copyBtn.Image         = "rbxassetid://10709812159"
	copyBtn.ImageColor3   = Color3.fromRGB(170,170,170)
	copyBtn.Parent        = row

	copyBtn.MouseButton1Click:Connect(function()
		if copy(message) then
			copyBtn.ImageColor3 = Theme.accent
			task.delay(0.4, function() copyBtn.ImageColor3 = Color3.fromRGB(170,170,170) end)
		end
	end)

	table.insert(entries, row)
	if #entries > 300 then
		table.remove(entries, 1):Destroy()
	end
	task.defer(function()
		task.defer(function()
			if Settings.opts.logScroll then
				content.CanvasPosition = Vector2.new(0, math.max(0, content.AbsoluteCanvasSize.Y - content.AbsoluteSize.Y))
			end
		end)
	end)
end

Settings.esp = { items = {}, conns = {}, color = Color3.fromRGB(255,60,60), team = false, transparency = 0.5 }

function Settings.esp.colorFor(plr)
	if Settings.esp.team then
		return plr.Team == player.Team and Color3.fromRGB(80,220,120) or Color3.fromRGB(255,60,60)
	end
	return Settings.esp.color
end

function Settings.esp.clear(plr)
	local item = Settings.esp.items[plr]
	if not item then return end
	Settings.esp.items[plr] = nil
	item.highlight:Destroy()
	item.gui:Destroy()
end

function Settings.esp.build(plr)
	local char = plr.Character
	if not char or plr == player then return end
	local head = char:WaitForChild("Head", 5)
	if not head or not ESPenabled or plr.Character ~= char then return end
	Settings.esp.clear(plr)
	local color = Settings.esp.colorFor(plr)

	local highlight = Instance.new("Highlight")
	highlight.Name = "DevXEsp"
	highlight.Adornee = char
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = Settings.esp.transparency
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	local gui = Instance.new("BillboardGui")
	gui.Name = "DevXEspTag"
	gui.Adornee = head
	gui.AlwaysOnTop = true
	gui.Size = UDim2.new(0,160,0,20)
	gui.StudsOffset = Vector3.new(0,2.5,0)
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1,0,1,0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.AutoLocalize = false
	label.Text = plr.Name
	label.Parent = gui

	Settings.esp.items[plr] = { highlight = highlight, gui = gui, label = label }
end

function Settings.esp.watch(plr)
	if plr == player then return end
	local old = Settings.esp.conns[plr]
	if old then old:Disconnect() end
	Settings.esp.conns[plr] = plr.CharacterAdded:Connect(function()
		task.spawn(Settings.esp.build, plr)
	end)
	if plr.Character then task.spawn(Settings.esp.build, plr) end
end

function Settings.esp.enable(team)
	ESPenabled = true
	Settings.esp.team = team
	for _, plr in ipairs(Players:GetPlayers()) do Settings.esp.watch(plr) end
	if Settings.esp.added then return end
	Settings.esp.added = Players.PlayerAdded:Connect(Settings.esp.watch)
	Settings.esp.removed = Players.PlayerRemoving:Connect(function(plr)
		Settings.esp.clear(plr)
		local conn = Settings.esp.conns[plr]
		if conn then
			conn:Disconnect()
			Settings.esp.conns[plr] = nil
		end
	end)
	local acc = 0
	Settings.esp.loop = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then return end
		acc = 0
		local mine = getRoot(player.Character)
		if not mine then return end
		for plr, item in pairs(Settings.esp.items) do
			local root = plr.Character and getRoot(plr.Character)
			if root then
				item.label.Text = plr.Name.." | "..math.floor((mine.Position - root.Position).Magnitude).."st"
			end
		end
	end)
end

function Settings.esp.disable()
	ESPenabled = false
	for plr in pairs(Settings.esp.items) do Settings.esp.clear(plr) end
	for plr, conn in pairs(Settings.esp.conns) do
		conn:Disconnect()
		Settings.esp.conns[plr] = nil
	end
	for _, key in ipairs({"added", "removed", "loop"}) do
		if Settings.esp[key] then
			Settings.esp[key]:Disconnect()
			Settings.esp[key] = nil
		end
	end
end

Settings.oldLighting = {
	Ambient = Lighting.Ambient, Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows
}

local function findCommandAction(name)
	for cmdName, action in pairs(CommandActions) do
		if cmdName:lower() == name:lower() then
			return action
		end
	end
	return nil
end

function CmdSearch.resolve(word)
	local q = word:lower()
	local runnable = {}
	for cmdName in pairs(CommandActions) do runnable[cmdName:lower()] = true end
	if runnable[q] then return q, false end
	if not Settings.opts.cmdShortcuts then return nil, false end
	local best, seen, count = nil, {}, 0
	for _, e in ipairs(CmdSearch.entries) do
		if runnable[e.base] and e.base:sub(1, #q) == q and not seen[e.base] then
			seen[e.base] = true
			count += 1
			if not best or #e.base < #best then best = e.base end
		end
	end
	return best, count > 1
end

function executeCommand()
	local raw = commandInput.Text:match("^%s*(.-)%s*$")
	if raw == "" then return end
	local parts = {}
	for w in raw:gmatch("%S+") do table.insert(parts, w) end
	local name = parts[1]
	table.remove(parts, 1)

	local aliased = CmdSearch.aliases[name:lower()]
	if aliased then name = aliased end
	local resolved, ambiguous = CmdSearch.resolve(name)
	if resolved and resolved ~= name:lower() then
		if ambiguous then notify("Shortcut", name:lower().." -> "..resolved) end
		name = resolved
	end

	if name:lower() ~= "lastcommand" and raw ~= "" then
		Settings.lastCmd = raw
	end

	if targetCmds[name:lower()] then
		if #parts == 0 or (parts[1] and Players:FindFirstChild(parts[1]) == nil and (not Players:FindFirstChild(parts[1])) ) then
			if Settings.target and Settings.target ~= player then
				local nameArg = Settings.target.Name
				if name:lower() == "whisper" then
					table.insert(parts, 1, nameArg)
				elseif #parts == 0 then
					table.insert(parts, 1, nameArg)
				else
					local firstIsPlayer = false
					for _,p in pairs(Players:GetPlayers()) do
						if p.Name:lower():sub(1,#parts[1]) == parts[1]:lower() then
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
		local prevBuf = getgenv().devxNoteBuf
		local buf = { thread = coroutine.running() }
		getgenv().devxNoteBuf = buf
		local ok, err = pcall(action, parts)
		getgenv().devxNoteBuf = prevBuf
		if buf.body then notify("DevX", buf.body) end
		if not ok then notify("Error", tostring(err)) else Settings.forget(name:lower()); Settings.ran[name:lower()] = true end
	else
		notify("Unknown Command", name)
	end
	commandInput.Text = ""
end

sendBtn.MouseButton1Click:Connect(executeCommand)
commandInput.FocusLost:Connect(function(enter) if enter then executeCommand() end end)

discordBtn.MouseButton1Click:Connect(function()
	if copy(DISCORD_LINK) then
		notify("DevX","Link copied")
	end
end)

Settings.order = 0
Settings.refreshers = {}
Settings.fileButtons = {}
Settings.dir = "DevX/Configs"
Settings.autoFile = "DevX/autoload.txt"
Settings.presets = {
	Colors.white, Color3.fromRGB(170,170,170), Color3.fromRGB(90,220,120),
	Color3.fromRGB(80,200,255), Color3.fromRGB(90,130,255), Color3.fromRGB(170,110,255),
	Color3.fromRGB(255,110,190), Color3.fromRGB(255,85,85), Color3.fromRGB(255,165,60),
	Color3.fromRGB(255,225,90),
}
Settings.defaults = {
	accent = Colors.white, outline = Colors.white,
	transparency = 0.2, scale = 1, outlineAnim = true, toggleKey = "F12", sound = true,
	emoteStopMove = true, emoteStopJump = true, emoteSpeed = 1, emoteLoop = false,
	animKeep = true, cmdShortcuts = true, cmdFilter = true, logScroll = true, cmdResume = true,
}

function Settings.rgb(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

function Settings.toColor(t, default)
	if type(t) == "table" then
		local r, g, b = tonumber(t[1]), tonumber(t[2]), tonumber(t[3])
		if r and g and b then
			return Color3.fromRGB(math.clamp(math.floor(r), 0, 255), math.clamp(math.floor(g), 0, 255), math.clamp(math.floor(b), 0, 255))
		end
	end
	return default
end

function Settings.hex(c)
	local v = Settings.rgb(c)
	return string.format("#%02X%02X%02X", v[1], v[2], v[3])
end

function Settings.parseColor(text)
	local s = tostring(text):gsub("[%s#]", "")
	local hex = s:match("^(%x%x%x%x%x%x)$")
	if hex then
		return Color3.fromRGB(tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16))
	end
	local r, g, b = s:match("^(%d+),(%d+),(%d+)$")
	if r then
		return Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
	end
	return nil
end

function Settings.fmt(v)
	return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

function Settings.fsOk()
	return (writefile and readfile and listfiles and isfile and makefolder and isfolder) ~= nil
end

function Settings.ensureDirs()
	pcall(function()
		if not isfolder("DevX") then makefolder("DevX") end
		if not isfolder(Settings.dir) then makefolder(Settings.dir) end
	end)
end

function Settings.path(name)
	return Settings.dir .. "/" .. name .. ".json"
end

function Settings.clean(name)
	local s = tostring(name or ""):gsub("[^%w%s_%-%.]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return s:sub(1, 32)
end

function Settings.listFiles()
	local names = {}
	if not Settings.fsOk() then return names end
	Settings.ensureDirs()
	local ok, files = pcall(listfiles, Settings.dir)
	if ok and type(files) == "table" then
		for _, p in ipairs(files) do
			local n = tostring(p):match("([^/\\]+)%.json$")
			if n then table.insert(names, n) end
		end
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	return names
end

function Settings.nameTaken(name)
	for _, n in ipairs(Settings.listFiles()) do
		if n:lower() == name:lower() then return true end
	end
	return false
end

function Settings.readFile(name)
	local ok, content = pcall(readfile, Settings.path(name))
	if not ok then return nil end
	local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
	if ok2 and type(data) == "table" then return data end
	return nil
end

function Settings.writeFile(name, data)
	Settings.ensureDirs()
	local ok = pcall(function()
		writefile(Settings.path(name), HttpService:JSONEncode(data))
	end)
	return ok
end

function Settings.autoloadName()
	if not (isfile and readfile) then return nil end
	local ok, exists = pcall(isfile, Settings.autoFile)
	if ok and exists then
		local ok2, content = pcall(readfile, Settings.autoFile)
		if ok2 and content ~= "" then return (content:gsub("%s+$", "")) end
	end
	return nil
end

function Settings.setAutoload(name)
	Settings.ensureDirs()
	pcall(function() writefile(Settings.autoFile, name or "") end)
end

function Settings.collect()
	local O = Settings.opts
	return {
		version = 2,
		accent = Settings.rgb(Theme.accent), outline = Settings.rgb(Theme.outline),
		transparency = window.BackgroundTransparency, scale = Settings.scale.Scale,
		outlineAnim = Outline.animate, toggleKey = Settings.toggleKey.Name, sound = Settings.sound,
		emoteStopMove = O.emoteStopMove, emoteStopJump = O.emoteStopJump,
		emoteSpeed = O.emoteSpeed, emoteLoop = O.emoteLoop,
		animKeep = O.animKeep, cmdShortcuts = O.cmdShortcuts, cmdFilter = O.cmdFilter, logScroll = O.logScroll, cmdResume = O.cmdResume,
		aliases = CmdSearch.aliases,
		animation = AnimState and AnimState.saved and { name = AnimState.savedName, map = AnimState.saved } or nil,
	}
end

function Settings.apply(d)
	local D, O = Settings.defaults, Settings.opts
	local function pick(v, default) if v == nil then return default end return v end

	Theme.accent = Settings.toColor(d.accent, D.accent)
	Theme.outline = Settings.toColor(d.outline, D.outline)
	window.BackgroundTransparency = math.clamp(tonumber(d.transparency) or D.transparency, 0, 0.95)
	Settings.scale.Scale = math.clamp(tonumber(d.scale) or D.scale, 0.6, 2)
	Outline.animate = pick(d.outlineAnim, D.outlineAnim) == true
	local okKey, key = pcall(function() return Enum.KeyCode[d.toggleKey or D.toggleKey] end)
	Settings.toggleKey = (okKey and key) or Enum.KeyCode.F12
	Settings.sound = pick(d.sound, D.sound) == true

	O.emoteStopMove = pick(d.emoteStopMove, D.emoteStopMove) == true
	O.emoteStopJump = pick(d.emoteStopJump, D.emoteStopJump) == true
	O.emoteSpeed = math.clamp(tonumber(d.emoteSpeed) or D.emoteSpeed, 0.25, 3)
	O.emoteLoop = pick(d.emoteLoop, D.emoteLoop) == true
	O.animKeep = pick(d.animKeep, D.animKeep) == true
	O.cmdShortcuts = pick(d.cmdShortcuts, D.cmdShortcuts) == true
	O.cmdFilter = pick(d.cmdFilter, D.cmdFilter) == true
	O.logScroll = pick(d.logScroll, D.logScroll) == true
	O.cmdResume = pick(d.cmdResume, D.cmdResume) == true
	if EmoteState and EmoteState.track then
		pcall(function()
			EmoteState.track:AdjustSpeed(O.emoteSpeed)
			if O.emoteLoop then EmoteState.track.Looped = true end
		end)
	end
	if type(d.aliases) == "table" then CmdSearch.aliases = d.aliases end
	pcall(CmdSearch.filter)

	if AnimState and type(d.animation) == "table" and type(d.animation.map) == "table" and next(d.animation.map) then
		AnimState.saved = d.animation.map
		AnimState.savedName = d.animation.name
		AnimState.markSelected()
		task.spawn(function() pcall(AnimState.apply, AnimState.saved) end)
	end
	Theme.refresh()
end

function Settings.updateSelected()
	Settings.selectedLabel.Text = Settings.selected or "None"
end

function Settings.select(name)
	Settings.selected = name
	Settings.nameBox.Text = name
	Settings.refreshFiles()
end

function Settings.needFs()
	if Settings.fsOk() then return false end
	notify("Settings", "Your executor has no file support")
	return true
end

function Settings.needSelected()
	if Settings.selected then return false end
	notify("Settings", "Select a profile first")
	return true
end

function Settings.save()
	if Settings.needFs() or Settings.needSelected() then return end
	if Settings.writeFile(Settings.selected, Settings.collect()) then
		notify("Settings", "Saved " .. Settings.selected)
	else
		notify("Settings", "Could not save the profile")
	end
end

function Settings.saveNew()
	if Settings.needFs() then return end
	local base = Settings.clean(Settings.nameBox.Text)
	if base == "" then base = "Profile" end
	local name, n = base, 1
	while Settings.nameTaken(name) do
		n += 1
		name = base .. " " .. n
	end
	if Settings.writeFile(name, Settings.collect()) then
		Settings.select(name)
		notify("Settings", "Saved as " .. name)
	else
		notify("Settings", "Could not save the profile")
	end
end

function Settings.load()
	if Settings.needFs() or Settings.needSelected() then return end
	local data = Settings.readFile(Settings.selected)
	if not data then notify("Settings", "Could not read that profile"); return end
	Settings.apply(data)
	notify("Settings", "Loaded " .. Settings.selected)
end

function Settings.rename()
	if Settings.needFs() or Settings.needSelected() then return end
	local new = Settings.clean(Settings.nameBox.Text)
	local old = Settings.selected
	if new == "" then notify("Settings", "Type the new name first"); return end
	if new:lower() == old:lower() and new == old then notify("Settings", "That is already its name"); return end
	if new:lower() ~= old:lower() and Settings.nameTaken(new) then
		notify("Settings", "That name is already used")
		return
	end
	local data = Settings.readFile(old)
	if not data or not Settings.writeFile(new, data) then notify("Settings", "Could not rename it"); return end
	if new:lower() ~= old:lower() then pcall(delfile, Settings.path(old)) end
	if Settings.autoloadName() == old then Settings.setAutoload(new) end
	Settings.select(new)
	notify("Settings", "Renamed to " .. new)
end

function Settings.delete()
	if Settings.needFs() or Settings.needSelected() then return end
	local name = Settings.selected
	if Settings.confirmDelete ~= name then
		Settings.confirmDelete = name
		Settings.deleteLabel.Text = "Sure?"
		task.delay(3, function()
			if Settings.confirmDelete == name then
				Settings.confirmDelete = nil
				Settings.deleteLabel.Text = "Delete"
			end
		end)
		return
	end
	Settings.confirmDelete = nil
	Settings.deleteLabel.Text = "Delete"
	pcall(delfile, Settings.path(name))
	if Settings.autoloadName() == name then Settings.setAutoload(nil) end
	Settings.selected = nil
	Settings.refreshFiles()
	notify("Settings", "Deleted " .. name)
end

function Settings.autoload()
	local name = Settings.autoloadName()
	if not name then return end
	local data = Settings.readFile(name)
	if data then
		Settings.selected = name
		Settings.apply(data)
		notify("Settings", "Loaded " .. name)
	end
end

function Settings.keep(name, args)
	local saved = {}
	for i, v in ipairs(args or {}) do saved[i] = v end
	Settings.resume[name] = saved
end

function Settings.forget(stopper)
	local stopsAnimations = stopper == "stopanim" or stopper == "stopanims" or stopper == "stopanimations"
	for name, stop in pairs(Settings.resumable) do
		if stop == stopper or (stopsAnimations and (stop == "stopanim" or stop == "stopanims")) then
			Settings.resume[name] = nil
		end
	end
end

function Settings.quiet(fn)
	local previous = getgenv().devxNoteBuf
	getgenv().devxNoteBuf = { thread = coroutine.running() }
	pcall(fn)
	getgenv().devxNoteBuf = previous
end

function Settings.resumeAll(char)
	if not Settings.opts.cmdResume or next(Settings.resume) == nil then return end
	char:WaitForChild("Humanoid", 10)
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.7)
	if player.Character ~= char then return end
	local names = {}
	for name in pairs(Settings.resume) do table.insert(names, name) end
	table.sort(names)
	local resumed = {}
	for _, name in ipairs(names) do
		local args = Settings.resume[name]
		local action = CommandActions[name]
		local stopper = CommandActions[Settings.resumable[name]]
		if args and action then
			if stopper then Settings.quiet(stopper) end
			task.wait(0.1)
			Settings.quiet(function() action(args) end)
			if Settings.resume[name] then table.insert(resumed, name) end
		end
	end
	if #resumed > 0 then notify("Resume", "Resumed after respawn: " .. table.concat(resumed, ", ")) end
end

Settings.link(player.CharacterAdded:Connect(function(char)
	task.spawn(Settings.resumeAll, char)
end))

function Settings.unload()
	Settings.flingRun = (Settings.flingRun or 0) + 1
	for name in pairs(Settings.ran) do
		local stopper = Settings.stoppers[name] or Settings.resumable[name]
		local action = stopper and CommandActions[stopper]
		if action then Settings.quiet(action) end
	end
	for name, value in pairs(getgenv()) do
		if type(name) == "string" and (name:sub(1, 4) == "devx" or name == "infJump") then
			if value == true then
				getgenv()[name] = false
			elseif typeof(value) == "RBXScriptConnection" then
				pcall(function() value:Disconnect() end)
				getgenv()[name] = nil
			end
		end
	end
	pcall(Settings.esp.disable)
	if Outline.conn then pcall(function() Outline.conn:Disconnect() end) end
	for _, conn in ipairs(Settings.conns) do pcall(function() conn:Disconnect() end) end
	screenGui:Destroy()
	getgenv().devxUnload = nil
end

function Settings.refreshAll()
	for _, fn in ipairs(Settings.refreshers) do pcall(fn) end
end

function Settings.refreshFiles()
	for _, b in ipairs(Settings.fileButtons) do b:Destroy() end
	Settings.fileButtons = {}
	local names = Settings.listFiles()
	local found = false
	for _, n in ipairs(names) do
		if n == Settings.selected then found = true end
	end
	if not found then Settings.selected = nil end

	Settings.emptyLabel.Text = Settings.fsOk() and "No profiles yet - type a name and press Save as new"
		or "Your executor has no file support"
	Settings.emptyLabel.Visible = #names == 0

	local auto = Settings.autoloadName()
	for i, name in ipairs(names) do
		local picked = name == Settings.selected
		local fg = picked and Theme.textOn(Theme.accent) or Colors.white

		local btn = Instance.new("TextButton")
		btn.Name = "File"
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1,0,0,28)
		btn.Text = ""
		btn.BorderSizePixel = 0
		btn.Parent = Settings.fileList
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
		Theme.mark(btn, picked)

		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.new(0,8,0.5,-8)
		icon.Size = UDim2.new(0,16,0,16)
		icon.Image = Settings.icon("file-json")
		icon.ImageColor3 = fg
		icon.Parent = btn

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0,30,0,0)
		label.Size = UDim2.new(1,-60,1,0)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = fg
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Text = name
		label.Parent = btn

		local badge = Instance.new("ImageLabel")
		badge.BackgroundTransparency = 1
		badge.Position = UDim2.new(1,-24,0.5,-8)
		badge.Size = UDim2.new(0,16,0,16)
		badge.Image = Settings.icon("play-circle")
		badge.ImageColor3 = fg
		badge.Visible = name == auto
		badge.Parent = btn

		btn.MouseButton1Click:Connect(function() Settings.select(name) end)
		table.insert(Settings.fileButtons, btn)
	end
	Settings.updateSelected()
	Settings.refreshAll()
end

function Settings.nextOrder()
	Settings.order += 1
	return Settings.order
end

function Settings.header(iconName, text)
	local h = Instance.new("Frame")
	h.LayoutOrder = Settings.nextOrder()
	h.Size = UDim2.new(1,0,0,26)
	h.BackgroundTransparency = 1
	h.Parent = Settings.page

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0,4,0,5)
	icon.Size = UDim2.new(0,16,0,16)
	icon.Image = Settings.icon(iconName)
	icon.ImageColor3 = Colors.white
	icon.Parent = h

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0,26,0,0)
	label.Size = UDim2.new(1,-26,1,-1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Colors.white
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = h

	local line = Instance.new("Frame")
	line.Position = UDim2.new(0,0,1,-1)
	line.Size = UDim2.new(1,0,0,1)
	line.BackgroundColor3 = Color3.fromRGB(70,70,70)
	line.BorderSizePixel = 0
	line.Parent = h
end

function Settings.row(iconName, text, height)
	local row = Instance.new("Frame")
	row.LayoutOrder = Settings.nextOrder()
	row.Size = UDim2.new(1,0,0,height or 32)
	row.BackgroundColor3 = Color3.fromRGB(25,25,25)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.Parent = Settings.page
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0,8,0,8)
	icon.Size = UDim2.new(0,16,0,16)
	icon.Image = Settings.icon(iconName)
	icon.ImageColor3 = Colors.gray200
	icon.Parent = row

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0,32,0,0)
	label.Size = UDim2.new(0.5,-32,0,32)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(230,230,230)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.Parent = row
	return row
end

function Settings.toggle(iconName, text, get, set)
	local row = Settings.row(iconName, text)
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1,0.5)
	btn.Position = UDim2.new(1,-10,0,16)
	btn.Size = UDim2.new(0,44,0,20)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,16,0,16)
	knob.BorderSizePixel = 0
	knob.Parent = btn
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

	local function refresh()
		local on = get()
		btn.BackgroundColor3 = on and Theme.accent or Color3.fromRGB(60,60,60)
		knob.BackgroundColor3 = on and Theme.textOn(Theme.accent) or Colors.gray200
		knob.Position = on and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)
	end
	btn.MouseButton1Click:Connect(function()
		set(not get())
		refresh()
	end)
	table.insert(Settings.refreshers, refresh)
	return row
end

function Settings.slider(iconName, text, min, max, step, get, set)
	local row = Settings.row(iconName, text)

	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1,0.5)
	box.Position = UDim2.new(1,-10,0,16)
	box.Size = UDim2.new(0,52,0,20)
	box.BackgroundColor3 = Colors.gray35
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Code
	box.TextSize = 12
	box.TextColor3 = Colors.white
	box.ClearTextOnFocus = true
	box.Parent = row
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(1,0.5)
	track.Position = UDim2.new(1,-70,0,16)
	track.Size = UDim2.new(0.3,0,0,6)
	track.BackgroundColor3 = Color3.fromRGB(60,60,60)
	track.BorderSizePixel = 0
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0,0,1,0)
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

	local hit = Instance.new("TextButton")
	hit.AnchorPoint = Vector2.new(0,0.5)
	hit.Position = UDim2.new(0,0,0.5,0)
	hit.Size = UDim2.new(1,0,0,22)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 2
	hit.Parent = track

	local function refresh()
		local raw = get()
		local v = math.clamp(raw, min, max)
		fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
		fill.BackgroundColor3 = Theme.accent
		box.Text = Settings.fmt(raw)
	end
	local function setValue(v)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		set(v)
		refresh()
	end
	local function fromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		setValue(min + rel * (max - min))
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Settings.drag = fromX
			Settings.page.ScrollingEnabled = false
			fromX(input.Position.X)
		end
	end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then setValue(n) else refresh() end
	end)
	table.insert(Settings.refreshers, refresh)
	return row
end

function Settings.color(iconName, text, get, set)
	local row = Settings.row(iconName, text, 72)

	local swatch = Instance.new("Frame")
	swatch.AnchorPoint = Vector2.new(1,0)
	swatch.Position = UDim2.new(1,-92,0,6)
	swatch.Size = UDim2.new(0,20,0,20)
	swatch.BorderSizePixel = 0
	swatch.Parent = row
	Instance.new("UICorner", swatch).CornerRadius = UDim.new(0,4)
	local swatchStroke = Instance.new("UIStroke")
	swatchStroke.Color = Colors.gray120
	swatchStroke.Thickness = 1
	swatchStroke.Parent = swatch

	local hex = Instance.new("TextBox")
	hex.AnchorPoint = Vector2.new(1,0)
	hex.Position = UDim2.new(1,-10,0,6)
	hex.Size = UDim2.new(0,76,0,20)
	hex.BackgroundColor3 = Colors.gray35
	hex.BorderSizePixel = 0
	hex.Font = Enum.Font.Code
	hex.TextSize = 12
	hex.TextColor3 = Colors.white
	hex.PlaceholderText = "#RRGGBB"
	hex.ClearTextOnFocus = true
	hex.Parent = row
	Instance.new("UICorner", hex).CornerRadius = UDim.new(0,4)

	local presets = Instance.new("Frame")
	presets.Position = UDim2.new(0,8,0,38)
	presets.Size = UDim2.new(1,-16,0,26)
	presets.BackgroundTransparency = 1
	presets.Parent = row
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,6)
	layout.Parent = presets

	local function refresh()
		local c = get()
		swatch.BackgroundColor3 = c
		hex.Text = Settings.hex(c)
	end
	for i, c in ipairs(Settings.presets) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = i
		b.Size = UDim2.new(0,22,0,22)
		b.BackgroundColor3 = c
		b.BorderSizePixel = 0
		b.Text = ""
		b.Parent = presets
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
		local st = Instance.new("UIStroke")
		st.Color = Colors.gray90
		st.Thickness = 1
		st.Parent = b
		b.MouseButton1Click:Connect(function()
			set(c)
			refresh()
		end)
	end
	hex.FocusLost:Connect(function()
		local c = Settings.parseColor(hex.Text)
		if c then set(c) end
		refresh()
	end)
	table.insert(Settings.refreshers, refresh)
	return row
end

function Settings.keybind(iconName, text, get, set)
	local row = Settings.row(iconName, text)
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1,0.5)
	btn.Position = UDim2.new(1,-10,0,16)
	btn.Size = UDim2.new(0,110,0,22)
	btn.BackgroundColor3 = Colors.gray35
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = 12
	btn.TextColor3 = Colors.white
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

	local function refresh() btn.Text = get().Name end
	btn.MouseButton1Click:Connect(function()
		btn.Text = "Press a key..."
		Settings.capture = function(key)
			Settings.capture = nil
			if key then set(key) end
			refresh()
		end
	end)
	table.insert(Settings.refreshers, refresh)
	return row
end

function Settings.action(parent, iconName, text, callback)
	local btn = Instance.new("TextButton")
	btn.Text = ""
	btn.BackgroundColor3 = Colors.gray30
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0,8,0.5,-8)
	icon.Size = UDim2.new(0,16,0,16)
	icon.Image = Settings.icon(iconName)
	icon.ImageColor3 = Colors.white
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0,28,0,0)
	label.Size = UDim2.new(1,-32,1,0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Colors.white
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.Parent = btn

	Outline.add(btn, Settings.panel)
	btn.MouseButton1Click:Connect(callback)
	return btn, label
end

function Settings.init()
	local panel = Instance.new("Frame")
	panel.Name = "SettingsPanel"
	panel.Position = UDim2.new(0,SIDE_W,0,32)
	panel.Size = UDim2.new(1,-SIDE_W,1,-32)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = window
	Settings.panel = panel

	Settings.scale = Instance.new("UIScale")
	Settings.scale.Parent = window

	local heading = Instance.new("TextLabel")
	heading.Name = "Heading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.new(0,0,0,4)
	heading.Size = UDim2.new(1,0,0,28)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 18
	heading.TextColor3 = Colors.white
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Text = "Settings"
	heading.Parent = panel

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page"
	page.Position = UDim2.new(0,0,0,36)
	page.Size = UDim2.new(1,0,1,-36)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ClipsDescendants = true
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Colors.gray90
	page.CanvasSize = UDim2.new(0,0,0,0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Parent = panel
	Settings.page = page

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,6)
	layout.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,4)
	pad.PaddingBottom = UDim.new(0,10)
	pad.PaddingLeft = UDim.new(0,6)
	pad.PaddingRight = UDim.new(0,10)
	pad.Parent = page

	Settings.link(UserInputService.InputChanged:Connect(function(input)
		if Settings.drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			Settings.drag(input.Position.X)
		end
	end))
	Settings.link(UserInputService.InputEnded:Connect(function(input)
		if Settings.drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			Settings.drag = nil
			page.ScrollingEnabled = true
		end
	end))
	Settings.link(UserInputService.InputBegan:Connect(function(input)
		if Settings.capture and input.UserInputType == Enum.UserInputType.Keyboard then
			local done = Settings.capture
			Settings.justCaptured = tick()
			if input.KeyCode == Enum.KeyCode.Escape then done(nil) else done(input.KeyCode) end
		end
	end))

	Settings.header("palette", "Appearance")
	Settings.color("paintbrush", "Accent color",
		function() return Theme.accent end,
		function(c) Theme.accent = c; Theme.refresh() end)
	Settings.color("pipette", "Outline color",
		function() return Theme.outline end,
		function(c) Theme.outline = c; Theme.refresh() end)
	Settings.slider("contrast", "Window transparency", 0, 0.9, 0.05,
		function() return window.BackgroundTransparency end,
		function(v) window.BackgroundTransparency = v end)
	Settings.slider("scaling", "UI scale", 0.7, 1.5, 0.05,
		function() return Settings.scale.Scale end,
		function(v) Settings.scale.Scale = v end)
	Settings.toggle("wand-2", "Animated outline",
		function() return Outline.animate end,
		function(v) Outline.animate = v; Outline.refresh() end)

	Settings.header("sliders-horizontal", "Interface")
	Settings.keybind("keyboard", "Toggle key",
		function() return Settings.toggleKey end,
		function(k) Settings.toggleKey = k end)
	Settings.toggle("volume-2", "Notification sound",
		function() return Settings.sound end,
		function(v) Settings.sound = v end)

	Settings.header("party-popper", "Emote")
	Settings.toggle("move-horizontal", "Stop when moving",
		function() return Settings.opts.emoteStopMove end,
		function(v) Settings.opts.emoteStopMove = v end)
	Settings.toggle("arrow-up", "Stop when jumping",
		function() return Settings.opts.emoteStopJump end,
		function(v) Settings.opts.emoteStopJump = v end)
	Settings.slider("gauge", "Emote speed", 0.25, 3, 0.25,
		function() return Settings.opts.emoteSpeed end,
		function(v)
			Settings.opts.emoteSpeed = v
			if EmoteState and EmoteState.track then pcall(function() EmoteState.track:AdjustSpeed(v) end) end
		end)
	Settings.toggle("repeat", "Force loop",
		function() return Settings.opts.emoteLoop end,
		function(v)
			Settings.opts.emoteLoop = v
			if v and EmoteState and EmoteState.track then pcall(function() EmoteState.track.Looped = true end) end
		end)

	Settings.header("person-standing", "Animations")
	Settings.toggle("refresh-cw", "Keep after respawn",
		function() return Settings.opts.animKeep end,
		function(v) Settings.opts.animKeep = v end)

	Settings.header("terminal", "Commands")
	Settings.toggle("command", "Shortcuts (part of a name)",
		function() return Settings.opts.cmdShortcuts end,
		function(v) Settings.opts.cmdShortcuts = v end)
	Settings.toggle("search", "Live search filter",
		function() return Settings.opts.cmdFilter end,
		function(v) Settings.opts.cmdFilter = v; CmdSearch.filter() end)
	Settings.toggle("refresh-cw", "Resume after respawn",
		function() return Settings.opts.cmdResume end,
		function(v) Settings.opts.cmdResume = v end)

	Settings.header("scroll", "Logs")
	Settings.toggle("arrow-down", "Auto-scroll to newest",
		function() return Settings.opts.logScroll end,
		function(v) Settings.opts.logScroll = v end)

	Settings.header("folder-open", "Profiles")

	local infoRow = Settings.row("file-json", "Selected profile")
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.AnchorPoint = Vector2.new(1,0.5)
	selectedLabel.Position = UDim2.new(1,-10,0,16)
	selectedLabel.Size = UDim2.new(0.5,-16,0,20)
	selectedLabel.Font = Enum.Font.GothamBold
	selectedLabel.TextSize = 12
	selectedLabel.TextColor3 = Colors.white
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
	selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	selectedLabel.Text = "None"
	selectedLabel.Parent = infoRow
	Settings.selectedLabel = selectedLabel

	local fileList = Instance.new("Frame")
	fileList.Name = "FileList"
	fileList.LayoutOrder = Settings.nextOrder()
	fileList.Size = UDim2.new(1,0,0,0)
	fileList.AutomaticSize = Enum.AutomaticSize.Y
	fileList.BackgroundTransparency = 1
	fileList.Parent = page
	local fileLayout = Instance.new("UIListLayout")
	fileLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fileLayout.Padding = UDim.new(0,4)
	fileLayout.Parent = fileList
	Settings.fileList = fileList

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.LayoutOrder = 1000000
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Size = UDim2.new(1,0,0,24)
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.TextSize = 12
	emptyLabel.TextColor3 = Colors.gray150
	emptyLabel.Text = ""
	emptyLabel.Parent = fileList
	Settings.emptyLabel = emptyLabel

	local nameRow = Settings.row("edit-3", "Profile name")
	local nameBox = Instance.new("TextBox")
	nameBox.AnchorPoint = Vector2.new(1,0.5)
	nameBox.Position = UDim2.new(1,-10,0,16)
	nameBox.Size = UDim2.new(0.5,-16,0,22)
	nameBox.BackgroundColor3 = Colors.gray35
	nameBox.BorderSizePixel = 0
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 12
	nameBox.TextColor3 = Colors.white
	nameBox.PlaceholderText = "New name..."
	nameBox.PlaceholderColor3 = Color3.fromRGB(110,110,110)
	nameBox.Text = ""
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = nameRow
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0,4)
	Settings.nameBox = nameBox

	Settings.toggle("play-circle", "Load selected on start",
		function() return Settings.selected ~= nil and Settings.autoloadName() == Settings.selected end,
		function(on)
			if Settings.needFs() or Settings.needSelected() then return end
			Settings.setAutoload(on and Settings.selected or nil)
			Settings.refreshFiles()
		end)

	local grid = Instance.new("Frame")
	grid.LayoutOrder = Settings.nextOrder()
	grid.Size = UDim2.new(1,0,0,62)
	grid.BackgroundTransparency = 1
	grid.Parent = page
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.CellPadding = UDim2.new(0,6,0,6)
	gridLayout.CellSize = UDim2.new(0.333,-4,0,28)
	gridLayout.Parent = grid

	local function addAction(order, iconName, text, callback)
		local btn, label = Settings.action(grid, iconName, text, callback)
		btn.LayoutOrder = order
		return btn, label
	end
	addAction(1, "save", "Save", function() Settings.save() end)
	addAction(2, "file-plus", "Save as new", function() Settings.saveNew() end)
	addAction(3, "download", "Load", function() Settings.load() end)
	addAction(4, "edit-3", "Rename", function() Settings.rename() end)
	local _, deleteLabel = addAction(5, "trash-2", "Delete", function() Settings.delete() end)
	Settings.deleteLabel = deleteLabel
	addAction(6, "rotate-ccw", "Reset", function()
		Settings.apply({})
		notify("Settings", "Back to the default look")
	end)

	Settings.refreshFiles()
end

Settings.init()

Theme.bind(function()
	local c = Theme.accent
	tabLogsUnderline.BackgroundColor3 = c
	tabCmdsUnderline.BackgroundColor3 = c
	Settings.tabUnderline.BackgroundColor3 = c
	Settings.art.TextColor3 = c
	commandPrompt.TextColor3 = c
	sendBtn.ImageColor3 = c
	for _, e in ipairs(CmdSearch.entries) do
		if e.label then e.label.TextColor3 = c end
	end
	if Settings.fpsLabel then Settings.fpsLabel.TextColor3 = c end
	for _, t in pairs(Settings.tabs) do
		if t.underline then t.underline.BackgroundColor3 = c end
	end
	Settings.paintTabs()
	Outline.refresh()
	Settings.refreshAll()
	if Settings.panel.Visible then Settings.refreshFiles() end
end)

Settings.tabs = {}
Settings.tabList = {}

function addTab(key, btn, underline, panel, onOpen)
	Settings.tabs[key] = { btn = btn, underline = underline, panel = panel, onOpen = onOpen }
	table.insert(Settings.tabList, key)
	btn.MouseButton1Click:Connect(function() Settings.switchTab(key) end)
end

function Settings.paintTabs()
	local tab = Settings.currentTab
	local on, off = Theme.accent, Colors.gray120
	for key, t in pairs(Settings.tabs) do
		local selected = key == tab
		local icon, name = t.btn:FindFirstChild("Icon"), t.btn:FindFirstChild("Name")
		if icon or name then
			if icon then icon.TextColor3 = selected and on or off end
			if name then name.TextColor3 = selected and on or off end
		elseif t.btn:IsA("ImageButton") then
			t.btn.ImageColor3 = selected and on or Colors.gray200
		else
			t.btn.TextColor3 = selected and on or off
		end
		if t.underline then t.underline.Visible = selected end
	end
end

function Settings.switchTab(tab)
	Settings.currentTab = tab
	for key, t in pairs(Settings.tabs) do
		t.panel.Visible = (key == tab)
	end
	Settings.paintTabs()
	local t = Settings.tabs[tab]
	if t and t.onOpen then t.onOpen() end
end

addTab("logs", tabLogs, tabLogsUnderline, content)
addTab("cmds", tabCmds, tabCmdsUnderline, commandsPanel)
addTab("settings", Settings.tab, Settings.tabUnderline, Settings.panel, function() Settings.refreshFiles() end)
Settings.switchTab("logs")

title.MouseEnter:Connect(function() if #entries > 0 then title.TextColor3 = Theme.accent end end)
title.MouseLeave:Connect(function() title.TextColor3 = Colors.white end)
title.MouseButton1Click:Connect(function()
	if #entries == 0 then return end
	for _,e in ipairs(entries) do e:Destroy() end
	entries = {}; lineNum = 0
end)

Settings.link(LogService.MessageOut:Connect(function(message, messageType)
	if shouldIgnore(message) then return end
	if messageType == Enum.MessageType.MessageWarning then pushEntry("Warn", message)
	elseif messageType == Enum.MessageType.MessageError then pushEntry("Error", message)
	else pushEntry("Print", message)
	end
end))

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

Settings.link(UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(0, startPos.X.Offset+delta.X, 0, startPos.Y.Offset+delta.Y)
	end
end))

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
	Settings.link(UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - stIn
			local w = stSize.X.Offset; local h = stSize.Y.Offset
			local x = stPos.X.Offset;  local y = stPos.Y.Offset
			if xd == 1  then w = math.max(430, stSize.X.Offset+delta.X) end
			if xd == -1 then w = math.max(430, stSize.X.Offset-delta.X); x = stPos.X.Offset+(stSize.X.Offset-w) end
			if yd == 1  then h = math.max(220, stSize.Y.Offset+delta.Y) end
			if yd == -1 then h = math.max(220, stSize.Y.Offset-delta.Y); y = stPos.Y.Offset+(stSize.Y.Offset-h) end
			window.Size = UDim2.new(0,w,0,h); window.Position = UDim2.new(0,x,0,y)
		end
	end))
end

local function MakeHandle(name,position,size,xd,yd)
	local handle = Instance.new("Frame")
	handle.Name = name; handle.BackgroundTransparency = 1
	handle.BorderSizePixel = 0; handle.Position = position
	handle.Size = size; handle.ZIndex = 5; handle.Active = true
	handle.Parent = window; BindResize(handle,xd,yd)
end

MakeHandle("ResizeRight",    UDim2.new(1,-3,0,0),   UDim2.new(0,6,1,0),   1,  0)
MakeHandle("ResizeLeft",     UDim2.new(0,-3,0,0),   UDim2.new(0,6,1,0),  -1,  0)
MakeHandle("ResizeTop",      UDim2.new(0,0,0,-3),   UDim2.new(1,0,0,6),   0, -1)
MakeHandle("ResizeBottom",   UDim2.new(0,0,1,-3),   UDim2.new(1,0,0,6),   0,  1)
MakeHandle("ResizeTopLeft",  UDim2.new(0,-5,0,-5),  UDim2.new(0,10,0,10),-1, -1)
MakeHandle("ResizeTopRight", UDim2.new(1,-5,0,-5),  UDim2.new(0,10,0,10), 1, -1)
MakeHandle("ResizeBottomLeft",  UDim2.new(0,-5,1,-5), UDim2.new(0,10,0,10),-1,1)
MakeHandle("ResizeBottomRight", UDim2.new(1,-5,1,-5), UDim2.new(0,10,0,10), 1,1)

Settings.link(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Settings.toggleKey and not Settings.capture and tick() - (Settings.justCaptured or 0) > 0.3 then
		window.Visible = not window.Visible
	end
end))

Settings.link(player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		local root = getRoot(char)
		if root then getgenv().devxLastDeath = root.CFrame end
	end)
end))
if player.Character then
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			local root = getRoot(player.Character)
			if root then getgenv().devxLastDeath = root.CFrame end
		end)
	end
end

pcall(function()
	for _, d in ipairs(screenGui:GetDescendants()) do
		if d:IsA("GuiBase2d") then d.AutoLocalize = false end
	end
end)

getgenv().devxUnload = Settings.unload

Settings = Settings
Theme = Theme
Outline = Outline
CmdSearch = CmdSearch
Colors = Colors
player = player
camera = camera
playerGui = playerGui
window = window
screenGui = screenGui
hotbar = hotbar
sidebar = sidebar
SIDE_W = SIDE_W
commandInput = commandInput
notify = notify
getRoot = getRoot
getHumanoid = getHumanoid
copy = copy
executeCommand = executeCommand
DISCORD_LINK = DISCORD_LINK

local function start()
task.spawn(function()
	for index, cmd in ipairs(Commands) do
		local frame = AddCommandEntry(cmd)
		frame.LayoutOrder = index
		table.insert(CmdSearch.entries, {
			frame = frame,
			base  = (cmd.Name:match("^(%S+)") or cmd.Name):lower(),
			index = index,
			label = frame:FindFirstChild("Name"),
		})
		if index % 40 == 0 then task.wait() end
	end
	CmdSearch.filter()
end)

	pcall(Settings.autoload)

pushEntry("Print", "DevX Console loaded – "..#Commands.." commands ready. Press "..Settings.toggleKey.Name.." to toggle.")
end

(function()
	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	local function getHumanoid(char)
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	local function r15(plr)
		local hum = getHumanoid(plr.Character)
		return hum and hum.RigType == Enum.HumanoidRigType.R15
	end

	local danceTrack = nil
	local SpasmAnim, Spasm = nil, nil

	local animPanel = Instance.new("Frame")
	animPanel.Name                   = "AnimationsPanel"
	animPanel.Position               = UDim2.new(0,SIDE_W,0,32)
	animPanel.Size                   = UDim2.new(1,-SIDE_W,1,-32)
	animPanel.BackgroundTransparency = 1
	animPanel.BorderSizePixel        = 0
	animPanel.Visible                = false
	animPanel.Parent                 = window

local tabAnims, tabAnimsUnderline = sideTab("A", "Anims", 4)

EmoteState = {
	loaded = false, loading = false, busy = false, page = 1, pageSize = 45,
	pool = {}, entryOf = {}, cellOf = {}, starOf = {}, ids = {}, names = {}, lower = {}, conns = {},
	view = nil, playing = nil, track = nil,
}

EmoteState.tab, EmoteState.tabUnderline = sideTab("E", "Emote", 5)

Settings.fav.tab, Settings.fav.tabUnderline = sideTab(utf8.char(0x2605), "Favorites", 6)

function Settings.fav.style(btn, owner)
	btn.BackgroundColor3 = Colors.gray30
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 12
	btn.TextColor3 = Colors.white
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
	Outline.add(btn, owner)
end

function Settings.fav.cell(parent, order)
	local cell = Instance.new("Frame")
	cell.LayoutOrder = order
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-28,1,0)
	btn.Text = ""
	btn.Parent = cell

	local star = Instance.new("ImageButton")
	star.AnchorPoint = Vector2.new(1,0.5)
	star.Position = UDim2.new(1,0,0.5,0)
	star.Size = UDim2.new(0,24,0,24)
	star.BackgroundTransparency = 1
	star.Image = Settings.icon("star")
	star.Parent = cell
	return cell, btn, star
end

function Settings.fav.paintStar(star, on)
	star.ImageColor3 = on and Theme.accent or Colors.gray90
	star.ImageTransparency = on and 0 or 0.35
end

function Settings.fav.search(parent, position, size, placeholder)
	local box = Instance.new("TextBox")
	box.Position = position
	box.Size = size
	box.BackgroundColor3 = Colors.gray30
	box.BackgroundTransparency = 0.1
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.TextSize = 13
	box.TextColor3 = Colors.white
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(110,110,110)
	box.Text = ""
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = parent
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0,8)
	pad.Parent = box
	return box
end

function Settings.fav.onSearch(box, fn)
	local token = 0
	box:GetPropertyChangedSignal("Text"):Connect(function()
		token += 1
		local mine = token
		task.delay(0.2, function()
			if mine == token then fn() end
		end)
	end)
end

function Settings.fav.has(kind, key)
	return Settings.fav[kind][key] ~= nil
end

function Settings.fav.sorted(kind)
	local list = {}
	for _, item in pairs(Settings.fav[kind]) do table.insert(list, item) end
	table.sort(list, function(a, b) return a.order < b.order end)
	return list
end

function Settings.fav.toggle(kind, key, data)
	local store = Settings.fav[kind]
	if store[key] then
		store[key] = nil
	else
		Settings.fav.counter += 1
		data.order = Settings.fav.counter
		store[key] = data
	end
	Settings.fav.save()
	Settings.fav.repaint()
end

AnimState = {
	loaded = false, loading = false, busy = false, saved = nil, selected = nil, savedName = nil, byName = {}, cells = {},
	url = "https://raw.githubusercontent.com/DRYF-1/Roblox-Emote/main/AnimationSniper.json",
	cacheFile = "AnimationCache.json",
	default = {
		["idle/Animation1"] = "rbxassetid://2510196951",
		["idle/Animation2"] = "rbxassetid://2510197257",
		["walk/WalkAnim"]   = "rbxassetid://2510202577",
		["run/RunAnim"]     = "rbxassetid://2510198475",
		["jump/JumpAnim"]   = "rbxassetid://2510197830",
		["climb/ClimbAnim"] = "rbxassetid://2510192778",
		["fall/FallAnim"]   = "rbxassetid://2510195892",
		["swim/SwimAnim"]   = "rbxassetid://2510203414",
	},
}

function AnimState.readCache()
	if isfile and readfile and isfile(AnimState.cacheFile) then
		local ok, content = pcall(readfile, AnimState.cacheFile)
		if ok then
			local ok2, decoded = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if ok2 and type(decoded) == "table" then return decoded end
		end
	end
	return {}
end

function AnimState.writeCache(data)
	if writefile then
		pcall(function()
			writefile(AnimState.cacheFile, HttpService:JSONEncode(data))
		end)
	end
end

function AnimState.resolve(bundled)
	if type(bundled) ~= "table" then bundled = {bundled} end
	local mappings = {}
	local fileCache = AnimState.readCache()
	local updated = false
	local counter = 0
	for _, assetIds in pairs(bundled) do
		local ids = type(assetIds) == "table" and assetIds or {assetIds}
		for _, assetId in pairs(ids) do
			local cleanId = tonumber(assetId)
			if cleanId and cleanId ~= 0 then
				local key = tostring(cleanId)
				if fileCache[key] then
					for pathKey, animId in pairs(fileCache[key]) do mappings[pathKey] = animId end
				else
					local ok, objects = pcall(function()
						return game:GetObjects("rbxassetid://" .. cleanId)
					end)
					if ok and objects then
						fileCache[key] = {}
						updated = true
						for _, obj in pairs(objects) do
							for _, d in ipairs(obj:GetDescendants()) do
								if d:IsA("Animation") and d.AnimationId ~= "" then
									local pathKey = d.Parent.Name .. "/" .. d.Name
									mappings[pathKey] = d.AnimationId
									fileCache[key][pathKey] = d.AnimationId
								end
							end
							obj:Destroy()
						end
					end
					counter += 1
					if counter >= 2 then RunService.Heartbeat:Wait(); counter = 0 end
				end
			end
		end
	end
	if updated then AnimState.writeCache(fileCache) end
	return mappings
end

function AnimState.apply(map)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	if hum.RigType ~= Enum.HumanoidRigType.R15 then
		notify("Animations", "Your character must be R15")
		return false
	end
	local animate = char:FindFirstChild("Animate") or char:WaitForChild("Animate", 5)
	if not animate then return false end

	for path, id in pairs(map) do
		local obj = animate
		for seg in string.gmatch(path, "[^/]+") do
			obj = obj:FindFirstChild(seg)
			if not obj then break end
		end
		if obj and obj:IsA("Animation") then obj.AnimationId = id end
	end

	animate.Disabled = true
	task.wait()
	animate.Disabled = false

	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, t in pairs(animator:GetPlayingAnimationTracks()) do
			t:Stop(0); t:Destroy()
		end
	end
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
	task.wait(0.01)
	hum:ChangeState(Enum.HumanoidStateType.Landed)
	return true
end

function AnimState.markSelected()
	if AnimState.selected and AnimState.selected.Parent then Theme.mark(AnimState.selected, false) end
	local btn = AnimState.savedName and AnimState.byName[AnimState.savedName]
	if btn then
		Theme.mark(btn, true)
		AnimState.selected = btn
	else
		AnimState.selected = nil
	end
	for name, favBtn in pairs(Settings.fav.animBtns) do Theme.mark(favBtn, name == AnimState.savedName) end
end

function AnimState.select(pack, btn)
	if AnimState.busy then return end
	AnimState.busy = true
	task.spawn(function()
		local ok, err = pcall(function()
			if not pack.map then
				btn.Text = "Loading..."
				pack.map = AnimState.resolve(pack.items)
			end
			btn.Text = pack.name
			if not next(pack.map) then
				notify("Animations", "This pack is empty or invalid")
				return
			end
			if AnimState.apply(pack.map) then
				AnimState.saved = pack.map
				AnimState.savedName = pack.name
				AnimState.markSelected()
				notify("Animations", "Selected " .. pack.name)
			end
		end)
		btn.Text = pack.name
		AnimState.busy = false
		if not ok then
			warn("Animations: " .. tostring(err))
			notify("Animations", "Something went wrong")
		end
	end)
end

function AnimState.build(packs)
	for i, pack in ipairs(packs) do
		local cell, btn, star = Settings.fav.cell(AnimState.list, i)
		btn.Name = "Pack"
		btn.TextWrapped = true
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Text = pack.name
		AnimState.byName[pack.name] = btn
		Settings.fav.style(btn, animPanel)
		btn.MouseButton1Click:Connect(function()
			AnimState.select(pack, btn)
		end)
		star.MouseButton1Click:Connect(function()
			Settings.fav.toggle("anims", pack.name, {name = pack.name, items = pack.items})
		end)
		Settings.fav.paintStar(star, Settings.fav.has("anims", pack.name))
		AnimState.cells[i] = {cell = cell, star = star, name = pack.name, lower = pack.name:lower()}
		if i % 20 == 0 then task.wait() end
	end
end

function AnimState.applySearch()
	local query = AnimState.searchBox.Text:lower():match("^%s*(.-)%s*$")
	local terms = {}
	for word in query:gmatch("%S+") do table.insert(terms, word) end
	local shown = 0
	for i, c in ipairs(AnimState.cells) do
		local hit = true
		for _, term in ipairs(terms) do
			if not c.lower:find(term, 1, true) then hit = false; break end
		end
		c.cell.Visible = hit
		c.cell.LayoutOrder = (hit and #terms > 0 and c.lower:sub(1, #terms[1]) == terms[1]) and (i - 100000) or i
		if hit then shown += 1 end
	end
	AnimState.status.Text = "No matching animations"
	AnimState.status.Visible = AnimState.loaded and shown == 0
	AnimState.list.CanvasPosition = Vector2.new(0, 0)
end

function AnimState.load()
	if AnimState.loaded or AnimState.loading then return end
	AnimState.loading = true
	AnimState.status.Text = "Loading..."
	AnimState.status.Visible = true
	task.spawn(function()
		local ok, packs = pcall(function()
			local decoded = HttpService:JSONDecode(game:HttpGet(AnimState.url))
			if type(decoded) ~= "table" or type(decoded.data) ~= "table" then error("bad data") end
			local unique, index = {}, {}
			for _, pack in ipairs(decoded.data) do
				if pack.bundledItems and pack.name then
					local clean = (tostring(pack.name):gsub("[:%.]", ""))
					clean = (clean:gsub("%s+[bB][yY].*", ""))
					clean = clean:sub(1,1):upper() .. clean:sub(2)
					local entry = {name = clean, items = pack.bundledItems}
					if index[clean] then
						unique[index[clean]] = entry
					else
						table.insert(unique, entry)
						index[clean] = #unique
					end
				end
			end
			table.insert(unique, 1, {name = "Default Animations", map = AnimState.default})
			return unique
		end)
		AnimState.loading = false
		if not ok then
			AnimState.status.Text = "Failed to load animations"
			warn("Animations: " .. tostring(packs))
			return
		end
		AnimState.loaded = true
		AnimState.status.Visible = false
		AnimState.build(packs)
		AnimState.markSelected()
		AnimState.applySearch()
	end)
end

function AnimState.init()
	local heading = Instance.new("TextLabel")
	heading.Name = "Heading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.new(0,0,0,4)
	heading.Size = UDim2.new(1,0,0,28)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 18
	heading.TextColor3 = Colors.white
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Text = "Animations"
	heading.Parent = animPanel

	local list = Instance.new("ScrollingFrame")
	list.Name = "AnimList"
	list.Position = UDim2.new(0,0,0,68)
	list.Size = UDim2.new(1,0,1,-68)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ClipsDescendants = true
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = Colors.gray90
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = animPanel
	AnimState.list = list

	AnimState.searchBox = Settings.fav.search(animPanel, UDim2.new(0,6,0,36), UDim2.new(1,-12,0,26), "Search animations...")
	Settings.fav.onSearch(AnimState.searchBox, function()
		if AnimState.loaded then AnimState.applySearch() end
	end)

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.new(0,6,0,6)
	grid.CellSize = UDim2.new(0,140,0,30)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,4)
	pad.PaddingBottom = UDim.new(0,8)
	pad.PaddingLeft = UDim.new(0,6)
	pad.PaddingRight = UDim.new(0,6)
	pad.Parent = list

	local function fit()
		local w = list.AbsoluteSize.X - 12 - 4 - 12
		grid.CellSize = UDim2.new(0, math.max(60, math.floor(w / 3)), 0, 30)
	end
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.AnchorPoint = Vector2.new(0,0.5)
	status.Position = UDim2.new(0,0,0.5,10)
	status.Size = UDim2.new(1,0,0,24)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextColor3 = Colors.gray150
	status.Text = ""
	status.Visible = false
	status.ZIndex = 2
	status.Parent = animPanel
	AnimState.status = status

	Settings.link(player.CharacterAdded:Connect(function()
		if AnimState.saved and Settings.opts.animKeep then
			task.wait(0.5)
			pcall(AnimState.apply, AnimState.saved)
		end
	end))
end

AnimState.init()

EmoteState.url = "https://raw.githubusercontent.com/DRYF-1/Roblox-Emote/refs/heads/main/EmoteSniper.json"
EmoteState.cacheFile = "EmoteCache.json"

function EmoteState.idStr(id)
	return string.format("%.0f", id)
end

function EmoteState.readCache()
	if isfile and readfile and isfile(EmoteState.cacheFile) then
		local ok, content = pcall(readfile, EmoteState.cacheFile)
		if ok then
			local ok2, decoded = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if ok2 and type(decoded) == "table" then return decoded end
		end
	end
	return {}
end

function EmoteState.resolve(id)
	if not EmoteState.animCache then EmoteState.animCache = EmoteState.readCache() end
	local key = EmoteState.idStr(id)
	if EmoteState.animCache[key] then return EmoteState.animCache[key] end

	local animId
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. key)
	end)
	if ok and objects then
		for _, obj in ipairs(objects) do
			local anim = obj:IsA("Animation") and obj or obj:FindFirstChildWhichIsA("Animation", true)
			if anim and anim.AnimationId ~= "" then animId = anim.AnimationId end
			obj:Destroy()
			if animId then break end
		end
	end
	if not animId then return "rbxassetid://" .. key end

	EmoteState.animCache[key] = animId
	if writefile then
		pcall(function()
			writefile(EmoteState.cacheFile, HttpService:JSONEncode(EmoteState.animCache))
		end)
	end
	return animId
end

function EmoteState.paint()
	for _, btn in ipairs(EmoteState.pool) do
		local idx = EmoteState.entryOf[btn]
		Theme.mark(btn, idx ~= nil and EmoteState.playing == EmoteState.idStr(EmoteState.ids[idx]))
	end
	for btn, id in pairs(Settings.fav.emoteBtns) do
		Theme.mark(btn, EmoteState.playing == id)
	end
end

function EmoteState.relabel()
	for _, btn in ipairs(EmoteState.pool) do
		local idx = EmoteState.entryOf[btn]
		if idx then btn.Text = EmoteState.names[idx] end
	end
end

function EmoteState.clear()
	EmoteState.playing = nil
	EmoteState.track = nil
	for _, c in ipairs(EmoteState.conns) do c:Disconnect() end
	EmoteState.conns = {}
	EmoteState.paint()
end

function EmoteState.stop()
	local track = EmoteState.track
	EmoteState.track = nil
	if track then
		pcall(function() track:Stop(0.2) end)
		task.delay(0.5, function() pcall(function() track:Destroy() end) end)
	end
	EmoteState.clear()
end

function EmoteState.play(id, btn)
	if EmoteState.busy then return end
	local key = EmoteState.idStr(id)
	if EmoteState.playing == key then EmoteState.stop(); return end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then notify("Emote", "No character found"); return end

	EmoteState.busy = true
	local original = btn.Text
	task.spawn(function()
		local ok, err = pcall(function()
			EmoteState.stop()
			btn.Text = "Loading..."

			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			local anim = Instance.new("Animation")
			anim.AnimationId = EmoteState.resolve(id)
			local track = animator:LoadAnimation(anim)

			local waited = 0
			while track.Length == 0 and waited < 3 do
				task.wait(0.05)
				waited += 0.05
			end
			if track.Length == 0 then
				track:Destroy()
				notify("Emote", "Could not load this emote")
				return
			end

			track.Priority = Enum.AnimationPriority.Action4
			if Settings.opts.emoteLoop then track.Looped = true end
			track:Play(0.2, 1, Settings.opts.emoteSpeed)
			EmoteState.track = track
			EmoteState.playing = key

			table.insert(EmoteState.conns, track.Stopped:Connect(function()
				if EmoteState.track == track then EmoteState.clear() end
			end))
			table.insert(EmoteState.conns, hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
				if Settings.opts.emoteStopMove and hum.MoveDirection.Magnitude > 0 then EmoteState.stop() end
			end))
			table.insert(EmoteState.conns, hum.Jumping:Connect(function(active)
				if active and Settings.opts.emoteStopJump then EmoteState.stop() end
			end))
			EmoteState.paint()
		end)
		EmoteState.busy = false
		EmoteState.relabel()
		if not EmoteState.entryOf[btn] then btn.Text = original end
		if not ok then
			warn("Emote: " .. tostring(err))
			notify("Emote", "Something went wrong")
		end
	end)
end

function EmoteState.total()
	return EmoteState.view and #EmoteState.view or #EmoteState.ids
end

function EmoteState.render()
	local total = EmoteState.total()
	local size = EmoteState.pageSize
	local pages = math.max(1, math.ceil(total / size))
	EmoteState.page = math.clamp(EmoteState.page, 1, pages)
	local first = (EmoteState.page - 1) * size
	local visible = math.max(0, math.min(size, total - first))
	EmoteState.pages = pages

	for i, btn in ipairs(EmoteState.pool) do
		local pos = first + i
		if pos <= total then
			local idx = EmoteState.view and EmoteState.view[pos] or pos
			EmoteState.entryOf[btn] = idx
			btn.Text = EmoteState.names[idx]
			EmoteState.cellOf[btn].Visible = true
			Settings.fav.paintStar(EmoteState.starOf[btn], Settings.fav.has("emotes", EmoteState.idStr(EmoteState.ids[idx])))
		else
			EmoteState.entryOf[btn] = nil
			EmoteState.cellOf[btn].Visible = false
		end
	end
	EmoteState.paint()

	local pad = (3 - visible % 3) % 3
	EmoteState.spacers[1].Visible = pad >= 1
	EmoteState.spacers[2].Visible = pad >= 2
	local canBack, canNext = EmoteState.page > 1, EmoteState.page < pages
	EmoteState.backBtn.Visible, EmoteState.nextBtn.Visible, EmoteState.pageBox.Visible = true, true, true
	EmoteState.backBtn.BackgroundTransparency = canBack and 0.1 or 0.6
	EmoteState.backBtn.TextTransparency = canBack and 0 or 0.6
	EmoteState.nextBtn.BackgroundTransparency = canNext and 0.1 or 0.6
	EmoteState.nextBtn.TextTransparency = canNext and 0 or 0.6
	EmoteState.pageBox.Text = EmoteState.page .. " / " .. pages
	if EmoteState.loaded then
		EmoteState.status.Text = "No matching emotes"
		EmoteState.status.Visible = total == 0
	end
	EmoteState.list.CanvasPosition = Vector2.new(0, 0)
end

function EmoteState.applySearch()
	local q = EmoteState.searchBox.Text:lower():match("^%s*(.-)%s*$")
	if q == EmoteState.lastQuery then return end
	if q == "" then
		EmoteState.view = nil
	else
		local terms = {}
		for w in q:gmatch("%S+") do table.insert(terms, w) end
		local n, first = #terms, terms[1]
		local flen = #first
		local starts, others = {}, {}
		local lower = EmoteState.lower
		for i = 1, #lower do
			local s = lower[i]
			local hit = true
			for t = 1, n do
				if not s:find(terms[t], 1, true) then hit = false; break end
			end
			if hit then
				if s:sub(1, flen) == first then
					starts[#starts + 1] = i
				else
					others[#others + 1] = i
				end
			end
		end
		table.move(others, 1, #others, #starts + 1, starts)
		EmoteState.view = starts
	end
	EmoteState.lastQuery = q
	EmoteState.page = 1
	EmoteState.render()
end

function EmoteState.load()
	if EmoteState.loaded or EmoteState.loading then return end
	EmoteState.loading = true
	EmoteState.status.Text = "Loading emotes..."
	EmoteState.status.Visible = true
	task.spawn(function()
		local ok, err = pcall(function()
			local raw = game:HttpGet(EmoteState.url)
			task.wait()
			local decoded = HttpService:JSONDecode(raw)
			if type(decoded) ~= "table" or type(decoded.data) ~= "table" then error("bad data") end
			local ids, names, lower = {}, {}, {}
			for _, item in ipairs(decoded.data) do
				if type(item) == "table" and type(item.id) == "number" then
					local name = type(item.name) == "string" and item.name:match("^%s*(.-)%s*$") or ""
					if name == "" then name = "Emote " .. EmoteState.idStr(item.id) end
					local n = #ids + 1
					ids[n], names[n], lower[n] = item.id, name, name:lower()
				end
			end
			if #ids == 0 then error("no emotes") end
			EmoteState.ids, EmoteState.names, EmoteState.lower = ids, names, lower
		end)
		EmoteState.loading = false
		if not ok then
			EmoteState.status.Text = "Failed to load emotes"
			warn("Emote: " .. tostring(err))
			return
		end
		EmoteState.loaded = true
		EmoteState.status.Visible = false
		EmoteState.applySearch()
	end)
end

function EmoteState.init()
	local panel = Instance.new("Frame")
	panel.Name = "EmotePanel"
	panel.Position = UDim2.new(0,SIDE_W,0,32)
	panel.Size = UDim2.new(1,-SIDE_W,1,-32)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = window
	EmoteState.panel = panel

	local function styleButton(btn)
		Settings.fav.style(btn, panel)
	end

	local heading = Instance.new("TextLabel")
	heading.Name = "Heading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.new(0,0,0,4)
	heading.Size = UDim2.new(1,0,0,28)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 18
	heading.TextColor3 = Colors.white
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Text = "Emote"
	heading.Parent = panel

	local searchBox = Settings.fav.search(panel, UDim2.new(0,6,0,36), UDim2.new(1,-88,0,26), "Search emotes...")
	EmoteState.searchBox = searchBox

	local stopBtn = Instance.new("TextButton")
	stopBtn.Name = "Stop"
	stopBtn.Position = UDim2.new(1,-76,0,36)
	stopBtn.Size = UDim2.new(0,70,0,26)
	stopBtn.Text = "Stop"
	stopBtn.Parent = panel
	styleButton(stopBtn)
	stopBtn.MouseButton1Click:Connect(function() EmoteState.stop() end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "EmoteList"
	list.Position = UDim2.new(0,0,0,68)
	list.Size = UDim2.new(1,0,1,-68)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ClipsDescendants = true
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = Colors.gray90
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel
	EmoteState.list = list

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.new(0,6,0,6)
	grid.CellSize = UDim2.new(0,140,0,30)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,4)
	pad.PaddingBottom = UDim.new(0,8)
	pad.PaddingLeft = UDim.new(0,6)
	pad.PaddingRight = UDim.new(0,6)
	pad.Parent = list

	local function fit()
		local w = list.AbsoluteSize.X - 12 - 4 - 12
		grid.CellSize = UDim2.new(0, math.max(60, math.floor(w / 3)), 0, 30)
	end
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	for i = 1, EmoteState.pageSize do
		local cell, btn, star = Settings.fav.cell(list, i)
		btn.Name = "Emote"
		btn.TextWrapped = true
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		cell.Visible = false
		styleButton(btn)
		btn.MouseButton1Click:Connect(function()
			local idx = EmoteState.entryOf[btn]
			if idx then EmoteState.play(EmoteState.ids[idx], btn) end
		end)
		star.MouseButton1Click:Connect(function()
			local idx = EmoteState.entryOf[btn]
			if not idx then return end
			local key = EmoteState.idStr(EmoteState.ids[idx])
			Settings.fav.toggle("emotes", key, {id = key, name = EmoteState.names[idx]})
		end)
		EmoteState.cellOf[btn] = cell
		EmoteState.starOf[btn] = star
		table.insert(EmoteState.pool, btn)
	end

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.AnchorPoint = Vector2.new(0,0.5)
	status.Position = UDim2.new(0,0,0.5,10)
	status.Size = UDim2.new(1,0,0,24)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextColor3 = Colors.gray150
	status.Text = ""
	status.Visible = false
	status.ZIndex = 2
	status.Parent = panel
	EmoteState.status = status

	EmoteState.spacers = {}
	for i = 1, 2 do
		local sp = Instance.new("Frame")
		sp.Name = "Spacer"
		sp.LayoutOrder = EmoteState.pageSize + i
		sp.BackgroundTransparency = 1
		sp.BorderSizePixel = 0
		sp.Visible = false
		sp.Parent = list
		EmoteState.spacers[i] = sp
	end

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "Back"
	backBtn.LayoutOrder = EmoteState.pageSize + 3
	backBtn.Text = "← Back"
	backBtn.Visible = false
	backBtn.Parent = list
	styleButton(backBtn)
	EmoteState.backBtn = backBtn

	local pageBox = Instance.new("TextBox")
	pageBox.Name = "PageBox"
	pageBox.LayoutOrder = EmoteState.pageSize + 4
	pageBox.BackgroundColor3 = Colors.gray30
	pageBox.BackgroundTransparency = 0.1
	pageBox.BorderSizePixel = 0
	pageBox.Font = Enum.Font.Gotham
	pageBox.TextSize = 12
	pageBox.TextColor3 = Colors.white
	pageBox.Text = "1 / 1"
	pageBox.ClearTextOnFocus = true
	pageBox.Visible = false
	pageBox.Parent = list
	Instance.new("UICorner", pageBox).CornerRadius = UDim.new(0,4)
	EmoteState.pageBox = pageBox

	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "Next"
	nextBtn.LayoutOrder = EmoteState.pageSize + 5
	nextBtn.Text = "Next →"
	nextBtn.Visible = false
	nextBtn.Parent = list
	styleButton(nextBtn)
	EmoteState.nextBtn = nextBtn

	backBtn.MouseButton1Click:Connect(function()
		if EmoteState.loaded and EmoteState.page > 1 then
			EmoteState.page -= 1
			EmoteState.render()
		end
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if EmoteState.loaded and EmoteState.page < EmoteState.pages then
			EmoteState.page += 1
			EmoteState.render()
		end
	end)
	pageBox.FocusLost:Connect(function()
		local n = tonumber(pageBox.Text:match("%d+"))
		if n and EmoteState.loaded then EmoteState.page = n end
		if EmoteState.loaded then EmoteState.render() end
	end)

	Settings.fav.onSearch(searchBox, function()
		if EmoteState.loaded then EmoteState.applySearch() end
	end)

	Settings.link(player.CharacterAdded:Connect(function() EmoteState.stop() end))
end

EmoteState.init()

function Settings.fav.save()
	if not (writefile and makefolder and isfolder) then return end
	Settings.ensureDirs()
	local data = { anims = {}, emotes = {} }
	for _, item in ipairs(Settings.fav.sorted("anims")) do
		table.insert(data.anims, { name = item.name, items = item.items })
	end
	for _, item in ipairs(Settings.fav.sorted("emotes")) do
		table.insert(data.emotes, { id = item.id, name = item.name })
	end
	pcall(function() writefile(Settings.fav.file, HttpService:JSONEncode(data)) end)
end

function Settings.fav.load()
	if not (isfile and readfile) then return end
	local ok, exists = pcall(isfile, Settings.fav.file)
	if not (ok and exists) then return end
	local ok2, content = pcall(readfile, Settings.fav.file)
	if not ok2 then return end
	local ok3, data = pcall(function() return HttpService:JSONDecode(content) end)
	if not (ok3 and type(data) == "table") then return end
	for _, item in ipairs(data.anims or {}) do
		if type(item) == "table" and type(item.name) == "string" then
			Settings.fav.counter += 1
			Settings.fav.anims[item.name] = { name = item.name, items = item.items, order = Settings.fav.counter }
		end
	end
	for _, item in ipairs(data.emotes or {}) do
		if type(item) == "table" and type(item.id) == "string" and type(item.name) == "string" then
			Settings.fav.counter += 1
			Settings.fav.emotes[item.id] = { id = item.id, name = item.name, order = Settings.fav.counter }
		end
	end
end

function Settings.fav.repaint()
	for _, c in ipairs(AnimState.cells) do
		Settings.fav.paintStar(c.star, Settings.fav.has("anims", c.name))
	end
	for btn, star in pairs(EmoteState.starOf) do
		local idx = EmoteState.entryOf[btn]
		if idx then
			Settings.fav.paintStar(star, Settings.fav.has("emotes", EmoteState.idStr(EmoteState.ids[idx])))
		end
	end
	if Settings.fav.panel and Settings.fav.panel.Visible then Settings.fav.refresh() end
end

function Settings.fav.refresh()
	for _, section in pairs(Settings.fav.sections) do
		for _, child in ipairs(section.grid:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
	end
	Settings.fav.animBtns = {}
	Settings.fav.emoteBtns = {}

	local animItems = Settings.fav.sorted("anims")
	for i, item in ipairs(animItems) do
		local cell, btn, star = Settings.fav.cell(Settings.fav.sections.anims.grid, i)
		btn.TextWrapped = true
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Text = item.name
		Settings.fav.style(btn, Settings.fav.panel)
		local pack = { name = item.name, items = item.items }
		if not item.items then pack.map = AnimState.default end
		btn.MouseButton1Click:Connect(function() AnimState.select(pack, btn) end)
		Settings.fav.paintStar(star, true)
		star.MouseButton1Click:Connect(function() Settings.fav.toggle("anims", item.name) end)
		Settings.fav.animBtns[item.name] = btn
		Theme.mark(btn, item.name == AnimState.savedName)
	end
	Settings.fav.sections.anims.empty.Visible = #animItems == 0

	local emoteItems = Settings.fav.sorted("emotes")
	for i, item in ipairs(emoteItems) do
		local cell, btn, star = Settings.fav.cell(Settings.fav.sections.emotes.grid, i)
		btn.TextWrapped = true
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Text = item.name
		Settings.fav.style(btn, Settings.fav.panel)
		btn.MouseButton1Click:Connect(function() EmoteState.play(tonumber(item.id), btn) end)
		Settings.fav.paintStar(star, true)
		star.MouseButton1Click:Connect(function() Settings.fav.toggle("emotes", item.id) end)
		Settings.fav.emoteBtns[btn] = item.id
		Theme.mark(btn, EmoteState.playing == item.id)
	end
	Settings.fav.sections.emotes.empty.Visible = #emoteItems == 0
end

function Settings.fav.init()
	local panel = Instance.new("Frame")
	panel.Name = "FavoritesPanel"
	panel.Position = UDim2.new(0,SIDE_W,0,32)
	panel.Size = UDim2.new(1,-SIDE_W,1,-32)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = window
	Settings.fav.panel = panel

	local heading = Instance.new("TextLabel")
	heading.Name = "Heading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.new(0,0,0,4)
	heading.Size = UDim2.new(1,0,0,28)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 18
	heading.TextColor3 = Colors.white
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Text = "Favorites"
	heading.Parent = panel

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page"
	page.Position = UDim2.new(0,0,0,36)
	page.Size = UDim2.new(1,0,1,-36)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ClipsDescendants = true
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Colors.gray90
	page.CanvasSize = UDim2.new(0,0,0,0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,8)
	layout.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,4)
	pad.PaddingBottom = UDim.new(0,10)
	pad.PaddingLeft = UDim.new(0,6)
	pad.PaddingRight = UDim.new(0,10)
	pad.Parent = page

	Settings.fav.sections = {}
	local function section(key, order, iconName, title, emptyText)
		local head = Instance.new("Frame")
		head.LayoutOrder = order
		head.Size = UDim2.new(1,0,0,26)
		head.BackgroundTransparency = 1
		head.Parent = page

		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.new(0,4,0,5)
		icon.Size = UDim2.new(0,16,0,16)
		icon.Image = Settings.icon(iconName)
		icon.ImageColor3 = Colors.white
		icon.Parent = head

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0,26,0,0)
		label.Size = UDim2.new(1,-26,1,-1)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextColor3 = Colors.white
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = title
		label.Parent = head

		local line = Instance.new("Frame")
		line.Position = UDim2.new(0,0,1,-1)
		line.Size = UDim2.new(1,0,0,1)
		line.BackgroundColor3 = Colors.gray90
		line.BorderSizePixel = 0
		line.Parent = head

		local grid = Instance.new("Frame")
		grid.LayoutOrder = order + 1
		grid.Size = UDim2.new(1,0,0,0)
		grid.AutomaticSize = Enum.AutomaticSize.Y
		grid.BackgroundTransparency = 1
		grid.Parent = page
		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.CellPadding = UDim2.new(0,6,0,6)
		gridLayout.CellSize = UDim2.new(0,140,0,30)
		gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		gridLayout.Parent = grid

		local empty = Instance.new("TextLabel")
		empty.LayoutOrder = order + 2
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1,0,0,24)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
		empty.TextColor3 = Colors.gray150
		empty.Text = emptyText
		empty.Visible = false
		empty.Parent = page

		Settings.fav.sections[key] = { grid = grid, layout = gridLayout, empty = empty }
	end
	section("anims", 1, "person-standing", "Animations", "No favorite animations yet, press the star next to an animation")
	section("emotes", 4, "party-popper", "Emotes", "No favorite emotes yet, press the star next to an emote")

	local function fit()
		local w = math.max(60, math.floor((page.AbsoluteSize.X - 12 - 4 - 12) / 3))
		for _, sec in pairs(Settings.fav.sections) do
			sec.layout.CellSize = UDim2.new(0, w, 0, 30)
		end
	end
	page:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
end

Settings.fav.load()
Settings.fav.init()
Settings.fav.refresh()

Theme.bind(function()
	AnimState.markSelected()
	EmoteState.paint()
	Settings.fav.repaint()
end)

addTab("anims", tabAnims, tabAnimsUnderline, animPanel, function() AnimState.load() end)
addTab("emote", EmoteState.tab, EmoteState.tabUnderline, EmoteState.panel, function() EmoteState.load() end)
addTab("favorites", Settings.fav.tab, Settings.fav.tabUnderline, Settings.fav.panel, function() Settings.fav.refresh() end)

AnimState = AnimState
EmoteState = EmoteState

local CommandActions = {}

CommandActions.dance = function()
	local hum = getHumanoid(player.Character)
	if hum then
		local anim = Instance.new("Animation")
		anim.AnimationId = r15(player) and "rbxassetid://3333432454" or "rbxassetid://27789359"
		danceTrack = hum:LoadAnimation(anim)
		danceTrack.Looped = true; danceTrack:Play()
		Settings.keep("dance")
	end
	notify("Dance","Enabled")
end
CommandActions.undance = function()
	if danceTrack then danceTrack:Stop(); danceTrack:Destroy(); danceTrack = nil end
	notify("Dance","Stopped")
end
CommandActions.spasm = function()
	if r15(player) then notify("Spasm","Requires R6"); return end
	local hum = getHumanoid(player.Character)
	if hum then
		SpasmAnim = Instance.new("Animation")
		SpasmAnim.AnimationId = "rbxassetid://33796059"
		Spasm = hum:LoadAnimation(SpasmAnim)
		Spasm:Play(); Spasm:AdjustSpeed(99)
		Settings.keep("spasm")
	end
	notify("Spasm","Enabled")
end
CommandActions.unspasm = function()
	if Spasm then Spasm:Stop() end
	if SpasmAnim then SpasmAnim:Destroy() end
	notify("Spasm","Disabled")
end
CommandActions.noanim = function()
	local animate = player.Character and player.Character:FindFirstChild("Animate")
	if animate then animate.Disabled = true end
	notify("Animations","Disabled")
end
CommandActions.reanim = function()
	local animate = player.Character and player.Character:FindFirstChild("Animate")
	if animate then animate.Disabled = false end
	notify("Animations","Restored")
end

CommandActions.animation = function(args)
	local id = args and args[1]
	if not id then notify("Animation","Provide an asset ID"); return end
	local hum = getHumanoid(player.Character)
	if hum then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://"..id:gsub("rbxassetid://","")
		local track = hum:LoadAnimation(anim)
		track:Play()
		Settings.keep("animation", args)
	end
end

CommandActions.animspeed = function(args)
	local spd = tonumber(args and args[1]) or 1
	local hum = getHumanoid(player.Character)
	if hum then
		for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(spd) end
	end
end

CommandActions.stopanims = function()
	local hum = getHumanoid(player.Character)
	if hum then
		for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
	end
end

CommandActions.loopanim = function()
	local hum = getHumanoid(player.Character)
	if hum then
		for _,t in pairs(hum:GetPlayingAnimationTracks()) do t.Looped = true end
	end
end

CommandActions.copyanimid = function(args)
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

local _animIds = {
	armcutr6         = "33169583",
	boxesr6          = "126753849",
	faintr6          = "181526230",
	hugr6            = "185299570",
	bangr6           = "148840371",
	illusionr6       = "215384594",
	insaner6         = "33796059",
	backpackheadr6   = "68339848",
	floatingheadr6   = "121572214",
	jerkingr6        = "204292303",
	saluter15        = "10714389988",
	doggyr15         = "13694096724",
	sb3awyr15        = "10214311282",
	zombier15        = "708553116",
	flingarmsr15     = "754656200",
	dolphinr15       = "10714068222",
	sleepyr15        = "10714360343",
	hugr15           = "10714377090",
	crazyr15         = "10713957138",
	b3b3r15          = "13694096724",
}
for cmdName, animId in pairs(_animIds) do
	CommandActions[cmdName] = function()
		playAnim(animId, 0, 1, true)
		Settings.keep(cmdName)
		notify("Anim", cmdName)
	end
end
CommandActions.stopanim = function()
	stopAnimAll()
	notify("StopAnim","Done")
end

CommandActions.copyanimationid = function(args)
	CommandActions.copyanimid(args)
end

Settings.resumable = Settings.resumable or {}
Settings.resumable.dance = "undance"
Settings.resumable.spasm = "unspasm"
Settings.resumable.animation = "stopanims"
for cmdName in pairs({
	armcutr6=1, boxesr6=1, faintr6=1, hugr6=1, bangr6=1, illusionr6=1, insaner6=1,
	backpackheadr6=1, floatingheadr6=1, jerkingr6=1, saluter15=1, doggyr15=1, sb3awyr15=1,
	zombier15=1, flingarmsr15=1, dolphinr15=1, sleepyr15=1, hugr15=1, crazyr15=1, b3b3r15=1,
}) do
	Settings.resumable[cmdName] = "stopanim"
end

animCmds = CommandActions
end)();

(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")

local iyflyspeed = 1
local vehicleflyspeed = 1
local QEfly = true
local fpsConn = nil
local fpsFrames = 0
local fpsClock = tick()
local xrayEnabled = false
local _tweenSpeed = 1
local _waypoints = {}
local _flingSpeed = 99999
local _freecamRunning = false
local _freecamConn = nil
local _freecamPos = Vector3.new()
local _freecamRot = Vector2.new()
local _freecamSpeed = 1
local _hoverConn = nil
local _hoverLabel = nil
local _loopOofConn = nil
local _swimConn = nil
local _floatPart = nil
local _loopflyConn = nil
local _walkflingConn = nil
local _loopflingConn = nil
local _flashlightPart = nil
local _jailBoxes = {}
local _removeSpecificTools = {}
local _grabToolsConn = nil
local _frozenUA = {}
local _loopFBConn = nil
local _loopNoBGConn = nil
local _hiddenGUIs = {}
local _invisGUIs = {}
local _spectateConn1, _spectateConn2
local _partEspParts = {}
local _pmSpamming = {}
local _spamSpeed = 1
local _antiSiteConn = nil
local _antiJumpPower, _antiJumpHeight
local _antiJumpConn = nil
local _instantPPConn = nil
local _guideleteConn = nil
local _cflyConn = nil
local _cflySpeed = 50
local _edgejumpConn = nil
local _flyjumpConn = nil
local _antiFlingData = {}
local _antiFlingConns = {}
local _checkpoint = nil

local function r15(plr)
	local hum = getHumanoid(plr.Character)
	return hum and hum.RigType == Enum.HumanoidRigType.R15
end
local function breakVelocity()
	local zero = Vector3.new(0,0,0)
	for _, part in ipairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = zero
			part.AssemblyAngularVelocity = zero
		end
	end
end
local function sendChat(msg)
	pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local channels = TextChatService:FindFirstChild("TextChannels")
			local general = channels and channels:FindFirstChild("RBXGeneral")
			if general then general:SendAsync(msg) end
		else
			ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
		end
	end)
end
local function rejoinServer()
	if #Players:GetPlayers() <= 1 then
		player:Kick("\nRejoining...")
		task.wait(0.3)
		TeleportService:Teleport(game.PlaceId, player)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end
end
local function applyFullbright()
	Lighting.Brightness = 2; Lighting.ClockTime = 14
	Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
end
Commands = {
	{Name = "info",          Description = "Sends the target player's info as a card."},
	{Name = "noclip",        Description = "Go through objects."},
	{Name = "clip",          Description = "Disables noclip."},
	{Name = "fly",           Description = "Makes you fly. Optional speed arg."},
	{Name = "unfly",         Description = "Disables fly."},
	{Name = "speed [num]",   Description = "Change your walkspeed (default 16)."},
	{Name = "jump",          Description = "Makes your character jump."},
	{Name = "infjump",       Description = "Allows you to jump before hitting the ground."},
	{Name = "uninfjump",     Description = "Disables infinite jump."},
	{Name = "god",           Description = "Makes your character difficult to kill."},
	{Name = "invisible",     Description = "Makes you invisible to other players."},
	{Name = "visible",       Description = "Makes you visible to other players."},
	{Name = "reset",         Description = "Resets your character normally."},
	{Name = "respawn",       Description = "Respawns you."},
	{Name = "refresh",       Description = "Respawns and brings you back to the same position."},
	{Name = "sit",           Description = "Makes your character sit."},
	{Name = "spin [speed]",  Description = "Spins your character."},
	{Name = "unspin",        Description = "Disables spin."},
	{Name = "gravity [num]", Description = "Change gravity (client)."},
	{Name = "jpower [num]",  Description = "Change jump power (default 50)."},
	{Name = "drophats",      Description = "Drops your hats."},
	{Name = "nohats",        Description = "Deletes your hats."},
	{Name = "noarms",        Description = "Removes your arms."},
	{Name = "nolegs",        Description = "Removes your legs."},
	{Name = "nolimbs",       Description = "Removes all limbs."},
	{Name = "noface",        Description = "Removes your face."},
	{Name = "blockhead",     Description = "Turns your head into a block."},
	{Name = "creeper",       Description = "Makes you look like a creeper."},
	{Name = "day",           Description = "Changes the time to day (client)."},
	{Name = "night",         Description = "Changes the time to night (client)."},
	{Name = "fullbright",    Description = "Makes the map brighter (client)."},
	{Name = "nofog",         Description = "Removes fog (client)."},
	{Name = "xray",          Description = "Makes all parts transparent."},
	{Name = "unxray",        Description = "Restores transparency to all parts."},
	{Name = "esp",           Description = "Red highlight on every player's body with name and distance."},
	{Name = "noesp",         Description = "Removes ESP."},
	{Name = "dance",         Description = "Makes you dance."},
	{Name = "undance",       Description = "Stops dance animations."},
	{Name = "spasm",         Description = "Makes you spasm (R6 only)."},
	{Name = "unspasm",       Description = "Stops spasm."},
	{Name = "noanim",        Description = "Disables your animations."},
	{Name = "reanim",        Description = "Restores your animations."},
	{Name = "freeze",        Description = "Freezes your character."},
	{Name = "thaw",          Description = "Unfreezes your character."},
	{Name = "naked",         Description = "Removes your clothing (client)."},
	{Name = "stun",          Description = "Enables PlatformStand."},
	{Name = "unstun",        Description = "Disables PlatformStand."},
	{Name = "norotate",      Description = "Disables AutoRotate."},
	{Name = "autorotate",    Description = "Enables AutoRotate."},
	{Name = "breakvelocity", Description = "Sets your velocity to 0."},
	{Name = "fov [num]",       Description = "Change your camera field of view."},
	{Name = "resetfov",        Description = "Resets FOV to default (70)."},
	{Name = "sensitivity [num]", Description = "Change your mouse sensitivity."},
	{Name = "resetsensitivity", Description = "Resets mouse sensitivity to default."},
	{Name = "thirdperson",     Description = "Locks your camera to third person."},
	{Name = "firstperson",     Description = "Locks your camera to first person."},
	{Name = "resetzoom",       Description = "Restores normal camera zoom range."},
	{Name = "facecam",         Description = "Makes your character always face the camera."},
	{Name = "unfacecam",       Description = "Disables facecam."},
	{Name = "resetcamera",     Description = "Resets FOV, zoom and sensitivity at once."},
	{Name = "rainbow",         Description = "Cycles your character's colors."},
	{Name = "unrainbow",       Description = "Stops the rainbow effect."},
	{Name = "glow",            Description = "Adds a glowing light to your character."},
	{Name = "unglow",          Description = "Removes the glow effect."},
	{Name = "trail",           Description = "Attaches a trail behind your character."},
	{Name = "untrail",         Description = "Removes the trail."},
	{Name = "sparkles",        Description = "Adds sparkles to your character."},
	{Name = "unsparkles",      Description = "Removes sparkles."},
	{Name = "fire",            Description = "Sets your character on fire (visual)."},
	{Name = "unfire",          Description = "Removes the fire effect."},
	{Name = "smoke",           Description = "Adds smoke to your character."},
	{Name = "unsmoke",         Description = "Removes smoke."},
	{Name = "giant",           Description = "Scales your character up (R15 only)."},
	{Name = "tiny",            Description = "Scales your character down (R15 only)."},
	{Name = "normalsize",      Description = "Restores your normal character scale."},
	{Name = "lowgravity",      Description = "Sets gravity to a low value."},
	{Name = "highgravity",     Description = "Sets gravity to a high value."},
	{Name = "resetgravity",    Description = "Resets gravity to default (196.2)."},
	{Name = "blur",            Description = "Adds a screen blur effect (client)."},
	{Name = "unblur",          Description = "Removes the blur effect."},
	{Name = "grayscale",       Description = "Removes color from your screen (client)."},
	{Name = "resetcolor",      Description = "Restores normal screen colors."},
	{Name = "nightvision",     Description = "Applies a green night vision tint (client)."},
	{Name = "resetlighting",   Description = "Resets all lighting effects to default."},
	{Name = "music [id]",      Description = "Plays a sound id on loop for only you."},
	{Name = "stopmusic",       Description = "Stops the currently playing music."},
	{Name = "copyname",        Description = "Copies your username to the clipboard."},
	{Name = "rejoin",          Description = "Rejoins the current server."},
	{Name = "ping",            Description = "Shows your current network ping."},
	{Name = "fps",             Description = "Toggles an on-screen FPS counter."},
	{Name = "goto [player]",        Description = "Teleport to a player."},
	{Name = "walkto [player]",      Description = "Walk towards a player."},
	{Name = "unwalkto",             Description = "Stop following a player."},
	{Name = "loopgoto [player]",    Description = "Loop teleport to a player."},
	{Name = "unloopgoto",           Description = "Stop loop teleport."},
	{Name = "cbring [player]",      Description = "Bring a player to you (client)."},
	{Name = "loopbring [player]",   Description = "Loop bring a player to you."},
	{Name = "unloopbring [player]", Description = "Stop loop bring."},
	{Name = "offset [x] [y] [z]",   Description = "Offset your position by coordinates."},
	{Name = "tppos [x] [y] [z]",    Description = "Teleport to exact coordinates."},
	{Name = "thru [num]",           Description = "Teleport forward by studs."},
	{Name = "orbit [player]",       Description = "Orbit around a player."},
	{Name = "unorbit",              Description = "Stop orbiting."},
	{Name = "carpet [player]",      Description = "Lay under a player."},
	{Name = "uncarpet",             Description = "Stop carpet."},
	{Name = "headsit [player]",     Description = "Sit on a player's head."},
	{Name = "scare [player]",       Description = "Teleport in front of a player briefly."},
	{Name = "bang [player]",        Description = "Play bang animation on a player."},
	{Name = "unbang",               Description = "Stop bang."},
	{Name = "stareat [player]",     Description = "Make your character face a player."},
	{Name = "unstareat",            Description = "Stop staring."},
	{Name = "friend [player]",      Description = "Send a friend request."},
	{Name = "unfriend [player]",    Description = "Unfriend a player."},
	{Name = "locate [player]",      Description = "ESP on a single player."},
	{Name = "unlocate [player]",    Description = "Remove locate ESP."},
	{Name = "chams",                Description = "ESP without text labels."},
	{Name = "nochams",              Description = "Remove chams."},
	{Name = "hitbox [player] [size]",Description = "Expand a player's hitbox."},
	{Name = "headsize [player] [size]",Description = "Expand a player's head size."},
	{Name = "userid [player]",      Description = "Show a player's user ID."},
	{Name = "copyid [player]",      Description = "Copy a player's user ID."},
	{Name = "age [player]",         Description = "Show a player's account age."},
	{Name = "inspect [player]",     Description = "Open inspect menu for a player."},
	{Name = "chat [text]",          Description = "Send a chat message."},
	{Name = "spam [text]",          Description = "Spam the chat."},
	{Name = "unspam",               Description = "Stop spam."},
	{Name = "whisper [player] [text]",Description = "Whisper a player."},
	{Name = "anchor",               Description = "Anchor your HumanoidRootPart."},
	{Name = "unanchor",             Description = "Unanchor your HumanoidRootPart."},
	{Name = "antifling",            Description = "Disable player collisions to avoid fling."},
	{Name = "unantifling",          Description = "Re-enable player collisions."},
	{Name = "flingspin",                Description = "Spin rapidly to fling others."},
	{Name = "unflingspin",              Description = "Stop fling."},
	{Name = "loopspeed [num]",      Description = "Constantly enforce a walkspeed."},
	{Name = "unloopspeed",          Description = "Stop looping speed."},
	{Name = "loopjp [num]",         Description = "Constantly enforce a jump power."},
	{Name = "unloopjp",             Description = "Stop looping jump power."},
	{Name = "antivoid",             Description = "Launch you up when near the void."},
	{Name = "unantivoid",           Description = "Disable antivoid."},
	{Name = "walltp",               Description = "Auto-teleport over walls you run into."},
	{Name = "unwalltp",             Description = "Disable walltp."},
	{Name = "trip",                 Description = "Make your character fall over."},
	{Name = "tpwalk [num]",         Description = "Teleport in your move direction continuously."},
	{Name = "untpwalk",             Description = "Stop tpwalk."},
	{Name = "sitwalk",              Description = "Walk while sitting."},
	{Name = "nosit",                Description = "Prevent your character from sitting."},
	{Name = "unnosit",              Description = "Allow sitting again."},
	{Name = "lay",                  Description = "Make your character lay down."},
	{Name = "autojump",             Description = "Auto jump when hitting objects."},
	{Name = "unautojump",           Description = "Disable autojump."},
	{Name = "nilchar",              Description = "Set your character parent to nil."},
	{Name = "unnilchar",            Description = "Restore your character to workspace."},
	{Name = "noroot",               Description = "Delete your HumanoidRootPart."},
	{Name = "split",                Description = "Split your character in half (R15)."},
	{Name = "hatspin",              Description = "Spin your accessories."},
	{Name = "unhatspin",            Description = "Stop hat spin."},
	{Name = "blockhats",            Description = "Turn your hats into blocks."},
	{Name = "deletevelocity",       Description = "Remove all velocity and force instances."},
	{Name = "weaken [num]",         Description = "Reduce your character density."},
	{Name = "unweaken",             Description = "Restore default physical properties."},
	{Name = "strengthen [num]",     Description = "Increase your character density."},
	{Name = "spawnpoint",           Description = "Set a spawn point at your position."},
	{Name = "nospawnpoint",         Description = "Remove your custom spawn point."},
	{Name = "flashback",            Description = "Teleport to where you last died."},
	{Name = "animation [id]",       Description = "Play an animation by asset ID."},
	{Name = "animspeed [num]",      Description = "Change speed of your current animation."},
	{Name = "stopanims",            Description = "Stop all running animations."},
	{Name = "loopanim",             Description = "Loop your current animation."},
	{Name = "copyanimid [player]",  Description = "Copy another player's animation ID."},
	{Name = "btools",               Description = "Give yourself building tools (client)."},
	{Name = "gotopart [name]",      Description = "Teleport to a part by name."},
	{Name = "bringpart [name]",     Description = "Bring a part to you (client)."},
	{Name = "loopxray",             Description = "Loop xray effect."},
	{Name = "unloopxray",           Description = "Stop loop xray."},
	{Name = "removeterrain",        Description = "Clear all terrain."},
	{Name = "destroyheight [num]",  Description = "Set FallenPartsDestroyHeight."},
	{Name = "deleteclass [class]",  Description = "Delete all parts of a classname (client)."},
	{Name = "delete [name]",        Description = "Delete parts with a specific name (client)."},
	{Name = "antiafk",              Description = "Prevent idle kick."},
	{Name = "autoclick",            Description = "Automatically click your mouse."},
	{Name = "unautoclick",          Description = "Stop auto click."},
	{Name = "reach [num]",          Description = "Extend your held tool hitbox."},
	{Name = "unreach",              Description = "Remove reach."},
	{Name = "notools",              Description = "Remove all tools from backpack."},
	{Name = "droptools",            Description = "Drop all tools into workspace."},
	{Name = "equiptools",           Description = "Equip all backpack tools at once."},
	{Name = "copytools [player]",   Description = "Copy a player's tools (client)."},
	{Name = "swim",                 Description = "Swim in the air."},
	{Name = "unswim",               Description = "Stop swimming in air."},
	{Name = "cfly [speed]",         Description = "CFrame fly, bypasses some anti-cheats."},
	{Name = "uncfly",               Description = "Disable cframe fly."},
	{Name = "cflyspeed [num]",      Description = "Set cframe fly speed."},
	{Name = "float",                Description = "Spawn a platform under you to float."},
	{Name = "unfloat",              Description = "Remove the float platform."},
	{Name = "loopfly",              Description = "Re-enable fly after respawn automatically."},
	{Name = "unloopfly",            Description = "Stop loop fly."},
	{Name = "kill [player]",        Description = "Kill a player using tool damage."},
	{Name = "loopkill [player]",    Description = "Repeatedly kill a player."},
	{Name = "unloopkill",           Description = "Stop loop kill."},
	{Name = "freezeplr [player]",   Description = "Freeze a player in place (client)."},
	{Name = "unfreezeplr [player]", Description = "Unfreeze a player."},
	{Name = "bring [player]",       Description = "Bring a player instantly to you (client)."},
	{Name = "tp [player]",          Description = "Teleport to a player instantly."},
	{Name = "jail [player]",        Description = "Trap a player in a box (client)."},
	{Name = "unjail [player]",      Description = "Remove a player's jail box."},
	{Name = "loopfreeze [player]",  Description = "Constantly freeze a player."},
	{Name = "unloopfreeze",         Description = "Stop loop freeze."},
	{Name = "fog [num]",            Description = "Set fog end distance."},
	{Name = "unfog",                Description = "Remove fog effect."},
	{Name = "ambient [r] [g] [b]",  Description = "Set lighting ambient color (0-255)."},
	{Name = "shadow",               Description = "Enable global shadows."},
	{Name = "unshadow",             Description = "Disable global shadows."},
	{Name = "time [num]",           Description = "Set the clock time (0-24)."},
	{Name = "noatmosphere",         Description = "Remove atmosphere instances."},
	{Name = "flashlight",           Description = "Toggle a point light on your character."},
	{Name = "unflashlight",         Description = "Remove the flashlight."},
	{Name = "brightness [num]",     Description = "Set lighting brightness."},
	{Name = "serverinfo",           Description = "Show server and place info."},
	{Name = "players",              Description = "List all players in the server."},
	{Name = "copypos",              Description = "Copy your current position to clipboard."},
	{Name = "notifypos",            Description = "Notify your current position."},
	{Name = "f3x",                  Description = "Load F3X building tools."},
	{Name = "firecd [name]",        Description = "Fire all click detectors (optional name)."},
	{Name = "firepp [name]",        Description = "Fire all proximity prompts (optional name)."},
	{Name = "nocdlimits",           Description = "Set all click detector max distance to max."},
	{Name = "nopplimits",           Description = "Set all proximity prompt max distance to max."},
	{Name = "lockws",               Description = "Lock all workspace parts."},
	{Name = "unlockws",             Description = "Unlock all workspace parts."},
	{Name = "savepos [name]",       Description = "Save your current position as a waypoint."},
	{Name = "loadpos [name]",       Description = "Teleport to a saved waypoint by name."},
	{Name = "deletepos [name]",     Description = "Delete a saved waypoint."},
	{Name = "listpos",              Description = "List all saved waypoints."},
	{Name = "clearpos",             Description = "Clear all saved waypoints."},
	{Name = "dex",                  Description = "Load Dex explorer."},
	{Name = "remotespy",            Description = "Load remote spy (Cobalt)."},
	{Name = "console",              Description = "Open the Roblox developer console."},
	{Name = "antilag",              Description = "Lower graphics to boost FPS."},
	{Name = "serverhop",            Description = "Jump to a different server."},
	{Name = "placeid",              Description = "Copy the current place ID."},
	{Name = "gameid",               Description = "Copy the current game ID."},
	{Name = "maxzoom [num]",        Description = "Set max camera zoom distance."},
	{Name = "minzoom [num]",        Description = "Set min camera zoom distance."},
	{Name = "lookat [player]",      Description = "Rotate camera toward a player."},
	{Name = "camdistance [num]",    Description = "Set camera distance from your character."},
	{Name = "toggleflingspin",         Description = "Toggle fling on/off."},
	{Name = "flyfling [speed]",    Description = "Vehicle fly + walkfling combined."},
	{Name = "unflyfling",          Description = "Disable flyfling."},
	{Name = "walkfling",           Description = "Fling without spinning (walk-based)."},
	{Name = "unwalkfling",         Description = "Disable walkfling."},
	{Name = "invisfling",          Description = "Invisible fling using character swap."},
	{Name = "toggleantifling",     Description = "Toggle antifling on/off."},
	{Name = "strengthenflingspin",     Description = "Max density then fling."},
	{Name = "weakenflingspin",         Description = "Zero density then fling for bigger sends."},
	{Name = "noclipflingspin",         Description = "Enable noclip then fling."},
	{Name = "loopflingspin",           Description = "Constantly re-enable fling after dying."},
	{Name = "unloopflingspin",         Description = "Stop loop fling."},
	{Name = "flingspinspeed [num]",    Description = "Set the fling angular velocity speed."},
	{Name = "freecam",             Description = "Enable free camera movement."},
	{Name = "unfreecam",           Description = "Disable free camera."},
	{Name = "fcspeed [num]",       Description = "Set freecam movement speed."},
	{Name = "fcpos [x] [y] [z]",   Description = "Open freecam at specific coordinates."},
	{Name = "fcgoto [player]",     Description = "Open freecam at a player's position."},
	{Name = "notifyfcpos",         Description = "Notify your freecam coordinates."},
	{Name = "copyfcpos",           Description = "Copy freecam coordinates to clipboard."},
	{Name = "gotocam",             Description = "Teleport to your camera's position."},
	{Name = "volume [0-10]",       Description = "Set game volume (0-10)."},
	{Name = "norender",            Description = "Disable 3D rendering to save CPU."},
	{Name = "render",              Description = "Re-enable 3D rendering."},
	{Name = "mousesensitivity [num]", Description = "Set mouse sensitivity (default 1)."},
	{Name = "hovername",           Description = "Show player name when hovering over them."},
	{Name = "unhovername",         Description = "Disable hover name."},
	{Name = "loopoof",             Description = "Loop everyone's character death sound."},
	{Name = "unloopoof",           Description = "Stop loop oof."},
	{Name = "muteboombox [player]",Description = "Mute a player's boombox."},
	{Name = "unmuteboombox [player]",Description = "Unmute a player's boombox."},
	{Name = "tweengoto [player]",   Description = "Tween to a player smoothly."},
	{Name = "tweenspeed [num]",     Description = "Set tween movement speed (default 1)."},
	{Name = "tweenpos [x] [y] [z]", Description = "Tween to coordinates smoothly."},
	{Name = "tweenoffset [x][y][z]",Description = "Tween offset from current position."},
	{Name = "tweengotopart [name]", Description = "Tween to a part by name."},
	{Name = "tweengotomodel [name]",Description = "Tween to a model by name."},
	{Name = "tweenwp [name]",       Description = "Tween to a saved waypoint."},
	{Name = "tweengotocam",         Description = "Tween to your camera position."},
	{Name = "pulsetp [player] [s]", Description = "TP to player for X seconds then return."},
	{Name = "spamspeed [num]",      Description = "Set chat spam speed (default 1s)."},
	{Name = "pmspam [player] [msg]",Description = "Spam whisper a player."},
	{Name = "unpmspam [player]",    Description = "Stop whisper spam."},
	{Name = "darkchat",             Description = "Make chat window dark themed."},
	{Name = "bubblechat",           Description = "Enable bubble chat."},
	{Name = "unbubblechat",         Description = "Disable bubble chat."},
	{Name = "chatwindow",           Description = "Enable the chat window."},
	{Name = "unchatwindow",         Description = "Disable the chat window."},
	{Name = "listento [player]",    Description = "Listen to audio around a player."},
	{Name = "unlistento",           Description = "Stop listening to player area."},
	{Name = "muteallvcs",           Description = "Mute voice chat for all players."},
	{Name = "unmuteallvcs",         Description = "Unmute voice chat for all players."},
	{Name = "mutevc [player]",      Description = "Mute a player's voice chat."},
	{Name = "unmutevc [player]",    Description = "Unmute a player's voice chat."},
	{Name = "espteam",              Description = "ESP with team colors (green/red)."},
	{Name = "esptransparency [n]",  Description = "Set ESP box transparency."},
	{Name = "partesp [name]",       Description = "Highlight parts by name."},
	{Name = "unpartesp [name]",     Description = "Remove part ESP."},
	{Name = "hitboxes",             Description = "Show all bounding boxes in workspace."},
	{Name = "unhitboxes",           Description = "Hide all bounding boxes."},
	{Name = "rolewatch [id] [role]",Description = "Notify if a group role joins the server."},
	{Name = "unrolewatch",          Description = "Disable rolewatch."},
	{Name = "staffwatch",           Description = "Notify if a staff member joins."},
	{Name = "unstaffwatch",         Description = "Disable staffwatch."},
	{Name = "findfriendgroups",     Description = "Find players who are friends with each other."},
	{Name = "joindate [player]",    Description = "Show the date a player joined Roblox."},
	{Name = "chatjoindate [player]",Description = "Chat the join date of a player."},
	{Name = "chatage [player]",     Description = "Chat the account age of a player."},
	{Name = "copyname [player]",    Description = "Copy a player's username to clipboard."},
	{Name = "appearanceid [player]",Description = "Show a player's appearance ID."},
	{Name = "copyappearanceid [p]", Description = "Copy a player's appearance ID."},
	{Name = "enablestate [state]",  Description = "Enable a humanoid state type."},
	{Name = "disablestate [state]", Description = "Disable a humanoid state type."},
	{Name = "hipheight [num]",      Description = "Adjust your hip height."},
	{Name = "maxslopeangle [num]",  Description = "Set max slope angle."},
	{Name = "platformstand",        Description = "Enable PlatformStand state."},
	{Name = "unplatformstand",      Description = "Disable PlatformStand state."},
	{Name = "edgejump",             Description = "Auto jump at edges of platforms."},
	{Name = "unedgejump",           Description = "Disable edgejump."},
	{Name = "flyjump",              Description = "Hold space to fly upward."},
	{Name = "unflyjump",            Description = "Disable flyjump."},
	{Name = "tpunanchored [player]",Description = "Teleport unanchored parts to a player."},
	{Name = "freezeunanchored",     Description = "Freeze all unanchored parts."},
	{Name = "thawunanchored",       Description = "Thaw all frozen unanchored parts."},
	{Name = "clearcharappearance",  Description = "Remove accessories shirt pants bodycolors."},
	{Name = "noclipcam",            Description = "Allow camera to go through walls."},
	{Name = "firstp",               Description = "Force camera to first person."},
	{Name = "thirdp",               Description = "Allow camera to third person."},
	{Name = "enableshiftlock",      Description = "Enable shift lock option."},
	{Name = "fixcam",               Description = "Reset camera to normal state."},
	{Name = "dupetools [num]",      Description = "Duplicate your tools N times."},
	{Name = "usetools [n] [delay]", Description = "Activate all backpack tools at once."},
	{Name = "droppabletools",       Description = "Make all tools droppable."},
	{Name = "removespecifictool [n]",Description = "Auto-remove a specific tool from backpack."},
	{Name = "unremovespecifictool [n]",Description = "Stop removing a specific tool."},
	{Name = "clearremovetools",     Description = "Stop removing all specific tools."},
	{Name = "grippos [x] [y] [z]",  Description = "Change current tool grip position."},
	{Name = "boxreach [num]",       Description = "Box-shaped reach on held tool."},
	{Name = "grabtools",            Description = "Auto-grab dropped tools."},
	{Name = "ungrabtools",          Description = "Stop auto-grabbing tools."},
	{Name = "gotomodel [name]",     Description = "Teleport to a model by name."},
	{Name = "gotopartclass [class]",Description = "Teleport to a part by classname."},
	{Name = "bringpartclass [class]",Description = "Bring all parts of a classname to you."},
	{Name = "gotopartdelay [num]",  Description = "Set delay between gotopart teleports."},
	{Name = "invisibleparts",       Description = "Show invisible parts."},
	{Name = "uninvisibleparts",     Description = "Restore invisible parts."},
	{Name = "deleteinvisparts",     Description = "Delete all invisible parts."},
	{Name = "clearnilinstances",    Description = "Destroy all nil instances."},
	{Name = "fakeout",              Description = "TP to void then back (detaches clingers)."},
	{Name = "headthrow",            Description = "Throw your head (R6)."},
	{Name = "copyanimation [player]",Description = "Copy another player's current animation."},
	{Name = "refreshanimations",    Description = "Refresh your character animations."},
	{Name = "allowcustomanim",      Description = "Allow custom animation packs."},
	{Name = "unallowcustomanim",    Description = "Disallow custom animation packs."},
	{Name = "noprompts",            Description = "Block purchase and premium prompts."},
	{Name = "showprompts",          Description = "Allow purchase prompts again."},
	{Name = "removeads",            Description = "Auto-remove ad billboards."},
	{Name = "unremoveads",          Description = "Stop removing ad billboards."},
	{Name = "datalimit [num]",      Description = "Set outgoing KBPS limit."},
	{Name = "replicationlag [num]", Description = "Set IncomingReplicationLag."},
	{Name = "antikick",             Description = "Prevent localscripts from kicking you."},
	{Name = "antiteleport",         Description = "Prevent localscripts from teleporting you."},
	{Name = "cancelteleport",       Description = "Cancel a teleport in progress."},
	{Name = "gametp [placeid]",     Description = "Teleport to a game by place ID."},
	{Name = "autorj",               Description = "Auto rejoin if kicked or disconnected."},
	{Name = "clearerror",           Description = "Clear the kick error screen."},
	{Name = "antigameplaypaused",   Description = "Remove the gameplay paused overlay."},
	{Name = "use2022materials",     Description = "Enable 2022 material textures."},
	{Name = "unuse2022materials",   Description = "Disable 2022 material textures."},
	{Name = "breakloops",           Description = "Stop all running command loops."},
	{Name = "addalias [cmd] [a]",   Description = "Add an alias to a command."},
	{Name = "removealias [alias]",  Description = "Remove a custom alias."},
	{Name = "clraliases",           Description = "Clear all custom aliases."},
	{Name = "alignmentkeys",        Description = "Enable alignment keys (comma/period)."},
	{Name = "unalignmentkeys",      Description = "Disable alignment keys."},
	{Name = "antiidle",             Description = "Prevent idle kick."},
	{Name = "audiologger",          Description = "Open audio logger."},
	{Name = "autokeypress [k][d]",  Description = "Auto press a key with delay."},
	{Name = "unautokeypress",       Description = "Stop auto key press."},
	{Name = "autorejoin",           Description = "Auto rejoin on disconnect."},
	{Name = "blocktool",            Description = "Turn held tool into a block."},
	{Name = "cframefly [speed]",    Description = "CFrame fly (works on mobile)."},
	{Name = "uncframefly",          Description = "Disable CFrame fly."},
	{Name = "cframeflyspeed [n]",   Description = "Set CFrame fly speed."},
	{Name = "chardelete [name]",    Description = "Delete part by name from character."},
	{Name = "chardeleteclass [c]",  Description = "Delete parts by classname from character."},
	{Name = "cleargamewaypoints",   Description = "Clear waypoints for this game."},
	{Name = "clearhats",            Description = "Clear hats in workspace."},
	{Name = "clearremovespecifictool",Description = "Stop removing all specific tools."},
	{Name = "clearwaypoints",       Description = "Clear all saved waypoints."},
	{Name = "clickdelete", Description = "Toggle: hold Alt and click a part to delete it (client)."},
	{Name = "clickteleport", Description = "Toggle: hold Ctrl and click to teleport."},
	{Name = "clientbring [player]", Description = "Bring a player to you (client)."},
	{Name = "copyanimationid [p]",  Description = "Copy animation ID to clipboard."},
	{Name = "copycreatorid",        Description = "Copy the game creator ID."},
	{Name = "copygameid",           Description = "Copy the game ID."},
	{Name = "copyplaceid",          Description = "Copy the place ID."},
	{Name = "copyposition [p]",     Description = "Copy a player's position."},
	{Name = "copyuserid [player]",  Description = "Copy a player's user ID."},
	{Name = "creatorid",            Description = "Notify the game creator ID."},
	{Name = "ctrllock",             Description = "Bind shift lock to LeftControl."},
	{Name = "unctrllock",           Description = "Re-bind shift lock to LeftShift."},
	{Name = "deleteselectedtool",   Description = "Remove currently equipped tool."},
	{Name = "deletewaypoint [n]",   Description = "Delete a waypoint by name."},
	{Name = "disable [item]",       Description = "Disable a CoreGui item."},
	{Name = "enable [item]",        Description = "Enable a CoreGui item."},
	{Name = "discord",              Description = "Copy Discord invite link."},
	{Name = "emote [id]",           Description = "Play an emote by asset ID."},
	{Name = "exit",                 Description = "Exit the game."},
	{Name = "explorer",             Description = "Open Dex++ explorer."},
	{Name = "fireclickdetectors [n]",Description = "Fire all click detectors."},
	{Name = "fireproximityprompts [n]",Description = "Fire all proximity prompts."},
	{Name = "firetouchinterests [n]",Description = "Fire all touch interests."},
	{Name = "flyspeed [num]",       Description = "Set fly speed."},
	{Name = "freecamgoto [player]", Description = "Move freecam to a player."},
	{Name = "freecampos [x][y][z]", Description = "Open freecam at coordinates."},
	{Name = "freecamspeed [num]",   Description = "Set freecam speed."},
	{Name = "freecamwaypoint [n]",  Description = "Move freecam to a waypoint."},
	{Name = "gameteleport [id]",    Description = "Teleport to a game by place ID."},
	{Name = "globalshadows",        Description = "Enable global shadows."},
	{Name = "noglobalshadows",      Description = "Disable global shadows."},
	{Name = "gotocamera",           Description = "Teleport to your camera position."},
	{Name = "guidelete",            Description = "Enable backspace to delete GUIs."},
	{Name = "unguidelete",          Description = "Disable GUI delete."},
	{Name = "guiscale [num]",       Description = "Change GUI scale (0.85-2)."},
	{Name = "handlekill [player]",  Description = "Kill with tool damage (needs tool)."},
	{Name = "hideguis",             Description = "Hide all PlayerGui GUIs."},
	{Name = "unhideguis",           Description = "Restore hidden GUIs."},
	{Name = "hideiy",               Description = "Hide the DevX console."},
	{Name = "showiy",               Description = "Show the DevX console."},
	{Name = "hidewaypoints",        Description = "Hide waypoint markers in workspace."},
	{Name = "showwaypoints",        Description = "Show waypoint markers in workspace."},
	{Name = "infinitejump",         Description = "Allow jumping before landing."},
	{Name = "uninfinitejump",       Description = "Disable infinite jump."},
	{Name = "instantproximityprompts",Description = "Instantly fire proximity prompts on hold."},
	{Name = "uninstantproximityprompts",Description = "Undo instant proximity prompts."},
	{Name = "inviteprompt", Description = "Open the game invite prompt."},
	{Name = "jobid",                Description = "Copy the server Job ID."},
	{Name = "jumppower [num]",      Description = "Set jump power (default 50)."},
	{Name = "lastcommand",          Description = "Re-run the last command used."},
	{Name = "light [range] [b]",    Description = "Add point light to your character."},
	{Name = "nolight",              Description = "Remove point light from character."},
	{Name = "logs", Description = "Open the Logs tab."},
	{Name = "loopanimation",        Description = "Loop your current animation."},
	{Name = "loopfullbright",       Description = "Loop fullbright effect."},
	{Name = "unloopfullbright",     Description = "Stop loop fullbright."},
	{Name = "loopjumppower [n]",    Description = "Constantly enforce jump power."},
	{Name = "unloopjumppower",      Description = "Stop loop jump power."},
	{Name = "loopnobgui",           Description = "Constantly remove billboard GUIs."},
	{Name = "unloopnobgui",         Description = "Stop loop no billboard GUI."},
	{Name = "moondex",              Description = "Open Moon's DEX explorer."},
	{Name = "mouseteleport",        Description = "Teleport to your mouse position."},
	{Name = "muteallvoices",        Description = "Mute voice chat for all players."},
	{Name = "unmuteallvoices",      Description = "Unmute all voice chat."},
	{Name = "nobillboardgui",       Description = "Remove billboard GUIs from character."},
	{Name = "noclickdetectorlimits",Description = "Set all click detectors to max range."},
	{Name = "noproximitypromptlimits",Description = "Set all proximity prompts to max range."},
	{Name = "notify [text]",        Description = "Send yourself a notification."},
	{Name = "notifyfreecamposition",Description = "Notify your freecam coordinates."},
	{Name = "notifyjobid",          Description = "Notify the server Job ID."},
	{Name = "notifyping",           Description = "Notify your current ping."},
	{Name = "notifyposition [p]",   Description = "Notify a player's coordinates."},
	{Name = "nowalltp",             Description = "Disable walltp."},
	{Name = "oldconsole",           Description = "Load old-themed Roblox console."},
	{Name = "partname", Description = "Click a part to copy its full path."},
	{Name = "pathfindwalkto [p]",   Description = "Walk to a player using pathfinding."},
	{Name = "pathfindwalktowp [n]", Description = "Walk to a waypoint using pathfinding."},
	{Name = "phonebook",            Description = "Open Roblox phonebook to call friends."},
	{Name = "promptr15",            Description = "Prompt game to switch rig to R15."},
	{Name = "promptr6",             Description = "Prompt game to switch rig to R6."},
	{Name = "qefly [true/false]",   Description = "Enable/disable Q and E hotkeys for fly."},
	{Name = "removecmd [name]",     Description = "Remove a command until script reload."},
	{Name = "replaceroot",          Description = "Replace your HumanoidRootPart."},
	{Name = "restorelighting",      Description = "Restore lighting to original state."},
	{Name = "rolewatchleave",       Description = "Toggle leaving when rolewatch triggers."},
	{Name = "rolewatchstop",        Description = "Stop rolewatch."},
	{Name = "savegame",             Description = "Save the game instance locally."},
	{Name = "screenshot",           Description = "Take a screenshot."},
	{Name = "setcreatorid",         Description = "Set your UserId to creator's ID."},
	{Name = "setwaypoint [name]",   Description = "Save current position as waypoint."},
	{Name = "showguis",             Description = "Make all invisible GUIs visible."},
	{Name = "unshowguis",           Description = "Undo showguis."},
	{Name = "simplespy",            Description = "Load Simple Spy remote spy."},
	{Name = "spectate [player]",    Description = "Spectate a player's camera."},
	{Name = "unspectate",           Description = "Stop spectating."},
	{Name = "viewpart [name]",      Description = "Set camera subject to a part."},
	{Name = "spoofjumppower [n]",   Description = "Spoof jump power client-side."},
	{Name = "spoofspeed [num]",     Description = "Spoof walk speed client-side."},
	{Name = "stopanimations",       Description = "Stop all playing animations."},
	{Name = "team [name]",          Description = "Change your team (client-side)."},
	{Name = "teleporttool",         Description = "Give yourself a teleport tool."},
	{Name = "togglefs",             Description = "Toggle fullscreen."},
	{Name = "toggleswim",           Description = "Toggle swim in air."},
	{Name = "togglexray",           Description = "Toggle xray on/off."},
	{Name = "toolinvisible",        Description = "Go invisible while keeping tool use."},
	{Name = "tools",                Description = "Copy tools from ReplicatedStorage."},
	{Name = "tpposition [x][y][z]", Description = "Teleport to exact coordinates."},
	{Name = "tweengotocamera",      Description = "Tween to your camera position."},
	{Name = "tweengotopartclass [c]",Description = "Tween to a part by classname."},
	{Name = "tweentpposition [xyz]",Description = "Tween to exact coordinates."},
	{Name = "tweenwaypoint [n]",    Description = "Tween to a waypoint."},
	{Name = "unvehiclefly",         Description = "Disable vehicle fly."},
	{Name = "vehicleclip",          Description = "Re-enable vehicle collision."},
	{Name = "vehiclefly [speed]",   Description = "Fly while in a vehicle."},
	{Name = "vehicleflyspeed [n]",  Description = "Set vehicle fly speed."},
	{Name = "vehiclegoto [player]", Description = "Go to a player while in vehicle."},
	{Name = "vehiclenoclip",        Description = "Disable vehicle collision."},
	{Name = "walktoposition [xyz]", Description = "Walk to coordinates."},
	{Name = "walktowaypoint [n]",   Description = "Walk to a waypoint."},
	{Name = "wallwalk",             Description = "Walk on walls."},
	{Name = "waypoint [name]",      Description = "Teleport to a waypoint."},
	{Name = "waypointpos [n][xyz]", Description = "Set waypoint at specific coordinates."},
	{Name = "waypoints",            Description = "Open waypoints panel."},
	{Name = "fling [player] [sec]",  Description = "Strong fling on a player. Stops once he is flung and returns you."},
	{Name = "unfling",              Description = "Stop the fling."},
	{Name = "jerkontarget [player]",Description = "Jerk animation on a target player."},
	{Name = "unjerkontarget",       Description = "Stop jerk on target."},
	{Name = "bangontarget [player]",Description = "Bang animation on a target player (advanced method)."},
	{Name = "unbangontarget",       Description = "Stop bang on target."},
	{Name = "reversebang [player]", Description = "Reverse bang – you sit, target moves behind."},
	{Name = "unreversebang",        Description = "Stop reverse bang."},
	{Name = "suck [player]",        Description = "Sucking animation on a target."},
	{Name = "unsuck",               Description = "Stop suck."},
	{Name = "backpack [player]",    Description = "Sit behind a target with backpack position."},
	{Name = "unbackpack",           Description = "Stop backpack."},
	{Name = "antisite",             Description = "Anti-sit – prevent your character from sitting."},
	{Name = "unantisite",           Description = "Disable anti-sit."},
	{Name = "antijump",             Description = "Anti-jump – set jump power to 0."},
	{Name = "unantijump",           Description = "Restore jump power."},
	{Name = "antivoid2",          Description = "Set FallenPartsDestroyHeight to NaN (anti void advanced method)."},
	{Name = "unantivoid2",        Description = "Restore FallenPartsDestroyHeight."},
	{Name = "antiafk2",           Description = "Use VirtualUser to prevent AFK kick."},
	{Name = "unantiafk2",         Description = "Stop virtual user anti AFK."},
	{Name = "antibang",          Description = "Detect and counter bang attempts."},
	{Name = "unantibang",        Description = "Disable anti bang."},
	{Name = "antifling2",         Description = "Remove collision from all players to prevent fling."},
	{Name = "unantifling2",       Description = "Restore collision for all players."},
	{Name = "armcutr6",             Description = "Play arm cut animation (R6)."},
	{Name = "boxesr6",              Description = "Play boxing animation (R6)."},
	{Name = "faintr6",              Description = "Play faint/sleep animation (R6)."},
	{Name = "hugr6",                Description = "Play hug animation (R6)."},
	{Name = "bangr6",               Description = "Play bang animation (R6)."},
	{Name = "illusionr6",           Description = "Play illusion/flash animation (R6)."},
	{Name = "insaner6",             Description = "Play insane animation (R6)."},
	{Name = "backpackheadr6",       Description = "Play backpack head animation (R6)."},
	{Name = "floatingheadr6",       Description = "Play floating head animation (R6)."},
	{Name = "jerkingr6",            Description = "Play jerking animation (R6)."},
	{Name = "saluter15",            Description = "Play salute animation (R15)."},
	{Name = "doggyr15",             Description = "Play doggy animation (R15)."},
	{Name = "sb3awyr15",            Description = "Play sba3wy animation (R15)."},
	{Name = "zombier15",            Description = "Play zombie walk animation (R15)."},
	{Name = "flingarmsr15",         Description = "Play fling arms/latm animation (R15)."},
	{Name = "dolphinr15",           Description = "Play dolphin animation (R15)."},
	{Name = "sleepyr15",            Description = "Play sleepy animation (R15)."},
	{Name = "hugr15",               Description = "Play hug animation (R15)."},
	{Name = "crazyr15",             Description = "Play crazy/mkhbl animation (R15)."},
	{Name = "b3b3r15",              Description = "Play b3b3 animation (R15)."},
	{Name = "stopanim",             Description = "Stop all playing animations."},
	{Name = "checkpointsave",       Description = "Save your current position as checkpoint."},
	{Name = "checkpointload",       Description = "Teleport to your saved checkpoint."},
	{Name = "predictiontp [player]",Description = "Teleport to predicted position of a moving player."},
}
local FLYING = false
local flyKeyDown, flyKeyUp
local Noclipping = nil
local Clip = true
local NoclipParts = {}
local function sFLY(vfly)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local T   = getRoot(char)
	if vfly then T = hum and hum.SeatPart end
	if not T then return end
	local function flySpeed() return vfly and vehicleflyspeed or iyflyspeed end

	if flyKeyDown then flyKeyDown:Disconnect() end
	if flyKeyUp   then flyKeyUp:Disconnect()   end

	local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
	local SPEED = 0

	FLYING = true
	local BG = Instance.new("BodyGyro")
	local BV = Instance.new("BodyVelocity")
	BG.P = 9e4; BG.Parent = T
	BV.Parent = T
	BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	BG.CFrame = T.CFrame
	BV.Velocity = Vector3.new(0,0,0)
	BV.MaxForce = Vector3.new(9e9,9e9,9e9)

	task.spawn(function()
		repeat task.wait()
			local cam = workspace.CurrentCamera
			if hum and not vfly then hum.PlatformStand = true end
			if (CONTROL.L+CONTROL.R)~=0 or (CONTROL.F+CONTROL.B)~=0 or (CONTROL.Q+CONTROL.E)~=0 then
				SPEED = 50
			else
				SPEED = 0
			end
			if SPEED ~= 0 then
				BV.Velocity = ((cam.CFrame.LookVector*(CONTROL.F+CONTROL.B)) + ((cam.CFrame*CFrame.new(CONTROL.L+CONTROL.R,(CONTROL.F+CONTROL.B+CONTROL.Q+CONTROL.E)*0.2,0).p)-cam.CFrame.p))*SPEED
			else
				BV.Velocity = Vector3.new(0,0,0)
			end
			BG.CFrame = cam.CFrame
		until not FLYING
		BG:Destroy(); BV:Destroy()
		if hum and not vfly then hum.PlatformStand = false end
	end)

	flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = flySpeed()
		elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -flySpeed()
		elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -flySpeed()
		elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = flySpeed()
		elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = flySpeed()*2
		elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = -flySpeed()*2
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
	if flyKeyUp   then flyKeyUp:Disconnect()   end
	if getHumanoid(player.Character) then
		player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
	end
	pcall(function() camera.CameraType = Enum.CameraType.Custom end)
end
local function xray()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
			v.LocalTransparencyModifier = xrayEnabled and 0.6 or 0
		end
	end
end
local facecamLoop, rainbowLoop, musicSound
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
CommandActions = {
	info = function()
		local t = Settings.target or player
		local joined = targetCreated and targetCreated.Text or "Joined: —"
		notify(t.DisplayName.." (@"..t.Name..")", "ID: "..tostring(t.UserId).." | "..joined)
	end,
	noclip = function()
		pcall(function() Noclipping:Disconnect() end)
		Clip = false; NoclipParts = {}
		Noclipping = RunService.Stepped:Connect(function()
			if player.Character then
				for _,child in pairs(player.Character:GetDescendants()) do
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
		if getgenv().infJump then getgenv().infJump:Disconnect() end
		getgenv().infJump = UserInputService.JumpRequest:Connect(function()
			local hum = getHumanoid(player.Character)
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
		notify("Infinite Jump","Enabled")
	end,
	uninfjump = function()
		if getgenv().infJump then getgenv().infJump:Disconnect() end
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
		for _,v in pairs(root:GetChildren()) do if v.Name=="Spinning" then v:Destroy() end end
		local bav = Instance.new("BodyAngularVelocity")
		bav.Name = "Spinning"; bav.Parent = root
		bav.MaxTorque = Vector3.new(0,math.huge,0)
		bav.AngularVelocity = Vector3.new(0,spd,0)
		notify("Spin","Enabled at speed "..spd)
	end,
	unspin = function()
		local root = getRoot(player.Character)
		if not root then return end
		for _,v in pairs(root:GetChildren()) do if v.Name=="Spinning" then v:Destroy() end end
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
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.Anchored = true end
			end
		end
		notify("Freeze","Enabled")
	end,
	thaw = function()
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
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
		if getgenv().devxInvisRunning then return end
		getgenv().devxInvisRunning = true
		local char = player.Character
		if not char then return end
		char.Archivable = true
		local invisChar = char:Clone()
		invisChar.Parent = Lighting
		for _,v in pairs(invisChar:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = v.Name=="HumanoidRootPart" and 1 or 0.5
			end
		end
		local void = workspace.FallenPartsDestroyHeight
		local cf = getRoot(char) and getRoot(char).CFrame
		char:MoveTo(Vector3.new(0,void+1000,0))
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		task.wait(0.2)
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		char.Parent = Lighting
		invisChar.Parent = workspace
		local newRoot = invisChar:FindFirstChild("HumanoidRootPart")
		if cf and newRoot then newRoot:PivotTo(cf) end
		player.Character = invisChar
		workspace.CurrentCamera.CameraSubject = invisChar:FindFirstChildOfClass("Humanoid")
		invisChar.Animate.Disabled = true
		invisChar.Animate.Disabled = false
		getgenv().devxInvisChar = invisChar
		getgenv().devxRealChar = char
		notify("Invisible","Enabled")
	end,
	visible = function()
		if not getgenv().devxInvisRunning then return end
		local invisChar = getgenv().devxInvisChar
		local char = getgenv().devxRealChar
		if not invisChar or not char then getgenv().devxInvisRunning=false; return end
		local cf = getRoot(invisChar) and getRoot(invisChar).CFrame
		player.Character = char
		char.Parent = workspace
		if cf then pcall(function() char.HumanoidRootPart:PivotTo(cf) end) end
		workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
		invisChar:Destroy()
		char.Animate.Disabled = true
		char.Animate.Disabled = false
		getgenv().devxInvisRunning = false
		getgenv().devxInvisChar = nil
		getgenv().devxRealChar = nil
		notify("Invisible","Disabled")
	end,
	drophats = function()
		local hum = getHumanoid(player.Character)
		if hum then
			for _,v in pairs(hum:GetAccessories()) do v.Parent = workspace end
		end
		notify("Hats","Dropped")
	end,
	nohats = function()
		local hum = getHumanoid(player.Character)
		if hum then
			for _,v in pairs(hum:GetAccessories()) do v:Destroy() end
		end
		notify("Hats","Deleted")
	end,
	noarms = function()
		if not player.Character then return end
		if r15(player) then
			for _,v in pairs(player.Character:GetChildren()) do
				if v:IsA("BasePart") and (v.Name=="RightUpperArm" or v.Name=="LeftUpperArm") then v:Destroy() end
			end
		else
			for _,v in pairs(player.Character:GetChildren()) do
				if v:IsA("BasePart") and (v.Name=="Right Arm" or v.Name=="Left Arm") then v:Destroy() end
			end
		end
		notify("Body","Arms removed")
	end,
	nolegs = function()
		if not player.Character then return end
		if r15(player) then
			for _,v in pairs(player.Character:GetChildren()) do
				if v:IsA("BasePart") and (v.Name=="RightUpperLeg" or v.Name=="LeftUpperLeg") then v:Destroy() end
			end
		else
			for _,v in pairs(player.Character:GetChildren()) do
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
			for _,v in pairs(player.Character:GetDescendants()) do
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
			for _,v in pairs(player.Character:GetDescendants()) do
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
		applyFullbright()
		notify("Fullbright","Enabled")
	end,
	nofog = function()
		Lighting.FogEnd = 100000
		for _,v in pairs(Lighting:GetDescendants()) do
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
		Settings.esp.enable(false)
		notify("ESP","Enabled")
	end,
	noesp = function()
		Settings.esp.disable()
		notify("ESP","Disabled")
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
				for _,v in pairs(player.Character:GetDescendants()) do
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
			light.Color = Theme.accent
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
			top.Name = "DevXTrailTop"; top.Position = Vector3.new(0,1,0); top.Parent = root
			local bottom = Instance.new("Attachment")
			bottom.Name = "DevXTrailBottom"; bottom.Position = Vector3.new(0,-1,0); bottom.Parent = root
			local trailFx = Instance.new("Trail")
			trailFx.Name = "DevXTrail"
			trailFx.Attachment0 = top; trailFx.Attachment1 = bottom
			trailFx.Color = ColorSequence.new(Theme.accent)
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
			fx.Name = "DevXSparkles"; fx.SparkleColor = Theme.accent
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
		fx.Name = "DevXColor"; fx.TintColor = Color3.fromRGB(120,255,120)
		fx.Brightness = 0.3; fx.Contrast = 0.2
		fx.Parent = Lighting
		notify("Vision","Night vision enabled")
	end,
	resetlighting = function()
		Lighting.Brightness = 1; Lighting.ClockTime = 14
		Lighting.FogEnd = 100000; Lighting.GlobalShadows = true
		Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
		clearCosmetic(Lighting, "DevXBlur")
		clearCosmetic(Lighting, "DevXColor")
		for _,v in pairs(Lighting:GetDescendants()) do
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
		if not name and Settings.target then name = Settings.target.Name end
		local p = name and Players:FindFirstChild(name) or player
		if p then copy(p.Name); notify("CopyName","Copied: "..p.Name) end
	end,
	ping = function()
		notify("Ping",math.round(player:GetNetworkPing()*1000).."ms")
	end,
	fps = function()
		if Settings.fpsLabel then
			Settings.fpsLabel:Destroy(); Settings.fpsLabel = nil
			if fpsConn then fpsConn:Disconnect(); fpsConn = nil end
			notify("FPS Counter","Disabled")
			return
		end
		Settings.fpsLabel = Instance.new("TextLabel")
		Settings.fpsLabel.Name = "DevXFPS"
		Settings.fpsLabel.Size = UDim2.new(0,80,0,20)
		Settings.fpsLabel.Position = UDim2.new(0,8,0,8)
		Settings.fpsLabel.BackgroundTransparency = 0.4
		Settings.fpsLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
		Settings.fpsLabel.TextColor3 = Theme.accent
		Settings.fpsLabel.Font = Enum.Font.Code
		Settings.fpsLabel.TextSize = 14
		Settings.fpsLabel.Text = "-- fps"
		Settings.fpsLabel.Parent = screenGui
		fpsFrames = 0; fpsClock = tick()
		fpsConn = RunService.RenderStepped:Connect(function()
			fpsFrames += 1
			local elapsed = tick() - fpsClock
			if elapsed >= 1 then
				Settings.fpsLabel.Text = tostring(math.floor(fpsFrames/elapsed)).." fps"
				fpsFrames = 0; fpsClock = tick()
			end
		end)
		notify("FPS Counter","Enabled")
	end,

	walkto = function(args)
		local name = args and args[1]
		if not name then notify("Walkto","Provide a player name"); return end
		getgenv().devxWalkto = true
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				task.spawn(function()
					while getgenv().devxWalkto and p.Parent do
						local hum = getHumanoid(player.Character)
						local troot = p.Character and getRoot(p.Character)
						if hum and troot then hum:MoveTo(troot.Position) end
						task.wait(0.1)
					end
				end)
				break
			end
		end
	end,

	unwalkto = function()
		getgenv().devxWalkto = false
		notify("Walkto","Stopped")
	end,

	loopgoto = function(args)
		local name = args and args[1]
		if not name then notify("Loopgoto","Provide a player name"); return end
		getgenv().devxLoopgoto = true
		task.spawn(function()
			while getgenv().devxLoopgoto do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local root = getRoot(player.Character)
						local troot = p.Character and getRoot(p.Character)
						if root and troot then root.CFrame = troot.CFrame + Vector3.new(3,0,0) end
					end
				end
				task.wait(0.1)
			end
		end)
		notify("Loopgoto","Started")
	end,

	unloopgoto = function()
		getgenv().devxLoopgoto = false
		notify("Loopgoto","Stopped")
	end,

	cbring = function(args)
		local name = args and args[1]
		if not name then notify("Cbring","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				local troot = p.Character and getRoot(p.Character)
				local root = getRoot(player.Character)
				if troot and root then troot.CFrame = root.CFrame + Vector3.new(3,0,0) end
				break
			end
		end
	end,

	loopbring = function(args)
		local name = args and args[1]
		if not name then notify("Loopbring","Provide a player name"); return end
		getgenv().devxLoopbring = true
		task.spawn(function()
			while getgenv().devxLoopbring do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local troot = p.Character and getRoot(p.Character)
						local root = getRoot(player.Character)
						if troot and root then troot.CFrame = root.CFrame + Vector3.new(3,0,0) end
					end
				end
				task.wait(0.1)
			end
		end)
		notify("Loopbring","Started")
	end,

	unloopbring = function()
		getgenv().devxLoopbring = false
		notify("Loopbring","Stopped")
	end,

	offset = function(args)
		local x,y,z = tonumber(args and args[1]) or 0, tonumber(args and args[2]) or 0, tonumber(args and args[3]) or 0
		local root = getRoot(player.Character)
		if root then root.CFrame = root.CFrame + Vector3.new(x,y,z) end
	end,

	tppos = function(args)
		local x,y,z = tonumber(args and args[1]), tonumber(args and args[2]), tonumber(args and args[3])
		if not (x and y and z) then notify("Tppos","Provide X Y Z"); return end
		local root = getRoot(player.Character)
		if root then root.CFrame = CFrame.new(x,y,z) end
	end,

	thru = function(args)
		local num = tonumber(args and args[1]) or 5
		local root = getRoot(player.Character)
		if root then root.CFrame = root.CFrame + root.CFrame.LookVector * num end
	end,

	orbit = function(args)
		local name = args and args[1]
		if not name then notify("Orbit","Provide a player name"); return end
		getgenv().devxOrbit = true
		local rot = 0
		task.spawn(function()
			while getgenv().devxOrbit do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local troot = p.Character and getRoot(p.Character)
						local root = getRoot(player.Character)
						if troot and root then
							rot += 2
							local cf = CFrame.new(troot.Position) * CFrame.Angles(0,math.rad(rot),0) * CFrame.new(6,0,0)
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
		getgenv().devxOrbit = false
		notify("Orbit","Stopped")
	end,

	carpet = function(args)
		local name = args and args[1]
		if not name then notify("Carpet","Provide a player name"); return end
		getgenv().devxCarpet = true
		task.spawn(function()
			while getgenv().devxCarpet do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
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
		getgenv().devxCarpet = false
		notify("Carpet","Stopped")
	end,

	headsit = function(args)
		local name = args and args[1]
		if not name then notify("Headsit","Provide a player name"); return end
		getgenv().devxHeadsit = true
		task.spawn(function()
			while getgenv().devxHeadsit do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local head = p.Character and p.Character:FindFirstChild("Head")
						local root = getRoot(player.Character)
						if head and root then root.CFrame = CFrame.new(head.Position + Vector3.new(0,2,0)) end
					end
				end
				task.wait()
			end
		end)
	end,

	scare = function(args)
		local name = args and args[1]
		if not name then notify("Scare","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
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
		local hum = getHumanoid(player.Character)
		if not hum then return end
		local anim = Instance.new("Animation")
		anim.AnimationId = r15(player) and "rbxassetid://5918726674" or "rbxassetid://148840371"
		getgenv().devxBangTrack = hum:LoadAnimation(anim)
		getgenv().devxBangTrack:Play(); getgenv().devxBangTrack:AdjustSpeed(3)
		getgenv().devxBang = true
		Settings.keep("bang", args)
		task.spawn(function()
			while getgenv().devxBang do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local troot = p.Character and getRoot(p.Character)
						local root = getRoot(player.Character)
						if troot and root then root.CFrame = troot.CFrame + Vector3.new(0,0,1.1) end
					end
				end
				task.wait()
			end
		end)
	end,

	unbang = function()
		getgenv().devxBang = false
		if getgenv().devxBangTrack then getgenv().devxBangTrack:Stop() end
		notify("Bang","Stopped")
	end,

	stareat = function(args)
		local name = args and args[1]
		if not name then notify("Stareat","Provide a player name"); return end
		getgenv().devxStare = true
		task.spawn(function()
			while getgenv().devxStare do
				for _,p in pairs(Players:GetPlayers()) do
					if p.Name:lower():sub(1,#name) == name:lower() then
						local troot = p.Character and getRoot(p.Character)
						local root = getRoot(player.Character)
						if troot and root and player.Character.PrimaryPart then
							local pos = root.Position
							local tpos = troot.Position
							player.Character:SetPrimaryPartCFrame(CFrame.new(pos, Vector3.new(tpos.X,pos.Y,tpos.Z)))
						end
					end
				end
				task.wait()
			end
		end)
	end,

	unstareat = function()
		getgenv().devxStare = false
		notify("Stareat","Stopped")
	end,

	friend = function(args)
		local name = args and args[1]
		if not name then notify("Friend","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				player:RequestFriendship(p)
				notify("Friend","Request sent to "..p.Name)
				break
			end
		end
	end,

	unfriend = function(args)
		local name = args and args[1]
		if not name then notify("Unfriend","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				player:RevokeFriendship(p)
				notify("Unfriend","Unfriended "..p.Name)
				break
			end
		end
	end,

	locate = function(args)
		local name = args and args[1]
		if not name then notify("Locate","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				for _,c in pairs(CoreGui:GetChildren()) do
					if c.Name == p.Name.."_LC" then c:Destroy() end
				end
				local folder = Instance.new("Folder"); folder.Name = p.Name.."_LC"; folder.Parent = CoreGui
				if p.Character then
					for _,part in pairs(p.Character:GetChildren()) do
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
			for _,c in pairs(CoreGui:GetChildren()) do
				if c.Name:sub(-3) == "_LC" then c:Destroy() end
			end
		else
			for _,p in pairs(Players:GetPlayers()) do
				if p.Name:lower():sub(1,#name) == name:lower() then
					local f = CoreGui:FindFirstChild(p.Name.."_LC")
					if f then f:Destroy() end
				end
			end
		end
		notify("Locate","Removed")
	end,

	chams = function()
		for _,p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				for _,part in pairs(p.Character:GetChildren()) do
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
		for _,v in pairs(workspace:GetDescendants()) do
			if v.Name == "DevXChams" then v:Destroy() end
		end
		notify("Chams","Disabled")
	end,

	hitbox = function(args)
		local name = args and args[1]
		local size = tonumber(args and args[2]) or 10
		if not name then notify("Hitbox","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				local root = p.Character and getRoot(p.Character)
				if root then root.Size = Vector3.new(size,size,size); root.Transparency = 0.5 end
				break
			end
		end
	end,

	headsize = function(args)
		local name = args and args[1]
		local size = tonumber(args and args[2]) or 5
		if not name then notify("Headsize","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				local head = p.Character and p.Character:FindFirstChild("Head")
				if head then head.Size = Vector3.new(size,size,size) end
				break
			end
		end
	end,

	userid = function(args)
		local name = args and args[1]
		if not name then notify("UserId","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				notify("UserId", p.Name..": "..tostring(p.UserId))
				break
			end
		end
	end,

	copyid = function(args)
		local name = args and args[1]
		if not name then notify("CopyId","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				copy(tostring(p.UserId))
				notify("CopyId","Copied "..p.Name.."'s ID")
				break
			end
		end
	end,

	age = function(args)
		local name = args and args[1]
		if not name then notify("Age","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				notify("Age", p.Name..": "..tostring(p.AccountAge).." days")
				break
			end
		end
	end,

	inspect = function(args)
		local name = args and args[1]
		if not name then notify("Inspect","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				pcall(function() GuiService:InspectPlayerFromUserId(p.UserId) end)
				break
			end
		end
	end,

	chat = function(args)
		if not args or #args == 0 then notify("Chat","Provide text"); return end
		local msg = table.concat(args," ")
		sendChat(msg)
	end,

	spam = function(args)
		if not args or #args == 0 then notify("Spam","Provide text"); return end
		getgenv().devxSpam = true
		local msg = table.concat(args," ")
		task.spawn(function()
			while getgenv().devxSpam do
				sendChat(msg)
				task.wait(1)
			end
		end)
	end,

	unspam = function()
		getgenv().devxSpam = false
		notify("Spam","Stopped")
	end,

	whisper = function(args)
		local name = args and args[1]
		if not name then notify("Whisper","Provide a player name"); return end
		local msg = table.concat(args," ",2)
		sendChat("/w "..name.." "..msg)
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
		getgenv().devxAntifling = RunService.Stepped:Connect(function()
			for _,p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					for _,v in pairs(p.Character:GetDescendants()) do
						if v:IsA("BasePart") then v.CanCollide = false end
					end
				end
			end
		end)
		notify("Antifling","Enabled")
	end,

	unantifling = function()
		if getgenv().devxAntifling then getgenv().devxAntifling:Disconnect(); getgenv().devxAntifling = nil end
		notify("Antifling","Disabled")
	end,

	flingspin = function()
		getgenv().devxFling = true
		local root = getRoot(player.Character)
		if not root then return end
		for _,v in pairs(root:GetChildren()) do if v.Name=="DevXFlingBAV" then v:Destroy() end end
		local bav = Instance.new("BodyAngularVelocity")
		bav.Name = "DevXFlingBAV"
		bav.MaxTorque = Vector3.new(0,math.huge,0)
		bav.AngularVelocity = Vector3.new(0,_flingSpeed,0)
		bav.Parent = root
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(100,0.3,0.5) end
			end
		end
		task.spawn(function()
			while getgenv().devxFling do
				bav.AngularVelocity = Vector3.new(0,_flingSpeed,0); task.wait(0.2)
				bav.AngularVelocity = Vector3.new(0,0,0); task.wait(0.1)
			end
			bav:Destroy()
		end)
		notify("Fling","Enabled")
	end,
	unflingspin = function()
		getgenv().devxFling = false
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CustomPhysicalProperties = PhysicalProperties.new(0.7,0.3,0.5)
					v.Massless = false
				end
				if v.Name == "DevXFlingBAV" then v:Destroy() end
			end
		end
		notify("Fling","Disabled")
	end,

	loopspeed = function(args)
		local spd = tonumber(args and args[1]) or 16
		getgenv().devxLoopspeedConn = getgenv().devxLoopspeedConn and getgenv().devxLoopspeedConn:Disconnect()
		local hum = getHumanoid(player.Character)
		if hum then
			hum.WalkSpeed = spd
			getgenv().devxLoopspeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				hum.WalkSpeed = spd
			end)
		end
		notify("Loopspeed",tostring(spd))
	end,

	unloopspeed = function()
		if getgenv().devxLoopspeedConn then getgenv().devxLoopspeedConn:Disconnect(); getgenv().devxLoopspeedConn = nil end
		notify("Loopspeed","Stopped")
	end,

	loopjp = function(args)
		local jp = tonumber(args and args[1]) or 50
		getgenv().devxLoopjpConn = getgenv().devxLoopjpConn and getgenv().devxLoopjpConn:Disconnect()
		local hum = getHumanoid(player.Character)
		if hum then
			if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end
			getgenv().devxLoopjpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if hum.UseJumpPower then hum.JumpPower = jp else hum.JumpHeight = jp end
			end)
		end
		notify("LoopJP",tostring(jp))
	end,

	unloopjp = function()
		if getgenv().devxLoopjpConn then getgenv().devxLoopjpConn:Disconnect(); getgenv().devxLoopjpConn = nil end
		notify("LoopJP","Stopped")
	end,

	antivoid = function()
		if getgenv().devxAntivoid then getgenv().devxAntivoid:Disconnect() end
		getgenv().devxAntivoid = RunService.Stepped:Connect(function()
			local root = getRoot(player.Character)
			if root and root.Position.Y <= workspace.FallenPartsDestroyHeight + 25 then
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + Vector3.new(0,250,0)
			end
		end)
		notify("Antivoid","Enabled")
	end,

	unantivoid = function()
		if getgenv().devxAntivoid then getgenv().devxAntivoid:Disconnect(); getgenv().devxAntivoid = nil end
		notify("Antivoid","Disabled")
	end,

	walltp = function()
		local char = player.Character
		local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
		if not torso then return end
		getgenv().devxWalltp = torso.Touched:Connect(function(hit)
			local root = getRoot(char)
			if hit and hit:IsA("BasePart") and not hit.Parent:FindFirstChildWhichIsA("Humanoid") and root then
				root.CFrame = root.CFrame + root.CFrame.LookVector * 5 + Vector3.new(0,2,0)
			end
		end)
		notify("Walltp","Enabled")
	end,

	unwalltp = function()
		if getgenv().devxWalltp then getgenv().devxWalltp:Disconnect(); getgenv().devxWalltp = nil end
		notify("Walltp","Disabled")
	end,

	trip = function()
		local hum = getHumanoid(player.Character)
		local root = getRoot(player.Character)
		if hum and root then
			hum:ChangeState(Enum.HumanoidStateType.FallingDown)
			root.AssemblyLinearVelocity = root.CFrame.LookVector * 30
		end
	end,

	tpwalk = function(args)
		local spd = tonumber(args and args[1]) or 1
		if getgenv().devxTpwalk then getgenv().devxTpwalk:Disconnect() end
		getgenv().devxTpwalk = RunService.Heartbeat:Connect(function(dt)
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.MoveDirection.Magnitude > 0 then
				char:TranslateBy(hum.MoveDirection * spd * dt * 10)
			end
		end)
		notify("Tpwalk","Enabled at speed "..spd)
	end,

	untpwalk = function()
		if getgenv().devxTpwalk then getgenv().devxTpwalk:Disconnect(); getgenv().devxTpwalk = nil end
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
		local hum = getHumanoid(player.Character)
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
		notify("Nosit","Enabled")
	end,

	unnosit = function()
		local hum = getHumanoid(player.Character)
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
		notify("Nosit","Disabled")
	end,

	lay = function()
		local hum = getHumanoid(player.Character)
		if hum then
			hum.Sit = true; task.wait(0.1)
			hum.RootPart.CFrame = hum.RootPart.CFrame * CFrame.Angles(math.pi*0.5,0,0)
		end
	end,

	autojump = function()
		if getgenv().devxAutojump then getgenv().devxAutojump:Disconnect() end
		getgenv().devxAutojump = RunService.RenderStepped:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.RootPart then
				local ahead = workspace:FindPartOnRay(Ray.new(hum.RootPart.Position - Vector3.new(0,1.5,0), hum.RootPart.CFrame.LookVector*3), char)
				if ahead then hum.Jump = true end
			end
		end)
		notify("Autojump","Enabled")
	end,

	unautojump = function()
		if getgenv().devxAutojump then getgenv().devxAutojump:Disconnect(); getgenv().devxAutojump = nil end
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
		if getgenv().devxHatspin then getgenv().devxHatspin:Disconnect() end
		local hum = getHumanoid(player.Character)
		if not hum then return end
		for _,acc in pairs(hum:GetAccessories()) do
			local weld = acc.Handle:FindFirstChildWhichIsA("Weld")
			if weld then weld:Destroy() end
			local bav = Instance.new("BodyAngularVelocity"); bav.Parent = acc.Handle
			bav.AngularVelocity = Vector3.new(0,100,0); bav.MaxTorque = Vector3.new(0,200,0)
			local bp = Instance.new("BodyPosition"); bp.Parent = acc.Handle; bp.P = 30000; bp.D = 50
			getgenv().devxHatspin = RunService.Stepped:Connect(function()
				bp.Position = player.Character.Head.Position
			end)
		end
		notify("Hatspin","Enabled")
	end,

	unhatspin = function()
		if getgenv().devxHatspin then getgenv().devxHatspin:Disconnect(); getgenv().devxHatspin = nil end
		notify("Hatspin","Disabled")
	end,

	blockhats = function()
		local hum = getHumanoid(player.Character)
		if hum then
			for _,acc in pairs(hum:GetAccessories()) do
				for _,v in pairs(acc:GetDescendants()) do
					if v:IsA("SpecialMesh") then v:Destroy() end
				end
			end
		end
	end,

	deletevelocity = function()
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
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
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(n,0.3,0.5) end
			end
		end
		notify("Weaken","Done")
	end,

	unweaken = function()
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(0.7,0.3,0.5) end
			end
		end
		notify("Weaken","Reset")
	end,

	strengthen = function(args)
		local n = tonumber(args and args[1]) or 100
		if player.Character then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.CustomPhysicalProperties = PhysicalProperties.new(n,0.3,0.5) end
			end
		end
		notify("Strengthen","Done")
	end,

	spawnpoint = function()
		local root = getRoot(player.Character)
		if root then
			getgenv().devxSpawnPos = root.CFrame
			getgenv().devxSpawnConn = getgenv().devxSpawnConn or player.CharacterAdded:Connect(function(char)
				char:WaitForChild("HumanoidRootPart")
				task.wait(0.2)
				if getgenv().devxSpawnPos then char.HumanoidRootPart.CFrame = getgenv().devxSpawnPos end
			end)
			notify("Spawnpoint","Set at current position")
		end
	end,

	nospawnpoint = function()
		getgenv().devxSpawnPos = nil
		if getgenv().devxSpawnConn then getgenv().devxSpawnConn:Disconnect(); getgenv().devxSpawnConn = nil end
		notify("Spawnpoint","Removed")
	end,

	flashback = function()
		if getgenv().devxLastDeath then
			local root = getRoot(player.Character)
			if root then root.CFrame = getgenv().devxLastDeath end
		else
			notify("Flashback","No death recorded yet")
		end
	end,

	btools = function()
		for i=1,4 do
			local h = Instance.new("HopperBin"); h.BinType = i; h.Parent = player:FindFirstChildWhichIsA("Backpack")
		end
		notify("Btools","Added")
	end,

	gotopart = function(args)
		local name = args and args[1]
		if not name then notify("Gotopart","Provide a part name"); return end
		for _,v in pairs(workspace:GetDescendants()) do
			if v.Name:lower() == name:lower() and v:IsA("BasePart") then
				local root = getRoot(player.Character)
				if root then root.CFrame = v.CFrame + Vector3.new(0,3,0) end
				break
			end
		end
	end,

	bringpart = function(args)
		local name = args and args[1]
		if not name then notify("Bringpart","Provide a part name"); return end
		local root = getRoot(player.Character)
		if not root then return end
		for _,v in pairs(workspace:GetDescendants()) do
			if v.Name:lower() == name:lower() and v:IsA("BasePart") then
				v.CFrame = root.CFrame
			end
		end
	end,

	loopxray = function()
		if getgenv().devxLoopXray then getgenv().devxLoopXray:Disconnect() end
		local function fade(v)
			if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
				v.LocalTransparencyModifier = 0.6
			end
		end
		for _,v in ipairs(workspace:GetDescendants()) do fade(v) end
		getgenv().devxLoopXray = workspace.DescendantAdded:Connect(fade)
		notify("Loopxray","Enabled")
	end,
	unloopxray = function()
		if getgenv().devxLoopXray then getgenv().devxLoopXray:Disconnect(); getgenv().devxLoopXray = nil end
		for _,v in pairs(workspace:GetDescendants()) do
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
		notify("DestroyHeight",tostring(h))
	end,

	deleteclass = function(args)
		local cls = args and args[1]
		if not cls then notify("Deleteclass","Provide a classname"); return end
		for _,v in pairs(workspace:GetDescendants()) do
			if v.ClassName:lower() == cls:lower() then v:Destroy() end
		end
		notify("Deleteclass","Deleted all "..cls)
	end,

	delete = function(args)
		local name = args and args[1]
		if not name then notify("Delete","Provide a name"); return end
		for _,v in pairs(workspace:GetDescendants()) do
			if v.Name:lower() == name:lower() then v:Destroy() end
		end
		notify("Delete","Deleted all "..name)
	end,

	antiafk = function()
		if getgenv().devxAntiAfk then getgenv().devxAntiAfk:Disconnect() end
		getgenv().devxAntiAfk = player.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
		notify("AntiAFK","Enabled")
	end,

	autoclick = function()
		if not (mouse1press and mouse1release) then notify("Autoclick","Not supported by your executor"); return end
		getgenv().devxAutoclick = true
		task.spawn(function()
			while getgenv().devxAutoclick do
				mouse1press(); task.wait(0.05); mouse1release(); task.wait(0.05)
			end
		end)
		notify("Autoclick","Enabled – run 'unautoclick' to stop")
	end,

	unautoclick = function()
		getgenv().devxAutoclick = false
		notify("Autoclick","Disabled")
	end,

	reach = function(args)
		local size = tonumber(args and args[1]) or 60
		local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		if handle then
			getgenv().devxOldHandleSize = getgenv().devxOldHandleSize or handle.Size
			handle.Size = Vector3.new(0.5,0.5,size)
			handle.Massless = true
			notify("Reach","Size "..size)
		else
			notify("Reach","Equip a tool first")
		end
	end,

	unreach = function()
		local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		if handle and getgenv().devxOldHandleSize then
			handle.Size = getgenv().devxOldHandleSize; getgenv().devxOldHandleSize = nil
		end
		notify("Reach","Removed")
	end,

	notools = function()
		local bp = player:FindFirstChildWhichIsA("Backpack")
		if bp then for _,v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v:Destroy() end end end
		if player.Character then for _,v in pairs(player.Character:GetChildren()) do if v:IsA("Tool") then v:Destroy() end end end
		notify("Notools","Done")
	end,

	droptools = function()
		local bp = player:FindFirstChildWhichIsA("Backpack")
		if bp then for _,v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v.Parent = player.Character end end end
		task.wait()
		if player.Character then for _,v in pairs(player.Character:GetChildren()) do if v:IsA("Tool") then v.Parent = workspace end end end
		notify("Droptools","Done")
	end,

	equiptools = function()
		local bp = player:FindFirstChildWhichIsA("Backpack")
		if bp then for _,v in pairs(bp:GetChildren()) do if v:IsA("Tool") then v.Parent = player.Character end end end
		notify("Equiptools","Done")
	end,

	copytools = function(args)
		local name = args and args[1]
		if not name then notify("Copytools","Provide a player name"); return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#name) == name:lower() then
				local bp = p:FindFirstChildWhichIsA("Backpack")
				if bp then
					for _,v in pairs(bp:GetChildren()) do
						if v:IsA("Tool") then v:Clone().Parent = player:FindFirstChildWhichIsA("Backpack") end
					end
				end
				notify("Copytools","Copied from "..p.Name)
				break
			end
		end
	end,
}
CommandActions.swim = function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local oldGrav = workspace.Gravity
	workspace.Gravity = 0
	local enums = Enum.HumanoidStateType:GetEnumItems()
	for _,v in pairs(enums) do pcall(function() hum:SetStateEnabled(v,false) end) end
	hum:ChangeState(Enum.HumanoidStateType.Swimming)
	_swimConn = RunService.Heartbeat:Connect(function()
		pcall(function()
			local root = getRoot(char)
			if root then root.AssemblyLinearVelocity = root.AssemblyLinearVelocity end
		end)
	end)
	getgenv().devxOldGrav = oldGrav
	notify("Swim","Enabled")
end
CommandActions.unswim = function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local enums = Enum.HumanoidStateType:GetEnumItems()
		for _,v in pairs(enums) do pcall(function() hum:SetStateEnabled(v,true) end) end
	end
	if _swimConn then _swimConn:Disconnect(); _swimConn = nil end
	workspace.Gravity = getgenv().devxOldGrav or 196.2
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
		camCF = camCF * CFrame.new(-camOffset.X,-camOffset.Y,-camOffset.Z+1)
		local camPos = camCF.Position
		local headPos = headCF.Position
		local objVel = CFrame.new(camPos,Vector3.new(headPos.X,camPos.Y,headPos.Z)):VectorToObjectSpace(moveDir)
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
	notify("CFly Speed",tostring(_cflySpeed))
end
CommandActions.float = function()
	local char = player.Character
	local root = getRoot(char)
	if not root then return end
	if _floatPart then _floatPart:Destroy() end
	_floatPart = Instance.new("Part")
	_floatPart.Anchored = true
	_floatPart.CanCollide = true
	_floatPart.Size = Vector3.new(4,0.2,4)
	_floatPart.Transparency = 0.5
	_floatPart.Parent = workspace
	getgenv().devxFloatConn = RunService.Heartbeat:Connect(function()
		if _floatPart and root and root.Parent then
			_floatPart.CFrame = CFrame.new(root.Position - Vector3.new(0,3,0))
		end
	end)
	notify("Float","Enabled")
end
CommandActions.unfloat = function()
	if getgenv().devxFloatConn then getgenv().devxFloatConn:Disconnect(); getgenv().devxFloatConn = nil end
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Kill","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() and p~=player then
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0 end
			notify("Kill","Killed "..p.Name)
			break
		end
	end
end
CommandActions.loopkill = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("LoopKill","Select a target"); return end
	getgenv().devxLoopkill = true
	task.spawn(function()
		while getgenv().devxLoopkill do
			for _,p in pairs(Players:GetPlayers()) do
				if p.Name:lower():sub(1,#name)==name:lower() and p~=player then
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
	getgenv().devxLoopkill = false
	notify("LoopKill","Stopped")
end
CommandActions.freezeplr = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Freeze","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			if p.Character then
				for _,v in pairs(p.Character:GetDescendants()) do
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Unfreeze","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			if p.Character then
				for _,v in pairs(p.Character:GetDescendants()) do
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("LoopFreeze","Select a target"); return end
	getgenv().devxLoopfreeze = true
	getgenv().devxLoopfreezeName = name
	task.spawn(function()
		while getgenv().devxLoopfreeze do
			for _,p in pairs(Players:GetPlayers()) do
				if p.Name:lower():sub(1,#(getgenv().devxLoopfreezeName or name))==(getgenv().devxLoopfreezeName or name):lower() and p.Character then
					for _,v in pairs(p.Character:GetDescendants()) do
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
	getgenv().devxLoopfreeze = false
	notify("LoopFreeze","Stopped")
end
CommandActions.bring = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Bring","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local troot = p.Character and getRoot(p.Character)
			local root = getRoot(player.Character)
			if troot and root then troot.CFrame = root.CFrame + Vector3.new(3,0,0) end
			notify("Bring","Brought "..p.Name)
			break
		end
	end
end
CommandActions.tp = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("TP","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local troot = p.Character and getRoot(p.Character)
			local root = getRoot(player.Character)
			if troot and root then root.CFrame = troot.CFrame + Vector3.new(3,0,0) end
			break
		end
	end
end
CommandActions.jail = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Jail","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local troot = p.Character and getRoot(p.Character)
			if not troot then break end
			if _jailBoxes[p.Name] then _jailBoxes[p.Name]:Destroy() end
			local model = Instance.new("Model"); model.Name = "DevXJail_"..p.Name; model.Parent = workspace
			_jailBoxes[p.Name] = model
			local walls = {
				{Vector3.new(10,10,0.5),Vector3.new(0,5,5)},
				{Vector3.new(10,10,0.5),Vector3.new(0,5,-5)},
				{Vector3.new(0.5,10,10),Vector3.new(5,5,0)},
				{Vector3.new(0.5,10,10),Vector3.new(-5,5,0)},
				{Vector3.new(10,0.5,10),Vector3.new(0,10,0)},
				{Vector3.new(10,0.5,10),Vector3.new(0,0,0)},
			}
			for _,w in pairs(walls) do
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then
		for n,m in pairs(_jailBoxes) do m:Destroy(); _jailBoxes[n]=nil end
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
	Lighting.Ambient = Color3.new(r,g,b)
	Lighting.OutdoorAmbient = Color3.new(r,g,b)
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
	notify("Time",tostring(t))
end
CommandActions.noatmosphere = function()
	for _,v in pairs(Lighting:GetChildren()) do
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
	notify("Brightness",tostring(Lighting.Brightness))
end
CommandActions.serverinfo = function()
	notify("Server Info","Place: "..game.PlaceId.."\nJob: "..game.JobId.."\nPlayers: "..#Players:GetPlayers())
end
CommandActions.players = function()
	local names = {}
	for _,p in pairs(Players:GetPlayers()) do table.insert(names,p.Name) end
	notify("Players ("..#names..")", table.concat(names,", "))
end
CommandActions.copypos = function()
	local root = getRoot(player.Character)
	if root then
		local p = root.Position
		local str = math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z)
		copy(str); notify("CopyPos",str)
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
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ClickDetector") then
			if not name or v.Parent.Name:lower()==name:lower() or v.Name:lower()==name:lower() then
				pcall(fireclickdetector,v)
			end
		end
	end
	notify("FireCD","Done")
end
CommandActions.firepp = function(args)
	if not fireproximityprompt then notify("FirePP","Not supported by your executor"); return end
	local name = args and args[1]
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			if not name or v.Parent.Name:lower()==name:lower() or v.Name:lower()==name:lower() then
				pcall(fireproximityprompt,v)
			end
		end
	end
	notify("FirePP","Done")
end
CommandActions.nocdlimits = function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ClickDetector") then v.MaxActivationDistance = math.huge end
	end
	notify("NoCDLimits","Done")
end
CommandActions.nopplimits = function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then v.MaxActivationDistance = math.huge end
	end
	notify("NoPPLimits","Done")
end
CommandActions.lockws = function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.Locked = true end
	end
	notify("LockWS","Done")
end
CommandActions.unlockws = function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.Locked = false end
	end
	notify("UnlockWS","Done")
end
CommandActions.savepos = function(args)
	local name = args and args[1] or ("wp"..tostring(#_waypoints+1))
	local root = getRoot(player.Character)
	if root then
		local p = root.Position
		_waypoints[name] = {p.X,p.Y,p.Z}
		notify("SavePos","Saved as '"..name.."'")
	end
end
CommandActions.loadpos = function(args)
	local name = args and args[1]
	if not name then notify("LoadPos","Provide a name"); return end
	local wp = _waypoints[name]
	if wp then
		local root = getRoot(player.Character)
		if root then root.CFrame = CFrame.new(wp[1],wp[2],wp[3]) end
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
	for k in pairs(_waypoints) do table.insert(names,k) end
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
	StarterGui:SetCore("DevConsoleVisible",true)
end
CommandActions.antilag = function()
	Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
	settings().Rendering.QualityLevel = 1
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.CastShadow = false end
		if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime = NumberRange.new(0) end
	end
	notify("AntiLag","Graphics lowered")
end
CommandActions.serverhop = function()
	task.spawn(function()
		local ok,data = pcall(function()
			return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"))
		end)
		if ok and data and data.data then
			for _,v in pairs(data.data) do
				if v.id ~= game.JobId and v.playing < v.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId,v.id,player)
					return
				end
			end
		end
		notify("ServerHop","No server found")
	end)
end
CommandActions.placeid = function()
	copy(tostring(game.PlaceId))
	notify("PlaceID",tostring(game.PlaceId))
end
CommandActions.gameid = function()
	copy(tostring(game.GameId))
	notify("GameID",tostring(game.GameId))
end
CommandActions.maxzoom = function(args)
	player.CameraMaxZoomDistance = tonumber(args and args[1]) or 400
	notify("MaxZoom",tostring(player.CameraMaxZoomDistance))
end
CommandActions.minzoom = function(args)
	player.CameraMinZoomDistance = tonumber(args and args[1]) or 0.5
	notify("MinZoom",tostring(player.CameraMinZoomDistance))
end
CommandActions.lookat = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("LookAt","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
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
CommandActions.toggleflingspin = function()
	if getgenv().devxFling then CommandActions.unflingspin() else CommandActions.flingspin() end
end
CommandActions.flingspinspeed = function(args)
	_flingSpeed = tonumber(args and args[1]) or 99999
	notify("FlingSpeed",tostring(_flingSpeed))
end
CommandActions.walkfling = function()
	CommandActions.unwalkfling()
	getgenv().devxWalkflingNoclip = Clip
	CommandActions.noclip()
	local hum = getHumanoid(player.Character)
	if hum then
		hum.Died:Connect(function() CommandActions.unwalkfling() end)
	end
	_walkflingConn = RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = getRoot(char)
		if not root or not root.Parent then return end
		local vel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0,10000,0)
		RunService.RenderStepped:Wait()
		if root and root.Parent then root.AssemblyLinearVelocity = vel end
	end)
	notify("Walkfling","Enabled")
end
CommandActions.unwalkfling = function()
	if _walkflingConn then _walkflingConn:Disconnect(); _walkflingConn = nil end
	if getgenv().devxWalkflingNoclip then CommandActions.clip() end
	getgenv().devxWalkflingNoclip = false
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
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
	local prt = Instance.new("Model"); prt.Parent = char
	local z1 = Instance.new("Part"); z1.Name="Torso"; z1.CanCollide=false; z1.Anchored=true; z1.Position=Vector3.new(0,9999,0)
	local z2 = Instance.new("Part"); z2.Name="Head"; z2.Parent=prt; z2.Anchored=true; z2.CanCollide=false
	local z3 = Instance.new("Humanoid"); z3.Name="Humanoid"; z3.Parent=prt
	player.Character = prt
	task.wait(3)
	player.Character = char
	task.wait(3)
	local root = getRoot(char)
	if root then
		for _,v in pairs(char:GetChildren()) do
			if v ~= root and v.Name~="Humanoid" then v:Destroy() end
		end
		root.Transparency = 0
		local bav = Instance.new("BodyAngularVelocity")
		bav.MaxTorque = Vector3.new(0,math.huge,0)
		bav.AngularVelocity = Vector3.new(0,99999,0)
		bav.Parent = root
	end
	notify("InvisFling","Done")
end
CommandActions.noclipflingspin = function()
	CommandActions.noclip()
	task.wait(0.1)
	CommandActions.flingspin()
	notify("NoclipFling","Enabled")
end
CommandActions.strengthenflingspin = function()
	CommandActions.strengthen()
	task.wait(0.1)
	CommandActions.flingspin()
	notify("StrengthenFling","Enabled")
end
CommandActions.weakenflingspin = function()
	CommandActions.weaken()
	task.wait(0.1)
	CommandActions.flingspin()
	notify("WeakenFling","Enabled")
end
CommandActions.loopflingspin = function()
	if _loopflingConn then _loopflingConn:Disconnect() end
	CommandActions.flingspin()
	_loopflingConn = player.CharacterAdded:Connect(function()
		task.wait(1)
		CommandActions.flingspin()
	end)
	notify("LoopFling","Enabled")
end
CommandActions.unloopflingspin = function()
	if _loopflingConn then _loopflingConn:Disconnect(); _loopflingConn = nil end
	CommandActions.unflingspin()
	notify("LoopFling","Disabled")
end
CommandActions.freecam = function()
	if _freecamRunning then return end
	_freecamRunning = true
	local cam = workspace.CurrentCamera
	_freecamPos = cam.CFrame.Position
	_freecamRot = Vector2.new()
	cam.CameraType = Enum.CameraType.Scriptable
	local keys = {W=0,S=0,A=0,D=0,E=0,Q=0}
	local keyDown = UserInputService.InputBegan:Connect(function(inp,gp)
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
			_freecamRot = _freecamRot + Vector2.new(-inp.Delta.Y,- inp.Delta.X)*0.003
			_freecamRot = Vector2.new(math.clamp(_freecamRot.X,-math.rad(89),math.rad(89)),_freecamRot.Y)
		end
	end)
	_freecamConn = RunService.RenderStepped:Connect(function(dt)
		local cf = CFrame.new(_freecamPos)*CFrame.fromOrientation(_freecamRot.X,_freecamRot.Y,0)
		local vel = cf.RightVector*(keys.D-keys.A) + cf.UpVector*(keys.E-keys.Q) + cf.LookVector*(keys.W-keys.S)
		_freecamPos = _freecamPos + vel*_freecamSpeed*64*dt
		cam.CFrame = CFrame.new(_freecamPos)*CFrame.fromOrientation(_freecamRot.X,_freecamRot.Y,0)
	end)
	getgenv().devxFreecamCleanup = function()
		keyDown:Disconnect(); keyUp:Disconnect(); mouseConn:Disconnect()
	end
	notify("Freecam","Enabled – W/A/S/D + Q/E to move")
end
CommandActions.unfreecam = function()
	_freecamRunning = false
	if _freecamConn then _freecamConn:Disconnect(); _freecamConn = nil end
	if getgenv().devxFreecamCleanup then getgenv().devxFreecamCleanup() end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	notify("Freecam","Disabled")
end
CommandActions.fcspeed = function(args)
	_freecamSpeed = tonumber(args and args[1]) or 1
	notify("FCSpeed",tostring(_freecamSpeed))
end
CommandActions.fcpos = function(args)
	local x,y,z = tonumber(args and args[1]),tonumber(args and args[2]),tonumber(args and args[3])
	if not (x and y and z) then notify("FCPos","Provide X Y Z"); return end
	_freecamPos = Vector3.new(x,y,z)
	if not _freecamRunning then CommandActions.freecam() end
end
CommandActions.fcgoto = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("FCGoto","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
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
		notify("FCPos",math.round(p.X)..", "..math.round(p.Y)..", "..math.round(p.Z))
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
	notify("Volume",tostring(vol).."/10")
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
	notify("MouseSens",tostring(s))
end
CommandActions.hovername = function()
	if _hoverConn then _hoverConn:Disconnect(); _hoverConn=nil end
	if _hoverLabel then _hoverLabel:Destroy(); _hoverLabel=nil end
	_hoverLabel = Instance.new("TextLabel")
	_hoverLabel.BackgroundTransparency = 0.4
	_hoverLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
	_hoverLabel.Size = UDim2.new(0,150,0,24)
	_hoverLabel.Font = Enum.Font.GothamBold
	_hoverLabel.TextSize = 14
	_hoverLabel.TextColor3 = Colors.white
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
			_hoverLabel.Position = UDim2.new(0,mouse.X+16,0,mouse.Y)
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
	_loopOofConn = RunService.Heartbeat:Connect(function()
		for _,p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("Head") then
				for _,s in pairs(p.Character.Head:GetChildren()) do
					if s:IsA("Sound") then s.Playing = true end
				end
			end
		end
	end)
	notify("LoopOof","Enabled")
end
CommandActions.unloopoof = function()
	if _loopOofConn then _loopOofConn:Disconnect(); _loopOofConn=nil end
	notify("LoopOof","Disabled")
end
CommandActions.muteboombox = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("MuteBoombox","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			if p.Character then
				for _,v in pairs(p.Character:GetDescendants()) do
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("UnmuteBoombox","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			if p.Character then
				for _,v in pairs(p.Character:GetDescendants()) do
					if v:IsA("Sound") then v.Playing = true end
				end
			end
			notify("UnmuteBoombox","Unmuted "..p.Name)
			break
		end
	end
end
CommandActions.tweengoto = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("TweenGoto","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local troot = p.Character and getRoot(p.Character)
			local root = getRoot(player.Character)
			if troot and root then
				TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=troot.CFrame+Vector3.new(3,0,0)}):Play()
			end
			break
		end
	end
end
CommandActions.tweenspeed = function(args)
	_tweenSpeed = tonumber(args and args[1]) or 1
	notify("TweenSpeed",tostring(_tweenSpeed))
end
CommandActions.tweenpos = function(args)
	local x,y,z = tonumber(args and args[1]),tonumber(args and args[2]),tonumber(args and args[3])
	if not(x and y and z) then notify("TweenPos","Provide X Y Z"); return end
	local root = getRoot(player.Character)
	if root then TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=CFrame.new(x,y,z)}):Play() end
end
CommandActions.tweenoffset = function(args)
	local x,y,z = tonumber(args and args[1]) or 0,tonumber(args and args[2]) or 0,tonumber(args and args[3]) or 0
	local root = getRoot(player.Character)
	if root then TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=CFrame.new(root.Position+Vector3.new(x,y,z))}):Play() end
end
CommandActions.tweengotopart = function(args)
	local name = args and args[1]
	if not name then notify("TweenGotoPart","Provide a part name"); return end
	local root = getRoot(player.Character)
	if not root then return end
	for _,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower()==name:lower() and v:IsA("BasePart") then
			TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=v.CFrame+Vector3.new(0,3,0)}):Play()
			break
		end
	end
end
CommandActions.tweengotomodel = function(args)
	local name = args and args[1]
	if not name then notify("TweenGotoModel","Provide a model name"); return end
	local root = getRoot(player.Character)
	if not root then return end
	for _,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower()==name:lower() and v:IsA("Model") and v.PrimaryPart then
			TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=v:GetPivot()}):Play()
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
	if root then TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=CFrame.new(wp[1],wp[2],wp[3])}):Play() end
end
CommandActions.tweengotocam = function()
	local root = getRoot(player.Character)
	if root then TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=workspace.CurrentCamera.CFrame}):Play() end
end
CommandActions.pulsetp = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("PulseTP","Select a target"); return end
	local secs = tonumber(args and args[2]) or 1
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local root = getRoot(player.Character)
			local troot = p.Character and getRoot(p.Character)
			if root and troot then
				local old = root.CFrame
				root.CFrame = troot.CFrame+Vector3.new(3,0,0)
				task.wait(secs)
				root.CFrame = old
			end
			break
		end
	end
end
CommandActions.spamspeed = function(args)
	_spamSpeed = tonumber(args and args[1]) or 1
	notify("SpamSpeed",tostring(_spamSpeed))
end
CommandActions.pmspam = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("PMSpam","Select a target"); return end
	local msg = table.concat(args," ",2)
	_pmSpamming[name] = true
	task.spawn(function()
		while _pmSpamming[name] do
			sendChat("/w "..name.." "..msg)
			task.wait(_spamSpeed)
		end
	end)
	notify("PMSpam","Started on "..name)
end
CommandActions.unpmspam = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if name then _pmSpamming[name] = false else for k in pairs(_pmSpamming) do _pmSpamming[k]=false end end
	notify("PMSpam","Stopped")
end
CommandActions.darkchat = function()
	pcall(function()
		local bcc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
		local cwc = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if bcc then bcc.Enabled=true; bcc.BackgroundColor3=Color3.new(); bcc.TextColor3=Colors.white end
		if cwc then cwc.Enabled=true; cwc.BackgroundColor3=Color3.new(); cwc.TextColor3=Colors.white end
	end)
	notify("DarkChat","Enabled")
end
CommandActions.bubblechat = function()
	pcall(function()
		local bcc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
		if bcc then bcc.Enabled = true end
	end)
	notify("BubbleChat","Enabled")
end
CommandActions.unbubblechat = function()
	pcall(function()
		local bcc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
		if bcc then bcc.Enabled = false end
	end)
	notify("BubbleChat","Disabled")
end
CommandActions.chatwindow = function()
	pcall(function()
		local cwc = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if cwc then cwc.Enabled = true end
	end)
	notify("ChatWindow","Enabled")
end
CommandActions.unchatwindow = function()
	pcall(function()
		local cwc = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if cwc then cwc.Enabled = false end
	end)
	notify("ChatWindow","Disabled")
end
CommandActions.listento = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("ListenTo","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local root = p.Character and getRoot(p.Character)
			if root then SoundService:SetListener(Enum.ListenerType.ObjectPosition,root) end
			notify("ListenTo","Listening near "..p.Name)
			break
		end
	end
end
CommandActions.unlistento = function()
	SoundService:SetListener(Enum.ListenerType.Camera)
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("MuteVC","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			pcall(function() game:GetService("VoiceChatInternal"):SubscribePause(p.UserId,true) end)
			notify("MuteVC","Muted "..p.Name)
			break
		end
	end
end
CommandActions.unmutevc = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("UnmuteVC","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			pcall(function() game:GetService("VoiceChatInternal"):SubscribePause(p.UserId,false) end)
			notify("UnmuteVC","Unmuted "..p.Name)
			break
		end
	end
end
CommandActions.espteam = function()
	Settings.esp.enable(true)
	notify("ESPTeam","Enabled")
end
CommandActions.esptransparency = function(args)
	Settings.esp.transparency = math.clamp(tonumber(args and args[1]) or 0.5, 0, 1)
	for _, item in pairs(Settings.esp.items) do item.highlight.FillTransparency = Settings.esp.transparency end
	notify("ESPTransparency",tostring(Settings.esp.transparency))
end
CommandActions.partesp = function(args)
	local name = args and args[1]
	if not name then notify("PartESP","Provide a part name"); return end
	table.insert(_partEspParts,name:lower())
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:lower()==name:lower() then
			local box = Instance.new("BoxHandleAdornment"); box.Name="DevXPartESP"
			box.Adornee=v; box.AlwaysOnTop=true; box.Size=v.Size
			box.Transparency=Settings.esp.transparency; box.Color=BrickColor.new("Lime green"); box.Parent=v
		end
	end
	notify("PartESP","Highlighting "..name)
end
CommandActions.unpartesp = function(args)
	local name = args and args[1]
	for _,v in pairs(workspace:GetDescendants()) do
		if v.Name=="DevXPartESP" then
			if not name or v.Parent.Name:lower()==name:lower() then v:Destroy() end
		end
	end
	if name then
		for i,n in pairs(_partEspParts) do if n==name:lower() then table.remove(_partEspParts,i) end end
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
	getgenv().devxRolewatch = Players.PlayerAdded:Connect(function(p)
		if p:IsInGroup(gid) and p:GetRoleInGroup(gid):lower()==role:lower() then
			notify("Rolewatch",p.Name.." joined with role: "..role)
		end
	end)
	notify("Rolewatch","Watching group "..gid.." for role: "..role)
end
CommandActions.unrolewatch = function()
	if getgenv().devxRolewatch then getgenv().devxRolewatch:Disconnect(); getgenv().devxRolewatch=nil end
	notify("Rolewatch","Disabled")
end
CommandActions.staffwatch = function()
	if game.CreatorType~=Enum.CreatorType.Group then notify("Staffwatch","Game not owned by a group"); return end
	local roles = {"mod","admin","staff","dev","founder","owner","manager","director"}
	getgenv().devxStaffwatch = Players.PlayerAdded:Connect(function(p)
		local r = p:GetRoleInGroup(game.CreatorId)
		for _,kw in pairs(roles) do
			if r:lower():find(kw) then notify("Staffwatch",p.Name.." is a "..r); break end
		end
	end)
	notify("Staffwatch","Enabled")
end
CommandActions.unstaffwatch = function()
	if getgenv().devxStaffwatch then getgenv().devxStaffwatch:Disconnect(); getgenv().devxStaffwatch=nil end
	notify("Staffwatch","Disabled")
end
CommandActions.findfriendgroups = function()
	notify("FriendGroups","Checking... (may take a moment)")
	task.spawn(function()
		local players = Players:GetPlayers()
		local results = {}
		for i=1,#players do
			for j=i+1,#players do
				local ok,friends = pcall(function() return players[i]:IsFriendsWith(players[j].UserId) end)
				if ok and friends then
					table.insert(results, players[i].Name.." & "..players[j].Name)
				end
			end
		end
		if #results>0 then notify("FriendGroups",table.concat(results,"\n")) else notify("FriendGroups","None found") end
	end)
end
CommandActions.joindate = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("JoinDate","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local secs = p.AccountAge*24*60*60
			local date = os.date("%m/%d/%Y",os.time()-secs)
			notify("JoinDate",p.Name..": "..date)
			break
		end
	end
end
CommandActions.chatjoindate = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("ChatJoinDate","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local secs = p.AccountAge*24*60*60
			local date = os.date("%m/%d/%Y",os.time()-secs)
			CommandActions.chat({"Joined Roblox: "..date})
			break
		end
	end
end
CommandActions.chatage = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("ChatAge","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			CommandActions.chat({p.Name.."'s age: "..p.AccountAge.." days"})
			break
		end
	end
end
CommandActions.appearanceid = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("AppearanceID","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			notify("AppearanceID",p.Name..": "..tostring(p.CharacterAppearanceId))
			break
		end
	end
end
CommandActions.copyappearanceid = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("CopyAppearanceID","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			copy(tostring(p.CharacterAppearanceId))
			notify("CopyAppearanceID","Copied "..p.Name.."'s appearance ID")
			break
		end
	end
end
CommandActions.enablestate = function(args)
	local s = args and args[1]
	if not s then notify("EnableState","Provide a state"); return end
	local hum = getHumanoid(player.Character)
	if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s],true) end) end
	notify("EnableState",tostring(s))
end
CommandActions.disablestate = function(args)
	local s = args and args[1]
	if not s then notify("DisableState","Provide a state"); return end
	local hum = getHumanoid(player.Character)
	if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s],false) end) end
	notify("DisableState",tostring(s))
end
CommandActions.hipheight = function(args)
	local h = tonumber(args and args[1]) or 0
	local hum = getHumanoid(player.Character)
	if hum then hum.HipHeight = h end
	notify("HipHeight",tostring(h))
end
CommandActions.maxslopeangle = function(args)
	local a = tonumber(args and args[1]) or 89
	local hum = getHumanoid(player.Character)
	if hum then hum.MaxSlopeAngle = a end
	notify("MaxSlopeAngle",tostring(a))
end
CommandActions.platformstand = function()
	local hum = getHumanoid(player.Character)
	if hum then hum.PlatformStand = true end
	notify("PlatformStand","Enabled")
end
CommandActions.unplatformstand = function()
	local hum = getHumanoid(player.Character)
	if hum then hum.PlatformStand = false end
	notify("PlatformStand","Disabled")
end
CommandActions.edgejump = function()
	if _edgejumpConn then _edgejumpConn:Disconnect() end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local lastState,lastCF
	_edgejumpConn = RunService.RenderStepped:Connect(function()
		if not(char and hum) then return end
		local state = hum:GetState()
		if lastState~=state and state==Enum.HumanoidStateType.Freefall and lastState~=Enum.HumanoidStateType.Jumping then
			if lastCF then hum.RootPart.CFrame = lastCF end
			hum.RootPart.AssemblyLinearVelocity = hum.RootPart.AssemblyLinearVelocity + Vector3.new(0,hum.JumpHeight or 50,0)
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
		local hum = getHumanoid(player.Character)
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("TPUnanchored","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local head = p.Character and p.Character:FindFirstChild("Head")
			if head then
				for _,v in pairs(workspace:GetDescendants()) do
					if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
						local bp = Instance.new("BodyPosition"); bp.Position=head.Position
						bp.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bp.Parent=v
						table.insert(_frozenUA,v)
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
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Anchored then
			local skip = false
			for _,b in pairs(bad) do if v.Name==b then skip=true; break end end
			if not skip and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
				local bp = Instance.new("BodyPosition"); bp.Position=v.Position
				bp.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bp.Parent=v
				local bg = Instance.new("BodyGyro"); bg.CFrame=v.CFrame
				bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); bg.Parent=v
				table.insert(_frozenUA,v)
			end
		end
	end
	notify("FreezeUnanchored","Frozen "..#_frozenUA.." parts")
end
CommandActions.thawunanchored = function()
	for _,v in pairs(_frozenUA) do
		if typeof(v)=="Instance" and v.Parent then
			for _,c in pairs(v:GetChildren()) do
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
			for _,f in pairs(getgc()) do
				if type(f)=="function" and getfenv and getfenv(f).script==pop then
					for i,v in pairs(gc(f)) do
						if v==0.25 then sc(f,i,0) elseif v==0 then sc(f,i,0.25) end
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
	workspace.CurrentCamera.CameraSubject = getHumanoid(player.Character)
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 400
	player.CameraMode = Enum.CameraMode.Classic
	notify("FixCam","Camera reset")
end
CommandActions.dupetools = function(args)
	local n = tonumber(args and args[1]) or 1
	local bp = player:FindFirstChildWhichIsA("Backpack")
	if not bp then return end
	for _=1,n do
		for _,v in pairs(bp:GetChildren()) do
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
	for _,v in pairs(bp:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = player.Character
			task.spawn(function()
				for _=1,n do pcall(function() v:Activate() end); if delay_>0 then task.wait(delay_) end end
				v.Parent = bp
			end)
		end
	end
end
CommandActions.droppabletools = function()
	local function setDroppable(container)
		if not container then return end
		for _,v in pairs(container:GetChildren()) do
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
			for _,v in pairs(bp:GetChildren()) do
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
	for k,v in pairs(_removeSpecificTools) do v:Disconnect(); _removeSpecificTools[k]=nil end
	notify("ClearRemoveTools","Done")
end
CommandActions.grippos = function(args)
	local x,y,z = tonumber(args and args[1]) or 0,tonumber(args and args[2]) or 0,tonumber(args and args[3]) or 0
	local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	if tool then tool.GripPos = Vector3.new(x,y,z) end
	notify("GripPos",x..", "..y..", "..z)
end
CommandActions.boxreach = function(args)
	local size = tonumber(args and args[1]) or 60
	local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if handle then
		getgenv().devxOldHandleSize = getgenv().devxOldHandleSize or handle.Size
		handle.Size = Vector3.new(size,size,size); handle.Massless = true
		notify("BoxReach","Size "..size)
	else notify("BoxReach","Equip a tool first") end
end
CommandActions.grabtools = function()
	if _grabToolsConn then _grabToolsConn:Disconnect() end
	local hum = getHumanoid(player.Character)
	if not hum then return end
	for _,v in pairs(workspace:GetChildren()) do
		if v:IsA("Tool") and v:FindFirstChild("Handle") then hum:EquipTool(v) end
	end
	_grabToolsConn = workspace.ChildAdded:Connect(function(v)
		if v:IsA("Tool") and v:FindFirstChild("Handle") then
			local h = getHumanoid(player.Character)
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
	for _,v in pairs(workspace:GetDescendants()) do
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
	for _,v in pairs(workspace:GetDescendants()) do
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
	for _,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower()==cls:lower() and v:IsA("BasePart") then
			v.CFrame = root.CFrame
		end
	end
	notify("BringPartClass","Done")
end
CommandActions.gotopartdelay = function(args)
	getgenv().devxGotoPartDelay = tonumber(args and args[1]) or 0.1
	notify("GotoPartDelay",tostring(getgenv().devxGotoPartDelay))
end
CommandActions.invisibleparts = function()
	getgenv().devxShownParts = {}
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency==1 then
			v.Transparency = 0
			table.insert(getgenv().devxShownParts,v)
		end
	end
	notify("InvisibleParts","Showing "..(#getgenv().devxShownParts).." parts")
end
CommandActions.uninvisibleparts = function()
	for _,v in pairs(getgenv().devxShownParts or {}) do
		if typeof(v)=="Instance" and v.Parent then v.Transparency=1 end
	end
	getgenv().devxShownParts = {}
	notify("InvisibleParts","Restored")
end
CommandActions.deleteinvisparts = function()
	local count = 0
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency==1 and v.CanCollide then
			v:Destroy(); count+=1
		end
	end
	notify("DeleteInvisParts","Deleted "..count.." parts")
end
CommandActions.clearnilinstances = function()
	if getnilinstances then
		for _,v in pairs(getnilinstances()) do pcall(function() v:Destroy() end) end
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
CommandActions.headthrow = function()
	if r15(player) then notify("Headthrow","Requires R6"); return end
	local hum = getHumanoid(player.Character)
	if hum then
		local anim = Instance.new("Animation"); anim.AnimationId="rbxassetid://35154961"
		local t = hum:LoadAnimation(anim); t:Play()
	end
end
CommandActions.copyanimation = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("CopyAnimation","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local phum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			local hum = getHumanoid(player.Character)
			if phum and hum then
				for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
				for _,t in pairs(phum:GetPlayingAnimationTracks()) do
					local newTrack = hum:LoadAnimation(t.Animation)
					newTrack:Play(0.1,1,t.Speed)
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
		for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
		anim.Disabled = false
	end
	notify("RefreshAnimations","Done")
end
CommandActions.noprompts = function()
	pcall(function() CoreGui.PurchasePromptApp.Enabled = false end)
	notify("NoPrompts","Enabled")
end
CommandActions.showprompts = function()
	pcall(function() CoreGui.PurchasePromptApp.Enabled = true end)
	notify("NoPrompts","Disabled")
end
CommandActions.removeads = function()
	if getgenv().devxRemoveAds then getgenv().devxRemoveAds:Disconnect() end
	local function clear(v)
		pcall(function()
			if v:IsA("PackageLink") then
				if v.Parent:FindFirstChild("ADpart") then v.Parent:Destroy()
				elseif v.Parent:FindFirstChild("AdGuiAdornee") then v.Parent.Parent:Destroy() end
			end
		end)
	end
	for _, v in ipairs(workspace:GetDescendants()) do clear(v) end
	getgenv().devxRemoveAds = workspace.DescendantAdded:Connect(clear)
	notify("RemoveAds","Enabled")
end
CommandActions.unremoveads = function()
	if getgenv().devxRemoveAds then getgenv().devxRemoveAds:Disconnect(); getgenv().devxRemoveAds = nil end
	notify("RemoveAds","Disabled")
end
CommandActions.datalimit = function(args)
	local n = tonumber(args and args[1]) or 50
	pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(n) end)
	notify("DataLimit",tostring(n).." KBPS")
end
CommandActions.replicationlag = function(args)
	local n = tonumber(args and args[1]) or 0
	pcall(function() settings():GetService("NetworkSettings").IncomingReplicationLag = n end)
	notify("ReplicationLag",tostring(n))
end
CommandActions.antikick = function()
	if not hookmetamethod then notify("AntiKick","Not supported by your executor"); return end
	local oldNmc; oldNmc = hookmetamethod(game,"__namecall",newcclosure(function(...)
		local method = getnamecallmethod and getnamecallmethod() or ""
		if select(1,...)==player and (method=="Kick" or method=="kick") then return end
		return oldNmc(...)
	end))
	notify("AntiKick","Enabled (client)")
end
CommandActions.antiteleport = function()
	if not hookmetamethod then notify("AntiTeleport","Not supported by your executor"); return end
	local oldNmc; oldNmc = hookmetamethod(game,"__namecall",newcclosure(function(...)
		local method = getnamecallmethod and getnamecallmethod() or ""
		local self = select(1,...)
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
	TeleportService:Teleport(id,player)
end
CommandActions.autorj = function()
	if getgenv().devxAutoRj then getgenv().devxAutoRj:Disconnect() end
	getgenv().devxAutoRj = GuiService.ErrorMessageChanged:Connect(function()
		pcall(rejoinServer)
	end)
	notify("AutoRJ","Enabled")
end
CommandActions.clearerror = function()
	pcall(function() GuiService:ClearError() end)
	notify("ClearError","Done")
end
CommandActions.antigameplaypaused = function()
	pcall(function()
		local rg = CoreGui:FindFirstChild("RobloxGui")
		if not rg then return end
		getgenv().devxNetPaused = rg.ChildAdded:Connect(function(obj)
			if obj.Name=="CoreScripts/NetworkPause" then pcall(function() obj:Destroy() end) end
		end)
		local np = rg:FindFirstChild("CoreScripts/NetworkPause")
		if np then pcall(function() np:Destroy() end) end
	end)
	notify("AntiGameplayPaused","Enabled")
end
CommandActions.use2022materials = function()
	pcall(function()
		local ms = game:GetService("MaterialService")
		local sh = sethiddenproperty or set_hidden_property
		if sh then sh(ms,"Use2022Materials",true) end
	end)
	notify("2022Materials","Enabled")
end
CommandActions.unuse2022materials = function()
	pcall(function()
		local ms = game:GetService("MaterialService")
		local sh = sethiddenproperty or set_hidden_property
		if sh then sh(ms,"Use2022Materials",false) end
	end)
	notify("2022Materials","Disabled")
end
CommandActions.breakloops = function()
	local flags = {
		"devxAntiVoid2", "devxAutoKeyPress", "devxAutoclick", "devxBackpack", "devxBang",
		"devxBangOnTarget", "devxCarpet", "devxFling", "devxHeadsit", "devxJerkOnTarget",
		"devxLoopbring", "devxLoopfreeze", "devxLoopgoto", "devxLoopkill", "devxOrbit",
		"devxPathfind", "devxReverseBang", "devxSpam", "devxStare", "devxSuck", "devxWalkto",
	}
	for _, flag in ipairs(flags) do getgenv()[flag] = false end
	for name in pairs(_pmSpamming) do _pmSpamming[name] = false end
	Settings.flingRun = (Settings.flingRun or 0) + 1
	Settings.resume = {}
	notify("BreakLoops","All loops stopped")
end
local function playAnim(id, timePos, speed, loop)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
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
	if hum then for _,t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
end
playAnim = playAnim
stopAnimAll = stopAnimAll
local function findPlayer(name)
	if not name and Settings.target then return Settings.target end
	if not name then return nil end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then return p end
	end
end
CommandActions.fling = function(args)
	local target = findPlayer(args and args[1])
	if not target or target == player then notify("Fling","Select another player as the target"); return end
	Settings.flingRun = (Settings.flingRun or 0) + 1
	local runId = Settings.flingRun
	local waited = 0
	while Settings.flingBusy and waited < 4 do
		task.wait(0.05)
		waited += 0.05
	end
	if Settings.flingRun ~= runId then return end
	local char = player.Character
	local root = getRoot(char)
	local hum = getHumanoid(char)
	if not root or not hum then return end

	Settings.flingBusy = true
	local seconds = tonumber(args and args[2]) or 8
	local deadline = seconds > 0 and tick() + seconds or nil
	local oldPos = root.CFrame
	local oldHeight = workspace.FallenPartsDestroyHeight
	local oldProps = {}
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			oldProps[part] = part.CustomPhysicalProperties or false
			part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 1, 100, 100)
		end
	end
	workspace.FallenPartsDestroyHeight = 0/0
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	hum.PlatformStand = true
	local bv = Instance.new("BodyVelocity")
	bv.Name = "DevXFlinger"
	bv.Velocity = Vector3.new(9e8,9e8,9e8)
	bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	bv.Parent = root

	task.spawn(function()
		local offsets = {
			Vector3.new(0,1.5,0), Vector3.new(0,-1.5,0), Vector3.new(2.25,1.5,-2.25),
			Vector3.new(-2.25,-1.5,2.25), Vector3.new(0,0,2), Vector3.new(0,0,-2),
		}
		local sum, step = 0, 0
		local lastRoot, lastPos, lastTime, lastSpeed, stable = nil, nil, 0, 0, nil
		local hits, peak, flung = 0, 0, false
		while Settings.flingRun == runId and root.Parent and target.Parent and (not deadline or tick() < deadline) do
			pcall(function()
				local troot = target.Character and getRoot(target.Character)
				if not troot then return end
				local now = tick()
				local pos = troot.Position
				local vel = troot.AssemblyLinearVelocity
				local speed = vel.Magnitude
				if pos ~= pos or speed ~= speed then
					flung = true
					return
				end
				if troot ~= lastRoot then
					lastRoot, lastPos, lastSpeed, stable, hits = troot, nil, 0, pos, 0
				end
				if lastPos then
					local dt = math.max(now - lastTime, 1 / 240)
					local moved = pos - lastPos
					local travelled = moved.Magnitude
					local aligned = travelled > 0 and speed > 0 and vel:Dot(moved) / (speed * travelled) > 0.5
					local spinning = troot.AssemblyAngularVelocity.Magnitude > 15
					local burst = speed > 20000 or (speed > 1200 and speed - lastSpeed > 600 and travelled / dt > 400 and aligned and (spinning or speed > 5000))
					local carry = hits > 0 and speed > 1200 and aligned
					if burst or carry then
						hits += 1
						peak = math.max(peak, speed)
					else
						hits = 0
						stable = pos
					end
					if hits >= 2 and (pos - stable).Magnitude > 30 then
						flung = true
						return
					end
				end
				lastPos, lastTime, lastSpeed = pos, now, speed

				step += 1
				local offset = offsets[step % #offsets + 1]
				root.CFrame = CFrame.new(pos) * CFrame.new(offset) * CFrame.Angles(math.rad(sum), math.rad(sum * 0.7), 0)
				root.AssemblyLinearVelocity = Vector3.new(9e7,9e8,9e7)
				root.AssemblyAngularVelocity = Vector3.new(9e8,9e8,9e8)
				sum += 100
			end)
			if flung then break end
			task.wait()
		end
		bv:Destroy()
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.FallenPartsDestroyHeight = oldHeight
		for part, props in pairs(oldProps) do
			if part.Parent then part.CustomPhysicalProperties = props or nil end
		end
		local started = tick()
		repeat
			if root.Parent then
				root.CFrame = oldPos * CFrame.new(0, 0.5, 0)
				pcall(breakVelocity)
			end
			task.wait()
		until not root.Parent or ((root.Position - oldPos.Position).Magnitude < 5 and tick() - started > 0.15) or tick() - started > 3
		if root.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		Settings.flingBusy = false
		notify("Fling", flung and (target.Name .. " was flung (" .. math.floor(peak) .. " studs/s)") or "Fling stopped, no fling detected")
	end)
	notify("Fling","Flinging " .. target.Name)
end
CommandActions.unfling = function()
	if not Settings.flingBusy then notify("Fling","Nothing to stop"); return end
	Settings.flingRun = (Settings.flingRun or 0) + 1
end
CommandActions.jerkontarget = function(args)
	local target = findPlayer(args and args[1])
	if not target then notify("JerkOnTarget","Select a target"); return end
	getgenv().devxJerkOnTarget = true
	local oldH = workspace.FallenPartsDestroyHeight
	workspace.FallenPartsDestroyHeight = 0/1/0
	local hum = getHumanoid(player.Character)
	task.spawn(function()
		while getgenv().devxJerkOnTarget do
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
		while getgenv().devxJerkOnTarget do
			pcall(function()
				local troot = target.Character and getRoot(target.Character)
				local root = getRoot(player.Character)
				if troot and root and hum then
					hum:ChangeState("GettingUp")
					if not hum.Sit then hum.Sit = true end
					root.CFrame = troot.CFrame * CFrame.new(0,1,-3) * CFrame.Angles(0,math.pi,0)
					root.AssemblyLinearVelocity = Vector3.new()
				end
			end)
			task.wait()
		end
		if hum then hum.Sit = false end
	end)
	Settings.keep("jerkontarget", args)
	notify("JerkOnTarget","Started on "..target.Name)
end
CommandActions.unjerkontarget = function()
	getgenv().devxJerkOnTarget = false
	local hum = getHumanoid(player.Character)
	if hum then hum.Sit = false end
	notify("JerkOnTarget","Stopped")
end
CommandActions.bangontarget = function(args)
	local target = findPlayer(args and args[1])
	if not target then notify("BangOnTarget","Select a target"); return end
	getgenv().devxBangOnTarget = true
	local hum = getHumanoid(player.Character)
	local r15mode = hum and hum.RigType == Enum.HumanoidRigType.R15
	playAnim(r15mode and 5918726674 or 148840371, 0, 3, true)
	local sum = -2; local sumN = 0.1; local offset = r15mode and -1 or -0.75
	task.spawn(function()
		while getgenv().devxBangOnTarget do
			pcall(function()
				local torso = target.Character and (target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Torso"))
				local root = getRoot(player.Character)
				if torso and root and hum then
					hum.Sit = true
					root.CFrame = torso.CFrame * CFrame.new(0,offset,sum) * CFrame.Angles(math.rad(270),0,0)
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
	Settings.keep("bangontarget", args)
	notify("BangOnTarget","Started on "..target.Name)
end
CommandActions.unbangontarget = function()
	getgenv().devxBangOnTarget = false
	local hum = getHumanoid(player.Character)
	if hum then hum.Sit = false end
	stopAnimAll()
	notify("BangOnTarget","Stopped")
end
CommandActions.reversebang = function(args)
	local target = findPlayer(args and args[1])
	if not target then notify("ReverseBang","Select a target"); return end
	getgenv().devxReverseBang = true
	local hum = getHumanoid(player.Character)
	local r15mode = hum and hum.RigType == Enum.HumanoidRigType.R15
	playAnim(r15mode and 5918726674 or 148840371, 0, 3, true)
	task.spawn(function()
		while getgenv().devxReverseBang do
			pcall(function()
				local troot = target.Character and getRoot(target.Character)
				local root = getRoot(player.Character)
				if troot and root and hum then
					hum.Sit = true
					root.CFrame = troot.CFrame * CFrame.new(0,1,1.1) * CFrame.Angles(0,0,0)
					root.AssemblyLinearVelocity = Vector3.new()
				end
			end)
			task.wait()
		end
		if hum then hum.Sit = false end
		stopAnimAll()
	end)
	Settings.keep("reversebang", args)
	notify("ReverseBang","Started on "..target.Name)
end
CommandActions.unreversebang = function()
	getgenv().devxReverseBang = false
	local hum = getHumanoid(player.Character)
	if hum then hum.Sit = false end
	stopAnimAll(); notify("ReverseBang","Stopped")
end
CommandActions.suck = function(args)
	local target = findPlayer(args and args[1])
	if not target then notify("Suck","Select a target"); return end
	getgenv().devxSuck = true
	local hum = getHumanoid(player.Character)
	task.spawn(function()
		while getgenv().devxSuck do
			pcall(function()
				local troot = target.Character and getRoot(target.Character)
				local root = getRoot(player.Character)
				if troot and root and hum then
					hum.Sit = true
					root.CFrame = troot.CFrame * CFrame.new(0,0,1.2) * CFrame.Angles(0,-3,0)
					root.AssemblyLinearVelocity = Vector3.new()
				end
			end)
			task.wait()
		end
		if hum then hum.Sit = false end
	end)
	Settings.keep("suck", args)
	notify("Suck","Started on "..target.Name)
end
CommandActions.unsuck = function()
	getgenv().devxSuck = false
	local hum = getHumanoid(player.Character)
	if hum then hum.Sit = false end
	notify("Suck","Stopped")
end
CommandActions.backpack = function(args)
	local target = findPlayer(args and args[1])
	if not target then notify("Backpack","Select a target"); return end
	getgenv().devxBackpack = true
	local hum = getHumanoid(player.Character)
	task.spawn(function()
		while getgenv().devxBackpack do
			pcall(function()
				local troot = target.Character and getRoot(target.Character)
				local root = getRoot(player.Character)
				if troot and root and hum then
					hum.Sit = true
					root.CFrame = troot.CFrame * CFrame.new(0,1,-1.2)
					root.AssemblyLinearVelocity = Vector3.new()
				end
			end)
			task.wait()
		end
		if hum then hum.Sit = false end
	end)
	Settings.keep("backpack", args)
	notify("Backpack","Started on "..target.Name)
end
CommandActions.unbackpack = function()
	getgenv().devxBackpack = false
	local hum = getHumanoid(player.Character)
	if hum then hum.Sit = false end
	notify("Backpack","Stopped")
end
CommandActions.antisite = function()
	if _antiSiteConn then _antiSiteConn:Disconnect() end
	_antiSiteConn = RunService.Heartbeat:Connect(function()
		local hum = getHumanoid(player.Character)
		if hum and hum.Sit then hum.Sit = false end
	end)
	notify("AntiSit","Enabled")
end
CommandActions.unantisite = function()
	if _antiSiteConn then _antiSiteConn:Disconnect(); _antiSiteConn = nil end
	notify("AntiSit","Disabled")
end
CommandActions.antijump = function()
	local hum = getHumanoid(player.Character)
	if not hum then return end
	_antiJumpPower = hum.JumpPower; _antiJumpHeight = hum.JumpHeight
	if _antiJumpConn then _antiJumpConn:Disconnect() end
	_antiJumpConn = RunService.Heartbeat:Connect(function()
		local h = getHumanoid(player.Character)
		if h then h.JumpPower = 0; h.JumpHeight = 0 end
	end)
	notify("AntiJump","Enabled")
end
CommandActions.unantijump = function()
	if _antiJumpConn then _antiJumpConn:Disconnect(); _antiJumpConn = nil end
	local hum = getHumanoid(player.Character)
	if hum then
		hum.JumpPower = _antiJumpPower or 50
		hum.JumpHeight = _antiJumpHeight or 7.2
	end
	notify("AntiJump","Disabled")
end
CommandActions.antivoid2 = function()
	getgenv().devxAntiVoid2 = true
	task.spawn(function()
		while getgenv().devxAntiVoid2 do
			workspace.FallenPartsDestroyHeight = 0/1/0
			task.wait(1)
		end
	end)
	notify("AntiVoid2","Enabled – FallenPartsDestroyHeight = NaN")
end
CommandActions.unantivoid2 = function()
	getgenv().devxAntiVoid2 = false
	workspace.FallenPartsDestroyHeight = -500
	notify("AntiVoid2","Disabled")
end
CommandActions.antiafk2 = function()
	CommandActions.antiafk()
end
CommandActions.unantiafk2 = function()
	if getgenv().devxAntiAfk then getgenv().devxAntiAfk:Disconnect(); getgenv().devxAntiAfk = nil end
	notify("AntiAFK","Disabled")
end
local _antiBang = false
CommandActions.antibang = function()
	_antiBang = true
	task.spawn(function()
		while _antiBang do
			pcall(function()
				workspace.FallenPartsDestroyHeight = 0/1/0
				local hum = getHumanoid(player.Character)
				local root = hum and hum.RootPart
				if hum and root and root.AssemblyLinearVelocity.Magnitude > 500 then
					local savedCF = root.CFrame
					local t = tick()
					repeat
						root.CFrame = CFrame.new(0,-499,0) * CFrame.Angles(math.rad(90),0,0)
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
CommandActions.antifling2 = function()
	local function protect(char)
		for _,p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				_antiFlingData[p] = p.CanCollide
				p.CanCollide = false
			end
		end
	end
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then protect(p.Character) end
		table.insert(_antiFlingConns, p.CharacterAdded:Connect(function(c)
			task.wait()
			protect(c)
		end))
	end
	notify("AntiFling2","Enabled")
end
CommandActions.unantifling2 = function()
	for _,c in pairs(_antiFlingConns) do c:Disconnect() end
	_antiFlingConns = {}
	for part, cc in pairs(_antiFlingData) do
		pcall(function() part.CanCollide = cc end)
	end
	_antiFlingData = {}
	notify("AntiFling2","Disabled")
end
CommandActions.toggleantifling = function()
	if getgenv().devxAntifling then CommandActions.unantifling() else CommandActions.antifling() end
end
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
	local target = findPlayer(args and args[1])
	if not target then notify("PredictionTP","Select a target"); return end
	local root = getRoot(player.Character)
	local troot = target.Character and getRoot(target.Character)
	if not root or not troot then return end
	local thum = target.Character:FindFirstChildOfClass("Humanoid")
	local ping = player:GetNetworkPing()
	local predicted = troot.Position + (thum and thum.MoveDirection * (thum.WalkSpeed * ping) or Vector3.new())
	root.CFrame = CFrame.new(predicted) + Vector3.new(3,0,0)
	notify("PredictionTP","Teleported to predicted position of "..target.Name)
end
CommandActions.addalias = function(args)
	local cmd, alias = args and args[1], args and args[2]
	if not (cmd and alias) then notify("AddAlias","Usage: addalias [command] [alias]"); return end
	alias = alias:lower()
	local real = CmdSearch.resolve(cmd)
	if not real then notify("AddAlias","Unknown command: "..cmd); return end
	for name in pairs(CommandActions) do
		if name:lower() == alias then notify("AddAlias","That name is already a command"); return end
	end
	CmdSearch.aliases[alias] = real
	notify("AddAlias", alias.." -> "..real)
end
CommandActions.removealias = function(args)
	local alias = args and args[1] and args[1]:lower()
	if not alias then notify("RemoveAlias","Provide an alias"); return end
	if CmdSearch.aliases[alias] then
		CmdSearch.aliases[alias] = nil
		notify("RemoveAlias","Removed "..alias)
	else
		notify("RemoveAlias","No such alias")
	end
end
CommandActions.clraliases = function()
	CmdSearch.aliases = {}
	notify("Aliases","All aliases cleared")
end
CommandActions.alignmentkeys = function()
	if getgenv().devxAlignKeys then getgenv().devxAlignKeys:Disconnect() end
	getgenv().devxAlignKeys = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.Comma then workspace.CurrentCamera:PanUnits(-1) end
		if inp.KeyCode == Enum.KeyCode.Period then workspace.CurrentCamera:PanUnits(1) end
	end)
	notify("AlignmentKeys","Enabled – use , and .")
end
CommandActions.unalignmentkeys = function()
	if getgenv().devxAlignKeys then getgenv().devxAlignKeys:Disconnect(); getgenv().devxAlignKeys = nil end
	notify("AlignmentKeys","Disabled")
end
CommandActions.antiidle = function()
	CommandActions.antiafk()
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
	local keyMap = {a=0x41,b=0x42,c=0x43,d=0x44,e=0x45,f=0x46,g=0x47,h=0x48,i=0x49,j=0x4A,k=0x4B,l=0x4C,m=0x4D,n=0x4E,o=0x4F,p=0x50,q=0x51,r=0x52,s=0x53,t=0x54,u=0x55,v=0x56,w=0x57,x=0x58,y=0x59,z=0x5A,space=0x20,enter=0x0D}
	local code = keyMap[key:lower()]
	if not code then notify("AutoKeyPress","Unknown key: "..key); return end
	getgenv().devxAutoKeyPress = true
	task.spawn(function()
		while getgenv().devxAutoKeyPress do
			keypress(code); task.wait(downDelay); keyrelease(code); task.wait(upDelay)
		end
	end)
	notify("AutoKeyPress","Pressing "..key)
end
CommandActions.unautokeypress = function()
	getgenv().devxAutoKeyPress = false
	notify("AutoKeyPress","Stopped")
end
CommandActions.autorejoin = function()
	CommandActions.autorj()
end
CommandActions.blocktool = function()
	local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	if tool then
		for _,v in pairs(tool:GetDescendants()) do
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
		for _,v in pairs(player.Character:GetDescendants()) do
			if v.Name:lower() == name:lower() then v:Destroy() end
		end
	end
	notify("CharDelete","Deleted "..name)
end
CommandActions.chardeleteclass = function(args)
	local cls = args and args[1]
	if not cls then notify("CharDeleteClass","Provide a classname"); return end
	if player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v.ClassName:lower() == cls:lower() then v:Destroy() end
		end
	end
	notify("CharDeleteClass","Deleted "..cls)
end
CommandActions.cleargamewaypoints = function()
	_waypoints = {}
	notify("ClearGameWaypoints","Done")
end
CommandActions.clearhats = function()
	if firetouchinterest then
		local hum = getHumanoid(player.Character)
		if hum then hum:RemoveAccessories() end
		notify("ClearHats","Done")
	else
		local hum = getHumanoid(player.Character)
		if hum then hum:RemoveAccessories() end
		notify("ClearHats","Done (client only)")
	end
end
CommandActions.clearremovespecifictool = function()
	for k,v in pairs(_removeSpecificTools) do v:Disconnect(); _removeSpecificTools[k]=nil end
	notify("ClearRemoveTools","Done")
end
CommandActions.clearwaypoints = function()
	_waypoints = {}
	notify("ClearWaypoints","All waypoints cleared")
end
CommandActions.clickdelete = function()
	if getgenv().devxClickDelete then
		getgenv().devxClickDelete:Disconnect(); getgenv().devxClickDelete = nil
		notify("ClickDelete","Disabled")
		return
	end
	getgenv().devxClickDelete = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then return end
		local target = player:GetMouse().Target
		if target then target:Destroy() end
	end)
	notify("ClickDelete","Enabled - hold Alt and click a part")
end
CommandActions.clickteleport = function()
	if getgenv().devxClickTp then
		getgenv().devxClickTp:Disconnect(); getgenv().devxClickTp = nil
		notify("ClickTeleport","Disabled")
		return
	end
	getgenv().devxClickTp = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		local root = getRoot(player.Character)
		local hit = player:GetMouse().Hit
		if root and hit then
			root.CFrame = CFrame.new(hit.Position + Vector3.new(0,3,0))
			breakVelocity()
		end
	end)
	notify("ClickTeleport","Enabled - hold Ctrl and click")
end
CommandActions.clientbring = function(args)
	CommandActions.cbring(args)
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
		local bk = mlc:FindFirstChild("BoundKeys") or Instance.new("StringValue",mlc)
		bk.Name = "BoundKeys"; bk.Value = "LeftControl"
	end)
	notify("CtrlLock","Shift lock bound to LeftControl")
end
CommandActions.unctrllock = function()
	pcall(function()
		local mlc = player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
		local bk = mlc:FindFirstChild("BoundKeys") or Instance.new("StringValue",mlc)
		bk.Name = "BoundKeys"; bk.Value = "LeftShift"
	end)
	notify("CtrlLock","Shift lock restored to LeftShift")
end
CommandActions.deleteselectedtool = function()
	if player.Character then
		for _,v in pairs(player.Character:GetChildren()) do
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
	copy(DISCORD_LINK)
	notify("Discord","Copied: "..DISCORD_LINK)
end
CommandActions.emote = function(args)
	local id = args and args[1]
	if not id then notify("Emote","Provide an asset ID"); return end
	local hum = getHumanoid(player.Character)
	if hum then
		if not pcall(function() hum:PlayEmoteAndGetAnimTrackById(tonumber(id)) end) then
			CommandActions.animation(args)
		else
			Settings.keep("emote", args)
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
	for _,v in pairs(workspace:GetDescendants()) do
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
	notify("FlySpeed",tostring(iyflyspeed))
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
		_freecamPos = Vector3.new(wp[1],wp[2],wp[3])
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
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Goto","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local root = getRoot(player.Character)
			local troot = p.Character and getRoot(p.Character)
			if root and troot then
				root.CFrame = troot.CFrame + Vector3.new(3,0,0)
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
				for _,g in pairs(guis) do if g.Visible then g:Destroy() end end
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
	scale = math.clamp(scale, 0.85, 2)
	window.Size = UDim2.new(0, math.floor(520*scale), 0, math.floor(360*scale))
	notify("GuiScale","Set to "..scale)
end
CommandActions.handlekill = function(args)
	if not firetouchinterest then notify("HandleKill","Not supported by executor"); return end
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("HandleKill","Select a target"); return end
	local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then notify("HandleKill","Equip a tool with a Handle first"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
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
	for _,v in pairs(playerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ScrollingFrame") or v:IsA("ImageLabel")) and v.Visible then
			v.Visible = false
			table.insert(_hiddenGUIs, v)
		end
	end
	notify("HideGuis","Hidden "..(#_hiddenGUIs).." GUIs")
end
CommandActions.unhideguis = function()
	for _,v in pairs(_hiddenGUIs) do
		pcall(function() v.Visible = true end)
	end
	_hiddenGUIs = {}
	notify("HideGuis","Restored")
end
CommandActions.hideiy = function()
	window.Visible = false
	notify("HideIY","Press "..Settings.toggleKey.Name.." to restore")
end
CommandActions.showiy = function()
	window.Visible = true
end
CommandActions.hidewaypoints = function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v.Name == "DevXWaypointPart" then v:Destroy() end
	end
	notify("HideWaypoints","Done")
end
CommandActions.showwaypoints = function()
	CommandActions.hidewaypoints()
	local count = 0
	for name, wp in pairs(_waypoints) do
		count += 1
		local part = Instance.new("Part"); part.Name = "DevXWaypointPart"; part.Anchored = true; part.CanCollide = false
		part.Size = Vector3.new(3,3,3); part.Transparency = 0.5
		part.CFrame = CFrame.new(wp[1],wp[2],wp[3]); part.Parent = workspace
		local box = Instance.new("BoxHandleAdornment"); box.Name = "DevXWaypoint"
		box.Adornee = part; box.AlwaysOnTop = true; box.Size = part.Size
		box.Transparency = 0.3; box.Color = BrickColor.new("Bright blue"); box.Parent = part
		local bg = Instance.new("BillboardGui"); bg.AlwaysOnTop = true
		bg.Size = UDim2.new(0,100,0,30); bg.StudsOffset = Vector3.new(0,4,0); bg.Adornee = part; bg.Parent = part
		local tl = Instance.new("TextLabel"); tl.BackgroundTransparency = 1; tl.Size = UDim2.new(1,0,1,0)
		tl.TextColor3 = Color3.new(1,1,1); tl.TextStrokeTransparency = 0; tl.Font = Enum.Font.GothamBold
		tl.TextSize = 14; tl.Text = name; tl.Parent = bg
	end
	notify("ShowWaypoints","Showing "..count.." waypoints")
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
CommandActions.inviteprompt = function()
	if not pcall(function() SocialService:PromptGameInvite(player) end) then
		notify("InvitePrompt","Invites are not available in this game")
	end
end
CommandActions.jobid = function()
	copy(game.JobId)
	notify("JobId","Copied: "..game.JobId)
end
CommandActions.jumppower = function(args)
	CommandActions.jpower(args)
end
CommandActions.lastcommand = function()
	if Settings.lastCmd ~= "" then
		commandInput.Text = Settings.lastCmd
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
	Settings.switchTab("logs")
end
CommandActions.loopanimation = function()
	CommandActions.loopanim()
end
CommandActions.loopfullbright = function()
	if _loopFBConn then _loopFBConn:Disconnect() end
	_loopFBConn = RunService.RenderStepped:Connect(applyFullbright)
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
	for _,v in pairs(char:GetDescendants()) do
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
	CommandActions.dex()
end
CommandActions.mouseteleport = function()
	local root = getRoot(player.Character)
	local mouse = player:GetMouse()
	if root and mouse.Hit then
		root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
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
		for _,v in pairs(player.Character:GetDescendants()) do
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
	notify("DevX", table.concat(args," "))
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
		local s = pcall(loadstring, game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/console.lua"))
		if s then pcall(s) end
	end)
end
CommandActions.partname = function()
	local mouse = player:GetMouse()
	notify("PartName","Click a part to copy its full path")
	local conn
	conn = mouse.Button1Down:Connect(function()
		conn:Disconnect()
		local target = mouse.Target
		if target then
			local full = target:GetFullName()
			copy(full)
			notify("PartName", full)
		else
			notify("PartName","Nothing under the mouse")
		end
	end)
end
CommandActions.pathfindwalkto = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("PathfindWalkTo","Select a target"); return end
	getgenv().devxPathfind = true
	local path = game:GetService("PathfindingService"):CreatePath()
	task.spawn(function()
		while getgenv().devxPathfind do
			for _,p in pairs(Players:GetPlayers()) do
				if p.Name:lower():sub(1,#name)==name:lower() and p.Character then
					local hum = getHumanoid(player.Character)
					local root = getRoot(player.Character)
					local troot = getRoot(p.Character)
					if hum and root and troot then
						pcall(function()
							path:ComputeAsync(root.Position, troot.Position)
							for _,wp in pairs(path:GetWaypoints()) do
								if not getgenv().devxPathfind then break end
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
	getgenv().devxPathfind = true
	local path = game:GetService("PathfindingService"):CreatePath()
	local hum = getHumanoid(player.Character)
	local root = getRoot(player.Character)
	if hum and root then
		task.spawn(function()
			pcall(function()
				path:ComputeAsync(root.Position, Vector3.new(wp[1],wp[2],wp[3]))
				for _,wpt in pairs(path:GetWaypoints()) do
					if not getgenv().devxPathfind then break end
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
		return SocialService:CanSendCallInviteAsync(player)
	end)
	if ok and canCall then
		pcall(function() SocialService:PromptPhoneBook(player,"") end)
	else
		notify("Phonebook","Voice chat or phonebook not available")
	end
end
CommandActions.promptr15 = function()
	pcall(function()
		local hum = getHumanoid(player.Character)
		if hum then
			game:GetService("AvatarEditorService"):PromptSaveAvatar(hum.HumanoidDescription, Enum.HumanoidRigType.R15)
		end
	end)
end
CommandActions.promptr6 = function()
	pcall(function()
		local hum = getHumanoid(player.Character)
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
CommandActions.rejoin = function()
	rejoinServer()
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
	if Settings.oldLighting.Ambient then Lighting.Ambient = Settings.oldLighting.Ambient end
	if Settings.oldLighting.Brightness then Lighting.Brightness = Settings.oldLighting.Brightness end
	if Settings.oldLighting.ClockTime then Lighting.ClockTime = Settings.oldLighting.ClockTime end
	if Settings.oldLighting.FogEnd then Lighting.FogEnd = Settings.oldLighting.FogEnd end
	if Settings.oldLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = Settings.oldLighting.GlobalShadows end
	notify("RestoreLighting","Restored")
end
CommandActions.rolewatchleave = function()
	if getgenv().devxRolewatch then
		getgenv().devxRolewatchLeave = not getgenv().devxRolewatchLeave
		notify("RolewatchLeave", getgenv().devxRolewatchLeave and "Will leave on trigger" or "Will only notify on trigger")
	else
		notify("RolewatchLeave","Enable rolewatch first")
	end
end
CommandActions.rolewatchstop = function()
	if getgenv().devxRolewatch then getgenv().devxRolewatch:Disconnect(); getgenv().devxRolewatch = nil end
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
	for _,v in pairs(playerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and not v.Visible then
			v.Visible = true; table.insert(_invisGUIs, v)
		end
	end
	notify("ShowGuis","Showing "..(#_invisGUIs).." GUIs")
end
CommandActions.unshowguis = function()
	for _,v in pairs(_invisGUIs) do pcall(function() v.Visible = false end) end
	_invisGUIs = {}
	notify("ShowGuis","Restored")
end
CommandActions.simplespy = function()
	notify("SimpleSpy","Loading...")
	pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))() end)
end
CommandActions.spectate = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("Spectate","Select a target"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
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
	workspace.CurrentCamera.CameraSubject = getHumanoid(player.Character)
	notify("Spectate","Stopped")
end
CommandActions.viewpart = function(args)
	local name = args and table.concat(args," ")
	if not name then notify("ViewPart","Provide a part name"); return end
	for _,v in pairs(workspace:GetDescendants()) do
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
	local oldIndex; oldIndex = hookmetamethod(game,"__index",newcclosure(function(self,key)
		if not checkcaller() and typeof(self)=="Instance" and self:IsA("Humanoid") and
			(key=="JumpPower" or key=="JumpHeight") and self:IsDescendantOf(char) then
			return jp
		end
		return oldIndex(self,key)
	end))
	notify("SpoofJP",tostring(jp))
end
CommandActions.spoofspeed = function(args)
	if not hookmetamethod then notify("SpoofSpeed","Not supported by executor"); return end
	local spd = tonumber(args and args[1]) or 16
	local char = player.Character
	local oldIndex; oldIndex = hookmetamethod(game,"__index",newcclosure(function(self,key)
		if not checkcaller() and typeof(self)=="Instance" and self:IsA("Humanoid") and
			key=="WalkSpeed" and self:IsDescendantOf(char) then
			return spd
		end
		return oldIndex(self,key)
	end))
	notify("SpoofSpeed",tostring(spd))
end
CommandActions.stopanimations = function()
	CommandActions.stopanim()
end
CommandActions.team = function(args)
	local name = args and table.concat(args," ")
	if not name then notify("Team","Provide a team name"); return end
	for _,t in pairs(game:GetService("Teams"):GetChildren()) do
		if t.Name:lower():find(name:lower()) then
			if firetouchinterest then
				for _,v in pairs(workspace:GetDescendants()) do
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
			root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
			breakVelocity()
		end
	end)
	notify("TeleportTool","Added to backpack")
end
CommandActions.togglefs = function()
	pcall(function() GuiService:ToggleFullscreen() end)
end
CommandActions.toggleswim = function()
	if _swimConn then CommandActions.unswim() else CommandActions.swim() end
end
CommandActions.togglexray = function()
	xrayEnabled = not xrayEnabled
	for _,v in pairs(workspace:GetDescendants()) do
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
	box.Size = Vector3.new(10,1,10); box.Position = Vector3.new(0,10000,0); box.Parent = workspace
	local loc = getRoot(char).Position
	box.Touched:Connect(function(part)
		if part.Parent and part.Parent.Name == player.Name and not touched then
			touched = true
			local no = char.HumanoidRootPart:Clone()
			task.wait(0.25); char.HumanoidRootPart:Destroy()
			no.Parent = char; char:MoveTo(loc); touched = false
		end
	end)
	char:MoveTo(Vector3.new(0,10000.5,0))
	notify("ToolInvisible","Done")
end
CommandActions.tools = function()
	local function copyTools(container)
		for _,v in pairs(container:GetDescendants()) do
			if v:IsA("Tool") or v:IsA("HopperBin") then
				v:Clone().Parent = player:FindFirstChildWhichIsA("Backpack")
			end
		end
	end
	copyTools(ReplicatedStorage)
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
	for _,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower()==cls:lower() and v:IsA("BasePart") then
			TweenService:Create(root,TweenInfo.new(_tweenSpeed,Enum.EasingStyle.Linear),{CFrame=v.CFrame+Vector3.new(0,3,0)}):Play()
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
	for _, v in ipairs(getgenv().devxVehicleParts or {}) do
		if v.Parent then v.CanCollide = true end
	end
	getgenv().devxVehicleParts = {}
	CommandActions.clip()
	notify("VehicleClip","Collision restored")
end
CommandActions.vehiclefly = function(args)
	NOFLY(); task.wait()
	if args and tonumber(args[1]) then vehicleflyspeed = tonumber(args[1]) end
	local hum = getHumanoid(player.Character)
	if not (hum and hum.SeatPart) then notify("VehicleFly","Sit in a vehicle first"); return end
	sFLY(true)
	notify("VehicleFly","Enabled")
end
CommandActions.vehicleflyspeed = function(args)
	vehicleflyspeed = tonumber(args and args[1]) or 1
	notify("VehicleFlySpeed",tostring(vehicleflyspeed))
end
CommandActions.vehiclegoto = function(args)
	local name = args and args[1]
	if not name and Settings.target then name = Settings.target.Name end
	if not name then notify("VehicleGoto","Select a target"); return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not seat then notify("VehicleGoto","Sit in a vehicle first"); return end
	local vehicle = seat:FindFirstAncestorWhichIsA("Model")
	if not vehicle then notify("VehicleGoto","No vehicle found"); return end
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name)==name:lower() then
			local troot = p.Character and getRoot(p.Character)
			if troot then vehicle:PivotTo(troot:GetPivot()) end
			break
		end
	end
end
CommandActions.vehiclenoclip = function()
	local hum = getHumanoid(player.Character)
	local seat = hum and hum.SeatPart
	if not seat then notify("VehicleNoclip","Sit in a vehicle first"); return end
	local vehicle = seat:FindFirstAncestorWhichIsA("Model")
	getgenv().devxVehicleParts = {}
	if vehicle then
		for _,v in pairs(vehicle:GetDescendants()) do
			if v:IsA("BasePart") and v.CanCollide then
				v.CanCollide = false
				table.insert(getgenv().devxVehicleParts, v)
			end
		end
	end
	CommandActions.noclip()
	notify("VehicleNoclip","Enabled")
end
CommandActions.walktoposition = function(args)
	local x,y,z = tonumber(args and args[1]),tonumber(args and args[2]),tonumber(args and args[3])
	if not(x and y and z) then notify("WalkToPosition","Provide X Y Z"); return end
	local hum = getHumanoid(player.Character)
	if hum then hum:MoveTo(Vector3.new(x,y,z)) end
end
CommandActions.walktowaypoint = function(args)
	local name = args and table.concat(args," ")
	if not name then notify("WalkToWaypoint","Provide a name"); return end
	local wp = _waypoints[name]
	if not wp then notify("WalkToWaypoint","Waypoint not found"); return end
	local hum = getHumanoid(player.Character)
	if hum then hum:MoveTo(Vector3.new(wp[1],wp[2],wp[3])) end
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
	local x,y,z = tonumber(args and args[2]),tonumber(args and args[3]),tonumber(args and args[4])
	if not(name and x and y and z) then notify("WaypointPos","Provide name X Y Z"); return end
	_waypoints[name] = {x,y,z}
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
	kill=1, loopkill=1, freeze=1, freezeplr=1, unfreezeplr=1,
	loopfreeze=1, bring=1, tp=1, jail=1, unjail=1, lookat=1, handlekill=1,
	fcgoto=1, freecamgoto=1, muteboombox=1, unmuteboombox=1,
	tweengoto=1, pulsetp=1, pmspam=1, unpmspam=1,
	listento=1, mutevc=1, unmutevc=1, joindate=1, chatjoindate=1,
	chatage=1, copyname=1, appearanceid=1, copyappearanceid=1,
	tpunanchored=1, copyanimation=1, fling=1, jerkontarget=1,
	bangontarget=1, reversebang=1, suck=1, backpack=1,
	predictiontp=1, spectate=1, vehiclegoto=1, pathfindwalkto=1,
	notifyposition=1, copyposition=1,
}
Settings.resumable = Settings.resumable or {}
for k, v in pairs({
	dance = "undance", spasm = "unspasm", bang = "unbang", bangontarget = "unbangontarget",
	reversebang = "unreversebang", jerkontarget = "unjerkontarget", suck = "unsuck",
	backpack = "unbackpack", animation = "stopanims", emote = "stopanims",
}) do Settings.resumable[k] = v end

Settings.stoppers = {
	noclip = "clip", fly = "unfly", cfly = "uncfly", cframefly = "uncframefly", vehiclefly = "unvehiclefly",
	loopfly = "unloopfly", spin = "unspin", flingspin = "unflingspin", walkfling = "unwalkfling",
	flyfling = "unflyfling", loopflingspin = "unloopflingspin", noclipflingspin = "unflingspin",
	strengthenflingspin = "unflingspin", weakenflingspin = "unflingspin", toggleflingspin = "unflingspin",
	fling = "unfling", swim = "unswim", toggleswim = "unswim", float = "unfloat", infjump = "uninfjump",
	infinitejump = "uninfinitejump", antifling = "unantifling", antifling2 = "unantifling2",
	toggleantifling = "unantifling", antivoid = "unantivoid", antivoid2 = "unantivoid2", antibang = "unantibang",
	antiafk = "unantiafk2", antiidle = "unantiafk2", antiafk2 = "unantiafk2", antisite = "unantisite",
	antijump = "unantijump", walltp = "unwalltp", autojump = "unautojump", tpwalk = "untpwalk",
	edgejump = "unedgejump", flyjump = "unflyjump", freecam = "unfreecam", spectate = "unspectate",
	hovername = "unhovername", facecam = "unfacecam", rainbow = "unrainbow", loopxray = "unloopxray",
	loopfullbright = "unloopfullbright", loopnobgui = "unloopnobgui", loopoof = "unloopoof",
	grabtools = "ungrabtools", removeads = "unremoveads", guidelete = "unguidelete",
	instantproximityprompts = "uninstantproximityprompts", alignmentkeys = "unalignmentkeys",
	autoclick = "unautoclick", autokeypress = "unautokeypress", spam = "unspam", pmspam = "unpmspam",
	loopgoto = "unloopgoto", loopbring = "unloopbring", orbit = "unorbit", carpet = "uncarpet",
	stareat = "unstareat", walkto = "unwalkto", loopkill = "unloopkill", loopfreeze = "unloopfreeze",
	esp = "noesp", espteam = "noesp", chams = "nochams", invisible = "visible", anchor = "unanchor",
	freeze = "thaw", stun = "unstun", norotate = "autorotate", platformstand = "unplatformstand",
	glow = "unglow", trail = "untrail", sparkles = "unsparkles", fire = "unfire", smoke = "unsmoke",
	blur = "unblur", giant = "normalsize", tiny = "normalsize", flashlight = "unflashlight",
	light = "nolight", jail = "unjail", gravity = "resetgravity", lowgravity = "resetgravity",
	highgravity = "resetgravity", xray = "unxray", togglexray = "unxray", headsit = "breakloops",
	pathfindwalkto = "breakloops",
}

for k, v in pairs(animCmds or {}) do CommandActions[k] = v end

CommandActions = CommandActions
Commands = Commands
targetCmds = playerTargetCmds
end)();

(function()
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	local targetPanel = Instance.new("Frame")
	targetPanel.Name                   = "TargetPanel"
	targetPanel.Position               = UDim2.new(0,SIDE_W,0,32)
	targetPanel.Size                   = UDim2.new(1,-SIDE_W,1,-32)
	targetPanel.BackgroundTransparency = 1
	targetPanel.BorderSizePixel        = 0
	targetPanel.Visible                = false
	targetPanel.Parent                 = window

	local tabTarget, tabTargetUnderline = sideTab("T", "Target", 3)

	local targetSection = Instance.new("Frame")
	targetSection.Name = "TargetSection"
	targetSection.BackgroundColor3 = Color3.fromRGB(25,25,25)
	targetSection.BackgroundTransparency = 0.2
	targetSection.BorderSizePixel = 0
	targetSection.Position = UDim2.new(0,6,0,6)
	targetSection.Size = UDim2.new(1,-12,0,84)
	targetSection.Parent = targetPanel
	Instance.new("UICorner",targetSection).CornerRadius = UDim.new(0,6)

	local targetAvatar = Instance.new("ImageLabel")
	targetAvatar.Name = "TargetAvatar"
	targetAvatar.BackgroundColor3 = Color3.fromRGB(40,40,40)
	targetAvatar.BorderSizePixel = 0
	targetAvatar.Position = UDim2.new(0,8,0,8)
	targetAvatar.Size = UDim2.new(0,68,0,68)
	targetAvatar.Image = ""
	targetAvatar.Parent = targetSection
	Instance.new("UICorner",targetAvatar).CornerRadius = UDim.new(0,4)

	local targetInfoFrame = Instance.new("Frame")
	targetInfoFrame.BackgroundTransparency = 1
	targetInfoFrame.Position = UDim2.new(0,84,0,8)
	targetInfoFrame.Size = UDim2.new(1,-168,0,68)
	targetInfoFrame.Parent = targetSection

	local targetDisplayName = Instance.new("TextLabel")
	targetDisplayName.BackgroundTransparency = 1
	targetDisplayName.Size = UDim2.new(1,0,0,18)
	targetDisplayName.Font = Enum.Font.GothamBold
	targetDisplayName.TextSize = 14
	targetDisplayName.TextColor3 = Colors.white
	targetDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	targetDisplayName.Text = "—"
	targetDisplayName.Parent = targetInfoFrame

	local targetUsername = Instance.new("TextLabel")
	targetUsername.BackgroundTransparency = 1
	targetUsername.Position = UDim2.new(0,0,0,18)
	targetUsername.Size = UDim2.new(1,0,0,14)
	targetUsername.Font = Enum.Font.Gotham
	targetUsername.TextSize = 11
	targetUsername.TextColor3 = Colors.gray150
	targetUsername.TextXAlignment = Enum.TextXAlignment.Left
	targetUsername.Text = "@—"
	targetUsername.Parent = targetInfoFrame

	local targetId = Instance.new("TextLabel")
	targetId.BackgroundTransparency = 1
	targetId.Position = UDim2.new(0,0,0,32)
	targetId.Size = UDim2.new(1,0,0,13)
	targetId.Font = Enum.Font.Gotham
	targetId.TextSize = 10
	targetId.TextColor3 = Colors.gray120
	targetId.TextXAlignment = Enum.TextXAlignment.Left
	targetId.Text = "ID: —"
	targetId.Parent = targetInfoFrame

	targetCreated = Instance.new("TextLabel")
	targetCreated.BackgroundTransparency = 1
	targetCreated.Position = UDim2.new(0,0,0,45)
	targetCreated.Size = UDim2.new(1,0,0,13)
	targetCreated.Font = Enum.Font.Gotham
	targetCreated.TextSize = 10
	targetCreated.TextColor3 = Colors.gray120
	targetCreated.TextXAlignment = Enum.TextXAlignment.Left
	targetCreated.Text = "Joined: —"
	targetCreated.Parent = targetInfoFrame

	local targetToolBtn = Instance.new("ImageButton")
	targetToolBtn.Name = "TargetToolBtn"
	targetToolBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	targetToolBtn.BorderSizePixel = 0
	targetToolBtn.Position = UDim2.new(1,-46,0,10)
	targetToolBtn.Size = UDim2.new(0,38,0,38)
	targetToolBtn.Image = "rbxassetid://13769558274"
	targetToolBtn.ScaleType = Enum.ScaleType.Fit
	targetToolBtn.Parent = targetSection
	Instance.new("UICorner",targetToolBtn).CornerRadius = UDim.new(0,4)
	Outline.add(targetToolBtn, targetPanel)

	local targetToolLabel = Instance.new("TextLabel")
	targetToolLabel.BackgroundTransparency = 1
	targetToolLabel.Position = UDim2.new(1,-46,0,50)
	targetToolLabel.Size = UDim2.new(0,38,0,12)
	targetToolLabel.Font = Enum.Font.Gotham
	targetToolLabel.TextSize = 9
	targetToolLabel.TextColor3 = Color3.fromRGB(100,100,100)
	targetToolLabel.TextXAlignment = Enum.TextXAlignment.Center
	targetToolLabel.Text = "Click Tool"
	targetToolLabel.Parent = targetSection

	local targetSearchRow = Instance.new("Frame")
	targetSearchRow.BackgroundTransparency = 1
	targetSearchRow.Position = UDim2.new(0,6,0,96)
	targetSearchRow.Size = UDim2.new(1,-12,0,24)
	targetSearchRow.Parent = targetPanel

	local targetSearchBox = Instance.new("TextBox")
	targetSearchBox.Name = "TargetSearchBox"
	targetSearchBox.BackgroundColor3 = Colors.gray30
	targetSearchBox.BorderSizePixel = 0
	targetSearchBox.Size = UDim2.new(1,0,1,0)
	targetSearchBox.Font = Enum.Font.Gotham
	targetSearchBox.TextSize = 12
	targetSearchBox.TextColor3 = Colors.white
	targetSearchBox.PlaceholderText = "🔍  Search player name..."
	targetSearchBox.PlaceholderColor3 = Colors.gray90
	targetSearchBox.Text = ""
	targetSearchBox.ClearTextOnFocus = false
	targetSearchBox.TextXAlignment = Enum.TextXAlignment.Left
	targetSearchBox.Parent = targetSearchRow
	Instance.new("UICorner",targetSearchBox).CornerRadius = UDim.new(0,4)
	Instance.new("UIPadding",targetSearchBox).PaddingLeft = UDim.new(0,10)

	local function setTarget(plr)
		Settings.target = plr
		Settings.awayId = nil
		targetDisplayName.Text = plr.DisplayName
		targetUsername.Text = "@"..plr.Name
		targetId.Text = "ID: "..tostring(plr.UserId)
		targetCreated.Text = "Joined: "..os.date("%m/%d/%Y", os.time() - plr.AccountAge * 86400)
		pcall(function()
			targetAvatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size100x100)
		end)
	end

	setTarget(player)

	Settings.link(Players.PlayerRemoving:Connect(function(plr)
		if plr == Settings.target and plr ~= player then
			Settings.awayId = plr.UserId
			targetUsername.Text = "@"..plr.Name.." (left)"
			notify("Target", plr.DisplayName.." (@"..plr.Name..") left the game")
		end
	end))

	Settings.link(Players.PlayerAdded:Connect(function(plr)
		if Settings.awayId and plr.UserId == Settings.awayId then
			setTarget(plr)
			notify("Target", plr.DisplayName.." (@"..plr.Name..") is back")
		end
	end))

	targetSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = targetSearchBox.Text:lower()
		if q == "" then return end
		for _,p in pairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1,#q) == q or p.DisplayName:lower():sub(1,#q) == q then
				setTarget(p); break
			end
		end
	end)

	targetToolBtn.MouseButton1Click:Connect(function()
		for _,P in ipairs(player.Backpack:GetChildren()) do if P.Name == "ClickTarget" then P:Destroy() end end
		for _,P in ipairs(player.Character:GetChildren()) do if P.Name == "ClickTarget" then P:Destroy() end end
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

	targetCreated = targetCreated

	local commandList = Instance.new("ScrollingFrame")
	commandList.Name = "TargetCommandList"
	commandList.Position = UDim2.new(0,6,0,126)
	commandList.Size = UDim2.new(1,-12,1,-132)
	commandList.BackgroundTransparency = 1
	commandList.BorderSizePixel = 0
	commandList.ClipsDescendants = true
	commandList.ScrollBarThickness = 4
	commandList.ScrollBarImageColor3 = Colors.gray90
	commandList.CanvasSize = UDim2.new(0,0,0,0)
	commandList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	commandList.Parent = targetPanel

	local listLayout = Instance.new("UIListLayout", commandList)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0,4)

	local listPadding = Instance.new("UIPadding", commandList)
	listPadding.PaddingTop = UDim.new(0,2)
	listPadding.PaddingBottom = UDim.new(0,8)

	local extraArg = {
		hitbox   = { kind = "slider", label = "Size (studs)",  min = 1, max = 50, step = 1, default = 10 },
		headsize = { kind = "slider", label = "Head size",     min = 1, max = 20, step = 1, default = 5 },
		pulsetp  = { kind = "slider", label = "Seconds",       min = 1, max = 30, step = 1, default = 1 },
		fling    = { kind = "slider", label = "Seconds",       min = 1, max = 30, step = 1, default = 8 },
		whisper  = { kind = "text",   label = "Message" },
		pmspam   = { kind = "text",   label = "Message" },
	}

	local niceNames = {
		["goto"] = "Go to", tp = "Teleport to", bring = "Bring", kill = "Kill",
		loopkill = "Loop kill", freeze = "Freeze", freezeplr = "Freeze",
		orbit = "Orbit", carpet = "Carpet", headsit = "Head-sit", jail = "Jail",
		friend = "Friend request", unfriend = "Unfriend", spectate = "Spectate",
		info = "Player info", userid = "Copy user ID", age = "Account age",
		locate = "Locate (ESP)", chams = "Chams", hitbox = "Hitbox", headsize = "Head size",
		pulsetp = "Pulse teleport", fling = "Fling", whisper = "Whisper", pmspam = "PM spam",
	}

	local function labelOf(name)
		return niceNames[name] or (name:sub(1,1):upper() .. name:sub(2))
	end

	local function run(cmdText)
		commandInput.Text = cmdText
		executeCommand()
	end

	local function newSlider(parent, spec)
		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1,0,0,34)
		wrap.Parent = parent

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0,110,0,16)
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.TextColor3 = Colors.gray150
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = spec.label
		label.Parent = wrap

		local box = Instance.new("TextBox")
		box.AnchorPoint = Vector2.new(1,0)
		box.Position = UDim2.new(1,0,0,0)
		box.Size = UDim2.new(0,52,0,20)
		box.BackgroundColor3 = Colors.gray35
		box.BorderSizePixel = 0
		box.Font = Enum.Font.Code
		box.TextSize = 12
		box.TextColor3 = Colors.white
		box.ClearTextOnFocus = true
		box.Text = tostring(spec.default)
		box.Parent = wrap
		Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

		local track = Instance.new("Frame")
		track.Position = UDim2.new(0,0,0,22)
		track.Size = UDim2.new(1,-60,0,6)
		track.BackgroundColor3 = Color3.fromRGB(60,60,60)
		track.BorderSizePixel = 0
		track.Parent = wrap
		Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0,0,1,0)
		fill.BackgroundColor3 = Theme.accent
		fill.BorderSizePixel = 0
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

		local hit = Instance.new("TextButton")
		hit.Size = UDim2.new(1,0,0,22)
		hit.Position = UDim2.new(0,0,-0.5,0)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Parent = track

		local value = spec.default

		local function refresh()
			local v = math.clamp(value, spec.min, spec.max)
			fill.Size = UDim2.new((v - spec.min) / (spec.max - spec.min), 0, 1, 0)
			box.Text = tostring(v)
		end
		local function setValue(v)
			value = math.clamp(math.floor(v / spec.step + 0.5) * spec.step, spec.min, spec.max)
			refresh()
		end
		local function fromX(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
			setValue(spec.min + rel * (spec.max - spec.min))
		end

		local dragging = false
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				fromX(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				fromX(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n then setValue(n) else refresh() end
		end)

		refresh()
		return wrap, function() return value end
	end

	local function newTextBox(parent, spec)
		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1,0,0,26)
		wrap.Parent = parent

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1,0,1,0)
		box.BackgroundColor3 = Colors.gray35
		box.BorderSizePixel = 0
		box.Font = Enum.Font.Gotham
		box.TextSize = 12
		box.TextColor3 = Colors.white
		box.PlaceholderText = spec.label
		box.PlaceholderColor3 = Colors.gray90
		box.ClearTextOnFocus = false
		box.Text = ""
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.Parent = wrap
		Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
		Instance.new("UIPadding", box).PaddingLeft = UDim.new(0,8)

		return wrap, function() return box.Text end
	end

	local function newButton(parent, text, w)
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Colors.gray30
		btn.BackgroundTransparency = 0.1
		btn.Size = UDim2.new(0, w or 60, 0, 24)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Colors.white
		btn.Text = text
		btn.Parent = parent
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
		return btn
	end

	local function addRow(name, order)
		local stopName = (Settings.stoppers and Settings.stoppers[name]) or (Settings.resumable and Settings.resumable[name])
		local spec = extraArg[name]

		local row = Instance.new("Frame")
		row.Name = name
		row.LayoutOrder = order
		row.BackgroundColor3 = Colors.gray30
		row.BackgroundTransparency = 0.35
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1,0,0,32)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.ClipsDescendants = true
		row.Parent = commandList
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
		local rowPad = Instance.new("UIPadding", row)
		rowPad.PaddingLeft = UDim.new(0,8); rowPad.PaddingRight = UDim.new(0,8)
		rowPad.PaddingTop = UDim.new(0,4); rowPad.PaddingBottom = UDim.new(0,4)

		local head = Instance.new("Frame")
		head.BackgroundTransparency = 1
		head.Size = UDim2.new(1,0,0,24)
		head.Parent = row

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1,-140,1,0)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = Colors.white
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = labelOf(name)
		label.Parent = head

		local extra = Instance.new("Frame")
		extra.BackgroundTransparency = 1
		extra.Position = UDim2.new(0,0,0,28)
		extra.Size = UDim2.new(1,0,0,0)
		extra.AutomaticSize = Enum.AutomaticSize.Y
		extra.Visible = false
		extra.Parent = row

		local getValue = nil
		if spec then
			local ctrl, get
			if spec.kind == "slider" then ctrl, get = newSlider(extra, spec)
			else ctrl, get = newTextBox(extra, spec) end
			getValue = get
			local goBtn = newButton(extra, "Go", 60)
			goBtn.Position = UDim2.new(1,-60,0, spec.kind == "slider" and 40 or 32)
			local function fire()
				local v = getValue()
				if spec.kind == "text" and (not v or v == "") then
					notify("Target", "Enter a message first")
					return
				end
				run(name.." "..tostring(v))
			end
			goBtn.MouseButton1Click:Connect(fire)
		end

		if stopName then
			local onBtn = newButton(head, "On", 46)
			onBtn.Position = UDim2.new(1,-100,0,0)
			onBtn.BackgroundColor3 = Theme.accent
			local offBtn = newButton(head, "Off", 46)
			offBtn.Position = UDim2.new(1,-48,0,0)

			if spec then
				onBtn.MouseButton1Click:Connect(function() extra.Visible = not extra.Visible end)
			else
				onBtn.MouseButton1Click:Connect(function() run(name) end)
			end
			offBtn.MouseButton1Click:Connect(function() run(stopName) end)
		else
			local runBtn = newButton(head, spec and "Set up" or "Run", spec and 70 or 60)
			runBtn.Position = UDim2.new(1, -(spec and 70 or 60), 0, 0)
			if spec then
				runBtn.MouseButton1Click:Connect(function() extra.Visible = not extra.Visible end)
			else
				runBtn.MouseButton1Click:Connect(function() run(name) end)
			end
		end
	end

	local skip = {}
	for _, stop in pairs(Settings.stoppers or {}) do skip[stop] = true end
	for _, stop in pairs(Settings.resumable or {}) do skip[stop] = true end

	local names = {}
	for name in pairs(targetCmds or {}) do
		if not skip[name] then table.insert(names, name) end
	end
	table.sort(names)
	for i, name in ipairs(names) do
		addRow(name, i)
	end

	Theme.bind(function()
		tabTargetUnderline.BackgroundColor3 = Theme.accent
	end)

	addTab("target", tabTarget, tabTargetUnderline, targetPanel)
end)()

start()
