
--==============================================================================
-- 🔪 MM2 ADVANCED PLAYER UTILITIES — KILLER HUB (MAX OPTIMIZED V2.0)
--==============================================================================

-- Cargar librería con fallback seguro
local rawLibrary = game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub1/refs/heads/main/MM2.lua")
local KillerHub = loadstring(rawLibrary)() or getgenv().KillerHub

if not KillerHub then
    warn("[KillerHub Error]: No se pudo obtener la interfaz base.")
    return
end

-- Prevenir doble ejecución
if getgenv().__MM2AdvancedScript_Loaded then
    KillerHub:NotifyWarn("Alerta", "El script ya se está ejecutando.", 3)
    return
end
getgenv().__MM2AdvancedScript_Loaded = true

-- Helper para consultar flags de forma segura
local function GetFlag(name, default)
    local f = KillerHub.Flags and KillerHub.Flags[name]
    if f == nil or f.CurrentValue == nil then return default end
    return f.CurrentValue
end

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variables de Estado & Conexiones
local NoclipConnection = nil
local InvisConnection = nil
local AntiFlingConnection = nil
local SpeedGlitchConnection = nil
local CharacterConnections = {}

local invisParts = {}
local noclipCache = {}

--==============================================================================
-- CORE UTILITY FUNCTIONS
--==============================================================================

-- Cachear partes para Noclip
local function UpdateNoclipCache(char)
    table.clear(noclipCache)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(noclipCache, part)
        end
    end
end

-- Speed Glitch Optimizado
local function ToggleSpeedGlitch(state)
    if SpeedGlitchConnection then
        SpeedGlitchConnection:Disconnect()
        SpeedGlitchConnection = nil
    end

    if not state then return end

    local wallCheckParams = RaycastParams.new()
    wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
    wallCheckParams.IgnoreWater = true

    SpeedGlitchConnection = RunService.Heartbeat:Connect(function()
        if not GetFlag("Speed_Glitch", false) then return end

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
    end)
end

-- Método FE Invisibility Fluidas (Sin RenderStepped:Wait inside Heartbeat)
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

            -- Sincronización limpia en el ciclo de física
            task.defer(function()
                if rootPart and rootPart.Parent then
                    rootPart.CFrame = cf
                end
                if humanoid and humanoid.Parent then
                    humanoid.CameraOffset = camOffset
                end
            end)
        end
    end)
end

-- Módulo Anti Fling Ultra-Optimizado
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
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        if part.CanCollide then
                            part.CanCollide = false
                        end
                        if part.AssemblyLinearVelocity.Magnitude > 40 or part.AssemblyAngularVelocity.Magnitude > 40 then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
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
    -- Limpiar conexiones previas del personaje
    for _, conn in ipairs(CharacterConnections) do
        conn:Disconnect()
    end
    table.clear(CharacterConnections)

    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    UpdateNoclipCache(char)

    -- Detectar cuando se añaden accesorios/herramientas para mantener el caché de Noclip
    table.insert(CharacterConnections, char.ChildAdded:Connect(function()
        task.defer(UpdateNoclipCache, char)
    end))

    if GetFlag("Invisible_FE", false) then
        ToggleInvisibilityFE(true)
    end

    if GetFlag("Anti_Fling", false) then
        ToggleAntiFling(true)
    end

    table.insert(CharacterConnections, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if GetFlag("WalkSpeed_Toggle", false) then
            local targetSpeed = GetFlag("WalkSpeed_Value", 16)
            if humanoid.WalkSpeed ~= targetSpeed then
                humanoid.WalkSpeed = targetSpeed
            end
        end
    end))

    table.insert(CharacterConnections, humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if GetFlag("JumpPower_Toggle", false) then
            humanoid.UseJumpPower = true
            local targetJump = GetFlag("JumpPower_Value", 50)
            if humanoid.JumpPower ~= targetJump then
                humanoid.JumpPower = targetJump
            end
        end
    end))

    if GetFlag("WalkSpeed_Toggle", false) then humanoid.WalkSpeed = GetFlag("WalkSpeed_Value", 16) end
    if GetFlag("JumpPower_Toggle", false) then 
        humanoid.UseJumpPower = true 
        humanoid.JumpPower = GetFlag("JumpPower_Value", 50) 
    end
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then task.spawn(SetupCharacter, LocalPlayer.Character) end

--==============================================================================
-- INTERFACE SETUP (TAB: PLAYER)
--==============================================================================

local TabPlayer = KillerHub:CreateTab("Player", "Movement")

-- Sección 1: Speed Glitch
TabPlayer:CreateSection("Speed Glitch")

TabPlayer:CreateToggle("Speed_Glitch", "Speed Glitch", function(state)
    ToggleSpeedGlitch(state)
end)

TabPlayer:CreateSlider("Speed_Glitch_Intensity", "Speed Glitch Intensity", 1, 200, function(value) end)

-- Sección 2: Modificadores de Movimiento
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

-- Sección 3: Utilidades
TabPlayer:CreateSection("Utilities")

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if GetFlag("Infinite_Jump", false) and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then 
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end
end)

TabPlayer:CreateToggle("Infinite_Jump", "Infinite Jump", function(state) end)

-- Noclip Limpio y Ultra-Rápido
TabPlayer:CreateToggle("Noclip", "Noclip", function(state)
    if state then
        if NoclipConnection then NoclipConnection:Disconnect() end
        NoclipConnection = RunService.Stepped:Connect(function()
            for i = 1, #noclipCache do
                local part = noclipCache[i]
                if part and part.Parent then
                    part.CanCollide = false
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

-- Invisible FE
TabPlayer:CreateToggle("Invisible_FE", "Invisible FE", function(state)
    ToggleInvisibilityFE(state)
end)

-- Anti Fling
TabPlayer:CreateToggle("Anti_Fling", "Anti Fling", function(state)
    ToggleAntiFling(state)
end)

-- Notificación de Carga
KillerHub:NotifySuccess("MM2 Script", "Script Loaded successfully.", 4)

return KillerHub
