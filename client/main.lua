--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                   6HA VEHICLE CONTROL SYSTEM                  ║
    ║                         Client Script                         ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  Developer: 6ha                                               ║
    ║  Discord: https://discord.gg/Zk4TTQrRdh                       ║
    ║  Server: 𝐑𝟔 | 𝐒𝐓𝐎𝐑𝐄                                          ║
    ║  All Rights Reserved © 2026                                   ║
    ╚═══════════════════════════════════════════════════════════════╝
]]--

-- ══════════════════════════════════════════════════════════════
--                      INITIALIZATION
-- ══════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentVehicle = nil
local currentSignalState = 'off' -- off, left, right, hazard

-- ══════════════════════════════════════════════════════════════
--                      UI CONTROL FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- فتح واجهة التحكم
local function OpenVehControl()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    -- التحقق من وجود اللاعب داخل المركبة
    if vehicle == 0 then
        QBCore.Functions.Notify(Config.Notifications['not_in_vehicle'], 'error')
        return
    end
    
    currentVehicle = vehicle
    local vehicleData = GetVehicleData(vehicle)
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'open',
        vehicleData = vehicleData
    })
end

-- إغلاق واجهة التحكم
local function CloseVehControl()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
    currentVehicle = nil
end

-- ══════════════════════════════════════════════════════════════
--                      VEHICLE DATA FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- الحصول على بيانات المركبة
function GetVehicleData(vehicle)
    if vehicle == 0 then return nil end
    
    local vehicleClass = GetVehicleClass(vehicle)
    local vehicleType = GetVehicleType(vehicleClass)
    local doorCount = GetNumberOfVehicleDoors(vehicle)
    local hasEngine = true
    local hasBonnet = doorCount > 0
    local hasTrunk = doorCount > 2
    local hasWindows = vehicleType == 'car' or vehicleType == 'truck'
    
    -- رقم اللوحة
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- عدد المقاعد في المركبة
    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local seats = {}
    
    for i = -1, maxSeats - 2 do
        local seatPed = GetPedInVehicleSeat(vehicle, i, false)
        seats[i] = {
            occupied = seatPed ~= 0,
            isCurrent = seatPed == PlayerPedId()
        }
    end
    
    -- حالة المركبة الحالية
    local engineRunning = GetIsVehicleEngineRunning(vehicle)
    local doorsLocked = GetVehicleDoorLockStatus(vehicle) == 2
    
    -- حالة الأبواب
    local doors = {}
    for i = 0, 3 do
        doors[i] = GetVehicleDoorAngleRatio(vehicle, i) > 0
    end
    
    -- حالة النوافذ
    local windows = {}
    for i = 0, 3 do
        windows[i] = not IsVehicleWindowIntact(vehicle, i)
    end
    
    -- حالة غطاء المحرك والصندوق
    local bonnetOpen = GetVehicleDoorAngleRatio(vehicle, 4) > 0
    local trunkOpen = GetVehicleDoorAngleRatio(vehicle, 5) > 0
    
    return {
        type = vehicleType,
        typeIcon = Config.VehicleTypes[vehicleType] or 'fa-car',
        plate = plate,
        doorCount = doorCount,
        hasEngine = hasEngine,
        hasBonnet = hasBonnet,
        hasTrunk = hasTrunk,
        hasWindows = hasWindows,
        engineRunning = engineRunning,
        doorsLocked = doorsLocked,
        doors = doors,
        windows = windows,
        bonnetOpen = bonnetOpen,
        trunkOpen = trunkOpen,
        interiorLight = IsVehicleInteriorLightOn(vehicle),
        maxSeats = maxSeats,
        seats = seats,
        signalState = currentSignalState
    }
end

-- تحديد نوع المركبة
function GetVehicleType(vehicleClass)
    local types = {
        [8] = 'motorcycle',
        [13] = 'bicycle',
        [14] = 'boat',
        [15] = 'helicopter',
        [16] = 'plane',
        [18] = 'emergency',
        [19] = 'military'
    }
    
    if types[vehicleClass] then
        return types[vehicleClass]
    elseif vehicleClass >= 0 and vehicleClass <= 7 then
        return 'car'
    elseif vehicleClass >= 9 and vehicleClass <= 12 then
        return 'truck'
    else
        return 'car'
    end
end

-- ══════════════════════════════════════════════════════════════
--                      VEHICLE CONTROL FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- التحكم بالمحرك
local function ToggleEngine()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local engineRunning = GetIsVehicleEngineRunning(currentVehicle)
    SetVehicleEngineOn(currentVehicle, not engineRunning, false, true)
    
    SendNUIMessage({
        action = 'updateState',
        state = 'engine',
        value = not engineRunning
    })
    
    -- إضافة صوت (اختياري)
    if Config.Sounds and Config.Sounds.Enable then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

