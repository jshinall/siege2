Script.Load("lua/ScriptActor.lua")
Script.Load("lua/ExtraEntitiesMod/LogicMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SiegeMod/MoveableMixin.lua")
Script.Load("lua/ExtraEntitiesMod/ScaledModelMixin.lua")

class 'FrontDoor' (ScriptActor)

FrontDoor.kMapName = "frontdoor"
FrontDoor.kMaxOpenDistance = 6

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


function FrontDoor:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, MoveableMixin)
end
function FrontDoor:OnInitialized()

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

function FrontDoor:Reset()
    ScriptActor.Reset(self)
    self.driving = false
    self.cleaning = true
    self:UpdateModelCoords()
    self:UpdatePhysicsModel()
    if (self._modelCoords and self.boneCoords and self.physicsModel) then
    self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
    end        
end

function FrontDoor:CreatePath(onUpdate) 
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

function FrontDoor:GetNextWaypoint()
        return self.waypoint
end
function FrontDoor:GetPushPlayers()
    return false
end

function FrontDoor:GetSpeed()
    return self.moveSpeed or 40
end

function FrontDoor:GetRotationEnabled()
    return false
end

Shared.LinkClassToMap("FrontDoor", FrontDoor.kMapName, networkVars)

class 'WeldDoor' (FrontDoor)
WeldDoor.kMapName = "welddoor"
/*
function WeldDoor:GetNextWaypoint()
    if self.isOpen then
        return self.savedOrigin
    else
        return self.waypoint
    end
end

function WeldDoor:CreatePath(onUpdate)   

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
    
    if self.direction == 0 then
        moveVector.y = extents.y
    elseif  self.direction == 1 then 
        moveVector.y = -extents.y
    elseif  self.direction == 2 then
        moveVector.x = directionVector.z * -extents.x 
        moveVector.z = directionVector.x * extents.x 
        //directionVector 
    elseif  self.direction == 3 then
        moveVector.x = directionVector.z * extents.x 
        moveVector.z = directionVector.x * -extents.x     
    elseif self.direction == 4 then
        for _, ent in ientitylist(Shared.GetEntitiesWithClassname("FuncTrainWaypoint")) do 
            if ent.trainName == self.name then
                wayPointOrigin = ent:GetOrigin()
                break
            end   
        end
    end
    
    self.waypoint = wayPointOrigin or (origin + moveVector)
       
    if self.startsOpened and not self.isDoor then
        self.isOpen = true  
        self:SetOrigin(self.waypoint)  
    end 
end
*/

Shared.LinkClassToMap("WeldDoor", WeldDoor.kMapName, { })