local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")
local _enabled  = true
local _seen     = {}
local _focused  = nil

-- ============================================================
-- KNOX HUB - ENHANCED CODE DETECTOR
-- ============================================================

local ANTHROPIC_KEY = ""  -- Set via Settings if you want AI riddle solving

-- Theme Colors
local T = {
    BG     = Color3.fromRGB(8,8,12),
    Card   = Color3.fromRGB(16,16,24),
    Border = Color3.fromRGB(38,38,58),
    Accent = Color3.fromRGB(80,140,255),
    Green  = Color3.fromRGB(70,210,100),
    Red    = Color3.fromRGB(255,70,70),
    Yellow = Color3.fromRGB(255,195,50),
    White  = Color3.fromRGB(215,225,255),
    Dim    = Color3.fromRGB(65,65,95),
}
local F = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tw(o,i,p) TweenService:Create(o,i,p):Play() end
local function Corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p
end
local function Stroke(p,col,th)
    local s=Instance.new("UIStroke"); s.Color=col or T.Border
    s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

-- ============================================================
-- SKY THEME SYSTEM (10 Themes)
-- ============================================================
local KNOX_SKY_TAG = "KnoxSkyTheme"
local currentSkyTheme = "Off"
local KNOX_SKY_PRESETS = {
    ["Off"]={kind="off"},
    ["Night"]={clock=22,brightness=2,ambient={110,100,130},outAmb={120,110,140},sky={stars=4000,moon=18,sun=0,moonTex=true},atm={dens=0.45,color={120,60,180},decay={60,20,100},glare=0.5,haze=1.2}},
    ["Aurora"]={clock=14,brightness=3,ambient={150,120,150},outAmb={160,130,150},atm={dens=0.55,color={255,80,200},decay={255,20,150},glare=2.5,haze=3},clouds={cover=0.7,dens=0.7,color={255,240,250}}},
    ["Sunset"]={clock=17.2,brightness=2.5,ambient={170,120,100},outAmb={180,130,110},sky={stars=0,sun=25,moon=0},atm={dens=0.5,color={255,130,60},decay={255,80,30},glare=2,haze=2.5},clouds={cover=0.55,dens=0.55,color={255,200,140}}},
    ["Galaxy"]={clock=0,brightness=1.5,ambient={70,60,100},outAmb={80,70,110},sky={stars=10000,moon=30,sun=0},atm={dens=0.15,color={40,20,80},decay={20,10,50},glare=0.3,haze=0.5}},
    ["Cyber"]={clock=21,brightness=2.2,ambient={90,130,170},outAmb={100,140,180},sky={stars=2000,moon=12},atm={dens=0.4,color={0,200,255},decay={150,0,255},glare=2,haze=2},clouds={cover=0.4,dens=0.6,color={100,200,255}}},
    ["Sakura"]={clock=11,brightness=3.5,ambient={170,150,160},outAmb={180,160,170},sky={sun=8},atm={dens=0.3,color={255,200,220},decay={255,170,200},glare=1,haze=1.5},clouds={cover=0.6,dens=0.4,color={255,250,252}}},
    ["Pink Night"]={clock=23,brightness=2.2,ambient={120,60,110},outAmb={140,70,120},sky={stars=5000,moon=22,sun=0,moonTex=true},atm={dens=0.5,color={255,80,180},decay={140,30,100},glare=0.7,haze=1.4},clouds={cover=0.3,dens=0.5,color={180,90,150}}},
    ["Blood Moon"]={clock=22.5,brightness=1.6,ambient={130,40,40},outAmb={150,50,50},sky={stars=1500,moon=28,sun=0,moonTex=true},atm={dens=0.6,color={220,30,30},decay={120,10,10},glare=1.4,haze=2},clouds={cover=0.5,dens=0.7,color={120,30,30}}},
    ["Emerald Dawn"]={clock=6.5,brightness=2.8,ambient={130,170,140},outAmb={140,180,150},sky={sun=18,moon=0,stars=0},atm={dens=0.4,color={80,200,140},decay={40,150,90},glare=1.8,haze=2.2},clouds={cover=0.5,dens=0.5,color={200,255,220}}},
    ["Deep Space"]={clock=0,brightness=1,ambient={30,25,50},outAmb={40,35,60},sky={stars=15000,moon=0,sun=0},atm={dens=0.08,color={15,5,40},decay={5,0,20},glare=0.2,haze=0.3}},
}
local SkyOrder={"Off","Night","Aurora","Sunset","Galaxy","Cyber","Sakura","Pink Night","Blood Moon","Emerald Dawn","Deep Space"}
local function candyColor(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
local function KnoxApplyCustomSky(mode)
    for _,child in ipairs(Lighting:GetChildren()) do if child:GetAttribute(KNOX_SKY_TAG) then pcall(function() child:Destroy() end) end end
    local terrain=workspace:FindFirstChildOfClass("Terrain")
    if terrain then for _,child in ipairs(terrain:GetChildren()) do if child:GetAttribute(KNOX_SKY_TAG) then pcall(function() child:Destroy() end) end end end
    local preset=KNOX_SKY_PRESETS[mode]
    if not preset or preset.kind=="off" then Lighting.ClockTime=14;Lighting.Brightness=2;Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127);Lighting.Ambient=Color3.fromRGB(127,127,127);Lighting.FogEnd=100000;Lighting.GlobalShadows=true;return end
    Lighting.FogStart=0;Lighting.FogEnd=100000;Lighting.FogColor=Color3.fromRGB(200,200,200);Lighting.ColorShift_Top=Color3.fromRGB(0,0,0);Lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0);Lighting.GlobalShadows=true
    Lighting.ClockTime=preset.clock or 14;Lighting.Brightness=preset.brightness or 2
    if preset.outAmb then Lighting.OutdoorAmbient=candyColor(preset.outAmb) end
    if preset.ambient then Lighting.Ambient=candyColor(preset.ambient) end
    if preset.sky then
        local skyInst=Instance.new("Sky");skyInst:SetAttribute(KNOX_SKY_TAG,true)
        if preset.sky.stars then skyInst.StarCount=preset.sky.stars end
        if preset.sky.moon then skyInst.MoonAngularSize=preset.sky.moon end
        if preset.sky.sun then skyInst.SunAngularSize=preset.sky.sun end
        if preset.sky.moonTex then skyInst.MoonTextureId="rbxasset://sky/moon.jpg" end
        skyInst.Parent=Lighting
    end
    if preset.atm then
        local atm=Instance.new("Atmosphere");atm:SetAttribute(KNOX_SKY_TAG,true)
        atm.Density=preset.atm.dens or 0.3;atm.Color=candyColor(preset.atm.color);atm.Decay=candyColor(preset.atm.decay);atm.Glare=preset.atm.glare or 1;atm.Haze=preset.atm.haze or 1;atm.Parent=Lighting
    end
    if preset.clouds and terrain then
        local clouds=Instance.new("Clouds");clouds:SetAttribute(KNOX_SKY_TAG,true)
        clouds.Cover=preset.clouds.cover or 0.5;clouds.Density=preset.clouds.dens or 0.5;clouds.Color=candyColor(preset.clouds.color);clouds.Parent=terrain
    end
end

-- ============================================================
-- SETTINGS / CONFIG
-- ============================================================
local CONFIG_FILE = "knoxhub_config.json"
local config = {
    introSoundEnabled = true,
    skyTheme = "Off",
    discordLink = "https://discord.gg/WnDZ3zbqr",
    maxHistory = 50,
    autoDetectInput = true,
    showNotifications = true,
    soundOnDetect = true,
    copyToClipboard = true,
    autoPaste = true,
    instantPaste = false,
}

local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do config[k] = v end
        end
    end
    currentSkyTheme = config.skyTheme or "Off"
end

local function saveConfig()
    if writefile then
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
    end
end

loadConfig()

