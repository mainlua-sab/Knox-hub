local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/knoxexploits/Ui-Library/refs/heads/main/BlackAscended.lua"))()
local win = library.new({
    Name = "Knox Hub",
    ConfigurationSaving = true,
    Scale = 1
})
local infoTab = win:CreateTab("Info")
infoTab:CreateSearch({
    Name = "Search",
    Placeholder = "Search...",
    Callback = function(text)
        -- Search functionality here
        print("Search query: " .. text)
    end
})
infoTab:CreateSection("Info")
infoTab:CreateDropdown({
    Name    = "Gui Size",
    Options = { "Small", "Medium", "Big" },
    Callback = function(selected)
        if selected == "Small" then
            win:SetScale(0.75)
        elseif selected == "Medium" then
            win:SetScale(1.0)
        elseif selected == "Big" then
            win:SetScale(1.25)
        end
    end
})
local pingInfo = infoTab:CreateInfo({
    Title = "Ping",
    Value = "Calculating..."
})
local fpsInfo = infoTab:CreateInfo({
    Title = "FPS",
    Value = "Calculating..."
})
infoTab:CreateButton("Copy Discord", function()
    setclipboard("https://discord.gg/dxdxZzyfmx")
    win:Notify({
        Title = "Success",
        Content = "Discord link copied to clipboard!",
        Duration = 3
    })
end)
infoTab:CreateToggle({
    Name = "Save Config",
    CurrentValue = false,
    Flag = "SaveConfigToggle",
    Callback = function(state)
        win.Config.Enabled = state
        if state then
            library.Flags["SaveConfigToggle"] = false
            win:Save()
        end
    end
})
local function resetMiniButtonPositions()
    local MINI_POS_PREFIX = "__minipos__"
    local entries = {
        { isAction = true,  flag = "TpDownMini"        },
        { isAction = false, flag = "AutoPlayMini"       },
        { isAction = false, flag = "LockMini"           },
        { isAction = true,  flag = "DropBrainrotMini"   },
    }
    for _, entry in ipairs(entries) do
        if entry.isAction then
            library.Flags[MINI_POS_PREFIX .. "act__" .. entry.flag] = nil
        else
            library.Flags[MINI_POS_PREFIX .. entry.flag] = nil
        end
    end
    library.Flags["SaveConfigToggle"] = false
    win.Config.Enabled = true
    win:Save()
    win.Config.Enabled = false
    win:Notify({
        Title   = "Positions Reset",
        Content = "Turn Off save config, Click ResetMiniBtn, Rejoin.",
        Duration = 5
    })
end
infoTab:CreateButton("ResetButtonPos", function()
    resetMiniButtonPositions()
end)
win:SetScale(1.0)
task.spawn(function()
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    while true do
        pcall(function()
            local deltaTime = RunService.RenderStepped:Wait()
            if deltaTime and deltaTime > 0 then
                local fps = math.floor(1 / deltaTime)
                pingInfo:Set(fps .. " fps")
            end
        end)
        pcall(function()
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            if ping then
                pingInfo:Set(math.floor(ping) .. " ms")
            end
        end)
        pcall(function()
            fpsInfo:Set(math.floor(1 / RunService.RenderStepped:Wait()) .. " fps")
        end)
        task.wait(1)
    end
end)
local mainTab = win:CreateTab("Main")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("RunService")
local V3 = Vector3.new
local IN = Instance.new
local lockMiniButtonInstance = nil
local lockActive = false
local lockCdBlocked = false
local lockHbConn = nil
local lockAtt = nil
local lockLv = nil
local LOCK_RADIUS = 250
local LOCK_SPEED = 53
local knoxNumericCfg = { lockPrediction = 1 }
local function getNearest()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest = nil
    local nearestDist = LOCK_RADIUS
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local pc = plr.Character
            local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
            if phrp then
                local d = (phrp.Position - hrp.Position).Magnitude
                if d <= nearestDist then
                    nearest = plr
                    nearestDist = d
                end
            end
        end
    end
    return nearest
end
local function getBat()
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and string.find(string.lower(t.Name), "bat", 1, true) then
            return t
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "bat", 1, true) then
                return t
            end
        end
    end
    return nil
end
local function startLock()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    lockAtt = IN("Attachment")
    lockAtt.Parent = hrp
    lockLv = IN("LinearVelocity")
    lockLv.Parent = hrp
    lockLv.Attachment0 = lockAtt
    lockLv.MaxForce = 50000
    lockLv.RelativeTo = Enum.ActuatorRelativeTo.World
    lockLv.Enabled = false
    lockHbConn = RS.Heartbeat:Connect(function()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not lockActive or lockCdBlocked or (hum and hum.WalkSpeed <= 25) then
            if lockLv then lockLv.Enabled = false end
            return
        end
        local targetPlayer = getNearest()
        if not targetPlayer then
            lockLv.Enabled = false
            return
        end
        local tChar = targetPlayer.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tHrp then
            lockLv.Enabled = false
            return
        end
        lockLv.Enabled = true
        local pred = knoxNumericCfg.lockPrediction or 0
        local velocity = tHrp.AssemblyLinearVelocity or V3(0, 0, 0)
        local predicted = tHrp.Position + (velocity * (pred * 0.05))
        local targetFacing = tHrp.CFrame.LookVector
        predicted = predicted + V3(targetFacing.X, 0, targetFacing.Z).Unit * 2
        local dir = predicted - hrp.Position
        if dir.Magnitude > 0.1 then
            lockLv.VectorVelocity = dir.Unit * 54
        else
            lockLv.VectorVelocity = V3(0, 0, 0)
        end
        local flatDir = V3(dir.X, 0, dir.Z)
        if flatDir.Magnitude > 0.1 then
            local angle = math.atan2(-flatDir.X, -flatDir.Z)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, angle, 0)
        end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if not currentTool then
            local bat = getBat()
            if bat then char.Humanoid:EquipTool(bat) end
        elseif currentTool and string.find(string.lower(currentTool.Name), "bat", 1, true) then
            currentTool:Activate()
        end
    end)
end
local function stopLock()
    lockActive = false
    if lockHbConn then lockHbConn:Disconnect(); lockHbConn = nil end
    if lockLv then lockLv:Destroy(); lockLv = nil end
    if lockAtt then lockAtt:Destroy(); lockAtt = nil end
end
mainTab:CreateToggle({
    Name = "Lock",
    CurrentValue = false,
    Flag = "LockToggle",
    Callback = function(state)
        if state then
            if not lockMiniButtonInstance then
                lockMiniButtonInstance = win:CreateMiniButton({
                    Flag = "LockMini",
                    Label = "Lock Target",
                    CurrentValue = false,
                    Callback = function(miniState)
                        if miniState and lockCdBlocked then return end
                        lockActive = miniState
                        if lockActive then
                            startLock()
                        else
                            stopLock()
                        end
                    end
                })
            end
            lockMiniButtonInstance.gui.Enabled = true
        else
            stopLock()
            if lockMiniButtonInstance then
                lockMiniButtonInstance.gui.Enabled = false
                lockMiniButtonInstance:SetState(false)
            end
        end
    end
})
local godmodeConn = nil
local function applyGodmode()
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        if godmodeConn then godmodeConn:Disconnect() end
        godmodeConn = RS.Heartbeat:Connect(function()
            if hum and hum.Parent then
                if hum.Health < math.huge then hum.Health = math.huge end
                if hum.MaxHealth < math.huge then hum.MaxHealth = math.huge end
            end
        end)
    end)
end
local function applyJumpPower()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower = 40
end
applyGodmode()
applyJumpPower()
LocalPlayer.CharacterAdded:Connect(function()
    if godmodeConn then godmodeConn:Disconnect(); godmodeConn = nil end
    task.wait(0.3)
    applyGodmode()
    applyJumpPower()
    if egoPlaying then
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
    end
end)
local antiRagdollMode = false
local ragdollConnections = {}
local cachedCharData = {}
local lp = LocalPlayer
local function cacheCharacterData()
    local char = lp.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = { character = char, humanoid = hum, root = root }
    return true
