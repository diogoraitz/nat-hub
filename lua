-- ================================================
--   NOOB ARMY TYCOON | Attack Hub v7
--   GitHub Raw — use o loadstring do arquivo LOADER.lua
-- ================================================
--[[
  loadstring(game:HttpGet("https://raw.githubusercontent.com/omgimanidiot/No-barmytycoonscript/refs/heads/main/lua", true))()
  Troque USER/REPO pelo seu GitHub apos o upload.
]]

local VERSION = "v7.1"
local ZERO = Vector3.new(0, 0, 0)

-- ─── Erro visível (se o script falhar) ───────────────
local function showError(msg)
    local text = "[NAT " .. VERSION .. "] " .. tostring(msg)
    warn(text)
    print(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "NAT — Erro no script",
            Text = tostring(msg):sub(1, 180),
            Duration = 12,
        })
    end)
end

local function notifyLoaded()
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "NAT " .. VERSION,
            Text = "Hub carregado! Procure a janela Rayfield.",
            Duration = 6,
        })
    end)
end

print("[NAT " .. VERSION .. "] Iniciando...")

local Players_boot = game:GetService("Players")
if not Players_boot.LocalPlayer then
    print("[NAT] Aguardando LocalPlayer...")
    Players_boot.PlayerAdded:Wait()
    task.wait(0.5)
end

-- ─── Cleanup previous GUIs ───────────────────────────
local function cleanupOldGui()
    local lp = Players_boot.LocalPlayer
    if not lp then return end
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        local n = gui.Name or ""
        if n == "Rayfield" or n:find("Rayfield") or n == "NATHub" or n:find("NAT") then
            pcall(function() gui:Destroy() end)
        end
    end
end
cleanupOldGui()
task.wait(0.15)

-- ─── Carregar Rayfield (várias URLs) ─────────────────
local function loadRayfield()
    local urls = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/shlexware/Sirius/refs/heads/master/source.lua",
    }
    for _, url in ipairs(urls) do
        local ok, lib = pcall(function()
            local body = game:HttpGet(url, true)
            if type(body) ~= "string" or #body < 300 then
                error("resposta vazia ou bloqueada")
            end
            local fn = loadstring(body)
            if not fn then error("loadstring invalido") end
            local result = fn()
            if type(result) ~= "table" or not result.CreateWindow then
                error("nao e Rayfield")
            end
            return result
        end)
        if ok and lib then
            print("[NAT] Rayfield OK:", url)
            return lib
        end
        warn("[NAT] Falhou URL:", url, lib)
    end
    return nil
end

local Rayfield = loadRayfield()
local UseFallbackUI = false

local function safeNotify(opts)
    pcall(function()
        if Rayfield and Rayfield.Notify then Rayfield:Notify(opts) end
    end)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = opts.Title or "NAT",
            Text = (opts.Content or ""):sub(1, 200),
            Duration = opts.Duration or 5,
        })
    end)
end

if not Rayfield then
    warn("[NAT] Rayfield falhou — usando menu simples embutido.")
    UseFallbackUI = true
end

-- ─── Services ────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ─── Remotes (discovered + cached) ───────────────────
local Remotes = {
    Game = nil, AllTarget = nil, BuyList = {},
    Redeem = nil, Treasure = nil, Computer = nil, Flower = nil,
}

