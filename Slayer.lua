--==============================================================================
-- 🔪 MM2 ADVANCED PLAYER & BOMB JUMP UTILITIES — KILLER HUB
--==============================================================================

local rawLibrary = game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub1/refs/heads/main/MM2.lua")
local KillerHub = loadstring(rawLibrary)() or getgenv().KillerHub

if not KillerHub then
    warn("[KillerHub Error]: No se pudo obtener la interfaz base.")
    return
end

if getgenv().__MM2AdvancedScript_Loaded then
    KillerHub:NotifyWarn("Alerta", "El script ya se está ejecutando.", 3)
    return
end
getgenv().__MM2AdvancedScript_Loaded = true

local function GetFlag(name, default)
    local f = KillerHub.Flags and KillerHub.Flags[name]
    if f == nil or f.CurrentValue == nil then return default end
    return f.CurrentValue
end

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Variables de Estado (Player)
local NoclipConnection = nil
local InvisConnection = nil
local AntiFlingConnection = nil
local invisParts = {}
local speedGlitchLooping = false

--==============================================================================
-- CORE UTILITY FUNCTIONS (PLAYER)
--==============================================================================

local function startSpeedGlitchLoop()
    if speedGlitchLooping then return end
    speedGlitchLooping = true
    
    task.spawn(function()
        local wallCheckParams = RaycastParams.new()
        wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
        wallCheckParams.IgnoreWater = true
        
        while GetFlag("Speed_Glitch", false) do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                local currentHandState = hum:GetState()
                local isClimbing = (currentHandState == Enum.HumanoidStateType.Climbing)
                local isSwimming = (currentHandState == Enum.HumanoidStateType.Swimming)
                
                if hum.FloorMaterial == Enum.Material.Air and root.AssemblyLinearVelocity.Y > 0 and not isClimbing and not isSwimming then
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude > 0 then
                        wallCheckParams.FilterDescendantsInstances = {char, workspace.CurrentCamera}
                        local raycastResult = workspace:Raycast(root.Position, moveDir * 2.2, wallCheckParams)
                        
                        if not raycastResult then
                            local power = GetFlag("Speed_Glitch_Intensity", 50)
                            root.AssemblyLinearVelocity = Vector3.new(
                                moveDir.X * power,
                                root.AssemblyLinearVelocity.Y,
                                moveDir.Z * power
                            )
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
        speedGlitchLooping = false
    end)
end

local function ToggleInvisibilityFE(state)
    if InvisConnection then
        InvisConnection:Disconnect()
        InvisConnection = nil
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not state then
        for part, origTrans in pairs(invisParts) do
            if part and part.Parent then
                part.Transparency = origTrans
            end
        end
        table.clear(invisParts)

        if hum then
            hum.CameraOffset = Vector3.zero
        end
        return
    end

    if not char or not hum then return end

    table.clear(invisParts)
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            invisParts[obj] = obj.Transparency
            obj.Transparency = 0.5
        end
    end

    InvisConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid and rootPart and humanoid.Health > 0 and GetFlag("Invisible_FE", false) then
            local cf = rootPart.CFrame
            local camOffset = humanoid.CameraOffset
            local hidden = cf * CFrame.new(0, -200000, 0)

            rootPart.CFrame = hidden
            humanoid.CameraOffset = hidden:ToObjectSpace(CFrame.new(cf.Position)).Position

            RunService.RenderStepped:Wait()

            if rootPart and rootPart.Parent then
                rootPart.CFrame = cf
            end
            if humanoid and humanoid.Parent then
                humanoid.CameraOffset = camOffset
            end
        end
    end)
end

local function ToggleAntiFling(state)
    if AntiFlingConnection then
        AntiFlingConnection:Disconnect()
        AntiFlingConnection = nil
    end

    if not state then return end

    AntiFlingConnection = RunService.Stepped:Connect(function()
        if not GetFlag("Anti_Fling", false) then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.CanCollide then
                            part.CanCollide = false
                        end
                        if part.AssemblyLinearVelocity.Magnitude > 50 or part.AssemblyAngularVelocity.Magnitude > 50 then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end
            end
        end

        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Accessory") then
                local handle = obj:FindFirstChildWhichIsA("BasePart")
                if handle then
                    if handle.CanCollide then
                        handle.CanCollide = false
                    end
                    if handle.AssemblyLinearVelocity.Magnitude > 50 then
                        handle.AssemblyLinearVelocity = Vector3.zero
                        handle.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end
    end)
