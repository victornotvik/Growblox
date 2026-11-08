-- ============================================================
-- WindUI → Native Roblox UI Adapter
-- Tanpa dependency eksternal — pakai ScreenGui native Roblox
-- Kompatibel Delta executor
-- ============================================================

local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME
-- ============================================================
local C = {
    Bg       = Color3.fromRGB(18, 18, 24),
    Panel    = Color3.fromRGB(26, 26, 36),
    Sidebar  = Color3.fromRGB(22, 22, 30),
    Tab      = Color3.fromRGB(32, 32, 44),
    TabSel   = Color3.fromRGB(80, 120, 255),
    Accent   = Color3.fromRGB(80, 120, 255),
    Toggle_on  = Color3.fromRGB(80, 200, 120),
    Toggle_off = Color3.fromRGB(60, 60, 80),
    Text     = Color3.fromRGB(220, 220, 240),
    TextDim  = Color3.fromRGB(140, 140, 170),
    Border   = Color3.fromRGB(50, 50, 70),
    Input    = Color3.fromRGB(14, 14, 20),
    Scroll   = Color3.fromRGB(50, 50, 80),
}

-- ============================================================
-- HELPERS
-- ============================================================
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, parent)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

local function padding(px, parent)
    local p = new("UIPadding", {}, parent)
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    return p
end

local function stroke(thickness, color, parent)
    return new("UIStroke", { Thickness = thickness, Color = color or C.Border }, parent)
end

local function listLayout(dir, spacing, parent)
    return new("UIListLayout", {
        FillDirection     = dir or Enum.FillDirection.Vertical,
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, spacing or 4),
    }, parent)
end

local function autoSize(frame, axis)
    -- Adjust frame size to fit content
    local layout = frame:FindFirstChildWhichIsA("UIListLayout")
    if not layout then return end
    local function update()
        if axis == "X" then
            frame.Size = UDim2.new(0, layout.AbsoluteContentSize.X, frame.Size.Y.Scale, frame.Size.Y.Offset)
        else
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, layout.AbsoluteContentSize.Y + 8)
        end
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

-- Draggable
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos  = target.Position
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- NOTIFICATION
-- ============================================================
local NotifGui
local function ensureNotifGui()
    if NotifGui and NotifGui.Parent then return NotifGui end
    NotifGui = new("ScreenGui", {
        Name = "KzoyzNotif", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
    }, PlayerGui)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = NotifGui,
    })
    local pad = new("UIPadding", {}, NotifGui)
    pad.PaddingRight  = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    return NotifGui
end

local function sendNotif(title, content, duration)
    local gui = ensureNotifGui()
    local card = new("Frame", {
        Size = UDim2.new(0, 280, 0, 60),
        BackgroundColor3 = C.Panel,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, gui)
    corner(8, card)
    stroke(1, C.Accent, card)
    local acc = new("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
    }, card)
    corner(2, acc)
    local inner = new("Frame", {
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
    }, card)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(title or ""),
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, inner)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = tostring(content or ""),
        TextColor3 = C.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, inner)
    task.delay(tonumber(duration) or 4, function()
        TweenService:Create(card, TweenInfo.new(0.3), { Size = UDim2.new(0, 280, 0, 0) }):Play()
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ============================================================
-- ELEMENT BUILDERS (dipanggil oleh tab/box)
-- ============================================================

local function buildToggle(parent, opts)
    local title = tostring(opts.Title or "")
    local desc  = tostring(opts.Desc or "")
    local def   = opts.Value == true
    local cb    = type(opts.Callback) == "function" and opts.Callback or nil

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, desc ~= "" and 46 or 34),
        BackgroundColor3 = C.Tab,
        BorderSizePixel  = 0,
    }, parent)
    corner(6, row)
    padding(10, row)

    new("TextLabel", {
        Size = UDim2.new(1, -50, 0, 16),
        Position = UDim2.new(0, 0, 0, desc ~= "" and 4 or 9),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    if desc ~= "" then
        new("TextLabel", {
            Size = UDim2.new(1, -50, 0, 14),
            Position = UDim2.new(0, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = C.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }, row)
    end

    -- Toggle pill
    local pill = new("Frame", {
        Size = UDim2.new(0, 36, 0, 20),
        Position = UDim2.new(1, -36, 0.5, -10),
        BackgroundColor3 = def and C.Toggle_on or C.Toggle_off,
        BorderSizePixel  = 0,
    }, row)
    corner(10, pill)

    local knob = new("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, def and 19 or 3, 0.5, -7),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
    }, pill)
    corner(7, knob)

    local val = def
    local el  = {}

    local function setVal(v, fireCallback)
        val = v == true
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = val and C.Toggle_on or C.Toggle_off,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = UDim2.new(0, val and 19 or 3, 0.5, -7),
        }):Play()
        if fireCallback and cb then pcall(cb, val) end
    end

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, row)
    btn.MouseButton1Click:Connect(function() setVal(not val, true) end)

    function el:Set(v) setVal(v, true) end
    return el
