-- ============================================================================
-- 🚀 KILLER HUB - PORTABLE TROLL & MODIFY MODULE (UNIVERSAL SHOT FIX EDITION)
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Global Optimizations & Fallen Height Cache
getgenv().KH_PlayerRoles = getgenv().KH_PlayerRoles or {}
getgenv().KH_PlayerDeadStatus = getgenv().KH_PlayerDeadStatus or {}
getgenv().FPDH = Workspace.FallenPartsDestroyHeight

-- Gun Aura Variables
local GunAuraActivo = false
local MostrarBoxVisual = true 
local GunAuraRadio = 15
local GunAuraConnection = nil
local VisualAuraPart = nil

-- Coin Aura & ESP Variables
local CoinAuraActivo = false
local MostrarCoinESPVisual = true
local CoinAuraRadio = 8
local CoinAuraConnection = nil
local CachedCoins = {}
local ActiveCoinAdornments = {}

-- Real-Time VFX Variables
local ModificarDisparosActivo = false
local ArcoirisActivo = false
local ColorDisparoActual = Color3.fromRGB(185, 0, 0) 
local GrosorDisparo = 0.8
local OpacidadDisparo = 0.0 -- 0.0 es 100% Sólido/Opaco en Roblox
local TrackedBeams = {}

-- Visual Cleaners
local function LimpiarAuraVisual()
    if VisualAuraPart then
        pcall(function() VisualAuraPart:Destroy() end)
        VisualAuraPart = nil
    end
end

local function LimpiarTodosLosAdornments()
    for coin, adorn in pairs(ActiveCoinAdornments) do
        pcall(function() adorn:Destroy() end)
    end
    table.clear(ActiveCoinAdornments)
end

-- ============================================================================
-- 🛡️ SMART SMART FILTRATION ENGINE (UNLOCKS NORMAL GUNS & BLOCKS MAP LIGHTS)
-- ============================================================================
local function EsUnDisparoValido(descendant)
    if not descendant:IsA("Beam") then return false end
    
    local parent = descendant.Parent
    if parent and parent:IsA("BasePart") and parent.Anchored then
        -- Las columnas de luz estáticas del mapa están ancladas y sus nombres revelan que son decoración
        local pName = parent.Name:lower()
        if pName:find("light") or pName:find("pillar") or pName:find("neon") or pName:find("post") or pName:find("decor") or pName:find("lamp") then
            return false
        end
        
        -- Comprobación del modelo contenedor del mapa para evitar clonados estáticos
        local grandParent = parent.Parent
        if grandParent and grandParent:IsA("Model") then
            local gpName = grandParent.Name:lower()
            if gpName:find("pool") or gpName:find("lobby") or gpName:find("building") or gpName:find("structure") then
                return false
            end
        end
    end
    
    -- Permite cualquier otro Beam (incluyendo los del sistema de disparo normal de MM2)
    return true
end

-- ============================================================================
-- ⚡ HIGH-PERFORMANCE VFX MOTOR (PREMIUM GLOW & SOLID LOCK)
-- ============================================================================
local function InicializarCacheBeams()
    table.clear(TrackedBeams)
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if EsUnDisparoValido(desc) then
            TrackedBeams[desc] = true
        end
    end
end

local function ActualizarTodosLosBeams()
    if not ModificarDisparosActivo then return end
    local currentOpacity = NumberSequence.new(OpacidadDisparo)
    local currentSequence = ColorSequence.new(ColorDisparoActual)
    
    for desc in pairs(TrackedBeams) do
        if desc and desc.Parent then
            desc.Texture = "" 
            desc.TextureSpeed = 0
            desc.Width0 = GrosorDisparo
            desc.Width1 = GrosorDisparo
            desc.Transparency = currentOpacity -- Bloqueo estricto de opacidad física
            
            -- Premium Glowing Engine (Láser limpio y brillante sin blanquear el color)
            desc.LightEmission = 0.55  
            desc.LightInfluence = 0.0  -- Ignora la iluminación ambiental para mantener los tonos vivos
            
            if not ArcoirisActivo then 
                desc.Color = currentSequence
            end
        else
            TrackedBeams[desc] = nil
        end
    end
end

Workspace.DescendantAdded:Connect(function(descendant)
    if EsUnDisparoValido(descendant) then
        TrackedBeams[descendant] = true
        if ModificarDisparosActivo then
            task.defer(ActualizarTodosLosBeams)
        end
    end
end)

InicializarCacheBeams()

