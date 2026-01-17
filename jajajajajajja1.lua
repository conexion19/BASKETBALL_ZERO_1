if not _G.NEXUS_LOADER_AUTH then
    error("Access denied: Script must be loaded through Nexus loader")
end
_G.NEXUS_LOADER_AUTH = nil

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/gffff"))() 
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/InterfaceManager/refs/heads/main/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "NEXUS",
    SubTitle = "Basketball Zero",
    Search = true,
    TabWidth = 130,
    Size = UDim2.fromOffset(620, 420), 
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftAlt,
    UserInfoSubtitle = _G.NEXUS_IS_PREMIUM and "Premium" or "Freekey"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main" }),
    Defense = Window:AddTab({ Title = "Defense" }),
    Movement = Window:AddTab({ Title = "Movement" }),
    Misc = Window:AddTab({ Title = "Misc" }),
    Visuals = Window:AddTab({ Title = "Visuals" }),
    Keybinds = Window:AddTab({ Title = "Keybinds" }),
    Settings = Window:AddTab({ Title = "Settings" })
}

local Options = Fluent.Options

local PerfectShotEnabled = false
local PerfectShotConnection = nil
local NoCooldownEnabled = false
local NoCooldownConnection = nil
local NoStunEnabled = false
local NoStunConnection = nil
local NoRagdollEnabled = false
local NoRagdollConnection = nil
local AutoBlockEnabled = false
local AutoBlockConnection = nil
local SpeedBoostEnabled = false
local SpeedBoostConnection = nil
local SpeedBoostValue = 15
local AutoPickupEnabled = false
local AutoPickupConnection = nil
local PickupRange = 30
local ShotPowerEnabled = false
local ShotPowerConnection = nil
local ShotPowerMultiplier = 1.5
local JumpBoostEnabled = false
local JumpBoostConnection = nil
local JumpBoostValue = 80
local InfinitePumpFakesEnabled = false
local BallController = nil
local OriginalGetMaxPumpFakes = nil
local FOVEnabled = false
local FOVConnection = nil
local FOVValue = 90
local AntiSlipEnabled = false
local AntiSlipConnection = nil
local ESPEnabled = false
local ESPConnection = nil
local ESPObjects = {}
local PlayerESPEnabled = true
local BallESPEnabled = true
local TeleportToBallKey = "T"

local MainSection = Tabs.Main:AddSection("Shooting")

local PerfectShotLastBallVelocity = Vector3.new()
local PerfectShotLastCorrectionTime = 0

local function GetCurrentBall()
    if ReplicatedStorage:FindFirstChild("GameValues") then
        local gv = ReplicatedStorage.GameValues
        if gv:FindFirstChild("Basketball") then
            return gv.Basketball.Value
        end
    end
    return Workspace:FindFirstChild("Basketball") or Workspace:FindFirstChild("Ball")
end

local function GetTargetHoop()
    if not LocalPlayer.Team or LocalPlayer.Team.Name == "Visitor" then return nil end
    local hoops = Workspace:FindFirstChild("Hoops")
    if hoops then
        local teamHoop = hoops:FindFirstChild(LocalPlayer.Team.Name)
        if teamHoop then
            return teamHoop:FindFirstChild("Hoop")
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not PerfectShotEnabled then return end
    local ball = GetCurrentBall()
    local hoop = GetTargetHoop()
    if not (ball and hoop) then return end
    
    local currentVel = ball.AssemblyLinearVelocity
    local velocityChange = (currentVel - PerfectShotLastBallVelocity).Magnitude
    local currentTime = tick()
    
    if velocityChange > 20 and currentVel.Magnitude > 15 and (currentTime - PerfectShotLastCorrectionTime) > 2 then
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local ballPos = ball.Position
        local hoopPos = hoop.Position
        local camera = workspace.CurrentCamera
        
        local cameraLookVector = camera.CFrame.LookVector
        local directionToHoop = (hoopPos - camera.CFrame.Position).Unit
        local dotProduct = cameraLookVector:Dot(directionToHoop)
        
        if dotProduct < 0.3 then
            PerfectShotLastBallVelocity = currentVel
            return
        end

        local distFromPlayer = (ballPos - root.Position).Magnitude
        if distFromPlayer > 20 then
            PerfectShotLastBallVelocity = currentVel
            return
        end
        
        PerfectShotLastCorrectionTime = currentTime
        local direction = (hoopPos - ballPos)
        local distance = direction.Magnitude
        local baseMultiplier = distance <= 30 and 1.35 or 0.75
        local distanceMultiplier = distance * (distance <= 30 and 0.0455 or 0.045)
        local totalMultiplier = baseMultiplier + distanceMultiplier
        local logMultiplier = math.log(totalMultiplier)
        local baseVelocity = direction / logMultiplier
        local gravityComp = workspace.Gravity * logMultiplier * 0.5
        local perfectVel = baseVelocity + Vector3.new(0, gravityComp, 0)
        ball.AssemblyLinearVelocity = perfectVel
    end
    PerfectShotLastBallVelocity = currentVel