end

--==============================================================================
-- CHARACTER INITIALIZATION & PERSISTENCE
--==============================================================================

local function SetupCharacter(char)
    task.wait(0.3)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    if GetFlag("Invisible_FE", false) then
        ToggleInvisibilityFE(true)
    end

    if GetFlag("Anti_Fling", false) then
        ToggleAntiFling(true)
    end
    
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if GetFlag("WalkSpeed_Toggle", false) then
            local targetSpeed = GetFlag("WalkSpeed_Value", 16)
            if humanoid.WalkSpeed ~= targetSpeed then
                humanoid.WalkSpeed = targetSpeed
            end
        end
    end)
    
    humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if GetFlag("JumpPower_Toggle", false) then
            humanoid.UseJumpPower = true
            local targetJump = GetFlag("JumpPower_Value", 50)
            if humanoid.JumpPower ~= targetJump then
                humanoid.JumpPower = targetJump
            end
        end
    end)
    
    if GetFlag("WalkSpeed_Toggle", false) then humanoid.WalkSpeed = GetFlag("WalkSpeed_Value", 16) end
    if GetFlag("JumpPower_Toggle", false) then 
        humanoid.UseJumpPower = true 
        humanoid.JumpPower = GetFlag("JumpPower_Value", 50) 
    end
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then task.spawn(SetupCharacter, LocalPlayer.Character) end

--==============================================================================
-- PESTAÑA 1: PLAYER
--==============================================================================

local TabPlayer = KillerHub:CreateTab("Player", "Movement")

TabPlayer:CreateSection("Speed Glitch")

TabPlayer:CreateToggle("Speed_Glitch", "Speed Glitch", function(state)
    if state then startSpeedGlitchLoop() end
end)

TabPlayer:CreateSlider("Speed_Glitch_Intensity", "Speed Glitch Intensity", 1, 200, function(value) end)

TabPlayer:CreateSection("Movement Modifiers")

TabPlayer:CreateToggleSlider("WalkSpeed_Toggle", "WalkSpeed_Value", "WalkSpeed", 16, 120, 
    function(state)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and GetFlag("WalkSpeed_Value", 16) or 16 end
    end,
    function(value)
        if not GetFlag("WalkSpeed_Toggle", false) then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
)

TabPlayer:CreateToggleSlider("JumpPower_Toggle", "JumpPower_Value", "JumpPower", 50, 150, 
    function(state)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.UseJumpPower = true
            hum.JumpPower = state and GetFlag("JumpPower_Value", 50) or 50 
        end
    end,
    function(value)
        if not GetFlag("JumpPower_Toggle", false) then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.UseJumpPower = true
            hum.JumpPower = value 
        end
    end
)

TabPlayer:CreateSection("Utilities")

UserInputService.JumpRequest:Connect(function()
    if GetFlag("Infinite_Jump", false) and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then 
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end
end)

TabPlayer:CreateToggle("Infinite_Jump", "Infinite Jump", function(state) end)

TabPlayer:CreateToggle("Noclip", "Noclip", function(state)
    if state then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char and char:IsDescendantOf(workspace) then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if NoclipConnection then 
            NoclipConnection:Disconnect() 
            NoclipConnection = nil 
        end
    end
end)

TabPlayer:CreateToggle("Invisible_FE", "Invisible FE", function(state)
    ToggleInvisibilityFE(state)
end)

TabPlayer:CreateToggle("Anti_Fling", "Anti Fling", function(state)
    ToggleAntiFling(state)
end)

--==============================================================================
-- PESTAÑA 2: BOMB JUMP (CORREGIDO Y OPTIMIZADO)
--==============================================================================

local MMVTab = KillerHub:CreateTab("Bomb Jump", "rbxassetid://14321074389")

local POTENCIA_SALTO = 55
local UMBRAL_ARRASTRE = 8

local CooldownNormalTime = 22.0
local CooldownFinNormal = 0
local NormalActivo = false
local AutoEquipNormalActivo = false
local LockNormal = false
local BotonSizeNormalActual = 100
local ARCHIVO_POS_NORMAL = "KillerHub_NormalPosConfig.json"

