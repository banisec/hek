--[[
      This File has been automatically renamed by @vyxonq for better readability.
      (Always verify before using)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local isTouchEnabled = UserInputService.TouchEnabled
if isTouchEnabled then
    isTouchEnabled = UserInputService.MouseEnabled or "Mobile" or "PC"
else

end
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local CurrentCamera = workspace.CurrentCamera
local Config = {
    MAX_INVENTORY = 4,
    DANGER_DISTANCE = 20,
    CONTAINER_DISTANCE = 200,
    LOOT_DISTANCE = 300,
    ESCAPE_COOLDOWN = 1,
    DESCENT_TIME = 33,
    ELEVATOR_WAIT = 2,
    LOOT_WAIT = 1.5,
    INTERACT_DIST = 25
}
local Colors = {
    Background = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(10, 10, 15),
    Element = Color3.fromRGB(25, 25, 30),
    Hover = Color3.fromRGB(35, 35, 40),
    TextTitle = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(140, 140, 150),
    AccentStart = Color3.fromRGB(0, 200, 255),
    AccentEnd = Color3.fromRGB(255, 0, 255)
}
local isAiming = false
local currentHealth = 0
local maxHealth = 0
local isAttacking = false
local collectedItems = {}
local collectedContainers = {}
local collectedLoot = {}
local isFarming = false
local lootRadius = 16
local containerRadius = 16
local aimKeybind = Enum.KeyCode.LeftControl
local currentTarget = nil
local currentTargetDistance = nil
local enemyMonsterConfig = nil
local itemLootConfig = nil
local function loadEnemyMonsterConfig()

    local configModule = ReplicatedStorage:FindFirstChild("Config")
    local enemyMonsterModule = nil
    if configModule then
        enemyMonsterModule = configModule:FindFirstChild("enemy_monster")
        if enemyMonsterModule and enemyMonsterModule:IsA("ModuleScript") then
            local success, result = pcall(function()

                return require(enemyMonsterModule)
            end)
            if success then
                enemyMonsterConfig = result
                return true
            end
        end

    end
    enemyMonsterModule = false
    return enemyMonsterModule
end
local function isMoneyItem(instance)

    local attributes = instance:GetAttributes()
    local itemId = nil
    if attributes and attributes.id then
        itemId = attributes.id
    end
    if itemId and itemLootConfig and itemLootConfig[itemId] then
        local itemType = itemLootConfig[itemId].type
        local isMoney = nil
        if itemType ~= "Money" then
            isMoney = itemType == "MoneyChristmas"
        else

        end
        return isMoney
    end
    return false
end
(function()

    local configModule = ReplicatedStorage:FindFirstChild("Config")
    local itemLootModule = nil
    if configModule then
        itemLootModule = configModule:FindFirstChild("item_loot")
        if itemLootModule and itemLootModule:IsA("ModuleScript") then
            local success, result = pcall(function()

                return require(itemLootModule)
            end)
            if success then
                itemLootConfig = result
                return true
            end
        end

    end
    itemLootModule = false
    return itemLootModule
end)()
loadEnemyMonsterConfig()
local function getItemName(instance)

    local attributes = instance:GetAttributes()
    local itemId = nil
    if attributes and attributes.id then
        itemId = attributes.id
    end
    if itemId and itemLootConfig and itemLootConfig[itemId] and itemLootConfig[itemId].name then
        return itemLootConfig[itemId].name
    end
    if itemId then
        return "ID: " .. tostring(itemId)
    end
    return instance.Name
end
local function getEntityIdentifier(instance)

    return "entity_" .. instance.Name:sub(1, 8)
end
local function isSantaMonster(instance)

    local instanceName = instance.Name
    for _, santaName in ipairs({"Santa MK", "Santa Mk", "SANTA MK"}) do
        if instanceName:find(santaName) then
            return true
        end
    end
    return false
end
local utilityFunctions = {
    Tween = function(instance, properties, duration, easingStyle, easingDirection)

        local tweenService = TweenService
        local targetInstance = instance
        local tweenProperties = properties
        local tweenInfo = TweenInfo.new
        local tweenDuration = duration or 0.3
        local tweenEasingStyle = easingStyle or Enum.EasingStyle.Quart
        tweenService:Create(targetInstance, tweenInfo(tweenDuration, tweenEasingStyle, easingDirection or Enum.EasingDirection.Out), tweenProperties):Play()
    end,
    CreateCorner = function(parentInstance, cornerRadius)

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, cornerRadius)
        uiCorner.Parent = parentInstance
        return uiCorner
    end,
    CreateRipple = function(parentInstance)

        spawn(function()

            local rippleImageLabel = Instance.new("ImageLabel")
            rippleImageLabel.Name = "Ripple"
            rippleImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            rippleImageLabel.BackgroundTransparency = 1
            rippleImageLabel.BorderSizePixel = 0
            rippleImageLabel.Image = "rbxassetid://2708891598"
            rippleImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
            rippleImageLabel.ImageTransparency = 0.8
            rippleImageLabel.Parent = parentInstance
            local mouseX = Mouse.X - parentInstance.AbsolutePosition.X
            local mouseY = Mouse.Y - parentInstance.AbsolutePosition.Y
            rippleImageLabel.Position = UDim2.new(0, mouseX, 0, mouseY)
            rippleImageLabel.Size = UDim2.new(0, 0, 0, 0)
            local maxSize = math.max(parentInstance.AbsoluteSize.X, parentInstance.AbsoluteSize.Y) * 2
            utilityFunctions:Tween(rippleImageLabel, {
                Size = UDim2.new(0, maxSize, 0, maxSize),
                Position = UDim2.new(0, mouseX - maxSize / 2, 0, mouseY - maxSize / 2),
                ImageTransparency = 1
            }, 0.5)
            task.wait(0.5)
            rippleImageLabel:Destroy()
        end)
    end,
    MakeDraggable = function(draggableFrame, dragFrame, handleFrame)

        if not handleFrame then
            handleFrame = dragFrame
        end
        local isDragging = nil
        local startPosition = nil
        local startOffset = nil
        handleFrame.InputBegan:Connect(function(inputObject)

            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                startPosition = inputObject.Position
                startOffset = dragFrame.Position
                inputObject.Changed:Connect(function()

                    if inputObject.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                    end
                end)
            end
        end)
        handleFrame.InputChanged:Connect(function(inputObject)

            if inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType ==
                Enum.UserInputType.Touch then
                if not currentTarget then
                    currentTarget = inputObject
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(inputObject)

            if inputObject == currentTarget and isDragging then
                local delta = inputObject.Position - startPosition
                utilityFunctions:Tween(dragFrame, {
                    Position = UDim2.new(startOffset.X.Scale, startOffset.X.Offset + delta.X, startOffset.Y.Scale,
                        startOffset.Y.Offset + delta.Y)
                }, 0.05)
            end
        end)
    end
}
(function()

    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Size = 0
    blurEffect.Parent = Lighting
    utilityFunctions:Tween(blurEffect, {
        Size = 24
    }, 0.5)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RuneX_Loader"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.BackgroundTransparency = 1
    backgroundFrame.Parent = mainFrame
    utilityFunctions:CreateCorner(backgroundFrame, 100)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 4
    uiStroke.Parent = backgroundFrame
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Colors.AccentStart),
                                         ColorSequenceKeypoint.new(1, Colors.AccentEnd)})
    uiGradient.Parent = uiStroke
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "R U N E X"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Colors.TextTitle
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    titleLabel.Parent = mainFrame
    utilityFunctions:Tween(titleLabel, {
        TextTransparency = 0
    }, 1)
    local isRotating = true
    task.spawn(function()

        while isRotating do
            local parent = mainFrame.Parent
            if parent then
                uiGradient.Rotation = uiGradient.Rotation + 5
                task.wait(0.01)
            else
                break
            end
        end
    end)
    task.wait(2.5)
    isRotating = false
    utilityFunctions:Tween(blurEffect, {
        Size = 0
    }, 0.5)
    utilityFunctions:Tween(mainFrame, {
        BackgroundTransparency = 1
    }, 0.5)
    utilityFunctions:Tween(titleLabel, {
        TextTransparency = 1
    }, 0.5)
    utilityFunctions:Tween(uiStroke, {
        Transparency = 1
    }, 0.5)
    task.wait(0.5)
    screenGui:Destroy()
    blurEffect:Destroy()
