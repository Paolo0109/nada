-- ============================================================================
-- 🔮 KILLER HUB - MÓDULO EXCLUSIVO MMV (EDICIÓN PROTECCIÓN & ANTI-LAG)
-- ============================================================================

-- 1. CARGAR TU LIBRERÍA EXTERNA
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub1/refs/heads/main/MM2.lua"))()

-- 2. CREAR PESTAÑA EXCLUSIVA MMV
local MMVTab = KillerHub:CreateTab("MMV 💣", "rbxassetid://10747373142")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- 📊 CONFIGURACIÓN GLOBAL DE JUMP POWER
local POTENCIA_SALTO = 55

-- 📊 VARIABLES DE CONTROL INTERNO (DIAMOND)
local CooldownBomba = 5.5
local EnEnfriamiento = false
local FakeClutchActivo = false
local AutoEquipActivo = false
local BotonSizeActual = 100
local ARCHIVO_POS_BOMBA = "KillerHub_BombPosConfig.json"

-- 📊 VARIABLES DE CONTROL INTERNO (GOLD)
local CooldownGold = 3.0
local EnEnfriamientoGold = false
local GoldClutchActivo = false
local AutoEquipGoldActivo = false
local BotonSizeGoldActual = 100
local ARCHIVO_POS_GOLD = "KillerHub_GoldPosConfig.json"

-- 📊 VARIABLES DE CONTROL INTERNO (NORMAL/FAKE BOMB)
local CooldownNormal = 22.0
local EnEnfriamientoNormal = false
local NormalClutchActivo = false
local AutoEquipNormalActivo = false
local BotonSizeNormalActual = 100
local ARCHIVO_POS_NORMAL = "KillerHub_NormalPosConfig.json"

-- Elementos de las UIs Flotantes
local ScreenGuiVoid, BotonCuadradoVoid
local ScreenGuiGold, BotonCuadradoGold
local ScreenGuiNormal, BotonCuadradoNormal

-- Identificador único para cancelar bucles viejos al morir o reiniciarse
local ID_Generacion_Actual = 0

-- ============================================================================
-- 💾 SISTEMA DE CONFIGURACIÓN LOCAL
-- ============================================================================
local function guardarPosicionBoton(archivo, xScale, xOffset, yScale, yOffset)
    local data = {X_Scale = xScale, X_Offset = xOffset, Y_Scale = yScale, Y_Offset = yOffset}
    pcall(function() if writefile then writefile(archivo, HttpService:JSONEncode(data)) end end)
end

local function cargarPosicionBoton(archivo, defX, defY)
    local de_vuelta = {ScaleX = defX, OffsetX = -50, ScaleY = defY, OffsetY = -50}
    pcall(function()
        if readfile and isfile and isfile(archivo) then
            local decoded = HttpService:JSONDecode(readfile(archivo))
            if decoded then
                de_vuelta.ScaleX = decoded.X_Scale or de_vuelta.ScaleX
                de_vuelta.OffsetX = decoded.X_Offset or de_vuelta.OffsetX
                de_vuelta.ScaleY = decoded.Y_Scale or de_vuelta.ScaleY
                de_vuelta.OffsetY = decoded.Y_Offset or de_vuelta.OffsetY
            end
        end
    end)
    return de_vuelta
end