-- ============================================================
-- SAB CODE EXTRACTOR - Aggressively filters ONLY the promo code
-- ============================================================
-- Common English words and SAB-specific spam words to EXCLUDE
local EXCLUDE_WORDS = {}
local excludeList = {
    "the","and","for","are","but","not","you","all","can","had","her","was","one","our","out","day","get","has","him","his","how","its","may","new","now","old","see","two","who","boy","did","she","use","way","many","oil","sit","set","run","eat","far","sea","eye","ago","off","too","any","say","man","try","ask","end","why","let","put","tell","very","when","much","would","there","their","what","said","have","like","just","make","time","know","take","year","good","some","come","them","well","were","they","been","look","long","call","into","over","think","also","back","only","after","first","never","these","could","state","where","being","every","great","might","shall","still","while","about","right","world","years","under","found","sound","those","place","again","small","house","light","party","point","today","water","young","watch","until","since","power","often","early","later","above","below","among","hello","thanks","please","sorry","brainrot","steal","brain","rot","sammy","admin","chat","talk","code","promo","redeem","free","pet","give","away","event","update","soon","maybe","probably","actually","basically","literally","definitely","absolutely","seriously","honestly","really","people","someone","everyone","something","nothing","anything","everything","somebody","nobody","anybody","everybody","going","want","need","come","here","down","most","more","than","then","them","this","that","with","from","have","been","were","said","each","which","will","about","could","other","after","work","life","even","left","both","last","find","long","great","world","year","still","own","under","right","old","any","same","three","also","back","after","use","two","how","our","work","first","well","way","even","new","want","because","these","give","day","most","us","is","it","to","of","in","on","at","by","as","or","if","up","so","no","go","me","my","we","do","he","am","an","be","hi","ok","yes","nah","lol","lmao","omg","wtf","bruh","fr","ong","cap","nocap","ratio","mid","fire","goat","skibidi","sigma","mewing","rizz","gyatt","fanum","tax","ohio","grimaceshake","grimace","shake","sus","imposter","vented","among","amongus","crewmate","task","emergency","meeting","ejected","vote","voted","impostor","sabotage","report","body","dead","killed","kill","murder","sussy","baka","sugoma","sugma","ligma","balls","deez","nuts","candice","joe","mama","yuri","sawcon","saw","con","dragon","deez","nuts","ha","got","em","goteem","updog","what","updog","ligma","balls","sugondese","sugma","bofa","bofadeez","imagine","dragons","kisma","kisma","ass","booty","cheeks","sugondese","sugma","bofa","bofadeez","kisma","kisma","ass","booty","cheeks","sugondese","sugma","bofa","bofadeez","kisma","kisma","ass","booty","cheeks"
}
for _, w in ipairs(excludeList) do EXCLUDE_WORDS[w:lower()] = true end

-- Smart SAB code extractor
local function extractSABCode(txt)
    if not txt or type(txt) ~= "string" then return nil end
    txt = txt:gsub("[%p%c]", " ")  -- replace punctuation with spaces

    local candidates = {}

    -- Pass 1: Find all uppercase/digit words
    for word in txt:gmatch("%S+") do
        local clean = word:gsub("[^A-Za-z0-9]", "")
        if #clean >= 3 and #clean <= 20 then
            local lower = clean:lower()
            -- Skip common words
            if not EXCLUDE_WORDS[lower] then
                -- Check if it looks like a code
                local hasUpper = clean:match("[A-Z]")
                local hasDigit = clean:match("[0-9]")
                local isAllUpper = clean == clean:upper()
                local isMixed = hasUpper and hasDigit

                -- Score the candidate
                local score = 0
                if isAllUpper then score = score + 3 end
                if isMixed then score = score + 4 end
                if hasDigit then score = score + 2 end
                if #clean >= 4 and #clean <= 12 then score = score + 2 end
                if clean:match("^[A-Z][A-Z0-9]+$") then score = score + 3 end

                if score >= 3 then
                    table.insert(candidates, {code = clean, score = score, isUpper = isAllUpper})
                end
            end
        end
    end

    -- Sort by score (highest first)
    table.sort(candidates, function(a, b) return a.score > b.score end)

    if #candidates > 0 then
        return candidates[1].code
    end

    -- Fallback: try pattern matching for known formats
    local patterns = {
        "%f[%a][A-Z][A-Z0-9]+%f[%A]",      -- ALLUPPER123
        "%f[%a][A-Z][A-Z][A-Z]+[0-9]+%f[%A]", -- CODE123
        "%f[%d][0-9]+[A-Z][A-Z]+%f[%A]",      -- 123CODE
    }
    for _, pat in ipairs(patterns) do
        local match = txt:match(pat)
        if match then
            local lower = match:lower()
            if not EXCLUDE_WORDS[lower] and #match >= 3 then
                return match
            end
        end
    end

    return nil
end

-- ============================================================
-- CODE HISTORY SYSTEM
-- ============================================================
local codeHistory = {}
local historyGui = nil
local historyList = nil

local function addToHistory(code, source, solved)
    local entry = {
        code = code,
        source = source or "Unknown",
        solved = solved or false,
        timestamp = os.time(),
        timeStr = os.date("%H:%M:%S"),
    }
    table.insert(codeHistory, 1, entry)
    while #codeHistory > (config.maxHistory or 50) do
        table.remove(codeHistory)
    end
    if historyList and historyList.Parent then
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 32)
        item.BackgroundColor3 = T.Card
        item.BorderSizePixel = 0
        item.ZIndex = 105
        Corner(item, 6)
        Stroke(item, T.Border, 0.5)

        local codeLbl = Instance.new("TextLabel", item)
        codeLbl.Size = UDim2.new(1, -60, 0, 16)
        codeLbl.Position = UDim2.new(0, 8, 0, 2)
        codeLbl.BackgroundTransparency = 1
        codeLbl.Text = code
        codeLbl.TextSize = 11
        codeLbl.Font = Enum.Font.GothamBold
        codeLbl.TextColor3 = solved and T.Green or T.Accent
        codeLbl.TextXAlignment = Enum.TextXAlignment.Left
        codeLbl.ZIndex = 106

        local infoLbl = Instance.new("TextLabel", item)
        infoLbl.Size = UDim2.new(1, -60, 0, 12)
        infoLbl.Position = UDim2.new(0, 8, 0, 18)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = entry.timeStr .. " | " .. source
        infoLbl.TextSize = 8
        infoLbl.Font = Enum.Font.GothamMedium
        infoLbl.TextColor3 = T.Dim
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.ZIndex = 106

        local copyBtn = Instance.new("TextButton", item)
        copyBtn.Size = UDim2.new(0, 44, 0, 22)
        copyBtn.Position = UDim2.new(1, -50, 0.5, -11)
        copyBtn.BackgroundColor3 = T.Accent
        copyBtn.BorderSizePixel = 0
        copyBtn.Text = "Copy"
        copyBtn.TextSize = 9
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextColor3 = T.BG
        copyBtn.ZIndex = 106
        Corner(copyBtn, 5)

        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(code) end
            copyBtn.Text = "Copied!"
            copyBtn.BackgroundColor3 = T.Green
            task.delay(1, function()
                copyBtn.Text = "Copy"
                copyBtn.BackgroundColor3 = T.Accent
            end)
        end)

        item.Parent = historyList
        item.Size = UDim2.new(1, -4, 0, 0)
        Tw(item, TweenInfo.new(0.2), {Size = UDim2.new(1, -4, 0, 32)})
    end
end

-- ============================================================
-- CLEANUP OLD GUI
-- ============================================================
pcall(function()
    if game.CoreGui:FindFirstChild("KnoxHub") then game.CoreGui.KnoxHub:Destroy() end
end)
pcall(function()
    if playerGui:FindFirstChild("KnoxHub") then playerGui.KnoxHub:Destroy() end
end)

-- ============================================================
-- MAIN GUI
-- ============================================================
local GUI = Instance.new("ScreenGui")
GUI.Name="KnoxHub"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999
if not pcall(function() GUI.Parent=game.CoreGui end) then GUI.Parent=playerGui end

local WIN_W = 260

local Win = Instance.new("Frame")
Win.Name="Win"
Win.Size=UDim2.new(0,WIN_W,0,10)
Win.AutomaticSize=Enum.AutomaticSize.Y
Win.AnchorPoint=Vector2.new(1,0)
Win.Position=UDim2.new(1,-14,0,52)
Win.BackgroundColor3=T.BG
Win.BackgroundTransparency=0
Win.BorderSizePixel=0
Win.ZIndex=100
Win.ClipsDescendants=true
Win.Parent=GUI
Corner(Win,10)

-- Main GUI Background Image
local WinBG=Instance.new("ImageLabel")
WinBG.Name="WinBG"
WinBG.Size=UDim2.new(1,0,1,0)
WinBG.BackgroundTransparency=1
WinBG.Image="rbxassetid://93080745671655"
WinBG.ImageColor3=Color3.fromRGB(255,255,255)
WinBG.ImageTransparency=0.15
WinBG.ScaleType=Enum.ScaleType.Crop
WinBG.ZIndex=99
WinBG.Parent=Win