end
local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end
local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    if state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown then return true end
    local endTime = lp:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end
    return false
end
local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    local hum = cachedCharData.humanoid
    local root = cachedCharData.root
    pcall(function() lp:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    for _, d in ipairs(cachedCharData.character:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
    if hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end
    root.Anchored = false
    if not lockActive then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    pcall(function()
        local controls = lp.PlayerScripts and lp.PlayerScripts:FindFirstChild("PlayerModule")
        if controls then
            local m = require(controls)
            if m and type(m.GetControls) == "function" then
                local ac = m:GetControls()
                if ac and type(ac.Enable) == "function" then ac:Enable(true) end
            end
        end
    end)
end
local function antiRagdollLoop()
    while antiRagdollMode do
        task.wait()
        if cacheCharacterData() then
            if isRagdolled() then forceExitRagdoll() end
            local cam = workspace.CurrentCamera
            if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
                cam.CameraSubject = cachedCharData.humanoid
            end
        end
    end
end
mainTab:CreateToggle({
    Name = "Antiragdoll",
    CurrentValue = false,
    Flag = "AntiRagdollToggle",
    Callback = function(state)
        antiRagdollMode = state
        if state then
            task.spawn(antiRagdollLoop)
        else
            disconnectAllRagdoll()
        end
    end
})
local medusaCounterEnabled = false
local medusaCounterCount   = 0
local medusaConnections    = {}
local medusaLastFire       = 0
local medusaCharConn       = nil
local function findMedusaTool()
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end
        end
    end
    return nil
end
local function runMedusaCounter()
    local now = tick()
    if now - medusaLastFire < 1.5 then return end
    medusaLastFire = now
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local tool = findMedusaTool()
    if not tool then return end
    if tool.Parent ~= char then
        pcall(function() hum:EquipTool(tool) end)
    end
    pcall(function() tool:Activate() end)
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            pcall(function() v:FireServer() end)
        end
    end
    medusaCounterCount += 1
end
local function hookMedusaCharacter(char)
    for _, c in ipairs(medusaConnections) do pcall(function() c:Disconnect() end) end
    table.clear(medusaConnections)
    local head = char:WaitForChild("Head", 5)
    if head then
        table.insert(medusaConnections,
            head:GetPropertyChangedSignal("Anchored"):Connect(function()
                if medusaCounterEnabled and head.Anchored then
                    task.spawn(runMedusaCounter)
                end
            end)
        )
    end
    local torso = char:WaitForChild("UpperTorso", 5)
    if torso then
        table.insert(medusaConnections,
            torso:GetPropertyChangedSignal("Anchored"):Connect(function()
                if medusaCounterEnabled and torso.Anchored then
                    task.spawn(runMedusaCounter)
                end
            end)
        )
    end
end
local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED    = 150
local function runDrop()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local t0 = tick()
    local dc
    dc = RS.Heartbeat:Connect(function()
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not r then dc:Disconnect(); return end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            dc:Disconnect()
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {char}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local rr = workspace:Raycast(r.Position, V3(0,-2000,0), rp)
            if rr then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local off = (hum and hum.HipHeight or 2) + (r.Size.Y / 2)
                r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
                r.AssemblyLinearVelocity = V3(0,0,0)
            end
            return
        end
        r.AssemblyLinearVelocity = V3(
            r.AssemblyLinearVelocity.X,
            DROP_ASCEND_SPEED,
            r.AssemblyLinearVelocity.Z
        )
    end)
end
local dropBrainrotMiniButton = nil
mainTab:CreateToggle({
    Name         = "Drop Brainrot",
    CurrentValue = false,
    Flag         = "DropBrainrotToggle",
    Callback     = function(state)
        if state then
            if not dropBrainrotMiniButton then
                dropBrainrotMiniButton = win:CreateMiniActionButton({
                    Flag     = "DropBrainrotMini",
                    Label    = "Drop",
                    Callback = function()
                        runDrop()
                        task.delay(0.05, function() runDrop() end)
                        task.delay(0.1,  function() runDrop() end)
                    end
                })
            end
            dropBrainrotMiniButton.gui.Enabled = true
        else
            if dropBrainrotMiniButton then
                dropBrainrotMiniButton.gui.Enabled = false
            end
        end
    end
})
local normalSpeed = 55
local stealSpeed  = 29.25
local autoPlayCd  = 0.4
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local agBarGui = Instance.new("ScreenGui")
agBarGui.Name = "KnoxAutoGrabBar"
agBarGui.ResetOnSpawn = false
agBarGui.DisplayOrder = 999
agBarGui.Parent = game:GetService("CoreGui")
local ragBarBg = Instance.new("Frame", agBarGui)
ragBarBg.Size = UDim2.new(0, 100, 0, 12)
ragBarBg.Position = UDim2.new(0.5, -50, 0, -5)
ragBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ragBarBg.BackgroundTransparency = 0.2
ragBarBg.BorderSizePixel = 0
ragBarBg.Visible = false
Instance.new("UICorner", ragBarBg).CornerRadius = UDim.new(1, 0)
local ragBarFill = Instance.new("Frame", ragBarBg)
ragBarFill.Size = UDim2.new(0, 0, 1, 0)
ragBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ragBarFill.BorderSizePixel = 0
Instance.new("UICorner", ragBarFill).CornerRadius = UDim.new(1, 0)
local ragBarLabel = Instance.new("TextLabel", ragBarBg)
ragBarLabel.Size = UDim2.new(1, 0, 1, 0)
ragBarLabel.BackgroundTransparency = 1
ragBarLabel.Text = "Waiting for ragdoll"
ragBarLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ragBarLabel.TextStrokeTransparency = 0.5
ragBarLabel.Font = Enum.Font.GothamBold
ragBarLabel.TextSize = 7
ragBarLabel.ZIndex = 2
local ragBarProgress   = 0
local ragBarFilling    = false
local ragBarThread     = nil
local RAG_BAR_DURATION = 3
local function ragBarStartFill()
    ragBarFilling = false
    if ragBarThread then task.cancel(ragBarThread) end
    ragBarProgress = 0
    ragBarFilling  = true
    ragBarThread   = task.spawn(function()
        local startTime = tick()
        while ragBarFilling do
            local elapsed = tick() - startTime
            ragBarProgress = math.clamp(elapsed / RAG_BAR_DURATION, 0, 1)
            if ragBarProgress >= 1 then
                ragBarFilling = false
                ragBarProgress = 0
                break
            end
            task.wait(0.05)
        end
        ragBarProgress = 0
    end)
end
task.spawn(function()
    local wasRagdolled = false
    while true do
        task.wait(0.05)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local nowRagdolled = false
        if hum then
            local state = hum:GetState()
            nowRagdolled = (state == Enum.HumanoidStateType.Physics
                or state == Enum.HumanoidStateType.Ragdoll
                or state == Enum.HumanoidStateType.FallingDown)
            if not nowRagdolled then
                local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
                if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
                    nowRagdolled = true
                end
            end
        end
        if nowRagdolled and not wasRagdolled then
            ragBarStartFill()
        end
        wasRagdolled = nowRagdolled
    end
end)
task.spawn(function()
    while true do
        task.wait(0.05)
        ragBarBg.Visible = true
        ragBarFill.Size  = UDim2.new(ragBarProgress, 0, 1, 0)
        if ragBarFilling then
            ragBarLabel.Text = math.floor(ragBarProgress * 100) .. "%"
        else
            ragBarLabel.Text = "Waiting for ragdoll"
        end
    end
end)
local agBarBg = Instance.new("Frame", agBarGui)
agBarBg.Size = UDim2.new(0, 160, 0, 12)
agBarBg.Position = UDim2.new(0.5, -80, 0, 9)
agBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
agBarBg.BackgroundTransparency = 0.2
agBarBg.BorderSizePixel = 0
agBarBg.Visible = false
Instance.new("UICorner", agBarBg).CornerRadius = UDim.new(1, 0)
local agBarFill = Instance.new("Frame", agBarBg)
agBarFill.Size = UDim2.new(0, 0, 1, 0)
agBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
agBarFill.BorderSizePixel = 0
Instance.new("UICorner", agBarFill).CornerRadius = UDim.new(1, 0)
local agBarLabel = Instance.new("TextLabel", agBarBg)
agBarLabel.Size = UDim2.new(1, 0, 1, 0)
agBarLabel.BackgroundTransparency = 1
agBarLabel.Text = "Grabbing..."
agBarLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
agBarLabel.TextStrokeTransparency = 0.5
agBarLabel.Font = Enum.Font.GothamBold
agBarLabel.TextSize = 8
agBarLabel.ZIndex = 2
local agSyncInternal = { _cache = {}, _dataTable = nil }
local function agGetInternalTable()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    local SynchronizerModule = Packages and Packages:FindFirstChild("Synchronizer")
    if not SynchronizerModule then return nil end
    local ok, sync = pcall(require, SynchronizerModule)
    if not ok or not sync then return nil end
    local GetMethod = sync.Get
    if type(GetMethod) ~= "function" then return nil end
    for i = 1, 5 do
        local s, uv = pcall(getupvalue, GetMethod, i)
        if s and type(uv) == "table" then
            if uv.___private or uv.___channels or uv.___data then return uv end
            for k, v in pairs(uv) do
                if (type(k) == "string" and k:match("^Plot_")) or type(v) == "table" then return uv end
            end
        end
    end
    local s, env = pcall(getfenv, GetMethod)
    if s and env and env.self then return env.self end
    return nil
end
task.spawn(function()
    local attempts = 0
    while attempts < 10 and not agSyncInternal._dataTable do
        agSyncInternal._dataTable = agGetInternalTable()
        if not agSyncInternal._dataTable then task.wait(1); attempts += 1 end
    end
end)
local function agStealthGet(plotName)
    if not plotName or type(plotName) ~= "string" then return nil end
    if agSyncInternal._cache[plotName] == false then return nil end
    if agSyncInternal._dataTable then
        local keys = { plotName, "Plot_"..plotName, "Plot"..plotName, plotName.."_Channel", "Channel_"..plotName }
        for _, k in ipairs(keys) do
            if agSyncInternal._dataTable[k] then
                agSyncInternal._cache[plotName] = agSyncInternal._dataTable[k]
                return agSyncInternal._dataTable[k]
            end
        end
        for k, v in pairs(agSyncInternal._dataTable) do
            if type(k) == "string" and (k == plotName or k:find(plotName, 1, true)) and type(v) == "table" then
                agSyncInternal._cache[plotName] = v; return v
            end
        end
    end
    agSyncInternal._cache[plotName] = false; return nil
end
local function agStealthGetProp(channel, prop)
    if not channel or type(channel) ~= "table" then return nil end
    if channel[prop] then return channel[prop] end
    if type(channel.Get) == "function" then
        local ok, r = pcall(channel.Get, channel, prop); if ok then return r end
    end
    local alts = { Owner={"owner","Owner","plotOwner","PlotOwner"}, AnimalList={"animalList","AnimalList","animals","Animals","pets"} }
    if alts[prop] then for _, a in ipairs(alts[prop]) do if channel[a] then return channel[a] end end end
    return nil
end
local agAllAnimals = {}
local agPromptCache = {}
local agStealCache = {}
local agIsCurrentlyStealing = false
local agCurrentProgress = 0
local agStealConn = nil
local agEnabled = false
local AgAnimalsData, AgAnimalsShared, AgNumberUtils
task.spawn(function()
    local Datas  = ReplicatedStorage:FindFirstChild("Datas")
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    local Utils  = ReplicatedStorage:FindFirstChild("Utils")
    for i = 1, 10 do
        if Datas  and not AgAnimalsData   then local ok,r = pcall(require, Datas:FindFirstChild("Animals"))   if ok then AgAnimalsData   = r end end
        if Shared and not AgAnimalsShared then local ok,r = pcall(require, Shared:FindFirstChild("Animals"))  if ok then AgAnimalsShared = r end end
        if Utils  and not AgNumberUtils   then local ok,r = pcall(require, Utils:FindFirstChild("NumberUtils")) if ok then AgNumberUtils = r end end
        if AgAnimalsData and AgAnimalsShared and AgNumberUtils then break end
        task.wait(0.5)
    end
end)
local function agIsMyPlot(animalData)
    if not animalData or not animalData.plot then return false end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot = plots:FindFirstChild(animalData.plot); if not plot then return false end
    local channel = agStealthGet(plot.Name)
    if channel then
        local owner = agStealthGetProp(channel, "Owner")
        if owner then
            if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == LocalPlayer.UserId end
            if typeof(owner) == "table" and owner.UserId then return owner.UserId == LocalPlayer.UserId end
            if typeof(owner) == "Instance" then return owner == LocalPlayer end
        end
    end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then local yb = sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled end end
    return false
end
local function agGetTarget()
    for _, a in ipairs(agAllAnimals) do
        if not agIsMyPlot(a) then return a end
    end
    return nil
end
local function agFindPrompt(animalData)
    if not animalData then return nil end
    local cached = agPromptCache[animalData.uid]
    if cached and cached.Parent then return cached end
    if cached and not cached.Parent then
        agStealCache[cached] = nil
        agPromptCache[animalData.uid] = nil
    end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot = plots:FindFirstChild(animalData.plot); if not plot then return nil end
    local foundPrompt = nil
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        local podium = podiums:FindFirstChild(animalData.slot)
        if podium then
            local base = podium:FindFirstChild("Base")
            local spawn = base and base:FindFirstChild("Spawn")
            local attach = spawn and spawn:FindFirstChild("PromptAttachment")
            if attach then
                for _, p in ipairs(attach:GetChildren()) do
                    if p:IsA("ProximityPrompt") then foundPrompt = p; break end
                end
            end
        end
    end
    if not foundPrompt and animalData.worldPosition then
        local bestDist = 12
        for _, obj in ipairs(plot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" and obj.Parent then
                local p = obj.Parent
                local pos
                if p:IsA("BasePart") then pos = p.Position
                elseif p:IsA("Attachment") then pos = p.WorldPosition
                elseif p:IsA("Model") then
                    local pp = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                    pos = pp and pp.Position
                end
                if pos then
                    local d = (pos - animalData.worldPosition).Magnitude
                    if d < bestDist then bestDist = d; foundPrompt = obj end
                end
            end
        end
    end
    if foundPrompt then
        agPromptCache[animalData.uid] = foundPrompt
    end
    return foundPrompt
end
local function agBuildCallbacks(prompt)
    local existing = agStealCache[prompt]
    if existing and not existing.useFallback then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then for _, c in ipairs(c1) do if type(c.Function) == "function" then table.insert(data.holdCallbacks, c.Function) end end end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then for _, c in ipairs(c2) do if type(c.Function) == "function" then table.insert(data.triggerCallbacks, c.Function) end end end
    if #data.holdCallbacks == 0 and #data.triggerCallbacks == 0 then
        data.useFallback = true
        if not existing then
            agStealCache[prompt] = data
        end
        return
    end
    agStealCache[prompt] = data
end
local AG_GRAB_SPEED = 1.3
local function agExecuteSteal(prompt)
    local data = agStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    agIsCurrentlyStealing = true
    agCurrentProgress = 0
    local startTime = tick()
    task.spawn(function()
        pcall(function()
            if data.useFallback then
                prompt.MaxActivationDistance = 9e9
                prompt.RequiresLineOfSight = false
                pcall(function()
                    fireproximityprompt(prompt, 9e9, AG_GRAB_SPEED)
                    prompt:InputHoldBegin()
                    while (tick() - startTime) < AG_GRAB_SPEED do
                        agCurrentProgress = math.clamp((tick() - startTime) / AG_GRAB_SPEED * 100, 0, 100)
                        task.wait(0.05)
                    end
                    prompt:InputHoldEnd()
                end)
            else
                for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
                while (tick() - startTime) < AG_GRAB_SPEED do
                    agCurrentProgress = math.clamp((tick() - startTime) / AG_GRAB_SPEED * 100, 0, 100)
                    task.wait(0.05)
                end
                for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
            end
        end)
        agCurrentProgress = 100
        task.wait()
        data.ready = true
        agIsCurrentlyStealing = false
        agCurrentProgress = 0
    end)
    return true
end
local agGrabRadius = 8
local function agGetPromptPos(prompt)
    if not prompt then return nil end
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("Model") then
        local pp = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
    local part = p:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position
end
task.spawn(function()
    while true do
        task.wait(0.05)
        if agEnabled then
            agBarBg.Visible = true
            if agIsCurrentlyStealing then
                local prog = agCurrentProgress / 100
                agBarFill.Size = UDim2.new(prog, 0, 1, 0)
                agBarLabel.Text = math.floor(agCurrentProgress) .. "%"
            else
                local inRange = false
                local target = agGetTarget()
                if target then
                    local prompt = agPromptCache[target.uid]
                    if not prompt or not prompt.Parent then
                        prompt = agFindPrompt(target)
                    end
                    if prompt and prompt.Parent then
                        local pos = agGetPromptPos(prompt)
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if pos and hrp then
                            inRange = (hrp.Position - pos).Magnitude <= agGrabRadius
                        end
                    end
                end
                agBarFill.Size = UDim2.new(0, 0, 1, 0)
                agBarLabel.Text = inRange and "In Range" or "Too Far"
            end
        else
            agBarFill.Size = UDim2.new(0, 0, 1, 0)
            agBarBg.Visible = false
        end
    end
end)
local agPlotChannels = {}; local agLastAnimalData = {}; local agScanConns = {}
local function agScanPlot(plot)
    pcall(function()
        local uid = plot.Name
        local channel = agStealthGet(uid); if not channel then return end
        local animalList = agStealthGetProp(channel, "AnimalList")
        local hash = ""; if animalList then for s, d in pairs(animalList) do if type(d)=="table" then hash=hash..tostring(s)..tostring(d.Index)..tostring(d.Mutation) end end end
        if agLastAnimalData[uid] == hash then return end
        agLastAnimalData[uid] = hash
        for i = #agAllAnimals, 1, -1 do if agAllAnimals[i].plot == uid then table.remove(agAllAnimals, i) end end
        local owner = agStealthGetProp(channel, "Owner")
        if not owner or not Players:FindFirstChild(owner.Name) then return end
        if not animalList then return end
        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table" and AgAnimalsData and AgAnimalsShared and AgNumberUtils then
                local info = AgAnimalsData[animalData.Index]; if not info then continue end
                local genValue = AgAnimalsShared:GetGeneration(animalData.Index, animalData.Mutation, animalData.Traits, nil)
                table.insert(agAllAnimals, {
                    name = info.DisplayName or animalData.Index,
                    genText = "$"..AgNumberUtils:ToString(genValue).."/s",
                    genValue = genValue,
                    mutation = animalData.Mutation or "None",
                    owner = owner.Name,
                    plot = uid,
                    slot = tostring(slot),
                    uid = uid.."_"..tostring(slot),
                })
            end
        end
        table.sort(agAllAnimals, function(a, b) return a.genValue > b.genValue end)
    end)
end
local function agSetupPlot(plot)
    if agPlotChannels[plot.Name] then return end
    local channel; local retries = 0
    while not channel and retries < 3 do channel = agStealthGet(plot.Name); if not channel then retries += 1; task.wait(0.3) end end
    if not channel then return end
    agPlotChannels[plot.Name] = true
    agScanPlot(plot)
    table.insert(agScanConns, plot.DescendantAdded:Connect(function() task.wait(0.05); agScanPlot(plot) end))
    table.insert(agScanConns, plot.DescendantRemoving:Connect(function() task.wait(0.05); agScanPlot(plot) end))
    task.spawn(function() while plot.Parent and agPlotChannels[plot.Name] do task.wait(3); agScanPlot(plot) end end)
end
task.spawn(function()
    local plots = workspace:WaitForChild("Plots", 30)
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do task.spawn(agSetupPlot, plot) end
    plots.ChildAdded:Connect(function(plot) task.wait(0.2); task.spawn(agSetupPlot, plot) end)
    plots.ChildRemoved:Connect(function(plot)
        agPlotChannels[plot.Name] = nil; agLastAnimalData[plot.Name] = nil
        for i = #agAllAnimals, 1, -1 do if agAllAnimals[i].plot == plot.Name then table.remove(agAllAnimals, i) end end
    end)
end)
task.spawn(function()
    while true do task.wait(2)
        for uid, prompt in pairs(agPromptCache) do
            if prompt and prompt.Parent then
                agBuildCallbacks(prompt)
            elseif prompt and not prompt.Parent then
                agStealCache[prompt] = nil
                agPromptCache[uid] = nil
            end
        end
    end
end)
local function agStartLoop()
    if agStealConn then agStealConn:Disconnect() end
    agStealConn = RS.Heartbeat:Connect(function()
        if not agEnabled or agIsCurrentlyStealing then return end
        local target = agGetTarget(); if not target then return end
        local prompt = agPromptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = agFindPrompt(target) end
        if not prompt then return end
        local promptPos = agGetPromptPos(prompt)
        if not promptPos then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (hrp.Position - promptPos).Magnitude
        if dist > agGrabRadius then return end
        if not agStealCache[prompt] then agBuildCallbacks(prompt) end
        agExecuteSteal(prompt)
    end)
end
local function agStopLoop()
    agEnabled = false
    if agStealConn then agStealConn:Disconnect(); agStealConn = nil end
    agIsCurrentlyStealing = false; agCurrentProgress = 0
end
mainTab:CreateToggle({
    Name = "Auto Grab",
    CurrentValue = false,
    Flag = "AutoGrabToggle",
    Callback = function(state)
        agEnabled = state
        if state then
            agStartLoop()
        else
            agStopLoop()
        end
    end
})
local autoMedusaEnabled = false
local autoMedusaRange   = 5
local autoMedusaConn    = nil
local medusaRing = Instance.new("CylinderHandleAdornment")
medusaRing.Name = "MedusaRangeRing"
medusaRing.Color3 = Color3.new(1, 1, 1)
medusaRing.Transparency = 0.5
medusaRing.Height = 0.1
medusaRing.AlwaysOnTop = false
medusaRing.ZIndex = 10
medusaRing.Visible = false
medusaRing.Parent = game:GetService("CoreGui")
RS.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if autoMedusaEnabled and hrp then
        medusaRing.Visible = true
        medusaRing.Adornee = hrp
        medusaRing.InnerRadius = (autoMedusaRange or 5) - 0.2
        medusaRing.Radius = (autoMedusaRange or 5)
        medusaRing.CFrame = CFrame.new(0, -2.8, 0) * CFrame.Angles(math.rad(90), 0, 0)
    else
        medusaRing.Visible = false
    end
end)
local function getMedusaTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("medusa") or tool:FindFirstChild("Handle")) then
            return tool
        end
    end
    return nil
end
local function isPlayerNearby(radius)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local pc   = plr.Character
            local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
            if phrp and (phrp.Position - hrp.Position).Magnitude <= radius then
                return true
            end
        end
    end
    return false
end
local function startAutoMedusa()
    if autoMedusaConn then autoMedusaConn:Disconnect() end
    local lastActivate = 0
    autoMedusaConn = RS.Heartbeat:Connect(function()
        if not autoMedusaEnabled then return end
        local now = tick()
        if now - lastActivate < 0.2 then return end
        local tool = getMedusaTool()
        if not tool then return end
        if not isPlayerNearby(autoMedusaRange) then return end
        lastActivate = now
        pcall(function() tool:Activate() end)
    end)
end
local function stopAutoMedusa()
    autoMedusaEnabled = false
    if autoMedusaConn then autoMedusaConn:Disconnect(); autoMedusaConn = nil end
end
mainTab:CreateToggle({
    Name         = "AutoMedusa",
    CurrentValue = false,
    Flag         = "AutoMedusaToggle",
    Callback     = function(state)
        autoMedusaEnabled = state
        if state then
            startAutoMedusa()
        else
            stopAutoMedusa()
        end
    end
})
local antiBatEnabled    = false
local antiBatMiniButton = nil
local antiBatConn       = nil
local function startAntiBat()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if antiBatConn then antiBatConn:Disconnect() end
    antiBatConn = RS.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.WalkSpeed > 25 then return end
        local orig = root.Velocity
        root.Velocity = Vector3.new(1000, root.Velocity.Y, 1000)
        RS.RenderStepped:Wait()
        root.Velocity = orig
    end)