local CooldownGoldTime = 3.0
local CooldownFinGold = 0
local GoldActivo = false
local AutoEquipGoldActivo = false
local LockGold = false
local BotonSizeGoldActual = 100
local ARCHIVO_POS_GOLD = "KillerHub_GoldPosConfig.json"

local CooldownDiamondTime = 5.5
local CooldownFinDiamond = 0
local DiamondActivo = false
local AutoEquipDiamondActivo = false
local LockDiamond = false
local BotonSizeDiamondActual = 100
local ARCHIVO_POS_DIAMOND = "KillerHub_DiamondPosConfig.json"

local ScreenGuiNormal, BotonNormal
local ScreenGuiGold, BotonGold
local ScreenGuiDiamond, BotonDiamond

local ID_Generacion_Actual = 0

local function guardarPosicionBoton(archivo, xScale, xOffset, yScale, yOffset)
    if not writefile then return end
    pcall(writefile, archivo, HttpService:JSONEncode({
        X_Scale = xScale, X_Offset = xOffset, Y_Scale = yScale, Y_Offset = yOffset
    }))
end

local function cargarPosicionBoton(archivo, defX, defY)
    local pos = {ScaleX = defX, OffsetX = -50, ScaleY = defY, OffsetY = -50}
    if readfile and isfile and isfile(archivo) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(archivo))
            if decoded then
                pos.ScaleX = decoded.X_Scale or pos.ScaleX
                pos.OffsetX = decoded.X_Offset or pos.OffsetX
                pos.ScaleY = decoded.Y_Scale or pos.ScaleY
                pos.OffsetY = decoded.Y_Offset or pos.OffsetY
            end
        end)
    end
    return pos
end

local function AplicarEstiloBoton(boton, colorTexto)
    boton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    boton.BackgroundTransparency = 0.5
    boton.Font = Enum.Font.GothamBold
    boton.TextSize = 11
    boton.TextColor3 = colorTexto
    boton.TextStrokeTransparency = 1
    boton.BorderSizePixel = 0
    boton.Active = true

    local corner = boton:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = boton

    local stroke = boton:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = boton
end

-- Limpieza estricta de conexiones para no saturar memoria al tocar/arrastrar
local function ConfigurarArrastreYClick(boton, archivoConfig, getLockState, accionClick)
    local dragging = false
    local wasDragged = false
    local dragInputObject = nil
    local dragStart = Vector3.zero
    local startPos = UDim2.new()
    local connections = {}

    table.insert(connections, boton.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            wasDragged = false
            dragInputObject = input
            dragStart = input.Position
            startPos = boton.Position
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInputObject then
            local delta = input.Position - dragStart
            if delta.Magnitude > UMBRAL_ARRASTRE then
                if not (getLockState and getLockState()) then
                    wasDragged = true
                    boton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input == dragInputObject and dragging then
            dragging = false
            dragInputObject = nil

            if wasDragged then
                guardarPosicionBoton(archivoConfig, boton.Position.X.Scale, boton.Position.X.Offset, boton.Position.Y.Scale, boton.Position.Y.Offset)
            else
                if accionClick then
                    accionClick()
                end
            end
        end
    end))

    boton.Destroying:Connect(function()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
    end)
end

local function IniciarLoopCooldown(boton, tiempoFin, textoBase, colorBase, idGen)
    task.spawn(function()
        while os.clock() < tiempoFin and idGen == ID_Generacion_Actual do
            if boton and boton.Parent then
                local restante = tiempoFin - os.clock()
                boton.Text = string.format("%.1fs", math.max(0, restante))
                boton.TextColor3 = Color3.fromRGB(150, 150, 150)
                boton.Active = false
            else
                break
            end
            task.wait(0.1)
        end
        if boton and boton.Parent and idGen == ID_Generacion_Actual then
            boton.Text = textoBase
            boton.TextColor3 = colorBase
            boton.Active = true
        end
    end)
end