end)()
local overlayScreenGui = Instance.new("ScreenGui")
overlayScreenGui.Name = "RuneX_Overlay"
overlayScreenGui.ResetOnSpawn = false
overlayScreenGui.IgnoreGuiInset = true
if LocalPlayer.PlayerGui:FindFirstChild("RuneX_Overlay") then
    LocalPlayer.PlayerGui.RuneX_Overlay:Destroy()
end
overlayScreenGui.Parent = LocalPlayer.PlayerGui
local topBarFrame = Instance.new("Frame")
topBarFrame.AnchorPoint = Vector2.new(0.5, 0)
topBarFrame.Size = UDim2.new(0, 220, 0, 30)
topBarFrame.Position = UDim2.new(0.5, 0, 0, 5)
topBarFrame.BackgroundColor3 = Colors.Background
topBarFrame.Parent = overlayScreenGui
utilityFunctions:CreateCorner(topBarFrame, 6)
local topBarStroke = Instance.new("UIStroke")
topBarStroke.Color = Colors.AccentStart
topBarStroke.Thickness = 1
topBarStroke.Parent = topBarFrame
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Colors.TextTitle
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 12
statsLabel.Parent = topBarFrame
task.spawn(function()

    while overlayScreenGui.Parent do
        local physicsFps = math.floor(workspace:GetRealPhysicsFPS())
        local ping = 0
        pcall(function()

            ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():match(
                "%d+"))
        end)
        statsLabel.Text = string.format("RuneX | FPS: %d | Ping: %dms", physicsFps, ping)
        task.wait(1)

    end
end)
local notificationFrame = Instance.new("Frame")
notificationFrame.AnchorPoint = Vector2.new(1, 0)
notificationFrame.Size = UDim2.new(0, 300, 1, 0)
notificationFrame.Position = UDim2.new(1, -20, 0, 50)
notificationFrame.BackgroundTransparency = 1
notificationFrame.Parent = overlayScreenGui
local notificationLayout = Instance.new("UIListLayout")
notificationLayout.Padding = UDim.new(0, 10)
notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notificationLayout.Parent = notificationFrame
function utilityFunctions.Notify(title, message, duration, type)

    local notificationBox = Instance.new("Frame")
    notificationBox.Size = UDim2.new(0, 280, 0, 60)
    notificationBox.BackgroundColor3 = Colors.Element
    notificationBox.BackgroundTransparency = 0.1
    notificationBox.Parent = notificationFrame
    utilityFunctions:CreateCorner(notificationBox, 8)
    local notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Colors.AccentStart
    notificationStroke.Transparency = 0.5
    notificationStroke.Parent = notificationBox
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Colors.AccentStart
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notificationBox
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextColor3 = Colors.TextDim
    messageLabel.Position = UDim2.new(0, 15, 0, 28)
    messageLabel.Size = UDim2.new(1, -20, 0, 25)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.Parent = notificationBox
    notificationBox.Position = UDim2.new(1, 100, 0, 0)
    utilityFunctions:Tween(notificationBox, {
        Position = UDim2.new(0, 0, 0, 0)
    }, 0.5, Enum.EasingStyle.Back)
    task.delay(duration or 3, function()

        utilityFunctions:Tween(notificationBox, {
            Position = UDim2.new(1, 50, 0, 0),
            BackgroundTransparency = 1
        }, 0.5)
        task.wait(0.5)
        notificationBox:Destroy()
    end)
end
local function sendKeypress(key)

    pcall(function()

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end
local function sendClick()

    pcall(function()

        local mouseLocation = UserInputService:GetMouseLocation()
        VirtualInputManager:SendMouseButtonEvent(mouseLocation.X, mouseLocation.Y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(mouseLocation.X, mouseLocation.Y, 0, false, game, 0)
    end)
end
local function setPlayerCFrame(cframe)

    if HumanoidRootPart then
        HumanoidRootPart.CFrame = cframe
    end
end
local function lookAt(position)

    CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, position)
end
local function lookAtRootPart()

    CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, HumanoidRootPart.Position + Vector3.new(0, -5, 0))