end
local function stopAntiBat()
    if antiBatConn then antiBatConn:Disconnect(); antiBatConn = nil end
end
LocalPlayer.CharacterAdded:Connect(function()
    if antiBatEnabled then stopAntiBat(); task.wait(0.2); startAntiBat() end
end)
mainTab:CreateToggle({
    Name         = "AntiBat",
    CurrentValue = false,
    Flag         = "AntiBatToggle",
    Callback     = function(state)
        if state then
            if not antiBatMiniButton then
                antiBatMiniButton = win:CreateMiniButton({
                    Flag         = "AntiBatMini",
                    Label        = "AntiBat",
                    CurrentValue = false,
                    Callback     = function(miniState)
                        antiBatEnabled = miniState
                        if antiBatEnabled then
                            startAntiBat()
                        else
                            stopAntiBat()
                        end
                    end
                })
            end
            antiBatMiniButton.gui.Enabled = true
        else
            antiBatEnabled = false
            stopAntiBat()
            if antiBatMiniButton then
                antiBatMiniButton.gui.Enabled = false
                pcall(function() antiBatMiniButton:SetState(false) end)
            end
        end
    end
})
local egoPlaying = false
local autoPlayFloatEnabled = true
local egoMiniButtonInstance = nil
local EGO_RIGHT_GOING  = { Vector3.new(-475,-7,27), Vector3.new(-483,-5,24) }
local EGO_RIGHT_RETURN = { Vector3.new(-475,-7,27), Vector3.new(-475,-7,107) }
local EGO_LEFT_GOING   = { Vector3.new(-475,-7,93), Vector3.new(-483,-5,97) }
local EGO_LEFT_RETURN  = { Vector3.new(-475,-7,93), Vector3.new(-475,-7,17) }
local EGO_RIGHT_REF = Vector3.new(-479,-6,27)
local EGO_LEFT_REF  = Vector3.new(-479,-6,93)
local function egoDetectSide()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "right" end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return "right" end
    local nearestPos, nearestDist = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        for _, obj in ipairs(plot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" then
                local p = obj.Parent
                local pos
                if p:IsA("BasePart") then pos = p.Position
                elseif p:IsA("Attachment") then pos = p.WorldPosition
                elseif p:IsA("Model") then
                    local pp = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                    pos = pp and pp.Position
                end
                if pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < nearestDist then nearestDist = d; nearestPos = pos end
                end
            end
        end
    end
    if nearestPos then
        return ((nearestPos - EGO_LEFT_REF).Magnitude <= (nearestPos - EGO_RIGHT_REF).Magnitude)
            and "left" or "right"
    end
    return "right"
end
local function egoDuelsMachineVisible()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local outer = pg:FindFirstChild("DuelsMachineAnimation")
    if not outer then return false end
    local inner = outer:FindFirstChild("DuelsMachineAnimation")
    if not inner then return false end
    if inner:IsA("ScreenGui") then return inner.Enabled end
    if inner:IsA("GuiObject") then return inner.Visible end
    return false
end
local egoMoving = false
local egoTimerBlocked = false
local egoIsReturning         = false
local egoReturnedToFirstPoint = false
local egoTimerLockConn   = nil
local egoTimerLockedPos  = nil
local function egoStartMoveLock()
    egoTimerLockedPos = nil
    if egoTimerLockConn then egoTimerLockConn:Disconnect() end
    egoTimerLockConn = RS.Heartbeat:Connect(function()
        if not egoTimerBlocked then
            egoTimerLockConn:Disconnect()
            egoTimerLockConn = nil
            egoTimerLockedPos = nil
            return
        end
        local c   = LocalPlayer.Character
        local rp  = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not rp then return end
        local vel = rp.AssemblyLinearVelocity
        rp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
        if hum then
            hum:Move(Vector3.new(0, 0, 0))
        end
    end)
end
local function egoStopMoveLock()
    if egoTimerLockConn then
        egoTimerLockConn:Disconnect()
        egoTimerLockConn = nil
    end
    egoTimerLockedPos = nil
end
local floatInAutoPlay = false
local function egoCancelTween()
    egoMoving = false
end
local egoLvAtt = nil
local egoLv    = nil
local function egoSetupLV()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if egoLv  then pcall(function() egoLv:Destroy()  end); egoLv  = nil end
    if egoLvAtt then pcall(function() egoLvAtt:Destroy() end); egoLvAtt = nil end
    egoLvAtt = IN("Attachment")
    egoLvAtt.Parent = hrp
    egoLv = IN("LinearVelocity")
    egoLv.Parent = hrp
    egoLv.Attachment0 = egoLvAtt
    egoLv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    egoLv.MaxAxesForce = V3(50000, 0, 50000)
    egoLv.RelativeTo = Enum.ActuatorRelativeTo.World
    egoLv.VectorVelocity = V3(0, 0, 0)
    egoLv.Enabled = false
end
local function egoCleanupLV()
    if egoLv  then pcall(function() egoLv.Enabled = false; egoLv:Destroy()  end); egoLv  = nil end
    if egoLvAtt then pcall(function() egoLvAtt:Destroy() end); egoLvAtt = nil end
end
local LV_GOING_SPEED  = 0.75
local LV_RETURN_SPEED = 0.47
local LV_ARRIVE_GOING  = 3.0
local LV_ARRIVE_RETURN = 1.2
local LV_FACE_SMOOTH   = 0.90
local FLOAT_Y_FORCE    = 14000
local FLOAT_RAMP_TIME  = 0.18
local FLOAT_MAX_VEL    = 25
local FLOAT_PULL       = 10
local LAND_WAIT        = 0.3
local function egoGoTo_LV_return(target)
    if not egoPlaying then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not egoLv or not egoLv.Parent then egoSetupLV() end
    if not egoLv then return end
    local dist = Vector3.new(target.X - hrp.Position.X, 0, target.Z - hrp.Position.Z).Magnitude
    if dist < LV_ARRIVE_RETURN then return end
    egoLv.MaxAxesForce = V3(50000, 0, 50000)
    egoMoving = true
    egoLv.Enabled = true
    local conn
    conn = RS.RenderStepped:Connect(function()
        if not egoMoving or not egoPlaying then
            if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0) end
            conn:Disconnect(); return
        end
        local c  = LocalPlayer.Character
        local rp = c and c:FindFirstChild("HumanoidRootPart")
        local h  = c and c:FindFirstChildOfClass("Humanoid")
        if not rp or not h then egoMoving = false; conn:Disconnect(); return end
        local cur       = rp.Position
        local remaining = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z).Magnitude
        if remaining <= LV_ARRIVE_RETURN then
            egoMoving = false
            if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0) end
            conn:Disconnect(); return
        end
        local dir = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z).Unit
        local rspd = stealSpeed * LV_RETURN_SPEED
        local moveDir = Vector3.new(dir.X, 0, dir.Z)
        local nudge = moveDir * (rspd * 0.0125)
        rp.CFrame = CFrame.new(rp.Position + nudge) * (rp.CFrame - rp.CFrame.Position)
        egoLv.VectorVelocity = V3(dir.X * rspd, 0, dir.Z * rspd)
    end)
    while egoMoving and egoPlaying do task.wait(0.01) end
    if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0) end
