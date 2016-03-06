MoveableMixin = CreateMixin( MoveableMixin )
MoveableMixin.type = "Moveable"

local kDefaultTurnSpeed = math.pi / 2 
local kCompleteDistance = 0.1

kJitter = 0.1

MoveableMixin.expectedMixins =
{
}

MoveableMixin.expectedCallbacks =
{
    GetPushPlayers = "Only train and elevators should push players",
    CreatePath = "Creates the path the moveable will move on",
    GetRotationEnabled = "Enables rotation of the moveable",
    GetSpeed = "Movement speed of the moveable",
    GetNextWaypoint = "Returns the next waypoint, only called on Server"
}

MoveableMixin.optionalCallbacks =
{
    OnTargetReached = "Gets called when the target is reached"
}

MoveableMixin.networkVars =  
{
    driving = "boolean",
    waiting = "boolean",
	savedOrigin = "vector",
	nextWaypoint = "vector",
	cleaning = "boolean",
}


local function TransformPlayerCoordsForTrain(player, srcCoords, dstCoords)

    local viewCoords = player:GetViewCoords()
    
    // If we're going through the backside of the phase gate, orient us
    // so we go out of the front side of the other gate.
    if Math.DotProduct(viewCoords.zAxis, srcCoords.zAxis) < 0 then
    
        srcCoords.zAxis = -srcCoords.zAxis
        srcCoords.xAxis = -srcCoords.xAxis
        
    end
    
    // Redirect player velocity relative to gates
    local invSrcCoords = srcCoords:GetInverse()   
    local viewCoords = dstCoords * (invSrcCoords * viewCoords)
    local viewAngles = Angles()
    viewAngles:BuildFromCoords(viewCoords)
    
    player:SetBaseViewAngles(viewAngles)       
    player:SetViewAngles(Angles(0, 0, 0))
    player:SetAngles(Angles(0, viewAngles.yaw, 0))
    
end


function MoveableMixin:__initmixin() 
    self.driving = false
    self.waiting = false
    self.cleaning = true
end


function MoveableMixin:OnInitialized()

    // Save origin, angles, etc. so we can restore on reset
    self.savedOrigin = Vector(self:GetOrigin())
    self.savedAngles = Angles(self:GetAngles())
        
    if Server then
        // set a box so it can be triggered, use the trigger scale from the mapEditor
        if self:GetPushPlayers() then
            self:MoveTrigger()        
        end        
    end
    self.opened = false
end