-- ============================================================================
-- 📡 NETWORK SYNC (ROLES DETECTOR)
-- ============================================================================
local function parsePlayerData(tabla)
    if type(tabla) == "table" then
        for name, data in pairs(tabla) do
            if type(data) == "table" then
                if data.Role then getgenv().KH_PlayerRoles[name] = data.Role end
                if data.Dead ~= nil then getgenv().KH_PlayerDeadStatus[name] = data.Dead end
            end
        end
    end
end

local PlayerDataChanged = ReplicatedStorage:FindFirstChild("PlayerDataChanged", true)
local RoundStart = ReplicatedStorage:FindFirstChild("RoundStart", true)

if PlayerDataChanged and PlayerDataChanged:IsA("RemoteEvent") then 
    PlayerDataChanged.OnClientEvent:Connect(parsePlayerData) 
end

if RoundStart and RoundStart:IsA("RemoteEvent") then
    RoundStart.OnClientEvent:Connect(function(arg1, arg2)
        table.clear(getgenv().KH_PlayerRoles)
        table.clear(getgenv().KH_PlayerDeadStatus)
        parsePlayerData(arg2)
        parsePlayerData(arg1)
    end)
end

local function EscanearMochilasYEquipamiento()
    local sheriffActual = nil
    for name, role in pairs(getgenv().KH_PlayerRoles) do
        if role == "Sheriff" and not getgenv().KH_PlayerDeadStatus[name] then
            sheriffActual = name
            break
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local character = p.Character
            local backpack = p:FindFirstChild("Backpack")
            local tieneKnife = false
            local tieneGun = false
            
            if backpack then
                if backpack:FindFirstChild("Knife") then tieneKnife = true end
                if backpack:FindFirstChild("Gun") then tieneGun = true end
            end
            
            if character then
                if character:FindFirstChild("Knife") then tieneKnife = true end
                if character:FindFirstChild("Gun") then tieneGun = true end
            end
            
            if tieneKnife then
                getgenv().KH_PlayerRoles[p.Name] = "Murderer"
            elseif tieneGun then
                if sheriffActual and sheriffActual ~= p.Name then
                    getgenv().KH_PlayerRoles[p.Name] = "Hero"
                else
                    getgenv().KH_PlayerRoles[p.Name] = "Sheriff"
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        EscanearMochilasYEquipamiento()
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                getgenv().KH_PlayerRoles[p.Name] = nil
                getgenv().KH_PlayerDeadStatus[p.Name] = true
            end
        end
    end
end)

-- ============================================================================
-- 🪙 COIN CACHE & ESP
-- ============================================================================
task.spawn(function()
    while true do
        if CoinAuraActivo then
            local coinContainer = Workspace:FindFirstChild("CoinContainer", true)
            local tempCoins = {}
            
            if coinContainer then
                for _, coin in ipairs(coinContainer:GetChildren()) do
                    if coin.Name == "Coin_Server" and coin:IsA("BasePart") then
                        table.insert(tempCoins, coin)
                        
                        if MostrarCoinESPVisual then
                            if not ActiveCoinAdornments[coin] or ActiveCoinAdornments[coin].Parent == nil then
                                local adorn = Instance.new("BoxHandleAdornment")
                                adorn.Name = "KH_CoinESP_Box"
                                adorn.Size = Vector3.new(1.6, 1.6, 1.6)
                                adorn.Color3 = Color3.fromRGB(255, 215, 0)
                                adorn.Transparency = 0.45
                                adorn.AlwaysOnTop = true 
                                adorn.ZIndex = 6
                                adorn.Adornee = coin
                                adorn.Parent = coin 
                                ActiveCoinAdornments[coin] = adorn
                            end
                        end
                    end
                end
            end
            
            if not MostrarCoinESPVisual then
                LimpiarTodosLosAdornments()
            else
                for coin, adorn in pairs(ActiveCoinAdornments) do
                    if not coin or not coin.Parent or not table.find(tempCoins, coin) then
                        pcall(function() adorn:Destroy() end)
                        ActiveCoinAdornments[coin] = nil
                    end
                end
            end
            
            CachedCoins = tempCoins
        else
            LimpiarTodosLosAdornments()
            table.clear(CachedCoins)
        end
        task.wait(0.4)
    end
end)

