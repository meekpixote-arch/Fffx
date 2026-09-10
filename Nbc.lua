--[[ NBC Hub - Client (Painel Moderno) ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("AdminRemote")
local camera = workspace.CurrentCamera

local token, rank, brand = nil, nil, nil
local state = {}
local updateUI

-- ============================================================
-- PALETA NBC HUB
-- ============================================================
local C = {
    bg        = Color3.fromRGB(12, 14, 22),
    bgSoft    = Color3.fromRGB(20, 23, 34),
    card      = Color3.fromRGB(28, 32, 46),
    cardHover = Color3.fromRGB(38, 43, 62),
    accent    = Color3.fromRGB(77, 166, 255),
    accent2   = Color3.fromRGB(168, 85, 247),
    success   = Color3.fromRGB(60, 210, 140),
    danger    = Color3.fromRGB(235, 75, 100),
    text      = Color3.fromRGB(235, 240, 255),
    subtext   = Color3.fromRGB(150, 162, 190),
    stroke    = Color3.fromRGB(58, 64, 90),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 10)}, p) end
local function stroke(p, col, th) return new("UIStroke", {Color = col or C.stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p) end
local function pad(p, n) return new("UIPadding", {PaddingTop = UDim.new(0,n), PaddingBottom = UDim.new(0,n), PaddingLeft = UDim.new(0,n), PaddingRight = UDim.new(0,n)}, p) end
local function gradient(p, c1, c2, rot)
    return new("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 0}, p)
end

-- ============================================================
-- TOASTS
-- ============================================================
local toastFrame

local function toast(text, kind)
    if not toastFrame then return end
    local col = kind == "ok" and C.success or kind == "err" and C.danger or C.accent
    local t = new("Frame", {
        Size = UDim2.new(0, 280, 0, 52),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.05,
        Parent = toastFrame,
    })
    corner(t, 14); stroke(t, col, 1.5)

    local bar = new("Frame", {
        Size = UDim2.new(0, 4, 1, -14),
        Position = UDim2.new(0, 7, 0, 7),
        BackgroundColor3 = col,
        BorderSizePixel = 0,
        Parent = t,
    })
    corner(bar, 4)

    new("TextLabel", {
        Size = UDim2.new(1, -30, 0, 16),
        Position = UDim2.new(0, 22, 0, 9),
        BackgroundTransparency = 1,
        Text = "◆  NBC HUB",
        TextColor3 = col,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = t,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.new(0, 22, 0, 26),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = t,
    })

    t.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(t, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        Position = UDim2.new(1, -300, 0, 0)
    }):Play()

    task.delay(3, function()
        local out = TweenService:Create(t, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1,
        })
        out:Play()
        out.Completed:Connect(function() t:Destroy() end)
    end)
end

-- ============================================================
-- INIT / STATE
-- ============================================================
Remote.OnClientEvent:Connect(function(kind, data)
    if kind == "Init" then
        token, rank, brand = data.token, data.rank, data.brand
        buildUI()
        toast("Bem-vindo, " .. plr.DisplayName, "ok")
    elseif kind == "State" then
        state = data
        if updateUI then updateUI() end
    end
end)

local function send(action, value)
    if not token then return end
    Remote:FireServer(token, action, value)
end

-- ============================================================
-- ESP / X-RAY
-- ============================================================
local espFolder = new("Folder", {Name = "NBC_ESP"}, game.CoreGui)
local espActive = false

local function createESP(target)
    if espFolder:FindFirstChild(target.Name) then return end
    local char = target.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    new("BoxHandleAdornment", {
        Name = target.Name,
        Adornee = char.HumanoidRootPart,
        AlwaysOnTop = true,
        ZIndex = 5,
        Size = Vector3.new(3, 5, 1),
        Transparency = 0.45,
        Color3 = C.accent,
    }, espFolder)

    local bill = new("BillboardGui", {
        Name = "ESPName", Size = UDim2.new(0, 130, 0, 22),
        StudsOffset = Vector3.new(0, 3.2, 0), AlwaysOnTop = true,
    }, char.Head)

    new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "◆ " .. target.DisplayName,
        TextColor3 = C.accent,
        TextStrokeTransparency = 0.2, TextScaled = true,
        Font = Enum.Font.GothamBold,
    }, bill)
end

local function clearESP()
    espFolder:ClearAllChildren()
    for _, p in pairs(Players:GetPlayers()) do
        local c = p.Character
        if c and c:FindFirstChild("Head") and c.Head:FindFirstChild("ESPName") then
            c.Head.ESPName:Destroy()
        end
    end
end

