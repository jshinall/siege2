// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Alien.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/Alien_Upgrade.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/EnergizeMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PrimalScreamMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/AlienActionFinderMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/StormCloudMixin.lua")
Script.Load("lua/PlayerHallucinationMixin.lua")
Script.Load("lua/MucousableMixin.lua")
Script.Load("lua/RedemptionMixin.lua")
Script.Load("lua/Mixins/LadderMoveMixin.lua")

PrecacheAsset("cinematics/vfx_materials/decals/alien_blood.surface_shader")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'Alien' (Player)

Alien.kMapName = "alien"

if Server then
    Script.Load("lua/Alien_Server.lua")
elseif Client then
    Script.Load("lua/Alien_Client.lua")
end

PrecacheAsset("models/alien/alien.surface_shader")

Alien.kNotEnoughResourcesSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/more")

Alien.kChatSound = PrecacheAsset("sound/NS2.fev/alien/common/chat")
Alien.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/alien/commander/spend_nanites")

// Representative portrait of selected units in the middle of the build button cluster
Alien.kPortraitIconsTexture = "ui/alien_portraiticons.dds"

// Multiple selection icons at bottom middle of screen
Alien.kFocusIconsTexture = "ui/alien_focusicons.dds"

// Small mono-color icons representing 1-4 upgrades that the creature or structure has
Alien.kUpgradeIconsTexture = "ui/alien_upgradeicons.dds"

Alien.kAnimOverlayAttack = "attack"

Alien.kWalkBackwardSpeedScalar = 1

Alien.kEnergyRecuperationRate = 10.0

// How long our "need healing" text gets displayed under our blip
Alien.kCustomBlipDuration = 10
Alien.kEnergyAdrenalineRecuperationRate = 13

PrecacheAsset("materials/infestation/infestation.dds")
PrecacheAsset("materials/infestation/infestation_normal.dds")
PrecacheAsset("models/alien/infestation/infestation2.model")
PrecacheAsset("cinematics/vfx_materials/vfx_neuron_03.dds")

local kDefaultAttackSpeed = 1

local networkVars = 
{
    // The alien energy used for all alien weapons and abilities (instead of ammo) are calculated
    // from when it last changed with a constant regen added
    timeAbilityEnergyChanged = "time",
    abilityEnergyOnChange = "float (0 to " .. math.ceil(kAdrenalineAbilityMaxEnergy) .. " by 0.05 [] )",
    
    movementModiferState = "boolean",
    
    oneHive = "private boolean",
    twoHives = "private boolean",
    threeHives = "private boolean",
    fourHives = "private boolean",
    
    hasAdrenalineUpgrade = "boolean",
    
    enzymed = "boolean",
    
    infestationSpeedScalar = "private float",
    infestationSpeedUpgrade = "private boolean",
    
    storedHyperMutationTime = "private float",
    storedHyperMutationCost = "private float",
    
    silenceLevel = "integer (0 to 3)",
    
    electrified = "boolean",
    
    hatched = "private boolean",
    
    darkVisionSpectatorOn = "private boolean",
    
    isHallucination = "boolean",
    hallucinatedClientIndex = "integer",
    
    creationTime = "time",
    spawnprotection = "boolean",
   modelsize = "float (0 to 10 by .1)",
   rtdmaxhealincreasepercent = "float (-25 to 25 by 1)",
   infiniteenergy = "boolean", 
   rtdarmoradjustmentpercent = "float (-50 to 50 by 1)",
   rtdplayertoplayerdamagescale = "float (-25 to 25 by 1)",
   rtdplayertononplayerdamagescale = "float (-25 to 25 by 1)",
   isridingdrifter = "boolean",
   drifterId = "entityid",


}

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(EnergizeMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(StormCloudMixin, networkVars)
AddMixinNetworkVars(ScoringMixin, networkVars)
AddMixinNetworkVars(MucousableMixin, networkVars)
AddMixinNetworkVars(LadderMoveMixin, networkVars)
AddMixinNetworkVars(PrimalScreamMixin, networkVars)

function Alien:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, FireMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, EnergizeMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, AlienActionFinderMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, StormCloudMixin)
    InitMixin(self, MucousableMixin)
    InitMixin(self, LadderMoveMixin)
    InitMixin(self, PrimalScreamMixin)
    InitMixin(self, RedemptionMixin)
        
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    self.timeLastMomentumEffect = 0
 
    self.timeAbilityEnergyChange = Shared.GetTime()
    self.abilityEnergyOnChange = self:GetMaxEnergy()
    self.lastEnergyRate = self:GetRecuperationRate()
    
    // Only used on the local client.
    self.darkVisionOn = false
    self.lastDarkVisionState = false
    self.darkVisionLastFrame = false
    self.darkVisionTime = 0
    self.darkVisionEndTime = 0
    
    self.oneHive = false
    self.twoHives = false
    self.threeHives = false
    self.fourHives = false
    self.enzymed = false
    
    self.infestationSpeedScalar = 0
    self.infestationSpeedUpgrade = false
    if self:isa("Skulk") then self.spawnprotection = true end
    if Server then
        self.timeInfiniteEnergyExpires = 0
        self.timeWhenEnzymeExpires = 0
        self.timeLastCombatAction = 0
        self.silenceLevel = 0
        self.rtdplayertoplayerdamagescaleExpires = 0
       self.rtdplayertononplayerdamagescaleExpires = 0
 
        self.electrified = false
        self.timeElectrifyEnds = 0
        
    elseif Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
      self.modelsize = 1  
      self.infiniteenergy = false
      self.rtdmaxhealincreasepercent = 0
      self.rtdarmoradjustmentpercent = 0
     self.rtdplayertoplayerdamagescale = 0
     self.rtdplayertononplayerdamagescale = 0
     self.isridingdrifter = false
     self.drifterId = Entity.invalidI