-- ============================================================================
-- 🌀 YOUTUBE ENGINE FLING
-- ============================================================================
local function ObtenerJugadorPorRol(rolBuscado)
    local espRoles = getgenv().KH_PlayerRoles
    local espDead = getgenv().KH_PlayerDeadStatus
    
    for _, p in ipairs(Players:GetPlayers()) do
        if espRoles[p.Name] == rolBuscado then
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local estaMuerto = espDead[p.Name] == true
                local hum = char:FindFirstChildOfClass("Humanoid")
                local sinVida = hum and hum.Health <= 0
                if not (estaMuerto or sinVida) then 
                    return p 
                end
            end
        end
    end
    return nil
end

local isFlinging = false
local function EjecutarSkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == LocalPlayer or isFlinging then return end
    isFlinging = true
    
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    
    if Character and Humanoid and RootPart and TCharacter and THumanoid and TRootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THead then 
            Workspace.CurrentCamera.CameraSubject = THead 
        elseif TRootPart then 
            Workspace.CurrentCamera.CameraSubject = TRootPart 
        end
        
        local FPos = function(BasePart, Pos, Ang)
            if not RootPart or not Character then return end
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, -9e7 * 10, 9e7) 
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 1.8
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid and BasePart and BasePart.Parent then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end
        
        Workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, -9e8, 9e8) 
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.Position - THead.Position).Magnitude > 5 then 
                SFBasePart(THead) 
            else 
                SFBasePart(TRootPart) 
            end
        elseif TRootPart then 
            SFBasePart(TRootPart) 
        elseif THead then 
            SFBasePart(THead) 
        elseif Handle then 
            SFBasePart(Handle) 
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        Workspace.CurrentCamera.CameraSubject = Humanoid
        
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in ipairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then 
                        x.Velocity = Vector3.new()
                        x.RotVelocity = Vector3.new() 
                    end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.Position).Magnitude < 25
        end
        
        Workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end
    isFlinging = false
end

-- ============================================================================
-- 🛠️ CLEAN ENGLISH UI TABS
-- ============================================================================
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Paolo0109/Privatehub.lua/refs/heads/main/Slayer.lua"))()
local TrollTab = KillerHub:CreateTab("Troll", "rbxassetid://10747373142")
local ModifyTab = KillerHub:CreateTab("Modify", "rbxassetid://10747372517")

local AntiFlingConnection, LocalAntiFlingConnection, NoCollisionConnection, SoundConnection, GrabGunConnection, GunAuraConnection, CoinAuraConnection

TrollTab:CreateSection("Combat Attacks")

TrollTab:CreateButton("Fling Murderer", function()
    local target = ObtenerJugadorPorRol("Murderer")
    if target then task.spawn(function() EjecutarSkidFling(target) end)
    else StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[KillerHub]: Murderer not found in cache yet.", Color = Color3.fromRGB(255, 100, 100)}) end
end)

TrollTab:CreateButton("Fling Sheriff / Hero", function()
    local target = ObtenerJugadorPorRol("Sheriff") or ObtenerJugadorPorRol("Hero")
    if target then task.spawn(function() EjecutarSkidFling(target) end)
    else StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[KillerHub]: Sheriff or Hero not found in cache yet.", Color = Color3.fromRGB(255, 100, 100)}) end
end)

TrollTab:CreateSection("Gun Aura")

TrollTab:CreateToggle("GunAuraToggle", "Gun Aura", function(estado)
    GunAuraActivo = estado
    if estado then
        GunAuraConnection = RunService.Heartbeat:Connect(function()
            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            if myRoot and myCharacter:FindFirstChildOfClass("Humanoid") and myCharacter:FindFirstChildOfClass("Humanoid").Health > 0 then
                local gunDrop = nil
                
                for _, folder in ipairs(Workspace:GetChildren()) do
                    local found = folder:FindFirstChild("GunDrop") or (folder.Name == "GunDrop" and folder)
                    if found and found:IsA("BasePart") then
                        gunDrop = found
                        break
                    end
                end
                
                if gunDrop then
                    local distancia = (myRoot.Position - gunDrop.Position).Magnitude
                    
                    if MostrarBoxVisual then
                        if not VisualAuraPart or VisualAuraPart.Parent == nil then
                            VisualAuraPart = Instance.new("Part")
                            VisualAuraPart.Name = "GunAuraHitbox3D"
                            VisualAuraPart.Shape = Enum.PartType.Block
                            VisualAuraPart.Material = Enum.Material.Neon
                            VisualAuraPart.Color = Color3.fromRGB(0, 255, 100)
                            VisualAuraPart.Transparency = 0.85
                            VisualAuraPart.Anchored = true
                            VisualAuraPart.CanCollide = false
                            VisualAuraPart.CastShadow = false
                            VisualAuraPart.Parent = Workspace
                        end
                        
                        local tamanoCaja = GunAuraRadio * 2
                        VisualAuraPart.Size = Vector3.new(tamanoCaja, tamanoCaja, tamanoCaja)
                        VisualAuraPart.CFrame = CFrame.new(gunDrop.Position)
                    else
                        LimpiarAuraVisual()
                    end
                    
                    if distancia <= GunAuraRadio then
                        pcall(function()
                            firetouchinterest(myRoot, gunDrop, 0)
                            firetouchinterest(myRoot, gunDrop, 1)
                        end)
                    end
                else
                    LimpiarAuraVisual()
                end
            end
        end)
    else
        if GunAuraConnection then GunAuraConnection:Disconnect() GunAuraConnection = nil end
        LimpiarAuraVisual()
    end
end)