end
local function egoGoGoing(waypoints, floatY)
    if not egoPlaying then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not egoLv or not egoLv.Parent then egoSetupLV() end
    if not egoLv then return end
    if floatY then
        egoLv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        egoLv.MaxAxesForce = V3(50000, FLOAT_Y_FORCE, 50000)
    else
        egoLv.MaxAxesForce = V3(50000, 0, 50000)
    end
    local floatStartTime = floatY and tick() or nil
    local wpIndex = 1
    local allDone = false
    egoMoving = true
    egoLv.Enabled = true
    local conn
    conn = RS.RenderStepped:Connect(function()
        if allDone or not egoMoving or not egoPlaying then
            if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0)
                egoLv.MaxAxesForce = V3(50000, 0, 50000) end
            conn:Disconnect(); return
        end
        local c  = LocalPlayer.Character
        local rp = c and c:FindFirstChild("HumanoidRootPart")
        local h  = c and c:FindFirstChildOfClass("Humanoid")
        if not rp or not h then
            egoMoving = false; allDone = true; conn:Disconnect(); return
        end
        while wpIndex <= #waypoints do
            local wp  = waypoints[wpIndex]
            local rem = Vector3.new(wp.X - rp.Position.X, 0, wp.Z - rp.Position.Z).Magnitude
            if rem > LV_ARRIVE_GOING then break end
            wpIndex = wpIndex + 1
        end
        if wpIndex > #waypoints then
            allDone = true; egoMoving = false
            if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0)
                egoLv.MaxAxesForce = V3(50000, 0, 50000) end
            conn:Disconnect(); return
        end
        local target = waypoints[wpIndex]
        local cur    = rp.Position
        local dir    = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z).Unit
        if dir.Magnitude > 0.1 then
            local tAngle = math.atan2(-dir.X, -dir.Z)
            local _, cAngle, _ = rp.CFrame:ToEulerAnglesYXZ()
            local delta  = ((tAngle - cAngle + math.pi) % (2 * math.pi)) - math.pi
            rp.CFrame = CFrame.new(rp.Position) * CFrame.Angles(0, cAngle + delta * LV_FACE_SMOOTH, 0)
        end
        local yVel = 0
        if floatY and floatStartTime then
            local rampT = math.clamp((tick() - floatStartTime) / FLOAT_RAMP_TIME, 0, 1)
            local ease  = rampT * rampT * (3 - 2 * rampT)
            local yDiff = floatY - cur.Y
            yVel = math.clamp(yDiff * FLOAT_PULL, 0, FLOAT_MAX_VEL) * ease
        end
        local horizMult = 1.0
        egoLv.VectorVelocity = V3(dir.X * (normalSpeed * LV_GOING_SPEED) * horizMult, yVel, dir.Z * (normalSpeed * LV_GOING_SPEED) * horizMult)
    end)
    while not allDone and egoPlaying do task.wait(0.01) end
    if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0)
        egoLv.MaxAxesForce = V3(50000, 0, 50000) end