-- Animated Border for Main GUI
local WBorder=Stroke(Win, T.Accent, 1.4)
local WBG=Instance.new("UIGradient")
WBG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(25,55,160)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,140,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(25,55,160)),
})
WBG.Rotation=0
WBG.Parent=WBorder

RunService.RenderStepped:Connect(function(dt)
    WBG.Rotation = (WBG.Rotation + dt*55) % 360
end)

local WinList=Instance.new("UIListLayout")
WinList.FillDirection=Enum.FillDirection.Vertical
WinList.Padding=UDim.new(0,0)
WinList.SortOrder=Enum.SortOrder.LayoutOrder
WinList.HorizontalAlignment=Enum.HorizontalAlignment.Center
WinList.Parent=Win

-- ===== HEADER =====
local Hdr=Instance.new("Frame")
Hdr.Size=UDim2.new(1,0,0,36)
Hdr.BackgroundColor3=Color3.fromRGB(12,12,20)
Hdr.BackgroundTransparency=0
Hdr.BorderSizePixel=0
Hdr.LayoutOrder=1
Hdr.Active=true
Hdr.ZIndex=101
Hdr.Parent=Win
Corner(Hdr,10)

local HdrBG=Instance.new("UIGradient")
HdrBG.Color=ColorSequence.new(Color3.fromRGB(14,14,22), Color3.fromRGB(10,10,18))
HdrBG.Rotation=90
HdrBG.Parent=Hdr

local HdrFill=Instance.new("Frame")
HdrFill.Size=UDim2.new(1,0,0,10)
HdrFill.Position=UDim2.new(0,0,1,-10)
HdrFill.BackgroundColor3=Color3.fromRGB(12,12,20)
HdrFill.BorderSizePixel=0
HdrFill.ZIndex=101
HdrFill.Parent=Hdr

local HdrLine=Instance.new("Frame")
HdrLine.Size=UDim2.new(1,0,0,1)
HdrLine.Position=UDim2.new(0,0,1,0)
HdrLine.BackgroundColor3=T.Accent
HdrLine.BackgroundTransparency=0.55
HdrLine.BorderSizePixel=0
HdrLine.ZIndex=102
HdrLine.Parent=Hdr

local Logo=Instance.new("ImageLabel")
Logo.Size=UDim2.new(0,18,0,18)
Logo.Position=UDim2.new(0,9,0.5,-9)
Logo.BackgroundTransparency=1
Logo.BorderSizePixel=0
Logo.Image="rbxassetid://131500026335675"
Logo.ZIndex=103
Logo.Parent=Hdr
Corner(Logo,5)

local TitleL=Instance.new("TextLabel")
TitleL.Size=UDim2.new(0,120,1,0)
TitleL.Position=UDim2.new(0,31,0,0)
TitleL.BackgroundTransparency=1
TitleL.RichText=true
TitleL.Text='<font color="rgb(90,150,255)">Knox</font> <font color="rgb(170,190,255)" size="10">Hub</font>'
TitleL.TextSize=12
TitleL.Font=Enum.Font.GothamBold
TitleL.TextColor3=T.White
TitleL.TextXAlignment=Enum.TextXAlignment.Left
TitleL.TextYAlignment=Enum.TextYAlignment.Center
TitleL.ZIndex=102
TitleL.Parent=Hdr

-- Discord Copy Button
local OnBtn=Instance.new("TextButton")
OnBtn.Size=UDim2.new(0,36,0,18)
OnBtn.AnchorPoint=Vector2.new(1,0.5)
OnBtn.Position=UDim2.new(1,-8,0.5,0)
OnBtn.BackgroundColor3=T.Green
OnBtn.BorderSizePixel=0
OnBtn.AutoButtonColor=false
OnBtn.Text="ON"
OnBtn.TextSize=9
OnBtn.Font=Enum.Font.GothamBold
OnBtn.TextColor3=Color3.fromRGB(8,8,12)
OnBtn.ZIndex=103
OnBtn.Parent=Hdr
Corner(OnBtn,5)
local OnS=Stroke(OnBtn,T.Green,1)

-- Discord Copy Button (next to ON/OFF)
local DiscordBtn=Instance.new("TextButton")
DiscordBtn.Size=UDim2.new(0,36,0,18)
DiscordBtn.AnchorPoint=Vector2.new(1,0.5)
DiscordBtn.Position=UDim2.new(1,-48,0.5,0)
DiscordBtn.BackgroundColor3=T.Card
DiscordBtn.BorderSizePixel=0
DiscordBtn.Text="DC"
DiscordBtn.TextSize=9
DiscordBtn.Font=Enum.Font.GothamBold
DiscordBtn.TextColor3=T.White
DiscordBtn.ZIndex=103
DiscordBtn.Parent=Hdr
Corner(DiscordBtn,5)
Stroke(DiscordBtn, T.Border, 0.5)

DiscordBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(config.discordLink) end
    DiscordBtn.Text = "OK"
    Tw(DiscordBtn, TweenInfo.new(0.1), {BackgroundColor3 = T.Green})
    task.delay(1.5, function()
        DiscordBtn.Text = "DC"
        Tw(DiscordBtn, TweenInfo.new(0.3), {BackgroundColor3 = T.Card})
    end)
end)

local DiscordTip=Instance.new("TextLabel")
DiscordTip.Size=UDim2.new(0,120,0,18)
DiscordTip.Position=UDim2.new(1,-168,0.5,-9)
DiscordTip.BackgroundColor3=T.Card
DiscordTip.BorderSizePixel=0
DiscordTip.Text="Click to copy Discord"
DiscordTip.TextSize=8
DiscordTip.Font=Enum.Font.GothamMedium
DiscordTip.TextColor3=T.Dim
DiscordTip.ZIndex=104
DiscordTip.Visible=false
DiscordTip.Parent=Hdr
Corner(DiscordTip,4)
Stroke(DiscordTip, T.Border, 0.5)

DiscordBtn.MouseEnter:Connect(function()
    DiscordTip.Visible = true
    Tw(DiscordTip, TweenInfo.new(0.15), {TextColor3 = T.White})
end)
DiscordBtn.MouseLeave:Connect(function()
    DiscordTip.Visible = false
end)

local drag,ds,ws,mv
Hdr.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        drag=true; mv=false; ds=inp.Position; ws=Win.Position
    end
end)
Hdr.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local d=inp.Position-ds
        if not mv and d.Magnitude<5 then return end
        mv=true
        Win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
    end
end)

-- ===== BODY =====
local Body=Instance.new("Frame")
Body.Size=UDim2.new(1,0,0,0)
Body.AutomaticSize=Enum.AutomaticSize.Y
Body.BackgroundTransparency=1
Body.BorderSizePixel=0
Body.LayoutOrder=2
Body.ZIndex=101
Body.Parent=Win

local BL=Instance.new("UIListLayout")
BL.FillDirection=Enum.FillDirection.Vertical
BL.Padding=UDim.new(0,5)
BL.HorizontalAlignment=Enum.HorizontalAlignment.Center
BL.Parent=Body

local BPad=Instance.new("UIPadding")
BPad.PaddingTop=UDim.new(0,7)
BPad.PaddingBottom=UDim.new(0,9)
BPad.PaddingLeft=UDim.new(0,8)
BPad.PaddingRight=UDim.new(0,8)
BPad.Parent=Body

-- Status Card
local StatusCard=Instance.new("Frame")
StatusCard.Size=UDim2.new(1,0,0,26)
StatusCard.BackgroundColor3=T.Card
StatusCard.BackgroundTransparency=0
StatusCard.BorderSizePixel=0
StatusCard.ZIndex=102
StatusCard.Parent=Body
Corner(StatusCard,7)
Stroke(StatusCard,T.Border,1)

local SDot=Instance.new("Frame")
SDot.Size=UDim2.new(0,6,0,6)
SDot.Position=UDim2.new(0,8,0.5,-3)
SDot.BackgroundColor3=T.Dim
SDot.BorderSizePixel=0
SDot.ZIndex=103
SDot.Parent=StatusCard
Corner(SDot,3)