local function discoverRemotes()
    Remotes.BuyList = {}
    Remotes.Redeem, Remotes.Treasure, Remotes.Computer, Remotes.Flower = nil, nil, nil, nil

    local ok, folder = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("Game", 15)
    end)
    if ok and folder then
        Remotes.Game = folder
        Remotes.AllTarget = folder:FindFirstChild("AllTargetPosition")
            or folder:FindFirstChild("AllTarget")
            or folder:FindFirstChild("TargetPosition")

        for _, child in ipairs(folder:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local n = child.Name:lower()
                if n:find("redeem") or n:find("code") then Remotes.Redeem = Remotes.Redeem or child end
                if n:find("treasure") or n:find("chest") then Remotes.Treasure = Remotes.Treasure or child end
                if n:find("computer") or n:find("pc") or n:find("monitor") then
                    Remotes.Computer = Remotes.Computer or child
                end
                if n:find("flower") or n:find("collect") then Remotes.Flower = Remotes.Flower or child end
                if n:find("buy") or n:find("purchase") or n:find("upgrade")
                    or n:find("tycoon") or n:find("build") or n:find("click")
                    or n:find("button") or n:find("item") or n:find("unlock") then
                    table.insert(Remotes.BuyList, child)
                end
            end
        end
        for _, name in ipairs({ "Buy", "Purchase", "BuyButton", "Upgrade", "UpgradeButton", "TycoonBuy", "ClickButton" }) do
            local r = folder:FindFirstChild(name, true)
            if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                local found = false
                for _, x in ipairs(Remotes.BuyList) do if x == r then found = true break end end
                if not found then table.insert(Remotes.BuyList, r) end
            end
        end
    end

    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local n = desc.Name:lower()
            local p = desc.Parent and desc.Parent.Name:lower() or ""
            if not Remotes.Redeem and (n:find("redeem") or n == "code") then Remotes.Redeem = desc end
            if not Remotes.Treasure and n:find("treasure") then Remotes.Treasure = desc end
            if not Remotes.Flower and n:find("flower") then Remotes.Flower = desc end
            if p:find("open") and n:find("capsule") then Remotes.Treasure = Remotes.Treasure or desc end
        end
    end

    table.sort(Remotes.BuyList, function(a, b) return a.Name < b.Name end)
    if Remotes.AllTarget then
        print("[NAT " .. VERSION .. "] Attack:", Remotes.AllTarget:GetFullName())
    end
    print("[NAT " .. VERSION .. "] Buy remotes:", #Remotes.BuyList,
        "| Redeem:", Remotes.Redeem ~= nil, "| Flower:", Remotes.Flower ~= nil)
end
discoverRemotes()

-- ─── Point lists ─────────────────────────────────────
local ALL_POINTS = {
    "Center",
    "Front A", "Front B", "Front C", "Front D",
    "Front E", "Front F", "Front G", "Front H",
    "Ground A", "Ground B", "Ground C", "Ground D",
    "Ground E", "Ground F", "Ground G", "Ground H",
    "Boat Point A", "Boat Point B", "Boat Point C", "Boat Point D",
    "Boat Point E", "Boat Point F", "Boat Point G", "Boat Point H",
}

local BOAT_POINTS = {
    "Boat Point A", "Boat Point B", "Boat Point C", "Boat Point D",
    "Boat Point E", "Boat Point F", "Boat Point G", "Boat Point H",
}

local FRONT_POINTS = {
    "Front A", "Front B", "Front C", "Front D",
    "Front E", "Front F", "Front G", "Front H",
}

local GROUND_POINTS = {
    "Ground A", "Ground B", "Ground C", "Ground D",
    "Ground E", "Ground F", "Ground G", "Ground H",
}

local SQUADS = { "A", "B", "C", "D", "E", "F" }
local BOAT_SQUADS = { "E", "F", "A", "B", "C", "D" } -- prefer E/F for boats

-- ─── Settings ────────────────────────────────────────
local function buildDefaultAssignment()
    local assignment = {}
    for _, squad in ipairs(SQUADS) do
        assignment[squad] = {}
    end
    for i, point in ipairs(ALL_POINTS) do
        local squad = SQUADS[((i - 1) % #SQUADS) + 1]
        table.insert(assignment[squad], point)
    end
    return assignment
end

local S = {
    AutoAttack       = false,
    HoldTime         = 1,
    LoopAll          = true,
    ReinforceEvery   = 30,
    Assignment       = buildDefaultAssignment(),
    ActiveSquads     = { A = true, B = true, C = true, D = true, E = true, F = true },

    -- Smart capture
    SmartBoatAttack   = false,
    SmartGroundAttack = false,
    BoatScanInterval  = 8,
    GroundScanInterval = 10,
    AttackNeutral     = true,
    BoatSquadRotate   = true,

    -- Auto upgrade / farm
    AutoUpgrade       = false,
    AutoBuy           = true,
    AutoComputer      = false,
    AutoCollectFlower = false,
    AutoRedeemCodes   = false,
    AutoOpenTreasure  = false,
    MasterAFK         = false,
    UpgradeInterval   = 3,
    UpgradeMonitors   = true,
    UpgradePCs        = true,
    UpgradeBuildings  = true,
    UseProximityBuy   = true,

    -- Movement / misc
    WalkSpeed        = 16,
    FlyEnabled       = false,
    FlySpeed         = 60,
    InfiniteJump     = false,
    Noclip           = false,
    AntiAFK          = false,
    GodMode          = false,
}

-- ─── State ───────────────────────────────────────────
local squadStatus = {}
for _, sq in ipairs(SQUADS) do squadStatus[sq] = "Idle" end

local squadThreads = {}
local backgroundThreads = {}
local connections = {}
local lastSquadFire = {}
local boatSquadIndex = 1
local captureCache = {}
local captureCacheTime = 0

local function trackThread(name, thread)
    backgroundThreads[name] = thread
end

local function stopThread(name)
    local t = backgroundThreads[name]
    if t then
        pcall(task.cancel, t)
        backgroundThreads[name] = nil
    end
end

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(connections, c)
    return c
end

local function setSquadStatus(squad, msg)
    squadStatus[squad] = msg
end

-- ─── Rate-limited remote fire ────────────────────────
local MIN_FIRE_GAP = 0.12

local function sendSquad(point, squad)
    if not Remotes.AllTarget then return false end
    local key = squad .. "|" .. point
    local now = tick()
    if lastSquadFire[key] and (now - lastSquadFire[key]) < MIN_FIRE_GAP then
        return false
    end
    lastSquadFire[key] = now
    local ok = pcall(function()
        Remotes.AllTarget:FireServer(point, squad)
    end)
    return ok
end

-- ─── Capture point ownership ─────────────────────────
local OWNER_ATTRS = {
    "Owner", "Team", "CapturedBy", "Controller",
    "OwningTeam", "Player", "CaptureTeam", "HeldBy",
}

local function namesMatch(a, b)
    if not a or not b then return false end
    return tostring(a):lower() == tostring(b):lower()
end

local function isLocalOwner(value)
    if value == nil then return false end
    local s = tostring(value):lower()
    if s == "" or s == "neutral" or s == "none" or s == "0" then return false end
    if namesMatch(value, LocalPlayer.Name) then return true end
    if namesMatch(value, LocalPlayer.UserId) then return true end
    if LocalPlayer.Team and namesMatch(value, LocalPlayer.Team.Name) then return true end
    if LocalPlayer:GetAttribute("Team") and namesMatch(value, LocalPlayer:GetAttribute("Team")) then
        return true
    end
    return false
end

local function readOwnershipFromInstance(inst)
    for _, attr in ipairs(OWNER_ATTRS) do
        local v = inst:GetAttribute(attr)
        if v ~= nil then
            if isLocalOwner(v) then return true end
            local s = tostring(v):lower()
            if s ~= "" and s ~= "neutral" and s ~= "none" then return false end
        end
    end
    for _, child in ipairs(inst:GetDescendants()) do
        if child:IsA("StringValue") or child:IsA("ObjectValue") then
            local n = child.Name:lower()
            if n:find("owner") or n:find("team") or n:find("captur") then
                local val = child.Value
                local isPlayer = false
                pcall(function() isPlayer = val:IsA("Player") end)
                if isPlayer then
                    return val == LocalPlayer
                end
                if isLocalOwner(val) then return true end
                if val and tostring(val) ~= "" then
                    local s = tostring(val):lower()
                    if s ~= "neutral" and s ~= "none" then return false end
                end
            end
        end
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local t = child.Text or ""
            if t:find(LocalPlayer.Name) then return true end
            if LocalPlayer.Team and t:find(LocalPlayer.Team.Name) then return true end
        end
    end
    return nil
end

local function findCaptureInstance(pointName)
    local short = pointName:gsub("Boat Point ", "Boat "):gsub("Point ", "")
    local names = { pointName, short, pointName:gsub(" ", ""), short:gsub(" ", "") }

    for _, rootName in ipairs({ "Map", "Game", "World", "CapturePoints", "Points", "Zones" }) do
        local root = Workspace:FindFirstChild(rootName)
        if not root then
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d.Name == rootName and (d:IsA("Folder") or d:IsA("Model")) then
                    root = d
                    break
                end
            end
        end
        if root and root ~= Workspace then
            for _, n in ipairs(names) do
                local found = root:FindFirstChild(n, true)
                if found and (found:IsA("BasePart") or found:IsA("Model") or found:IsA("Folder")) then
                    return found
                end
            end
        end
    end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc.Name == pointName or desc.Name == short then
            if desc:IsA("BasePart") or desc:IsA("Model") then
                return desc
            end
        end
    end
    return nil
end

local function isPointDominatedByLocal(pointName)
    local inst = findCaptureInstance(pointName)
    if not inst then return nil end
    local owned = readOwnershipFromInstance(inst)
    if owned ~= nil then return owned end
    local parent = inst.Parent
    while parent and parent ~= Workspace do
        owned = readOwnershipFromInstance(parent)
        if owned ~= nil then return owned end
        parent = parent.Parent
    end
    return nil
end

local function refreshCaptureCache()
    captureCache = {}
    for _, pt in ipairs(ALL_POINTS) do
        captureCache[pt] = isPointDominatedByLocal(pt)
    end
    captureCacheTime = tick()
end

local function isPointUnowned(pointName)
    if tick() - captureCacheTime > 5 then refreshCaptureCache() end
    local state = captureCache[pointName]
    if state == true then return false end
    if state == false then return true end
    return S.AttackNeutral
end

local function getUnownedBoatPoints()
    local list = {}
    for _, pt in ipairs(BOAT_POINTS) do
        if isPointUnowned(pt) then table.insert(list, pt) end
    end
    return list
end

local function getUnownedGroundPoints()
    local list = {}
    for _, pt in ipairs(GROUND_POINTS) do
        if isPointUnowned(pt) then table.insert(list, pt) end
    end
    if isPointUnowned("Center") then table.insert(list, 1, "Center") end
    return list
end

local function nextBoatSquad()
    for _ = 1, #BOAT_SQUADS do
        local sq = BOAT_SQUADS[boatSquadIndex]
        boatSquadIndex = (boatSquadIndex % #BOAT_SQUADS) + 1
        if S.ActiveSquads[sq] then return sq end
    end
    return nil
end

-- ─── Auto upgrade base (NAT: Workspace.Tycoons) ─────
local function getNAT_Tycoon()
    local folder = Workspace:FindFirstChild("Tycoons")
    if not folder then return nil end
    local pname = LocalPlayer.Name
    local plot = folder:FindFirstChild(pname .. " tycoon")
        or folder:FindFirstChild(pname .. " Tycoon")
        or folder:FindFirstChild(pname)
    if plot then return plot end
    for _, ch in ipairs(folder:GetChildren()) do
        if ch.Name:find(pname, 1, true) then return ch end
    end
    return nil
end

local function getPlayerPlot()
    local tycoon = getNAT_Tycoon()
    if tycoon then return tycoon end

    local keys = { LocalPlayer.Name, tostring(LocalPlayer.UserId) }
    local folderNames = { "Bases", "Base", "Plots", "Tycoons", "PlayerBases" }
    for _, fname in ipairs(folderNames) do
        local folder = Workspace:FindFirstChild(fname)
        if folder then
            for _, key in ipairs(keys) do
                local plot = folder:FindFirstChild(key)
                if plot then return plot end
            end
        end
    end
    return nil
end

local function tryTycoonButtonBuys(plot)
    if not plot then return 0 end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local n = 0
    local buyKeywords = { "button", "purchase", "buy", "upgrade", "unlock", "pad", "claim" }

    for _, desc in ipairs(plot:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            pcall(function()
                if fireclickdetector then
                    fireclickdetector(desc)
                    n = n + 1
                end
            end)
        end

        if desc:IsA("BasePart") then
            local nm = desc.Name:lower()
            local isBuy = false
            for _, kw in ipairs(buyKeywords) do
                if nm:find(kw) then isBuy = true break end
            end
            if not isBuy and desc.Parent then
                local pn = desc.Parent.Name:lower()
                for _, kw in ipairs(buyKeywords) do
                    if pn:find(kw) then isBuy = true break end
                end
            end
            if isBuy or desc:GetAttribute("Cost") or desc:GetAttribute("Price") then
                for _, remote in ipairs(Remotes.BuyList) do
                    pcall(function() remote:FireServer(desc) end)
                    pcall(function() remote:FireServer(desc.Parent) end)
                    pcall(function() remote:FireServer(desc.Name) end)
                end
                if hrp and firetouchinterest then
                    pcall(function()
                        firetouchinterest(desc, hrp, 0)
                        task.wait(0.03)
                        firetouchinterest(desc, hrp, 1)
                    end)
                    n = n + 1
                end
            end
        end

        if (desc:IsA("Model") or desc:IsA("Folder")) and desc.Parent and desc.Parent.Name == "Models" then
            for _, remote in ipairs(Remotes.BuyList) do
                pcall(function() remote:FireServer(desc) end)
                pcall(function() remote:FireServer(desc.Name) end)
            end
        end
    end

    local models = plot:FindFirstChild("Models") or plot:FindFirstChild("Buttons") or plot:FindFirstChild("Purchases")
    if models then
        for _, item in ipairs(models:GetChildren()) do
            for _, remote in ipairs(Remotes.BuyList) do
                pcall(function() remote:FireServer(item) end)
                pcall(function() remote:FireServer(item.Name) end)
            end
            n = n + 1
        end
    end
    return n
end

local function tryProximityBuys(plot)
    if not S.UseProximityBuy or not plot then return 0 end
    local count = 0
    local keywords = { "buy", "purchase", "upgrade", "unlock", "build", "place" }

    for _, obj in ipairs(plot:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local text = ((obj.ActionText or "") .. " " .. (obj.ObjectText or "")):lower()
            local match = false
            for _, kw in ipairs(keywords) do
                if text:find(kw) then match = true break end
            end
            if match then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(obj, 1)
                        count = count + 1
                    end
                end)
            end
        end
    end
    return count
end

local function tryRemoteBuys()
    local count = 0
    for _, remote in ipairs(Remotes.BuyList) do
        local n = remote.Name:lower()
        local skip = false
        if not S.UpgradeBuildings and (n:find("build") or n:find("tycoon")) then skip = true end
        if not S.UpgradeMonitors and n:find("monitor") then skip = true end
        if not S.UpgradePCs and (n:find("pc") or n:find("computer")) then skip = true end
        if skip then
            -- next remote
        else
        local argsList = {
            {},
            { true },
            { "Buy" },
            { LocalPlayer },
        }
        for _, args in ipairs(argsList) do
            local ok = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(args))
                else
                    remote:InvokeServer(unpack(args))
                end
            end)
            if ok then count = count + 1 end
        end
        end
    end
    return count
end

local function runAutoUpgrade()
    local plot = getPlayerPlot()
    if not plot then
        plot = getNAT_Tycoon()
    end
    local bought = 0
    bought = bought + tryProximityBuys(plot)
    bought = bought + tryTycoonButtonBuys(plot)
    bought = bought + tryRemoteBuys()
    return bought
end

-- ─── Squad attack threads ────────────────────────────
local function stopAllSquadThreads()
    S.AutoAttack = false
    for squad, thread in pairs(squadThreads) do
        if thread then pcall(task.cancel, thread) end
    end
    squadThreads = {}
    for _, sq in ipairs(SQUADS) do
        squadStatus[sq] = "Idle"
    end
end

local function startSquadThread(squad)
    if squadThreads[squad] then
        pcall(task.cancel, squadThreads[squad])
        squadThreads[squad] = nil
    end

    squadThreads[squad] = task.spawn(function()
        local points = S.Assignment[squad]
        if not points or #points == 0 then
            setSquadStatus(squad, "No points assigned")
            return
        end

        local pointIndex = 1
        while S.AutoAttack and S.ActiveSquads[squad] do
            local point = points[pointIndex]
            sendSquad(point, squad)
            setSquadStatus(squad, "Attacking → " .. point)

            local holdEnd = tick() + (S.HoldTime * 60)
            local lastReinforce = tick()

            while tick() < holdEnd and S.AutoAttack and S.ActiveSquads[squad] do
                local rem = math.max(0, holdEnd - tick())
                local m = math.floor(rem / 60)
                local sc = math.floor(rem % 60)
                setSquadStatus(squad, string.format("Holding %s — %d:%02d", point, m, sc))

                if tick() - lastReinforce >= S.ReinforceEvery then
                    sendSquad(point, squad)
                    lastReinforce = tick()
                end
                task.wait(1)
            end

            if not S.AutoAttack or not S.ActiveSquads[squad] then break end

            pointIndex = pointIndex + 1
            if pointIndex > #points then
                if S.LoopAll then
                    pointIndex = 1
                    setSquadStatus(squad, "Cycle restart")
                    task.wait(0.5)
                else
                    setSquadStatus(squad, "Done")
                    break
                end
            end
        end
        setSquadStatus(squad, "Idle")
        squadThreads[squad] = nil
    end)
end

local function startAllSquads()
    stopAllSquadThreads()
    S.AutoAttack = true
    for i, squad in ipairs(SQUADS) do
        if S.ActiveSquads[squad] then
            task.wait(0.08 * i)
            startSquadThread(squad)
        end
    end
end

-- ─── Smart boat loop ─────────────────────────────────
local function startSmartBoatLoop()
    stopThread("SmartBoat")
    if not S.SmartBoatAttack then return end

    trackThread("SmartBoat", task.spawn(function()
        while S.SmartBoatAttack do
            refreshCaptureCache()
            local targets = getUnownedBoatPoints()

            if #targets > 0 then
                for _, pt in ipairs(targets) do
                    if not S.SmartBoatAttack then break end
                    local sq = S.BoatSquadRotate and nextBoatSquad() or "E"
                    if sq then
                        sendSquad(pt, sq)
                        setSquadStatus(sq, "Boat → " .. pt)
                    end
                    task.wait(0.25)
                end
                Rayfield:Notify({
                    Title = "Boat Capture",
                    Content = #targets .. " unowned boat point(s) targeted",
                    Duration = 3,
                })
            end
            task.wait(S.BoatScanInterval)
        end
    end))
end

local NAT_CODES = {
    "AwesomeBirthday", "LukaBirthday", "NewSquads", "ProServers", "7x7FormationGrid",
    "quack", "meow", "read", "gift", "gift2", "2years", "free8000gems", "free3900gems",
    "buildingskins", "free1070gems", "1001gems", "free1kgems", "800gems", "750gems",
    "600gems", "350gems", "factory", "troop credits",
}

local redeemedCodes = {}

local function tryRedeemCodes()
    if not S.AutoRedeemCodes then return 0 end
    local remote = Remotes.Redeem
    if not remote then
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name:lower():find("redeem") then
                remote = d
                break
            end
        end
    end
    if not remote then return 0 end
    local n = 0
    for _, code in ipairs(NAT_CODES) do
        if not redeemedCodes[code] then
            local ok = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(code)
                else
                    remote:InvokeServer(code)
                end
            end)
            if ok then redeemedCodes[code] = true; n = n + 1 end
            task.wait(0.35)
        end
    end
    return n
end

local function tryCollectFlowers()
    if not S.AutoCollectFlower then return 0 end
    local plot = getPlayerPlot()
    if not plot then return 0 end
    local n = 0
    for _, obj in ipairs(plot:GetDescendants()) do
        local nm = obj.Name:lower()
        if nm:find("flower") and (obj:IsA("BasePart") or obj:IsA("Model")) then
            pcall(function()
                if firetouchinterest and LocalPlayer.Character then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        firetouchinterest(obj, hrp, 0)
                        task.wait()
                        firetouchinterest(obj, hrp, 1)
                        n = n + 1
                    end
                end
            end)
        end
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local t = ((obj.ActionText or "") .. (obj.ObjectText or "")):lower()
            if t:find("flower") or t:find("collect") or t:find("pick") then
                pcall(function()
                    if fireproximityprompt then fireproximityprompt(obj, 1); n = n + 1 end
                end)
            end
        end
    end
    if Remotes.Flower then
        pcall(function() Remotes.Flower:FireServer() end)
        n = n + 1
    end
    return n
end

local function tryUseComputer()
    if not S.AutoComputer then return 0 end
    local plot = getPlayerPlot()
    local n = 0
    if plot then
        for _, obj in ipairs(plot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local t = ((obj.ActionText or "") .. (obj.ObjectText or "")):lower()
                if t:find("computer") or t:find("monitor") or t:find("pc") or t:find("use") then
                    pcall(function()
                        if fireproximityprompt then fireproximityprompt(obj, 1); n = n + 1 end
                    end)
                end
            end
        end
    end
    if Remotes.Computer then
        pcall(function() Remotes.Computer:FireServer(true) end)
        pcall(function() Remotes.Computer:FireServer() end)
        n = n + 1
    end
    return n
end

local function tryOpenTreasure()
    if not S.AutoOpenTreasure then return 0 end
    if Remotes.Treasure then
        pcall(function() Remotes.Treasure:FireServer() end)
        return 1
    end
    return 0
end

local function startSmartGroundLoop()
    stopThread("SmartGround")
    if not S.SmartGroundAttack then return end
    trackThread("SmartGround", task.spawn(function()
        while S.SmartGroundAttack do
            refreshCaptureCache()
            for _, pt in ipairs(getUnownedGroundPoints()) do
                if not S.SmartGroundAttack then break end
                for _, sq in ipairs({ "A", "B", "C", "D" }) do
                    if S.ActiveSquads[sq] then sendSquad(pt, sq); break end
                end
                task.wait(0.3)
            end
            task.wait(S.GroundScanInterval)
        end
    end))
end

-- ─── Presets (ANTES do Master AFK — evita nil) ───────
local function applyEvenSplit()
    S.Assignment = buildDefaultAssignment()
    safeNotify({ Title = "Even Split", Content = "25 points across 6 squads.", Duration = 3 })
end

local function applyZoneSplit()
    S.Assignment = {
        A = { "Center", "Front A", "Front B", "Front C", "Front D" },
        B = { "Front E", "Front F", "Front G", "Front H" },
        C = { "Ground A", "Ground B", "Ground C", "Ground D" },
        D = { "Ground E", "Ground F", "Ground G", "Ground H" },
        E = { "Boat Point A", "Boat Point B", "Boat Point C", "Boat Point D" },
        F = { "Boat Point E", "Boat Point F", "Boat Point G", "Boat Point H" },
    }
    safeNotify({ Title = "Zone Split", Content = "A-B Front | C-D Ground | E-F Boat", Duration = 4 })
end

local function applyOnePointEach()
    for i, squad in ipairs(SQUADS) do
        S.Assignment[squad] = { ALL_POINTS[i] or ALL_POINTS[1] }
    end
    safeNotify({ Title = "1 Point Each", Content = "6 points held simultaneously.", Duration = 4 })
end

local function applyBoatFocus()
    S.Assignment = {
        A = { "Boat Point A", "Boat Point B" },
        B = { "Boat Point C", "Boat Point D" },
        C = { "Boat Point E", "Boat Point F" },
        D = { "Boat Point G", "Boat Point H" },
        E = { "Boat Point A", "Boat Point C", "Boat Point E", "Boat Point G" },
        F = { "Boat Point B", "Boat Point D", "Boat Point F", "Boat Point H" },
    }
    safeNotify({ Title = "Boat Focus", Content = "All squads prioritize boat points.", Duration = 4 })
end

local function burstAttackAllPoints()
    if not Remotes.AllTarget then return end
    task.spawn(function()
        for _, pt in ipairs(ALL_POINTS) do
            for _, sq in ipairs(SQUADS) do
                if S.ActiveSquads[sq] then
                    sendSquad(pt, sq)
                    task.wait(0.06)
                end
            end
        end
        safeNotify({ Title = "Burst Attack", Content = "Todos os esquadroes enviados!", Duration = 4 })
    end)
end

local function startAutoUpgradeLoop()
    stopThread("AutoUpgrade")
    if not S.AutoUpgrade and not S.MasterAFK then return end

    trackThread("AutoUpgrade", task.spawn(function()
        while S.AutoUpgrade or S.MasterAFK do
            if S.AutoBuy or S.AutoUpgrade then
                local n = runAutoUpgrade()
                if n > 0 then
                    print("[NAT] Tycoon buy attempts:", n)
                end
            end
            if S.AutoComputer then tryUseComputer() end
            if S.AutoCollectFlower then tryCollectFlowers() end
            if S.AutoOpenTreasure then tryOpenTreasure() end
            if S.MasterAFK or S.AutoRedeemCodes then tryRedeemCodes() end
            task.wait(S.UpgradeInterval)
        end
    end))
end

local function startMasterAFK(on)
    S.MasterAFK = on
    if on then
        discoverRemotes()
        applyZoneSplit()
        S.AutoAttack = true
        S.AutoUpgrade = true
        S.AutoBuy = true
        S.AutoRedeemCodes = true
        S.AutoComputer = true
        S.SmartBoatAttack = true
        S.SmartGroundAttack = true
        S.AntiAFK = true

        local tycoon = getNAT_Tycoon()
        if tycoon then
            print("[NAT] Tycoon encontrado:", tycoon:GetFullName())
        else
            warn("[NAT] Tycoon nao encontrado em Workspace.Tycoons")
        end

        tryRedeemCodes()
        burstAttackAllPoints()
        startAllSquads()
        startSmartBoatLoop()
        startSmartGroundLoop()
        startAutoUpgradeLoop()

        safeNotify({
            Title = "AFK Farm ON",
            Content = "Ataque + boat + chao + tycoon upgrade. Veja tropas se movendo.",
            Duration = 6,
        })
    else
        S.MasterAFK = false
        S.AutoAttack = false
        stopAllSquadThreads()
        S.SmartBoatAttack = false
        S.SmartGroundAttack = false
        S.AutoUpgrade = false
        stopThread("SmartBoat")
        stopThread("SmartGround")
        stopThread("AutoUpgrade")
        safeNotify({ Title = "AFK Farm OFF", Content = "Tudo desligado.", Duration = 3 })
    end
end

-- ─── Character helpers ───────────────────────────────
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ─── Fly (LinearVelocity + AlignOrientation) ─────────
local flyLV, flyAO, flyAtt

local flyBV, flyBG

local function enableFly()
    local hrp = getHRP()
    if not hrp then return end
    disableFly()

    local ok = pcall(function()
        flyAtt = Instance.new("Attachment")
        flyAtt.Name = "NATFlyAtt"
        flyAtt.Parent = hrp
        flyLV = Instance.new("LinearVelocity")
        flyLV.Name = "NATFlyLV"
        flyLV.Attachment0 = flyAtt
        flyLV.MaxForce = math.huge
        flyLV.RelativeTo = Enum.ActuatorRelativeTo.World
        flyLV.Parent = hrp
        flyAO = Instance.new("AlignOrientation")
        flyAO.Name = "NATFlyAO"
        flyAO.Attachment0 = flyAtt
        flyAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        flyAO.MaxTorque = math.huge
        flyAO.Parent = hrp
    end)

    if not ok then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "NATFlyBV"
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = ZERO
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "NATFlyBG"
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
    end
end

local function disableFly()
    local hrp = getHRP()
    if hrp then
        for _, n in ipairs({ "NATFlyLV", "NATFlyAO", "NATFlyAtt", "NATFlyBV", "NATFlyBG" }) do
            local o = hrp:FindFirstChild(n)
            if o then o:Destroy() end
        end
    end
    flyLV, flyAO, flyAtt, flyBV, flyBG = nil, nil, nil, nil, nil
end

connect(RunService.Heartbeat, function()
    if not S.FlyEnabled then return end
    local hrp = getHRP()
    if not hrp then return end

    local d = ZERO
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.new(0, 1, 0) end
    local vel = (d.Magnitude > 0 and d.Unit or ZERO) * S.FlySpeed

    if flyLV and flyAO then
        flyLV.VectorVelocity = vel
        flyAO.CFrame = Camera.CFrame
    elseif flyBV and flyBG then
        flyBV.Velocity = vel
        flyBG.CFrame = Camera.CFrame
    end
end)

connect(UserInputService.JumpRequest, function()
    if S.InfiniteJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

connect(RunService.Heartbeat, function()
    if S.GodMode then
        local h = getHum()
        if h then h.Health = h.MaxHealth end
    end
end)

local noclipConn
local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if not on then
        local c = LocalPlayer.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        return
    end
    noclipConn = connect(RunService.Stepped, function()
        local c = LocalPlayer.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

connect(LocalPlayer.Idled, function()
    if S.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

connect(LocalPlayer.CharacterAdded, function(char)
    task.wait(0.5)
    local h = char:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = S.WalkSpeed end
    if S.FlyEnabled then enableFly() end
    if S.Noclip then setNoclip(true) end
end)

-- ======================================================
--              FALLBACK UI (sem Rayfield)
-- ======================================================
local function buildFallbackUI()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("NATFallback")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "NATFallback"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 280)
    frame.Position = UDim2.new(0, 12, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(45, 90, 200)
    title.Text = "NAT " .. VERSION .. " (Simple)"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame

    local y, h = 44, 32
    local function addBtn(text, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -16, 0, h)
        b.Position = UDim2.new(0, 8, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.Parent = frame
        b.MouseButton1Click:Connect(fn)
        y = y + h + 6
    end

    addBtn("AFK FARM (tudo)", function() startMasterAFK(not S.MasterAFK) end)
    addBtn("Ataque paralelo", function()
        if S.AutoAttack then stopAllSquadThreads() else startAllSquads() end
    end)
    addBtn("Smart Boat", function()
        S.SmartBoatAttack = not S.SmartBoatAttack
        if S.SmartBoatAttack then startSmartBoatLoop() else stopThread("SmartBoat") end
    end)
    addBtn("Auto Upgrade", function()
        S.AutoUpgrade = not S.AutoUpgrade
        if S.AutoUpgrade then startAutoUpgradeLoop() else stopThread("AutoUpgrade") end
    end)
    addBtn("Resgatar codigos", function() tryRedeemCodes() end)
    addBtn("Fechar menu", function() sg:Destroy() end)

    notifyLoaded()
    print("[NAT] Fallback UI ativo.")
end

-- ======================================================
--                     RAYFIELD UI
-- ======================================================
if UseFallbackUI then
    buildFallbackUI()
    print("[NAT " .. VERSION .. "] Pronto (menu simples).")
    return
end

local ICON = 4483362458

local function createTab(window, title)
    local ok, tab = pcall(function()
        return window:CreateTab(title, ICON)
    end)
    if ok and tab then return tab end
    return window:CreateTab(title)
end

local function addNote(tab, text)
    if tab.CreateLabel then tab:CreateLabel(text) end
end

local uiOk, uiErr = pcall(function()

local Window = Rayfield:CreateWindow({
    Name = "Noob Army Tycoon | " .. VERSION,
    Icon = ICON,
    LoadingTitle = "NAT Attack Hub",
    LoadingSubtitle = "Carregando " .. VERSION .. "...",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "NATHub",
        FileName = "NATv6Config",
    },
    KeySystem = false,
})

-- TAB 0 — AFK FARM
local FarmTab = createTab(Window, "AFK Farm")
FarmTab:CreateSection("Modo completo (estilo RIP Hub)")
addNote(FarmTab, "Liga: ataque Zone Split + boat + chao + upgrade + anti-AFK + codigos.")
FarmTab:CreateToggle({
    Name = "MASTER AFK FARM",
    CurrentValue = false,
    Flag = "MasterAFK",
    Callback = function(v)
        local ok, err = pcall(function() startMasterAFK(v) end)
        if not ok then
            warn("[NAT] Master AFK erro:", err)
            showError("Master AFK: " .. tostring(err))
        end
    end,
})
FarmTab:CreateToggle({ Name = "Auto Redeem Codes", CurrentValue = false, Flag = "AutoRedeem",
    Callback = function(v) S.AutoRedeemCodes = v end })
FarmTab:CreateButton({ Name = "Redeem ALL codes now", Callback = function()
    discoverRemotes()
    local n = tryRedeemCodes()
    safeNotify({ Title = "Codes", Content = "Tentativas: " .. n, Duration = 4 })
end })
FarmTab:CreateToggle({ Name = "Auto Collect Flowers", CurrentValue = false, Flag = "AutoFlower",
    Callback = function(v) S.AutoCollectFlower = v end })
FarmTab:CreateToggle({ Name = "Auto Use Computer", CurrentValue = false, Flag = "AutoPC",
    Callback = function(v) S.AutoComputer = v end })
FarmTab:CreateToggle({ Name = "Auto Open Treasure", CurrentValue = false, Flag = "AutoTreasure",
    Callback = function(v) S.AutoOpenTreasure = v end })

-- TAB 1 — AUTO ATTACK
local AttackTab = createTab(Window, "Attack")
AttackTab:CreateSection("Parallel Attack")

local autoAttackToggle
autoAttackToggle = AttackTab:CreateToggle({
    Name = "Start Parallel Attack",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(v)
        if v then
            startAllSquads()
            Rayfield:Notify({ Title = "Squads launched", Content = "Parallel attack running.", Duration = 3 })
        else
            stopAllSquadThreads()
            Rayfield:Notify({ Title = "Stopped", Content = "All squad threads stopped.", Duration = 2 })
        end
    end,
})

AttackTab:CreateToggle({
    Name = "Loop Continuously",
    CurrentValue = S.LoopAll,
    Flag = "LoopAll",
    Callback = function(v) S.LoopAll = v end,
})

AttackTab:CreateSection("Timing")
AttackTab:CreateSlider({
    Name = "Hold Time Per Point",
    Range = { 1, 15 },
    Increment = 1,
    Suffix = " min",
    CurrentValue = S.HoldTime,
    Flag = "HoldTime",
    Callback = function(v) S.HoldTime = v end,
})
AttackTab:CreateSlider({
    Name = "Reinforce Every",
    Range = { 5, 120 },
    Increment = 5,
    Suffix = " sec",
    CurrentValue = S.ReinforceEvery,
    Flag = "ReinforceEvery",
    Callback = function(v) S.ReinforceEvery = v end,
})

AttackTab:CreateSection("Presets")
AttackTab:CreateButton({ Name = "Even Split (default)", Callback = function()
    applyEvenSplit()
    if S.AutoAttack then startAllSquads() end
end })
AttackTab:CreateButton({ Name = "Zone Split (Front / Ground / Boat)", Callback = function()
    applyZoneSplit()
    if S.AutoAttack then startAllSquads() end
end })
AttackTab:CreateButton({ Name = "1 Point Each (fastest)", Callback = function()
    applyOnePointEach()
    if S.AutoAttack then startAllSquads() end
end })
AttackTab:CreateButton({ Name = "Boat Focus (all squads → boats)", Callback = function()
    applyBoatFocus()
    if S.AutoAttack then startAllSquads() end
end })

AttackTab:CreateSection("Status")
AttackTab:CreateButton({
    Name = "Show Squad Status + Boat Points",
    Callback = function()
        refreshCaptureCache()
        local lines = ""
        for _, sq in ipairs(SQUADS) do
            lines = lines .. "Squad " .. sq .. ": " .. squadStatus[sq] .. "\n"
        end
        lines = lines .. "\n— Boat Points —\n"
        for _, pt in ipairs(BOAT_POINTS) do
            local st = captureCache[pt]
            local label = st == true and "YOURS" or (st == false and "ENEMY/OPEN" or "UNKNOWN")
            lines = lines .. pt .. ": " .. label .. "\n"
        end
        print("[NAT Status]\n" .. lines)
        Rayfield:Notify({ Title = "Status", Content = lines, Duration = 10 })
    end,
})

AttackTab:CreateToggle({
    Name = "Smart Ground (unowned)",
    CurrentValue = false,
    Flag = "SmartGround",
    Callback = function(v)
        S.SmartGroundAttack = v
        if v then startSmartGroundLoop() else stopThread("SmartGround") end
    end,
})

-- TAB 2 — SMART BOAT
local BoatTab = createTab(Window, "Boats")
BoatTab:CreateSection("Capture uncontested boat points")
addNote(BoatTab, "Ataca boat points que voce NAO domina. Use preset Zone Split ou Boat Focus.")

BoatTab:CreateToggle({
    Name = "Smart Boat Attack (unowned only)",
    CurrentValue = false,
    Flag = "SmartBoatAttack",
    Callback = function(v)
        S.SmartBoatAttack = v
        if v then startSmartBoatLoop() else stopThread("SmartBoat") end
    end,
})

BoatTab:CreateSlider({
    Name = "Scan Interval",
    Range = { 3, 30 },
    Increment = 1,
    Suffix = " sec",
    CurrentValue = S.BoatScanInterval,
    Flag = "BoatScanInterval",
    Callback = function(v) S.BoatScanInterval = v end,
})

BoatTab:CreateToggle({
    Name = "Also attack UNKNOWN points",
    CurrentValue = S.AttackNeutral,
    Flag = "AttackNeutral",
    Callback = function(v) S.AttackNeutral = v end,
})

BoatTab:CreateToggle({
    Name = "Rotate squads E→F→A…",
    CurrentValue = S.BoatSquadRotate,
    Flag = "BoatSquadRotate",
    Callback = function(v) S.BoatSquadRotate = v end,
})

BoatTab:CreateButton({
    Name = "Scan boat points NOW",
    Callback = function()
        refreshCaptureCache()
        local unowned = getUnownedBoatPoints()
        local msg = #unowned > 0 and table.concat(unowned, ", ") or "All boat points appear yours!"
        Rayfield:Notify({ Title = "Boat scan", Content = msg, Duration = 6 })
    end,
})

BoatTab:CreateButton({
    Name = "Fire ALL unowned boat points once",
    Callback = function()
        for _, pt in ipairs(getUnownedBoatPoints()) do
            local sq = nextBoatSquad() or "E"
            sendSquad(pt, sq)
            task.wait(0.2)
        end
    end,
})

-- TAB 3 — AUTO UPGRADE
local UpgradeTab = createTab(Window, "Auto Upgrade")
UpgradeTab:CreateSection("Base / Tycoon")
addNote(UpgradeTab, "Compra upgrades na sua base. Ja tenha comprado 1 item no tycoon antes.")

UpgradeTab:CreateToggle({
    Name = "Auto Upgrade Base",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(v)
        S.AutoUpgrade = v
        if v then
            discoverRemotes()
            startAutoUpgradeLoop()
        else
            stopThread("AutoUpgrade")
        end
    end,
})

UpgradeTab:CreateSlider({
    Name = "Upgrade Interval",
    Range = { 1, 15 },
    Increment = 1,
    Suffix = " sec",
    CurrentValue = S.UpgradeInterval,
    Flag = "UpgradeInterval",
    Callback = function(v) S.UpgradeInterval = v end,
})

UpgradeTab:CreateToggle({ Name = "Upgrade Monitors", CurrentValue = true, Flag = "UpgMonitors",
    Callback = function(v) S.UpgradeMonitors = v end })
UpgradeTab:CreateToggle({ Name = "Upgrade PCs / Computers", CurrentValue = true, Flag = "UpgPCs",
    Callback = function(v) S.UpgradePCs = v end })
UpgradeTab:CreateToggle({ Name = "Buy Buildings (tycoon)", CurrentValue = true, Flag = "UpgBuildings",
    Callback = function(v) S.UpgradeBuildings = v end })
UpgradeTab:CreateToggle({ Name = "Use ProximityPrompt buy", CurrentValue = true, Flag = "UseProximityBuy",
    Callback = function(v) S.UseProximityBuy = v end })

UpgradeTab:CreateButton({
    Name = "Upgrade once NOW",
    Callback = function()
        discoverRemotes()
        local t = getNAT_Tycoon()
        local n = runAutoUpgrade()
        safeNotify({
            Title = "Tycoon Upgrade",
            Content = (t and ("Base: " .. t.Name .. " | ") or "Tycoon NAO achado! ") .. "Tentativas: " .. n,
            Duration = 5,
        })
    end,
})
UpgradeTab:CreateButton({
    Name = "Listar botoes do tycoon (F9)",
    Callback = function()
        local t = getNAT_Tycoon()
        if not t then warn("[NAT] Sem tycoon"); return end
        local c = 0
        for _, d in ipairs(t:GetDescendants()) do
            if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d.Name:lower():find("button") then
                print("[NAT Tycoon]", d:GetFullName())
                c = c + 1
            end
        end
        safeNotify({ Title = "Tycoon", Content = c .. " botoes listados no F9", Duration = 4 })
    end,
})

UpgradeTab:CreateButton({
    Name = "Rediscover remotes (check console F9)",
    Callback = function()
        discoverRemotes()
        local names = {}
        for _, r in ipairs(Remotes.BuyList) do table.insert(names, r.Name) end
        Rayfield:Notify({
            Title = "Remotes",
            Content = #names > 0 and table.concat(names, ", ") or "No buy remotes found — using prompts only",
            Duration = 6,
        })
    end,
})

-- TAB 4 — ASSIGNMENT
local AssignTab = createTab(Window, "Assignment")
AssignTab:CreateSection("Active Squads")
for _, squad in ipairs(SQUADS) do
    AssignTab:CreateToggle({
        Name = "Squad " .. squad .. " Active",
        CurrentValue = true,
        Flag = "sqActive_" .. squad,
        Callback = function(v)
            S.ActiveSquads[squad] = v
            if S.AutoAttack then
                if v then startSquadThread(squad)
                else
                    if squadThreads[squad] then
                        pcall(task.cancel, squadThreads[squad])
                        squadThreads[squad] = nil
                        squadStatus[squad] = "Disabled"
                    end
                end
            end
        end,
    })
end

AssignTab:CreateSection("Manual Fire")
for _, squad in ipairs(SQUADS) do
    AssignTab:CreateButton({
        Name = "Fire Squad " .. squad .. " → all its points",
        Callback = function()
            task.spawn(function()
                local pts = S.Assignment[squad] or {}
                for _, pt in ipairs(pts) do
                    sendSquad(pt, squad)
                    task.wait(0.2)
                end
            end)
        end,
    })
end

-- TAB 5 — QUICK FIRE
local QuickTab = createTab(Window, "Quick Fire")
QuickTab:CreateSection("Zone Blitz")

local function fireZoneAllSquads(list, label)
    task.spawn(function()
        for _, pt in ipairs(list) do
            for _, sq in ipairs(SQUADS) do
                if S.ActiveSquads[sq] then
                    sendSquad(pt, sq)
                    task.wait(0.05)
                end
            end
            task.wait(0.15)
        end
        Rayfield:Notify({ Title = label, Content = "Done.", Duration = 2 })
    end)
end

QuickTab:CreateButton({ Name = "Blitz ALL 25 Points", Callback = function() fireZoneAllSquads(ALL_POINTS, "Full Blitz") end })
QuickTab:CreateButton({ Name = "All Front Points", Callback = function() fireZoneAllSquads(FRONT_POINTS, "Front") end })
QuickTab:CreateButton({ Name = "All Ground Points", Callback = function() fireZoneAllSquads(GROUND_POINTS, "Ground") end })
QuickTab:CreateButton({ Name = "All Boat Points", Callback = function() fireZoneAllSquads(BOAT_POINTS, "Boat") end })
QuickTab:CreateButton({ Name = "Unowned Boat Points only", Callback = function()
    fireZoneAllSquads(getUnownedBoatPoints(), "Unowned Boats")
end })
QuickTab:CreateButton({ Name = "Everyone → CENTER", Callback = function()
    for _, sq in ipairs(SQUADS) do sendSquad("Center", sq) end
end })

QuickTab:CreateSection("Single Point")
local function makeBlitzBtn(pt)
    QuickTab:CreateButton({ Name = pt, Callback = function()
        for _, sq in ipairs(SQUADS) do
            if S.ActiveSquads[sq] then sendSquad(pt, sq) end
        end
    end })
end
makeBlitzBtn("Center")
for _, n in ipairs(FRONT_POINTS) do makeBlitzBtn(n) end
for _, n in ipairs(GROUND_POINTS) do makeBlitzBtn(n) end
for _, n in ipairs(BOAT_POINTS) do makeBlitzBtn(n) end

-- TAB 6 — MOVEMENT
local MoveTab = createTab(Window, "Movement")
MoveTab:CreateSlider({ Name = "Walk Speed", Range = { 16, 250 }, Increment = 1, Suffix = " studs/s",
    CurrentValue = 16, Flag = "WalkSpeed", Callback = function(v)
        S.WalkSpeed = v
        local h = getHum()
        if h then h.WalkSpeed = v end
    end })
MoveTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v) S.InfiniteJump = v end })
MoveTab:CreateSlider({ Name = "Fly Speed", Range = { 10, 300 }, Increment = 10, Suffix = " studs/s",
    CurrentValue = 60, Flag = "FlySpeed", Callback = function(v) S.FlySpeed = v end })
MoveTab:CreateToggle({ Name = "Enable Fly (WASD + Space/Ctrl)", CurrentValue = false, Flag = "FlyEnabled",
    Callback = function(v) S.FlyEnabled = v; if v then enableFly() else disableFly() end end })
MoveTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Flag = "Noclip",
    Callback = function(v) S.Noclip = v; setNoclip(v) end })

-- TAB 7 — MISC
local MiscTab = createTab(Window, "Misc")
MiscTab:CreateToggle({ Name = "Anti AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v) S.AntiAFK = v end })
MiscTab:CreateToggle({ Name = "God Mode", CurrentValue = false, Flag = "GodMode",
    Callback = function(v) S.GodMode = v end })
MiscTab:CreateButton({ Name = "Rejoin Server", Callback = function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end })
MiscTab:CreateButton({ Name = "Reset Character", Callback = function()
    local h = getHum()
    if h then h.Health = 0 end
end })

end) -- pcall UI

if not uiOk then
    showError("Rayfield UI: " .. tostring(uiErr))
    buildFallbackUI()
    return
end

-- ─── Startup ───────────────────────────────────────────
safeNotify({
    Title = "NAT " .. VERSION .. " pronto!",
    Content = "Janela Rayfield aberta. Auto Attack na primeira aba.",
    Duration = 8,
    Image = ICON,
})
notifyLoaded()
print("[NAT " .. VERSION .. "] Carregado com sucesso. Abra o menu Rayfield (geralmente K ou botao no canto).")