end)

Tabs.Main:AddToggle("PerfectShot", {
    Title = "Perfect Shot",
    Description = "Automatically makes perfect shots",
    Default = false,
    Callback = function(Value)
        PerfectShotEnabled = Value
    end
})

local NoCooldownControllerInstance = nil

local function FindNoCooldownController()
    if NoCooldownControllerInstance then return NoCooldownControllerInstance end
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                if rawget(obj, "CDS") and rawget(obj, "Name") == "AbilityController" then
                    NoCooldownControllerInstance = obj
                    return
                end
            end
        end
    end)
    return NoCooldownControllerInstance
end

Tabs.Main:AddToggle("NoAbilityCooldown", {
    Title = "No Ability Cooldown",
    Description = "Remove cooldowns from abilities",
    Default = false,
    Callback = function(Value)
        NoCooldownEnabled = Value
        if Value then
            if NoCooldownConnection then
                NoCooldownConnection:Disconnect()
                NoCooldownConnection = nil
            end
            NoCooldownConnection = RunService.Heartbeat:Connect(function()
                if not NoCooldownEnabled then return end
                local instance = FindNoCooldownController()
                if instance and instance.CDS then
                    for i = 1, 4 do
                        if instance.CDS[i] then
                            instance.CDS[i] = 0
                        end
                    end
                end
            end)
        else
            if NoCooldownConnection then
                NoCooldownConnection:Disconnect()
                NoCooldownConnection = nil
            end
        end
    end
})

local DefenseSection = Tabs.Defense:AddSection("Protection")

Tabs.Defense:AddToggle("NoStun", {
    Title = "No Stun",
    Description = "Prevents stun effects",
    Default = false,
    Callback = function(Value)
        NoStunEnabled = Value
        if Value then
            local function RemoveStunEffects()
                if not NoStunEnabled then return end
                if LocalPlayer.Character then
                    for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                        if v.Name:lower():find("stun") or v.Name:lower():find("impact") or v.Name:lower():find("dizzy") then
                            pcall(function() v:Destroy() end)
                        end
                    end
                    if LocalPlayer.Character:GetAttribute("Stunned") then
                        LocalPlayer.Character:SetAttribute("Stunned", false)
                    end
                    if LocalPlayer.Character:GetAttribute("StunTime") then
                        LocalPlayer.Character:SetAttribute("StunTime", 0)
                    end
                end
            end
            NoStunConnection = RunService.Heartbeat:Connect(RemoveStunEffects)
        else
            if NoStunConnection then
                NoStunConnection:Disconnect()
            end
        end
    end
})