local SLbl=Instance.new("TextLabel")
SLbl.Size=UDim2.new(1,-22,1,0)
SLbl.Position=UDim2.new(0,18,0,0)
SLbl.BackgroundTransparency=1
SLbl.Text="Click the code box first"
SLbl.TextSize=10
SLbl.Font=Enum.Font.GothamMedium
SLbl.TextColor3=T.Dim
SLbl.TextXAlignment=Enum.TextXAlignment.Left
SLbl.TextYAlignment=Enum.TextYAlignment.Center
SLbl.ZIndex=103
SLbl.Parent=StatusCard

-- Code Card
local CodeCard=Instance.new("Frame")
CodeCard.Size=UDim2.new(1,0,0,42)
CodeCard.BackgroundColor3=T.Card
CodeCard.BackgroundTransparency=0
CodeCard.BorderSizePixel=0
CodeCard.ZIndex=102
CodeCard.Parent=Body
Corner(CodeCard,7)
local CodeStroke=Stroke(CodeCard,T.Border,1)
local CodeBG=Instance.new("UIGradient")
CodeBG.Color=ColorSequence.new(Color3.fromRGB(14,14,22),Color3.fromRGB(11,11,18))
CodeBG.Rotation=90
CodeBG.Parent=CodeCard

local CodeSmall=Instance.new("TextLabel")
CodeSmall.Size=UDim2.new(1,-10,0,12)
CodeSmall.Position=UDim2.new(0,9,0,5)
CodeSmall.BackgroundTransparency=1
CodeSmall.Text="DETECTED"
CodeSmall.TextSize=7
CodeSmall.Font=Enum.Font.GothamBold
CodeSmall.TextColor3=T.Dim
CodeSmall.TextXAlignment=Enum.TextXAlignment.Left
CodeSmall.ZIndex=103
CodeSmall.Parent=CodeCard

local CodeVal=Instance.new("TextLabel")
CodeVal.Size=UDim2.new(1,-10,0,22)
CodeVal.Position=UDim2.new(0,9,0,17)
CodeVal.BackgroundTransparency=1
CodeVal.Text="-"
CodeVal.TextSize=17
CodeVal.Font=Enum.Font.GothamBlack
CodeVal.TextColor3=T.Dim
CodeVal.TextXAlignment=Enum.TextXAlignment.Left
CodeVal.TextYAlignment=Enum.TextYAlignment.Center
CodeVal.ZIndex=103
CodeVal.Parent=CodeCard

-- History Button
local HistoryBtn=Instance.new("TextButton")
HistoryBtn.Size=UDim2.new(1,0,0,28)
HistoryBtn.BackgroundColor3=T.Card
HistoryBtn.BorderSizePixel=0
HistoryBtn.Text="Code History (0)"
HistoryBtn.TextSize=10
HistoryBtn.Font=Enum.Font.GothamBold
HistoryBtn.TextColor3=T.Accent
HistoryBtn.ZIndex=102
HistoryBtn.Parent=Body
Corner(HistoryBtn,7)
Stroke(HistoryBtn,T.Border,1)

-- Settings Button
local SettingsBtn=Instance.new("TextButton")
SettingsBtn.Size=UDim2.new(1,0,0,28)
SettingsBtn.BackgroundColor3=T.Card
SettingsBtn.BorderSizePixel=0
SettingsBtn.Text="Settings"
SettingsBtn.TextSize=10
SettingsBtn.Font=Enum.Font.GothamBold
SettingsBtn.TextColor3=T.Accent
SettingsBtn.ZIndex=102
SettingsBtn.Parent=Body
Corner(SettingsBtn,7)
Stroke(SettingsBtn,T.Border,1)

-- Riddle Card
local RiddleCard=Instance.new("Frame")
RiddleCard.Size=UDim2.new(1,0,0,0)
RiddleCard.AutomaticSize=Enum.AutomaticSize.Y
RiddleCard.BackgroundColor3=Color3.fromRGB(30,22,8)
RiddleCard.BackgroundTransparency=0
RiddleCard.BorderSizePixel=0
RiddleCard.Visible=false
RiddleCard.ZIndex=102
RiddleCard.Parent=Body
Corner(RiddleCard,7)
Stroke(RiddleCard,T.Yellow,1)
local RiddlePad=Instance.new("UIPadding")
RiddlePad.PaddingTop=UDim.new(0,5); RiddlePad.PaddingBottom=UDim.new(0,6)
RiddlePad.PaddingLeft=UDim.new(0,8); RiddlePad.PaddingRight=UDim.new(0,8)
RiddlePad.Parent=RiddleCard
local RLL=Instance.new("UIListLayout")
RLL.FillDirection=Enum.FillDirection.Vertical
RLL.Padding=UDim.new(0,2)
RLL.Parent=RiddleCard
local RTag=Instance.new("TextLabel")
RTag.Size=UDim2.new(1,0,0,11)
RTag.BackgroundTransparency=1
RTag.Text="RIDDLE SOLVER"
RTag.TextSize=7; RTag.Font=Enum.Font.GothamBold
RTag.TextColor3=T.Yellow
RTag.TextXAlignment=Enum.TextXAlignment.Left
RTag.ZIndex=103; RTag.Parent=RiddleCard
local RMsg=Instance.new("TextLabel")
RMsg.Size=UDim2.new(1,0,0,14)
RMsg.BackgroundTransparency=1; RMsg.Text=""
RMsg.TextSize=10; RMsg.Font=Enum.Font.GothamMedium
RMsg.TextColor3=T.White; RMsg.TextXAlignment=Enum.TextXAlignment.Left
RMsg.TextWrapped=true; RMsg.ZIndex=103; RMsg.Parent=RiddleCard