end

local function buildButton(parent, opts)
    local title = tostring(opts.Title or "")
    local cb    = type(opts.Callback) == "function" and opts.Callback or nil

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Text = title,
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, parent)
    corner(6, btn)
    btn.MouseButton1Click:Connect(function()
        if cb then pcall(cb) end
    end)
end

local function buildSlider(parent, opts)
    local title  = tostring(opts.Title or "")
    local valTbl = type(opts.Value) == "table" and opts.Value or {}
    local minV   = tonumber(valTbl.Min) or 0
    local maxV   = tonumber(valTbl.Max) or 100
    local defV   = tonumber(valTbl.Default) or minV
    local step   = tonumber(opts.Step) or 1
    local cb     = type(opts.Callback) == "function" and opts.Callback or nil

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.Tab,
        BorderSizePixel  = 0,
    }, parent)
    corner(6, frame)
    padding(10, frame)

    local labelRow = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1 }, frame)
    new("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, labelRow)
    local valLabel = new("TextLabel", {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(defV),
        TextColor3 = C.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, labelRow)

    local track = new("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = C.Toggle_off,
        BorderSizePixel  = 0,
    }, frame)
    corner(4, track)

    local fill = new("Frame", {
        Size = UDim2.new((defV - minV) / math.max(maxV - minV, 1), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
    }, track)
    corner(4, fill)

    local function snap(v)
        if step > 0 then v = math.round((v - minV) / step) * step + minV end
        return math.clamp(v, minV, maxV)
    end

    local function setFromX(absX)
        local rel = math.clamp((absX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minV + rel * (maxV - minV)
        local val = snap(raw)
        fill.Size = UDim2.new((val - minV) / math.max(maxV - minV, 1), 0, 1, 0)
        valLabel.Text = tostring(val)
        if cb then pcall(cb, val) end
    end

    local sliding = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(inp.Position.X)
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            setFromX(inp.Position.X)
        end
    end)
end

local function buildDropdown(parent, opts)
    local title   = tostring(opts.Title or "")
    local values  = type(opts.Values) == "table" and opts.Values or {}
    local defVal  = type(opts.Value) == "string" and opts.Value or (values[1] or "")
    local cb      = type(opts.Callback) == "function" and opts.Callback or nil

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = C.Tab,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
    }, parent)
    corner(6, frame)
    padding(10, frame)

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local selected = defVal
    local selBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = C.Input,
        BorderSizePixel  = 0,
        Text = "  " .. tostring(selected) .. "  ▾",
        TextColor3 = C.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    corner(5, selBtn)

    -- Dropdown list
    local list = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 2),
        BackgroundColor3 = C.Panel,
        BorderSizePixel  = 0,
        Visible = false,
        ZIndex  = 10,
        ClipsDescendants = true,
    }, selBtn)
    corner(5, list)
    stroke(1, C.Border, list)
    local ll = listLayout(nil, 2, list)
    padding(4, list)

    local function pick(opt)
        selected = opt
        selBtn.Text = "  " .. tostring(opt) .. "  ▾"
        list.Visible = false
        if cb then pcall(cb, opt) end
    end

    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, v in ipairs(values) do
            local item = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = selected == v and C.Tab or Color3.fromRGB(0,0,0),
                BackgroundTransparency = selected == v and 0 or 1,
                Text = "  " .. tostring(v),
                TextColor3 = C.Text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            }, list)
            corner(4, item)
            item.MouseButton1Click:Connect(function() pick(v) end)
        end
        list.Size = UDim2.new(1, 0, 0, math.min(#values * 28 + 8, 160))
    end

    rebuild()

    selBtn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then rebuild() end
    end)

    local el = {}
    function el:Refresh(newValues)
        values = type(newValues) == "table" and newValues or values
        rebuild()
    end
    function el:Select(opt) pick(opt) end
    return el
end

local function buildInput(parent, opts)
    local title = tostring(opts.Title or "")
    local ph    = tostring(opts.Placeholder or opts.Desc or "")
    local cb    = type(opts.Callback) == "function" and opts.Callback or nil

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = C.Tab,
        BorderSizePixel  = 0,
    }, parent)
    corner(6, frame)
    padding(10, frame)

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = C.Input,
        BorderSizePixel  = 0,
        PlaceholderText  = ph,
        PlaceholderColor3 = C.TextDim,
        Text = tostring(opts.Value or ""),
        TextColor3 = C.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        ClearTextOnFocus = false,
    }, frame)
    corner(5, box)
    padding(6, box)

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed and cb then pcall(cb, box.Text) end
    end)

    local el = {}
    function el:Set(v) box.Text = tostring(v or "") end
    return el