Tabs.Defense:AddToggle("NoRagdoll", {
    Title = "No Ragdoll",
    Description = "Prevents ragdoll effects",
    Default = false,
    Callback = function(Value)
        NoRagdollEnabled = Value
        if Value then
            local function RemoveRagdoll()
                if not NoRagdollEnabled then return end
                if not LocalPlayer.Character then return end
                local isRagdoll = LocalPlayer.Character:FindFirstChild("IsRagdoll")
                if isRagdoll and isRagdoll:IsA("BoolValue") then
                    if isRagdoll.Value == true then
                        isRagdoll.Value = false
                    end
                end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Anchored then
                    hrp.Anchored = false
                end
                if hrp and hrp.AssemblyLinearVelocity.Magnitude > 100 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    if humanoid.PlatformStand then
                        humanoid.PlatformStand = false
                    end
                    if humanoid.Sit then
                        humanoid.Sit = false
                    end
                end
            end
            NoRagdollConnection = RunService.Heartbeat:Connect(RemoveRagdoll)
        else
            if NoRagdollConnection then
                NoRagdollConnection:Disconnect()
            end
        end
    end
})

Tabs.Defense:AddToggle("AutoBlock", {
    Title = "Auto Block",
    Description = "Automatically blocks incoming shots",
    Default = false,
    Callback = function(Value)
        AutoBlockEnabled = Value
        if Value then
            local AUTO_BLOCK_RANGE = 18
            local COOLDOWN = 1.2
            local lastBlockTime = 0
            local isBlocking = false
            
            local function Jump()
                local char = LocalPlayer.Character
                if not char then return false end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid then return false end
                if not isBlocking and humanoid.FloorMaterial ~= Enum.Material.Air and tick() - lastBlockTime > COOLDOWN then
                    isBlocking = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastBlockTime = tick()
                    task.delay(0.6, function() isBlocking = false end)
                    return true
                end
            end
            
            AutoBlockConnection = RunService.Heartbeat:Connect(function()
                if not AutoBlockEnabled then return end
                local ball = Workspace:FindFirstChild("Basketball") or Workspace:FindFirstChild("Ball")
                if not ball then return end
                local char = LocalPlayer.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local nearestEnemy, nearestDist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearestEnemy = p
                            nearestDist = dist
                        end
                    end
                end
                if not nearestEnemy or nearestDist > AUTO_BLOCK_RANGE then return end
                local ballVel = ball.AssemblyLinearVelocity
                local distance = (ball.Position - root.Position).Magnitude
                if ballVel.Magnitude > 55 and distance <= AUTO_BLOCK_RANGE then
                    Jump()
                end
            end)
        else
            if AutoBlockConnection then
                AutoBlockConnection:Disconnect()
            end
        end
    end
})

local MovementSection = Tabs.Movement:AddSection("Speed")

Tabs.Movement:AddToggle("SpeedBoost", {
    Title = "Speed Boost",
    Description = "Increase movement speed",
    Default = false,
    Callback = function(Value)
        SpeedBoostEnabled = Value
        if Value then
            local movementController = nil
            local function GetMovementController()
                if movementController then return movementController end
                local success, controller = pcall(function()
                    local Knit = require(ReplicatedStorage.Packages.Knit)
                    return Knit.GetController("MovementController")
                end)
                if success and controller then
                    movementController = controller
                end
                return movementController
            end
            
            task.spawn(function()
                task.wait(2)
                GetMovementController()
            end)
            
            SpeedBoostConnection = RunService.Heartbeat:Connect(function()
                if not SpeedBoostEnabled then return end
                local controller = GetMovementController()
                if controller then
                    if controller.Boost ~= SpeedBoostValue then
                        controller.Boost = SpeedBoostValue
                    end
                end
            end)
        else
            if SpeedBoostConnection then
                SpeedBoostConnection:Disconnect()
            end
        end
    end
})

Tabs.Movement:AddSlider("SpeedBoostAmount", {
    Title = "Speed Boost Amount",
    Description = "Adjust speed boost value",
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        SpeedBoostValue = Value
    end
})

local MiscSection = Tabs.Misc:AddSection("Utilities")

local AutoPickupLastTeleport = 0
local AutoPickupBallController = nil