-- التحكم بالأبواب
local function ToggleDoor(doorIndex)
    if not currentVehicle or currentVehicle == 0 then return end
    
    local doorAngle = GetVehicleDoorAngleRatio(currentVehicle, doorIndex)
    
    if doorAngle > 0 then
        SetVehicleDoorShut(currentVehicle, doorIndex, false)
    else
        SetVehicleDoorOpen(currentVehicle, doorIndex, false, false)
    end
    
    SendNUIMessage({
        action = 'updateState',
        state = 'door',
        doorIndex = doorIndex,
        value = doorAngle == 0
    })
end

-- قفل/فتح قفل الأبواب
local function ToggleDoorLock()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local lockStatus = GetVehicleDoorLockStatus(currentVehicle)
    local newStatus = lockStatus == 2 and 1 or 2
    
    SetVehicleDoorsLocked(currentVehicle, newStatus)
    
    -- تشغيل صوت القفل
    PlayVehicleDoorOpenSound(currentVehicle, 1)
    
    SendNUIMessage({
        action = 'updateState',
        state = 'lock',
        value = newStatus == 2
    })
    
    -- إشعار
    if newStatus == 2 then
        QBCore.Functions.Notify(Config.Notifications['doors_locked'], 'success')
    else
        QBCore.Functions.Notify(Config.Notifications['doors_unlocked'], 'success')
    end
end

-- التحكم بالنوافذ
local function ToggleWindow(windowIndex)
    if not currentVehicle or currentVehicle == 0 then return end
    
    local isIntact = IsVehicleWindowIntact(currentVehicle, windowIndex)
    
    if isIntact then
        RollDownWindow(currentVehicle, windowIndex)
    else
        RollUpWindow(currentVehicle, windowIndex)
    end
    
    SendNUIMessage({
        action = 'updateState',
        state = 'window',
        windowIndex = windowIndex,
        value = isIntact
    })
end

-- التحكم بغطاء المحرك
local function ToggleBonnet()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local doorAngle = GetVehicleDoorAngleRatio(currentVehicle, 4)
    
    if doorAngle > 0 then
        SetVehicleDoorShut(currentVehicle, 4, false)
    else
        SetVehicleDoorOpen(currentVehicle, 4, false, false)
    end
    
    SendNUIMessage({
        action = 'updateState',
        state = 'bonnet',
        value = doorAngle == 0
    })
end

-- التحكم بالصندوق الخلفي
local function ToggleTrunk()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local doorAngle = GetVehicleDoorAngleRatio(currentVehicle, 5)
    
    if doorAngle > 0 then
        SetVehicleDoorShut(currentVehicle, 5, false)
    else
        SetVehicleDoorOpen(currentVehicle, 5, false, false)
    end
    
    SendNUIMessage({
        action = 'updateState',
        state = 'trunk',
        value = doorAngle == 0
    })
end

-- التحكم بإضاءة الداخلية
local function ToggleInteriorLight()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local isOn = IsVehicleInteriorLightOn(currentVehicle)
    SetVehicleInteriorlight(currentVehicle, not isOn)
    
    SendNUIMessage({
        action = 'updateState',
        state = 'interiorLight',
        value = not isOn
    })
end

-- التنقل بين المقاعد
local function ChangeSeat(seatIndex)
    if not currentVehicle or currentVehicle == 0 then return end
    
    local ped = PlayerPedId()
    local seatPed = GetPedInVehicleSeat(currentVehicle, seatIndex, false)
    
    -- التحقق من أن المقعد فارغ
    if seatPed == 0 or seatPed == ped then
        TaskWarpPedIntoVehicle(ped, currentVehicle, seatIndex)
        
        -- تحديث بيانات المقاعد
        Wait(100)
        local vehicleData = GetVehicleData(currentVehicle)
        SendNUIMessage({
            action = 'updateSeats',
            seats = vehicleData.seats
        })
    else
        QBCore.Functions.Notify('هذا المقعد مشغول', 'error')
    end
end