function MoveableMixin:OnUpdate(deltaTime) 
if Server then

     local gameRules = GetGamerules()
         if gameRules and not self.opened and not self:isa("LogicBreakable") then
            if not gameRules:GetGameStarted() then
             self.driving = true
             self.opened = true
             end
         end
 if self:isa("FrontDoor") or ( self:isa("FuncMoveable") and Shared.GetMapName() == "ns2_tram_siege" ) then
  if not self.driving then
     self:UpdateModelCoords()
    self:UpdatePhysicsModel()
    if (self._modelCoords and self.boneCoords and self.physicsModel) then
    self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
    end   
 end
 if self.cleaning and Shared.GetMapName() ~= "ns2_tram_siege" then
    for _, entity in ipairs(GetEntitiesWithMixinWithinRange("Team", self:GetOrigin(), 15)) do
       if entity:isa("NerveGasCloud") or entity:isa("Cyst") or entity:isa("TunnelEntrance") then
       DestroyEntity(entity)
    //  elseif entity:isa("Player") and entity:GetTeamNumber() == 1 and entity:GetActiveWeapon() ~= nil and entity:GetActiveWeapon():isa("Flamethrower") then
     //  entity:SetActiveWeapon(Axe.kMapName)
      // entity:SetVelocity( entity:GetVelocity() + Vector(math.random(-50, 50),math.random(-10, 10),math.random(-50, 50) )
     // elseif entity:GetWeaponInHUDSlot(1) ~= nil and entity:GetWeaponInHUDSlot(1):isa("Flamethrower") then entity:GetWeaponInHUDSlot(1):SetClip(0)
       end
       if entity:isa("Rocket") then
       entity:Detonate(nil)
       end
    end
  end
 end
 if self.cleaning and Shared.GetMapName() == "ns2_tram_siege" then
    for _, entity in ipairs(GetEntitiesWithMixinWithinRange("Team", self:GetOrigin(), 9)) do
       if entity:isa("NerveGasCloud") or entity:isa("Cyst") then
       DestroyEntity(entity)
    //  elseif entity:isa("Player") and entity:GetTeamNumber() == 1 and entity:GetActiveWeapon() ~= nil and entity:GetActiveWeapon():isa("Flamethrower") then
     //  entity:SetActiveWeapon(Axe.kMapName)
      // entity:SetVelocity( entity:GetVelocity() + Vector(math.random(-50, 50),math.random(-10, 10),math.random(-50, 50) )
     // elseif entity:GetWeaponInHUDSlot(1) ~= nil and entity:GetWeaponInHUDSlot(1):isa("Flamethrower") then entity:GetWeaponInHUDSlot(1):SetClip(0)
       end
       if entity:isa("Rocket") then
       entity:Detonate(nil)
       end
    end
  end
 end  
 if not self.driving then //and self:isa("SiegeDoor") then
     self:UpdateModelCoords()
    self:UpdatePhysicsModel()
    if (self._modelCoords and self.boneCoords and self.physicsModel) then
    self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
    end        
 end  
    if Shared.GetIsRunningPrediction() then
        return
    end
    
    if self.driving then     
  
    end

    if Server then 
        if self.driving then   
            self:UpdatePosition(deltaTime)    
            self:MoveTrigger()
            if not self.waiting  and self:GetPushPlayers() then
                self:SetOldAngles(self:GetAngles())
                self:MovePlayersInTrigger(deltaTime)
            end
        end  
    end    
    
    if self.driving then
        // move also the physics model
        self:UpdateModelCoords()
        self:UpdatePhysicsModel()
        if (self._modelCoords and self.boneCoords and self.physicsModel) then
            self.physicsModel:SetBoneCoords(self._modelCoords, self.boneCoords)
        end               
        
    end
    
    /*
    local physModel = self:GetPhysicsModel()
    if physModel then
        local coords = physModel:GetCoords()
        
        if not self.lastAxesDrawn or Shared.GetTime()  > self.lastAxesDrawn + 1 then
            DebugDrawAxes( coords, coords.origin, 2, 1, 1 )  
            self.lastAxesDrawn = Shared.GetTime()
        end
    end      
    */
end


function MoveableMixin:Reset()

    // Restore original origin, angles, etc. as it could have been rag-dolled
    self.opened = false
    self:SetOrigin(self.savedOrigin)
    self:SetAngles(self.savedAngles)
    self.driving = false
    self.nextWaypoint = nil
                
    if self.autoStart then
        self.driving = true
    end
    self.waiting = false
    
    self.movementVector = nil
    self.oldAngles = nil
    
    // only the Server should generate the path
    if Server then
        self:CreatePath()
        self.nextWaypoint = self:GetNextWaypoint()
    end
    
end

function MoveableMixin:CheckBlocking(endPoint)

    if not endPoint then
        return
    end

    // kill entities that blocks us
    //local startPoint = self:GetOrigin()    
    local coords = self:GetCoords()
    local middle = coords.origin + (coords.yAxis / 2)
    
    local extents = self.scale or self:GetExtents()  
    //local trace = self.physicsModel:Trace(CollisionRep.Move, CollisionRep.Move, PhysicsMask.Movement)  
    local trace = Shared.TraceRay(middle, endPoint, CollisionRep.Move, PhysicsMask.All, EntityFilterOne(self))
    if trace.entity then
        if HasMixin(trace.entity, "Live") then
            trace.entity:Kill()
        end
    end  