local function GetAutoPickupBallController()
    if AutoPickupBallController then return AutoPickupBallController end
    local success, controller = pcall(function()
        local Knit = require(ReplicatedStorage.Packages.Knit)
        return Knit.GetController("BallController")
    end)
    if success and controller then
        AutoPickupBallController = controller
    end
    return AutoPickupBallController
end

local function GetCurrentBall()
    local controller = GetAutoPickupBallController()
    if controller then
        local success, ball = pcall(function()
            if ReplicatedStorage:FindFirstChild("Basketball") then
                return ReplicatedStorage.Basketball.Value
            end
        end)
        if success and ball and ball.Parent then
            return ball
        end
    end
    return Workspace:FindFirstChild("Basketball")
end

local function HasBall()
    local controller = GetAutoPickupBallController()
    if controller then
        local success, result = pcall(function()
            return controller.HasBall == true or controller.CharValues and controller.CharValues.HasBall == true
        end)
        if success and result then
            return true
        end
    end
    if LocalPlayer.Character then
        local plrBall = LocalPlayer.Character:FindFirstChild("PlrBall")
        if plrBall and plrBall:IsA("Model") and plrBall:FindFirstChild("Basketball") then
            return true
        end
    end
    return false
end

local function SomeoneHasBall()
    local controller = GetAutoPickupBallController()
    if controller and controller.GetPlayerPossessingBall then
        local success, player = pcall(function()
            return controller:GetPlayerPossessingBall()
        end)
        if success and player then
            return true
        end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local plrBall = player.Character:FindFirstChild("PlrBall")
            if plrBall and plrBall:IsA("Model") and plrBall:FindFirstChild("Basketball") then
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    task.wait(2)
    GetAutoPickupBallController()
end)

RunService.Heartbeat:Connect(function()
    if not AutoPickupEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if HasBall() then return end
    if SomeoneHasBall() then return end
    
    local currentTime = tick()
    if currentTime - AutoPickupLastTeleport < 0.5 then return end
    
    local ball = GetCurrentBall()
    if not ball then return end
    
    local distance = (ball.Position - root.Position).Magnitude
    local range = tonumber(PickupRange) or 30
    if distance <= range and distance > 2 then
        pcall(function()
            local direction = (root.Position - ball.Position).Unit
            local targetPos = ball.Position + (direction * 2)
            root.CFrame = CFrame.new(targetPos)
            AutoPickupLastTeleport = currentTime
        end)
    end
end)

Tabs.Misc:AddToggle("AutoPickup", {
    Title = "Auto Pickup Ball",
    Description = "Automatically pickup the ball",
    Default = false,
    Callback = function(Value)
        AutoPickupEnabled = Value
    end
})

Tabs.Misc:AddSlider("PickupRange", {
    Title = "Pickup Range",
    Description = "Maximum distance to pickup ball",
    Default = 30,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        PickupRange = Value
    end
})

Tabs.Misc:AddToggle("ShotPowerModifier", {
    Title = "Shot Power Modifier",
    Description = "Modify shot power",
    Default = false,
    Callback = function(Value)
        ShotPowerEnabled = Value
        if Value then
            local lastShotTime = 0
            local SHOT_COOLDOWN = 0.5
            
            local function GetCurrentBall()
                if ReplicatedStorage:FindFirstChild("GameValues") then
                    local gv = ReplicatedStorage.GameValues
                    if gv:FindFirstChild("Basketball") then
                        return gv.Basketball.Value
                    end
                end
                return Workspace:FindFirstChild("Basketball") or Workspace:FindFirstChild("Ball")
            end
            
            ShotPowerConnection = RunService.Heartbeat:Connect(function()
                if not ShotPowerEnabled then return end
                local ball = GetCurrentBall()
                if not ball then return end
                
                local currentVel = ball.AssemblyLinearVelocity
                local currentTime = tick()
                
                if currentVel.Magnitude > 15 and (currentTime - lastShotTime) > SHOT_COOLDOWN then
                    lastShotTime = currentTime
                    ball.AssemblyLinearVelocity = currentVel * ShotPowerMultiplier
                end
            end)
        else
            if ShotPowerConnection then
                ShotPowerConnection:Disconnect()
            end
        end
    end
})

