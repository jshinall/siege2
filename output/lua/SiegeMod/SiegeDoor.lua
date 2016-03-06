Script.Load("lua/ScriptActor.lua")
Script.Load("lua/ExtraEntitiesMod/LogicMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SiegeMod/MoveableMixin.lua")
Script.Load("lua/ExtraEntitiesMod/ScaledModelMixin.lua")

class 'SiegeDoor' (ScriptActor)

SiegeDoor.kMapName = "siegedoor"
SiegeDoor.kMaxOpenDistance = 6

local networkVars =
{
    scale = "vector",
    model = "string (128)",
    moveSpeed = "float"
}

AddMixinNetworkVars(LogicMixin, networkVars)
AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(MoveableMixin, networkVars)


function SiegeDoor:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, MoveableMixin)
end
function SiegeDoor:OnInitialized()

    ScriptActor.OnInitialized(self)  
    InitMixin(self, ScaledModelMixin)
    Shared.PrecacheModel(self.model) 
    self:SetModel(self.model)
	//self:SetScaledModel(self.model)
	
    if Server then
        InitMixin(self, LogicMixin)  
    end
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.FuncMoveable)
end

function SiegeDoor:Reset()
    ScriptActor.Reset(self)
    self.driving = false
    self:UpdateModelCoords()
    self:UpdatePhysicsModel()
    if (self._modelCoords and self.boneCoords and self.physicsModel) then
    self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
    end        
end

function SiegeDoor:CreatePath(onUpdate) 
 
    if self.driving then    
    local extents = nil
    
    if self.model then
        _, extents = self:GetModelExtents()
    end
    
    if not extents then
        extents = self.scale or Vector(1,1,1)
    end    

    local origin = self:GetOrigin()
    local wayPointOrigin = nil
    local moveVector = Vector(0,0,0)
    local directionVector = self:AnglesToVector()
    for _, ent in ientitylist(Shared.GetEntitiesWithClassname("NS2Gamerules")) do 
    wayPointOrigin = ent:GetOrigin()
    end

    self.waypoint = wayPointOrigin or (origin + moveVector)
    self:SetOrigin(self.waypoint) 
    end
end

function SiegeDoor:GetNextWaypoint()
        return self.waypoint
end
function SiegeDoor:GetPushPlayers()
    return false
end

function SiegeDoor:GetSpeed()
    return self.moveSpeed or 40
end

function SiegeDoor:GetRotationEnabled()
    return false
end

Shared.LinkClassToMap("SiegeDoor", SiegeDoor.kMapName, networkVars)