local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Http = game:GetService("HttpService")

local Folder = "Dashboard"
local Least = Vector2.new(420, 400)
local Limit = {min = 0.6, max = 1.4}
local Previews = {}
local Live = {}
local Queue = {}
local Playing = false
local Moving = false
local Target = "keyboard"
local Current

local Theme = {
    top = Color3.fromRGB(38, 38, 42),
    body = Color3.fromRGB(38, 38, 42),
    field = Color3.fromRGB(56, 56, 62),
    well = Color3.fromRGB(22, 22, 25),
    text = Color3.fromRGB(240, 240, 242),
    muted = Color3.fromRGB(150, 150, 158),
    dark = Color3.fromRGB(18, 18, 22),
    accent = Color3.fromRGB(88, 140, 255),
}

local Config = {
    keyboard = {hue = 0.6, sat = 0.75, val = 1, size = 1, on = true},
    mouse = {hue = 0.6, sat = 0.75, val = 1, size = 1, on = true},
    place = {x = 0, y = -40},
}

local Codes = {
    ["`"] = "Backquote", ["-"] = "Minus", ["="] = "Equals",
    ["["] = "LeftBracket", ["]"] = "RightBracket", ["\\"] = "BackSlash",
    [";"] = "Semicolon", ["'"] = "Quote", [","] = "Comma",
    ["."] = "Period", ["/"] = "Slash",
    ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four", ["5"] = "Five",
    ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine", ["0"] = "Zero",
}

local function make(class, props, parent)
    local item = Instance.new(class)
    if item:IsA("GuiObject") then item.BorderSizePixel = 0 end
    if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 14
        item.TextColor3 = Theme.text
    end
    if item:IsA("TextLabel") then item.BackgroundTransparency = 1 end
    if item:IsA("TextButton") then
        item.AutoButtonColor = false
        item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.15 end)
        item.MouseLeave:Connect(function() item.BackgroundTransparency = 0 end)
    end
    for key, value in props do item[key] = value end
    item.Parent = parent
    return item
end

local function corner(item, radius) return make("UICorner", {CornerRadius = UDim.new(0, radius)}, item) end

local Host = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
if Host:FindFirstChild("Dashboard") then Host.Dashboard:Destroy() end

local Gui = make("ScreenGui", {
    Name = "Dashboard",
    ResetOnSpawn = false,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
},Host)

local Window = make("Frame", {
    BackgroundColor3 = Theme.body,
    Position = UDim2.new(0.5, -260, 0.5, -270),
    Size = UDim2.fromOffset(520, 540),
},Gui)
corner(Window, 12)
make("UIStroke", {Color = Theme.field, Transparency = 0.4}, Window)

local Top = make("Frame", {
    BackgroundColor3 = Theme.top,
    Size = UDim2.new(1, 0, 0, 40),
    ZIndex = 2,
},Window)
corner(Top, 12)
make("Frame", {
    BackgroundColor3 = Theme.top,
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    ZIndex = 2,
},Top)

make("TextLabel", {
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.new(1, -36, 1, 0),
    Text = "DEVlyx Key",
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
},Top)

local Body = make("CanvasGroup", {
    BackgroundTransparency = 1,
    GroupTransparency = 1,
    Position = UDim2.fromOffset(0, 40),
    Size = UDim2.new(1, 0, 1, -40),
},Window)
corner(Body, 12)

local Scroll = make("ScrollingFrame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.muted,
    ScrollingDirection = Enum.ScrollingDirection.Y,
},Body)
make("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
},Scroll)
make("UIPadding", {
    PaddingTop = UDim.new(0, 14),
    PaddingBottom = UDim.new(0, 18),
    PaddingLeft = UDim.new(0, 18),
    PaddingRight = UDim.new(0, 22),
},Scroll)

local Hello = make("TextLabel", {
    Position = UDim2.fromOffset(0, 40),
    Size = UDim2.new(1, 0, 1, -40),
    Text = "Welcome",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 34,
    Font = Enum.Font.GothamBold,
    TextTransparency = 1,
},Window)

