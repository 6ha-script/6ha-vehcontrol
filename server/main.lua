--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                   6HA VEHICLE CONTROL SYSTEM                  ║
    ║                         Server Script                         ║
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

-- ══════════════════════════════════════════════════════════════
--                      SERVER EVENTS
-- ══════════════════════════════════════════════════════════════

-- حدث للتحقق من مفاتيح المركبة
RegisterNetEvent('6ha-vehcontrol:server:checkKeys', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local hasKeys = false
    
    -- التحقق من qb-vehiclekeys
    local keys = Player.PlayerData.metadata.vehiclekeys or {}
    if keys[plate] then
        hasKeys = true
    end
    
    -- إرسال النتيجة للعميل
    TriggerClientEvent('6ha-vehcontrol:client:keysResult', src, hasKeys)
end)
