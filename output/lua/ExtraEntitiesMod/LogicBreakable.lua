Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/ExtraEntitiesMod/LogicMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/ExtraEntitiesMod/ScaledModelMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")

//Because the model doesn't properly remove itself after being destroyed, how about having it simply move like a funcmoveable, to a waypoint, upon destroyed?
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SiegeMod/MoveableMixin.lua")

class 'LogicBreakable' (ScriptActor)

LogicBreakable.kMapName = "logic_breakable"

local kSurfaceName = {
                        "metal",
                        "rock",
                        "organic",
                        "infestation",
                        "thin_metal",
                        "electronic",
                        "armor",
                        "flesh",
                        "membrane",
                    }

-- Breakable entities may have a LOT of health for various reasons
kMaxBreakableHealth = 200000

local networkVars =
{
    scale = "vector",
    surface = "integer (0 to 10)",
    team = "integer (0 to 2)",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(MoveableMixin, networkVars)

-- Override the health LiveMixin network vars, to increase the maximum size.
networkVars.health = string.format("float (0 to %f by 1)", kMaxBreakableHealth)
networkVars.maxHealth = string.format("float (0 to %f by 1)", kMaxBreakableHealth)

function LogicBreakable:OnCreate()
    ScriptActor.OnCreate(self)
        
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, MoveableMixin)
end

LogicBreakable.HealthScaleCallbacks = {}
LogicBreakable.HasHealthScaleCallbacks = false

function LogicBreakable:CreatePath(onUpdate) 
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
function LogicBreakable:GetNextWaypoint()
        return self.waypoint
end
function LogicBreakable:GetPushPlayers()
    return false
end
function LogicBreakable:GetRotationEnabled()
    return false
end
function LogicBreakable:GetSpeed()
    return 40
end

-- Hooks into the relevant team add/remove player function.
function HealthScaleUpdateCallback(f)

    return function(team, player)

        for _, breakable in ipairs(LogicBreakable.HealthScaleCallbacks) do
            breakable:RecalculateHealth()
        end

        return f(team, player)

    end

end

function LogicBreakable:OnInitialized()

    ScriptActor.OnInitialized(self)
    InitMixin(self, ScaledModelMixin)
	
    if not Predict and (self.model ~= nil) then
        PrecacheAsset(self.model)
        self:SetScaledModel(self.model)
    end

    if Server then
        InitMixin(self, LogicMixin)
        InitMixin(self, StaticTargetMixin)
        if (self.team and self.team > 0) then
            self:SetTeamNumber(self.team)

            -- Hook into the team add/remove player functions
            if self.scaleHealthOnTeamSize then

                if not LogicBreakable.HasHealthScaleCallbacks then
                    Team.AddPlayer = HealthScaleUpdateCallback(Team.AddPlayer)
                    Team.RemovePlayer = HealthScaleUpdateCallback(Team.RemovePlayer)
                    Event.Hook("ClientDisconnected", function ()
                        for _, breakable in ipairs(LogicBreakable.HealthScaleCallbacks) do
                            breakable:RecalculateHealth()
                        end
                    end)
                    LogicBreakable.HasHealthScaleCallbacks = true
                end

                table.insert(LogicBreakable.HealthScaleCallbacks, self)

            end
        end

    elseif Client then

        InitMixin(self, UnitStatusMixin)

    end
    
    self.health = tonumber(self.health)    
    self.unscaledHealth = self.health
    self.maxHealth = self.health
    self:RecalculateHealth()    
    
    if not self.surface then
        self.surface = 0
    end
    
    self:SetPhysicsType(PhysicsType.Kinematic)    
        
end

function LogicBreakable:OnDestroy()
    table.removevalue(LogicBreakable.HealthScaleCallbacks, self)
end

function LogicBreakable:Reset()
    self.health = self.maxHealth
    self:RecalculateHealth()
    
    if not self:GetRenderModel() then
        if(self.model ~= nil) then
            self:SetScaledModel(self.model)
        end
    end
    
end

function LogicBreakable:GetCanIdle()
    return false
end

function LogicBreakable:GetSendDeathMessageOverride()
    return false
end

function LogicBreakable:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end   

function LogicBreakable:GetCanTakeDamageOverride()
    return true
end

function LogicBreakable:OnTakeDamage(damage, attacker, doer, point)



end

function LogicBreakable:GetShowHitIndicator()
    return true
end

function LogicBreakable:GetSurfaceOverride()
    return kSurfaceName[self.surface + 1]
end   

function LogicBreakable:OnKill(damage, attacker, doer, point, direction)

    ScriptActor.OnKill(self, damage, attacker, doer, point, direction)
    BaseModelMixin.OnDestroy(self)
   
    self:SetPhysicsGroup(PhysicsGroup.DroppedWeaponGroup)
    self:SetPhysicsGroupFilterMask(PhysicsMask.None)
    
    if Server then
        self:TriggerOutputs(attacker)  
        Print("Trigger ouputs")
    end
    
     self.driving = true

end

function LogicBreakable:GetUnitName(player)

    return self.displayName or ""

end

-- Handle the health scaling when a player joins/leaves the team

-- Ignore the commander when calculating the team size, they can't contribute to breaking the object, so this makes the scaling more linear/fair.
local function GetNumPlayersIgnoringCommander(team)

    local numPlayers = 0

    local function CountPlayers( player )
    	local client = Server.GetOwner(player)
	if client and not player:isa("Commander") then
	    numPlayers = numPlayers + 1
	end
    end
    team:ForEachPlayer( CountPlayers )

    return numPlayers

end

function LogicBreakable:RecalculateHealth()

    if self.scaleHealthOnTeamSize then
        local healthFraction = self.health / self.maxHealth
        self.maxHealth = self.unscaledHealth * math.max(GetNumPlayersIgnoringCommander(GetGamerules():GetTeam(GetEnemyTeamNumber(self:GetTeamNumber()))), 1)
        self.health = self.maxHealth * healthFraction
    end

end

if (Client) then

    function LogicBreakable:OnKillClient()
        BaseModelMixin.OnDestroy(self)
        self:SetPhysicsType(PhysicsType.None) 
        // TODO: delete phys model from Client.propList
    end

end

Shared.LinkClassToMap("LogicBreakable", LogicBreakable.kMapName , networkVars )

