// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ConstructMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

PrecacheAsset("cinematics/vfx_materials/build.surface_shader")

ConstructMixin = CreateMixin( ConstructMixin )
ConstructMixin.type = "Construct"

local kBuildMaterial = PrecacheAsset("cinematics/vfx_materials/build.material")

local kBuildEffectsInterval = 1
local kDrifterBuildRate = 1

ConstructMixin.networkVars =
{
    // 0-1 scalar representing build completion time. Since we use this to blend
    // animations, it must be interpolated for the animations to appear smooth
    // on the client.
    buildFraction           = "interpolated float (0 to 1 by 0.01)",
    
    // true if structure finished building
    constructionComplete    = "boolean",

    // Show different material when under construction
    underConstruction       = "boolean"
    
}

ConstructMixin.expectedMixins =
{
    Live = "ConstructMixin manipulates the health when construction progresses."
}

ConstructMixin.expectedCallbacks = 
{
}

ConstructMixin.optionalCallbacks = 
{
    OnConstruct = "Called whenever construction progress changes.",
    OnConstructionComplete = "Called whenever construction is completes.",
    GetCanBeUsedConstructed = "Return true when this entity has a use function when constructed.",
    GetAddConstructHealth = "Return false to prevent adding health when constructing."
    
}

function ConstructMixin:__initmixin()

    // used for client side material effect
    self.underConstruction = false
    self.timeLastConstruct = 0
    self.timeOfNextBuildWeldEffects = 0
    self.buildTime = 0
    self.buildFraction = 0
    self.timeOfLastHealSpray = 0
    
    // Structures start with a percentage of their full health and gain more as they're built.
    if self.startsBuilt then
        self:SetHealth( self:GetMaxHealth() )
        self:SetArmor( self:GetMaxArmor() )
    else
        self:SetHealth( self:GetMaxHealth() * kStartHealthScalar )
        self:SetArmor( self:GetMaxArmor() * kStartHealthScalar )
    end
    
    self.startsBuilt  = false
    
end

local function CreateBuildEffect(self)

    local model = self:GetRenderModel()
    if not self.buildMaterial and model then
    
        local material = Client.CreateRenderMaterial()
        material:SetMaterial(kBuildMaterial)
        model:AddMaterial(material)
        self.buildMaterial = material
        
    end    
    
end

local function RemoveBuildEffect(self)

    local model = self:GetRenderModel()
    if self.buildMaterial and model then
    
        local material = self.buildMaterial
        model:RemoveMaterial(material)
        Client.DestroyRenderMaterial(material)
        self.buildMaterial = nil
        
    end            

end

local function SharedUpdate(self, deltaTime)

    if Server then
        
        local effectTimeout = Shared.GetTime() - self.timeLastConstruct > 0.65
        self.underConstruction = not self:GetIsBuilt() and not effectTimeout
        
        // Only Alien structures auto build.
        // Update build fraction every tick to be smooth.
        if not self:GetIsBuilt() and GetIsAlienUnit(self) then

            if not self.GetCanAutoBuild or self:GetCanAutoBuild() then
            
                local multiplier = self.hasDrifterEnzyme and self.drifterbonusspeed or kAutoBuildRate 
                multiplier = multiplier * ( (HasMixin(self, "Catalyst") and self:GetIsCatalysted()) and kNutrientMistAutobuildMultiplier or 1 )
                 local gameRules = GetGamerules()
                 if gameRules:GetGameStarted() and Shared.GetTime() - gameRules:GetGameStartTime() < (kFrontDoorTime)  then
                 multiplier = multiplier * kAlienTeamSetupBuildMultiplier
                 end
                self:Construct(deltaTime * multiplier)
                
            end
        
        end
        
        if self.timeDrifterConstructEnds then
            
            if self.timeDrifterConstructEnds <= Shared.GetTime() then
            
                self.hasDrifterEnzyme = false
                self.drifterbonusspeed = 1
                self.timeDrifterConstructEnds = nil
                
            end
            
        end

        // respect the cheat here; sometimes the cheat breaks due to things relying on it NOT being built until after a frame
        if GetGamerules():GetAutobuild() then
            self:SetConstructionComplete()
        end
        
    elseif Client then
    
        if GetIsMarineUnit(self) then
            if self.underConstruction then
                CreateBuildEffect(self)
            else
                RemoveBuildEffect(self)
            end
        end
    
    end
    
end

if Server then

    function ConstructMixin:OnKill()

        if not self:GetIsBuilt() then
        
            local techTree = self:GetTeam():GetTechTree()
            local techNode = techTree:GetTechNode(self:GetTechId())
            
            if techNode then
                techNode:SetResearchProgress(0.0)
                techTree:SetTechNodeChanged(techNode, "researchProgress = 1.0f")
            end 
            
        end
        
    end
    
end