local function track(handle, start, finish)
    handle.InputBegan:Connect(function(input)
        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
        local update = start(input.Position)
        update(input.Position)
        local move = Input.InputChanged:Connect(function(change)
            local moved = change.UserInputType
            if moved == Enum.UserInputType.MouseMovement or moved == Enum.UserInputType.Touch then update(change.Position) end
        end)
        local stop
        stop = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                move:Disconnect()
                stop:Disconnect()
                if finish then finish() end
            end
        end)
    end)
end

track(Top, function(origin)
    local base = Window.Position
    return function(now)
        local shift = now - origin
        Window.Position = UDim2.new(base.X.Scale, base.X.Offset + shift.X, base.Y.Scale, base.Y.Offset + shift.Y)
    end
end)

local Edges = {
    {x = 0, y = -1, place = UDim2.new(0, 14, 0, -3), size = UDim2.new(1, -28, 0, 6)},
    {x = 0, y = 1, place = UDim2.new(0, 14, 1, -3), size = UDim2.new(1, -28, 0, 6)},
    {x = -1, y = 0, place = UDim2.new(0, -3, 0, 14), size = UDim2.new(0, 6, 1, -28)},
    {x = 1, y = 0, place = UDim2.new(1, -3, 0, 14), size = UDim2.new(0, 6, 1, -28)},
    {x = -1, y = -1, place = UDim2.new(0, -4, 0, -4), size = UDim2.fromOffset(16, 16)},
    {x = 1, y = -1, place = UDim2.new(1, -12, 0, -4), size = UDim2.fromOffset(16, 16)},
    {x = -1, y = 1, place = UDim2.new(0, -4, 1, -12), size = UDim2.fromOffset(16, 16)},
    {x = 1, y = 1, place = UDim2.new(1, -12, 1, -12), size = UDim2.fromOffset(16, 16)},
}

for _, edge in Edges do
    local handle = make("Frame", {
        BackgroundTransparency = 1,
        Position = edge.place,
        Size = edge.size,
        ZIndex = 10,
    }, Window)
    track(handle, function(origin)
        local base, size = Window.Position, Window.Size
        return function(now)
            local shift = now - origin
            local x, y = base.X.Offset, base.Y.Offset
            local width, height = size.X.Offset, size.Y.Offset
            if edge.x == 1 then width = math.max(Least.X, width + shift.X)
            elseif edge.x == -1 then
                local fresh = math.max(Least.X, width - shift.X)
                x = x + width - fresh
                width = fresh
            end
            if edge.y == 1 then
                height = math.max(Least.Y, height + shift.Y)
            elseif edge.y == -1 then
                local fresh = math.max(Least.Y, height - shift.Y)
                y = y + height - fresh
                height = fresh
            end
            Window.Position = UDim2.new(base.X.Scale, x, base.Y.Scale, y)
            Window.Size = UDim2.fromOffset(width, height)
        end
    end)
end

local function tone(cfg) return Color3.fromHSV(cfg.hue, cfg.sat, cfg.val) end

local function ink(color)
    local level = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return level > 0.55 and Theme.dark or Color3.new(1, 1, 1)
end

local function letters(text, first, last)
    local list = {}
    if first then table.insert(list, first) end
    for char in text:gmatch(".") do table.insert(list, {char, Codes[char] or char}) end
    if last then table.insert(list, last) end
    return list
end

local Header = {{"Esc", "Escape"}, {"", "", 1}}
for index = 1, 12 do
    table.insert(Header, {"F" .. index, "F" .. index})
    if index == 4 or index == 8 then table.insert(Header, {"", "", 0.5}) end
end