end

function Alien:OnJoinTeam()
    
    Player.OnJoinTeam( self )
    
    if self:GetTeamNumber() ~= kNeutralTeamType then
        self.oneHive = false
        self.twoHives = false
        self.threeHives = false
        self.fourHives = false
    end

end

function Alien:OnInitialized()

    Player.OnInitialized(self)
    
    InitMixin(self, CloakableMixin)

    self.armor = self:GetArmorAmount()
    self.maxArmor = self.armor
    
    if Server then
    
        InitMixin(self, InfestationTrackerMixin)
        UpdateAbilityAvailability(self, self:GetTierOneTechId(), self:GetTierTwoTechId(), self:GetTierThreeTechId())
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
       if self:GetIsAlive() and self:GetTeamNumber() == 2 then
      if self:isa("Skulk") then self:AddTimedCallback(function() self:SetHasFireProofUmbra(true, 5) end, 0.06) end
       self:AddTimedCallback(function() self.spawnprotection = false end, 5.06)
       end
    elseif Client then
    
        InitMixin(self, HiveVisionMixin)
        
        if self:GetIsLocalPlayer() and self.hatched then
            self:TriggerHatchEffects()
        end
        
    end
    
    if Client and Client.GetLocalPlayer() == self then
    
        Client.SetPitch(0.0)
        self:AddHelpWidget("GUIAlienVisionHelp", 2)
        
    end
    
    if self.isHallucination then    
        InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })
    end

end
function Alien:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)

    if hitPoint ~= nil and self.spawnprotection then 
    
        damageTable.damage = 0
        
    end

end
function Alien:GetHasOutterController()
    return not self.isHallucination and Player.GetHasOutterController(self)
end    

function Alien:SetHatched()
    self.hatched = true
end

function Alien:GetCanRepairOverride(target)
    return false
end


// player for local player
function Alien:TriggerHatchEffects()
    self.clientTimeTunnelUsed = Shared.GetTime()
end

function Alien:GetArmorAmount()

    local carapaceAmount = 0
    
    if GetHasCarapaceUpgrade(self) then
    local derp = self:GetArmorFullyUpgradedAmount() * self.modelsize
        return  derp * (self.rtdarmoradjustmentpercent/100) + derp
    end
   local herp = self:GetBaseArmor() * self.modelsize
    return herp * (self.rtdarmoradjustmentpercent/100) + herp
   