Tabs.Misc:AddSlider("ShotPowerAmount", {
    Title = "Shot Power Multiplier",
    Description = "Adjust shot power multiplier",
    Default = 1.5,
    Min = 0.5,
    Max = 3.0,
    Rounding = 1,
    Callback = function(Value)
        ShotPowerMultiplier = Value
    end
})

Tabs.Misc:AddButton({
    Title = "Teleport To Ball",
    Description = "Instantly teleport to the ball",
    Callback = function()
        local Character = LocalPlayer.Character
        if not Character then return end
        local Root = Character:FindFirstChild("HumanoidRootPart")
        if not Root then return end
        local Ball = Workspace:FindFirstChild("Basketball")
        if not Ball then
            if ReplicatedStorage:FindFirstChild("Basketball") then
                Ball = ReplicatedStorage.Basketball.Value
            end
        end
        if not Ball then
            Fluent:Notify({
                Title = "Teleport Failed",
                Content = "Ball not found",
                Duration = 3
            })
            return
        end
        local Direction = (Root.Position - Ball.Position).Unit
        local TargetPosition = Ball.Position + (Direction * 3)
        Root.CFrame = CFrame.new(TargetPosition)
        Fluent:Notify({
            Title = "Teleported",
            Content = "Teleported to ball!",
            Duration = 2
        })
    end
})

local MovementSection2 = Tabs.Movement:AddSection("Jump")

Tabs.Movement:AddToggle("JumpBoost", {
    Title = "Jump Boost",
    Description = "Increase jump power",
    Default = false,
    Callback = function(Value)
        JumpBoostEnabled = Value
        if Value then
            local function ApplyJumpBoost()
                local Character = LocalPlayer.Character
                if not Character then return end
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not Humanoid then return end
                pcall(function()
                    Humanoid.UseJumpPower = true
                    Humanoid.JumpPower = JumpBoostValue
                end)
            end
            JumpBoostConnection = RunService.Heartbeat:Connect(function()
                if not JumpBoostEnabled then return end
                ApplyJumpBoost()
            end)
        else
            if JumpBoostConnection then
                JumpBoostConnection:Disconnect()
            end
        end
    end
})

Tabs.Movement:AddSlider("JumpBoostAmount", {
    Title = "Jump Power",
    Description = "Adjust jump power value",
    Default = 80,
    Min = 50,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        JumpBoostValue = Value
    end
})

local DefenseSection2 = Tabs.Defense:AddSection("Stability")

Tabs.Defense:AddToggle("AntiSlip", {
    Title = "Anti Slip",
    Description = "Prevents slipping and falling",
    Default = false,
    Callback = function(Value)
        AntiSlipEnabled = Value
        if Value then
            local function ApplyAntiSlip()
                local Character = LocalPlayer.Character
                if not Character then return end
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not Humanoid then return end
                local Root = Character:FindFirstChild("HumanoidRootPart")
                if not Root then return end
                pcall(function()
                    if Humanoid:GetState() == Enum.HumanoidStateType.FallingDown or 
                       Humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    local ball = GetCurrentBall()
                    local isBallInMotion = false
                    if ball and PerfectShotEnabled then
                        local ballVel = ball.AssemblyLinearVelocity
                        if ballVel.Magnitude > 15 and (tick() - PerfectShotLastCorrectionTime) < 0.5 then
                            isBallInMotion = true
                        end
                    end
                    if not isBallInMotion and Root.AssemblyLinearVelocity.Y < -50 then
                        Root.AssemblyLinearVelocity = Vector3.new(
                            Root.AssemblyLinearVelocity.X,
                            0,
                            Root.AssemblyLinearVelocity.Z
                        )
                    end
                end)
            end
            AntiSlipConnection = RunService.Heartbeat:Connect(function()
                if not AntiSlipEnabled then return end
                ApplyAntiSlip()
            end)
        else
            if AntiSlipConnection then
                AntiSlipConnection:Disconnect()
            end
        end
    end
})