local function toggleESP(on)
    espActive = on
    if on then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr then createESP(p) end
        end
        toast("ESP ativado", "ok")
    else
        clearESP()
        toast("ESP desativado", "err")
    end
end

local function toggleXRay(on)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = on and 0.7 or 0
        end
    end
    toast("X-Ray " .. (on and "ativado" or "desativado"), on and "ok" or "err")
end

Players.PlayerAdded:Connect(function(p)
    if p == plr then return end
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if espActive then createESP(p) end
    end)
end)

-- ============================================================
-- UI
-- ============================================================
function buildUI()
    local gui = new("ScreenGui", {
        Name = "NBCHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, plr:WaitForChild("PlayerGui"))

    -- Toasts container
    toastFrame = new("Frame", {
        Size = UDim2.new(0, 320, 1, -40),
        Position = UDim2.new(1, -340, 0, 20),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, toastFrame)

    -- ============ FAB ============
    local fab = new("TextButton", {
        Size = UDim2.new(0, 62, 0, 62),
        Position = UDim2.new(0, 24, 0.5, -31),
        BackgroundColor3 = C.bgSoft,
        Text = "◆",
        TextSize = 26,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.text,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = gui,
    })
    corner(fab, 18)
    stroke(fab, C.accent, 1.5)
    gradient(fab, C.accent, C.accent2, 45)

    -- ============ PAINEL ============
    local panel = new("Frame", {
        Size = UDim2.new(0, 460, 0, 580),
        Position = UDim2.new(0.5, -230, 0.5, -290),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Visible = false,
        Parent = gui,
    })
    corner(panel, 20)
    stroke(panel, C.stroke, 1.2)

    -- Header
    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = C.bgSoft,
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(header, 20)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        BackgroundColor3 = C.bgSoft,
        BorderSizePixel = 0,
        Parent = header,
    })

    local logoDot = new("Frame", {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 18, 0.5, -20),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(logoDot, 12)
    gradient(logoDot, C.accent, C.accent2, 45)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "◆", TextScaled = true, Font = Enum.Font.GothamBold,
        TextColor3 = C.text, Parent = logoDot,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -240, 0, 24),
        Position = UDim2.new(0, 70, 0, 14),
        BackgroundTransparency = 1,
        Text = "NBC HUB",
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -240, 0, 16),
        Position = UDim2.new(0, 70, 0, 38),
        BackgroundTransparency = 1,
        Text = "Advanced Admin Suite  •  " .. tostring(rank or "?"),
        TextColor3 = C.subtext,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local verBadge = new("Frame", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -110, 0.5, -11),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(verBadge, 8)
    stroke(verBadge, C.accent, 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = (brand and brand.Version or "v1.0"),
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Parent = verBadge,
    })

    local closeBtn = new("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -44, 0.5, -16),
        BackgroundColor3 = C.card,
        Text = "✕",
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(closeBtn, 10)

    -- ============ TABS ============
    local tabBar = new("Frame", {
        Size = UDim2.new(1, -28, 0, 44),
        Position = UDim2.new(0, 14, 0, 82),
        BackgroundColor3 = C.bgSoft,
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(tabBar, 12)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
    }, tabBar)
    pad(tabBar, 4)

    local content = new("Frame", {
        Size = UDim2.new(1, -28, 1, -186),
        Position = UDim2.new(0, 14, 0, 134),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local pages, tabButtons = {}, {}

    local function switchTab(name)
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            local active = (n == name)
            TweenService:Create(b, TweenInfo.new(0.2), {
                BackgroundColor3 = active and C.accent or C.bgSoft
            }):Play()
            b.TextColor3 = active and C.text or C.subtext
        end
    end

    local function makeTab(name, icon, label)
        local btn = new("TextButton", {
            Size = UDim2.new(0, 108, 1, -8),
            BackgroundColor3 = C.bgSoft,
            Text = icon .. "  " .. label,
            TextColor3 = C.subtext,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = tabBar,
        })
        corner(btn, 8)
        tabButtons[name] = btn
        btn.MouseButton1Click:Connect(function() switchTab(name) end)

        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.accent,
            Visible = false,
            Parent = content,
        })
        local l = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10)
        end)
        pages[name] = page
        return page
    end

    local function sectionLabel(parent, text)
        local f = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = parent})
        local left = new("Frame", {
            Size = UDim2.new(0, 3, 0, 12), Position = UDim2.new(0, 0, 0.5, -6),
            BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = f,
        })
        corner(left, 2)
        new("TextLabel", {
            Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1, Text = text,
            TextColor3 = C.subtext, Font = Enum.Font.GothamBold,
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
        })
    end

    local toggles = {}

    local function toggleRow(parent, key, label, action)
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundColor3 = C.card,
            Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = parent,
        })
        corner(btn, 12); stroke(btn, C.stroke, 1)

        local dot = new("Frame", {
            Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 18, 0.5, -4),
            BackgroundColor3 = C.danger, BorderSizePixel = 0, Parent = btn,
        })
        corner(dot, 4)

        new("TextLabel", {
            Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 36, 0, 0),
            BackgroundTransparency = 1, Text = label,
            TextColor3 = C.text, Font = Enum.Font.GothamMedium,
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
        })

        local pill = new("Frame", {
            Size = UDim2.new(0, 46, 0, 26), Position = UDim2.new(1, -60, 0.5, -13),
            BackgroundColor3 = C.bgSoft, BorderSizePixel = 0, Parent = btn,
        })
        corner(pill, 13)
        local knob = new("Frame", {
            Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = C.subtext, BorderSizePixel = 0, Parent = pill,
        })
        corner(knob, 10)

        toggles[key] = {btn = btn, dot = dot, pill = pill, knob = knob}

        btn.MouseButton1Click:Connect(function()
            send(action, not (state[key] == true))
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.card}):Play()
        end)
    end

    local function actionRow(parent, label, callback, color)
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = C.card, Text = label,
            TextColor3 = C.text, Font = Enum.Font.GothamMedium,
            TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0, Parent = parent,
        })
        corner(btn, 12); stroke(btn, C.stroke, 1)
        btn.MouseButton1Click:Connect(callback)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or C.cardHover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.card}):Play()
        end)
        return btn
    end

    -- ============ PÁGINA MOVIMENTO ============
    local pageMove = makeTab("move", "🏃", "Movimento")
    sectionLabel(pageMove, "PODERES")
    toggleRow(pageMove, "God", "God Mode", "God")
    toggleRow(pageMove, "Noclip", "Noclip", "Noclip")
    toggleRow(pageMove, "Float", "Float", "Float")
    toggleRow(pageMove, "InfiniteJump", "Infinite Jump", "InfiniteJump")
    sectionLabel(pageMove, "TPWALK")
    toggleRow(pageMove, "TpWalk", "TpWalk", "TpWalk")
    actionRow(pageMove, "⚡  TpWalk 70", function()
        send("TpWalkSpeed", 70); send("TpWalk", true); toast("TpWalk 70 ativado", "ok")
    end)
    actionRow(pageMove, "🐢  TpWalk 20", function()
        send("TpWalkSpeed", 20); send("TpWalk", true); toast("TpWalk 20 ativado", "ok")
    end)
    sectionLabel(pageMove, "ESTADO")
    actionRow(pageMove, "❄️  Freeze", function() send("Freeze", true); toast("Você congelou", "ok") end)
    actionRow(pageMove, "🔥  Unfreeze", function() send("Unfreeze", true); toast("Você descongelou", "ok") end)

    -- ============ PÁGINA VISÃO ============
    local pageView = makeTab("view", "👁️", "Visão")
    sectionLabel(pageView, "CÂMERA")
    actionRow(pageView, "🔭  FOV 70", function() send("FOV", 70); toast("FOV 70", "ok") end)
    actionRow(pageView, "🔭  FOV 90", function() send("FOV", 90); toast("FOV 90", "ok") end)
    actionRow(pageView, "🔭  FOV 120", function() send("FOV", 120); toast("FOV 120", "ok") end)
    sectionLabel(pageView, "VISUAL")
    actionRow(pageView, "👁️  ESP ON", function() toggleESP(true) end)
    actionRow(pageView, "🚫  ESP OFF", function() toggleESP(false) end)
    actionRow(pageView, "🩻  X-Ray ON", function() toggleXRay(true) end)
    actionRow(pageView, "🩻  X-Ray OFF", function() toggleXRay(false) end)

    -- ============ PÁGINA JOGADORES ============
    local pagePlayers = makeTab("players", "👥", "Jogadores")
    sectionLabel(pagePlayers, "SELECIONE UM JOGADOR")

    local selected = nil
    local playerListFrame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = pagePlayers,
    })
    corner(playerListFrame, 12); stroke(playerListFrame, C.stroke, 1)

    local playerScroll = new("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = playerListFrame,
    })
    local plLayout = new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, playerScroll)
    plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 8)
    end)

    local selectedLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        Text = "◆  Nenhum jogador selecionado",
        TextColor3 = C.subtext, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pagePlayers,
    })

    local function buildPlayerRow(p)
        local row = new("TextButton", {
            Size = UDim2.new(1, -8, 0, 38),
            BackgroundColor3 = C.bgSoft, Text = "",
            AutoButtonColor = false, BorderSizePixel = 0, Parent = playerScroll,
        })
        co