end

function Alien:UpdateArmorAmount(carapaceLevel)

    local level = GetHasCarapaceUpgrade(self) and carapaceLevel or 0
    local newMaxArmor = ( (level / 3) * (self:GetArmorFullyUpgradedAmount() - self:GetBaseArmor()) + self:GetBaseArmor() ) * self.modelsize
    local derp = newMaxArmor * (self.rtdarmoradjustmentpercent/100) + newMaxArmor

    if derp ~= self.maxArmor then

        local armorPercent = self.maxArmor > 0 and self.armor/self.maxArmor or 0
        self.maxArmor = derp
        self:SetArmor( self.maxArmor * armorPercent )
    
    end

end

function Alien:SetElectrified(time)

    if self.timeElectrifyEnds - Shared.GetTime() < time then
    
        self.timeElectrifyEnds = Shared.GetTime() + time
        self.electrified = true
        
    end
    
end

if Server then

    local function Electrify(client)
    
        if Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            if player.SetElectrified then
                player:SetElectrified(5)
            end
            
        end
        
    end
    Event.Hook("Console_electrify", Electrify)
    
end

function Alien:UpdateHealthAmount(bioMassLevel, maxLevel)

    local level = math.max(0, bioMassLevel - 1)
    local newMaxHealth = ( (self:GetBaseHealth() + level * self:GetHealthPerBioMass()) * self.modelsize ) 
    local finalmaxhealth = newMaxHealth * (self.rtdmaxhealincreasepercent/100) + newMaxHealth

    if finalmaxhealth ~= self.maxHealth  then

        local healthPercent = self.maxHealth > 0 and self.health/self.maxHealth or 0
        self:SetMaxHealth(finalmaxhealth)
        self:SetHealth(self.maxHealth * healthPercent)
    
    end

end

function Alien:GetCanCatalystOverride()
    return false
end

function Alien:GetCarapaceSpeedReduction()
    return kCarapaceSpeedReduction
end

function Alien:GetCarapaceFraction()

    local maxCarapaceArmor = self:GetMaxArmor() - self:GetBaseArmor()
    local currentCarpaceArmor = math.max(0, self:GetArmor() - self:GetBaseArmor())
    
    if maxCarapaceArmor == 0 then
        return 0
    end

    return currentCarpaceArmor / maxCarapaceArmor

end

function Alien:GetCarapaceMovementScalar()

    if GetHasCarapaceUpgrade(self) then
        return 1 - self:GetCarapaceFraction() * self:GetCarapaceSpeedReduction()    
    end
    
    return 1

end

function Alien:GetSlowSpeedModifier()
    return Player.GetSlowSpeedModifier(self) * self:GetCarapaceMovementScalar()
end

function Alien:GetHasOneHive()
    return self.oneHive
end

function Alien:GetHasTwoHives()
    return self.twoHives
end

function Alien:GetHasThreeHives()
    return self.threeHives
end
function Alien:GetHasFourHives()
    return self.fourHives
end
// For special ability, return an array of totalPower, minimumPower, tex x offset, tex y offset, 
// visibility (boolean), command name
function Alien:GetAbilityInterfaceData()
    return { }
end

local function CalcEnergy(self, rate)
    local dt = Shared.GetTime() - self.timeAbilityEnergyChanged
    local result = Clamp(self.abilityEnergyOnChange + dt * rate, 0, self:GetMaxEnergy())
    return result
end

function Alien:GetEnergy()
    local rate = self:GetRecuperationRate()
    if self.lastEnergyRate ~= rate then
        // we assume we ask for energy enough times that the change in energy rate
        // will hit on the same tick they occure (or close enough)
        self.abilityEnergyOnChange = CalcEnergy(self, self.lastEnergyRate)
        self.timeAbilityEnergyChange = Shared.GetTime()
    end
    self.lastEnergyRate = rate
    return CalcEnergy(self, rate)