local function EjecutarNormalBombJump()
    if os.clock() < CooldownFinNormal or not NormalActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("FakeBomb")) or (backpack and backpack:FindFirstChild("FakeBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipNormalActivo and backpack then
            local bombTool = backpack:FindFirstChild("FakeBomb")
            if bombTool then hum:EquipTool(bombTool); task.wait(0.05) end
        end
        
        local fakeBomb = char and char:FindFirstChild("FakeBomb")
        local remote = fakeBomb and fakeBomb:FindFirstChild("Remote")
        if fakeBomb and remote then
            CooldownFinNormal = os.clock() + CooldownNormalTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonNormal, CooldownFinNormal, "BOMB JUMP", Color3.fromRGB(255, 255, 255), ID_Generacion_Actual)
        end
    end
end

local function EjecutarGoldBombJump()
    if os.clock() < CooldownFinGold or not GoldActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("GoldBomb")) or (backpack and backpack:FindFirstChild("GoldBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipGoldActivo and backpack then
            local goldTool = backpack:FindFirstChild("GoldBomb")
            if goldTool then hum:EquipTool(goldTool); task.wait(0.05) end
        end
        
        local goldBomb = char and char:FindFirstChild("GoldBomb")
        local remote = goldBomb and goldBomb:FindFirstChild("Remote")
        if goldBomb and remote then
            CooldownFinGold = os.clock() + CooldownGoldTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonGold, CooldownFinGold, "GOLD JUMP", Color3.fromRGB(255, 215, 0), ID_Generacion_Actual)
        end
    end
end

local function EjecutarDiamondBombJump()
    if os.clock() < CooldownFinDiamond or not DiamondActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("DiamondBomb")) or (backpack and backpack:FindFirstChild("DiamondBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipDiamondActivo and backpack then
            local diamondTool = backpack:FindFirstChild("DiamondBomb")
            if diamondTool then hum:EquipTool(diamondTool); task.wait(0.05) end
        end
        
        local diamondBomb = char and char:FindFirstChild("DiamondBomb")
        local remote = diamondBomb and diamondBomb:FindFirstChild("Remote")
        if diamondBomb and remote then
            CooldownFinDiamond = os.clock() + CooldownDiamondTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonDiamond, CooldownFinDiamond, "DIAMOND JUMP", Color3.fromRGB(0, 191, 255), ID_Generacion_Actual)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    ID_Generacion_Actual = ID_Generacion_Actual + 1
    CooldownFinNormal = 0
    CooldownFinGold = 0
    CooldownFinDiamond = 0
    
    if BotonNormal and NormalActivo then
        BotonNormal.Text = "BOMB JUMP"
        BotonNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
        BotonNormal.Active = true
    end
    if BotonGold and GoldActivo then
        BotonGold.Text = "GOLD JUMP"
        BotonGold.TextColor3 = Color3.fromRGB(255, 215, 0)
        BotonGold.Active = true
    end
    if BotonDiamond and DiamondActivo then
        BotonDiamond.Text = "DIAMOND JUMP"
        BotonDiamond.TextColor3 = Color3.fromRGB(0, 191, 255)
        BotonDiamond.Active = true
    end
end)

local function CrearBotonNormal()
    if CoreGui:FindFirstChild("KillerHub_NormalJump") then CoreGui.KillerHub_NormalJump:Destroy() end
    ScreenGuiNormal = Instance.new("ScreenGui", CoreGui)
    ScreenGuiNormal.Name = "KillerHub_NormalJump"
    ScreenGuiNormal.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_NORMAL, 0.6, 0.7)
    BotonNormal = Instance.new("TextButton", ScreenGuiNormal)
    BotonNormal.Name = "NormalJumpButton"
    BotonNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual)
    BotonNormal.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonNormal, Color3.fromRGB(255, 255, 255))
    
    if os.clock() < CooldownFinNormal then
        IniciarLoopCooldown(BotonNormal, CooldownFinNormal, "BOMB JUMP", Color3.fromRGB(255, 255, 255), ID_Generacion_Actual)
    else
        BotonNormal.Text = "BOMB JUMP"
    end
    
    ConfigurarArrastreYClick(BotonNormal, ARCHIVO_POS_NORMAL, function() return LockNormal end, EjecutarNormalBombJump)
end

local function CrearBotonGold()
    if CoreGui:FindFirstChild("KillerHub_GoldJump") then CoreGui.KillerHub_GoldJump:Destroy() end
    ScreenGuiGold = Instance.new("ScreenGui", CoreGui)
    ScreenGuiGold.Name = "KillerHub_GoldJump"
    ScreenGuiGold.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_GOLD, 0.4, 0.7)
    BotonGold = Instance.new("TextButton", ScreenGuiGold)
    BotonGold.Name = "GoldJumpButton"
    BotonGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual)
    BotonGold.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonGold, Color3.fromRGB(255, 215, 0))
    
    if os.clock() < CooldownFinGold then
        IniciarLoopCooldown(BotonGold, CooldownFinGold, "GOLD JUMP", Color3.fromRGB(255, 215, 0), ID_Generacion_Actual)
    else
        BotonGold.Text = "GOLD JUMP"
    end
    
    ConfigurarArrastreYClick(BotonGold, ARCHIVO_POS_GOLD, function() return LockGold end, EjecutarGoldBombJump)