local Rows = {
    Header,
    letters("`1234567890-=", nil, {"Back", "Backspace", 2}),
    letters("QWERTYUIOP[]", {"Tab", "Tab", 1.5}, {"\\", "BackSlash", 1.5}),
    letters("ASDFGHJKL;'", {"Caps", "CapsLock", 1.75}, {"Enter", "Return", 2.25}),
    letters("ZXCVBNM,./", {"Shift", "LeftShift", 2.25}, {"Shift", "RightShift", 2.75}),
    {
        {"Ctrl", "LeftControl", 1.25},
        {"Win", "LeftSuper", 1.25},
        {"Alt", "LeftAlt", 1.25},
        {"Space", "Space", 7.5},
        {"Alt", "RightAlt", 1.25},
        {"Win", "RightSuper", 1.25},
        {"Ctrl", "RightControl", 1.25},
    },
}

local function measure(cfg)
    local board, mouse = cfg.keyboard, cfg.mouse
    local cell = 32 * board.size
    local reach = board.on and 15 * cell - 5 * board.size or 0
    local depth = board.on and 6.4 * cell - 5 * board.size or 0
    local wide = mouse.on and 64 * mouse.size or 0
    local tall = mouse.on and 104 * mouse.size or 0
    local join = board.on and mouse.on and 30 or 0
    return Vector2.new(reach + join + wide, math.max(depth, tall)), reach, depth, wide, tall
end