end
function Alien:GetModelSize()
return self.modelsize
end
function Alien:AddEnergy(energy)
    assert(energy >= 0)
    self.abilityEnergyOnChange = Clamp(self:GetEnergy() + energy, 0, self:GetMaxEnergy())
    self.timeAbilityEnergyChanged = Shared.GetTime()
end

function Alien:SetEnergy(energy)
    self.abilityEnergyOnChange = Clamp(energy, 0, self:GetMaxEnergy())
    self.timeAbilityEnergyChanged = Shared.GetTime()
end

function Alien:DeductAbilityEnergy(energyCost)

    if not self:GetDarwinMode() and not self:GetHasInfiniteEnergy() then
    
        local maxEnergy = self:GetMaxEnergy()
    
        self.abilityEnergyOnChange = Clamp(self:GetEnergy() - energyCost, 0, maxEnergy)
        self.timeAbilityEnergyChanged = Shared.GetTime()
        
    end
    
end

function Alien:GetRecuperationRate()

    local scalar = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnFire), kOnFireEnergyRecuperationScalar, 1)
    scalar = scalar * (self.electrified and kElectrifiedEnergyRecuperationScalar or 1)
    local rate = 0

    if self.hasAdrenalineUpgrade then
        rate = (( Alien.kEnergyAdrenalineRecuperationRate - Alien.kEnergyRecuperationRate) * (GetSpurLevel(self:GetTeamNumber()) / 3) + Alien.kEnergyRecuperationRate)
    else
        rate = Alien.kEnergyRecuperationRate
    end
    
    rate = rate * scalar
 
    return rate
    
end

function Alien:OnGiveUpgrade(techId)

    if techId == kTechId.Camouflage then
        TEST_EVENT("Camouflage evolved")
    elseif techId == kTechId.Regeneration then
        TEST_EVENT("Regeneration evolved")
    end

end

function Alien:GetMaxEnergy()
    return ConditionalValue(self.hasAdrenalineUpgrade, (kAdrenalineAbilityMaxEnergy - kAbilityMaxEnergy) * (GetSpurLevel(self:GetTeamNumber()) / 3) + kAbilityMaxEnergy, kAbilityMaxEnergy)
end

function Alien:GetAdrenalineMaxEnergy()
    
    if self.hasAdrenalineUpgrade then
        return (kAdrenalineAbilityMaxEnergy - kAbilityMaxEnergy) * (GetSpurLevel(self:GetTeamNumber()) / 3)
    end
    
    return 0
    
end

function Alien:GetMaxBackwardSpeedScalar()
    return Alien.kWalkBackwardSpeedScalar
end

// for marquee selection
function Alien:GetIsMoveable()
    return false
end

function Alien:SetDarkVision(state)
    self.darkVisionOn = state
    self.darkVisionSpectatorOn = state
end

function Alien:GetControllerPhysicsGroup()

    if self.isHallucination then
        return PhysicsGroup.SmallStructuresGroup
    end

    return Player.GetControllerPhysicsGroup(self)

end

function Alien:GetHallucinatedClientIndex()
    return self.hallucinatedClientIndex
end

function Alien:SetHallucinatedClientIndex(clientIndex)
    self.hallucinatedClientIndex = clientIndex
end

function Alien:HandleButtons(input)

    PROFILE("Alien:HandleButtons")   
    
    Player.HandleButtons(self, input)
    
    // Update alien movement ability
    local newMovementState = bit.band(input.commands, Move.MovementModifier) ~= 0
    if newMovementState ~= self.movementModiferState and self.movementModiferState ~= nil then
        self:MovementModifierChanged(newMovementState, input)
    end
    
    self.movementModiferState = newMovementState
    
    if self:GetCanControl() and (Client or Server) then
    
        local darkVisionPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.darkVisionLastFrame and darkVisionPressed then
            self:SetDarkVision(not self.darkVisionOn)
        end
        
        self.darkVisionLastFrame = darkVisionPressed

    end
    