-- ===== HISTORY GUI =====
local function createHistoryGui()
    if historyGui then pcall(function() historyGui:Destroy() end) end

    historyGui = Instance.new("ScreenGui")
    historyGui.Name = "KnoxHubHistory"
    historyGui.ResetOnSpawn = false
    historyGui.DisplayOrder = 1000
    pcall(function() historyGui.Parent = game.CoreGui end)
    if not historyGui.Parent then historyGui.Parent = playerGui end

    local bg = Instance.new("Frame", historyGui)
    bg.Size = UDim2.new(0, 320, 0, 400)
    bg.Position = UDim2.new(0.5, -160, 0.5, -200)
    bg.BackgroundColor3 = T.BG
    bg.BorderSizePixel = 0
    bg.ZIndex = 200
    Corner(bg, 12)

    -- Animated Border for Settings GUI
    local SBorder=Stroke(bg, T.Accent, 1.5)
    local SBG=Instance.new("UIGradient")
    SBG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(25,55,160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,140,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(25,55,160)),
    })
    SBG.Rotation=0
    SBG.Parent=SBorder

    RunService.RenderStepped:Connect(function(dt)
        SBG.Rotation = (SBG.Rotation + dt*55) % 360
    end)

    local hhdr = Instance.new("Frame", bg)
    hhdr.Size = UDim2.new(1, 0, 0, 36)
    hhdr.BackgroundColor3 = Color3.fromRGB(12,12,20)
    hhdr.BorderSizePixel = 0
    hhdr.ZIndex = 201
    Corner(hhdr, 12)

    local ht = Instance.new("TextLabel", hhdr)
    ht.Size = UDim2.new(1, -60, 1, 0)
    ht.Position = UDim2.new(0, 12, 0, 0)
    ht.BackgroundTransparency = 1
    ht.Text = "Code History"
    ht.TextSize = 13
    ht.Font = Enum.Font.GothamBlack
    ht.TextColor3 = T.White
    ht.TextXAlignment = Enum.TextXAlignment.Left
    ht.ZIndex = 202

    local hclose = Instance.new("TextButton", hhdr)
    hclose.Size = UDim2.new(0, 26, 0, 26)
    hclose.Position = UDim2.new(1, -32, 0.5, -13)
    hclose.BackgroundColor3 = T.Red
    hclose.BorderSizePixel = 0
    hclose.Text = "X"
    hclose.TextSize = 12
    hclose.Font = Enum.Font.GothamBlack
    hclose.TextColor3 = T.White
    hclose.ZIndex = 202
    Corner(hclose, 6)
    hclose.MouseButton1Click:Connect(function()
        Tw(bg, TweenInfo.new(0.2), {Size = UDim2.new(0, 320, 0, 0)})
        task.delay(0.2, function() pcall(function() historyGui:Destroy() end) historyGui = nil end)
    end)

    local hclear = Instance.new("TextButton", hhdr)
    hclear.Size = UDim2.new(0, 50, 0, 22)
    hclear.Position = UDim2.new(1, -88, 0.5, -11)
    hclear.BackgroundColor3 = T.Card
    hclear.BorderSizePixel = 0
    hclear.Text = "Clear"
    hclear.TextSize = 9
    hclear.Font = Enum.Font.GothamBold
    hclear.TextColor3 = T.Red
    hclear.ZIndex = 202
    Corner(hclear, 5)
    Stroke(hclear, T.Red, 0.5)
    hclear.MouseButton1Click:Connect(function()
        codeHistory = {}
        if historyList then
            for _, child in ipairs(historyList:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
        end
        HistoryBtn.Text = "Code History (0)"
    end)

    local scroll = Instance.new("ScrollingFrame", bg)
    scroll.Size = UDim2.new(1, -16, 1, -48)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ZIndex = 201

    historyList = Instance.new("Frame", scroll)
    historyList.Size = UDim2.new(1, 0, 0, 0)
    historyList.AutomaticSize = Enum.AutomaticSize.Y
    historyList.BackgroundTransparency = 1
    historyList.BorderSizePixel = 0
    historyList.ZIndex = 202

    local hll = Instance.new("UIListLayout", historyList)
    hll.FillDirection = Enum.FillDirection.Vertical
    hll.Padding = UDim.new(0, 4)
    hll.SortOrder = Enum.SortOrder.LayoutOrder

    for _, entry in ipairs(codeHistory) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 32)
        item.BackgroundColor3 = T.Card
        item.BorderSizePixel = 0
        item.ZIndex = 205
        Corner(item, 6)
        Stroke(item, T.Border, 0.5)

        local codeLbl = Instance.new("TextLabel", item)
        codeLbl.Size = UDim2.new(1, -60, 0, 16)
        codeLbl.Position = UDim2.new(0, 8, 0, 2)
        codeLbl.BackgroundTransparency = 1
        codeLbl.Text = entry.code
        codeLbl.TextSize = 11
        codeLbl.Font = Enum.Font.GothamBold
        codeLbl.TextColor3 = entry.solved and T.Green or T.Accent
        codeLbl.TextXAlignment = Enum.TextXAlignment.Left
        codeLbl.ZIndex = 206

        local infoLbl = Instance.new("TextLabel", item)
        infoLbl.Size = UDim2.new(1, -60, 0, 12)
        infoLbl.Position = UDim2.new(0, 8, 0, 18)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = entry.timeStr .. " | " .. entry.source
        infoLbl.TextSize = 8
        infoLbl.Font = Enum.Font.GothamMedium
        infoLbl.TextColor3 = T.Dim
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.ZIndex = 206

        local copyBtn = Instance.new("TextButton", item)
        copyBtn.Size = UDim2.new(0, 44, 0, 22)
        copyBtn.Position = UDim2.new(1, -50, 0.5, -11)
        copyBtn.BackgroundColor3 = T.Accent
        copyBtn.BorderSizePixel = 0
        copyBtn.Text = "Copy"
        copyBtn.TextSize = 9
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextColor3 = T.BG
        copyBtn.ZIndex = 206
        Corner(copyBtn, 5)

        local codeText = entry.code
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(codeText) end
            copyBtn.Text = "Copied!"
            copyBtn.BackgroundColor3 = T.Green
            task.delay(1, function()
                copyBtn.Text = "Copy"
                copyBtn.BackgroundColor3 = T.Accent
            end)
        end)

        item.Parent = historyList
    end

    local hdrag, hds, hws, hmv
    hhdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            hdrag=true; hmv=false; hds=inp.Position; hws=bg.Position
        end
    end)
    hhdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then hdrag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if hdrag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-hds
            if not hmv and d.Magnitude<5 then return end
            hmv=true
            bg.Position=UDim2.new(hws.X.Scale,hws.X.Offset+d.X,hws.Y.Scale,hws.Y.Offset+d.Y)
        end
    end)
end

HistoryBtn.MouseButton1Click:Connect(createHistoryGui)

-- ===== SETTINGS GUI =====
local settingsGui = nil

