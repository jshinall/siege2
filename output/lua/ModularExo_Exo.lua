
Script.Load("lua/Exo.lua")
Script.Load("lua/PhaseGateUserMixin.lua")

local networkVars = {
    powerModuleType    = "enum kExoModuleTypes",
	rightArmModuleType = "enum kExoModuleTypes",
	leftArmModuleType  = "enum kExoModuleTypes",

    utilityModuleType  = "enum kExoModuleTypes",
    
	hasPhaseGate = "boolean",
    hasNano = "boolean",
	armorBonus = "float (0 to 2045 by 1)",

}

local kMaxSpeed = 6

local orig_Exo_OnInitialized = Exo.OnInitialized
function Exo:OnInitialized()
    self.powerModuleType = self.powerModuleType or kExoModuleTypes.Power1
    self.leftArmModuleType = self.leftArmModuleType or kExoModuleTypes.Claw
    self.rightArmModuleType = self.rightArmModuleType or kExoModuleTypes.Minigun
    self.armorModuleType = self.armorModuleType or kExoModuleTypes.None
    self.utilityModuleType = self.utilityModuleType or kExoModuleTypes.None
    
    local armorModuleData = kExoModuleTypesData[self.utilityModuleType]
    self.armorBonus = armorModuleData and armorModuleData.armorBonus or 0
    self.hasPhaseGate = (self.utilityModuleType == kExoModuleTypes.PhaseGate)
    self.hasNano = (self.utilityModuleType == kExoModuleTypes.Nano)
    self.timeLastWeldEffect = 0 
    
    orig_Exo_OnInitialized(self)
end

local orig_Exo_InitExoModel = Exo.InitExoModel
function Exo:InitExoModel(overrideAnimGraph)
    local leftArmType = (kExoModuleTypesData[self.leftArmModuleType] or {}).armType
    local rightArmType = (kExoModuleTypesData[self.rightArmModuleType] or {}).armType
    local modelData = (kExoWeaponRightLeftComboModels[rightArmType] or {})[leftArmType] or {}
    local modelName = modelData.worldModel or "models/marine/exosuit/exosuit_rr.model"
    local graphName = modelData.worldAnimGraph or "models/marine/exosuit/exosuit_rr.animation_graph"
    self:SetModel(modelName, overrideAnimGraph or graphName)
    self.viewModelName = modelData.viewModel or "models/marine/exosuit/exosuit_rr_view.model"
    self.viewModelGraphName = modelData.viewAnimGraph or "models/marine/exosuit/exosuit_rr_view.animation_graph"
end

local kDeploy2DSound = PrecacheAsset("sound/NS2.fev/marine/heavy/deploy_2D")
local orig_Exo_InitWeapons = Exo.InitWeapons
function Exo:InitWeapons()
    Player.InitWeapons(self)
    
    local weaponHolder = self:GetWeapon(ExoWeaponHolder.kMapName)
    if not weaponHolder then
        weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)   
    end
    
    if self.layout then
            if self.layout == "ClawMinigun" then
           weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
        elseif self.layout == "MinigunMinigun" then
           weaponHolder:SetWeapons(Minigun.kMapName, Minigun.kMapName)
        elseif self.layout == "ClawRailgun" then
           weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
        elseif self.layout == "RailgunRailgun" then
           weaponHolder:SetWeapons(Railgun.kMapName, Railgun.kMapName)
         else
           Print("Warning: incorrect layout set for exosuit")
          weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
          end
  
   elseif not self.layout then  
    local leftArmModuleTypeData = kExoModuleTypesData[self.leftArmModuleType]
    local rightArmModuleTypeData = kExoModuleTypesData[self.rightArmModuleType]
    weaponHolder:SetWeapons(leftArmModuleTypeData.mapName, rightArmModuleTypeData.mapName)
    
     weaponHolder:TriggerEffects("exo_login")
    self.inventoryWeight = self:CalculateWeight()
    self:SetActiveWeapon(ExoWeaponHolder.kMapName)
    StartSoundEffectForPlayer(kDeploy2DSound, self)
    return
    
    end
    
    Print("Warning: incorrect layout set for exosuit")
    weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
    weaponHolder:TriggerEffects("exo_login")
    self.inventoryWeight = self:CalculateWeight()
    self:SetActiveWeapon(ExoWeaponHolder.kMapName)
    StartSoundEffectForPlayer(kDeploy2DSound, self)
    
end

//local orig_Exo_GetIsThrusterAllowed = Exo.GetIsThrusterAllowed
//function Exo:GetIsThrusterAllowed()
	//return self.hasThrusters and orig_Exo_GetIsThrusterAllowed(self)
//end
local orig_Exo_GetCanPhase = PhaseGateUserMixin.GetCanPhase
function Exo:GetCanPhase()
	return self.hasPhaseGate and orig_Exo_GetCanPhase(self)
end 
local function UpdateIdle2DSound(self, yaw, pitch, dt)

    if self.idleSound2DId ~= Entity.invalidId then
    
        local idleSound2D = Shared.GetEntity(self.idleSound2DId)
        
        self.lastExoYaw = self.lastExoYaw or yaw
        self.lastExoPitch = self.lastExoPitch or pitch
        
        local yawDiff = math.abs(GetAnglesDifference(yaw, self.lastExoYaw))
        local pitchDiff = math.abs(GetAnglesDifference(pitch, self.lastExoPitch))
        
        self.lastExoYaw = yaw
        self.lastExoPitch = pitch
        
        local rotateSpeed = math.min(1, ((yawDiff ^ 2) + (pitchDiff ^ 2)) / 0.05)
        idleSound2D:SetParameter("rotate", rotateSpeed, 1)
        
    end
    