local function render(holder, cfg)
    local parts = {}
    local keys = {}
    local pieces = {strokes = {}, fades = {}, lines = {}}
    local board, mouse = cfg.keyboard, cfg.mouse
    local total, reach, depth, wide, tall = measure(cfg)
    local area = make("Frame",{
        Name = "Area",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(total.X, total.Y),
    },holder)
    make("UIScale", {}, area)

    if board.on then
        local scale = board.size
        local cell, gap = 32 * scale, 5 * scale
        local color = tone(board)
        local tint = color:Lerp(Color3.new(1, 1, 1), 0.3)
        local bright = color:Lerp(Color3.new(1, 1, 1), 0.35)
        local shade = ink(color)
        local radius = 6 * scale
        local offset = (total.Y - depth) / 2

        for line, row in Rows do
            local x = 0
            local y = offset + (line - 1) * cell + (line > 1 and cell * 0.4 or 0)
            for _, entry in row do
                local text, name, span = unpack(entry)
                span = span or 1
                if name ~= "" then
                    local slot = make("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(x * cell, y),
                        Size = UDim2.fromOffset(span * cell - gap, cell - gap),
                    },area)

                    local edge = make("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, 2 * scale),
                        Size = UDim2.fromScale(1, 1),
                    },slot)
                    corner(edge, radius)
                    local outline = make("UIStroke", {Color = color, Thickness = 1.5, Transparency = 0.7}, edge)

                    local glow = make("Frame", {
                        BackgroundColor3 = color,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(-2, -2),
                        Size = UDim2.new(1, 4, 1, 4),
                    },slot)
                    corner(glow, radius + 2)

                    local cap = make("Frame", {
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                    },slot)
                    corner(cap, radius)
                    local fade = make("UIGradient", {Rotation = 90, Color = ColorSequence.new(bright, color)}, cap)
                    local rim = make("UIStroke", {Color = color, Thickness = 1.5, Transparency = 0.15}, cap)
                    local label = make("TextLabel", {
                        Size = UDim2.fromScale(1, 1),
                        Text = text,
                        TextColor3 = tint,
                        TextSize = math.max(8, math.floor(12 * scale)),
                        Font = Enum.Font.GothamBold,
                    }, cap)
                    if #text > 2 then
                        label.TextScaled = true
                        make("UITextSizeConstraint", {
                            MaxTextSize = math.max(8, math.floor(12 * scale)),
                            MinTextSize = 5,
                        },label)
                        make("UIPadding", {
                            PaddingLeft = UDim.new(0, 2),
                            PaddingRight = UDim.new(0, 2),
                        },label)
                    end
                    local ok, code = pcall(function() return Enum.KeyCode[name] end)
                    local part = {
                        cap = cap,
                        glow = glow,
                        rim = rim,
                        label = label,
                        tint = tint,
                        ink = shade,
                        lift = 1.5 * scale,
                    }
                    table.insert(keys, {
                        part = part,
                        outline = outline,
                        fade = fade,
                        glow = glow,
                        rim = rim,
                        label = label,
                    })
                    if ok then parts[code] = part end
                end
                x = x + span
            end
        end
    end

    if mouse.on then
        local scale = mouse.size
        local color = tone(mouse)
        local bright = color:Lerp(Color3.new(1, 1, 1), 0.35)
        local radius = wide * 0.45
        local high = tall * 0.42
        local seam = 2 * scale
        local gapTop = high * 0.16
        local gapBottom = high * 0.66

        local shell = make("Frame",{
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(board.on and reach + 30 or 0, (total.Y - tall) / 2),
            Size = UDim2.fromOffset(wide, tall),
        },area)
        corner(shell, radius)
        table.insert(pieces.strokes, make("UIStroke", {Color = color, Thickness = 2, Transparency = 0.1}, shell))

        local inner = make("CanvasGroup", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
        },shell)
        corner(inner, radius)

        for index, name in {"MouseButton1", "MouseButton2"} do
            local button = make("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1,
                Position = UDim2.new((index - 1) * 0.5, index == 2 and seam / 2 or 0, 0, 0),
                Size = UDim2.new(0.5, -seam / 2, 0, high),
            }, inner)
            table.insert(pieces.fades, make("UIGradient", {Rotation = 90, Color = ColorSequence.new(bright, color)}, button))
            parts[Enum.UserInputType[name]] = {cap = button}
        end

        local lines = {
            {UDim2.new(0.5, -seam / 2, 0, 0), UDim2.fromOffset(seam, gapTop)},
            {UDim2.new(0.5, -seam / 2, 0, gapBottom), UDim2.fromOffset(seam, high - gapBottom)},
            {UDim2.fromOffset(0, high), UDim2.new(1, 0, 0, seam)},
        }
        for _, line in lines do
            table.insert(pieces.lines, make("Frame", {
                BackgroundColor3 = color,
                BackgroundTransparency = 0.1,
                Position = line[1],
                Size = line[2],
            },inner))
        end
        local wheel = make("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, gapTop),
            Size = UDim2.fromOffset(9 * scale, gapBottom - gapTop),
        },shell)
        corner(wheel, 4.5 * scale)
        table.insert(pieces.fades, make("UIGradient", {Rotation = 90, Color = ColorSequence.new(bright, color)}, wheel))
        local rim = make("UIStroke", {Color = color, Thickness = 1.5, Transparency = 0.15}, wheel)
        table.insert(pieces.strokes, rim)
        parts[Enum.UserInputType.MouseButton3] = {cap = wheel, rim = rim}
    end

    parts.paint = function(fresh)
        local color = tone(fresh.keyboard)
        local tint = color:Lerp(Color3.new(1, 1, 1), 0.3)
        local bright = color:Lerp(Color3.new(1, 1, 1), 0.35)
        local shade = ink(color)
        for _, key in keys do
            key.outline.Color = color
            key.glow.BackgroundColor3 = color
            key.fade.Color = ColorSequence.new(bright, color)
            key.rim.Color = color
            key.label.TextColor3 = tint
            key.part.tint = tint
            key.part.ink = shade
        end
        local other = tone(fresh.mouse)
        local soft = other:Lerp(Color3.new(1, 1, 1), 0.35)
        for _, stroke in pieces.strokes do stroke.Color = other end
        for _, fade in pieces.fades do fade.Color = ColorSequence.new(soft, other) end
        for _, line in pieces.lines do line.BackgroundColor3 = other end
    end
    return parts, area
end

