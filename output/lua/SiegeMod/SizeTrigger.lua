Script.Load("lua/ExtraEntitiesMod/LogicMixin.lua")

class 'SizeTrigger' (Trigger)

SizeTrigger.kMapName = "size_trigger"

local networkVars =
{
}


AddMixinNetworkVars(LogicMixin, networkVars)

function SizeTrigger:OnCreate()
 
    Trigger.OnCreate(self)  
    self.alreadyaltered = {}
    
end
local function GetTeamType(self)
    return self.teamType ~= nil and self.teamType
end
local function ScaleEntity(self, entity)
    local team = self.TeamNumber
    if self.enabled and entity:isa("Player") and 
    entity:GetTeamNumber() == team or team == 0 and
     entity:isa("%s", self.Classname) or self.Classname == "All" and not self.alreadyaltered[entity]
     then
      local size = self.Percentage
      entity.modelsize = size
     local defaulthealth = LookupTechData(entity:GetTechId(), kTechDataMaxHealth, 1)
     entity:AdjustMaxHealth(defaulthealth * size)
   if not entity:isa("Onos") then entity:AdjustMaxArmor(entity:GetMaxArmor() * size) end
     if Shared.GetMapName() ~= "ns_supersiege" and Shared.GetMapName() ~= "ns_siegeaholic_remade" then self.alreadyaltered[entity] = true end
    end
    
end

local function SizeAllInTrigger(self)

    for _, entity in ipairs(self:GetEntitiesInTrigger()) do
        ScaleEntity(self, entity)
    end
    
end

function SizeTrigger:OnInitialized()

    Trigger.OnInitialized(self) 
    if Server then
        InitMixin(self, LogicMixin)   
        self:SetUpdates(true)  
    end
    self:SetTriggerCollisionEnabled(true) 
    
end

function SizeTrigger:OnTriggerEntered(enterEnt, triggerEnt)

    if self.enabled then
         ScaleEntity(self, enterEnt)
    end
    
end
function SizeTrigger:OnTriggerExited(exitEnt, triggerEnt)
    
    if exitEnt:isa("Player") then
      exitEnt.modelsize = 1
      exitEnt:AdjustMaxHealth(LookupTechData(exitEnt:GetTechId(), kTechDataMaxHealth, exitEnt:GetMaxHealth()))
      exitEnt:AdjustMaxArmor(LookupTechData(exitEnt:GetTechId(), kTechDataMaxArmor, exitEnt:GetMaxArmor()))
   if Shared.GetMapName() ~= "ns_supersiege" and Shared.GetMapName() ~= "ns_siegeaholic_remade" then  self.alreadyaltered[exitEnt] = false end
    end
end

//Addtimedcallback had not worked, so lets search it this way
function SizeTrigger:OnUpdate(deltaTime)

    if self.enabled then
        SizeAllInTrigger(self)
    end
    
end


function SizeTrigger:OnLogicTrigger()
	self:OnTriggerAction()
end



Shared.LinkClassToMap("SizeTrigger", SizeTrigger.kMapName, networkVars)