local function createSettingsGui()
    if settingsGui then pcall(function() settingsGui:Destroy() end) end

    settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = "KnoxHubSettings"
    settingsGui.ResetOnSpawn = false
    settingsGui.DisplayOrder = 1000
    pcall(function() settingsGui.Parent = game.CoreGui end)
    if not settingsGui.Parent then settingsGui.Parent = playerGui end

    local bg = Instance.new("Frame", settingsGui)
    bg.Size = UDim2.new(0, 300, 0, 480)
    bg.Position = UDim2.new(0.5, -150, 0.5, -240)
    bg.BackgroundColor3 = T.BG
    bg.BorderSizePixel = 0
    bg.ZIndex = 200
    Corner(bg, 12)

    -- Animated Border for Settings GUI
    local SBorder=Stroke(bg, T.Accent, 1.5)
    local SBG=Instance.new("UIGradient")
    SBG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(25,55,160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,140,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(25,55,160)),
    })
    SBG.Rotation=0
    SBG.Parent=SBorder

    RunService.RenderStepped:Connect(function(dt)
        SBG.Rotation = (SBG.Rotation + dt*55) % 360
    end)

    local shdr = Instance.new("Frame", bg)
    shdr.Size = UDim2.new(1, 0, 0, 36)
    shdr.BackgroundColor3 = Color3.fromRGB(12,12,20)
    shdr.BorderSizePixel = 0
    shdr.ZIndex = 201
    shdr.Active = true
    shdr.Selectable = true
    Corner(shdr, 12)

    local st = Instance.new("TextLabel", shdr)
    st.Size = UDim2.new(1, -40, 1, 0)
    st.Position = UDim2.new(0, 12, 0, 0)
    st.BackgroundTransparency = 1
    st.Text = "Settings"
    st.TextSize = 13
    st.Font = Enum.Font.GothamBlack
    st.TextColor3 = T.White
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.ZIndex = 202

    local sclose = Instance.new("TextButton", shdr)
    sclose.Size = UDim2.new(0, 26, 0, 26)
    sclose.Position = UDim2.new(1, -32, 0.5, -13)
    sclose.BackgroundColor3 = T.Red
    sclose.BorderSizePixel = 0
    sclose.Text = "X"
    sclose.TextSize = 12
    sclose.Font = Enum.Font.GothamBlack
    sclose.TextColor3 = T.White
    sclose.ZIndex = 202
    Corner(sclose, 6)
    sclose.MouseButton1Click:Connect(function()
        Tw(bg, TweenInfo.new(0.2), {Size = UDim2.new(0, 300, 0, 0)})
        task.delay(0.2, function() pcall(function() settingsGui:Destroy() end) settingsGui = nil end)
    end)

    local scroll = Instance.new("ScrollingFrame", bg)
    scroll.Size = UDim2.new(1, -16, 1, -48)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ZIndex = 201

    local sll = Instance.new("UIListLayout", scroll)
    sll.FillDirection = Enum.FillDirection.Vertical
    sll.Padding = UDim.new(0, 6)
    sll.SortOrder = Enum.SortOrder.LayoutOrder

    local spd = Instance.new("UIPadding", scroll)
    spd.PaddingTop = UDim.new(0, 4)
    spd.PaddingBottom = UDim.new(0, 8)

    local function mkSection(parent, txt)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt:upper()
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = T.Dim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 202
        lbl.LayoutOrder = #parent:GetChildren()

        local div = Instance.new("Frame", parent)
        div.Size = UDim2.new(1, 0, 0, 1)
        div.BackgroundColor3 = T.Border
        div.BackgroundTransparency = 0.5
        div.BorderSizePixel = 0
        div.ZIndex = 202
        div.LayoutOrder = #parent:GetChildren()
        return lbl
    end

    local function mkToggle(parent, txt, state, callback)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = T.Card
        row.BorderSizePixel = 0
        row.ZIndex = 202
        row.LayoutOrder = #parent:GetChildren()
        Corner(row, 6)
        Stroke(row, T.Border, 0.5)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = T.White
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 203

        local pill = Instance.new("Frame", row)
        pill.Size = UDim2.new(0, 34, 0, 18)
        pill.Position = UDim2.new(1, -44, 0.5, -9)
        pill.BackgroundColor3 = state and T.Green or T.Dim
        pill.BorderSizePixel = 0
        pill.ZIndex = 203
        Corner(pill, 9)

        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        dot.BackgroundColor3 = T.White
        dot.BorderSizePixel = 0
        dot.ZIndex = 204
        Corner(dot, 6)

        local btn = Instance.new("TextButton", pill)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 205

        local on = state
        btn.MouseButton1Click:Connect(function()
            on = not on
            Tw(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and T.Green or T.Dim})
            Tw(dot, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
            })
            if callback then callback(on) end
        end)

        return row
    end

    local function mkDropdown(parent, txt, options, current, callback)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = T.Card
        row.BorderSizePixel = 0
        row.ZIndex = 202
        row.LayoutOrder = #parent:GetChildren()
        Corner(row, 6)
        Stroke(row, T.Border, 0.5)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = T.White
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 203

        local dd = Instance.new("TextButton", row)
        dd.Size = UDim2.new(0, 100, 0, 22)
        dd.Position = UDim2.new(1, -110, 0.5, -11)
        dd.BackgroundColor3 = T.Card
        dd.BorderSizePixel = 0
        dd.Text = current
        dd.TextSize = 9
        dd.Font = Enum.Font.GothamBold
        dd.TextColor3 = T.Accent
        dd.ZIndex = 203
        Corner(dd, 5)
        Stroke(dd, T.Border, 0.5)

        local idx = 1
        for i, v in ipairs(options) do if v == current then idx = i break end end

        dd.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            local newVal = options[idx]
            dd.Text = newVal
            if callback then callback(newVal) end
        end)

        return row
    end

    -- Sky Themes Section
    mkSection(scroll, "Sky Themes")
    mkDropdown(scroll, "Theme", SkyOrder, currentSkyTheme, function(theme)
        currentSkyTheme = theme
        config.skyTheme = theme
        KnoxApplyCustomSky(theme)
        saveConfig()
    end)

    -- Settings Section
    mkSection(scroll, "Detection Settings")
    mkToggle(scroll, "Auto-detect Input Box", config.autoDetectInput, function(on)
        config.autoDetectInput = on
        saveConfig()
    end)
    mkToggle(scroll, "Auto Paste Code", config.autoPaste, function(on)
        config.autoPaste = on
        saveConfig()
    end)
    mkToggle(scroll, "Instant Paste (No Click)", config.instantPaste, function(on)
        config.instantPaste = on
        saveConfig()
    end)
    mkToggle(scroll, "Show Notifications", config.showNotifications, function(on)
        config.showNotifications = on
        saveConfig()
    end)
    mkToggle(scroll, "Sound on Detect", config.soundOnDetect, function(on)
        config.soundOnDetect = on
        saveConfig()
    end)
    mkToggle(scroll, "Copy to Clipboard", config.copyToClipboard, function(on)
        config.copyToClipboard = on
        saveConfig()
    end)

    -- Discord Section
    mkSection(scroll, "Discord")
    local discordRow = Instance.new("Frame", scroll)
    discordRow.Size = UDim2.new(1, 0, 0, 32)
    discordRow.BackgroundColor3 = T.Card
    discordRow.BorderSizePixel = 0
    discordRow.ZIndex = 202
    discordRow.LayoutOrder = #scroll:GetChildren()
    Corner(discordRow, 6)
    Stroke(discordRow, T.Border, 0.5)

    local discordLbl = Instance.new("TextLabel", discordRow)
    discordLbl.Size = UDim2.new(0.5, 0, 1, 0)
    discordLbl.Position = UDim2.new(0, 10, 0, 0)
    discordLbl.BackgroundTransparency = 1
    discordLbl.Text = "Discord Link"
    discordLbl.TextSize = 10
    discordLbl.Font = Enum.Font.GothamBold
    discordLbl.TextColor3 = T.White
    discordLbl.TextXAlignment = Enum.TextXAlignment.Left
    discordLbl.ZIndex = 203

    local discordCopy = Instance.new("TextButton", discordRow)
    discordCopy.Size = UDim2.new(0, 80, 0, 22)
    discordCopy.Position = UDim2.new(1, -90, 0.5, -11)
    discordCopy.BackgroundColor3 = T.Accent
    discordCopy.BorderSizePixel = 0
    discordCopy.Text = "Copy Link"
    discordCopy.TextSize = 9
    discordCopy.Font = Enum.Font.GothamBold
    discordCopy.TextColor3 = T.BG
    discordCopy.ZIndex = 203
    Corner(discordCopy, 5)

    discordCopy.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(config.discordLink) end
        discordCopy.Text = "Copied!"
        discordCopy.BackgroundColor3 = T.Green
        task.delay(1.5, function()
            discordCopy.Text = "Copy Link"
            discordCopy.BackgroundColor3 = T.Accent
        end)
    end)

    -- UI SCALE +/- BUTTONS
    mkSection(scroll, "UI Scale")
    local scaleRow = Instance.new("Frame", scroll)
    scaleRow.Size = UDim2.new(1, 0, 0, 32)
    scaleRow.BackgroundColor3 = T.Card
    scaleRow.BorderSizePixel = 0
    scaleRow.ZIndex = 202
    scaleRow.LayoutOrder = #scroll:GetChildren()
    Corner(scaleRow, 6)
    Stroke(scaleRow, T.Border, 0.5)

    local scaleLbl = Instance.new("TextLabel", scaleRow)
    scaleLbl.Size = UDim2.new(0.3, 0, 1, 0)
    scaleLbl.Position = UDim2.new(0, 10, 0, 0)
    scaleLbl.BackgroundTransparency = 1
    scaleLbl.Text = "UI Scale"
    scaleLbl.TextSize = 10
    scaleLbl.Font = Enum.Font.GothamBold
    scaleLbl.TextColor3 = T.White
    scaleLbl.TextXAlignment = Enum.TextXAlignment.Left
    scaleLbl.ZIndex = 203

    local currentScale = 1.0

    local scaleVal = Instance.new("TextLabel", scaleRow)
    scaleVal.Size = UDim2.new(0, 40, 1, 0)
    scaleVal.Position = UDim2.new(0.5, -20, 0, 0)
    scaleVal.BackgroundTransparency = 1
    scaleVal.Text = "1.0"
    scaleVal.TextSize = 12
    scaleVal.Font = Enum.Font.GothamBlack
    scaleVal.TextColor3 = T.Accent
    scaleVal.TextXAlignment = Enum.TextXAlignment.Center
    scaleVal.ZIndex = 203

    local function applyScale(newScale)
        currentScale = math.clamp(newScale, 0.5, 2.0)
        currentScale = math.floor(currentScale * 10 + 0.5) / 10
        scaleVal.Text = string.format("%.1f", currentScale)

        -- Scale the settings window proportionally
        local newWidth = math.floor(300 * currentScale)
        local newHeight = math.floor(480 * currentScale)
        local headerH = math.floor(36 * currentScale)
        local scrollPad = math.floor(8 * currentScale)
        local scrollTop = math.floor(40 * currentScale)

        Tw(bg, TweenInfo.new(0.2), {
            Size = UDim2.new(0, newWidth, 0, newHeight),
            Position = UDim2.new(0.5, -newWidth/2, 0.5, -newHeight/2)
        })

        -- Resize header
        shdr.Size = UDim2.new(1, 0, 0, headerH)

        -- Resize scroll frame
        scroll.Size = UDim2.new(1, -scrollPad*2, 1, -scrollTop - scrollPad)
        scroll.Position = UDim2.new(0, scrollPad, 0, scrollTop)
        scroll.ScrollBarThickness = math.max(2, math.floor(3 * currentScale))

        -- Scale all text in scroll
        for _, child in ipairs(scroll:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local baseSize = child:GetAttribute("BaseTextSize")
                if not baseSize then
                    baseSize = child.TextSize
                    child:SetAttribute("BaseTextSize", baseSize)
                end
                child.TextSize = math.max(6, math.floor(baseSize * currentScale))
            end
            if child:IsA("Frame") and child ~= scroll then
                local baseH = child:GetAttribute("BaseHeight")
                if not baseH then
                    baseH = child.Size.Y.Offset
                    child:SetAttribute("BaseHeight", baseH)
                end
                child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, math.max(20, math.floor(baseH * currentScale)))
            end
        end
    end

    local minusBtn = Instance.new("TextButton", scaleRow)
    minusBtn.Size = UDim2.new(0, 28, 0, 22)
    minusBtn.Position = UDim2.new(1, -70, 0.5, -11)
    minusBtn.BackgroundColor3 = T.Card
    minusBtn.BorderSizePixel = 0
    minusBtn.Text = "-"
    minusBtn.TextSize = 14
    minusBtn.Font = Enum.Font.GothamBlack
    minusBtn.TextColor3 = T.White
    minusBtn.ZIndex = 203
    Corner(minusBtn, 5)
    Stroke(minusBtn, T.Border, 0.5)

    local plusBtn = Instance.new("TextButton", scaleRow)
    plusBtn.Size = UDim2.new(0, 28, 0, 22)
    plusBtn.Position = UDim2.new(1, -36, 0.5, -11)
    plusBtn.BackgroundColor3 = T.Accent
    plusBtn.BorderSizePixel = 0
    plusBtn.Text = "+"
    plusBtn.TextSize = 14
    plusBtn.Font = Enum.Font.GothamBlack
    plusBtn.TextColor3 = T.BG
    plusBtn.ZIndex = 203
    Corner(plusBtn, 5)

    minusBtn.MouseButton1Click:Connect(function()
        applyScale(currentScale - 0.1)
    end)
    plusBtn.MouseButton1Click:Connect(function()
        applyScale(currentScale + 0.1)
    end)

    -- CODE HISTORY BUTTON IN SETTINGS
    mkSection(scroll, "Tools")
    local historyBtnSettings = Instance.new("TextButton", scroll)
    historyBtnSettings.Size = UDim2.new(1, 0, 0, 32)
    historyBtnSettings.BackgroundColor3 = T.Card
    historyBtnSettings.BorderSizePixel = 0
    historyBtnSettings.Text = "📋 Open Code History"
    historyBtnSettings.TextSize = 10
    historyBtnSettings.Font = Enum.Font.GothamBold
    historyBtnSettings.TextColor3 = T.Accent
    historyBtnSettings.ZIndex = 202
    historyBtnSettings.LayoutOrder = #scroll:GetChildren()
    Corner(historyBtnSettings, 6)
    Stroke(historyBtnSettings, T.Border, 0.5)

    historyBtnSettings.MouseButton1Click:Connect(function()
        createHistoryGui()
    end)

    local sdrag, sds, sws, smv
    shdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sdrag=true; smv=false; sds=inp.Position; sws=bg.Position
        end
    end)
    shdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sdrag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sdrag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-sds
            if not smv and d.Magnitude<5 then return end
            smv=true
            bg.Position=UDim2.new(sws.X.Scale,sws.X.Offset+d.X,sws.Y.Scale,sws.Y.Offset+d.Y)
        end
    end)
