local Shine = Shine
local Plugin = Plugin

Shine.MapStatsData = {}

Plugin.Version = "1.0"

local MapStatsPath = "config://shine/plugins/mapstats.json"

function Plugin:Initialise()
self.Enabled = true
self:CreateCommands()
self.GameStarted = false
self.MarinesWon = false
self.AliensWon = false

self.AlienBonus = false
self.MarineBonus = false

return true
end
function Plugin:OnFirstThink() 
local MapStatsFile = Shine.LoadJSONFile( MapStatsPath  )
self.MapStatsData = MapStatsFile

     if Shared.GetMapName() ~= "ns2_rockdownsiege2" and Shared.GetMapName() ~= "de_dust_siege" then
       local MarineWinAmount = self:GetStatsData(false, true)
       local AlienWinAmount = self:GetStatsData(true, false)
       
       if  MarineWinAmount ~=  AlienWinAmount then
          if MarineWinAmount > AlienWinAmount then 
          
                   local unclampedtime =  kFrontDoorTime - ( (MarineWinAmount - AlienWinAmount) * 10 )
                   local clampedtime = Clamp(unclampedtime, 300, 480) 
                   kFrontDoorTime = clampedtime
                   
                   local unclampedsiegetime = kSiegeDoorTime + ( (MarineWinAmount - AlienWinAmount) * 30 )
                   local clampedsiegetime = Clamp(unclampedsiegetime, 900, 1500)
                   kSiegeDoorTime = clampedsiegetime
                   
                   local unclampedstartingres = kAlienInitialIndivRes + ( (MarineWinAmount - AlienWinAmount) * 5 )
                   local clampedstartingres = Clamp(unclampedstartingres, 15, 55)
                   kAlienInitialIndivRes = clampedstartingres
                   
                   local unclampedresearchtimes = kAlienTeamResearchMod + ( (MarineWinAmount - AlienWinAmount) * .1 )
                   local clampedresearchtime = Clamp(unclampedresearchtimes, 1.0, 2.0)
                   kAlienTeamResearchMod = clampedresearchtime
                   
                   local unclampedbuildtimes = kAlienTeamSetupBuildMultiplier + ( (MarineWinAmount - AlienWinAmount) * .1 )
                   local clampedbuildtime = Clamp(unclampedbuildtimes, 1.0, 2.0)
                   kAlienTeamSetupBuildMultiplier = clampedbuildtime
                   
                   local unclampedinitialalientres = kAlienTeamInitialTres + ( (MarineWinAmount - AlienWinAmount) * 5 )
                   local clampedinitialtres = Clamp(unclampedinitialalientres, 60, 200)
                   kAlienTeamInitialTres = clampedinitialtres
                   self.AlienBonus = true
                   
         elseif AlienWinAmount > MarineWinAmount then
         
                   local unclampedtime = kSiegeDoorTime - ( (AlienWinAmount - MarineWinAmount) * 30 )
                   local clampedtime = Clamp(unclampedtime, 900, 1500) 
                   kSiegeDoorTime = clampedtime
                   
                   local unclampedtimefront = kFrontDoorTime + ( (AlienWinAmount - MarineWinAmount) * 5 )
                   local clampedtimefront = Clamp(unclampedtimefront, 300, 480) 
                   kFrontDoorTime = clampedtimefront
                   
                   local unclampedmarineresearchtimes = kMarineTeamResearchMod + ( (AlienWinAmount - MarineWinAmount) * .1 )
                   local clampedresearchtime = Clamp(unclampedmarineresearchtimes, 1.0, 2.0) 
                   kMarineTeamResearchMod = clampedresearchtime
                   
                   local unclampedbuildtimes = kMarineTeamSetupBuildMultiplier + ( (AlienWinAmount - MarineWinAmount) * .1 )
                   local clampedbuildtime = Clamp(unclampedbuildtimes, 1.0, 2.0)
                   kMarineTeamSetupBuildMultiplier = clampedbuildtime
                
                   local unclampedinitialmarinetres = kMarineTeamInitialTres + ( (AlienWinAmount - MarineWinAmount) * 5 )
                   local clampedinitialtres = Clamp(unclampedinitialmarinetres, 60, 200)
                   kMarineTeamInitialTres = clampedinitialtres
                   self.MarineBonus = true
         end
     end
   end