TrollTab:CreateToggle("ShowGunBoxToggle", "Show Gun Box", function(estado)
    MostrarBoxVisual = estado
    if not estado then LimpiarAuraVisual() end
end)

TrollTab:CreateSlider("GunAuraRadius", "Gun Aura Radius", 1, 50, function(valor)
    GunAuraRadio = valor
end)

TrollTab:CreateSection("Coin Aura")

TrollTab:CreateToggle("CoinAuraToggle", "Coin Aura", function(estado)
    CoinAuraActivo = estado
    if estado then
        CoinAuraConnection = RunService.Heartbeat:Connect(function()
            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            if myRoot and myCharacter:FindFirstChildOfClass("Humanoid") and myCharacter:FindFirstChildOfClass("Humanoid").Health > 0 then
                
                for _, coin in ipairs(CachedCoins) do
                    if coin and coin.Parent then
                        local dist = (myRoot.Position - coin.Position).Magnitude
                        
                        if dist <= CoinAuraRadio then
                            pcall(function()
                                firetouchinterest(myRoot, coin, 0)
                                firetouchinterest(myRoot, coin, 1)
                            end)
                        end
                    end
                end
            end
        end)
    else
        if CoinAuraConnection then CoinAuraConnection:Disconnect() CoinAuraConnection = nil end
        LimpiarTodosLosAdornments()
    end
end)

TrollTab:CreateToggle("ShowCoinBoxToggle", "See Coins", function(estado)
    MostrarCoinESPVisual = estado
    if not estado then LimpiarTodosLosAdornments() end
end)

TrollTab:CreateSlider("CoinAuraRadius", "Coin Aura Radius", 1, 8, function(valor)
    CoinAuraRadio = valor
end)

TrollTab:CreateSection("Grab Gun")

TrollTab:CreateToggle("AutoGrabGun", "Grab Gun", function(estado)
    if estado then
        GrabGunConnection = RunService.Heartbeat:Connect(function()
            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            if myRoot and myCharacter:FindFirstChildOfClass("Humanoid") and myCharacter:FindFirstChildOfClass("Humanoid").Health > 0 then
                for _, folder in ipairs(Workspace:GetChildren()) do
                    local gunDrop = folder:FindFirstChild("GunDrop") or (folder.Name == "GunDrop" and folder)
                    if gunDrop and gunDrop:IsA("BasePart") then
                        local distancia = (myRoot.Position - gunDrop.Position).Magnitude
                        if distancia < 500 then
                            pcall(function()
                                firetouchinterest(myRoot, gunDrop, 0)
                                firetouchinterest(myRoot, gunDrop, 1)
                            end)
                        end
                        break
                    end
                end
            end
        end)
    else
        if GrabGunConnection then GrabGunConnection:Disconnect() GrabGunConnection = nil end
    end
end)

TrollTab:CreateSection("Physics & Disruption")

TrollTab:CreateToggle("AntiFlingActive", "Anti-Fling", function(estado)
    if estado then
        AntiFlingConnection = RunService.Heartbeat:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root and (root.AssemblyAngularVelocity.Magnitude > 50 or root.AssemblyLinearVelocity.Magnitude > 100) then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end
                end
            end
        end)
        local lastPosition = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.CFrame
        LocalAntiFlingConnection = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                local root = LocalPlayer.Character.PrimaryPart
                if root.AssemblyLinearVelocity.Magnitude > 250 or root.AssemblyAngularVelocity.Magnitude > 250 then
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    if lastPosition then root.CFrame = lastPosition end
                elseif root.AssemblyLinearVelocity.Magnitude < 50 and root.AssemblyAngularVelocity.Magnitude < 50 then lastPosition = root.CFrame end
            end
        end)
    else
        if AntiFlingConnection then AntiFlingConnection:Disconnect() AntiFlingConnection = nil end
        if LocalAntiFlingConnection then LocalAntiFlingConnection:Disconnect() LocalAntiFlingConnection = nil end
    end