end

SettingsBtn.MouseButton1Click:Connect(function()
    if settingsGui and settingsGui.Parent then
        pcall(function() settingsGui:Destroy() end)
        settingsGui = nil
    else
        createSettingsGui()
    end
end)


-- ===== CORE FUNCTIONS =====
local function setStatus(msg, col)
    col=col or T.Dim
    SLbl.Text=msg; SLbl.TextColor3=col; SDot.BackgroundColor3=col
end

local function flashCode(code, col)
    col=col or T.Accent
    CodeVal.Text=code; CodeVal.TextColor3=col
    Tw(CodeStroke, TweenInfo.new(0.1), {Color=col})
    task.delay(0.6, function()
        Tw(CodeStroke, TweenInfo.new(0.5), {Color=T.Border})
        Tw(CodeVal, TweenInfo.new(0.5), {TextColor3=col})
    end)
end

local function showRiddle(msg, col)
    RMsg.Text=msg; RMsg.TextColor3=col or T.White
    RiddleCard.Visible=true
end
local function hideRiddle()
    RiddleCard.Visible=false
end

-- Sound on detect
local detectSound = nil
local function playDetectSound()
    if not config.soundOnDetect then return end
    pcall(function()
        if not detectSound then
            detectSound = Instance.new("Sound")
            detectSound.SoundId = "rbxassetid://9113083740"
            detectSound.Volume = 0.3
            detectSound.Parent = game:GetService("SoundService")
        end
        detectSound:Play()
    end)
end

-- Notification
local function showNotification(text)
    if not config.showNotifications then return end
    pcall(function()
        local notif = Instance.new("ScreenGui")
        notif.Name = "KnoxNotification"
        notif.ResetOnSpawn = false
        notif.DisplayOrder = 2000
        pcall(function() notif.Parent = game.CoreGui end)
        if not notif.Parent then notif.Parent = playerGui end

        local card = Instance.new("Frame", notif)
        card.Size = UDim2.new(0, 200, 0, 40)
        card.Position = UDim2.new(1, 20, 1, -60)
        card.BackgroundColor3 = T.Card
        card.BorderSizePixel = 0
        card.ZIndex = 300
        Corner(card, 8)
        Stroke(card, T.Accent, 1)

        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(1, -16, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = T.Accent
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 301

        Tw(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -220, 1, -60)})
        task.delay(2.5, function()
            Tw(card, TweenInfo.new(0.3), {Position = UDim2.new(1, 20, 1, -60)})
            task.delay(0.3, function() pcall(function() notif:Destroy() end) end)
        end)
    end)
end

OnBtn.MouseButton1Click:Connect(function()
    _enabled=not _enabled
    if _enabled then
        OnBtn.Text="ON"; OnBtn.BackgroundColor3=T.Green; OnS.Color=T.Green
        OnBtn.TextColor3=Color3.fromRGB(8,8,12)
        setStatus(_focused and "Ready - watching" or "Click the code box first",
            _focused and T.Green or T.Dim)
    else
        OnBtn.Text="OFF"; OnBtn.BackgroundColor3=T.Red; OnS.Color=T.Red
        OnBtn.TextColor3=T.White; setStatus("Paused",T.Dim)
    end
end)

UserInputService.TextBoxFocused:Connect(function(box)
    _focused=box
    if _enabled then setStatus("Ready - watching",T.Green) end
end)
UserInputService.TextBoxFocusReleased:Connect(function(box)
    if _focused==box then
        _focused=nil
        if _enabled then setStatus("Click the code box first",T.Dim) end
    end
end)

-- Smart append - replaces text box content with ONLY the clean code
local function pasteCleanCode(code)
    if not code or code=="" then return end
    if not _focused or not _focused.Parent then
        setStatus("Click the code box first!",T.Yellow)
        flashCode(code, T.Yellow)
        return false
    end
    -- Replace entire text with clean code (not append)
    _focused.Text = code
    setStatus("Pasted clean code!",T.Green)
    flashCode(code,T.Green)
    return true
end

-- Also support old append mode
local function appendToBox(text)
    if not text or text=="" then return end
    if not _focused or not _focused.Parent then
        setStatus("Click the code box first!",T.Yellow)
        flashCode(text, T.Yellow)
        return
    end
    local cur=_focused.Text or ""
    if cur=="" then
        _focused.Text=text
    else
        _focused.Text=cur.." "..text
    end
    setStatus("Appended!",T.Green)
    flashCode(text,T.Green)
end

local RIDDLE_KW={
    "when was","how old","what year","what month","birthday","age of",
    "released","release date","hint","riddle","figure out","guess",
    "first letter","combine","spell","backwards","months","years",
    "old is","how many","what is","do you know","can you","which month",
    "which year","how long","since when",
}
local function isRiddle(txt)
    local l=txt:lower()
    for _,p in ipairs(RIDDLE_KW) do if l:find(p,1,true) then return true end end
    return false
end