end


function MoveableMixin:SetOldAngles(newAngles)

    if self.oldAngles then
        self:SetOldAnglesDiff(newAngles)
        self.oldAngles.yaw = newAngles.yaw
        self.oldAngles.pitch = newAngles.pitch
        self.oldAngles.roll = newAngles.roll

    else
        self.oldAngles = newAngles
    end
end

function MoveableMixin:SetOldAnglesDiff(newAngles)

    if self.oldAnglesDiff then
        local newYaw = (newAngles.yaw - self.oldAngles.yaw)
        self.oldAnglesDiff.yaw = newYaw
        self.oldAnglesDiff.pitch = (newAngles.pitch - self.oldAngles.pitch)
        self.oldAnglesDiff.roll = (newAngles.roll - self.oldAngles.roll)        
        
    else
        self.oldAnglesDiff = Angles(0,0,0)
    end
end


function MoveableMixin:GetDeltaAngles()
    if not self.oldAnglesDiff then
        local angles = Angles()
        angles.pitch = 0
        angles.yaw = 0
        angles.roll = 0
        self.oldAnglesDiff = angles   
    end
    return self.oldAnglesDiff   
end

function MoveableMixin:MovePlayersInTrigger(deltaTime)
    for _, entity in ipairs(self:GetEntitiesInTrigger()) do 
        if self.driving and entity~= self then
            if entity.GetIsJumping and not entity:GetIsJumping() then   
         
                //entity:SetOrigin(self:GetPhysicsModel():GetCoords().origin)                
                //entity.onGround = true
                
                // change position when the train is driving
                local entOrigin = entity:GetOrigin()
                local trainOrigin = self:GetOrigin()
                local newOrigin = entOrigin
                
                local selfDeltaAngles = self:GetDeltaAngles()              
                local entityAngles = entity:GetAngles() 
                local degrees = selfDeltaAngles.yaw
                
                if self:GetRotationEnabled() then
                
                    // 2d rotation , I don't think I need 3d here, will get the correct position after rotating the train
                    newOrigin.z = trainOrigin.z + (math.cos(degrees) * (entOrigin.z - trainOrigin.z) -  math.sin(degrees) * (entOrigin.x - trainOrigin.x))                
                    newOrigin.x = trainOrigin.x + (math.sin(degrees) * (entOrigin.z - trainOrigin.z) +  math.cos(degrees) * (entOrigin.x - trainOrigin.x))
                    
                end

                entityAngles.yaw = entityAngles.yaw + selfDeltaAngles.yaw
                local coords = Coords.GetLookIn(newOrigin, self:GetAngles():GetCoords().zAxis)
                //TransformPlayerCoordsForTrain(entity, entity:GetCoords(), coords)               

                //entity:UpdateControllerFromEntity()
                //entity.controller:SetPosition(newOrigin  + self:GetMovementVector())
                //entity:UpdateOriginFromController()
                
                local newOrigin = newOrigin  + self.movementVector
                entity.velocity.y = 0
                entity:SetOrigin(newOrigin)
                
                entity.pushTime = -1                
                
            end
        end
    end
end

    
function MoveableMixin:MoveTrigger()
    /*
    local scale = Vector(1,1,1)
    if self.scaleTrigger then
        scale = self.scaleTrigger
    // scale1 was the old name for this, dunno why but sometimes its still in there
    elseif self.scale1 then
         scale = self.scale1
    else
        scale = self:GetExtents()
    end
    self:SetBox(scale)
    self:SetTriggerCollisionEnabled(true)
    */
    
    // make it a bit bigger so were inside the trigger
    local coords = self:GetCoords()
    coords.yAxis = coords.yAxis  * 5
    
    if self.triggerModel then
        //Shared.DestroyCollisionObject(self.triggerModel)
        //self.triggerModel = nil
        self.triggerModel:SetCoords(coords)
        self.triggerModel:SetBoneCoords(coords, CoordsArray())
    else    
        if self.modelIndex then    

            self.triggerModel = Shared.CreatePhysicsModel(self.modelIndex, false, coords , self)
            
            if self.triggerModel ~= nil then
                self.triggerModel:SetTriggerEnabled(true)
                self.triggerModel:SetCollisionEnabled(false)
                self.triggerModel:SetEntity(self)         
            end

        end        
    end
    