end

local function CrearBotonDiamond()
    if CoreGui:FindFirstChild("KillerHub_DiamondJump") then CoreGui.KillerHub_DiamondJump:Destroy() end
    ScreenGuiDiamond = Instance.new("ScreenGui", CoreGui)
    ScreenGuiDiamond.Name = "KillerHub_DiamondJump"
    ScreenGuiDiamond.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_DIAMOND, 0.5, 0.7)
    BotonDiamond = Instance.new("TextButton", ScreenGuiDiamond)
    BotonDiamond.Name = "DiamondJumpButton"
    BotonDiamond.Size = UDim2.new(0, BotonSizeDiamondActual, 0, BotonSizeDiamondActual)
    BotonDiamond.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonDiamond, Color3.fromRGB(0, 191, 255))
    
    if os.clock() < CooldownFinDiamond then
        IniciarLoopCooldown(BotonDiamond, CooldownFinDiamond, "DIAMOND JUMP", Color3.fromRGB(0, 191, 255), ID_Generacion_Actual)
    else
        BotonDiamond.Text = "DIAMOND JUMP"
    end
    
    ConfigurarArrastreYClick(BotonDiamond, ARCHIVO_POS_DIAMOND, function() return LockDiamond end, EjecutarDiamondBombJump)
end

local function DestruirBotonNormal() if ScreenGuiNormal then ScreenGuiNormal:Destroy() ScreenGuiNormal = nil BotonNormal = nil end end
local function DestruirBotonGold() if ScreenGuiGold then ScreenGuiGold:Destroy() ScreenGuiGold = nil BotonGold = nil end end
local function DestruirBotonDiamond() if ScreenGuiDiamond then ScreenGuiDiamond:Destroy() ScreenGuiDiamond = nil BotonDiamond = nil end end

MMVTab:CreateSection("Bomb Jump")

MMVTab:CreateToggle("NormalBomb_Enable", "Bomb Jump", function(estado)
    NormalActivo = estado
    if estado then CrearBotonNormal() else DestruirBotonNormal() end
end)

MMVTab:CreateSlider("NormalBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeNormalActual = math.floor(valor)
    if BotonNormal and NormalActivo then
        BotonNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual)
    end
end)

MMVTab:CreateToggle("NormalBomb_Lock", "Lock Position", function(estado)
    LockNormal = estado
end)

MMVTab:CreateToggle("NormalBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipNormalActivo = estado
end)

MMVTab:CreateSection("Gold Bomb Jump")

MMVTab:CreateToggle("GoldBomb_Enable", "Gold Bomb Jump", function(estado)
    GoldActivo = estado
    if estado then CrearBotonGold() else DestruirBotonGold() end
end)

MMVTab:CreateSlider("GoldBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeGoldActual = math.floor(valor)
    if BotonGold and GoldActivo then
        BotonGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual)
    end
end)

MMVTab:CreateToggle("GoldBomb_Lock", "Lock Position", function(estado)
    LockGold = estado
end)

MMVTab:CreateToggle("GoldBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipGoldActivo = estado
end)

MMVTab:CreateSection("Diamond Bomb Jump")

MMVTab:CreateToggle("DiamondBomb_Enable", "Diamond Bomb Jump", function(estado)
    DiamondActivo = estado
    if estado then CrearBotonDiamond() else DestruirBotonDiamond() end
end)

MMVTab:CreateSlider("DiamondBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeDiamondActual = math.floor(valor)
    if BotonDiamond and DiamondActivo then
        BotonDiamond.Size = UDim2.new(0, BotonSizeDiamondActual, 0, BotonSizeDiamondActual)
    end
end)

MMVTab:CreateToggle("DiamondBomb_Lock", "Lock Position", function(estado)
    LockDiamond = estado
end)

MMVTab:CreateToggle("DiamondBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipDiamondActivo = estado
end)

KillerHub:NotifySuccess("MM2 Script", "Script unificado cargado sin problemas.", 4)

return KillerHub