end
local function UpdateThrusterEffects(self)

    if self.clientThrustersActive ~= self.thrustersActive then
    
        self.clientThrustersActive = self.thrustersActive

        if self.thrustersActive then            
        
            local effectParams = {}
            effectParams[kEffectParamVolume] = 0.1
        
            self:TriggerEffects("exo_thruster_start", effectParams)         
        else
            self:TriggerEffects("exo_thruster_end")            
        end
    
    end
    
    local showEffect = ( not self:GetIsLocalPlayer() or self:GetIsThirdPerson() ) and self.thrustersActive
    self.thrusterLeftCinematic:SetIsVisible(showEffect)
    self.thrusterRightCinematic:SetIsVisible(showEffect)

end
local function HandleThrusterEnd(self)

    self.thrustersActive = false
    self.timeThrustersEnded = Shared.GetTime()
    
end
function Exo:OnProcessMove(input)
    Player.OnProcessMove(self, input)
    if self.catpackboost then
        self.catpackboost = Shared.GetTime() - self.timeCatpackboost < kCatPackDuration
    end
    
    if Client and not Shared.GetIsRunningPrediction() then
        UpdateIdle2DSound(self, input.yaw, input.pitch, input.time)
        UpdateThrusterEffects(self)
    end
    
    local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
    if not self.flashlightLastFrame and flashlightPressed then
    
        self:SetFlashlightOn(not self:GetFlashlightOn())
        StartSoundEffectOnEntity(Marine.kFlashlightSoundName, self, 1, self)
        
    end
    self.flashlightLastFrame = flashlightPressed
      if self.hasNano and not self:GetIsInCombat() then
               self:SetArmor(self:GetArmor() + input.time * kNanoArmorHealPerSecond, true) 
   end
end
local orig_Exo_GetSlowOnLand = Exo.GetSlowOnLand
function Exo:GetSlowOnLand()
    return true
end
local orig_Exo_GetWebSlowdownScalar = Exo.GetWebSlowdownScalar
function Exo:GetWebSlowdownScalar()
    return 0.6
end

local orig_Exo_GetArmorAmount = Exo.GetArmorAmount 
function Exo:GetArmorAmount(armorLevels)
	
	if not armorLevels then
    
        armorLevels = 0
    
        if GetHasTech(self, kTechId.Armor3, true) then
            armorLevels = 3
        elseif GetHasTech(self, kTechId.Armor2, true) then
            armorLevels = 2
        elseif GetHasTech(self, kTechId.Armor1, true) then
            armorLevels = 1
        end
    
    end

	return ( 340 + armorLevels * 40 + self.armorBonus ) * self.modelsize

end

function Exo:ProcessExoModularBuyAction(message)
    ModularExo_HandleExoModularBuy(self, message)
end
/*
function Exo:GetCanBeWeldedOverride()
return not self.hasnano
end
*/
function Exo:CalculateWeight()
    return ModularExo_GetConfigWeight(ModularExo_ConvertNetMessageToConfig(self))
end

if Server then
    local orig_Exo_PerformEject = Exo.PerformEject
    function Exo:PerformEject()
        if self:GetIsAlive() then
            -- pickupable version
            local exosuit = CreateEntity(Exosuit.kMapName, self:GetOrigin(), self:GetTeamNumber(), {
                powerModuleType    = self.powerModuleType   ,
                rightArmModuleType = self.rightArmModuleType,
                leftArmModuleType  = self.leftArmModuleType ,
                armorModuleType    = self.armorModuleType   ,
                utilityModuleType  = self.utilityModuleType ,
            })
            exosuit:SetCoords(self:GetCoords())
            exosuit:SetMaxArmor(self:GetMaxArmor())
            exosuit:SetArmor(self:GetArmor())
            
            local reuseWeapons = self.storedWeaponsIds ~= nil
            
            local marine = self:Replace(self.prevPlayerMapName or Marine.kMapName, self:GetTeamNumber(), false, self:GetOrigin() + Vector(0, 0.2, 0), { preventWeapons = reuseWeapons })
            marine:SetHealth(self.prevPlayerHealth or kMarineHealth)
            marine:SetMaxArmor(self.prevPlayerMaxArmor or kMarineArmor)
            marine:SetArmor(self.prevPlayerArmor or kMarineArmor)
            
            exosuit:SetOwner(marine)
            
            marine.onGround = false
            local initialVelocity = self:GetViewCoords().zAxis
            initialVelocity:Scale(4)
            initialVelocity.y = 9
            marine:SetVelocity(initialVelocity)
            
            if reuseWeapons then
                for _, weaponId in ipairs(self.storedWeaponsIds) do
                    local weapon = Shared.GetEntity(weaponId)
                    if weapon then
                        marine:AddWeapon(weapon)
                    end
                end
            end
            marine:SetHUDSlotActive(1)
            if marine:isa("JetpackMarine") then
                marine:SetFuel(0)
            end
        end
        return false
    end 
end
if Client then
    local orig_Exo_BuyMenu = Exo.BuyMenu
    function Exo:BuyMenu(structure)
        if self:GetTeamNumber() ~= 0 and Client.GetLocalPlayer() == self then
            if not self.buyMenu then
                self.buyMenu = GetGUIManager():CreateGUIScript("GUIModularExoBuyMenu")
                MarineUI_SetHostStructure(structure)
                if structure then
                    self.buyMenu:SetHostStructure(structure)
                end
                self:TriggerEffects("marine_buy_menu_open")
                TEST_EVENT("Exo buy menu displayed")
            end
        end
    end
end


Class_Reload("Exo", networkVars)
