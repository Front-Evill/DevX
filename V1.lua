local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

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
		if message:find(pattern, 1, true) then
			return true
		end
	end
	return false
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
window.Position = UDim2.new(0, vp.X / 2 - 260, 0, vp.Y / 2 - 180)
window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
window.BackgroundTransparency = 0.2
window.BorderSizePixel = 0
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
subtitle.Position = UDim2.new(0, 52, 0, 2)
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

local function copy(str) return pcall(function() setclipboard(str) end) end

local function nty(notifTitle, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = notifTitle,
			Text = text,
			Duration = 4,
		})
	end)
end

local function Sound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

discordBtn.MouseButton1Click:Connect(function()
	if copy("discord.gg/xPMwC2DTeg") then
		nty("DevX", "Link copied")
		Sound("rbxassetid://9117492353")
	end
end)

local function Added(kind, message)
	lineNum += 1

	local entryIcon, entryColor
	if kind == "Print" then
		entryIcon = "rbxassetid://10723367380"
		entryColor = Color3.fromRGB(255, 255, 255)
	elseif kind == "Warn" then
		entryIcon = "rbxassetid://10709753149"
		entryColor = Color3.fromRGB(255, 214, 0)
	elseif kind == "Error" then
		entryIcon = "rbxassetid://10709753064"
		entryColor = Color3.fromRGB(255, 70, 70)
	end

	local row = Instance.new("Frame")
	row.Name = "Entry"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = lineNum
	row.Parent = content

	local lineLabel = Instance.new("TextLabel")
	lineLabel.Name = "LineNumber"
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
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 26, 0, 1)
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.Image = entryIcon
	icon.ImageColor3 = entryColor
	icon.Parent = row

	local dash = Instance.new("TextLabel")
	dash.Name = "Dash"
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
	text.Name = "Text"
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
	copyBtn.Name = "Copy"
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
		task.defer(function() content.CanvasPosition = Vector2.new(0, math.max(0, content.AbsoluteCanvasSize.Y - content.AbsoluteSize.Y)) end)
	end)
end

title.MouseEnter:Connect(function() if #entries > 0 then title.TextColor3 = Color3.fromRGB(80, 220, 120) end end)
title.MouseLeave:Connect(function() title.TextColor3 = Color3.fromRGB(255, 255, 255) end)

title.MouseButton1Click:Connect(function()
	if #entries == 0 then return end
	for _, entry in ipairs(entries) do entry:Destroy() end
	entries = {}
	lineNum = 0
end)

hotbar.InputBegan:Connect(function(input)
	if busy then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		busy = true
		dragging = true
		dragStart = input.Position
		startPos = window.Position

		if dragConn then
			dragConn:Disconnect()
			dragConn = nil
		end

		dragConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				dragging = false
				busy = false
				if dragConn then
					dragConn:Disconnect()
					dragConn = nil
				end
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local x = startPos.X.Offset + delta.X
		local y = startPos.Y.Offset + delta.Y
		window.Position = UDim2.new(0, x, 0, y)
	end
end)

local function BindResize(handle, xd, yd)
	local resizing = false
	local stIn, stSize, stPos
	local resizeConn
	handle.InputBegan:Connect(function(input)
		if busy then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			busy = true
			resizing = true
			stIn = input.Position
			stSize = window.Size
			stPos = window.Position

			if resizeConn then
				resizeConn:Disconnect()
				resizeConn = nil
			end

			resizeConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
					resizing = false
					busy = false
					if resizeConn then
						resizeConn:Disconnect()
						resizeConn = nil
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - stIn

			local w = stSize.X.Offset
			local h = stSize.Y.Offset
			local x = stPos.X.Offset
			local y = stPos.Y.Offset

			if xd == 1 then
				w = math.max(320, stSize.X.Offset + delta.X)
			elseif xd == -1 then
				w = math.max(320, stSize.X.Offset - delta.X)
				x = stPos.X.Offset + (stSize.X.Offset - w)
			end

			if yd == 1 then
				h = math.max(220, stSize.Y.Offset + delta.Y)
			elseif yd == -1 then
				h = math.max(220, stSize.Y.Offset - delta.Y)
				y = stPos.Y.Offset + (stSize.Y.Offset - h)
			end

			window.Size = UDim2.new(0, w, 0, h)
			window.Position = UDim2.new(0, x, 0, y)
		end
	end)
end

local function CreHandil(name, position, size, xd, yd)
	local handle = Instance.new("Frame")
	handle.Name = name
	handle.BackgroundTransparency = 1
	handle.BorderSizePixel = 0
	handle.Position = position
	handle.Size = size
	handle.ZIndex = 5
	handle.Active = true
	handle.Parent = window
	BindResize(handle, xd, yd)
end

CreHandil("ResizeRight", UDim2.new(1, -3, 0, 0), UDim2.new(0, 6, 1, 0), 1, 0)
CreHandil("ResizeLeft", UDim2.new(0, -3, 0, 0), UDim2.new(0, 6, 1, 0), -1, 0)
CreHandil("ResizeTop", UDim2.new(0, 0, 0, -3), UDim2.new(1, 0, 0, 6), 0, -1)
CreHandil("ResizeBottom", UDim2.new(0, 0, 1, -3), UDim2.new(1, 0, 0, 6), 0, 1)
CreHandil("ResizeTopLeft", UDim2.new(0, -5, 0, -5), UDim2.new(0, 10, 0, 10), -1, -1)
CreHandil("ResizeTopRight", UDim2.new(1, -5, 0, -5), UDim2.new(0, 10, 0, 10), 1, -1)
CreHandil("ResizeBottomLeft", UDim2.new(0, -5, 1, -5), UDim2.new(0, 10, 0, 10), -1, 1)
CreHandil("ResizeBottomRight", UDim2.new(1, -5, 1, -5), UDim2.new(0, 10, 0, 10), 1, 1)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F12 then window.Visible = not window.Visible end
end)

LogService.MessageOut:Connect(function(message, messageType)
	if shouldIgnore(message) then return end
	if messageType == Enum.MessageType.MessageWarning then Added("Warn", message)
	elseif messageType == Enum.MessageType.MessageError then Added("Error", message)
	else Added("Print", message)
	end
end)