local function light(part, down)
    if not part then return end
    local info = TweenInfo.new(down and 0.04 or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {BackgroundTransparency = down and 0.05 or 1}
    if part.lift then
        goal.Position = down and UDim2.fromOffset(0, part.lift) or UDim2.new()
    end
    Tween:Create(part.cap, info, goal):Play()
    if part.glow then
        Tween:Create(part.glow, info, {BackgroundTransparency = down and 0.72 or 1}):Play()
    end
    if part.rim then
        Tween:Create(part.rim, info, {Transparency = down and 0 or 0.15}):Play()
    end
    if part.label then
        Tween:Create(part.label, info, {TextColor3 = down and part.ink or part.tint}):Play()
    end
end

local function listen(down)
    return function(input)
        if not Playing and input.KeyCode == Enum.KeyCode.Unknown then return end
        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
        local function apply()
            if down and Moving and key == Enum.UserInputType.MouseButton1 then
                return
            end
            for _, parts in Live do
                light(parts[key], down)
            end
        end
        if key == Enum.UserInputType.MouseButton1 then
            task.defer(apply)
        else apply()
        end
    end
end

local function scrolled(input)
    if Playing and input.UserInputType == Enum.UserInputType.MouseWheel then
        for _, parts in Live do
            local part = parts[Enum.UserInputType.MouseButton3]
            light(part, true)
            task.delay(0.12, function()
                light(part, false)
            end)
        end
    end
end

local Links = {
    Input.InputBegan:Connect(listen(true)),
    Input.InputEnded:Connect(listen(false)),
    Input.InputChanged:Connect(scrolled),
    Input.WindowFocusReleased:Connect(function()
        for _, parts in Live do
            for _, part in parts do
                if type(part) == "table" then light(part, false) end
            end
        end
    end),
}
Gui.Destroying:Connect(function() for _, link in Links do link:Disconnect() end end)

local function fit(holder)
    local area = holder:FindFirstChild("Area")
    if area then
        local ref = measure({keyboard = {size = Limit.max, on = true}, mouse = {size = Limit.max, on = true}})
        local ratio = math.min(1, (holder.AbsoluteSize.X - 24) / ref.X, (holder.AbsoluteSize.Y - 44) / ref.Y)
        area.UIScale.Scale = math.max(0.05, ratio)
    end
end

local function refresh()
    if Playing then return end
    table.clear(Live)
    for _, holder in Previews do
        for _, child in holder:GetChildren() do
            if child.Name == "Area" or child.Name == "Note" then child:Destroy() end
        end
        table.insert(Live, (render(holder, Config)))
        if not Config.keyboard.on and not Config.mouse.on then
            make("TextLabel", {
                Name = "Note",
                Size = UDim2.fromScale(1, 1),
                Text = "Nothing enabled",
                TextColor3 = Theme.muted,
            },holder)
        end fit(holder)
    end
end

local function repaint() for _, parts in Live do parts.paint(Config) end end
local function later(func)
    if not Queue[func] then
        Queue[func] = true
        task.delay(0.04, function()
            Queue[func] = nil
            func()
        end)
    end
end

local function preview(parent)
    local holder = make("Frame", {
        BackgroundColor3 = Theme.well,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, 200),
    },parent)
    corner(holder, 12)
    make("UIStroke", {Color = Theme.field, Transparency = 0.5}, holder)
    make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 185)),
    },holder)
    table.insert(Previews, holder)
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit(holder) end)
    return holder
end

local function title(parent, text)
    if parent:FindFirstChildOfClass("TextLabel") then make("Frame", {BackgroundColor3 = Theme.field, Size = UDim2.new(1, 0, 0, 1)}, parent) end
    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        Text = text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    },parent)
    make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, label)
    local bar = make("Frame", {
        BackgroundColor3 = Theme.accent,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -12, 0.5, 0),
        Size = UDim2.fromOffset(3, 16),
    },label) corner(bar, 2)
end