end
local function findNearestDanger()

    local gameSystem = workspace:FindFirstChild("GameSystem")
    if not gameSystem then
        return false
    end
    local monstersFolder = gameSystem:FindFirstChild("Monsters")
    if not monstersFolder then
        return false
    end
    for _, monsterModel in pairs(monstersFolder:GetChildren()) do
        if monsterModel:IsA("Model") then
            local humanoid = monsterModel:FindFirstChildOfClass("Humanoid")
            if humanoid and 0 < humanoid.Health and not isSantaMonster(monsterModel) then
                local rootPart = monsterModel.PrimaryPart or monsterModel:FindFirstChild("HumanoidRootPart") or
                                   monsterModel:FindFirstChildWhichIsA("BasePart")
                if rootPart then
                    local distance = (HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if distance <= Config.DANGER_DISTANCE then
                        return true, monsterModel, distance
                    end
                end
            end
        end
    end
    return false, nil, nil
end
local function collectAllLoot()

    local function updateCollectedLoot()

        local gameSystem = workspace:FindFirstChild("GameSystem")
        if not gameSystem then
            return
        end
        local lootsFolder = gameSystem:FindFirstChild("Loots")
        if not lootsFolder then
            return
        end
        local worldFolder = lootsFolder:FindFirstChild("World")
        if not worldFolder then
            return
        end
        for _, lootObject in pairs(worldFolder:GetChildren()) do
            local lootPart = nil
            if lootObject:IsA("BasePart") then
                lootPart = lootObject
            elseif lootObject:IsA("Model") then
                lootPart = lootObject.PrimaryPart or lootObject:FindFirstChildWhichIsA("BasePart")
            end
            if lootPart and (HumanoidRootPart.Position - lootPart.Position).Magnitude <= 20 then
                collectedLoot[lootObject.Name] = true
            end
        end
    end
    for _, key in ipairs({"One", "Two", "Three", "Four"}) do
        sendKeypress(key)
        task.wait(0.2)
        sendClick()
        task.wait(0.3)
        sendKeypress("G")
        task.wait(0.2)
        updateCollectedLoot()
    end
end
local function interactWithElevator(shouldDescend)

    local gameSystem = workspace:FindFirstChild("GameSystem")
    if not gameSystem then
        return false
    end
    local lootsFolder = gameSystem:FindFirstChild("Loots")
    if not lootsFolder then
        return false
    end
    local elevatorCollectPart = lootsFolder:FindFirstChild("ElevatorCollect")
    if not elevatorCollectPart then
        currentHealth = 0
        return false
    end
    local elevatorPositionPart = nil
    if elevatorCollectPart:IsA("Model") then
        elevatorPositionPart = elevatorCollectPart.PrimaryPart or elevatorCollectPart:FindFirstChildWhichIsA("BasePart")
    elseif elevatorCollectPart:IsA("Folder") then
        elevatorPositionPart = elevatorCollectPart:FindFirstChildWhichIsA("BasePart", true)
    elseif elevatorCollectPart:IsA("BasePart") then
        elevatorPositionPart = elevatorCollectPart
    end
    if not elevatorPositionPart then
        currentHealth = 0
        return false
    end
    setPlayerCFrame(CFrame.new(elevatorPositionPart.Position) * CFrame.new(0, 5, 0))
    task.wait(2)
    local soldItemsCount = currentHealth
    currentHealth = 0
    utilityFunctions:Notify("Farm", "Items Sold", 2, "Success")
    task.wait(0.5)
    if soldItemsCount > 0 then
        utilityFunctions:Notify("Farm", "Clearing unwanted items...", 2, "Warning")
        collectAllLoot()
        task.wait(0.5)
    end
    if shouldDescend then
        local elevatorModel = workspace:FindFirstChild("  梯")
        if elevatorModel then
            local continuePart = elevatorModel:FindFirstChild("ContinuePart", true)
            if continuePart then
                local interactablePart = continuePart:FindFirstChild("Interactable")
                if interactablePart and interactablePart:IsA("BasePart") then
                    setPlayerCFrame(CFrame.new(interactablePart.Position) * CFrame.new(0, 3, 5))
                    task.wait(60)
                    for i = 1, 3, 1 do
                        lookAt(interactablePart.Position)
                        task.wait(0.2)
                        sendKeypress("E")
                        task.wait(0.3)
                    end
                    isFarming = true
                    utilityFunctions:Notify("Elevator", "Going Deep...", 2, "Info")
                    task.wait(Config.DESCENT_TIME)
                    isFarming = false
                end
            end
        end
    end
    return true
end
local function findContainers()

    local containers = {}
    local gameSystem = workspace:FindFirstChild("GameSystem")
    if not gameSystem then
        return containers
    end
    local interactiveItemFolder = gameSystem:FindFirstChild("InteractiveItem")
    if not interactiveItemFolder then
        return containers
    end
    for _, containerModel in pairs(interactiveItemFolder:GetChildren()) do
        if containerModel:IsA("Model") and not collectedContainers[containerModel] then
            local rootPart = containerModel.PrimaryPart or containerModel:FindFirstChildWhichIsA("BasePart")
            if rootPart then
                local distance = (HumanoidRootPart.Position - rootPart.Position).Magnitude
                if distance <= Config.CONTAINER_DISTANCE then
                    table.insert(containers, {
                        Model = containerModel,
                        Name = containerModel.Name,
                        Position = rootPart.Position,
                        Distance = distance
                    })
                end
            end
        end
    end
    table.sort(containers, function(a, b)

        return a.Distance < b.Distance
    end)
    return containers
end
local function interactWithContainer(container)

    setPlayerCFrame(CFrame.new(container.Position) * CFrame.new(0, 3, 0))
    task.wait(0.15)
    sendKeypress("E")
    task.wait(0.1)
    collectedContainers[container.Model] = true
    return true
end
local function findLoot()

    local lootItems = {}
    local gameSystem = workspace:FindFirstChild("GameSystem")
    if not gameSystem then
        return lootItems
    end
    local lootsFolder = gameSystem:FindFirstChild("Loots")
    if not lootsFolder then
        return lootItems
    end
    local worldFolder = lootsFolder:FindFirstChild("World")
    if not worldFolder then
        return lootItems
    end
    for _, lootObject in pairs(worldFolder:GetChildren()) do
        if not collectedLoot[lootObject] then
            local lootPart = nil
            if lootObject:IsA("BasePart") then
                lootPart = lootObject
            elseif lootObject:IsA("Model") then
                lootPart = lootObject.PrimaryPart or lootObject:FindFirstChildWhichIsA("BasePart")
            end
            if lootPart then
                local distance = (HumanoidRootPart.Position - lootPart.Position).Magnitude
                if distance <= Config.LOOT_DISTANCE then
                    table.insert(lootItems, {
                        Object = lootObject,
                        Name = lootObject.Name,
                        Position = lootPart.Position,
                        Distance = distance
                    })
                end
            end
        end
    end
    table.sort(lootItems, function(a, b)

        return a.Distance < b.Distance
    end)
    return lootItems
end
table.sort(sortedObjects, function(objectA, objectB)

        return objectA.Distance < objectB.Distance
    end)
    return sortedObjects
end
local function processMonster(monsterObject)

    if processedMonsters[monsterObject.Name] then
        activeObjects[monsterObject.Object] = true
        return false
    end
    playAttackAnimation()
    setPosition(CFrame.new(monsterObject.Position) * CFrame.new(0, 2, 0))
    task.wait(0.2)
    sendKey("E")
    task.wait(0.1)
    sendKey("E")
    task.wait(0.2)
    activeObjects[monsterObject.Object] = true
    if not isTargetValid(monsterObject.Object) then
        targetCount = targetCount + 1
    end
    return true
end
spawn(function()

    while true do
        local shouldBreakLoop = false
        local function stopLoop()

            shouldBreakLoop = true
        end
        task.wait(0.5)
        if isEnabled then
            local detectedObject = firstDetectedObject
            if not detectedObject then
                local success, result, monsterPosition = findFirstMonster()
                if success then
                    local currentTime = tick()
                    if settings.ESCAPE_COOLDOWN < currentTime - lastMonsterDetectedTime then
                        notificationManager:Notify("Warning", "Monster Detected!", 2, "Error")
                        setAimbotEnabled(false)
                        lastMonsterDetectedTime = currentTime
                        task.wait(1)
                    end
                end
                if isEnabled then
                    if settings.MAX_INVENTORY <= targetCount then
                        setAimbotEnabled(false)
                    end
                    if isEnabled then
                        local nearbyItems = getNearbyItems()
                        if #nearbyItems > 0 then
                            for i = 1, math.min(3, #nearbyItems), 1 do
                                if not isEnabled then
                                    stopLoop()
                                end
                                collectItem(nearbyItems[i])
                            end
                            task.wait(0.5)
                        end
                        if isEnabled then
                            local nearbyMonsters = getNearbyMonsters()
                            if #nearbyMonsters > 0 then
                                for index, monster in ipairs(nearbyMonsters) do
                                    if not isEnabled then
                                        stopLoop()
                                    end
                                    if index <= 10 then
                                        processMonster(monster)
                                        if settings.MAX_INVENTORY <= targetCount then
                                            setAimbotEnabled(false)
                                        end
                                    end
                                end
                            elseif targetCount > 0 then
                                setAimbotEnabled(true)
                            end
                        end
                    end
                end
            end
        end
        if shouldBreakLoop then

            break
        else

        end
    end
end)
spawn(function()

    while true do
        task.wait(0.1)
        if isPlayerMoving then
            local playerCharacter = localPlayerCharacter
            if playerCharacter then
                playerCharacter = playerCharacter:FindFirstChildOfClass("Humanoid")
                if playerCharacter then
                    playerCharacter.WalkSpeed = playerWalkSpeed
                end
            end
        end
    end
end)
local function createEspLabel(objectId, objectName, color, isVisible)

    local espName = "ESP_" .. tostring(objectId)
    if espContainer:FindFirstChild(espName) then
        return
    end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = espName
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = espContainer
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    local sizeForNameLabel = UDim2.new(1, 0, 0, 20)
    nameLabel.Size = sizeForNameLabel
    nameLabel.BackgroundTransparency = 1
    if isVisible then
        nameLabel.Text = objectName or ""
    else

    end
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Visible = isVisible
    nameLabel.Parent = billboardGui
    sizeForNameLabel = Instance.new("TextLabel")
    sizeForNameLabel.Name = "DistLabel"
    local sizeForDistLabel = UDim2.new(1, 0, 0, 15)
    sizeForNameLabel.Size = sizeForDistLabel
    if isVisible then
        sizeForDistLabel = UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0)
    else

    end
    sizeForNameLabel.Position = sizeForDistLabel
    sizeForNameLabel.BackgroundTransparency = 1
    sizeForNameLabel.Text = "0m"
    sizeForNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeForNameLabel.TextStrokeTransparency = 0.5
    sizeForNameLabel.Font = Enum.Font.Gotham
    sizeForNameLabel.TextSize = 12
    sizeForNameLabel.Parent = billboardGui
    sizeForDistLabel = Instance.new("Frame")
    sizeForDistLabel.Size = UDim2.new(1, 0, 1, 0)
    sizeForDistLabel.BackgroundTransparency = 1
    sizeForDistLabel.Parent = billboardGui
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0.3
    uiStroke.Parent = sizeForDistLabel
    guiHelper:CreateCorner(sizeForDistLabel, 6)
    return billboardGui, sizeForNameLabel
end
spawn(function()

    while true do
        task.wait(0.5)
        localPlayerCharacter = Players.LocalPlayer.Character
        if localPlayerCharacter then
            local humanoidRootPart = localPlayerCharacter:FindFirstChild("HumanoidRootPart")
            rootPart = humanoidRootPart
        end
        local currentRootPart = rootPart
        local targetObject = nil
        local distanceLabel = nil
        if currentRootPart then
            currentRootPart = pairs
            for _, billboardGui in pairs(espContainer:GetChildren()) do
                targetObject = billboardGui.Adornee
                if targetObject then
                    distanceLabel = billboardGui:FindFirstChild("DistLabel")
                    if distanceLabel then
                        distanceLabel = distanceLabel:IsA("TextLabel")
                        if distanceLabel then
                            distanceLabel = billboardGui.Adornee
                            if distanceLabel then
                                local success, magnitude = pcall(function()

                                    return (rootPart.Position - distanceLabel.Position).Magnitude
                                end)
                                if success and magnitude then
                                    distanceLabel.Text = math.floor(magnitude) .. "m"
                                end
                            end

                        end
                    end
                end
            end
        end
        currentRootPart = pairs
        for _, billboardGui in pairs(espContainer:GetChildren()) do
            local objectName = billboardGui.Name:gsub("ESP_", "")
            local foundInWorkspace = false
            for _, descendant in pairs(workspace:GetDescendants()) do
                if tostring(descendant) == objectName then
                    foundInWorkspace = true
                    break
                end
            end
            if not foundInWorkspace then
                billboardGui:Destroy()
            end
        end
        currentRootPart = isMonsterEspEnabled
        if currentRootPart then
            local gameSystem = workspace:FindFirstChild("GameSystem")
            if gameSystem and gameSystem:FindFirstChild("Monsters") then
                for _, monster in pairs(gameSystem.Monsters:GetChildren()) do
                    local isModel = monster:IsA("Model")
                    if isModel then
                        local humanoid = monster:FindFirstChildOfClass("Humanoid")
                        if humanoid and 0 < humanoid.Health then
                            local primaryPart = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
                            if primaryPart then
                                local monsterName = getMonsterName(monster)
                                local isHostile = isMonsterHostile(monster)
                                local monsterColor = isHostile and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                                local espGui, distLabel = createEspLabel(monster, monsterName, monsterColor, true)
                                if espGui then
                                    espGui.Adornee = primaryPart
                                end
                            end
                        end
                    end
                end
            end
        else
            currentRootPart = pairs
            for _, billboardGui in pairs(espContainer:GetChildren()) do
                local nameContainsEsp = billboardGui.Name:find("ESP_")
                if nameContainsEsp then
                    targetObject = billboardGui.Adornee
                    if targetObject then
                        local parentName = billboardGui.Adornee.Parent.Parent.Name
                        if parentName == "Monsters" then
                            billboardGui:Destroy()
                        end
                    end
                end
            end
        end
        currentRootPart = isLootEspEnabled
        if currentRootPart then
            local gameSystem = workspace:FindFirstChild("GameSystem")
            if gameSystem and gameSystem:FindFirstChild("Loots") and gameSystem.Loots:FindFirstChild("World") then
                for _, loot in pairs(gameSystem.Loots.World:GetChildren()) do
                    local lootPart = nil
                    if loot:IsA("BasePart") then
                        lootPart = loot
                    elseif loot:IsA("Model") then
                        lootPart = loot.PrimaryPart
                    end
                    if lootPart then
                        local lootName = getLootName(loot)
                        local espGui, distLabel = createEspLabel(loot, lootName, Color3.fromRGB(0, 255, 0), true)
                        if espGui then
                            espGui.Adornee = lootPart
                        end
                    end
                end
            end
        else
            currentRootPart = pairs
            for _, billboardGui in pairs(espContainer:GetChildren()) do
                local nameContainsEsp = billboardGui.Name:find("ESP_")
                if nameContainsEsp then
                    targetObject = billboardGui.Adornee
                    if targetObject then
                        local isMonster = false
                        local checkParent = pcall(function()

                            if billboardGui.Adornee.Parent and billboardGui.Adornee.Parent.Parent then
                                isMonster = billboardGui.Adornee.Parent.Parent.Name == "Monsters"
                            end
                        end)
                        if not isMonster then
                            billboardGui:Destroy()
                        end

                    end
                end

            end
        end
        currentRootPart = isInteractiveItemEspEnabled
        if currentRootPart then
            local gameSystem = workspace:FindFirstChild("GameSystem")
            if gameSystem and gameSystem:FindFirstChild("InteractiveItem") then
                for _, item in pairs(gameSystem.InteractiveItem:GetChildren()) do
                    local itemPart = item:IsA("Model")
                    if itemPart then
                        itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if itemPart then
                            local itemName = item.Name:match("^(.-)_?%d*$") or item.Name
                            local espGui, distLabel = createEspLabel(item, itemName, Color3.fromRGB(255, 255, 0), true)
                            if espGui then
                                espGui.Adornee = itemPart
                            end
                        end
                    end
                end
            end
        else
            currentRootPart = pairs
            for _, billboardGui in pairs(espContainer:GetChildren()) do
                local name = billboardGui.Name
                name = name:find("ESP_")
                if name then
                    targetObject = billboardGui.Adornee
                    if targetObject then
                        local isInteractive = false
                        local checkParent = pcall(function()

                            if billboardGui.Adornee.Parent and billboardGui.Adornee.Parent.Parent then
                                isInteractive = billboardGui.Adornee.Parent.Parent.Name == "InteractiveItem"
                            end
                        end)
                        if isInteractive then
                            billboardGui:Destroy()
                        end

                    end
                end

            end
        end
    end
end)
function guiHelper.Window(windowTitle)

    local windowElements = {}
    local windowWidth = 600
    if deviceType == "Mobile" then
        windowWidth = 700
    else

    end
    local windowHeight = 320
    if deviceType == "Mobile" then
        windowHeight = 450
    else

    end
    if deviceType == "Mobile" and workspace.CurrentCamera.ViewportSize.X < 600 then
        windowWidth = workspace.CurrentCamera.ViewportSize.X - 20
    end
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "RuneXFrame"
    mainFrame.Size = UDim2.new(0, windowWidth, 0, windowHeight)
    mainFrame.Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = guiContainer
    guiHelper:CreateCorner(mainFrame, 12)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Parent = mainFrame
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, theme.AccentStart),
                                         ColorSequenceKeypoint.new(0.5, theme.AccentEnd),
                                         ColorSequenceKeypoint.new(1, theme.AccentStart)})
    uiGradient.Parent = uiStroke
    spawn(function()

        while mainFrame.Parent do
            uiGradient.Rotation = uiGradient.Rotation + 1
            local currentRotation = uiGradient.Rotation
            if currentRotation >= 360 then
                currentRotation = uiGradient
                currentRotation.Rotation = 0
            end
            task.wait(0.02)
        end
    end)
    guiHelper:MakeDraggable(mainFrame)
    local sidebarWidth = 180
    local sidebarFrame = Instance.new("Frame")
    sidebarFrame.Size = UDim2.new(0, sidebarWidth, 1, 0)
    sidebarFrame.BackgroundColor3 = theme.Sidebar
    sidebarFrame.Parent = mainFrame
    guiHelper:CreateCorner(sidebarFrame, 12)
    local profileFrame = Instance.new("Frame")
    profileFrame.Size = UDim2.new(1, 0, 0, 90)
    profileFrame.BackgroundTransparency = 1
    profileFrame.Parent = sidebarFrame
    local profilePicture = Instance.new("ImageLabel")
    profilePicture.Size = UDim2.new(0, 35, 0, 35)
    profilePicture.Position = UDim2.new(0, 10, 0, 25)
    profilePicture.BackgroundColor3 = theme.Element
    profilePicture.Parent = profileFrame
    guiHelper:CreateCorner(profilePicture, 20)
    spawn(function()

        profilePicture.Image = userThumbnail:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100)
    end)
    local displayNameLabel = Instance.new("TextLabel")
    displayNameLabel.Text = localPlayer.DisplayName
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextSize = 13
    displayNameLabel.TextColor3 = theme.TextTitle
    displayNameLabel.Position = UDim2.new(0, 55, 0, 15)
    displayNameLabel.Size = UDim2.new(1, -60, 0, 15)
    displayNameLabel.BackgroundTransparency = 1
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    displayNameLabel.Parent = profileFrame
    local clientNameLabel = Instance.new("TextLabel")
    clientNameLabel.Text = "RuneX"
    clientNameLabel.Font = Enum.Font.GothamBlack
    clientNameLabel.TextSize = 14
    clientNameLabel.TextColor3 = theme.AccentStart
    clientNameLabel.Position = UDim2.new(0, 55, 0, 32)
    clientNameLabel.Size = UDim2.new(1, -60, 0, 15)
    clientNameLabel.BackgroundTransparency = 1
    clientNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    clientNameLabel.Parent = profileFrame
    local tabListFrame = Instance.new("ScrollingFrame")
    tabListFrame.Size = UDim2.new(1, 0, 1, -140)
    tabListFrame.Position = UDim2.new(0, 0, 0, 100)
    tabListFrame.BackgroundTransparency = 1
    tabListFrame.ScrollBarThickness = 2
    tabListFrame.Parent = sidebarFrame
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Padding = UDim.new(0, 5)
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabListLayout.Parent = tabListFrame
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -sidebarWidth, 1, 0)
    contentFrame.Position = UDim2.new(0, sidebarWidth, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    local searchBarFrame = Instance.new("Frame")
    searchBarFrame.Size = UDim2.new(1, -20, 0, 40)
    searchBarFrame.Position = UDim2.new(0, 10, 0, 15)
    searchBarFrame.BackgroundColor3 = theme.Element
    searchBarFrame.Parent = contentFrame
    guiHelper:CreateCorner(searchBarFrame, 8)
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Image = "rbxassetid://3926305904"
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -10)
    searchIcon.ImageColor3 = theme.TextDim
    searchIcon.BackgroundTransparency = 1
    searchIcon.Parent = searchBarFrame
    local searchInput = Instance.new("TextBox")
    searchInput.Size = UDim2.new(1, -40, 1, 0)
    searchInput.Position = UDim2.new(0, 40, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Text = ""
    searchInput.PlaceholderText = "Search features..."
    searchInput.PlaceholderColor3 = theme.TextDim
    searchInput.TextColor3 = theme.TextTitle
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 14
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.Parent = searchBarFrame
    local searchResultsFrame = Instance.new("Frame")
    searchResultsFrame.Size = UDim2.new(1, 0, 1, -70)
    searchResultsFrame.Position = UDim2.new(0, 0, 0, 70)
    searchResultsFrame.BackgroundTransparency = 1
    searchResultsFrame.ClipsDescendants = true
    searchResultsFrame.Parent = contentFrame
    local featureList = {}
    local searchResultsScrollingFrame = Instance.new("ScrollingFrame")
    searchResultsScrollingFrame.Name = "SearchResults"
    searchResultsScrollingFrame.Size = UDim2.new(1, -20, 1, 0)
    searchResultsScrollingFrame.Position = UDim2.new(0, 10, 0, 0)
    searchResultsScrollingFrame.BackgroundTransparency = 1
    searchResultsScrollingFrame.Visible = false
    searchResultsScrollingFrame.ScrollBarThickness = 2
    searchResultsScrollingFrame.Parent = searchResultsFrame
    local searchResultsLayout = Instance.new("UIListLayout")
    searchResultsLayout.Padding = UDim.new(0, 8)
    searchResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    searchResultsLayout.Parent = searchResultsScrollingFrame
    local pageList = {}
    local currentPage = nil
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()

        local searchText = searchInput.Text:lower()
        if searchText == "" then
            searchResultsScrollingFrame.Visible = false
            for _, featureData in ipairs(featureList) do
                featureData.Frame.Parent = featureData.OriginalParent
                featureData.Frame.Visible = true
            end
            for _, pageData in pairs(pageList) do
                pageData.Page.Visible = pageData == currentPage
            end
        else
            searchResultsScrollingFrame.Visible = true
            for _, pageData in pairs(pageList) do
                pageData.Page.Visible = false
            end
            for _, featureData in ipairs(featureList) do
                if featureData.Text:find(searchText) then
                    featureData.Frame.Parent = searchResultsScrollingFrame
                    featureData.Frame.Visible = true
                else
                    featureData.Frame.Parent = featureData.OriginalParent
                end
            end
        end
    end)
    local isFirstTab = true
    function windowElements.Tab(tabName, tabContent)

        local tabData = {}
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0.9, 0, 0, 40)
        tabButton.BackgroundColor3 = theme.Background
        tabButton.BackgroundTransparency = 1
        tabButton.Text = "  " .. tabName
        tabButton.TextColor3 = theme.TextDim
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextSize = 14
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabListFrame
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0.6, 0)
        indicator.Position = UDim2.new(0, 0, 0.2, 0)
        indicator.BackgroundColor3 = theme.AccentStart
        indicator.BackgroundTransparency = 1
        indicator.Parent = tabButton
        local tabScrollingFrame = Instance.new("ScrollingFrame")
        tabScrollingFrame.Size = UDim2.new(1, -20, 1, 0)
        tabScrollingFrame.Position = UDim2.new(0, 10, 0, 0)
        tabScrollingFrame.BackgroundTransparency = 1
        tabScrollingFrame.Visible = false
        tabScrollingFrame.ScrollBarThickness = 2
        tabScrollingFrame.Parent = searchResultsFrame
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 8)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabScrollingFrame
        local tabInfo = {
            Button = tabButton,
            Indicator = indicator,
            Page = tabScrollingFrame
        }
        tabButton.MouseButton1Click:Connect(function()

            currentPage = tabInfo
            for _, otherTabInfo in pairs(pageList) do
                otherTabInfo.Indicator.BackgroundTransparency = 1
                otherTabInfo.Page.Visible = false
            end
            tabInfo.Indicator.BackgroundTransparency = 0
            tabInfo.Page.Visible = true
            if searchInput.Text == "" then
                searchResultsScrollingFrame.Visible = false
            end
        end)
        if isFirstTab then
            tabButton.MouseButton1Click:Fire()
            isFirstTab = false
        end
        table.insert(pageList, tabInfo)
        tabContent(tabLayout, featureList)
        return tabInfo
    end
