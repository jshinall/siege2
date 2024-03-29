--
-- Modifies the shine unstuck plugin so that it 
--

Script.Load("lua/Player.lua")

-- Helper function to determine whether or not two position vectors are on the same side of a plane obstacle, such as a door
function SwappedSides(Obstacle, currentPosition, newPosition)

    -- Calculate the new/old positions relative to the obstacles's position
    local oldPos = Obstacle:GetOrigin() - currentPosition
    local newPos = Obstacle:GetOrigin() - newPosition

    -- Calculate a vector perpendicular to the door's plane
    local obstacleAngles = Obstacle:GetAngles()
    AnglesTo2PiRange(obstacleAngles)
    local obstacleVector = Vector(math.sin(obstacleAngles.yaw), 0, math.cos(obstacleAngles.yaw))

    -- Ignore any horizontal obstacles, we're mostly concerned with vertical obstacles such as doors
    if (obstacleAngles.pitch > 0.25 * math.pi and obstacleAngles.pitch < 0.75 * math.pi) or
       (obstacleAngles.pitch > 1.25 * math.pi and obstacleAngles.pitch < 1.75 * math.pi) then
        return false
    end

    -- Calculate which side of the door the old/new position are on
    local oldSide = GetSign(oldPos:DotProduct(obstacleVector))
    local newSide = GetSign(newPos:DotProduct(obstacleVector))

    return oldSide ~= newSide

end

function SiegeUnstickPlayer(self, Player, Pos)
	local TechID = kTechId.Skulk

	if Player:GetIsAlive() then
		TechID = Player:GetTechId()
	end

	local Bounds = LookupTechData( TechID, kTechDataMaxExtents )

	if not Bounds then
		return false
	end

	local Height, Radius = GetTraceCapsuleFromExtents( Bounds )
	
	local SpawnPoint
	local ResourceNear
        local OtherSideOfObstacle
	local i = 1

        -- Grab any nearby doors so we can make sure that the player isn't unstucking through them
        local NearbyDoors = GetEntitiesWithinRange("SiegeDoor", Pos, 10)
        local NearbyMoveables = GetEntitiesWithinRange("FrontDoor", Pos, 7)
        local NearbyBreakables = GetEntitiesWithinRange("LogicBreakable", Pos, 6)
        local Naughty = false

	repeat
		SpawnPoint = GetRandomSpawnForCapsule( Height, Radius, Pos, 2, Range, EntityFilterAll() )

                ResourceNear = false
                OtherSideOfObstacle = false

		if SpawnPoint then
		        ResourceNear = #GetEntitiesWithinRange( "ResourcePoint", SpawnPoint, 2 ) > 0
		end

                -- Check that the player haven't gone through any nearby closed doors or barriers
                if not ResourceNear and SpawnPoint then

                    if NearbyDoors then

                        for _, Door in ipairs(NearbyDoors) do

                            -- Only check doors if they are welded shut (ie. locked)
                            if Door:GetIsWeldedShut() and SwappedSides(Door, Player:GetOrigin(), SpawnPoint) then

                                Naughty = true
                                OtherSideOfObstacle = true
                                break

                            end

                        end

                    end

                    if not OtherSideOfObstacle and NearbyMoveables then

                        for _, Moveable in ipairs(NearbyMoveables) do

                            if SwappedSides(Moveable, Player:GetOrigin(), SpawnPoint) then

                                Naughty = true
                                OtherSideOfObstacle = true
                                break

                            end

                        end

                    end

                    if not OtherSideOfObstacle and NearbyBreakables then

                        for _, Breakable in ipairs(NearbyBreakables) do

                            -- Ignore any surface types that are not planar barriers. Such as rocks.
                            -- Todo: Add more surface types to ignore?
                            if Breakable:GetSurfaceOverride() ~= "rock"
                              and Breakable:GetPhysicsGroup() ~= PhysicsGroup.DroppedWeaponGroup
                              and SwappedSides(Breakable, Player:GetOrigin(), SpawnPoint) then

                                Naughty = true
                                OtherSideOfObstacle = true
                                break

                            end

                        end

                    end

                end

		i = i + 1
	until ((not ResourceNear) and (not OtherSideOfObstacle)) or i > 100

        if Naughty then

                Shine:NotifyError(Player, "You tried to unstuck through a closed door or barrier! Naughty!")

        end

	if SpawnPoint then

		SpawnPlayerAtPoint( Player, SpawnPoint )

		return true

	end

	return false
end

if Shine and Shine:IsExtensionEnabled("unstuck") then

    Shine.Plugins["unstuck"].UnstickPlayer = SiegeUnstickPlayer

end