end
local function egoGoGoing_MoveTo(waypoints)
    if not egoPlaying then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if egoLv then egoLv.Enabled = false; egoLv.VectorVelocity = V3(0,0,0) end
    local origWalkSpeed = hum.WalkSpeed
    hum.WalkSpeed = normalSpeed * LV_GOING_SPEED
    local wpIndex = 1
    local allDone = false
    local function refreshMoveTo()
        if wpIndex <= #waypoints then
            local wp = waypoints[wpIndex]
            hum:MoveTo(Vector3.new(wp.X, hrp.Position.Y, wp.Z))
        end
    end
    refreshMoveTo()
    local conn
    conn = RS.RenderStepped:Connect(function()
        if allDone or not egoPlaying then
            conn:Disconnect(); return
        end
        local c  = LocalPlayer.Character
        local rp = c and c:FindFirstChild("HumanoidRootPart")
        local h  = c and c:FindFirstChildOfClass("Humanoid")
        if not rp or not h then allDone = true; conn:Disconnect(); return end
        while wpIndex <= #waypoints do
            local wp  = waypoints[wpIndex]
            local rem = Vector3.new(wp.X - rp.Position.X, 0, wp.Z - rp.Position.Z).Magnitude
            if rem > LV_ARRIVE_GOING then break end
            wpIndex = wpIndex + 1
            if wpIndex <= #waypoints then
                local nwp = waypoints[wpIndex]
                h:MoveTo(Vector3.new(nwp.X, rp.Position.Y, nwp.Z))
            end
        end
        if wpIndex > #waypoints then
            allDone = true; conn:Disconnect(); return
        end
        local wp  = waypoints[wpIndex]
        local dir = Vector3.new(wp.X - rp.Position.X, 0, wp.Z - rp.Position.Z)
        if dir.Magnitude > 0.1 then
            dir = dir.Unit
            rp.CFrame = rp.CFrame + dir * (normalSpeed * LV_GOING_SPEED * 0.070)
        end
        if dir.Magnitude > 0.1 then
            local tAngle = math.atan2(-dir.X, -dir.Z)
            local _, cAngle, _ = rp.CFrame:ToEulerAnglesYXZ()
            local delta = ((tAngle - cAngle + math.pi) % (2 * math.pi)) - math.pi
            rp.CFrame = CFrame.new(rp.Position) * CFrame.Angles(0, cAngle + delta * LV_FACE_SMOOTH, 0)
        end
    end)
    while not allDone and egoPlaying do task.wait(0.01) end
    conn:Disconnect()
    hum.WalkSpeed = origWalkSpeed
    hum:Move(Vector3.new(0,0,0))