local SAB={rm="MAY",ry="2024",rf="MAY2024",sa="24",c="MAY24"}
local function solveLocal(txt)
    local l=txt:lower()
    if (l:find("month") or l:find("when")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rm end
    if l:find("year") and (l:find("sab") or l:find("releas")) then return SAB.ry end
    if (l:find("when") or l:find("date")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rf end
    if (l:find("age") or l:find("old")) and l:find("sammy") then return SAB.sa end
    if (l:find("age") or l:find("old")) and (l:find("month") or l:find("when") or l:find("releas")) then return SAB.c end
    if l:find("may") and l:find("24") then return SAB.c end
    return nil
end

local function callAI(prompt)
    if not ANTHROPIC_KEY or ANTHROPIC_KEY=="" then return nil end
    local ok,result=pcall(function()
        local body=HttpService:JSONEncode({
            model="claude-sonnet-4-6",
            max_tokens=40,
            system="Decode Roblox promo codes for Steal a Brainrot (SAB). SAB released May 2024. Sammy is 24. Output ONLY the code uppercase no spaces nothing else.",
            messages={{role="user",content=prompt}}
        })
        local resp=HttpService:RequestAsync({
            Url="https://api.anthropic.com/v1/messages",
            Method="POST",
            Headers={
                ["Content-Type"]="application/json",
                ["x-api-key"]=ANTHROPIC_KEY,
                ["anthropic-version"]="2023-06-01",
            },
            Body=body,
        })
        if resp.StatusCode==200 then
            local data=HttpService:JSONDecode(resp.Body)
            if data and data.content and data.content[1] then return data.content[1].text end
        end
        return nil
    end)
    if ok and result then return tostring(result):match("^%s*([A-Z0-9_%-]+)%s*$") end
    return nil
end

-- Debounce for performance
local lastProcessTime = 0
local PROCESS_COOLDOWN = 0.05  -- Faster for SAB spam

local function processGlobal(txt)
    if not _enabled then return end
    if not txt or type(txt)~="string" or #txt<2 then return end
    if _seen[txt] then return end

    local now = tick()
    if now - lastProcessTime < PROCESS_COOLDOWN then return end
    lastProcessTime = now

    _seen[txt]=true
    task.delay(20, function() _seen[txt]=nil end)

    if isRiddle(txt) then
        showRiddle("Solving...",T.Yellow)
        setStatus("Riddle detected...",T.Yellow)
        local ans=solveLocal(txt)
        if ans then
            showRiddle("Answer: "..ans,T.Green)
            setStatus("Solved: "..ans,T.Green)
            pasteCleanCode(ans)
            addToHistory(ans, "Riddle (Local)", true)
            playDetectSound()
            showNotification("Riddle solved: " .. ans)
            if config.copyToClipboard and setclipboard then setclipboard(ans) end
            HistoryBtn.Text = "Code History (" .. #codeHistory .. ")"
            task.delay(4,hideRiddle); return
        end
        showRiddle("Asking AI...",T.Yellow)
        task.spawn(function()
            local ai=callAI("Sammy said: "..txt..". SAB=May2024,Sammy=24. Code only.")
            if ai then
                showRiddle("AI: "..ai,T.Green)
                setStatus("AI solved: "..ai,T.Green)
                pasteCleanCode(ai)
                addToHistory(ai, "Riddle (AI)", true)
                playDetectSound()
                showNotification("AI solved riddle: " .. ai)
                if config.copyToClipboard and setclipboard then setclipboard(ai) end
                HistoryBtn.Text = "Code History (" .. #codeHistory .. ")"
                task.delay(4,hideRiddle)
            else
                showRiddle("Could not solve",T.Red)
                setStatus("Riddle unsolved",T.Red)
                task.delay(3,function()
                    hideRiddle()
                    setStatus(_focused and "Ready - watching" or "Click the code box first",
                        _focused and T.Green or T.Dim)
                end)
            end
        end)
        return
    end

    -- Use the smart SAB extractor
    local code=extractSABCode(txt)
    if code then 
        -- Auto-paste clean code into the text box
        local pasted = false
        if config.autoPaste then
            pasted = pasteCleanCode(code)
        end
        if not pasted then
            flashCode(code, T.Accent)
        end
        addToHistory(code, "Detected", false)
        playDetectSound()
        showNotification("Code: " .. code)
        if config.copyToClipboard and setclipboard then setclipboard(code) end
        HistoryBtn.Text = "Code History (" .. #codeHistory .. ")"
    end
end

-- Optimized watching
local _watched={}
local function watchLabel(obj)
    if _watched[obj] then return end
    _watched[obj]=true
    local lastText = obj.Text
    obj:GetPropertyChangedSignal("Text"):Connect(function()
        local newText = obj.Text
        if newText ~= lastText then
            lastText = newText
            processGlobal(newText)
        end
    end)
end

local BAD={"backpack","inventory","chatmain","bubblechat","overhead","nametag","leaderboard","hudgui"}
local GOOD={"global","announce","notif","banner","broadcast","event","popup","sammy","alert","header","news","system","message","center"}
local function classify(obj)
    local n=(obj.Name or ""):lower()
    local pn=((obj.Parent and obj.Parent.Name) or ""):lower()
    local gpn=((obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name) or ""):lower()
    for _,b in ipairs(BAD) do if n:find(b) or pn:find(b) then return false end end
    for _,g in ipairs(GOOD) do
        if n:find(g) or pn:find(g) or gpn:find(g) then return true end
    end
    return false
end

-- Batch process descendants
local pendingDescendants = {}
local processingDescendants = false

local function processPendingDescendants()
    if processingDescendants then return end
    processingDescendants = true

    while #pendingDescendants > 0 do
        local batch = {}
        for i = 1, math.min(10, #pendingDescendants) do
            table.insert(batch, table.remove(pendingDescendants, 1))
        end

        for _, obj in ipairs(batch) do
            if obj and obj.Parent then
                local txt = obj.Text or ""
                if classify(obj) or extractSABCode(txt) or isRiddle(txt) then
                    watchLabel(obj)
                    if #txt > 1 then processGlobal(txt) end
                end
                obj:GetPropertyChangedSignal("Text"):Connect(function()
                    local t = obj.Text or ""
                    if classify(obj) or extractSABCode(t) or isRiddle(t) then
                        if not _watched[obj] then watchLabel(obj) end
                        processGlobal(t)
                    end
                end)
            end
        end

        task.wait(0.05)
    end

    processingDescendants = false
end

playerGui.DescendantAdded:Connect(function(obj)
    task.wait(0.04)
    if obj:IsA("TextLabel") then
        table.insert(pendingDescendants, obj)
        task.spawn(processPendingDescendants)
    end
end)

pcall(function()
    local tcs=game:GetService("TextChatService")
    if tcs and tcs.MessageReceived then
        tcs.MessageReceived:Connect(function(msg)
            if not msg then return end
            processGlobal(msg.Text or "")
        end)
    end
end)

pcall(function()
    local shared=ReplicatedStorage:WaitForChild("Shared",5)
    if not shared then return end
    local flags=shared:WaitForChild("Flags",5); if not flags then return end
    local cf=flags:WaitForChild("CodesFlags",5); if not cf then return end
    cf.ChildAdded:Connect(function(obj)
        processGlobal(obj.Name)
        if obj:IsA("StringValue") then
            processGlobal(tostring(obj.Value))
            obj:GetPropertyChangedSignal("Value"):Connect(function()
                processGlobal(tostring(obj.Value))
            end)
        end
    end)
end)

pcall(function()
    local ctrl=ReplicatedStorage:WaitForChild("Controllers",5)
    if not ctrl then return end
    local cc=ctrl:WaitForChild("CodesController",5); if not cc then return end
    cc.DescendantAdded:Connect(function(obj)
        if obj:IsA("StringValue") then processGlobal(tostring(obj.Value)) end
        processGlobal(obj.Name)
    end)
end)

-- Auto-detect code input box
if config.autoDetectInput then
    task.spawn(function()
        while task.wait(1) do
            if not _focused or not _focused.Parent then
                for _, obj in ipairs(playerGui:GetDescendants()) do
                    if obj:IsA("TextBox") then
                        local n = (obj.Name or ""):lower()
                        local pn = ((obj.Parent and obj.Parent.Name) or ""):lower()
                        if n:find("code") or n:find("promo") or n:find("redeem") or 
                           pn:find("code") or pn:find("promo") or pn:find("redeem") then
                            _focused = obj
                            if _enabled then setStatus("Auto-detected code box", T.Green) end
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- Instant paste mode: auto-focus and paste when code detected
if config.instantPaste then
    task.spawn(function()
        while task.wait(0.5) do
            if _enabled and #codeHistory > 0 then
                local latest = codeHistory[1]
                if latest and (os.time() - latest.timestamp) <= 2 then
                    -- Code detected very recently, try to paste it
                    if _focused and _focused.Parent then
                        _focused.Text = latest.code
                    end
                end
            end
        end
    end)
end

-- Apply saved sky theme
KnoxApplyCustomSky(currentSkyTheme)

setStatus("Click the code box first",T.Dim)
flashCode("-",T.Dim)