local function palette(parent)
    local sync
    local tabs = {}
    local strip = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32)}, parent)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
    },strip)
    for _, name in {"keyboard", "mouse"} do
        local tab = make("TextButton", {
            Size = UDim2.new(0.5, -50, 1, 0),
            Text = name:sub(1, 1):upper() .. name:sub(2),
            Font = Enum.Font.GothamBold,
        },strip)
        corner(tab, 8)
        tab.MouseButton1Click:Connect(function()
            Target = name
            sync()
        end)
        tabs[name] = tab
    end
    local chip = make("TextLabel", {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 84, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
    },strip)
    corner(chip, 8)

    local shell = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 130)}, parent)
    local field = make("Frame", {
        BackgroundColor3 = Color3.new(1, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
    },shell)
    corner(field, 10)

    local white = make("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1)}, field)
    corner(white, 10)
    make("UIGradient", {Transparency = NumberSequence.new(0, 1)}, white)

    local black = make("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1)}, field)
    corner(black, 10)
    make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, black)

    local spot = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
    },field)
    corner(spot, 8)
    make("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2}, spot)

    local bar = make("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 24, 1, 0),
    }, shell)
    corner(bar, 10)
    local points = {}
    for step = 0, 6 do points[step + 1] = ColorSequenceKeypoint.new(step / 6, Color3.fromHSV(step / 6, 1, 1)) end
    make("UIGradient", {Rotation = 90, Color = ColorSequence.new(points)}, bar)
    local mark = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 6, 0, 8),
    },bar)
    corner(mark, 4)
    make("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2}, mark)

    sync = function()
        local cfg = Config[Target]
        local color = tone(cfg)
        for name, tab in tabs do
            tab.BackgroundColor3 = name == Target and Theme.accent or Theme.field
            tab.TextColor3 = name == Target and Color3.new(1, 1, 1) or Theme.text
        end
        chip.BackgroundColor3 = color
        chip.TextColor3 = ink(color)
        chip.Text = "#" .. color:ToHex():upper()
        field.BackgroundColor3 = Color3.fromHSV(cfg.hue, 1, 1)
        spot.Position = UDim2.fromScale(cfg.sat, 1 - cfg.val)
        mark.Position = UDim2.fromScale(0.5, cfg.hue)
    end
    track(field, function()
        return function(now)
            local cfg = Config[Target]
            cfg.sat = math.clamp((now.X - field.AbsolutePosition.X) / field.AbsoluteSize.X, 0, 1)
            cfg.val = 1 - math.clamp((now.Y - field.AbsolutePosition.Y) / field.AbsoluteSize.Y, 0, 1)
            sync()
            later(repaint)
        end
    end)
    track(bar, function()
        return function(now)
            Config[Target].hue = math.clamp((now.Y - bar.AbsolutePosition.Y) / bar.AbsoluteSize.Y, 0, 1)
            sync()
            later(repaint)
        end
    end)
    sync()
end

local function slider(parent, name, cfg)
    local row = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28)}, parent)
    make("TextLabel", {
        Size = UDim2.new(0, 80, 1, 0),
        Text = name,
        TextColor3 = Theme.muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    },row)
    local hit = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 90, 0.5, 0),
        Size = UDim2.new(1, -160, 0, 24),
    },row)
    local rail = make("Frame", {
        BackgroundColor3 = Theme.field,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 6),
    },hit)
    corner(rail, 3)
    local fill = make("Frame", {BackgroundColor3 = Theme.accent, Size = UDim2.fromScale(0, 1)}, rail)
    corner(fill, 3)
    local knob = make("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
    },hit)
    corner(knob, 9)
    make("UIStroke", {Color = Theme.accent, Thickness = 2}, knob)
    local readout = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 56, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    },row)

    local function show()
        local ratio = (cfg.size - Limit.min) / (Limit.max - Limit.min)
        fill.Size = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.fromScale(ratio, 0.5)
        readout.Text = string.format("%.2fx", cfg.size)
    end
    show()

    track(hit, function()
        return function(now)
            local ratio = math.clamp((now.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
            local value = Limit.min + ratio * (Limit.max - Limit.min)
            local size = math.clamp(math.floor(value / 0.05 + 0.5) * 0.05, Limit.min, Limit.max)
            if size ~= cfg.size then
                cfg.size = size
                show()
                later(refresh)
            end
        end
    end)
end

local function switch(parent, name, cfg)
    local row = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32)}, parent)
    make("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
    },row)
    local word = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -58, 0.5, 0),
        Size = UDim2.fromOffset(50, 20),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    },row)
    local pill = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(46, 26),
        Text = "",
    },row)
    corner(pill, 13)
    local dot = make("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(20, 20),
    }, pill)
    corner(dot, 10)
    local function show(instant)
        local info = TweenInfo.new(instant and 0 or 0.15)
        word.Text = cfg.on and "True" or "False"
        word.TextColor3 = cfg.on and Theme.text or Theme.muted
        Tween:Create(pill, info, {BackgroundColor3 = cfg.on and Theme.accent or Theme.field}):Play()
        Tween:Create(dot, info, {Position = UDim2.new(0, cfg.on and 23 or 3, 0.5, 0)}):Play()
    end show(true)
    pill.MouseButton1Click:Connect(function()
        cfg.on = not cfg.on
        show(false)
        refresh()
    end)