end

function Alien:GetIsCamouflaged()
    return GetHasCamouflageUpgrade(self) and not self:GetIsInCombat()
end

function Alien:GetNotEnoughResourcesSound()
    return Alien.kNotEnoughResourcesSound
end

// Returns true when players are selecting new abilities. When true, draw small icons
// next to your current weapon and force all abilities to draw.
function Alien:GetInactiveVisible()
    return Shared.GetTime() < self:GetTimeOfLastWeaponSwitch() + kDisplayWeaponTime
end

/**
 * Must override.
 */
function Alien:GetBaseArmor()
    assert(false)
end

function Alien:GetBaseHealth()
    assert(false)
end

function Alien:GetHealthPerBioMass()
    assert(false)
end

/**
 * Must override.
 */
function Alien:GetArmorFullyUpgradedAmount()
    assert(false)
end

function Alien:GetCanBeHealedOverride()

    return self:GetIsAlive()
end

function Alien:MovementModifierChanged(newMovementModifierState, input)
end

/**
 * Aliens cannot climb ladders.
 */
function Alien:GetCanClimb()
    return false
end

function Alien:GetChatSound()
    return Alien.kChatSound
end

function Alien:GetDeathMapName()
    return AlienSpectator.kMapName
end

// Returns the name of the player's lifeform
function Alien:GetPlayerStatusDesc()

    local status = kPlayerStatus.Void
    
    if (self:GetIsAlive() == false) then
        status = kPlayerStatus.Dead
    else
        if (self:isa("Embryo")) then
            if self.gestationTypeTechId == kTechId.Skulk then
                status = kPlayerStatus.SkulkEgg
            elseif self.gestationTypeTechId == kTechId.Gorge then
                status = kPlayerStatus.GorgeEgg
            elseif self.gestationTypeTechId == kTechId.Lerk then
                status = kPlayerStatus.LerkEgg
            elseif self.gestationTypeTechId == kTechId.Fade then
                status = kPlayerStatus.FadeEgg
            elseif self.gestationTypeTechId == kTechId.Onos then
                status = kPlayerStatus.OnosEgg
            else
                status = kPlayerStatus.Embryo
            end
        else
            status = kPlayerStatus[self:GetClassName()]
        end
    end
    
    return status

end

function Alien:OnCatalyst()
end

function Alien:OnCatalystEnd()
end

function Alien:GetCanTakeDamageOverride()
    return Player.GetCanTakeDamageOverride(self)
end

function Alien:GetEffectParams(tableParams)

    tableParams[kEffectFilterSilenceUpgrade] = self.silenceLevel == 3
    tableParams[kEffectParamVolume] = 1 - Clamp(self.silenceLevel / 3, 0, 1)

end

function Alien:GetIsEnzymed()
    return self.enzymed
end
function Alien:GetHasInfiniteEnergy()
return self.infiniteenergy
end
function Alien:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)
    local scale = 1
    if self.modelsize > 1 then scale = self.modelsize end
    local attackSpeed = self:GetIsEnzymed() and kEnzymeAttackSpeed or kDefaultAttackSpeed
    attackSpeed = attackSpeed * ( self.electrified and kElectrifiedAttackSpeed or 1 )
    attackSpeed = attackSpeed + ( self:GetHasPrimalScream() and kPrimalScreamROFIncrease or 0)
    attackSpeed = attackSpeed / scale
    if self.ModifyAttackSpeed then
    
        local attackSpeedTable = { attackSpeed = attackSpeed }
        self:ModifyAttackSpeed(attackSpeedTable)
        attackSpeed = attackSpeedTable.attackSpeed
        
    end
    
    modelMixin:SetAnimationInput("attack_speed", attackSpeed)
    