end)

TrollTab:CreateToggle("NoPlayerCollision", "No-Collision", function(estado)
    if estado then
        NoCollisionConnection = RunService.Stepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end)
    else
        if NoCollisionConnection then NoCollisionConnection:Disconnect() NoCollisionConnection = nil end
    end
end)

-- ============================================================================
-- PESTAÑA MODIFY
-- ============================================================================
ModifyTab:CreateSection("Weapon Sounds")

local GunSounds = {
    ["Default"] = {Disparo = nil, Recarga = nil},
    ["Gingerscope"] = {Disparo = "rbxassetid://98245448501031", Recarga = nil},
    ["Laser"] = {Disparo = "rbxassetid://8561500387", Recarga = "rbxassetid://8561502124"}
}

local KnifeSounds = {
    ["Default"] = nil,
    ["Minecraft"] = "rbxassetid://133823475766637",
    ["Minecraft 2"] = "rbxassetid://133248563542879",
    ["Minecraft 3"] = "rbxassetid://107868586874799",
    ["Minecraft 4"] = "rbxassetid://90520156786055",
    ["Fart"] = "rbxassetid://17043360893"
}

local SonidoPistolaActual = "Default"
local SonidoCuchilloActual = "Default"
local VolumenPistola = 2 
local VolumenCuchillo = 2
local OriginalIds = {}

local function ModificarAudio(descendant)
    if not descendant:IsA("Sound") then return end
    
    if not OriginalIds[descendant] then
        OriginalIds[descendant] = descendant.SoundId
    end

    local name = descendant.Name:lower()
    local esDePistola = descendant:FindFirstAncestor("Gun") or descendant:FindFirstAncestor("Pistola") or name:find("gun") or name:find("shoot") or name:find("reload")
    local esDeCuchillo = descendant:FindFirstAncestor("Knife") or descendant:FindFirstAncestor("Cuchillo") or name:find("slash") or name:find("stab") or name:find("knife")

    local configPistola = GunSounds[SonidoPistolaActual]
    if SonidoPistolaActual ~= "Default" and configPistola and esDePistola and not esDeCuchillo then
        descendant.Volume = VolumenPistola
        if (name:find("shoot") or name:find("shot") or name:find("fire")) and configPistola.Disparo then
            descendant.SoundId = configPistola.Disparo
        elseif name:find("reload") and configPistola.Recarga then
            descendant.SoundId = configPistola.Recarga
        end
    elseif SonidoPistolaActual == "Default" and esDePistola then
        if OriginalIds[descendant] then descendant.SoundId = OriginalIds[descendant] end
    end
    
    local audioCuchillo = KnifeSounds[SonidoCuchilloActual]
    if SonidoCuchilloActual ~= "Default" and audioCuchillo and esDeCuchillo then
        descendant.Volume = VolumenCuchillo
        if (name:find("slash") or name:find("stab") or name:find("kill") or name:find("hit")) then
            descendant.SoundId = audioCuchillo
        end
    elseif SonidoCuchilloActual == "Default" and esDeCuchillo then
        if OriginalIds[descendant] then descendant.SoundId = OriginalIds[descendant] end
    end
end

local function GestionarEscuchadorSonidos()
    if SoundConnection then SoundConnection:Disconnect() SoundConnection = nil end
    
    for _, descendant in ipairs(game:GetDescendants()) do
        if descendant:IsA("Sound") then ModificarAudio(descendant) end
    end

    SoundConnection = game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Sound") then
            descendant.Played:Connect(function() ModificarAudio(descendant) end)
            ModificarAudio(descendant)
        end
    end)
end

ModifyTab:CreateDropdown("CustomGunSound", "Select Gun Sound:", {"Default", "Gingerscope", "Laser"}, function(seleccionado)
    SonidoPistolaActual = seleccionado
    GestionarEscuchadorSonidos()
end)