end
local function egoGoTo_LV(target, _, isStealLeg)
    if isStealLeg then
        egoGoTo_LV_return(target)
    else
        egoGoGoing({target}, nil)
    end
end
local function egoRunLoop(side)
    local goingWP  = side == "left" and EGO_LEFT_GOING  or EGO_RIGHT_GOING
    local returnWP = side == "left" and EGO_LEFT_RETURN or EGO_RIGHT_RETURN
    egoSetupLV()
    while egoPlaying do
        egoIsReturning          = false
        egoReturnedToFirstPoint = false
        local floatY = autoPlayFloatEnabled and -3 or nil
        if egoPlaying then
            egoGoGoing(goingWP, floatY)
        end
        if not egoPlaying then egoCleanupLV(); return end
        task.wait(LAND_WAIT)
        if not egoPlaying then egoCleanupLV(); return end
        task.wait(autoPlayCd)
        egoIsReturning          = true
        egoReturnedToFirstPoint = false
        for i, wp in ipairs(returnWP) do
            if not egoPlaying then egoCleanupLV(); return end
            egoGoTo_LV_return(wp)
            if i == 1 then egoReturnedToFirstPoint = true end
        end
        egoIsReturning = false
        local loopWaitEnd = tick() + 3
        while tick() < loopWaitEnd do
            if not egoPlaying then egoCleanupLV(); return end
            task.wait(0.05)
        end
    end
    egoIsReturning          = false
    egoReturnedToFirstPoint = false
    egoCleanupLV()
end
local function egoStart()
    egoPlaying = true
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = false end
    task.spawn(function()
        local side = egoDetectSide()
        egoRunLoop(side)
    end)
end
local function egoStop()
    egoPlaying = false
    egoMoving  = false
    egoIsReturning          = false
    egoReturnedToFirstPoint = false
    egoCancelTween()
    egoCleanupLV()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity  = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
    end