local MiscSection2 = Tabs.Misc:AddSection("Ball Control")

Tabs.Misc:AddToggle("InfinitePumpFakes", {
    Title = "Infinite Pump Fakes",
    Description = "Unlimited pump fakes",
    Default = false,
    Callback = function(Value)
        InfinitePumpFakesEnabled = Value
        if Value then
            task.spawn(function()
                local function GetBallController()
                    if BallController then return BallController end
                    local Success, Controller = pcall(function()
                        local Knit = require(ReplicatedStorage.Packages.Knit)
                        return Knit.GetController("BallController")
                    end)
                    if Success and Controller then
                        BallController = Controller
                        if Controller.GetMaxPumpFakes and not OriginalGetMaxPumpFakes then
                            OriginalGetMaxPumpFakes = Controller.GetMaxPumpFakes
                            Controller.GetMaxPumpFakes = function(Self)
                                return 999
                            end
                        end
                    end
                    return BallController
                end
                task.wait(2)
                GetBallController()
            end)
        else
            if BallController and OriginalGetMaxPumpFakes then
                BallController.GetMaxPumpFakes = OriginalGetMaxPumpFakes
                OriginalGetMaxPumpFakes = nil
            end
            BallController = nil
        end
    end
})

local VisualsSection = Tabs.Visuals:AddSection("Camera")

Tabs.Visuals:AddToggle("FOVChanger", {
    Title = "FOV Changer",
    Description = "Change field of view",
    Default = false,
    Callback = function(Value)
        FOVEnabled = Value
        if Value then
            local Camera = workspace.CurrentCamera
            FOVConnection = RunService.RenderStepped:Connect(function()
                if not FOVEnabled then return end
                if Camera.FieldOfView ~= FOVValue then
                    Camera.FieldOfView = FOVValue
                end
            end)
        else
            if FOVConnection then
                FOVConnection:Disconnect()
            end
            workspace.CurrentCamera.FieldOfView = 70
        end
    end
})

Tabs.Visuals:AddSlider("FOVAmount", {
    Title = "FOV Value",
    Description = "Adjust field of view",
    Default = 90,
    Min = 70,
    Max = 120,
    Rounding = 1,
    Callback = function(Value)
        FOVValue = Value
    end
})

local VisualsSection2 = Tabs.Visuals:AddSection("ESP")

local function CreateHighlight(Parent, Color)
    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color
    Highlight.OutlineColor = Color
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Parent
    return Highlight
end