end
function Plugin:NotifyMapStats( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[MapStats]",  255, 0, 0, String, Format, ... )
end
function Plugin:CreateCommands()

local function MapStats(Client)
        self:NotifyMapStats( Client, "%s: Aliens:%s, Marines:%s", true, Shared.GetMapName(), self:GetStatsData(true, false), self:GetStatsData(false, true) )
end 
local MapStatsCommand = self:BindCommand("sh_mapstats", "mapstats", MapStats, true, false)
MapStatsCommand:Help("sh_mapstats - Shares the win/lose ratios for both marines and aliens on the currentmap")

end
function Plugin:SetGameState( Gamerules, State, OldState )   
     if State == kGameState.Countdown then
           Shine.ScreenText.End(1)  
          Shine.ScreenText.End(2)  
          Shine.ScreenText.End(3) 
      if Shared.GetMapName() ~= "ns2_rockdownsiege2" and Shared.GetMapName() ~= "de_dust_siege" then
        if self.MarineBonus then
         self:NotifyGeneric( nil, "Front Door: %s, Siege Door: %s, Marine team bonus: %sx research/construction speed during setup, +%s initial tres", true, string.TimeToString( kFrontDoorTime ), string.TimeToString( kSiegeDoorTime ), kMarineTeamResearchMod, kMarineTeamInitialTres - 60)
        elseif self.AlienBonus then
         self:NotifyGeneric( nil, "Front Door: %s, Siege Door: %s, Alien team bonus: %sx research/construction speed during setup, +%s initial tres, +%s initial pres", true, string.TimeToString( kFrontDoorTime ), string.TimeToString( kSiegeDoorTime ), kAlienTeamResearchMod, kAlienTeamInitialTres - 60, kAlienInitialIndivRes - 15 )
         end      
     end                             
     elseif State == kGameState.Team1Won  then
     local MapStatsFile = Shine.LoadJSONFile( MapStatsPath  )
     self.MapStatsData = MapStatsFile
     self:SimpleTimer(3, function()
     self.MarinesWon = true
     self.MapStatsData.Maps[tostring(Shared.GetMapName() ) ] = {marines = self:GetStatsData(false, true), aliens = self:GetStatsData(true, false) }
     Shine.SaveJSONFile( self.MapStatsData, MapStatsPath  )
     self:ShowStats()
     self.MarinesWon = false
     end)
     elseif State == kGameState.Team2Won then
     local MapStatsFile = Shine.LoadJSONFile( MapStatsPath  )
     self.MapStatsData = MapStatsFile
     self:SimpleTimer(3, function()
     self.AliensWon = true
     self.MapStatsData.Maps[tostring(Shared.GetMapName() ) ] = {marines = self:GetStatsData(false, true), aliens = self:GetStatsData(true, false) }
     Shine.SaveJSONFile( self.MapStatsData, MapStatsPath  )
     self:ShowStats()
     self.AliensWon = false 
     end)    
  end
end
function Plugin:GetStatsData(aliens, marines)
      local Map = self.MapStatsData.Maps[ tostring( Shared.GetMapName() ) ]
      if aliens then 
        local alienstats = 0
        if Map and Map.aliens then alienstats = Map.aliens end
        if self.AliensWon then alienstats = alienstats + 1 end
       return alienstats
     end
    if marines then
      local marinestats = 0
       if Map and Map.marines then marinestats = Map.marines end
       if self.MarinesWon then marinestats = marinestats + 1 end
       return marinestats
    end
end
        
function Plugin:ShowStats()
      local Map = self.MapStatsData.Maps[ tostring( Shared.GetMapName() ) ] 
      Shine.ScreenText.Add( 1, {X = 0.40, Y = 0.35,Text = "Map Stats:",Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
      Shine.ScreenText.Add( 2, {X = 0.40, Y = 0.40,Text = "Aliens:".. Map.aliens,Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
      Shine.ScreenText.Add( 3, {X = 0.40, Y = 0.45,Text = "Marines:".. Map.marines,Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
end
function Plugin:NotifyGeneric( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[MapStats]",  255, 0, 0, String, Format, ... )
end
function Plugin:Cleanup()
	self:Disable()
	self.BaseClass.Cleanup( self )    
	self.Enabled = false
end