end

local function buildParagraph(parent, opts)
    local title = tostring(opts.Title or "")
    local desc  = tostring(opts.Desc or "")

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = C.Tab,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
    }, parent)
    corner(6, frame)
    padding(10, frame)

    local ll = listLayout(nil, 2, frame)

    local titleLbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local descLbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = C.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, frame)

    local function update()
        descLbl.Size = UDim2.new(1, 0, 0, math.max(14, descLbl.TextBounds.Y + 2))
        frame.Size = UDim2.new(1, 0, 0, ll.AbsoluteContentSize.Y + 20)
    end
    descLbl:GetPropertyChangedSignal("TextBounds"):Connect(update)
    task.defer(update)

    local el = {}
    function el:SetDesc(txt)
        descLbl.Text = tostring(txt or "")
        task.defer(update)
    end
    return el
end

local function buildSection(parent, opts)
    local title = tostring(opts.Title or "")
    -- visual separator label
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "— " .. title .. " —",
        TextColor3 = C.TextDim,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, parent)
end

-- ============================================================
-- BOX / TAB PROXY
-- ============================================================
local function makeBoxProxy(scrollContent)
    local proxy = {}

    function proxy:Toggle(opts)   return buildToggle(scrollContent, opts or {})   end
    function proxy:Button(opts)   buildButton(scrollContent, opts or {})           end
    function proxy:Slider(opts)   buildSlider(scrollContent, opts or {})           end
    function proxy:Dropdown(opts) return buildDropdown(scrollContent, opts or {})  end
    function proxy:Input(opts)    return buildInput(scrollContent, opts or {})     end
    function proxy:Paragraph(opts) return buildParagraph(scrollContent, opts or {}) end

    function proxy:Section(opts)
        buildSection(scrollContent, opts or {})
        return proxy  -- section-within-section = same level
    end

    return proxy
end

-- ============================================================
-- WINDOW
-- ============================================================

