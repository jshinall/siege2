// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Contamination.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Creates temporary infestation.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")

class 'Contamination' (ScriptActor)

Contamination.kMapName = "contamination"

Contamination.kModelName = PrecacheAsset("models/alien/contamination/contamination.model")
local kAnimationGraph = PrecacheAsset("models/alien/contamination/contamination.animation_graph")

local kContaminationSpreadEffect = PrecacheAsset("cinematics/alien/contamination_spread.cinematic")

local kLifeSpan = 20
local kPhysicsRadius = 0.67

local networkVars =
{
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

local function TimeUp(self)

    self:Kill()
    return false

end

function Contamination:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, IdleMixin)

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)

          if Server then
            local gameRules = GetGamerules()
            if gameRules then
               if gameRules:GetGameStarted() and Shared.GetTime() - gameRules:GetGameStartTime() < (kFrontDoorTime) then 
               DestroyEntity(self)
               end
            end
          end
          
end

function Contamination:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, InfestationMixin)
    
    self:SetModel(Contamination.kModelName, kAnimationGraph)

    local coords = Angles(0, math.random() * 2 * math.pi, 0):GetCoords()
    coords.origin = self:GetOrigin()
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
        self:AddTimedCallback(TimeUp, kLifeSpan)
        self:SetCoords(coords)
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
        self.contaminationEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.contaminationEffect:SetCinematic(kContaminationSpreadEffect)
        self.contaminationEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.contaminationEffect:SetCoords(self:GetCoords())

        self.infestationDecal = CreateSimpleInfestationDecal(1, coords)
    
    end

end

function Contamination:GetIsFlameAble()
    return true
end

function Contamination:GetReceivesStructuralDamage()
    return true
end    

function Contamination:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Client then
    
        if self.contaminationEffect then
        
            Client.DestroyCinematic(self.contaminationEffect)
            self.contaminationEffect = nil
        
        end
        
        if self.infestationDecal then
        
            Client.DestroyRenderDecal(self.infestationDecal)
            self.infestationDecal = nil
        
        end
    
    end

end

function Contamination:GetInfestationRadius()
    return kInfestationRadius
end

function Contamination:GetInfestationMaxRadius()
    return kInfestationRadius
end

function Contamination:GetInfestationGrowthRate()
    return 0.5
end

function Contamination:GetPlayIdleSound()
    return self:GetCurrentInfestationRadiusCached() < 1
end

function Contamination:OnKill(attacker, doer, point, direction)

    self:TriggerEffects("death")
    self:SetModel(nil)
    TEST_EVENT("Contamination killed")
    CreateEntity(Rupture.kMapName, self:GetOrigin(), self:GetTeamNumber())
    
end 

function Contamination:GetSendDeathMessageOverride()
    return false
end

function Contamination:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Contamination:GetCanBeHealedOverride()
    return false
end

function Contamination:OverrideCheckVision()
    return false
end

local kTargetPointOffset = Vector(0, 0.18, 0)
function Contamination:GetEngagementPointOverride()
    return self:GetOrigin() + kTargetPointOffset
end

function Contamination:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if not self:GetIsAlive() then
    
        if Server then
    
            local destructionAllowedTable = { allowed = true }
            if self.GetDestructionAllowed then
                self:GetDestructionAllowed(destructionAllowedTable)
            end
            
            if destructionAllowedTable.allowed then
                DestroyEntity(self)
            end
        
        end
        
        if Client then
        
            if self.contaminationEffect then
                
                Client.DestroyCinematic(self.contaminationEffect)
                self.contaminationEffect = nil
                
            end
            
            if self.infestationDecal then
            
                Client.DestroyRenderDecal(self.infestationDecal)
                self.infestationDecal = nil
            
            end
            
        end 
    
    end

end

Shared.LinkClassToMap("Contamination", Contamination.kMapName, networkVars)