end
/*
function Alien:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)
    
    local attackSpeed = self:GetIsEnzymed() and kEnzymeAttackSpeed or kDefaultAttackSpeed
    attackSpeed = attackSpeed * ( self.electrified and kElectrifiedAttackSpeed or 1 )
    if self.ModifyAttackSpeed then
    
        local attackSpeedTable = { attackSpeed = attackSpeed }
        self:ModifyAttackSpeed(attackSpeedTable)
        attackSpeed = attackSpeedTable.attackSpeed
        
    end
    
    modelMixin:SetAnimationInput("attack_speed", attackSpeed)
    
end
*/
/*
function Alien:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("attack_speed", self:GetAttackSpeed())
    
end

function Alien:GetAttackSpeed()
    return kDefaultAttackSpeed * self:GetAttackSpeedModifiers()
end
function Alien:GetAttackSpeedModifiers()
  local finalspeed = 1
  local multamount = 1
  local addamount = 0
  local multanother = 1
if self:GetIsEnzymed() then multamount = multamount * kEnzymeAttackSpeed end
if self.electrified then multanother = multanother * kElectrifiedAttackSpeed end
if self:GetHasPrimalScream() then addamount = addamount + kPrimalScreamROFIncrease end
finalspeed = finalspeed * multamount + addamount * multanother
  return finalspeed 
end
*/
function Alien:GetHasMovementSpecial()
    return false
end   

function Alien:ModifyHeal(healTable)

    if self.isOnFire then
        healTable.health = healTable.health * kOnFireHealingScalar
    end
    
    if self.lasthealingtable == nil then
        self.lasthealingtable = {time = 0, healing = 0}
    end
    
    local curtime = Shared.GetTime()
    
    if curtime < self.lasthealingtable.time + kAlienHealRateTimeLimit then
        //Within timer, check values.
        //Check current max limit
        local tHeal = 0     //Previous heals within timer.
        local rHeal = 0     //Unmodded heal from this heal instance.
        local mHeal = 0     //Modded heal from this instance.
        local pHeal = 0     //Current percentage of healing within timer, including this heal instance.
        local nHeal = 0     //Final effective heal after all modifications.
        tHeal = self.lasthealingtable.healing
        rHeal = healTable.health
        pHeal = (tHeal + rHeal) / self:GetBaseHealth()
        if (tHeal + rHeal) > kAlienHealRateLimit then
            //We're over the limit, reduce.
            //Get amount of health to mod, can only mod max amount recieving this heal.
            mHeal = Clamp((tHeal + rHeal) - kAlienHealRateLimit, 0, rHeal)
            //Adjust 'real' heal accordingly for partial amounts that were under limit
            rHeal = math.max(rHeal - mHeal, 0)
        elseif pHeal >= kAlienHealRatePercentLimit then
            //We're over the limit, reduce.
            //Get correct amount of HP to reduce if just exceeding cap.
            mHeal = Clamp((tHeal + rHeal) - (self:GetBaseHealth() * kAlienHealRatePercentLimit), 0, rHeal)
            //Lower 'real' unmodded healing accordingly.
            rHeal = math.max(rHeal - mHeal, 0)
        end
        nHeal = rHeal + math.max(mHeal * kAlienHealRateOverLimitReduction, 0)
        //Shared.Message(string.format("Healing cap information - Total Amount :%s - CurrentHeal :%s - Current Heal Percent :%s - Effective Heal :%s - 'Real' Heal :%s - 'Mod' Heal :%s - Healing Window :%s ", tHeal, healTable.health, pHeal, nHeal, rHeal, mHeal, kAlienHealRateTimeLimit))
        //Add to current limit
        healTable.health = nHeal
        self.lasthealingtable.healing = tHeal + nHeal
    else
        //Not under limit, clear table
        self.lasthealingtable.time = curtime
        self.lasthealingtable.healing = healTable.health
    end
    
end 

function Alien:UpdateMove( input , runningPrediction )

	if self.isridingdrifter then 
	 	local drifter = Shared.GetEntity( self.drifterId ) 
	 	local offset = drifter:GetOrigin() + Vector(0,1,0)
	 	self:SetOrigin(offset)
        if not self:GetOrigin() == offset then self:SetOrigin(offset) end
     end
end

Shared.LinkClassToMap("Alien", Alien.kMapName, networkVars, true)
