//    
// lua\RedemptionMixin.lua    
//    
//    Created by:   Dragon

RedemptionMixin = CreateMixin(RedemptionMixin)
RedemptionMixin.type = "Redemption"

function RedemptionMixin:__initmixin()
    self.redemptionallowed = true
end

local function ClearRedemptionCooldown(self)
    self.redemptionallowed = true
end

local function RedemAlienToHive(self)
    if self:GetIsAlive() and self:GetHealthScalar() <= kRedemptionEHPThreshold then
        self:OnRedemed()
        self:TeleportToHive()
        //TeleportToHive(self)
        //Shared.Message("LOG - Attempting To Reedem")
        self.redemptionallowed = false
        self:AddTimedCallback(ClearRedemptionCooldown, kRedemptionCooldown)
    end
    return false
end

function RedemptionMixin:OnTakeDamage(damage, attacker, doer, point, direction, damageType, preventAlert)
    if Server then
        if GetHasRedemptionUpgrade(self) and self.redemptionallowed and self:GetHealthScalar() <= kRedemptionEHPThreshold then
            //Shared.Message("LOG - Eligable For Redeem")
            self.redemptionallowed = false
            self:AddTimedCallback(RedemAlienToHive, kRedemptionTimeBase)
        end
    end
end