local function CreateBillboard(Parent, Text, Color)
    local Billboard = Instance.new("BillboardGui")
    Billboard.Size = UDim2.new(0, 100, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Parent
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = Text
    TextLabel.TextColor3 = Color
    TextLabel.TextStrokeTransparency = 0
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 14
    TextLabel.Parent = Billboard
    return Billboard
end

local function AddPlayerESP(Player)
    if Player == LocalPlayer then return end
    if not Player.Character then return end
    local Character = Player.Character
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    if ESPObjects[Player] then
        for _, Obj in pairs(ESPObjects[Player]) do
            if Obj then Obj:Destroy() end
        end
    end
    ESPObjects[Player] = {}
    local Color = Player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    if PlayerESPEnabled then
        local Highlight = CreateHighlight(Character, Color)
        table.insert(ESPObjects[Player], Highlight)
        local Billboard = CreateBillboard(Root, Player.Name, Color)
        table.insert(ESPObjects[Player], Billboard)
    end
end

local BallESPDebugTime = 0

local function AddBallESP()
    if ESPObjects["Ball"] then
        for _, Obj in pairs(ESPObjects["Ball"]) do
            if Obj and Obj.Parent then Obj:Destroy() end
        end
        ESPObjects["Ball"] = nil
    end
    
    if not BallESPEnabled then
        return
    end
    
    local Ball = nil
    local BallLocation = "Not Found"
    
    local WorkspaceBall = Workspace:FindFirstChild("Basketball")
    
    if WorkspaceBall and WorkspaceBall.Transparency < 0.5 then
        Ball = WorkspaceBall
        BallLocation = "Workspace.Basketball (Free)"
    else
        for _, Player in pairs(Players:GetPlayers()) do
            if Player.Character then
                local PlrBall = Player.Character:FindFirstChild("PlrBall")
                if PlrBall then
                    local Anims = PlrBall:FindFirstChild("Anims")
                    if Anims then
                        local AnimBall = Anims:FindFirstChild("BALL")
                        if AnimBall then 
                            Ball = AnimBall
                            BallLocation = Player.Name .. ".PlrBall.Anims.BALL"
                            break 
                        end
                    end
                end
            end
        end
    end
    
    if not Ball then
        local BallValue = ReplicatedStorage:FindFirstChild("Basketball")
        if BallValue and BallValue:IsA("ObjectValue") and BallValue.Value then
            Ball = BallValue.Value
            BallLocation = "ReplicatedStorage.Basketball.Value (Fallback)"
        end
    end
    
    local currentTime = tick()
    if currentTime - BallESPDebugTime > 2 then
        BallESPDebugTime = currentTime
        print("[BALL ESP DEBUG] Location:", BallLocation)
        if Ball then
            print("[BALL ESP DEBUG] Ball Parent:", Ball.Parent and Ball.Parent.Name or "nil")
            print("[BALL ESP DEBUG] Ball Position:", Ball.Position)
        end
    end
    
    if not Ball or not Ball:IsA("BasePart") then 
        return 
    end
    
    ESPObjects["Ball"] = {}
    local Highlight = CreateHighlight(Ball, Color3.fromRGB(255, 165, 0))
    table.insert(ESPObjects["Ball"], Highlight)
    local Billboard = CreateBillboard(Ball, "BALL", Color3.fromRGB(255, 165, 0))
    table.insert(ESPObjects["Ball"], Billboard)
end

local function UpdateESP()
    if PlayerESPEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Character then
                pcall(function()
                    AddPlayerESP(Player)
                end)
            end
        end
    else
        for Player, Objects in pairs(ESPObjects) do
            if Player ~= "Ball" then
                for _, Obj in pairs(Objects) do
                    if Obj then Obj:Destroy() end
                end
                ESPObjects[Player] = nil
            end
        end
    end
    pcall(AddBallESP)
end

ESPConnection = RunService.Heartbeat:Connect(function()
    pcall(UpdateESP)
end)

Tabs.Visuals:AddToggle("PlayerESP", {
    Title = "Player ESP",
    Description = "Show player ESP",
    Default = false,
    Callback = function(Value)
        PlayerESPEnabled = Value
    end
})

Tabs.Visuals:AddToggle("BallESP", {
    Title = "Ball ESP",
    Description = "Show ball ESP",
    Default = false,
    Callback = function(Value)
        BallESPEnabled = Value
    end
})

local KeybindsSection = Tabs.Keybinds:AddSection("Quick Actions")

Tabs.Keybinds:AddKeybind("TeleportToBallKeybind", {
    Title = "Teleport To Ball",
    Mode = "Hold",
    Default = "T",
    Callback = function(Value)
        if Value then
            local Character = LocalPlayer.Character
            if not Character then return end
            local Root = Character:FindFirstChild("HumanoidRootPart")
            if not Root then return end
            local Ball = Workspace:FindFirstChild("Basketball")
            if not Ball then
                if ReplicatedStorage:FindFirstChild("Basketball") then
                    Ball = ReplicatedStorage.Basketball.Value
                end
            end
            if not Ball then return end
            local Direction = (Root.Position - Ball.Position).Unit
            local TargetPosition = Ball.Position + (Direction * 3)
            Root.CFrame = CFrame.new(TargetPosition)
        end
    end,
    ChangedCallback = function(New)
        TeleportToBallKey = New
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BasketballZeroHub")
SaveManager:SetFolder("BasketballZeroHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Basketball Zero Hub",
    Content = "Successfully loaded!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