end
task.spawn(function()
    local wasVisible   = false
    local timerRunning = false
    while true do
        RS.Heartbeat:Wait()
        local nowVisible = egoDuelsMachineVisible()
        if nowVisible and not wasVisible then
            if lockActive then stopLock() end
            if not timerRunning then
                timerRunning = true
                lockCdBlocked = true
                task.spawn(function()
                    task.wait(5)
                    lockCdBlocked = false
                    timerRunning = false
                    local miniIsNowOn = lockMiniButtonInstance
                        and lockMiniButtonInstance.gui.Enabled
                        and library.Flags["LockMini"]
                    if miniIsNowOn and not lockActive then
                        pcall(function() lockMiniButtonInstance:SetState(true) end)
                        lockActive = true
                        startLock()
                    end
                end)
            end
        end
        wasVisible = nowVisible
    end
end)
task.spawn(function()
    local wasVisible   = false
    local timerRunning = false
    while true do
        RS.Heartbeat:Wait()
        local nowVisible = egoDuelsMachineVisible()
        if nowVisible and not wasVisible then
            if egoPlaying then egoStop() end
            if not timerRunning then
                timerRunning = true
                egoTimerBlocked = true
                egoStartMoveLock()
                task.spawn(function()
                    task.wait(4.9)
                    egoTimerBlocked = false
                    egoStopMoveLock()
                    timerRunning = false
                    local miniIsNowOn = egoMiniButtonInstance
                        and egoMiniButtonInstance.gui.Enabled
                        and library.Flags["AutoPlayMini"]
                    if miniIsNowOn and not egoPlaying then
                        pcall(function() egoMiniButtonInstance:SetState(true) end)
                        egoStart()
                    end
                end)
            end
        end
        wasVisible = nowVisible
    end
end)
mainTab:CreateToggle({
    Name         = "AutoPlay",
    CurrentValue = false,
    Flag         = "AutoPlayToggle",
    Callback     = function(state)
        if state then
            if not egoMiniButtonInstance then
                egoMiniButtonInstance = win:CreateMiniButton({
                    Flag         = "AutoPlayMini",
                    Label        = "AutoPlay",
                    CurrentValue = false,
                    Callback     = function(miniState)
                        if miniState then
                            if egoTimerBlocked then return end
                            egoStart()
                        else
                            egoStop()
                        end
                    end
                })
            end
            egoMiniButtonInstance.gui.Enabled = true
        else
            egoPlaying = false
            egoMoving  = false
            egoIsReturning = false
            egoReturnedToFirstPoint = false
            egoCancelTween()
            egoCleanupLV()
            local _char = LocalPlayer.Character
            local _hrp  = _char and _char:FindFirstChild("HumanoidRootPart")
            if _hrp then
                _hrp.AssemblyLinearVelocity  = Vector3.new(0, _hrp.AssemblyLinearVelocity.Y, 0)
                _hrp.AssemblyAngularVelocity = Vector3.zero
            end
            local _hum = _char and _char:FindFirstChildOfClass("Humanoid")
            if _hum then
                _hum.AutoRotate = true
                _hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            end
            if egoMiniButtonInstance then
                egoMiniButtonInstance.gui.Enabled = false
                pcall(function() egoMiniButtonInstance:SetState(false) end)
            end
        end
    end
})
local localTab = win:CreateTab("Local")
local fovBoostEnabled = false
local defaultFOV = 70
local boostedFOV = 110
localTab:CreateToggle({
	Name         = "FOV Boost",
	CurrentValue = false,
	Flag         = "FovBoostToggle",
	Callback     = function(state)
		fovBoostEnabled = state
		local cam = workspace.CurrentCamera
		if not cam then return end
		if state then
			cam.FieldOfView = boostedFOV
		else
			cam.FieldOfView = defaultFOV
		end
	end
})
local infiniteJumpEnabled = false
local UIS = game:GetService("UserInputService")
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return end
    hrp.AssemblyLinearVelocity = Vector3.new(
        hrp.AssemblyLinearVelocity.X,
        50,
        hrp.AssemblyLinearVelocity.Z
    )
end)
localTab:CreateToggle({
    Name = "Inf Jump",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(state)
        infiniteJumpEnabled = state
    end
})
local applySpeedEnabled = false
localTab:CreateSection("Speed")
localTab:CreateSlider({
    Name         = "Normal Speed",
    Flag         = "NormalSpeedSlider",
    CurrentValue = 55,
    Min          = 1,
    Max          = 64,
    Increment    = 1,
    Callback     = function(val)
        normalSpeed = val
    end
})
localTab:CreateSlider({
    Name         = "Steal Speed",
    Flag         = "StealSpeedSlider",
    CurrentValue = 24,
    Min          = 1,
    Max          = 34,
    Increment    = 1,
    Callback     = function(val)
        stealSpeed = val
    end
})
task.spawn(function()
    task.wait(0.5)
    local sn = tonumber(library.Flags["NormalSpeedSlider"])
    if sn and sn >= 1 and sn <= 60 then normalSpeed = sn end
    local ss = tonumber(library.Flags["StealSpeedSlider"])
    if ss and ss >= 1 and ss <= 30 then stealSpeed = ss end
end)
local stealLvAtt = nil
local stealLv    = nil
local function createStealLV()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if stealLv    then pcall(function() stealLv:Destroy()    end); stealLv    = nil end
    if stealLvAtt then pcall(function() stealLvAtt:Destroy() end); stealLvAtt = nil end
    stealLvAtt        = IN("Attachment")
    stealLvAtt.Parent = hrp
    stealLv            = IN("LinearVelocity")
    stealLv.Parent     = hrp
    stealLv.Attachment0 = stealLvAtt
    stealLv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    stealLv.MaxAxesForce   = V3(50000, 0, 50000)
    stealLv.RelativeTo = Enum.ActuatorRelativeTo.World
    stealLv.Enabled    = false
end
local function destroyStealLV()
    if stealLv    then pcall(function() stealLv:Destroy()    end); stealLv    = nil end
    if stealLvAtt then pcall(function() stealLvAtt:Destroy() end); stealLvAtt = nil end
end
local speedConnection = nil
local function startSpeedConnection()
    if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
    createStealLV()
    speedConnection = RS.PreSimulation:Connect(function(deltaTime)
        if not applySpeedEnabled then return end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then
                if stealLv then stealLv.Enabled = false end
                return
            end
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics
            or humState == Enum.HumanoidStateType.Ragdoll
            or hum.PlatformStand == true then
                if stealLv then stealLv.Enabled = false end
                return
            end
            local md = hum.MoveDirection
            if md.Magnitude == 0 then
                if stealLv then stealLv.Enabled = false end
                return
            end
            if egoTimerBlocked then
                if stealLv then stealLv.Enabled = false end
                return
            end
            if egoPlaying then
                if stealLv then stealLv.Enabled = false end
                return
            end
            if hum.WalkSpeed < 25 then
                if stealLv then stealLv.Enabled = false end
                local fpsScale = deltaTime * 60
                local baseFactor = (stealSpeed * 0.0058) * fpsScale
                local targetCF = hrp.CFrame + (md.Unit * baseFactor)
                hrp.CFrame = CFrame.new(
                    Vector3.new(hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z):Lerp(
                        Vector3.new(targetCF.X, hrp.CFrame.Y, targetCF.Z), 0.35
                    )
                ) * (hrp.CFrame - hrp.CFrame.Position)
                local hv = md.Unit * (baseFactor / deltaTime)
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X + hv.X * 0.015,
                    hrp.AssemblyLinearVelocity.Y,
                    hrp.AssemblyLinearVelocity.Z + hv.Z * 0.015
                )
                return
            end
            if stealLv then stealLv.Enabled = false end
            local currentYVelocity = hrp.AssemblyLinearVelocity.Y
            local fpsScale = deltaTime * 60
            local baseFactor = ((normalSpeed * 0.85) * 0.0125) * fpsScale
            local targetCF = hrp.CFrame + (md.Unit * baseFactor)
            hrp.CFrame = CFrame.new(
                Vector3.new(hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z):Lerp(
                    Vector3.new(targetCF.X, hrp.CFrame.Y, targetCF.Z), 0.35
                )
            ) * (hrp.CFrame - hrp.CFrame.Position)
            local hv = md.Unit * (baseFactor / deltaTime)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X + hv.X * 0.015,
                currentYVelocity,
                hrp.AssemblyLinearVelocity.Z + hv.Z * 0.015
            )
        end)
    end)