-- ============================================================================
-- ⚡ LÓGICAS CORE DE IMPULSO (SISTEMA os.clock() & PROTECCIÓN EXISTENCIA)
-- ============================================================================
local function EjecutarBombJump()
    if EnEnfriamiento or not FakeClutchActivo then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    -- 🛡️ PROTECCIÓN ANTI-FALLO: Comprobar existencia real de la bomba
    local tieneBomba = (char and char:FindFirstChild("DiamondBomb")) or (backpack and backpack:FindFirstChild("DiamondBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipActivo and backpack then
            local bombInBackpack = backpack:FindFirstChild("DiamondBomb")
            if bombInBackpack then hum:EquipTool(bombInBackpack); task.wait(0.05) end
        end
        local bomb = char:FindFirstChild("DiamondBomb")
        if bomb and bomb:FindFirstChild("Remote") then
            EnEnfriamiento = true; BotonCuadradoVoid.Active = false
            hum.Jump = true; task.wait(0.15)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            task.spawn(function() bomb.Remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            -- Lógica temporal absoluta inmune a tirones
            local tiempoFinal = os.clock() + CooldownBomba
            local idAlIniciar = ID_Generacion_Actual
            task.spawn(function()
                while os.clock() < tiempoFinal and FakeClutchActivo and idAlIniciar == ID_Generacion_Actual do
                    local restante = tiempoFinal - os.clock()
                    BotonCuadradoVoid.Text = string.format("%.1fs", math.max(0, restante))
                    BotonCuadradoVoid.TextColor3 = Color3.fromRGB(120, 120, 120)
                    task.wait(0.05)
                end
                if BotonCuadradoVoid and FakeClutchActivo and idAlIniciar == ID_Generacion_Actual then
                    BotonCuadradoVoid.Text = "BOMB JUMP"; BotonCuadradoVoid.TextColor3 = Color3.fromRGB(255, 255, 255)
                    BotonCuadradoVoid.Active = true; EnEnfriamiento = false
                end
            end)
        end
    end
end

local function EjecutarGoldBombJump()
    if EnEnfriamientoGold or not GoldClutchActivo then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    -- 🛡️ PROTECCIÓN ANTI-FALLO: Comprobar existencia real de la bomba
    local tieneBomba = (char and char:FindFirstChild("GoldBomb")) or (backpack and backpack:FindFirstChild("GoldBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipGoldActivo and backpack then
            local goldInBackpack = backpack:FindFirstChild("GoldBomb")
            if goldInBackpack then hum:EquipTool(goldInBackpack); task.wait(0.05) end
        end
        local goldBomb = char:FindFirstChild("GoldBomb")
        if goldBomb and goldBomb:FindFirstChild("Remote") then
            EnEnfriamientoGold = true; BotonCuadradoGold.Active = false
            hum.Jump = true; task.wait(0.15)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            task.spawn(function() goldBomb.Remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            local tiempoFinal = os.clock() + CooldownGold
            local idAlIniciar = ID_Generacion_Actual
            task.spawn(function()
                while os.clock() < tiempoFinal and GoldClutchActivo and idAlIniciar == ID_Generacion_Actual do
                    local restante = tiempoFinal - os.clock()
                    BotonCuadradoGold.Text = string.format("%.1fs", math.max(0, restante))
                    BotonCuadradoGold.TextColor3 = Color3.fromRGB(120, 120, 120)
                    task.wait(0.05)
                end
                if BotonCuadradoGold and GoldClutchActivo and idAlIniciar == ID_Generacion_Actual then
                    BotonCuadradoGold.Text = "GOLD JUMP"; BotonCuadradoGold.TextColor3 = Color3.fromRGB(218, 165, 32)
                    BotonCuadradoGold.Active = true; EnEnfriamientoGold = false
                end
            end)
        end
    end
end

local function EjecutarNormalBombJump()
    if EnEnfriamientoNormal or not NormalClutchActivo then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    -- 🛡️ PROTECCIÓN ANTI-FALLO: Comprobar existencia real de la bomba (FakeBomb)[span_0](start_span)[span_0](end_span)
    local tieneBomba = (char and char:FindFirstChild("FakeBomb")) or (backpack and backpack:FindFirstChild("FakeBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipNormalActivo and backpack then
            local normalInBackpack = backpack:FindFirstChild("FakeBomb")
            if normalInBackpack then hum:EquipTool(normalInBackpack); task.wait(0.05) end
        end
        local fakeBomb = char:FindFirstChild("FakeBomb")
        if fakeBomb and fakeBomb:FindFirstChild("Remote") then
            EnEnfriamientoNormal = true; BotonCuadradoNormal.Active = false
            hum.Jump = true; task.wait(0.15)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            task.spawn(function() fakeBomb.Remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            local tiempoFinal = os.clock() + CooldownNormal
            local idAlIniciar = ID_Generacion_Actual
            task.spawn(function()
                while os.clock() < tiempoFinal and NormalClutchActivo and idAlIniciar == ID_Generacion_Actual do
                    local restante = tiempoFinal - os.clock()
                    BotonCuadradoNormal.Text = string.format("%.1fs", math.max(0, restante))
                    BotonCuadradoNormal.TextColor3 = Color3.fromRGB(120, 120, 120)
                    task.wait(0.05)
                end
                if BotonCuadradoNormal and NormalClutchActivo and idAlIniciar == ID_Generacion_Actual then
                    BotonCuadradoNormal.Text = "FAKE JUMP"; BotonCuadradoNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
                    BotonCuadradoNormal.Active = true; EnEnfriamientoNormal = false
                end
            end)
        end
    end
end

-- ============================================================================
-- 🔄 DETECTOR DE REINICIO AUTOMÁTICO (RESET INSTANTÁNEO)
-- ============================================================================
local function AlReaparecerPersonaje()
    ID_Generacion_Actual = ID_Generacion_Actual + 1
    
    EnEnfriamiento = false
    EnEnfriamientoGold = false
    EnEnfriamientoNormal = false
    
    if BotonCuadradoVoid and FakeClutchActivo then
        BotonCuadradoVoid.Text = "BOMB JUMP"
        BotonCuadradoVoid.TextColor3 = Color3.fromRGB(255, 255, 255)
        BotonCuadradoVoid.Active = true
    end
    if BotonCuadradoGold and GoldClutchActivo then
        BotonCuadradoGold.Text = "GOLD JUMP"
        BotonCuadradoGold.TextColor3 = Color3.fromRGB(218, 165, 32)
        BotonCuadradoGold.Active = true
    end
    if BotonCuadradoNormal and NormalClutchActivo then
        BotonCuadradoNormal.Text = "FAKE JUMP"
        BotonCuadradoNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
        BotonCuadradoNormal.Active = true
    end
end

LocalPlayer.CharacterAdded:Connect(AlReaparecerPersonaje)
if LocalPlayer.Character then task.spawn(AlReaparecerPersonaje) end

-- ============================================================================
-- 🔳 CONSTRUCTORES DE INTERFAZ FLOTANTE
-- ============================================================================
local function AplicarEstiloShoot(boton, cornerRadius, strokeColor)
    boton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    boton.BackgroundTransparency = 0.65
    boton.Font = Enum.Font.GothamBold
    boton.TextSize = 11
    boton.TextStrokeTransparency = 1
    boton.BorderSizePixel = 0
    boton.Active = true

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, cornerRadius)
    Corner.Parent = boton

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Color = strokeColor
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = boton
end

local function ConfigurarArrastre(boton, archivoConfig)
    local dragging, dragInput, dragStart, startPos
    boton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = boton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    guardarPosicionBoton(archivoConfig, boton.Position.X.Scale, boton.Position.X.Offset, boton.Position.Y.Scale, boton.Position.Y.Offset)
                end
            end)
        end
    end)
    boton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            boton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function CrearBotonFlotanteVoid()
    if CoreGui:FindFirstChild("KillerHub_VoidClutch") then CoreGui.KillerHub_VoidClutch:Destroy() end
    ScreenGuiVoid = Instance.new("ScreenGui", CoreGui); ScreenGuiVoid.Name = "KillerHub_VoidClutch"; ScreenGuiVoid.ResetOnSpawn = false
    local pos = cargarPosicionBoton(ARCHIVO_POS_BOMBA, 0.5, 0.7)
    BotonCuadradoVoid = Instance.new("TextButton", ScreenGuiVoid); BotonCuadradoVoid.Name = "VoidJumpButton"
    BotonCuadradoVoid.Size = UDim2.new(0, BotonSizeActual, 0, BotonSizeActual)
    BotonCuadradoVoid.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    BotonCuadradoVoid.Text = EnEnfriamiento and "..." or "BOMB JUMP"
    BotonCuadradoVoid.TextColor3 = Color3.fromRGB(255, 255, 255)
    AplicarEstiloShoot(BotonCuadradoVoid, 28, Color3.fromRGB(30, 15, 50))
    ConfigurarArrastre(BotonCuadradoVoid, ARCHIVO_POS_BOMBA)
    BotonCuadradoVoid.MouseButton1Click:Connect(EjecutarBombJump)
end

local function CrearBotonFlotanteGold()
    if CoreGui:FindFirstChild("KillerHub_GoldClutch") then CoreGui.KillerHub_GoldClutch:Destroy() end
    ScreenGuiGold = Instance.new("ScreenGui", CoreGui); ScreenGuiGold.Name = "KillerHub_GoldClutch"; ScreenGuiGold.ResetOnSpawn = false
    local pos = cargarPosicionBoton(ARCHIVO_POS_GOLD, 0.4, 0.7)
    BotonCuadradoGold = Instance.new("TextButton", ScreenGuiGold); BotonCuadradoGold.Name = "GoldJumpButton"
    BotonCuadradoGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual)
    BotonCuadradoGold.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    BotonCuadradoGold.Text = EnEnfriamientoGold and "..." or "GOLD JUMP"
    BotonCuadradoGold.TextColor3 = Color3.fromRGB(218, 165, 32)
    AplicarEstiloShoot(BotonCuadradoGold, 28, Color3.fromRGB(30, 15, 50))
    ConfigurarArrastre(BotonCuadradoGold, ARCHIVO_POS_GOLD)
    BotonCuadradoGold.MouseButton1Click:Connect(EjecutarGoldBombJump)
end

local function CrearBotonFlotanteNormal()
    if CoreGui:FindFirstChild("KillerHub_NormalClutch") then CoreGui.KillerHub_NormalClutch:Destroy() end
    ScreenGuiNormal = Instance.new("ScreenGui", CoreGui); ScreenGuiNormal.Name = "KillerHub_NormalClutch"; ScreenGuiNormal.ResetOnSpawn = false
    local pos = cargarPosicionBoton(ARCHIVO_POS_NORMAL, 0.6, 0.7)
    BotonCuadradoNormal = Instance.new("TextButton", ScreenGuiNormal); BotonCuadradoNormal.Name = "NormalJumpButton"
    BotonCuadradoNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual)
    BotonCuadradoNormal.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    BotonCuadradoNormal.Text = EnEnfriamientoNormal and "..." or "FAKE JUMP"
    BotonCuadradoNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
    AplicarEstiloShoot(BotonCuadradoNormal, 28, Color3.fromRGB(30, 15, 50))
    ConfigurarArrastre(BotonCuadradoNormal, ARCHIVO_POS_NORMAL)
    BotonCuadradoNormal.MouseButton1Click:Connect(EjecutarNormalBombJump)
end

local function DestruirBotonFlotanteVoid() if ScreenGuiVoid then ScreenGuiVoid:Destroy() ScreenGuiVoid = nil BotonCuadradoVoid = nil end end
local function DestruirBotonFlotanteGold() if ScreenGuiGold then ScreenGuiGold:Destroy() ScreenGuiGold = nil BotonCuadradoGold = nil end end
local function DestruirBotonFlotanteNormal() if ScreenGuiNormal then ScreenGuiNormal:Destroy() ScreenGuiNormal = nil BotonCuadradoNormal = nil end end

-- ============================================================================
-- 🛠️ ASIGNACIÓN DE COMPONENTES USANDO TU NUEVA API COMPATIBLE
-- ============================================================================

MMVTab:CreateSection("Custom Mod Mechanics")

MMVTab:CreateToggle("FakeBombClutchFlag", "Fake Bomb Clutch (Mod Edition)", function(estado) 
    FakeClutchActivo = estado
    if estado then CrearBotonFlotanteVoid() else DestruirBotonFlotanteVoid() end 
end)

MMVTab:CreateToggle("AutoEquipBombFlag", "Auto Equip Bomb", function(estado) 
    AutoEquipActivo = estado 
end)

MMVTab:CreateSlider("BombButtonSize", "Tamaño del Botón de la Bomba", 60, 200, function(valor) 
    BotonSizeActual = math.floor(valor)
    if BotonCuadradoVoid and FakeClutchActivo then 
        BotonCuadradoVoid.Size = UDim2.new(0, BotonSizeActual, 0, BotonSizeActual) 
    end 
end)

MMVTab:CreateSection("Gold Mod Mechanics")

MMVTab:CreateToggle("GoldBombClutchFlag", "Gold Bomb Clutch", function(estado) 
    GoldClutchActivo = estado
    if estado then CrearBotonFlotanteGold() else DestruirBotonFlotanteGold() end 
end)

MMVTab:CreateToggle("AutoEquipGoldFlag", "Auto Equip Gold Bomb", function(estado) 
    AutoEquipGoldActivo = estado 
end)

MMVTab:CreateSlider("GoldBombButtonSize", "Tamaño del Botón Gold", 60, 200, function(valor) 
    BotonSizeGoldActual = math.floor(valor)
    if BotonCuadradoGold and GoldClutchActivo then 
        BotonCuadradoGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual) 
    end 
end)

MMVTab:CreateSection("Normal Mod Mechanics")

MMVTab:CreateToggle("NormalBombClutchFlag", "Fake Bomb Clutch (Normal)", function(estado) 
    NormalClutchActivo = estado
    if estado then CrearBotonFlotanteNormal() else DestruirBotonFlotanteNormal() end 
end)

MMVTab:CreateToggle("AutoEquipNormalFlag", "Auto Equip Fake Bomb", function(estado) 
    AutoEquipNormalActivo = estado 
end)

MMVTab:CreateSlider("NormalBombButtonSize", "Tamaño del Botón Normal", 60, 200, function(valor) 
    BotonSizeNormalActual = math.floor(valor)
    if BotonCuadradoNormal and NormalClutchActivo then 
        BotonCuadradoNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual) 
    end 
end)

return KillerHub