function ConstructMixin:ModifyHeal(healTable)

    if not self:GetIsBuilt() then
    
        local maxFraction = kStartHealthScalar + (1 - kStartHealthScalar) * self.buildFraction    
        local maxHealth = self:GetMaxHealth() * maxFraction + self:GetMaxArmor() * maxFraction
        local health = self:GetHealth() + self:GetArmor()
        
        healTable.health = Clamp(maxHealth - health, 0, healTable.health) 
    
    end

end

function ConstructMixin:ResetConstructionStatus()

    self.buildTime = 0
    self.buildFraction = 0
    self.constructionComplete = false
    
end

function ConstructMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function ConstructMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function ConstructMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("ConstructMixin:OnUpdateAnimationInput")    
    modelMixin:SetAnimationInput("built", self.constructionComplete)
    modelMixin:SetAnimationInput("active", self.constructionComplete) // TODO: remove this and adjust animation graphs
    
end

function ConstructMixin:OnUpdatePoseParameters()

    self:SetPoseParam("grow", self.buildFraction)
    
end    

/**
 * Add health to structure as it builds.
 */
local function AddBuildHealth(self, scalar)

    // Add health according to build time.
    if scalar > 0 then
    
        local maxHealth = self:GetMaxHealth()
        self:AddHealth(scalar * (1 - kStartHealthScalar) * maxHealth, false, false, true)
        
    end
    
end

/**
 * Add health to structure as it builds.
 */
local function AddBuildArmor(self, scalar)

    // Add health according to build time.
    if scalar > 0 then
    
        local maxArmor = self:GetMaxArmor()
        self:SetArmor(self:GetArmor() + scalar * (1 - kStartHealthScalar) * maxArmor, true)
        
    end
    
end

/**
 * Build structure by elapsedTime amount and play construction sounds. Pass custom construction sound if desired, 
 * otherwise use Gorge build sound or Marine sparking build sounds. Returns two values - whether the construct
 * action was successful and if enough time has elapsed so a construction AV effect should be played.
 */
function ConstructMixin:Construct(elapsedTime, builder)

    local success = false
    local playAV = false
    
    if not self.constructionComplete and (not HasMixin(self, "Live") or self:GetIsAlive()) then
        
        if builder and builder.OnConstructTarget then
            builder:OnConstructTarget(self)
        end
        
        if Server then

            if not self.lastBuildFractionTechUpdate then
                self.lastBuildFractionTechUpdate = self.buildFraction
            end
            
            local techTree = self:GetTeam():GetTechTree()
            local techNode = techTree:GetTechNode(self:GetTechId())

            local modifier = (self:GetTeamType() == kMarineTeamType and GetIsPointOnInfestation(self:GetOrigin())) and kInfestationBuildModifier or 1
            local gameRules = GetGamerules()
            if self:GetTeamType() == kMarineTeamType and gameRules:GetGameStarted() and Shared.GetTime() - gameRules:GetGameStartTime() < (kFrontDoorTime)  then modifier = modifier * kMarineTeamSetupBuildMultiplier end
            local startBuildFraction = self.buildFraction
            local newBuildTime = self.buildTime + elapsedTime * modifier
            local timeToComplete = self:GetTotalConstructionTime()           
            
            if newBuildTime >= timeToComplete then
            
                self:SetConstructionComplete(builder)
                
                if techNode then
                    techNode:SetResearchProgress(1.0)
                    techTree:SetTechNodeChanged(techNode, "researchProgress = 1.0f")
                end    
                
            else
            
                if self.buildTime <= self.timeOfNextBuildWeldEffects and newBuildTime >= self.timeOfNextBuildWeldEffects then
                
                    playAV = true
                    self.timeOfNextBuildWeldEffects = newBuildTime + kBuildEffectsInterval
                    
                end
                
                self.timeLastConstruct = Shared.GetTime()
                self.underConstruction = true
                
                self.buildTime = newBuildTime
                self.oldBuildFraction = self.buildFraction
                self.buildFraction = math.max(math.min((self.buildTime / timeToComplete), 1), 0)
                
                if techNode and (self.buildFraction - self.lastBuildFractionTechUpdate) >= 0.05 then
                
                    techNode:SetResearchProgress(self.buildFraction)
                    techTree:SetTechNodeChanged(techNode, string.format("researchProgress = %.2f", self.buildFraction))
                    self.lastBuildFractionTechUpdate = self.buildFraction
                    
                end
                
                if not self.GetAddConstructHealth or self:GetAddConstructHealth() then
                
                    local scalar = self.buildFraction - startBuildFraction
                    AddBuildHealth(self, scalar)
                    AddBuildArmor(self, scalar)
                
                end
                
                if self.oldBuildFraction ~= self.buildFraction then
                
                    if self.OnConstruct then
                        self:OnConstruct(builder, self.buildFraction, self.oldBuildFraction)
                    end
                    
                end
                
            end
        
        end
        
        success = true
        
    end
    
    if playAV then

        local builderClassName = builder and builder:GetClassName()    
        self:TriggerEffects("construct", {classname = self:GetClassName(), doer = builderClassName, isalien = GetIsAlienUnit(self)})
        
    end 
    
    return success, playAV
    
