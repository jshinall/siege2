//

// FuncMoveable.lua
// Base entity for FuncMoveable things

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/ExtraEntitiesMod/LogicMixin.lua")
// needed for the MoveToTarget Command
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SiegeMod/MoveableMixin.lua")
Script.Load("lua/ExtraEntitiesMod/ScaledModelMixin.lua")

class 'FuncMoveable' (ScriptActor)

FuncMoveable.kMapName = "func_moveable"
FuncMoveable.kMaxOpenDistance = 6
local kUpdateAutoOpenRate = 0.3
local kUpdateAutoCloseRate = 4

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


local function UpdateAutoOpen(self, timePassed)

    // If any players are around, have door open if possible, otherwise close it
    
    if self.enabled then
    
        local desiredOpenState = false        
        local entities = Shared.GetEntitiesWithTagInRange("Door", self:GetOrigin(), FuncMoveable.kMaxOpenDistance)
        for index = 1, #entities do
            
            local entity = entities[index]          
            if (not HasMixin(entity, "Live") or entity:GetIsAlive()) and entity:GetIsVisible() then
                desiredOpenState = true
                break            
            end            
           
        end
	        
        if desiredOpenState then 
            if not self.driving and not self:IsOpen() then
                self.driving = true
            end
        else           
            if self:IsOpen() then
                if not self.autoCloseTime then
                    self.autoCloseTime = Shared.GetTime() + kUpdateAutoCloseRate
                end
                if Shared.GetTime() >= self.autoCloseTime then
                    self.driving = true
                    self.autoCloseTime = nil
                end
            else
                self.autoCloseTime = nil
            end
        end
        
    end
    
    return true

end

function FuncMoveable:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, MoveableMixin)
end
function FuncMoveable:OnInitialized()

    ScriptActor.OnInitialized(self)  
    InitMixin(self, ScaledModelMixin)
    Shared.PrecacheModel(self.model) 
    self:SetModel(self.model)
	//self:SetScaledModel(self.model)
	
    if Server then
        InitMixin(self, LogicMixin)  
        if self.isDoor then
            self:AddTimedCallback(UpdateAutoOpen, kUpdateAutoOpenRate)            
        end
    end
    
    self.isOpen = false
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.FuncMoveable)
end

function FuncMoveable:Reset()
    ScriptActor.Reset(self)
    self.isOpen = false
    self:UpdateModelCoords()
    self:UpdatePhysicsModel()
    if (self._modelCoords and self.boneCoords and self.physicsModel) then
    self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
    end        
end

function FuncMoveable:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false   
end



function FuncMoveable:IsOpen()
    return self.isOpen
end

/* will create a path so the train will know the next points
case self.direction:
"Up" value="0"
"Down" value="1"
"Left" value="2"
"Right" value="3"
*/
function FuncMoveable:CreatePath(onUpdate)   

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

function FuncMoveable:GetNextWaypoint()
    if self.isOpen then
        return self.savedOrigin
    else
        return self.waypoint
    end
end

function FuncMoveable:OnTargetReached()
    self.isOpen = not self.isOpen
end

function FuncMoveable:GetPushPlayers()
    return false
end

function FuncMoveable:GetSpeed()
    return self.moveSpeed or 40
end

function FuncMoveable:GetRotationEnabled()
    return false
end

function FuncMoveable:OnLogicTrigger(player)
    self.driving = true
end

function FuncMoveable:AnglesToVector()
    // y -1.57 in game is up in the air
    local angles =  self:GetAngles()
    local origin = self:GetOrigin()
    local directionVector = Vector(0,0,0)
    if angles then
        // get the direction Vector the pushTrigger should push you                
        
        // pitch to vector
        directionVector.z = math.cos(angles.pitch)
        directionVector.y = -math.sin(angles.pitch)
        
        // yaw to vector
        if angles.yaw ~= 0 then
            directionVector.x = directionVector.z * math.sin(angles.yaw)                   
            directionVector.z = directionVector.z * math.cos(angles.yaw)                                
        end  
    end
    return directionVector
end


Shared.LinkClassToMap("FuncMoveable", FuncMoveable.kMapName, networkVars)