end
localTab:CreateToggle({
    Name         = "Apply Speed",
    CurrentValue = false,
    Flag         = "ApplySpeedToggle",
    Callback     = function(state)
        applySpeedEnabled = state
        if state then
            startSpeedConnection()
        else
            if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
            destroyStealLV()
        end
    end
})
local tpDownMiniButton = nil
local function doTPDown()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if char and hrp then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), params)
        if ray then
            char:PivotTo(CFrame.new(ray.Position + Vector3.new(0, 3, 0)))
        else
            char:PivotTo(hrp.CFrame * CFrame.new(0, -20, 0))
        end
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end
localTab:CreateToggle({
    Name         = "TpDown",
    CurrentValue = false,
    Flag         = "TpDownToggle",
    Callback     = function(state)
        if state then
            if not tpDownMiniButton then
                tpDownMiniButton = win:CreateMiniActionButton({
                    Flag     = "TpDownMini",
                    Label    = "TpDown",
                    Callback = function()
                        doTPDown()
                    end
                })
            end
            tpDownMiniButton.gui.Enabled = true
        else
            if tpDownMiniButton then
                tpDownMiniButton.gui.Enabled = false
            end
        end
    end
})
local autoTpDownEnabled = false
local autoTpDownYAxis   = 12
local autoTpDownConn    = nil
local function startAutoTpDown()
    if autoTpDownConn then autoTpDownConn:Disconnect() end
    autoTpDownConn = RS.Heartbeat:Connect(function()
        if not autoTpDownEnabled then return end
        if lockActive then return end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), params)
        if not ray then return end
        local heightAboveGround = hrp.Position.Y - ray.Position.Y
        if heightAboveGround > autoTpDownYAxis then
            doTPDown()
        end
    end)
end
local function stopAutoTpDown()
    autoTpDownEnabled = false
    if autoTpDownConn then autoTpDownConn:Disconnect(); autoTpDownConn = nil end
end
localTab:CreateToggle({
    Name         = "Auto TpDown",
    CurrentValue = false,
    Flag         = "AutoTpDownToggle",
    Callback     = function(state)
        autoTpDownEnabled = state
        if state then
            startAutoTpDown()
        else
            stopAutoTpDown()
        end
    end
})
localTab:CreateToggle({
    Name         = "Medusa Counter",
    CurrentValue = false,
    Flag         = "MedusaCounterToggle",
    Callback     = function(state)
        medusaCounterEnabled = state
        if state then
            if LocalPlayer.Character then
                task.spawn(function() hookMedusaCharacter(LocalPlayer.Character) end)
            end
            if medusaCharConn then medusaCharConn:Disconnect() end
            medusaCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                if medusaCounterEnabled then
                    hookMedusaCharacter(char)
                end
            end)
        else
            for _, c in ipairs(medusaConnections) do pcall(function() c:Disconnect() end) end
            table.clear(medusaConnections)
            if medusaCharConn then medusaCharConn:Disconnect(); medusaCharConn = nil end
        end
    end
})
local function applyOtherPlayerNoCollision()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local pc = plr.Character
            if pc then
                local folder = workspace:FindFirstChild("KnoxNoCollisionFolder")
                if not folder then
                    folder = Instance.new("Folder")
                    folder.Name = "KnoxNoCollisionFolder"
                    folder.Parent = workspace
                end
                for _, part in ipairs(pc:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end
task.spawn(function()
    while true do
        applyOtherPlayerNoCollision()
        task.wait(0.5)
    end
end)
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        applyOtherPlayerNoCollision()
    end)
end)
local visualTab = win:CreateTab("Visuals")
local espEnabled = false
local espConnections = {}
local espBillboards = {}
local function removeESP(player)
    if espBillboards[player] then
        pcall(function() espBillboards[player]:Destroy() end)
        espBillboards[player] = nil
    end
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
end
local function createESP(player)
    if player == LocalPlayer then return end
    if not espEnabled then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    removeESP(player)
    local bb = Instance.new("BillboardGui")
    bb.Name = "KnoxESP"
    bb.Adornee = hrp
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 999999
    bb.LightInfluence = 0
    bb.Parent = hrp
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = player.Name
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    espBillboards[player] = bb
    espConnections[player] = RS.RenderStepped:Connect(function()
        if not espEnabled then
            removeESP(player)
            return
        end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            removeESP(player)
            return
        end
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            local dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
            lbl.Text = player.Name .. "\n[" .. dist .. "m]"
        end
    end)
end
local function enableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function() createESP(player) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled then pcall(function() createESP(p) end) end
        end)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if espEnabled then pcall(function() createESP(player) end) end
            end)
        end
    end
end
local function disableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end
end
visualTab:CreateToggle({
    Name = "Esp Player",
    CurrentValue = false,
    Flag = "EspPlayerToggle",
    Callback = function(state)
        espEnabled = state
        if state then
            enableESP()
        else
            disableESP()
        end
    end
})
local function applyAntiLag()
    local myChar = LocalPlayer.Character
    local function isInMyChar(obj)
        if not myChar then return false end
        local cur = obj
        while cur do
            if cur == myChar then return true end
            cur = cur.Parent
        end
        return false
    end
    local descendants = workspace:GetDescendants()
    for _, obj in ipairs(descendants) do
        if isInMyChar(obj) then continue end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Material   = Enum.Material.Plastic
                obj.CastShadow = false
            end)
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
            or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") then
            pcall(function() obj.Enabled = false end)
        elseif obj:IsA("Humanoid") or obj:IsA("AnimationController") then
            local animator = obj:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function() track:Stop(0); track:Destroy() end)
                end
            end
        end
    end
    pcall(function()
        workspace.StreamingMinRadius    = 64
        workspace.StreamingTargetRadius = 2048
    end)
end
visualTab:CreateToggle({
    Name         = "Anti Lag",
    CurrentValue = false,
    Flag         = "AntiLagToggle",
    Callback     = function(state)
        if state then
            applyAntiLag()
        end
    end
})
local settingsTab = win:CreateTab("Settings")
settingsTab:CreateSection("Auto Play")
settingsTab:CreateInput({
    Name        = "AutoPlayCd",
    Flag        = "AutoPlayCdInput",
    Default     = "0.4",
    Placeholder = "e.g. 0.4",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n >= 0 and n <= 10 then
            autoPlayCd = n
        end
    end
})
do
    local saved = tonumber(library.Flags["AutoPlayCdInput"])
    if saved then autoPlayCd = saved end
end

settingsTab:CreateToggle({
    Name         = "AutoPlay Float",
    CurrentValue = true,
    Flag         = "AutoPlayFloatToggle",
    Callback     = function(state)
        autoPlayFloatEnabled = state
    end
})
do
    local saved = library.Flags["AutoPlayFloatToggle"]
    if saved ~= nil then autoPlayFloatEnabled = saved end
end
settingsTab:CreateSection("Auto Medusa")
settingsTab:CreateInput({
    Name        = "AutoMedusaRange",
    Flag        = "AutoMedusaRangeInput",
    Default     = "5",
    Placeholder = "e.g. 5",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n > 0 and n <= 100 then
            autoMedusaRange = n
        end
    end
})
do
    local saved = tonumber(library.Flags["AutoMedusaRangeInput"])
    if saved and saved > 0 and saved <= 100 then autoMedusaRange = saved end
end
settingsTab:CreateSection("Auto Grab")
settingsTab:CreateInput({
    Name        = "Grab Radius",
    Flag        = "GrabRadiusInput",
    Default     = "8",
    Placeholder = "e.g. 8",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n > 0 and n <= 200 then
            agGrabRadius = n
        end
    end
})
do
    local saved = tonumber(library.Flags["GrabRadiusInput"])
    if saved and saved > 0 and saved <= 200 then agGrabRadius = saved end
end
settingsTab:CreateSection("Auto TpDown")
settingsTab:CreateInput({
    Name        = "TpDownYAxis",
    Flag        = "TpDownYAxisInput",
    Default     = "12",
    Placeholder = "e.g. 12",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n > 0 and n <= 500 then
            autoTpDownYAxis = n
        end
    end
})
do
    local saved = tonumber(library.Flags["TpDownYAxisInput"])
    if saved and saved > 0 and saved <= 500 then autoTpDownYAxis = saved end
end
settingsTab:CreateSection("Lock")
settingsTab:CreateInput({
    Name        = "Lock Radius",
    Flag        = "LockRadiusInput",
    Default     = "250",
    Placeholder = "e.g. 40",
    Callback    = function(val)
        local n = tonumber(val)
        if n and n > 0 and n <= 9999 then
            LOCK_RADIUS = n
        end
    end
})
do
    local saved = tonumber(library.Flags["LockRadiusInput"])
    if saved and saved > 0 and saved <= 9999 then LOCK_RADIUS = saved end
end