end

function ConstructMixin:GetCanBeUsedConstructed(byPlayer)
    return false
end

function ConstructMixin:GetCanBeUsed(player, useSuccessTable)

    if self:GetIsBuilt() and not self:GetCanBeUsedConstructed(player) then
        useSuccessTable.useSuccess = false
    end
    
end

function ConstructMixin:SetConstructionComplete(builder)

    // Construction cannot resurrect the dead.
    if self:GetIsAlive() then
    
        local wasComplete = self.constructionComplete
        self.constructionComplete = true
        
        AddBuildHealth(self, 1 - self.buildFraction)
        AddBuildArmor(self, 1 - self.buildFraction)
        
        self.buildFraction = 1
        
        if wasComplete ~= self.constructionComplete then
            self:OnConstructionComplete(builder)
        end
        
    end
    
end


function ConstructMixin:GetCanConstruct(constructor)

    if self.GetCanConstructOverride then
        return self:GetCanConstructOverride(constructor)
    end
    
    // Check if we're on infestation
    // Doing the origin-based check may be expensive, but this is only done sparsely. And better than tracking infestation all the time.
    if LookupTechData(self:GetTechId(), kTechDataNotOnInfestation) and GetIsPointOnInfestation(self:GetOrigin()) then
        return false
    end
    
    return not self:GetIsBuilt() and GetAreFriends(self, constructor) and self:GetIsAlive() and
           (not constructor or constructor:isa("Marine") or constructor:isa("Gorge") or constructor:isa("MAC"))
    
end

function ConstructMixin:OnUse(player, elapsedTime, useSuccessTable)

    local used = false

    if not GetIsAlienUnit(self) and self:GetCanConstruct(player) then        

        // Always build by set amount of time, for AV reasons
        // Calling code will put weapon away we return true

        local success, playAV = self:Construct(kUseInterval, player)
        
        if success then

            used = true
        
        end
                
    end
    
    useSuccessTable.useSuccess = useSuccessTable.useSuccess or used
    
end

function ConstructMixin:RefreshDrifterConstruct(drifterbonusspeed)

    self.timeDrifterConstructEnds = Shared.GetTime() + 0.3
    self.hasDrifterEnzyme = true
    self.drifterbonusspeed = drifterbonusspeed
end

function ConstructMixin:OnHealSpray(gorge)

    if not gorge:isa("Gorge") then
        return
    end

    if GetIsAlienUnit(self) and GetAreFriends(self, gorge) and not self:GetIsBuilt() then
    
        local currentTime = Shared.GetTime()
        
        -- Multiple Gorges scale non-linearly 
        local timePassed = Clamp((currentTime - self.timeOfLastHealSpray), 0, kMaxBuildTimePerHealSpray)
        local constructTimeForSpray = math.min(kMinBuildTimePerHealSpray + timePassed, kMaxBuildTimePerHealSpray)

        --Print("added time: %.2f (time passed: %.2f)", constructTimeForSpray, timePassed)
        
        local success, playAV = self:Construct(constructTimeForSpray, gorge)
        
        self.timeOfLastHealSpray = currentTime
        
    end

end

function ConstructMixin:GetIsBuilt()
    return self.constructionComplete
end

function ConstructMixin:OnConstructionComplete(builder)

    local team = HasMixin(self, "Team") and self:GetTeam()
    
    if team then

        if self.GetCompleteAlertId then
            team:TriggerAlert(self:GetCompleteAlertId(), self)
            
        elseif GetIsMarineUnit(self) then

            if builder and builder:isa("MAC") then    
                team:TriggerAlert(kTechId.MACAlertConstructionComplete, self)
            else            
                team:TriggerAlert(kTechId.MarineAlertConstructionComplete, self)
            end
            
        end

        team:OnConstructionComplete(self)

    end     

    self:TriggerEffects("construction_complete")
    
end    

function ConstructMixin:GetBuiltFraction()
    return self.buildFraction
end

function ConstructMixin:GetTotalConstructionTime()
    return LookupTechData(self:GetTechId(), kTechDataBuildTime, kDefaultBuildTime)
end

if Server then

    function ConstructMixin:Reset()

        if self.startsBuilt then
            self:SetConstructionComplete()
        end
        
    end

    function ConstructMixin:OnInitialized()

        self.startsBuilt = GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false)

        if (self.startsBuilt and not self:GetIsBuilt()) then
            self:SetConstructionComplete()
        end
        
    end

end

function ConstructMixin:GetEffectParams(tableParams)

    tableParams[kEffectFilterBuilt] = self:GetIsBuilt()
        
end