local function makeWindow(opts)
    opts = opts or {}
    local title  = tostring(opts.Title or "Script")
    local author = tostring(opts.Author or "")
    local toggleKey = opts.ToggleKey or Enum.KeyCode.Insert

    -- ScreenGui
    local sg = new("ScreenGui", {
        Name            = "KzoyzOpusUI",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        DisplayOrder    = 100,
    }, PlayerGui)

    -- Main window frame
    local win = new("Frame", {
        Size            = UDim2.fromOffset(640, 400),
        Position        = UDim2.fromScale(0.5, 0.5),
        AnchorPoint     = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
    }, sg)
    corner(10, win)
    stroke(1, C.Border, win)

    -- Titlebar
    local titlebar = new("Frame", {
        Size            = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.Panel,
        BorderSizePixel  = 0,
    }, win)
    corner(10, titlebar)
    -- Mask bottom corners of titlebar
    new("Frame", {
        Size            = UDim2.new(1, 0, 0, 10),
        Position        = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = C.Panel,
        BorderSizePixel  = 0,
    }, titlebar)

    new("TextLabel", {
        Size            = UDim2.new(1, -80, 1, 0),
        Position        = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text            = title .. (author ~= "" and "  |  " .. author or ""),
        TextColor3      = C.Text,
        Font            = Enum.Font.GothamBold,
        TextSize        = 13,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, titlebar)

    -- Close / minimize buttons
    local closeBtn = new("TextButton", {
        Size            = UDim2.fromOffset(20, 20),
        Position        = UDim2.new(1, -28, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(220, 70, 70),
        BorderSizePixel  = 0,
        Text            = "✕",
        TextColor3      = Color3.new(1,1,1),
        Font            = Enum.Font.GothamBold,
        TextSize        = 11,
    }, titlebar)
    corner(5, closeBtn)
    closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

    makeDraggable(titlebar, win)

    -- Body
    local body = new("Frame", {
        Size            = UDim2.new(1, 0, 1, -36),
        Position        = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
    }, win)

    -- Sidebar (tab list)
    local sidebar = new("ScrollingFrame", {
        Size            = UDim2.new(0, 150, 1, 0),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel  = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Scroll,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
    }, body)
    -- round bottom-left corner
    corner(10, sidebar)
    local sideLL = listLayout(nil, 2, sidebar)
    padding(6, sidebar)
    sideLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebar.CanvasSize = UDim2.new(0, 0, 0, sideLL.AbsoluteContentSize.Y + 12)
    end)

    -- Content area
    local contentHost = new("Frame", {
        Size            = UDim2.new(1, -150, 1, 0),
        Position        = UDim2.new(0, 150, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, body)

    -- Toggle key
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == toggleKey then
            win.Visible = not win.Visible
        end
    end)

    -- Floating open button (mobile / when closed)
    local openBtn = new("TextButton", {
        Size            = UDim2.fromOffset(44, 44),
        Position        = UDim2.new(0, 10, 0.5, -22),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Text            = "☰",
        TextColor3      = Color3.new(1,1,1),
        Font            = Enum.Font.GothamBold,
        TextSize        = 20,
        Visible         = true,
    }, sg)
    corner(10, openBtn)
    makeDraggable(openBtn, openBtn)
    openBtn.MouseButton1Click:Connect(function() win.Visible = not win.Visible end)
    win:GetPropertyChangedSignal("Visible"):Connect(function()
        openBtn.Visible = not win.Visible
    end)

    -- Tab management
    local tabs        = {}
    local activeTab   = nil
    local tabBtns     = {}

    local function selectTab(name)
        for n, frame in pairs(tabs) do
            frame.Visible = (n == name)
        end
        for n, btn in pairs(tabBtns) do
            btn.BackgroundColor3 = (n == name) and C.TabSel or C.Tab
            btn.TextColor3       = (n == name) and Color3.new(1,1,1) or C.TextDim
        end
        activeTab = name
    end

    local function createTab(tabName)
        -- Sidebar button
        local btn = new("TextButton", {
            Size            = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = C.Tab,
            BorderSizePixel  = 0,
            Text            = "  " .. tabName,
            TextColor3      = C.TextDim,
            Font            = Enum.Font.Gotham,
            TextSize        = 12,
            TextXAlignment  = Enum.TextXAlignment.Left,
        }, sidebar)
        corner(6, btn)
        tabBtns[tabName] = btn

        -- Scroll frame for content
        local scroll = new("ScrollingFrame", {
            Size            = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.Scroll,
            CanvasSize      = UDim2.new(0, 0, 0, 0),
            Visible         = false,
        }, contentHost)

        local content = new("Frame", {
            Size            = UDim2.new(1, -8, 0, 0),
            BackgroundTransparency = 1,
        }, scroll)
        local ll = listLayout(nil, 6, content)
        padding(8, content)
        local function updateCanvas()
            content.Size = UDim2.new(1, -8, 0, ll.AbsoluteContentSize.Y + 16)
            scroll.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 16)
        end
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        tabs[tabName] = scroll
        btn.MouseButton1Click:Connect(function() selectTab(tabName) end)

        if not activeTab then selectTab(tabName) end

        return makeBoxProxy(content)
    end

    -- Window proxy object
    local winProxy = {}

    function winProxy:Tab(o)
        o = o or {}
        local name = tostring(o.Title or o[1] or "Tab")
        return createTab(name)
    end

    function winProxy:Section(o)
        -- Sidebar section = group label + tab factory
        o = o or {}
        local _grpTitle = tostring(o.Title or "")
        -- Add a small group label to sidebar
        new("TextLabel", {
            Size            = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text            = string.upper(_grpTitle),
            TextColor3      = C.TextDim,
            Font            = Enum.Font.GothamBold,
            TextSize        = 9,
            TextXAlignment  = Enum.TextXAlignment.Left,
        }, sidebar)
        local sec = {}
        function sec:Tab(o2)
            o2 = o2 or {}
            local name = tostring(o2.Title or o2[1] or "Tab")
            return createTab(name)
        end
        return sec
    end

    function winProxy:EditOpenButton(_o) end  -- noop

    function winProxy:Destroy()
        pcall(function() sg:Destroy() end)
    end

    return winProxy
end

-- ============================================================
-- WINDUI ADAPTER
-- ============================================================
local WindUI = {}

function WindUI:CreateWindow(opts)
    local ok, result = pcall(makeWindow, opts)
    if ok then return result end
    -- Fallback dummy
    local d = {}
    setmetatable(d, { __index = function() return function() return setmetatable({}, {
        __index = function() return function() return {} end end
    }) end end })
    return d
end

function WindUI:Notify(opts)
    opts = opts or {}
    pcall(sendNotif, opts.Title, opts.Content, opts.Duration)
end

function WindUI:Popup(opts)
    opts = opts or {}
    local buttons = type(opts.Buttons) == "table" and opts.Buttons or {}
    local names = {}
    for _, b in ipairs(buttons) do names[#names + 1] = tostring(b.Title or "") end
    local content = tostring(opts.Content or "")
    if #names > 0 then content = content .. "\n[" .. table.concat(names, " / ") .. "]" end
    pcall(sendNotif, opts.Title, content, 4)
    if #buttons > 0 and type(buttons[1].Callback) == "function" then
        task.spawn(function()
            task.wait(0.1)
            pcall(buttons[1].Callback)
        end)
    end
end

return WindUI