end


function MoveableMixin:OnTriggerEntered(enterEnt, triggerEnt)    
end

function MoveableMixin:OnTriggerExited(exitEnt, triggerEnt)
    //DebugCircle(self:GetOrigin(), 2, Vector(1, 0, 0), 1, 1, 1, 1, 1)
end


//**********************************
// Driving things
//**********************************

// TODO:Accept
// 1. Generate Path
// 2. Move
// called from OnUpdate when self.driving = true
function MoveableMixin:UpdatePosition(deltaTime)
   
    if self.driving then
        local wayPoint = self:GetWaypoint()    
        if wayPoint then
        
            if not self.waiting then
        
                self:CheckBlocking()
                 
                local oldOrigin = self:GetOrigin()
                local movespeed = self:GetSpeed() 
                local rotate = self:GetRotationEnabled()
                local directionVector = wayPoint - oldOrigin                
                local direction = GetNormalizedVector(wayPoint - oldOrigin)
                local endPoint = oldOrigin + direction * deltaTime * movespeed 

                // dont drive too far
                if directionVector:GetLength() <= (endPoint - oldOrigin):GetLength() then
                    endPoint = wayPoint
                end              
               
                if rotate then
                  self:UpdateRotation(deltaTime, direction, movespeed, rotate)     
                end
                
                //local coords = self:GetCoords()
                //coords.origin = endPoint

                self:SetOrigin(endPoint)
                //self:SetCoords(coords)                
                local movementVector = endPoint - oldOrigin
                self.movementVector = movementVector
                               
            end
                        
            if self:HasReachedTarget(wayPoint) then
                self.driving = false
                self.nextWaypoint = nil
                
                if self.OnTargetReached then
                    self:UpdateModelCoords()
                    self:UpdatePhysicsModel()
                    self:OnTargetReached()
                    if Server then
                        self.nextWaypoint = self:GetNextWaypoint()
                    end
                end
                
            end
            
        else
            Print("Error: No waypoint found!")
            self.driving = false
        end
    end
            
end 

function MoveableMixin:UpdateRotation(deltaTime, direction, moveSpeed)
    
    // smooth turning
    local angles = self:GetAngles()
    local currentYaw = self:NormalizeYaw(angles.yaw)
    local desiredYaw = self:NormalizeYaw(GetYawFromVector(direction))
    
    local dYaw = self:GetDeltaYaw(desiredYaw,currentYaw)
    local turnAmount = math.min(math.abs(dYaw), deltaTime * kDefaultTurnSpeed) * (dYaw < 0 and -1 or 1)
    turnAmount = math.abs(turnAmount) > 0.001 and turnAmount or 0 
    
    angles.yaw = self:NormalizeYaw(currentYaw + turnAmount)
    self:SetAngles(angles)    
    
end



function MoveableMixin:GetWaypoint()
    if Server then
        if not self.nextWaypoint then
            self.nextWaypoint = self:GetNextWaypoint()
            return nil
        end
    end
    return self.nextWaypoint
end

function MoveableMixin:HasReachedTarget(endPoint)
    return ((endPoint-self:GetOrigin()):GetLength() <= kCompleteDistance)
end

function MoveableMixin:OnTriggerEntered(entity, triggerEnt)
    //Print("parent")
    //entity:SetParent(self)
end    

function MoveableMixin:OnTriggerExited(entity, triggerEnt)
    //Print("no parent")
    //entity:SetParent(nil)
end    

