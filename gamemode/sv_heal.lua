--Horde's healing framework
-- Healing is affected by skill bonuses and is logged.
util.AddNetworkString("Horde_RenderHealer")

HealInfo = {}
HealInfo.__index = HealInfo

function HealInfo:New(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function HealInfo:SetHealAmount(amount)
    self.amount = amount
end

function HealInfo:GetHealAmount()
    return self.amount or 0
end

function HealInfo:SetHealer(healer)
    self.healer = healer
end

function HealInfo:GetHealer(healer)
    return self.healer
end

function HealInfo:SetOverHealPercentage(percentage)
    self.over_heal_percentage = percentage
end

function HealInfo:GetOverHealPercentage()
    return self.over_heal_percentage or 0
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_AddHealAmount(amount)
    if GetConVar("horde_enable_sandbox"):GetInt() == 1 then return end
    if not self.Horde_HealAmount then self.Horde_HealAmount = 0 end
    self.Horde_HealAmount = self.Horde_HealAmount + amount
    if self.Horde_HealAmount >= 100 then
        self.Horde_HealAmount = 0
        if HORDE.current_wave <= 0 then return end
		local class_name = self:Horde_GetClass().name
		if self:Horde_GetLevel(class_name) >= HORDE.max_level then return end
		self:Horde_SetExp(class_name, self:Horde_GetExp(class_name) + 1)
    end
end

-- Call this if you want Horde to recognize your healing
function HORDE:OnPlayerHeal(ply, healinfo, silent)
    hook.Run("Horde_OnPlayerHeal", ply, healinfo)
    if (ply:GetMaxHealth() <= ply:Health()) and (healinfo:GetOverHealPercentage() <= 0) then return end
    ply:SetHealth(math.min(ply:GetMaxHealth() * (1 + healinfo:GetOverHealPercentage()), ply:Health() + healinfo:GetHealAmount()))

    local healer = healinfo:GetHealer()
    if not healer:IsPlayer() or not healer:IsValid() then return end
    if not HORDE.player_heal[healer:SteamID()] then HORDE.player_heal[healer:SteamID()] = 0 end
    HORDE.player_heal[healer:SteamID()] = HORDE.player_heal[healer:SteamID()] + healinfo:GetHealAmount()

    if silent then
        healer:Horde_AddHealAmount(healinfo:GetHealAmount())
        return
    end
    ply:ScreenFade(SCREENFADE.IN, Color(50, 200, 50, 10), 0.3, 0)
    if healer ~= ply then
        healer:Horde_AddMoney(3)
        healer:Horde_SyncEconomy()
        net.Start("Horde_RenderHealer")
            net.WriteString(healer:GetName())
        net.Send(ply)

        healer:Horde_AddHealAmount(healinfo:GetHealAmount())
    end
end