end

local function action(parent, text, place)
    local item = make("TextButton", {
        BackgroundColor3 = Theme.field,
        Position = UDim2.new(1, place, 0, 0),
        Size = UDim2.new(0, 58, 1, 0),
        Text = text,
        TextSize = 12,
    }, parent)
    corner(item, 8)
    return item
end

local function clean(text) return (text:gsub("[^%w _%-]", "")):match("^%s*(.-)%s*$") end
local function names()
    local found = {}
    local ok, files = pcall(listfiles, Folder)
    if ok then
        for _, path in files do
            local name = path:match("([^/\\]+)%.json$")
            if name then table.insert(found, name) end
        end
    end table.sort(found)
    return found
end

local function store(name)
    pcall(function()
        if not isfolder(Folder) then makefolder(Folder) end
        writefile(Folder .. "/" .. name .. ".json", Http:JSONEncode(Config))
    end)
end

local function read(name)
    local ok, data = pcall(function() return Http:JSONDecode(readfile(Folder .. "/" .. name .. ".json")) end)
    if not ok or type(data) ~= "table" then return false end
    for _, part in {"keyboard", "mouse"} do
        local source = data[part]
        if type(source) == "table" then
            for key, value in Config[part] do
                if type(source[key]) == type(value) then Config[part][key] = source[key] end
            end
            Config[part].size = math.clamp(Config[part].size, Limit.min, Limit.max)
        end
    end
    if type(data.place) == "table" then
        for _, axis in {"x", "y"} do
            if type(data.place[axis]) == "number" then
                Config.place[axis] = data.place[axis]
            end
        end
    end
    return true
end

local function bound(size, x, y)
    local screen = Gui.AbsoluteSize
    local half = size.X / 2
    return math.max(half - screen.X / 2, math.min(screen.X / 2 - half, x)), math.max(size.Y + 26 - screen.Y, math.min(0, y))
end

local function launch()
    Window:Destroy()
    table.clear(Previews)

    local holder = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
    },Gui)
    local parts, area = render(holder, Config)
    local size = Vector2.new(area.Size.X.Offset, area.Size.Y.Offset)
    local x, y = bound(size, Config.place.x, Config.place.y)
    holder.Size = UDim2.fromOffset(size.X, size.Y)
    holder.Position = UDim2.new(0.5, x, 1, y)

    local hit = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -4),
        Size = UDim2.fromOffset(math.max(size.X, 90), 22),
    }, holder)
    local line = make("Frame", {
        BackgroundColor3 = tone(Config.keyboard.on and Config.keyboard or Config.mouse),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 0, 0, 4),
    }, hit)
    corner(line, 2)

    local function reveal(state) Tween:Create(line, TweenInfo.new(0.3), {BackgroundTransparency = state and 0.1 or 1}):Play() end

    track(hit, function(origin)
        Moving = true
        reveal(true)
        local base = holder.Position
        return function(now)
            local shift = now - origin
            local moveX, moveY = bound(size, base.X.Offset + shift.X, base.Y.Offset + shift.Y)
            holder.Position = UDim2.new(0.5, moveX, 1, moveY)
        end
    end, function()
        Moving = false
        Config.place.x = holder.Position.X.Offset
        Config.place.y = holder.Position.Y.Offset
        store(Current)
        task.delay(0.5, function() if not Moving then reveal(false) end end)
    end)
    reveal(true)
    task.delay(3, function() if not Moving then reveal(false) end end)
    table.clear(Live)
    table.insert(Live, parts)
    Playing = true