local actualizandoVolPistola = 0
ModifyTab:CreateSlider("GunVolume", "Gun Volume", 0, 10, function(valor)
    VolumenPistola = valor
    local idActual = tick()
    actualizandoVolPistola = idActual
    task.wait(0.08)
    if actualizandoVolPistola == idActual then
        for _, descendant in ipairs(game:GetDescendants()) do
            if descendant:IsA("Sound") then ModificarAudio(descendant) end
        end
    end
end)

ModifyTab:CreateDropdown("CustomKnifeSound", "Select Knife Sound:", {"Default", "Minecraft", "Minecraft 2", "Minecraft 3", "Minecraft 4", "Fart"}, function(seleccionado)
    SonidoCuchilloActual = seleccionado
    GestionarEscuchadorSonidos()
end)

local actualizandoVolCuchillo = 0
ModifyTab:CreateSlider("KnifeVolume", "Knife Volume", 0, 10, function(valor)
    VolumenCuchillo = valor
    local idActual = tick()
    actualizandoVolCuchillo = idActual
    task.wait(0.08)
    if actualizandoVolCuchillo == idActual then
        for _, descendant in ipairs(game:GetDescendants()) do
            if descendant:IsA("Sound") then ModificarAudio(descendant) end
        end
    end
end)

-- ============================================================================
-- 💎 CUSTOM BEAM VFX (UNIVERSAL COMPATIBILITY MOTOR)
-- ============================================================================
ModifyTab:CreateSection("Gun Shot Effects")

ModifyTab:CreateToggle("ModifyVfxActive", "Modify Gun Shots", function(val) 
    ModificarDisparosActivo = val 
    if val then
        ActualizarTodosLosBeams()
    end
end)

ModifyTab:CreateToggle("RainbowVfxActive", "Rainbow Effect (RGB)", function(val) 
    ArcoirisActivo = val 
    ActualizarTodosLosBeams()
end)

RunService.Heartbeat:Connect(function()
    if not ModificarDisparosActivo or not ArcoirisActivo then return end
    
    -- Flujo Cromático Premium de 5 Fases (Ultra Suave, Sólido y Vivo)
    local t = tick() * 1.2
    local k1 = Color3.fromHSV((t) % 1, 1.0, 0.85)   
    local k2 = Color3.fromHSV((t + 0.25) % 1, 1.0, 0.85)
    local k3 = Color3.fromHSV((t + 0.50) % 1, 1.0, 0.85)
    local k4 = Color3.fromHSV((t + 0.75) % 1, 1.0, 0.85)
    local k5 = Color3.fromHSV((t + 1.00) % 1, 1.0, 0.85)
    
    local premiumSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, k1),
        ColorSequenceKeypoint.new(0.25, k2),
        ColorSequenceKeypoint.new(0.50, k3),
        ColorSequenceKeypoint.new(0.75, k4),
        ColorSequenceKeypoint.new(1, k5)
    })
    
    for b in pairs(TrackedBeams) do 
        if b and b.Parent then 
            b.Color = premiumSequence 
            b.Transparency = NumberSequence.new(OpacidadDisparo) -- Bloqueo de opacidad estricto en RGB
        else 
            TrackedBeams[b] = nil 
        end 
    end
end)

ModifyTab:CreateColorPicker("BeamCustomColor", "Shot Color", Color3.fromRGB(185, 0, 0), function(c) 
    ColorDisparoActual = c 
    ActualizarTodosLosBeams()
end)

ModifyTab:CreateSlider("BeamTransparency", "Shot Opacity (1 = Opaque)", 1, 10, function(v) 
    -- Cuando lo dejas en 1, el valor es 0 (100% sólido y opaco en Roblox)
    OpacidadDisparo = (v - 1) / 9
    ActualizarTodosLosBeams()
end)

ModifyTab:CreateSlider("BeamWidth", "Shot Width", 1, 15, function(v) 
    GrosorDisparo = v / 10
    ActualizarTodosLosBeams()
end)

CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "KillerHub" then 
        if AntiFlingConnection then AntiFlingConnection:Disconnect() end
        if LocalAntiFlingConnection then LocalAntiFlingConnection:Disconnect() end
        if NoCollisionConnection then NoCollisionConnection:Disconnect() end
        if SoundConnection then SoundConnection:Disconnect() end
        if GrabGunConnection then GrabGunConnection:Disconnect() end
        if GunAuraConnection then GunAuraConnection:Disconnect() end
        if CoinAuraConnection then CoinAuraConnection:Disconnect() end
        LimpiarAuraVisual()
        LimpiarTodosLosAdornments()
        table.clear(TrackedBeams)
    end
end)

return KillerHub