-- التحكم بالإشارات
local function ToggleSignal(signalType)
    if not currentVehicle or currentVehicle == 0 then return end
    
    -- إيقاف الإشارة الحالية إذا كانت نفس النوع
    if currentSignalState == signalType then
        currentSignalState = 'off'
        SetVehicleIndicatorLights(currentVehicle, 0, false) -- Left off
        SetVehicleIndicatorLights(currentVehicle, 1, false) -- Right off
    else
        currentSignalState = signalType
        
        if signalType == 'left' then
            SetVehicleIndicatorLights(currentVehicle, 1, false) -- Right off
            SetVehicleIndicatorLights(currentVehicle, 0, true)  -- Left on
        elseif signalType == 'right' then
            SetVehicleIndicatorLights(currentVehicle, 0, false) -- Left off
            SetVehicleIndicatorLights(currentVehicle, 1, true)  -- Right on
        elseif signalType == 'hazard' then
            SetVehicleIndicatorLights(currentVehicle, 0, true)  -- Left on
            SetVehicleIndicatorLights(currentVehicle, 1, true)  -- Right on
        end
    end
    
    SendNUIMessage({
        action = 'updateState',
        state = 'signal',
        value = currentSignalState
    })
end

-- نسخ رقم اللوحة
local function CopyPlate()
    if not currentVehicle or currentVehicle == 0 then return end
    
    local plate = GetVehicleNumberPlateText(currentVehicle)
    QBCore.Functions.Notify('رقم اللوحة: ' .. plate, 'primary', 3000)
end

-- ══════════════════════════════════════════════════════════════
--                      NUI CALLBACKS
-- ══════════════════════════════════════════════════════════════

RegisterNUICallback('close', function(data, cb)
    CloseVehControl()
    cb('ok')
end)

RegisterNUICallback('toggleEngine', function(data, cb)
    ToggleEngine()
    cb('ok')
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    ToggleDoor(data.doorIndex)
    cb('ok')
end)

RegisterNUICallback('toggleLock', function(data, cb)
    ToggleDoorLock()
    cb('ok')
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    ToggleWindow(data.windowIndex)
    cb('ok')
end)

RegisterNUICallback('toggleBonnet', function(data, cb)
    ToggleBonnet()
    cb('ok')
end)

RegisterNUICallback('toggleTrunk', function(data, cb)
    ToggleTrunk()
    cb('ok')
end)

RegisterNUICallback('toggleInteriorLight', function(data, cb)
    ToggleInteriorLight()
    cb('ok')
end)

RegisterNUICallback('changeSeat', function(data, cb)
    ChangeSeat(data.seatIndex)
    cb('ok')
end)

RegisterNUICallback('copyPlate', function(data, cb)
    CopyPlate()
    cb('ok')
end)

RegisterNUICallback('toggleSignal', function(data, cb)
    ToggleSignal(data.signalType)
    cb('ok')
end)

-- ══════════════════════════════════════════════════════════════
--                      COMMANDS & EVENTS
-- ══════════════════════════════════════════════════════════════

-- أمر فتح الواجهة
RegisterCommand(Config.Command, function()
    if isUIOpen then
        CloseVehControl()
    else
        OpenVehControl()
    end
end, false)

-- حدث خارجي لفتح الواجهة
RegisterNetEvent('vehcontrol:openExternal', function()
    if isUIOpen then
        CloseVehControl()
    else
        OpenVehControl()
    end
end)

-- دعم الحدث القديم للتوافق
RegisterNetEvent('client:vehcontrol:openExternal', function()
    if isUIOpen then
        CloseVehControl()
    else
        OpenVehControl()
    end
end)

-- ══════════════════════════════════════════════════════════════
--                      THREADS
-- ══════════════════════════════════════════════════════════════

-- إغلاق عند الخروج من المركبة
CreateThread(function()
    while true do
        Wait(500)
        if isUIOpen then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle == 0 then
                CloseVehControl()
            end
        end
    end
end)

-- معالجة التحكمات
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            DisableControlAction(0, 1, true)  -- Mouse look
            DisableControlAction(0, 2, true)  -- Mouse look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- Melee Attack
            DisableControlAction(0, 106, true) -- Vehicle Mouse Control Override
        else
            Wait(500)
        end
    end
end)

-- إيقاف الإشارة تلقائياً عند الانعطاف
CreateThread(function()
    local lastHeading = 0
    while true do
        Wait(100)
        
        if currentVehicle and currentVehicle ~= 0 and (currentSignalState == 'left' or currentSignalState == 'right') then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle == currentVehicle then
                local currentHeading = GetEntityHeading(vehicle)
                local headingDiff = math.abs(currentHeading - lastHeading)
                
                -- إذا انعطفت المركبة بزاوية كبيرة (أكثر من 30 درجة)
                if headingDiff > 30 then
                    -- التحقق من اتجاه الانعطاف
                    if currentSignalState == 'left' and headingDiff > 30 then
                        ToggleSignal('left') -- إيقاف إشارة اليسار
                    elseif currentSignalState == 'right' and headingDiff > 30 then
                        ToggleSignal('right') -- إيقاف إشارة اليمين
                    end
                end
                
                lastHeading = currentHeading
            end
        else
            Wait(400)
        end
    end
end)