end

local function page(scroll)
    local place = scroll.CanvasPosition
    for _, child in scroll:GetChildren() do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    table.clear(Previews)

    title(scroll, "Color Dashboard Key")
    palette(scroll)
    preview(scroll)

    title(scroll, "Size Dashboard Key")
    slider(scroll, "Keyboard", Config.keyboard)
    slider(scroll, "Mouse", Config.mouse)
    preview(scroll)

    title(scroll, "True/False Mouse and Keyboard")
    switch(scroll, "Keyboard", Config.keyboard)
    switch(scroll, "Mouse", Config.mouse)
    preview(scroll)

    local saved = names()

    title(scroll, "Save Profile")
    local row = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)}, scroll)
    local box = make("TextBox", {
        BackgroundColor3 = Theme.field,
        Size = UDim2.new(1, -100, 1, 0),
        Text = Current or "Profile" .. (#saved + 1),
        PlaceholderText = "Profile name",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    corner(box, 8)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, box)
    local save = make("TextButton", {
        BackgroundColor3 = Theme.accent,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 90, 1, 0),
        Text = "Save",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
    },row)
    corner(save, 8)
    save.MouseButton1Click:Connect(function()
        local name = clean(box.Text)
        if name == "" then name = "Profile" end
        store(name)
        Current = name
        launch()
    end)
    title(scroll, "Saved Profiles")
    if #saved == 0 then
        make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24),
            Text = "No saved profiles yet",
            TextColor3 = Theme.muted,
            TextXAlignment = Enum.TextXAlignment.Left,
        },scroll)
    end

    for _, name in saved do
        local path = Folder .. "/" .. name .. ".json"
        local line = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34)}, scroll)
        local field = make("TextBox", {
            BackgroundColor3 = Theme.field,
            Size = UDim2.new(1, -190, 1, 0),
            Text = name,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
        },line)
        corner(field, 8)
        make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, field)
        local apply = action(line, "Load", -182)
        apply.BackgroundColor3 = Theme.accent
        apply.TextColor3 = Color3.new(1, 1, 1)
        local rename = action(line, "Rename", -120)
        local remove = action(line, "Delete", -58)
        apply.MouseButton1Click:Connect(function()
            if read(name) then
                Current = name
                page(scroll)
            end
        end)
        rename.MouseButton1Click:Connect(function() field:CaptureFocus() end)
        field.FocusLost:Connect(function(entered)
            local fresh = clean(field.Text)
            local target = Folder .. "/" .. fresh .. ".json"
            local ok = entered and fresh ~= "" and fresh ~= name and pcall(function()
                assert(not isfile(target))
                writefile(target, readfile(path))
                delfile(path)
            end)
            if ok then
                if Current == name then Current = fresh end
                page(scroll)
            else
                field.Text = name
            end
        end)

        remove.MouseButton1Click:Connect(function()
            if remove.Text == "Delete" then
                remove.Text = "Confirm"
                task.delay(2, function() if remove.Parent then remove.Text = "Delete" end end)
                return
            end
            pcall(delfile, path)
            if Current == name then Current = nil end
            page(scroll)
        end)
    end refresh()
    task.delay(0.05, function() scroll.CanvasPosition = place end)
end

task.spawn(function()
    local fade = TweenInfo.new(0.6, Enum.EasingStyle.Sine)
    Tween:Create(Hello, fade, {TextTransparency = 0}):Play()
    task.wait(1.8)
    Tween:Create(Hello, fade, {TextTransparency = 1}):Play()
    task.wait(0.7)
    if Gui.Parent and Window.Parent then
        Hello:Destroy()
        page(Scroll)
        Tween:Create(Body, fade, {GroupTransparency = 0}):Play()
        task.wait(0.7)
        if Window.Parent and Scroll.Parent == Body then
            Scroll.Parent = Window
            Scroll.Position = UDim2.fromOffset(0, 40)
            Scroll.Size = UDim2.new(1, 0, 1, -52)
            Body:Destroy()
        end
    end
end)