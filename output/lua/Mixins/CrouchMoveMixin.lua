// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Mixins\CrouchMoveMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

CrouchMoveMixin = CreateMixin( CrouchMoveMixin )
CrouchMoveMixin.type = "CrouchMove"

CrouchMoveMixin.networkVars =
{
    crouching = "compensated boolean",
    timeOfCrouchChange = "compensated time",
}

CrouchMoveMixin.expectedCallbacks =
{
    GetCrouchSpeedScalar = ""
}

CrouchMoveMixin.optionalCallbacks =
{
    GetCrouchCameraAnimationAllowed = "Return false from this callback to prevent camera animation from crouching."
}

local kCrouchAnimationTime = 0.25

function CrouchMoveMixin:__initmixin()

    self.crouching = false
    self.timeOfCrouchChange = 0

end

function CrouchMoveMixin:GetExtentsOverride()

    local extents = self:GetMaxExtents()
    
    if self:isa("Marine") or self:isa("Onos") or self:isa("JetpackMarine") or self:isa("Fade") then
             if self.modelsize < 1 then
             extents.x = extents.x * self.modelsize
             extents.x = extents.x * self.modelsize
            extents.y = extents.y * self.modelsize
    
                if self.crouching then
                extents.y = extents.y * (1 - self:GetExtentsCrouchShrinkAmount()) * self.modelsize
                end
           return extents
           end
  end
  
  if self.crouching then
   extents.y = extents.y * (1 - self:GetExtentsCrouchShrinkAmount())
  end
       
    return extents
    
end

local kCrouchCameraAnimationAllowedTable = { allowed = true }
function CrouchMoveMixin:OnUpdateCamera(deltaTime)

    if self.GetCrouchCameraAnimationAllowed then
    
        kCrouchCameraAnimationAllowedTable.allowed = true
        self:GetCrouchCameraAnimationAllowed(kCrouchCameraAnimationAllowedTable)
        if not kCrouchCameraAnimationAllowedTable.allowed then
            return
        end
        
    end
    
    // Update view offset from crouching
    local offset = -self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    self:SetCameraYOffset(offset)
    
end

function CrouchMoveMixin:GetCrouching()
    return self.crouching
end

/**
 * Returns a value between 0 and 1 indicating how much the player has crouched
 * visually (actual crouching is binary).
 */
function CrouchMoveMixin:GetCrouchAmount()
     
    // Get 0-1 scalar of time since crouch changed        
    local crouchScalar = 0
    if self.timeOfCrouchChange > 0 then
    
        crouchScalar = math.min(Shared.GetTime() - self.timeOfCrouchChange, kCrouchAnimationTime) / kCrouchAnimationTime
        
        if(self.crouching) then
            crouchScalar = math.sin(crouchScalar * math.pi/2)
        else
            crouchScalar = math.cos(crouchScalar * math.pi/2)
        end
        
    end
    
    return crouchScalar

end

function CrouchMoveMixin:ModifyMaxSpeed(maxSpeedTable)

    if self:GetIsOnGround() then
        local crouchMod = 1 - self:GetCrouchAmount() * self:GetCrouchSpeedScalar()
        maxSpeedTable.maxSpeed = maxSpeedTable.maxSpeed * crouchMod
    end

end

local function RecentlyLanded(self)
    return Shared.GetTime() - self:GetTimeGroundTouched() < 0.2
end

function CrouchMoveMixin:HandleButtons(input)

    PROFILE("CrouchMoveMixin:SetCrouchState")

    local crouchDesired = bit.band(input.commands, Move.Crouch) ~= 0
    if crouchDesired == self.crouching then
        return
    end
   
    if not crouchDesired then
        
        // Check if there is room for us to stand up.
        self.crouching = crouchDesired
        self:UpdateControllerFromEntity()
        
        if self:GetIsColliding() then
            self.crouching = true
            self:UpdateControllerFromEntity()
        else
            self.timeOfCrouchChange = Shared.GetTime()
        end
        
    elseif self:GetCanCrouch() then
        self.crouching = crouchDesired
        self.timeOfCrouchChange = Shared.GetTime()
        self:UpdateControllerFromEntity()
    end
    
end