tabButton.MouseButton1Click:Connect(function()

            if inputField.Text ~= "" then
                return
            end
            for _, tabData in pairs(tabs) do
                tweenService:Tween(tabData.button, {
                    BackgroundTransparency = 1,
                    TextColor3 = theme.TextDim
                })
                tweenService:Tween(tabData.indicator, {
                    BackgroundTransparency = 1
                })
                tabData.page.Visible = false
            end
            tweenService:Tween(tabButton, {
                BackgroundTransparency = 0,
                BackgroundColor3 = theme.Element,
                TextColor3 = theme.TextTitle
            })
            tweenService:Tween(selectedIndicator, {
                BackgroundTransparency = 0
            })
            pagesContainer.Visible = true
            currentPage = tabData.page
            tweenService:CreateRipple(tabButton)
        end)
        if initialTabLoaded then
            initialTabLoaded = false
            tabButton.BackgroundTransparency = 0
            tabButton.BackgroundColor3 = theme.Element
            tabButton.TextColor3 = theme.TextTitle
            selectedIndicator.BackgroundTransparency = 0
            pagesContainer.Visible = true
            currentPage = tabData.page
        end
        table.insert(tabs, tabData)
        function ui.createLabel(parent, text)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 30)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = theme.TextDim
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = parent
            return label
        end
        function ui.createButton(parent, text, callback)

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 45)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            table.insert(uiElements, {
                Frame = frame,
                Text = text:lower(),
                OriginalParent = parent
            })
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundColor3 = theme.Element
            button.Text = text
            button.TextColor3 = theme.TextTitle
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 14
            button.AutoButtonColor = false
            button.Parent = frame
            tweenService:CreateCorner(button, 8)
            button.MouseButton1Click:Connect(function()

                tweenService:CreateRipple(button)
                callback()
            end)
            button.MouseEnter:Connect(function()

                tweenService:Tween(button, {
                    BackgroundColor3 = theme.Hover
                })
            end)
            button.MouseLeave:Connect(function()

                tweenService:Tween(button, {
                    BackgroundColor3 = theme.Element
                })
            end)
        end
        function ui.createToggle(parent, labelText, defaultValue, callback)

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 45)
            frame.BackgroundColor3 = theme.Element
            frame.Parent = parent
            table.insert(uiElements, {
                Frame = frame,
                Text = labelText:lower(),
                OriginalParent = parent
            })
            tweenService:CreateCorner(frame, 8)
            local label = Instance.new("TextLabel")
            label.Text = labelText
            label.TextColor3 = theme.TextTitle
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 14
            label.Position = UDim2.new(0, 15, 0, 0)
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            local toggleButton = Instance.new("TextButton")
            toggleButton.Size = UDim2.new(0, 44, 0, 22)
            toggleButton.Position = UDim2.new(1, -55, 0.5, -11)
            toggleButton.BackgroundColor3 = theme.Sidebar
            toggleButton.Text = ""
            toggleButton.AutoButtonColor = false
            toggleButton.Parent = frame
            tweenService:CreateCorner(toggleButton, 11)
            local toggleHandle = Instance.new("Frame")
            toggleHandle.Size = UDim2.new(0, 18, 0, 18)
            toggleHandle.Position = UDim2.new(0, 2, 0.5, -9)
            toggleHandle.BackgroundColor3 = theme.TextDim
            toggleHandle.Parent = toggleButton
            tweenService:CreateCorner(toggleHandle, 9)
            local isToggled = defaultValue or false
            local function updateToggleVisuals()

                if isToggled then
                    tweenService:Tween(toggleButton, {
                        BackgroundColor3 = theme.AccentStart
                    })
                    tweenService:Tween(toggleHandle, {
                        Position = UDim2.new(1, -20, 0.5, -9),
                        BackgroundColor3 = theme.TextTitle
                    })
                else
                    tweenService:Tween(toggleButton, {
                        BackgroundColor3 = theme.Sidebar
                    })
                    tweenService:Tween(toggleHandle, {
                        Position = UDim2.new(0, 2, 0.5, -9),
                        BackgroundColor3 = theme.TextDim
                    })
                end
                callback(isToggled)
            end
            toggleButton.MouseButton1Click:Connect(function()

                isToggled = not isToggled
                updateToggleVisuals()
            end)
            if defaultValue then
                updateToggleVisuals()
            end
        end
        function ui.createSlider(parent, labelText, minValue, maxValue, defaultValue, callback)

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 60)
            frame.BackgroundColor3 = theme.Element
            frame.Parent = parent
            table.insert(uiElements, {
                Frame = frame,
                Text = labelText:lower(),
                OriginalParent = parent
            })
            tweenService:CreateCorner(frame, 8)
            local label = Instance.new("TextLabel")
            label.Text = labelText
            label.TextColor3 = theme.TextTitle
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 14
            label.Position = UDim2.new(0, 15, 0, 10)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Text = tostring(defaultValue)
            valueLabel.TextColor3 = theme.AccentStart
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextSize = 14
            valueLabel.Position = UDim2.new(1, -60, 0, 10)
            valueLabel.Size = UDim2.new(0, 45, 0, 20)
            valueLabel.BackgroundTransparency = 1
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = frame
            local sliderTrack = Instance.new("TextButton")
            sliderTrack.Size = UDim2.new(1, -30, 0, 6)
            sliderTrack.Position = UDim2.new(0, 15, 0, 40)
            sliderTrack.BackgroundColor3 = theme.Sidebar
            sliderTrack.Text = ""
            sliderTrack.AutoButtonColor = false
            sliderTrack.Parent = frame
            tweenService:CreateCorner(sliderTrack, 3)
            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
            sliderFill.BackgroundColor3 = theme.AccentStart
            sliderFill.Parent = sliderTrack
            tweenService:CreateCorner(sliderFill, 3)
            local isDragging = false
            local function updateSlider(input)

                local clickPositionX = input.Position.X - sliderTrack.AbsolutePosition.X
                local sliderWidth = sliderTrack.AbsoluteSize.X
                local normalizedPosition = math.clamp(clickPositionX / sliderWidth, 0, 1)
                tweenService:Tween(sliderFill, {
                    Size = UDim2.new(normalizedPosition, 0, 1, 0)
                }, 0.05)
                local currentValue = math.floor(minValue + (maxValue - minValue) * normalizedPosition)
                valueLabel.Text = tostring(currentValue)
                callback(currentValue)
            end
            sliderTrack.InputBegan:Connect(function(input)

                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType ==
                    Enum.UserInputType.Touch then
                    isDragging = true
                    updateSlider(input)
                end
            end)
            userInputService.InputEnded:Connect(function(input)

                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType ==
                    Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)
            userInputService.InputChanged:Connect(function(input)

                if isDragging and
                    (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType ==
                        Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end
        return ui
    end
    local isMenuOpen = true
    local function toggleMenu()

        isMenuOpen = not isMenuOpen
        menuFrame.Visible = isMenuOpen
    end
    (function()

        if keybindConnection then
            keybindConnection:Disconnect()
            keybindConnection = nil
        end
        keybindConnection = userInputService.InputBegan:Connect(function(input, gameProcessedEvent)

            if gameProcessedEvent then
                return
            end
            if input.KeyCode == toggleKey then
                toggleMenu()
            end
        end)
    end)()
    if deviceType == "Mobile" then
        local toggleButtonMobile = Instance.new("ImageButton")
        toggleButtonMobile.Name = "RuneXToggle"
        toggleButtonMobile.Size = UDim2.new(0, 50, 0, 50)
        toggleButtonMobile.Position = UDim2.new(0, 20, 0.5, -25)
        toggleButtonMobile.BackgroundColor3 = theme.Background
        toggleButtonMobile.Image = "rbxassetid://6026568198"
        toggleButtonMobile.Parent = menuFrame
        tweenService:CreateCorner(toggleButtonMobile, 25)
        local uiStroke = Instance.new("UIStroke")
        uiStroke.Color = theme.AccentStart
        uiStroke.Thickness = 2
        uiStroke.Parent = toggleButtonMobile
        toggleButtonMobile.MouseButton1Click:Connect(toggleMenu)
    end
    return scriptModule
end
local mainWindow = tweenService:Window()
local dashboardTab = mainWindow:Tab("Dashboard")
dashboardTab:Label("Main Controls")
dashboardTab:Toggle("Enable Auto-Farm", false, function(isEnabled)

    autoFarmEnabled = isEnabled
    local notificationService = tweenService
    local notificationCategory = "System"
    local notificationMessage = nil
    if isEnabled then
        notificationMessage = "Farming started."
        if not notificationMessage then

            notificationMessage = "Farming paused."
        end
    else

    end
    notificationService:Notify(notificationCategory, notificationMessage, 2)
end)
dashboardTab:Button("TP Elevator", function()

    local gameSystem = workspace:FindFirstChild("GameSystem")
    if not gameSystem then
        tweenService:Notify("Error", "GameSystem not found", 2, "Error")
        return
    end
    local lootsFolder = gameSystem:FindFirstChild("Loots")
    if not lootsFolder then
        tweenService:Notify("Error", "Loots folder not found", 2, "Error")
        return
    end
    local elevatorPart = lootsFolder:FindFirstChild("ElevatorCollect")
    if not elevatorPart then
        tweenService:Notify("Error", "Elevator not found", 2, "Error")
        return
    end
    local targetPart = nil
    if elevatorPart:IsA("Model") then
        targetPart = elevatorPart.PrimaryPart or elevatorPart:FindFirstChildWhichIsA("BasePart")
    elseif elevatorPart:IsA("Folder") then
        targetPart = elevatorPart:FindFirstChildWhichIsA("BasePart", true)
    elseif elevatorPart:IsA("BasePart") then
        targetPart = elevatorPart
    end
    if targetPart then
        teleportToPosition(CFrame.new(targetPart.Position) * CFrame.new(0, 5, 0))
        tweenService:Notify("Teleport", "Teleported to the elevator", 2, "Success")
    else
        tweenService:Notify("Error", "Elevator part not found", 2, "Error")
    end
end)
dashboardTab:Label("Configuration")
dashboardTab:Slider("Interact Distance", 10, 100, 25, function(distance)

    settings.INTERACT_DIST = distance
end)
local espTab = mainWindow:Tab("ESP")
espTab:Label("ESP Options")
espTab:Toggle("ESP Entity", false, function(isEnabled)

    entityEspEnabled = isEnabled
    local notificationService = tweenService
    local notificationCategory = "ESP"
    local notificationMessage = nil
    if isEnabled then
        notificationMessage = "Entity ESP Enabled"
        if not notificationMessage then

            notificationMessage = "Entity ESP Disabled"
        end
    else

    end
    notificationService:Notify(notificationCategory, notificationMessage, 2)
end)
espTab:Toggle("ESP Loot", false, function(isEnabled)

    lootEspEnabled = isEnabled
    local notificationService = tweenService
    local notificationCategory = "ESP"
    local notificationMessage = nil
    if isEnabled then
        notificationMessage = "Loot ESP Enabled"
        if not notificationMessage then

            notificationMessage = "Loot ESP Disabled"
        end
    else

    end
    notificationService:Notify(notificationCategory, notificationMessage, 2)
end)
espTab:Toggle("ESP Container", false, function(isEnabled)

    containerEspEnabled = isEnabled
    local notificationService = tweenService
    local notificationCategory = "ESP"
    local notificationMessage = nil
    if isEnabled then
        notificationMessage = "Container ESP Enabled"
        if not notificationMessage then

            notificationMessage = "Container ESP Disabled"
        end
    else

    end
    notificationService:Notify(notificationCategory, notificationMessage, 2)
end)
local miscTab = mainWindow:Tab("Misc")
miscTab:Label("Player Options")
miscTab:Toggle("Speed Hack", false, function(isEnabled)

    speedHackEnabled = isEnabled
    if not isEnabled then
        local playerHumanoid = player:FindFirstChildOfClass("Humanoid")
        if playerHumanoid then
            playerHumanoid.WalkSpeed = defaultWalkSpeed
        end
    end
    local notificationService = tweenService
    local notificationCategory = "Speed"
    local notificationMessage = nil
    if isEnabled then
        notificationMessage = "Speed Enabled"
        if not notificationMessage then

            notificationMessage = "Speed Disabled"
        end
    else

    end
    notificationService:Notify(notificationCategory, notificationMessage, 2)
end)
miscTab:Slider("Walk Speed", 16, 200, 16, function(walkSpeed)

    customWalkSpeed = walkSpeed
end)
local settingsTab = mainWindow:Tab("Settings")
settingsTab:Label("Keybind Settings")
local currentKeybindLabel = settingsTab:Label("Current Toggle Key: " .. toggleKey.Name)
settingsTab:Button("Change Toggle Key (Press Any Key)", function()

    if keybindInputConnection then
        keybindInputConnection:Disconnect()
        keybindInputConnection = nil
    end
    currentKeybindLabel.Text = "Press any key..."
    keybindInputConnection = userInputService.InputBegan:Connect(function(input, gameProcessedEvent)

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            toggleKey = input.KeyCode
            currentKeybindLabel.Text = "Current Toggle Key: " .. toggleKey.Name
            tweenService:Notify("Keybind", "Toggle key set to: " .. toggleKey.Name, 2)
            if keybindInputConnection then
                keybindInputConnection:Disconnect()
                keybindInputConnection = nil
            end
        end
    end)
end)
settingsTab:Label("Credits")
settingsTab:Label("Developer: xxdayssheus")
settingsTab:Button("Unload Script", function()

    menuFrame:Destroy()
    script.Parent:Destroy()
end)
tweenService:Notify("RuneX", "Deadly Delivery Loaded.", 5)
task.delay(5, function()

    local discordInviteGui = Instance.new("ScreenGui")
    discordInviteGui.Name = "DiscordInvite"
    discordInviteGui.ResetOnSpawn = false
    discordInviteGui.DisplayOrder = 999
    discordInviteGui.Parent = playerGui
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.5
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = discordInviteGui
    local inviteCard = Instance.new("Frame")
    inviteCard.Size = UDim2.new(0, 400, 0, 250)
    inviteCard.Position = UDim2.new(0.5, -200, 0.5, -125)
    inviteCard.BackgroundColor3 = theme.Background
    inviteCard.BorderSizePixel = 0
    inviteCard.Parent = discordInviteGui
    tweenService:CreateCorner(inviteCard, 12)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = theme.AccentStart
    uiStroke.Thickness = 2
    uiStroke.Parent = inviteCard
    local discordLogo = Instance.new("ImageLabel")
    discordLogo.Size = UDim2.new(0, 80, 0, 80)
    discordLogo.Position = UDim2.new(0.5, -40, 0, 25)
    discordLogo.BackgroundTransparency = 1
    discordLogo.Image = "rbxassetid://6031229361"
    discordLogo.Parent = inviteCard
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "Join Our Discord!"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 22
    titleLabel.TextColor3 = theme.TextTitle
    titleLabel.Position = UDim2.new(0, 0, 0, 115)
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = inviteCard
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Text = "Get updates, support, and more scripts!"
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.TextSize = 13
    descriptionLabel.TextColor3 = theme.TextDim
    descriptionLabel.Position = UDim2.new(0, 0, 0, 145)
    descriptionLabel.Size = UDim2.new(1, 0, 0, 20)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Parent = inviteCard
    local copyButton = Instance.new("TextButton")
    copyButton.Size = UDim2.new(0, 180, 0, 40)
    copyButton.Position = UDim2.new(0.5, -90, 0, 180)
    copyButton.BackgroundColor3 = theme.AccentStart
    copyButton.Text = "Copy Invite Link"
    copyButton.TextColor3 = theme.TextTitle
    copyButton.Font = Enum.Font.GothamBold
    copyButton.TextSize = 14
    copyButton.AutoButtonColor = false
    copyButton.Parent = inviteCard
    tweenService:CreateCorner(copyButton, 8)
    copyButton.MouseEnter:Connect(function()

        tweenService:Tween(copyButton, {
            BackgroundColor3 = theme.AccentEnd
        })
    end)
    copyButton.MouseLeave:Connect(function()

        tweenService:Tween(copyButton, {
            BackgroundColor3 = theme.AccentStart
        })
    end)
    copyButton.MouseButton1Click:Connect(function()

        setclipboard("https://discord.com/invite/ycw9aFxtv6")
        copyButton.Text = "✅ Copied!"
        tweenService:Notify("Discord", "Invite link copied to clipboard!", 2)
        task.wait(1.5)
        tweenService:Tween(inviteCard, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.3)
        tweenService:Tween(backgroundFrame, {
            BackgroundTransparency = 1
        }, 0.3)
        task.wait(0.3)
        discordInviteGui:Destroy()
    end)
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = theme.Element
    closeButton.Text = "X"
    closeButton.TextColor3 = theme.TextDim
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.AutoButtonColor = false
    closeButton.Parent = inviteCard
    tweenService:CreateCorner(closeButton, 8)
    closeButton.MouseEnter:Connect(function()

        tweenService:Tween(closeButton, {
            BackgroundColor3 = theme.Hover,
            TextColor3 = theme.TextTitle
        })
    end)
    closeButton.MouseLeave:Connect(function()

        tweenService:Tween(closeButton, {
            BackgroundColor3 = theme.Element,
            TextColor3 = theme.TextDim
        })
    end)
    closeButton.MouseButton1Click:Connect(function()

        tweenService:Tween(inviteCard, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.3)
        tweenService:Tween(backgroundFrame, {
            BackgroundTransparency = 1
        }, 0.3)
        task.wait(0.3)
        discordInviteGui:Destroy()
    end)
    inviteCard.Size = UDim2.new(0, 0, 0, 0)
    inviteCard.Position = UDim2.new(0.5, 0, 0.5, 0)
    tweenService:Tween(inviteCard, {
        Size = UDim2.new(0, 400, 0, 250),
        Position = UDim2.new(0.5, -200, 0.5, -125)
    }, 0.5, Enum.EasingStyle.Back)
end)