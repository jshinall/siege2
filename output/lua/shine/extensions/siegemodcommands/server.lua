/*Kyle Abent SiegeModCommands 
KyleAbent@gmail.com / 12XNLDBRNAXfBCqwaBfwcBn43W3PkKUkUb
*/
local Shine = Shine
local Plugin = Plugin

Shine.CreditData = {}

Plugin.Version = "1.0"

local CreditsPath = "config://shine/plugins/credits.json"

Shine.Hook.SetupClassHook( "ScoringMixin", "AddScore", "OnScore", "PassivePost" )


function Plugin:Initialise()
self.rtd_succeed_cooldown = 90
self.rtdenabled = true
self.rtd_failed_cooldown = self.rtd_succeed_cooldown
self.Users = {}
self:CreateCommands()
self.Enabled = true
self.GameStarted = false
self.CreditAmount = 0
self.CreditUsers = {}
self.BuyUsersTimer = {}

self.marineplayers = 0
self.marinecredits = 0
self.aliencredits = 0
self.alienplayers = 0
self.totalcreditsearned = 0

self.UserStartOfRoundCredits = {}
self.ServerTotalCreditsSpent = 0


return true
end

local function GetPathingRequirementsMet(position, extents)

    local noBuild = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_Walk)
    return not noBuild and walk
    
end

function Plugin:OnScore( Player, Points, Res, WasKill )
if Points ~= nil and Points ~= 0 and Player and GetGamerules():GetGameStarted() then
self.CreditUsers[ Player:GetClient() ] = self:GetPlayerCreditsInfo(Player:GetClient()) + (Points/10)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Player:GetClient()) ), Player:GetClient()) 
end
end

function Plugin:OnFirstThink() 
local CreditsFile = Shine.LoadJSONFile( CreditsPath )
self.CreditData = CreditsFile


end
/*
        if not Shine.Timer.Exists("SeedTimer") then
        	Shine.Timer.Create( "SeedTimer", 300, -1, function() self:SeedCredits() end )
      end

end
 function Plugin:SeedCredits()
             
if Shine.GetHumanPlayerCount() <= 10 then self:GiveSeedCredits() end
 
 end
 function Plugin:GiveSeedCredits()
 local randomcredits = math.random(1,5)
 self:NotifyCredits( nil, "Playercount is less than or equal to 10. Therefore, as a thank you for seeding the server, here's %s credit(s) to everyone on the server. Thanks!", true, randomcredits)
 
  local Players = Shine.GetAllPlayers()
   for i = 1, #Players do
    local player = Players[ i ]
     if player then
      self.CreditUsers[ player:GetClient() ] = self:GetPlayerCreditsInfo(player:GetClient()) + randomcredits
          if self.GameStarted then
          Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(player:GetClient()) ), player:GetClient()) 
          end
      end
   end
 end
 */
function Plugin:SaveCredits(Client)
       local Data = self:GetCreditData( Client )
       if Data and Data.credits then 
       Data.credits = self:GetPlayerCreditsInfo(Client) 
       else 
      self.CreditData.Users[Client:GetUserId() ] = {credits = self:GetPlayerCreditsInfo(Client) }
       end
     Shine.SaveJSONFile( self.CreditData, CreditsPath  )
end
function Plugin:CalculateEndofRoundCredits()

      local Players = Shine.GetAllPlayers()
      for i = 1, #Players do
      local player = Players[ i ]
        if player then
            if player:GetTeamNumber() == 1 then
            self.marinecredits = self.marinecredits + player:GetScore()
            self.marineplayers = self.marineplayers + 1
            elseif player:GetTeamNumber() == 2 then
            self.aliencredits = self.aliencredits + player:GetScore()
            self.alienplayers = self.alienplayers + 1
            end
            self.totalcreditsearned = self.totalcreditsearned + player:GetScore() / 10
                 if self.UserStartOfRoundCredits[player:GetClient()] then
                 local currentamount = self:GetPlayerCreditsInfo(player:GetClient())
                 local startamount = self.UserStartOfRoundCredits[player:GetClient()]
                 local formula1 = ( startamount - currentamount )
                 local formula2 = ( currentamount - startamount )
                 self.ServerTotalCreditsSpent = self.ServerTotalCreditsSpent + ConditionalValue(currentamount > startamount , formula2, formula1)
                 end
        end
      end
     
      
       self.marinecredits = Clamp(self.marinecredits / self.marineplayers / 10, 5, 100)
       self.aliencredits = Clamp( self.aliencredits/ self.alienplayers / 8, 5, 100)
       self:NotifyCredits( nil, "Marines: + %s credits", true, math.round(self.marinecredits, 2) )
       self:NotifyCredits( nil, "Aliens: + %s credits ", true, math.round(self.aliencredits, 2) )
      
end
function Plugin:DistributeEndofRoundCredits()

      local Players = Shine.GetAllPlayers()
  for i = 1, #Players do
      local player = Players[ i ]
      if player then
          if player:GetTeamNumber() == 1 then
             self.CreditUsers[ player:GetClient() ] = self:GetPlayerCreditsInfo(player:GetClient()) + self.marinecredits
             Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(player:GetClient()) ), player:GetClient()) 
          elseif player:GetTeamNumber() == 2 then
             self.CreditUsers[ player:GetClient() ] = self:GetPlayerCreditsInfo(player:GetClient()) + self.aliencredits
             Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(player:GetClient()) ), player:GetClient()) 
        end
         self:SaveCredits(player:GetClient())
      end 
    end
    


end
function Plugin:ClientDisconnect(Client)
self:SaveCredits(Client)
end

function Plugin:GetPlayerCreditsInfo(Client)
local Credits = 0
if self.CreditUsers[ Client ] then
Credits = self.CreditUsers[ Client ]
elseif not self.CreditUsers[ Client ] then 
local Data = self:GetCreditData( Client )
if Data and Data.credits then 
Credits = Data.credits 
end
end
return math.round(Credits, 2)
end
local function GetIDFromClient( Client )
	return Shine.IsType( Client, "number" ) and Client or ( Client.GetUserId and Client:GetUserId() ) // or nil //or nil was blocked but im testin
 end
function Plugin:GetCreditData(Client)
  if not self.CreditData then return nil end
  if not self.CreditData.Users then return nil end
  local ID = GetIDFromClient( Client )
  if not ID then return nil end
  local User = self.CreditData.Users[ tostring( ID ) ] 
  if not User then 
     local SteamID = Shine.NS2ToSteamID( ID )
     User = self.CreditData.Users[ SteamID ]
     if User then
     return User, SteamID
     end
     local Steam3ID = Shine.NS2ToSteam3ID( ID )
     User = self.CreditData.Users[ ID ]
     if User then
     return User, Steam3ID
     end
     return nil, ID
   end
return User, ID
end

 function Plugin:ClientConfirmConnect(Client)
 
 if Client:GetIsVirtual() then return end
 
 /*
        --Decoy is a twat--
     serverIp = IPAddressToString(Server.GetIpAddress())
     if not string.find(serverIp, "162.248.91.177") then 
       		Shine.SendNetworkMessage( Client, "Shine_Command", {
			Command = string.format( "connect 162.248.91.177:27015" )
		}, true )
        end
  */ 
  
  if GetGamerules():GetGameStarted() then

  Shine.ScreenText.Add( "Credits", {X = 0.20, Y = 0.85,Text = string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ),Duration = 1800,R = 255, G = 0, B = 0,Alignment = 0,Size = 3,FadeIn = 0,}, Client )
  if not self.UserStartOfRoundCredits[Client] then self.UserStartOfRoundCredits[Client] = self:GetPlayerCreditsInfo(Client) end
     
  if ( Shared.GetTime() - GetGamerules():GetGameStartTime() ) < kFrontDoorTime then
    local NowToFront = kFrontDoorTime - (Shared.GetTime() - GetGamerules():GetGameStartTime())
    local FrontLength =  math.ceil( Shared.GetTime() + NowToFront - Shared.GetTime() )
   Shine.ScreenText.Add( 8, {X = 0.40, Y = 0.75,Text = "Front Door(s) opens in %s",Duration = FrontLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 3,FadeIn = 0,} )

  end

   if    ( Shared.GetTime() - GetGamerules():GetGameStartTime() ) < kSiegeDoorTime then
     local NowToSiege = kSiegeDoorTime - (Shared.GetTime() - GetGamerules():GetGameStartTime())
     local SiegeLength =  math.ceil( Shared.GetTime() + NowToSiege - Shared.GetTime() )
    Shine.ScreenText.Add( 9, {X = 0.60, Y = 0.95,Text = "Siege Door(s) opens in %s",Duration = SiegeLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 3,FadeIn = 0,} )
   end
   /*
      if    ( Shared.GetTime() - GetGamerules():GetGameStartTime() ) > kSiegeDoorTime then
     local NowToSuddendeath = kTimeAfterSiegeOpeningToEnableSuddenDeath - (Shared.GetTime() - GetGamerules():GetGameStartTime())
     local SuddenDeathLength =  math.ceil( Shared.GetTime() +  NowToSuddendeath - Shared.GetTime() )
	  Shine.ScreenText.Add( 83, {X = 0.40, Y = 0.95,Text = "Sudden Death activates in %s",Duration = SuddenDeathLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
     end
     
     if  ( Shared.GetTime() - GetGamerules():GetGameStartTime() ) > kTimeAfterSiegeOpeningToEnableSuddenDeath then
	  Shine.ScreenText.Add( 84, {X = 0.40, Y = 0.95,Text = "Sudden Death is ACTIVE! (No Respawning)",Duration = 300,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
     end
    */
    
end
    
 end
function Plugin:SetGameState( Gamerules, State, OldState )
       if State == kGameState.Countdown then
       
          Shine.ScreenText.End(6)  
          Shine.ScreenText.End(7)  
          Shine.ScreenText.End(81)  
          Shine.ScreenText.End(82)  
          if self:TimerExists(20) then self:DestroyTimer(20) end
          if self:TimerExists(21) then self:DestroyTimer(21) end
          
        elseif State == kGameState.Started then 
          
        self.GameStarted = true
        
        local DerpLength =  math.ceil( Shared.GetTime() + kFrontDoorTime - Shared.GetTime() )
       local SiegeLength =  math.ceil( Shared.GetTime() + kSiegeDoorTime - Shared.GetTime() )

	
       Shine.ScreenText.Add( 6, {X = 0.40, Y = 0.75,Text = "Front Door(s) opens in %s",Duration = DerpLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 3,FadeIn = 0,} )
	   Shine.ScreenText.Add( 7, {X = 0.60, Y = 0.95,Text = "Siege Door(s) opens in %s",Duration = SiegeLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 3,FadeIn = 0,} )
	   
	   self:CreateTimer(20, kSiegeDoorTime + 1, 1, function ()
	   if self.GameStarted then
	   local SuddenDeathLength =  math.ceil( Shared.GetTime() + kTimeAfterSiegeOpeningToEnableSuddenDeath - Shared.GetTime() )
	   Shine.ScreenText.Add( 81, {X = 0.40, Y = 0.95,Text = "Sudden Death activates in %s",Duration = SuddenDeathLength,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
	   end
	   end)
	   self:CreateTimer(21,kSiegeDoorTime + kTimeAfterSiegeOpeningToEnableSuddenDeath, 1, function ()
	   if self.GameStarted then
	   Shine.ScreenText.Add( 82, {X = 0.40, Y = 0.95,Text = "Sudden Death is ACTIVE! (No Respawning!)",Duration = 1800,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
	   end
	   end)
  
          Shine.ScreenText.End(83)  
          Shine.ScreenText.End(84)  
          Shine.ScreenText.End(85) 
          Shine.ScreenText.End(86) 
          Shine.ScreenText.End(87) 
         
          Shine.ScreenText.End("Credits")    
              self.marineplayers = 0
              self.marinecredits = 0
              self.aliencredits = 0
              self.alienplayers = 0
              self.totalcreditsearned = 0
              self.ServerTotalCreditsSpent = 0
              
              local Players = Shine.GetAllPlayers()
              for i = 1, #Players do
              local Player = Players[ i ]
                  if Player then
                  //Shine.ScreenText.Add( "Credits", {X = 0.20, Y = 0.95,Text = "Loading Credits...",Duration = 1800,R = 255, G = 0, B = 0,Alignment = 0,Size = 3,FadeIn = 0,}, Player )
                  Shine.ScreenText.Add( "Credits", {X = 0.20, Y = 0.95,Text = string.format( "%s Credits", self:GetPlayerCreditsInfo(Player:GetClient()) ),Duration = 1800,R = 255, G = 0, B = 0,Alignment = 0,Size = 3,FadeIn = 0,}, Player:GetClient() )
                  self.UserStartOfRoundCredits[Player:GetClient()] = self:GetPlayerCreditsInfo(Player:GetClient())
                  end
              end
              
      end        
              
     if State == kGameState.Team1Won or State == kGameState.Team2Won or State == kGameState.Draw then
     
      self.GameStarted = false
      
          Shine.ScreenText.End(6) 
          Shine.ScreenText.End(7) 
          Shine.ScreenText.End(8)  
          Shine.ScreenText.End(9)  
          Shine.ScreenText.End(81) 
          Shine.ScreenText.End(82) 
          
      self:CalculateEndofRoundCredits()
      
        self:SimpleTimer(0.8, function ()
        self:DistributeEndofRoundCredits()
        end)
       
       self:SimpleTimer(1, function ()
       
              local Players = Shine.GetAllPlayers()
              for i = 1, #Players do
              local Player = Players[ i ]
                  if Player then
                  self:SaveCredits(Player:GetClient())
                     if Player:GetTeamNumber() == 1 or Player:GetTeamNumber() == 2 then
                    Shine.ScreenText.Add( 84, {X = 0.40, Y = 0.15,Text = "(Your)Total Credits Earned:".. math.round((Player:GetScore() / 10 + ConditionalValue(Player:GetTeamNumber() == 1, self.marinecredits, self.aliencredits)), 2), Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,}, Player )
                    local formula1 = ( self.UserStartOfRoundCredits[Player:GetClient()] + self.marinecredits + (Player:GetScore() / 10) )  - self:GetPlayerCreditsInfo(Player:GetClient() )
                    local formula2 = ( self.UserStartOfRoundCredits[Player:GetClient()] + self.aliencredits + (Player:GetScore() / 10) ) - self:GetPlayerCreditsInfo(Player:GetClient() )
                    local allofformula = ConditionalValue(Player:GetTeamNumber() == 1, formula1, formula2, 2)
                    Shine.ScreenText.Add( 86, {X = 0.40, Y = 0.20,Text = "(Your)Total Credits Spent:".. math.round(allofformula, 2), Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,}, Player )
                     end
                  end
             end
      end)
      
      self:SimpleTimer(3, function ()    
      Shine.ScreenText.Add( 83, {X = 0.40, Y = 0.10,Text = "End of round Stats:",Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
      Shine.ScreenText.Add( 85, {X = 0.40, Y = 0.25,Text = "(Server Wide)Total Credits Earned:".. math.round((self.totalcreditsearned + self.marinecredits + self.aliencredits), 2), Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
      Shine.ScreenText.Add( 87, {X = 0.40, Y = 0.30,Text = "(Server Wide)Total Credits Spent:".. math.round(self.ServerTotalCreditsSpent, 2), Duration = 120,R = 255, G = 255, B = 0,Alignment = 0,Size = 4,FadeIn = 0,} )
      end)
   end
     
end

function Plugin:NotifyGiveRes( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[GiveRes]",  255, 0, 0, String, Format, ... )
end



function Plugin:NotifyGeneric( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Admin Abuse]",  255, 0, 0, String, Format, ... )
end

function Plugin:NotifyCredits( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[Credits]",  255, 0, 0, String, Format, ... )
end

function Plugin:NotifyGiveRes( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 255, 165, 0,  "[GiveRes]",  255, 0, 0, String, Format, ... )
end
function Plugin:NotifyMarine( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 250, 235, 215,  "[RTD] [Alpha]",  40, 248, 255, String, Format, ... )
end
function Plugin:NotifyAlien( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 250, 235, 215,  "[RTD] [Alpha]", 144, 238, 144, String, Format, ... )
end
function Plugin:NotifyPoop( Player, String, Format, ... )
Shine:NotifyDualColour( Player, 250, 235, 215,  "[Bonewall Poop]", 144, 238, 144, String, Format, ... )
end


function Plugin:AddDelayToPlayer(Player)
 return true
 //self:RollPlayer(Player)
end
function Plugin:RollPlayer(Player)
//self:NotifyMarine( nil, "%s Attempting to roll. Getting Qualifications.", true, Player:GetName())
if Player:GetIsAlive() and Player:GetTeamNumber() == 1 and not Player:isa("Commander") then 
//self:NotifyMarine( nil, "%s Player is an alive marine, not commander. Could be marine, jetpack, or exo. Getting random number.", true, Player:GetName())
   local MarineorJetpackMarineorExoRoll = math.random(1, 3)
    //self:NotifyMarine( nil, "%s Random number calculated, now applying.", true, Player:GetName())

if MarineorJetpackMarineorExoRoll == 1 then
          local WinLoseResHealthArmor = math.random(1,9)
     //self:NotifyMarine( nil, "%s Random number is 1. Checking resource gain qualifications)", true, Player:GetName())
           if WinLoseResHealthArmor == 1 and Player:GetResources() >= 90 then self:RollPlayer(Player) return end //self:NotifyMarine( nil, "%s Resources are 90 or greater. No need to add. ReRolling.", true, Player:GetName()) self:RollPlayer(Player) return end
           if WinLoseResHealthArmor == 1 and Player:GetResources() <= 89 then
           self:AddDelayToPlayer(Player)
           local OnlyGiveUpToThisMuch = 100 - Player:GetResources()
           local GiveResRTD = math.random(9.0, OnlyGiveUpToThisMuch)
           Player:SetResources(Player:GetResources() + GiveResRTD) 
           self:NotifyMarine( nil, "%s won %s resource(s)", true, Player:GetName(), GiveResRTD)
          return
          end //end of WinResLoseres roll 1
            //self:NotifyMarine( nil, "%s roll number 2. Calcualting how much res the player has.", true, Player:GetName()) 
             if WinLoseResHealthArmor == 2 and Player:GetResources() <= 9 then self:RollPlayer(Player) return end //self:NotifyMarine( nil, "%s Player has 9 or less res. No need to remove. ReRolling Player.", true, Player:GetName()) self:RollPlayer(Player)  end
          if WinLoseResHealthArmor == 2 and Player:GetResources() >= 10 then  
             self:AddDelayToPlayer(Player) 
             //self:NotifyMarine( nil, "%s Player has 10 or greater res. Calculating how much to randomly take away. ", true, Player:GetName()) 
             local OnlyRemoveUpToThisMuch = Player:GetResources() 
             local LoseResRTD = math.random(9.0, OnlyRemoveUpToThisMuch) 
             Player:SetResources(Player:GetResources() - LoseResRTD)
             self:NotifyMarine( nil, "%s lost %s resource(s)", true, Player:GetName(),  LoseResRTD)
         return
         end // end of WinLoseResHealthArmor 2
          if WinLoseResHealthArmor == 3 and Player:isa("Exo") then self:RollPlayer(Player) return end
   if WinLoseResHealthArmor == 3 and not Player:isa("Exo") then 
         local playerhealth = Player:GetHealth()
         if playerhealth >= Player:GetMaxHealth() * (90/100) then self:RollPlayer(Player) return end
         if playerhealth <= Player:GetMaxHealth() * (89/100) then 
         self:AddDelayToPlayer(Player) 
         local GainHealth = 0
        GainHealth = Player:GetMaxHealth() - playerhealth
        local HealthToGive = math.random(Player:GetMaxHealth() * (10/100), GainHealth)
        StartSoundEffectAtOrigin(MedPack.kHealthSound, Player:GetOrigin())
        Player:SetHealth(Player:GetHealth() + HealthToGive)
        self:NotifyMarine( nil, "%s gained %s health", true, Player:GetName(), HealthToGive)
        return
        end // end of if player rhealth <=89 then
        end //End of if  WinLoseResHealthArmor == 3 not player is exo then
      if WinLoseResHealthArmor == 4 and Player:isa("Exo") then self:RollPlayer(Player) return end
         if WinLoseResHealthArmor == 4 and not Player:isa("Exo") then
        local playerhealth = Player:GetHealth()
         if playerhealth <= Player:GetMaxHealth() * (10/100) then self:RollPlayer(Player) return end
          if playerhealth >= Player:GetMaxHealth() * (11/100) then
          self:AddDelayToPlayer(Player) 
         local LoseHealth = 0
         LoseHealth = Player:GetHealth() - 1
         local TakeAwayHealth = math.random(Player:GetMaxHealth() * (10/100), LoseHealth)
         Player:SetHealth(Player:GetHealth() - TakeAwayHealth)
         self:NotifyMarine( nil, "%s lost %s health", true, Player:GetName(), TakeAwayHealth)
        return
         end // end of if player rhealth >= 11 then
         end //End of if not player is exo then

   if WinLoseResHealthArmor == 5 then
    //self:NotifyMarine( nil, "%s give armor roll start", true, Player:GetName())
    local playerarmor = Player:GetArmor()
    local playermaxarmor = Player:GetMaxArmor()
        if playerarmor >=  playermaxarmor * (90 / 100 ) then self:RollPlayer(Player) return end
        if playerarmor <=  playermaxarmor * (89 / 100 ) then 
        self:AddDelayToPlayer(Player) 
        local GiveArmor = math.random(playermaxarmor * (10 / 100 ), playermaxarmor)
        Player:SetArmor(playerarmor + GiveArmor)
        self:NotifyMarine( nil, "%s gained %s armor", true, Player:GetName(), math.round(GiveArmor, 1))
        return
        end //end of if player armor <=
         self:NotifyMarine( nil, "%s gained armor roll end", true, Player:GetName())
   end//end of if WinLoseResHealthArmor == 5 then
   if WinLoseResHealthArmor == 6 then
   local playerarmor = Player:GetArmor()
   local playermaxarmor = Player:GetMaxArmor()
       if playerarmor <= playermaxarmor * (10 / 100) then self:RollPlayer(Player) return end
       if playerarmor >= playermaxarmor * (11 / 100) then 
       self:AddDelayToPlayer(Player)
       local LoseArmor = 0
       LoseArmor = Player:GetArmor()
       local TakeAwayArmor = math.random(playerarmor * (10 / 100), LoseArmor)
       Player:SetArmor(playerarmor - TakeAwayArmor)
       self:NotifyMarine( nil, "%s lost %s armor", true, Player:GetName(), math.round(TakeAwayArmor, 1)) 
       return
       end //end of if playerarmor >=
   end//end of WinLoseResHealthArmor == 6
   if WinLoseResHealthArmor == 7 then
     local Amount = math.random(-3.0,10.0)
     if Amount == 0 then self:RollPlayer(Player) return end
     if Amount >=1 then
     self:AddDelayToPlayer(Player) 
     self:NotifyMarine( nil, "%s attained %s credits", true, Player:GetName(), Amount)
    else
    self:NotifyMarine( nil, "%s lost %s credits", true, Player:GetName(), Amount * -1)
    end
     self.CreditUsers[ Player:GetClient() ] = self:GetPlayerCreditsInfo(Player:GetClient()) + Amount
     Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Player:GetClient()) ), Player:GetClient()) 
    return
   end //end of == 7
      if WinLoseResHealthArmor == 8 then
     local Amount = math.random(-50, 50)
     if Amount == 0 then self:RollPlayer(Player) return end
     if Amount >=1 then
     self:AddDelayToPlayer(Player) 
     self:NotifyMarine( nil, "%s increased max health by %s percent", true, Player:GetName(), Amount)
    else
    self:NotifyMarine( nil, "%s decreased max health by %s percent", true, Player:GetName(), Amount * -1)
    end
     Player:AdjustMaxHealth( Player:GetMaxHealth() + Player:GetMaxHealth() * (Amount/100) )
    return
   end //end of == 8
      if WinLoseResHealthArmor == 9 then
     local Amount = math.random(-50, 50)
     if Amount == 0 then self:RollPlayer(Player) return end
     if Amount >=1 then
     self:AddDelayToPlayer(Player) 
     self:NotifyMarine( nil, "%s increased max armor by %s percent", true, Player:GetName(), Amount)
    else
    self:NotifyMarine( nil, "%s decreased max armor by %s percent", true, Player:GetName(), Amount * -1)
    end
     Player.rtdmaxarmoradjustment = Amount
    return
   end //end of == 9
 end//End of roll 1

if MarineorJetpackMarineorExoRoll == 2 then
             //self:NotifyMarine( nil, "%s Rolled a 3. Determining Qualifications.", true, Player:GetName())
          if Player:isa("Exo") then self:RollPlayer(Player) return end //self:NotifyMarine( Player, "Rolled a 3, though is not eligable. Re-Rolling.") self:RollPlayer(Player)  end  //self:NotifyMarine( nil, "%s Player is an exo and not qualified for roll 3 (yet). ReRolling", true, Player:GetName()) self:RollPlayer(Player)  end 
      //if not Player:isa("Exo") then 
          //self:NotifyMarine( nil, "%s Player is not an exo, so is qualified for roll 3 (Maybe roll 3 WILL have exo alternative later :))", true, Player:GetName())             
           local WeaponRoll = math.random(1, 9) 
          // self:NotifyMarine( nil, "%s Attaining weapon to switch to", true, Player:GetName())       //Destroy the entity so it's not dropped, and can be picked up, which is espcially annoyign with ns2+ autopicking it up, rendering this useless unless deleted
           if WeaponRoll == 1 and Player:GetWeaponInHUDSlot(1) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("GrenadeLauncher") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(GrenadeLauncher.kMapName) self:NotifyMarine( nil, "%s switched to a GrenadeLauncher", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                     if WeaponRoll == 1 and Player:GetWeaponInHUDSlot(1) == nil then Player:GiveItem(GrenadeLauncher.kMapName) self:NotifyMarine( nil, "%s switched to a GrenadeLauncher", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                     if WeaponRoll == 2 then self:RollPlayer(Player) return end
           if WeaponRoll == 2 and Player:GetWeaponInHUDSlot(1) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("HeavyRifle") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(HeavyRifle.kMapName) self:NotifyMarine( nil, "%s switched to a HMG.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                      if WeaponRoll == 2 and Player:GetWeaponInHUDSlot(1) == nil then Player:GiveItem(HeavyRifle.kMapName) self:NotifyMarine( nil, "%s switched to a Onifle.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 3 and Player:GetWeaponInHUDSlot(1) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("Flamethrower") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(Flamethrower.kMapName) self:NotifyMarine( nil, "%s switched to a flamethrower.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                      if WeaponRoll == 3 and Player:GetWeaponInHUDSlot(1) == nil then Player:GiveItem(Flamethrower.kMapName) self:NotifyMarine( nil, "%s switched to a flamethrower.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 4 and Player:GetWeaponInHUDSlot(1) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("Rifle") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(Rifle.kMapName) self:NotifyMarine( nil, "%s switched to a rifle.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                      if WeaponRoll == 4 and Player:GetWeaponInHUDSlot(1) == nil then Player:GiveItem(Rifle.kMapName) self:NotifyMarine( nil, "%s switched to a rifle.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 5 and not Player:GetWeaponInHUDSlot(3):isa("Welder") then Player:GiveItem(Welder.kMapName) self:NotifyMarine( nil, "%s switched to a welder.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 6 and not Player:GetWeaponInHUDSlot(3):isa("Axe") then DestroyEntity(Player:GetWeaponInHUDSlot(3)) Player:GiveItem(Axe.kMapName) self:NotifyMarine( nil, "%s switched to a axe.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 7 and Player:GetWeaponInHUDSlot(2) ~= nil and not Player:GetWeaponInHUDSlot(2):isa("Pistol") then DestroyEntity(Player:GetWeaponInHUDSlot(2)) Player:GiveItem(Pistol.kMapName) self:NotifyMarine( nil, "%s switched to a pistol", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                     if WeaponRoll == 7 and Player:GetWeaponInHUDSlot(2) == nil then Player:GiveItem(Pistol.kMapName) self:NotifyMarine( nil, "%s switched to a pistol", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 8 and Player:GetWeaponInHUDSlot(1) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("Shotgun") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(Shotgun.kMapName) self:NotifyMarine( nil, "%s switched to a shotgun.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
                     if WeaponRoll == 8 and Player:GetWeaponInHUDSlot(2) == nil then Player:GiveItem(Shotgun.kMapName) self:NotifyMarine( nil, "%s switched to a shotgun.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
          // if WeaponRoll == 9 then Player:GiveItem(GasGrenade.kMapName) self:NotifyMarine( nil, "%s dropped an active gas grenade.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
          // if WeaponRoll == 10 then Player:GiveItem(ClusterGrenade.kMapName) self:NotifyMarine( nil, "%s dropped an active cluster grenade.", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           //if WeaponRoll == 11 then Player:GiveItem(PulseGrenade.kMapName) self:NotifyMarine( nil, "%s dropped an activepulse grneade", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
           if WeaponRoll == 9 and Player:GetWeaponInHUDSlot(4) == nil then Player:GiveItem(LayMines.kMapName) self:NotifyMarine( nil, "%s attained mines", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
          //self:NotifyMarine( nil, "%s Rolled to switch to a weapon that's already owned. Therefore re-rolling.", true, Player:GetName())
          //if Weaponroll == 13 then Player:DestroyWeapons() self:NotifyMarine( nil, "%s destroyed all held weapons", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
          self:RollPlayer(Player)
          return
      //end// end of player exo
end //end of rol 2  
      if MarineorJetpackMarineorExoRoll == 3 then
      local EffectsRoll = math.random(1,16)
            //self:NotifyMarine( nil, "%s Rolled a 4", true, Player:GetName())
            if EffectsRoll == 1 and Player:isa("Exo") or not Player:GetIsOnGround() then self:RollPlayer(Player) return end //self:NotifyMarine( nil, "%s Not qualified for roll 4. Re-rolling", true, Player:GetName()) self:RollPlayer(Player) return end
            if EffectsRoll == 1 and not Player:isa("Exo") and Player:GetIsOnGround() and not Player:GetIsStunned() then
            local kStunDuration = math.random(1,10)
             self:AddDelayToPlayer(Player)
            Player:SetStun(kStunDuration)
            //Timer: Set Camera distance to third person and back to first person
            //Add stun safeguard to either this roll or rtd in general? prohibit it?
            self:NotifyMarine( nil, "%s Has been stunned for %s seconds", true, Player:GetName(), kStunDuration)
           Shine.ScreenText.Add( 50, {X = 0.20, Y = 0.80,Text = "Stunned for %s",Duration = kStunDuration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player ) 
            return 
            end//End of effects roll 1         
            if EffectsRoll == 2 then
            self:AddDelayToPlayer(Player) 
            local kCatPackDuration = math.random(8,60)
            Shine.ScreenText.Add( 51, {X = 0.20, Y = 0.80,Text = "Catpack: %s",Duration = kCatPackDuration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            self:NotifyMarine( nil, "%s has been given the effects of Catalyst for %s seconds", true, Player:GetName(), kCatPackDuration)
            StartSoundEffectAtOrigin(CatPack.kPickupSound, Player:GetOrigin())
            Player:ApplyDurationCatPack(kCatPackDuration) 
            return
            end//end of effects roll 2
            if EffectsRoll == 3 then
            self:AddDelayToPlayer(Player) 
            local kNanoShieldDuration = math.random (8, 45)
            Shine.ScreenText.Add( 52, {X = 0.20, Y = 0.80,Text = "Nano: %s",Duration = kNanoShieldDuration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            Player:ActivateDurationNanoShield(kNanoShieldDuration)
            self:NotifyMarine( nil, "%s has been given the effects of NanoShield for %s seconds", true, Player:GetName(), kNanoShieldDuration)
            return
            end//end of effects roll 3
            if EffectsRoll == 4 then
            self:AddDelayToPlayer(Player) 
            local kScanDuration = math.random(1, 30)
            Shine.ScreenText.Add( 53, {X = 0.20, Y = 0.80,Text = "Scans: %s",Duration = kScanDuration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            CreateEntity(Scan.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
            StartSoundEffectForPlayer(Observatory.kCommanderScanSound, Player)
            self:NotifyMarine( nil, "%s %s seconds of scans", true, Player:GetName(), kScanDuration)
            self:CreateTimer(2, 1, kScanDuration, function () if not Player:GetIsAlive() then self:DestroyTimer(2) self.ScreenText.End(53) return end StartSoundEffectForPlayer(Observatory.kCommanderScanSound, Player) CreateEntity(Scan.kMapName, Player:GetOrigin(), Player:GetTeamNumber())  end )
            return
            end//end of effects roll 3
          /*
            if EffectsRoll == 5 then
            self:NotifyMarine( nil, "%s turning flashlight on/off for 30 seconds", true, Player:GetName())
            self:CreateTimer( self.FlashLightTimer, 1, 30, 
            function () 
           if not Player:GetIsAlive()  and self:TimerExists( self.FlashLightTimer ) then self:DestroyTimer( self.FlashLightTimer ) return end 
           Player:SetFlashlightOn(not Player:GetFlashlightOn())
            end )
            self:AddDelayToPlayer(Player) 
            return
            end//end of effects roll 5
         */
            if EffectsRoll == 5 then
            self:AddDelayToPlayer(Player) 
            local  kInfiniteAmmoTimer = math.random(15,60)
            Shine.ScreenText.Add( 54, {X = 0.20, Y = 0.80,Text = "Infinite Ammo: %s",Duration = kInfiniteAmmoTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            self:NotifyMarine( nil, "%s Infinite ammo: %s seconds", true, Player:GetName(), kInfiniteAmmoTimer)
            self:CreateTimer(3, 1, kInfiniteAmmoTimer, function () if not Player:GetIsAlive() then Shine.ScreenText.End(54) self:DestroyTimer(3) return end  if Player:GetWeaponInHUDSlot(1) ~= nil then  Player:GetWeaponInHUDSlot(1):SetClip(99) end 
                 if Player:GetWeaponInHUDSlot(2) ~= nil then 
                  Player:GetWeaponInHUDSlot(2):SetClip(99)
                  end 
            end )
            return
            end//end of effects roll 5
            if EffectsRoll == 6 then
            self:AddDelayToPlayer(Player) 
            local  kNanoShieldANDCatPackTimer = math.random(10,60)
            Shine.ScreenText.Add( 55, {X = 0.20, Y = 0.80,Text = "Catpack/Nano: %s",Duration = kNanoShieldANDCatPackTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            Player:ActivateDurationNanoShield(kNanoShieldANDCatPackTimer)
            Player:ApplyDurationCatPack(kNanoShieldANDCatPackTimer) 
            StartSoundEffectAtOrigin(CatPack.kPickupSound, Player:GetOrigin())
            self:NotifyMarine( nil, "%s has been given the effects of NanoShield AND Catpack for %s seconds", true, Player:GetName(), kNanoShieldANDCatPackTimer)
            return
            end //end of effects roll 6
            if EffectsRoll == 7 then
            self:NotifyMarine( nil, "%s Has been bonewall-ed", true, Player:GetName())
            CreateEntity(BoneWall.kMapName, Player:GetOrigin(), 2)    
            StartSoundEffectForPlayer(AlienCommander.kBoneWallSpawnSound, Player)
            end//end of effects roll 7
         /*
            if EffectsRoll == 9 then
            Player:SetMarineNoReload(true)
            self:NotifyMarine( nil, "%s does not have to reload for 30 seconds", true, Player:GetName())
            self:CreateTimer( self.MarineNoReloadTimer, 30, 1, 
            function () 
           if not Player:GetIsAlive() then self:DestroyTimer( self.MarineNoReloadTimer ) return end 
            Player:SetMarineNoReload(false)
            end )
            self:AddDelayToPlayer(Player) 
            return
            end//end of effects roll 9
        */
            if EffectsRoll == 8 then
            self:AddDelayToPlayer(Player) 
            local  kWebTimer = math.random(5,30)
            Shine.ScreenText.Add( 56, {X = 0.20, Y = 0.80,Text = "Webbed: %s",Duration = kWebTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            self:NotifyMarine( nil, "%s is webbed for %s seconds", true, Player:GetName(), kWebTimer)
            Player:SetWebbed(kWebTimer)
            return
            end//end of effects roll 8
          
            if EffectsRoll == 9 then
            self:AddDelayToPlayer(Player) 
            self:NotifyMarine( nil, "%s fell under the effects of a parasite", true, Player:GetName())
            Player:SetParasited()
            return
            end//end of effects roll 9
          /*
            if EffectsRoll == 11 then
            self:NotifyMarine( nil, "%s is becoming paranoid", true, Player:GetName())
            self:CreateTimer( self.FoVTimer, 1, 29, function ()  if not Player:GetIsAlive() and self:TimerExists(  self.FoVTimer ) then self:DestroyTimer( self.FoVTimer ) return end Player:SetFov(Player:GetFov() + 3) end )
            self:CreateTimer( self.FoVRestoreTimer, 31, 1, function () if not Player:GetIsAlive() and self:TimerExists(   self.FoVRestoreTimer ) then self:DestroyTimer( self.FoVRestoreTimer ) return end Player:SetFov(Player:GetFov() - 87) end )
            self:AddDelayToPlayer(Player) 
            return
            end//end of effects roll 11
         */
           if EffectsRoll == 10 then
            self:AddDelayToPlayer(Player) 
           self:NotifyMarine( nil, "%s is being hit by a Slap Bomb", true, Player:GetName())
            self:CreateTimer(4, 0.5, 30, function () if not Player:GetIsAlive() then self:DestroyTimer(4) return end Player:SetVelocity(Player:GetVelocity() + Vector(math.random(-50, 50),math.random(-5, 10),math.random(-50, 50))) end )
            end//end of effectsroll 10
            if EffectsRoll == 11 then
            self:AddDelayToPlayer(Player) 
            local kZeroAmmoTimer = math.random(5,30)
            Shine.ScreenText.Add( 57, {X = 0.20, Y = 0.80,Text = "Zero Ammo: %s",Duration = kZeroAmmoTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            self:NotifyMarine( nil, "%s Zero ammo for %s seconds", true, Player:GetName(), kZeroAmmoTimer)
            
            self:CreateTimer(5, 1, kZeroAmmoTimer, function () 
            if not Player:GetIsAlive() then self:DestroyTimer(5) self.ScreenText.End(57) return end
               if Player:GetWeaponInHUDSlot(1) ~= nil then 
                Player:GetWeaponInHUDSlot(1):SetClip(0) 
                end 
                if Player:GetWeaponInHUDSlot(0) ~= nil then 
               Player:GetWeaponInHUDSlot(2):SetClip(0) 
                end  
             end )
             
            return
            end//end of effects roll 5
            if EffectsRoll == 12 then
            self:AddDelayToPlayer(Player) 
            local kNerveGasTimer = math.random(5,15)
            Shine.ScreenText.Add( 58, {X = 0.20, Y = 0.80,Text = "NerveGas: %s", Duration = kNerveGasTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyMarine( nil, "%s won %s seconds of nerve gas clouds spawning on player", true, Player:GetName(), kNerveGasTimer)  
     
       Player:GiveItem(GasGrenade.kMapName)
      self:CreateTimer(6, 1, kNerveGasTimer, function () if not Player:GetIsAlive() then self:DestroyTimer(6) self.ScreenTextEnd(58) return end Player:GiveItem(GasGrenade.kMapName) end )
        
      return 
      end // end of effects roll 12
     if EffectsRoll == 13 then
     self:AddDelayToPlayer(Player) 
      local size = math.random(10,200)
      if size == Player.modelsize then self:RollPlayer(Player) return end
     self:NotifyMarine( nil, "Adjusted %s's size %s percent to %s percent", true, Player:GetName(), Player.modelsize * 100, size  ) 
     Player.modelsize = size / 100
     Player:AdjustMaxHealth(Player:GetMaxHealth() * size / 100)
     Player:AdjustMaxArmor(Player:GetMaxArmor() * size / 100)
      return 
      end // end of effects roll 13
      if EffectsRoll == 14 then
      if not Player:isa("JetpackMarine") then self:RollPlayer(Player) return end
      local kInfiniteJetpackFuelDuration = math.random(15,60)
     Shine.ScreenText.Add( 68, {X = 0.20, Y = 0.80,Text = "Infinite Fuel: %s", Duration = kInfiniteJetpackFuelDuration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
     self:NotifyMarine( nil, "%s won infinite jetpack fuel for %s", true, Player:GetName(), kInfiniteJetpackFuelDuration ) 
     Player:GiveInfiniteFuel(30)
      return 
      end // end of effects roll 14
   
             if EffectsRoll == 15 then
           self:AddDelayToPlayer(Player)
      local percent = math.random(-25,25)
     if percent == 0  then self:RollPlayer(Player) return end
      local duration = math.random(15, 45)
     if percent >=1 then 
     self:NotifyMarine( nil, "%s %s percent damage buff against NON PLAYERS for %s seconds", true, Player:GetName(), percent, duration ) 
     Shine.ScreenText.Add( 74, {X = 0.20, Y = 0.80,Text ="damage buff against NON PLAYERS: %s",Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
    else
      self:NotifyMarine( nil, "%s %s percent damage de-buff against NON PLAYERS for %s seconds", true, Player:GetName(), percent, duration ) 
    Shine.ScreenText.Add( 75, {X = 0.20, Y = 0.80,Text ="damage de-buff against NON PLAYERS for %s",Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
    end
     Player:TriggerRTDNonPlayerDamageSclae(duration, percent)
      return 
      end // end of effects roll 15
 
       if EffectsRoll == 16 then
           self:AddDelayToPlayer(Player)
      local percent = math.random(-25,25)
     if percent == 0 then self:RollPlayer(Player) return end
      local duration = math.random(15, 45)
     if percent >=1 then 
      Shine.ScreenText.Add( 76, {X = 0.20, Y = 0.80,Text ="dmg buff against PLAYERS: %s", Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
     self:NotifyMarine( nil, "%s %s percent damage buff against PLAYERS: %s seconds", true, Player:GetName(), percent, duration ) 
    else
      Shine.ScreenText.Add( 77, {X = 0.20, Y = 0.80,Text ="dmg de-buff against PLAYERS: %s", Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyMarine( nil, "%s %s percent damage de-buff against PLAYERS:%s seconds", true, Player:GetName(), percent, duration ) 
    end
     Player:TriggerRTDPlayerDamageSclae(duration, percent)
      return 
      end // end of effects roll 16
      end//End of roll 3     
   
/*
if MarineorJetpackMarineorExoRoll == 6 then
        // self:NotifyMarine( nil, "%s roll 6 start", true, Player:GetName())
         if Player:GetFuel() ~= nil then
           local activeWeapon = Player:GetActiveWeapon()
             local activeWeaponMapName = nil
             local health = Player:GetHealth()
             local armor = Player:GetArmor()
             if activeWeapon ~= nil then
            activeWeaponMapName = activeWeapon:GetMapName()
             end
            local Marine = Player:Replace(Marine.kMapName, Player:GetTeamNumber(), true)
           Marine:SetActiveWeapon(activeWeaponMapName)
           Marine:SetHealth(health)
           Marine:SetArmor(armor)
          self:NotifyMarine( nil, "%s switched to a marine", true, Player:GetName())
          self:AddDelayToPlayer(Player) 
           return
           end //end of player is not a marine
                    local activeWeapon = Player:GetActiveWeapon()
                    local activeWeaponMapName = nil
                    local health = Player:GetHealth()
                    local armor = Player:GetArmor()
                    if activeWeapon ~= nil then
                   activeWeaponMapName = activeWeapon:GetMapName()
                    end
                   local jetpackMarine = Player:Replace(JetpackMarine.kMapName, Player:GetTeamNumber(), true)
                  jetpackMarine:SetActiveWeapon(activeWeaponMapName)
                  jetpackMarine:SetHealth(health)
                  jetpackMarine:SetArmor(armor)
                  self:NotifyMarine( nil, "%s switched to a jetpack", true, Player:GetName())
                 self:AddDelayToPlayer(Player) 
                  return
end//end of roll 6
*/
end //End of marine roll
 if Player:GetIsAlive() and Player:GetTeamNumber() == 2 and not Player:isa("Commander") then
  //self:NotifyAlien( nil, "%s Player is an alive alien, not commander.", true, Player:GetName())
      local AlienRoll = math.random(1,2)
      //self:NotifyAlien( nil, "%s Random number calculated, now applying.", true, Player:GetName())
  
      if AlienRoll == 1 then
      local WinLoseResHPArmor = math.random(1,9)
     //self:NotifyAlien( nil, "%s Random number is 1. Checking resource gain qualifications)", true, Player:GetName())
              if WinLoseResHPArmor == 1 and Player:GetResources() >= 90 then self:RollPlayer(Player) return end //self:NotifyAlien( nil, "%s Resources are 90 or greater. No need to add. ReRolling.", true, Player:GetName()) self:RollPlayer(Player) return end
              if WinLoseResHPArmor == 1 and Player:GetResources() <= 89 then
              self:AddDelayToPlayer(Player)
              local OnlyGiveUpToThisMuch = 100 - Player:GetResources()
              local GiveResRTD = math.random(10.0, OnlyGiveUpToThisMuch)
              Player:SetResources(Player:GetResources() + GiveResRTD)
              self:NotifyAlien( nil, "%s won %s resource(s)", true, Player:GetName(), GiveResRTD)
              return
              end//WinLoseResHPArmor 1
            //self:NotifyAlien( nil, "%s roll number 2. Calcualting how much res the player has.", true, Player:GetName()) 
             if WinLoseResHPArmor == 2 and Player:GetResources() <= 9 then self:RollPlayer(Player) return end //self:NotifyAlien( nil, "%s Player has 9 or less res. No need to remove. ReRolling Player.", true, Player:GetName()) self:RollPlayer(Player)  end
             if WinLoseResHPArmor == 2 and Player:GetResources() >= 10 then  
             self:AddDelayToPlayer(Player) 
             //self:NotifyAlien( nil, "%s Player has 10 or greater res. Calculating how much to randomly take away. ", true, Player:GetName()) 
             local OnlyRemoveUpToThisMuch = Player:GetResources() 
             local LoseResRTD = math.random(9.0, OnlyRemoveUpToThisMuch)  
             Player:SetResources(Player:GetResources() - LoseResRTD)
             self:NotifyAlien( nil, "%s lost %s resource(s)", true, Player:GetName(),  LoseResRTD)
             return
             end//end of WinLoseResHPArmor 2  
   if WinLoseResHPArmor == 3 then 
         local playerhealth = Player:GetHealth()
         local playermaxhealth = Player:GetMaxHealth()
        if playerhealth >=  playermaxhealth * (90 / 100 ) then self:RollPlayer(Player) return end
        if playerhealth <=  playermaxhealth * (89 / 100 ) then 
         self:AddDelayToPlayer(Player) 
         local GainHealth = Player:GetMaxHealth() - Player:GetHealth()
        local HealthToGive = math.random(playermaxhealth * (10 / 100 ),  GainHealth)
        Player:SetHealth(Player:GetHealth() + HealthToGive)
        self:NotifyAlien( nil, "%s gained %s health", true, Player:GetName(), HealthToGive)
        return
        end // end of if player rhealth <=89 then
   end //End of if WinLoseResHPArmor == 3 then
         if WinLoseResHPArmor == 4  then
        local playerhealth = Player:GetHealth()
        local playermaxhealth = Player:GetMaxHealth()
         if playerhealth <= playermaxhealth * (10 / 100) then self:RollPlayer(Player) return end
          if playerhealth >= playermaxhealth * (11 / 100) then
          self:AddDelayToPlayer(Player) 
         local LoseHealth = 0
         LoseHealth = Player:GetHealth() - 1
         local TakeAwayHealth = math.random(playermaxhealth * (11 / 100), LoseHealth)
         Player:SetHealth(Player:GetHealth() - TakeAwayHealth)
         self:NotifyAlien( nil, "%s lost %s health", true, Player:GetName(), TakeAwayHealth)
        return
         end // end of if player rhealth >= 11 then
         end //End of if WinLoseResHPArmor == 4 then
   if WinLoseResHPArmor == 5 then
    //self:NotifyAlien( nil, "%s give armor roll start", true, Player:GetName())
    local playerarmor = Player:GetArmor()
    local playermaxarmor = Player:GetMaxArmor()
        if playerarmor >=  playermaxarmor * (90 / 100 ) or Player:isa("Skulk") then self:RollPlayer(Player) return end
        if playerarmor <=  playermaxarmor * (89 / 100 ) then 
        self:AddDelayToPlayer(Player) 
        local GiveArmor = math.random(playermaxarmor * (10 / 100 ), playermaxarmor)
        Player:SetArmor(playerarmor + GiveArmor)
        self:NotifyAlien( nil, "%s gained %s armor", true, Player:GetName(), math.round(GiveArmor, 1))
        return
        end //end of if player armor <=
         //self:NotifyAlien( nil, "%s gained armor roll end", true, Player:GetName())
   end//end of if WinLoseResHPArmor == 5 then
   if WinLoseResHPArmor == 6 then
   local playerarmor = Player:GetArmor()
   local playermaxarmor = Player:GetMaxArmor()
       if playerarmor <= playermaxarmor * (10 / 100) or Player:isa("Skulk") then self:RollPlayer(Player) return end
       if playerarmor >= playermaxarmor * (11 / 100) then 
       self:AddDelayToPlayer(Player) 
       local LoseArmor = 0
       LoseArmor = Player:GetArmor()
       local TakeAwayArmor = math.random(playermaxarmor * (11 / 100), LoseArmor)
       Player:SetArmor(playerarmor - TakeAwayArmor)
       self:NotifyAlien( nil, "%s lost %s armor", true, Player:GetName(), math.round(TakeAwayArmor, 1))
       return
       end //end of if playerarmor >=
   end//end of WinLoseResHPArmor 6
      if WinLoseResHPArmor == 7 then
     local Amount = math.random(-3.0,10.0)
     if Amount == 0 then self:RollPlayer(Player) return end
      self:AddDelayToPlayer(Player) 
     if Amount >=1 then
     self:NotifyAlien( nil, "%s attained %s credits", true, Player:GetName(), Amount)
    else
    self:NotifyAlien( nil, "%s lost %s credits", true, Player:GetName(), Amount * -1 )
    end
     self.CreditUsers[ Player:GetClient() ] = self:GetPlayerCreditsInfo(Player:GetClient()) + Amount
     Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Player:GetClient()) ), Player:GetClient()) 
    return
   end //end of == 7
         if WinLoseResHPArmor == 8 then
     local Amount = math.random(-25, 25)
     if Amount == 0 then self:RollPlayer(Player) return end
     if Amount >=1 then
     self:AddDelayToPlayer(Player) 
     self:NotifyAlien( nil, "%s increased max health by %s percent", true, Player:GetName(), Amount)
    else
    self:NotifyAlien( nil, "%s decreased max health by %s percent", true, Player:GetName(), Amount * -1)
    end
     Player.rtdmaxhealincreasepercent = Amount
    return
   end //end of == 8
      if WinLoseResHPArmor == 9 then
     local Amount = math.random(-50, 50)
     if Amount == 0 then self:RollPlayer(Player) return end
     if Amount >=1 then
     self:AddDelayToPlayer(Player) 
     self:NotifyAlien( nil, "%s increased max armor by %s percent", true, Player:GetName(), Amount)
    else
    self:NotifyAlien( nil, "%s decreased max armor by %s percent", true, Player:GetName(), Amount * -1)
    end
     Player.rtdarmoradjustmentpercent = Amount
    return
   end //end of == 8
end//Alien roll 1

   /*
      if AlienRoll == 3 then //Maybe better to add a whole new class and replace the class/respawn the player in the current location
                             //Would REQUIRE Alot alot of work, especially for each class and each weapon to give. THough don't know any alternative
                             //Aside from sticking to the glitchy animation/damage/energy. Which considers this into the state of alpha :)
                             //The above may be required for secondary attccks from classes. OR can be possibly edited the weapon files them self such as LeapGORE(rtd) rather than LeapBite, or visa versa
                             //Seems fine so far having the weapons this way because the game is not told to give the classes these weapons, even thought the hudslots match. 
      //self:NotifyAlien( nil, "%s Rolled a 3.", true, Player:GetName())                
      if Player:isa("Skulk") and not Player:GetWeaponInHUDSlot(1):isa("Gore") then DestroyEntity(Player:GetWeaponInHUDSlot(1)) Player:GiveItem(Gore.kMapName) self:NotifyAlien( nil, "%s is a skulk and traded bite/leap for gore (DO NOT GESTATE)", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
      if Player:isa("Gorge") and Player:GetWeaponInHUDSlot(4) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("Primal") then DestroyEntity(Player:GetWeaponInHUDSlot(4)) Player:GiveItem(Primal.kMapName) self:NotifyAlien( nil, "%s is a gorge and won Primal Scream and spikes!! (Slot 4/DO NOT GESTATE)", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
            if Player:isa("Gorge") and Player:GetWeaponInHUDSlot(4) == nil then Player:GiveItem(Primal.kMapName) self:NotifyAlien( nil, "%s is a gorge and won Primal Scream and spikes!! (Slot 4/DO NOT GESTATE)", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
      if Player:isa("Lerk") and Player:GetWeaponInHUDSlot(3) ~= nil and not Player:GetWeaponInHUDSlot(1):isa("BileBomb") then DestroyEntity(Player:GetWeaponInHUDSlot(3)) Player:GiveItem(BileBomb.kMapName) self:NotifyAlien( nil, "%s is a lerk and traded Spores & Spikes for Bile Bomb & Heal Spray!! (DO NOT GESTATE)", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
             if Player:isa("Lerk") and Player:GetWeaponInHUDSlot(3) == nil  then Player:GiveItem(BileBomb.kMapName) self:NotifyAlien( nil, "%s is a lerk and traded Spores & Spikes for Bile Bomb & Heal Spray!! (DO NOT GESTATE)", true, Player:GetName()) self:AddDelayToPlayer(Player) return end
      //self:NotifyAlien( nil, "%s Not eligable for weapon switch roll. Re-Rolling.", true, Player:GetName())
      self:RollPlayer(Player)
      // add if not weapon:gethudslot weapon:isa to prevent getting the same duplicate, rather reroll // Add in if not weaponslot then because if alien does not have the biomass for it then nothging happens, or biomass may overrwrite it?
      return
      end//End of alien roll 3
      */
     if AlienRoll == 2 then 
      local EffectsRoll = math.random(1,19)
      if EffectsRoll == 1 then 
      self:AddDelayToPlayer(Player)   
      local  kEnzymeTimer = math.random(15,60)                                
      Shine.ScreenText.Add( 59, {X = 0.20, Y = 0.80,Text = "Enzyme: %s",Duration = kEnzymeTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s won enzyme for %s seconds", true, Player:GetName(), kEnzymeTimer)  
      Player:TriggerFireProofEnzyme(kEnzymeTimer)
      return 
      end//end of effects roll 1
      if EffectsRoll == 2 then
      self:AddDelayToPlayer(Player)
      local  kUmbraTimer = math.random(15,60)
      self:NotifyAlien( nil, "%s won umbra for %s seconds", true, Player:GetName(), kUmbraTimer)  
      Shine.ScreenText.Add( 60, {X = 0.20, Y = 0.80,Text = "Umbra: %s", Duration = kEnzymeTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      Player:SetHasFireProofUmbra(true, kUmbraTimer)
 
      return 
      end//end of effects roll 2
      if EffectsRoll == 3 then
      self:AddDelayToPlayer(Player) 
      local kElectrifyTimer = math.random(5, 30)
     Shine.ScreenText.Add( 61, {X = 0.20, Y = 0.80,Text = "Electrified: %s",Duration = kElectrifyTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s became electrified for %s seconds", true, Player:GetName(), kElectrifyTimer)
      Player:SetElectrified(kElectrifyTimer)

      return
      end//end of effects roll 3
      if EffectsRoll == 4 then
      self:AddDelayToPlayer(Player) 
      Shine.ScreenText.Add( 70, {X = 0.20, Y = 0.80,Text = "Hallucinations: %s", Duration = 30,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s hallucination cloud every 5 seconds for 30 seconds", true, Player:GetName())
      Player:GiveItem(HallucinationCloud.kMapName)
      self:CreateTimer(7, 5, 30, function () if not Player:GetIsAlive() then self:DestroyTimer(7) self.ScreenText.End(70) return end Player:GiveItem(HallucinationCloud.kMapName) end )
      end//end of effects roll 4
      if EffectsRoll == 5 then
      self:AddDelayToPlayer(Player) 
      Shine.ScreenText.Add( 71, {X = 0.20, Y = 0.80,Text = "Ink: %s",Duration = 15,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s rolled a total of 3 inks every 5 seconds", true, Player:GetName())
      Player:GiveItem(ShadeInk.kMapName)
      self:CreateTimer(8, 3, 5, function() if not Player:GetIsAlive() then self.ScreenText.End(71) self:DestroyTimer(8) return end Player:GiveItem(ShadeInk.kMapName) end )
      return
      end // end of effects roll 5
      if EffectsRoll == 6 then
      self:AddDelayToPlayer(Player) 
      local  kSporeTimer = math.random(15, 60)
      Shine.ScreenText.Add( 63, {X = 0.20, Y = 0.80,Text = "Spores: %s",Duration = kSporeTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s won %s seconds of spore clouds spawning on player", true, Player:GetName(), kSporeTimer)  
      Player:GiveItem(SporeCloud.kMapName)
      self:CreateTimer(9, 1, kSporeTimer, function () if not Player:GetIsAlive() then self.ScreenTextEnd(63) self:DestroyTimer(9) return end Player:GiveItem(SporeCloud.kMapName) end )
      return 
      end // end of effects roll 6
      if EffectsRoll == 7 then
       self:AddDelayToPlayer(Player)
       local kWonBabblersAmount = math.random(3, 12)
      self:NotifyAlien( nil, "%s won %s babblers", true, Player:GetName(), kWonBabblersAmount)  
      for i = 1, kWonBabblersAmount do
            local babbler = CreateEntity(Babbler.kMapName, Player:GetOrigin(), Player:GetTeamNumber())
            babbler:SetOwner(Player)
       end 
      return 
      end  //alien effects roll 7
      if EffectsRoll == 8 then
      self:AddDelayToPlayer(Player)
      Shine.ScreenText.Add( 64, {X = 0.20, Y = 0.80,Text = "MucousMembrane: %s",Duration = 15,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s won 3 mucous membranes every 5 seconds", true, Player:GetName())  
      Player:GiveItem(MucousMembrane.kMapName)
      self:CreateTimer(10, 1, 15, function () if not Player:GetIsAlive() then self:DestroyTimer(10) self.ScreenText.End(64) return end Player:GiveItem(MucousMembrane.kMapName) end ) 
      return 
      end  //alien effects roll 8
      if EffectsRoll == 9 then
      self:AddDelayToPlayer(Player) 
      local kZeroEnergyTimer = math.random(5,30)
      Shine.ScreenText.Add( 65, {X = 0.20, Y = 0.80,Text = "Zero Energy: %s",Duration = kZeroEnergyTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s rolled %s seconds of 0 energy", true, Player:GetName(), kZeroEnergyTimer)
      Player:SetEnergy(0)
       self:CreateTimer(11, 1, kZeroEnergyTimer, function () if not Player:GetIsAlive() then self.ScreenText.End(65) self:DestroyTimer(11) return end Player:SetEnergy(0) end )
      return
      end//end of effects roll 9
      if EffectsRoll == 10 then
      self:AddDelayToPlayer(Player) 
      local kInfiniteEnergyTimer = math.random(15,60)
      Shine.ScreenText.Add( 66, {X = 0.20, Y = 0.80,Text = "Infinite Energy: %s",Duration = kInfiniteEnergyTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s won %s seconds of infinite energy", true, Player:GetName(), kInfiniteEnergyTimer)
      Player:TriggerInfiniteEnergy(kInfiniteEnergyTimer)
      return
      end//end of effects roll 10
      if EffectsRoll == 11 then
      self:AddDelayToPlayer(Player) 
     local  kInfiniteEnergyANDEnzymeTimer = math.random(15,60)
      Shine.ScreenText.Add( 67, {X = 0.20, Y = 0.80,Text ="Energy & Enzyme: %s",Duration = kInfiniteEnergyANDEnzymeTimer,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s won %s seconds of infinite energy AND enzyme", true, Player:GetName(), kInfiniteEnergyANDEnzymeTimer)
      Player:TriggerInfiniteEnergy(kInfiniteEnergyANDEnzymeTimer)
      Player:TriggerFireProofEnzyme(kInfiniteEnergyANDEnzymeTimer)
      return
      end//end of effects roll 10
    /*
            if EffectsRoll == 12 then
            self:NotifyAlien( nil, "%s is becoming paranoid", true, Player:GetName())
            self:CreateTimer( self.FoVTimer, 1, 29, function ()  if not Player:GetIsAlive() and self:TimerExists(  self.FoVTimer ) then self:DestroyTimer( self.FoVTimer ) return end Player:SetFov(Player:GetFov() + 3) end )
            self:CreateTimer( self.FoVRestoreTimer, 31, 1, function () if not Player:GetIsAlive() and self:TimerExists( self.FoVRestoreTimer ) then self:DestroyTimer( self.FoVRestoreTimer ) return end Player:SetFov(Player:GetFov() - 87) end )
            self:AddDelayToPlayer(Player) 
            return
            end//end of effects roll 11
       */
           if EffectsRoll == 12 then
           self:AddDelayToPlayer(Player) 
           self:NotifyAlien( nil, "%s is being hit by a slap bomb", true, Player:GetName())
            self:CreateTimer(12, 0.5, 30, function () if not Player:GetIsAlive() then self:DestroyTimer(12) return end Player:SetVelocity(Player:GetVelocity() + Vector(math.random(-50, 50),math.random(-10, 10),math.random(-50, 50))) end )
            return
            end//end of effectsroll 12
           if EffectsRoll == 13 then
            self:AddDelayToPlayer(Player)
            if Player:GetIsOnFire() then self:RollPlayer(Player) return end
           Player:SetOnFire()
           self:NotifyAlien( nil, "%s has been set on fire", true, Player:GetName())
           return
          end//effects roll 14
          if EffectsRoll == 14 then
            self:AddDelayToPlayer(Player) 
            CreateEntity(Scan.kMapName, Player:GetOrigin(), 1)    
            StartSoundEffectForPlayer(Observatory.kCommanderScanSound, Player)
            self:NotifyAlien( nil, "%s has been scanned", true, Player:GetName())
            return
            end//end of effects roll 15
          if EffectsRoll == 15 then
            self:NotifyAlien( nil, "%s Has been bonewall-ed", true, Player:GetName())
            CreateEntity(BoneWall.kMapName, Player:GetOrigin(), 2)    
            StartSoundEffectForPlayer(AlienCommander.kBoneWallSpawnSound, Player)
            end//end of effects roll 16
          if EffectsRoll == 16 then
          local kEnzymeANDUmbraDuration = math.random(15,60)
            Shine.ScreenText.Add( 64, {X = 0.20, Y = 0.80,Text = "Enzyme & Umbra: %s",Duration = kEnzymeANDUmbraDuration, R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
            self:NotifyAlien( nil, "%s won enzyme & umbra for %s seconds", true, Player:GetName(), kEnzymeANDUmbraDuration)
            Player:SetHasFireProofUmbra(true, kEnzymeANDUmbraDuration)
            Player:TriggerFireProofEnzyme(kEnzymeANDUmbraDuration)
            end//end of effects roll 16
            if EffectsRoll == 17 then
           self:AddDelayToPlayer(Player)
      local size = math.random(10,200)
      if size == Player.modelsize then self:RollPlayer(Player) return end
     self:NotifyAlien( nil, "Adjusted %s's size from %s percent to %s percent", true, Player:GetName(), Player.modelsize * 100, size) 
     Player.modelsize = size / 100
     Player:AdjustMaxHealth(Player:GetMaxHealth() * size / 100)
     Player:AdjustMaxArmor(Player:GetMaxArmor() * size / 100) 
      return 
      end // end of effects roll 17
   
       if EffectsRoll == 18 then
           self:AddDelayToPlayer(Player)
      local percent = math.random(-25,25)
     if percent == 0  then self:RollPlayer(Player) return end
      local duration = math.random(15, 45)
     if percent >=1 then 
     self:NotifyAlien( nil, "%s %s percent damage buff against NON PLAYERS for %s seconds", true, Player:GetName(), percent, duration ) 
     Shine.ScreenText.Add( 72, {X = 0.20, Y = 0.80,Text ="damage buff against NON PLAYERS: %s",Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
    else
      self:NotifyAlien( nil, "%s %s percent damage de-buff against NON PLAYERS for %s seconds", true, Player:GetName(), percent, duration ) 
    Shine.ScreenText.Add( 73, {X = 0.20, Y = 0.80,Text ="damage de-buff against NON PLAYERS for %s",Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
    end
     Player:TriggerRTDNonPlayerDamageSclae(duration, percent)
      return 
      end // end of effects roll 19
       if EffectsRoll == 19 then
           self:AddDelayToPlayer(Player)
      local percent = math.random(-25,25)
     if percent == 0 then self:RollPlayer(Player) return end
      local duration = math.random(15, 45)
     if percent >=1 then 
      Shine.ScreenText.Add( 71, {X = 0.20, Y = 0.80,Text ="dmg buff against PLAYERS: %s", Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
     self:NotifyAlien( nil, "%s %s percent damage buff against PLAYERS: %s seconds", true, Player:GetName(), percent, duration ) 
    else
     Shine.ScreenText.Add( 78, {X = 0.20, Y = 0.80,Text ="dmg de-buff against PLAYERS: %s", Duration = duration,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
      self:NotifyAlien( nil, "%s %s percent damage de-buff against PLAYERS:%s seconds", true, Player:GetName(), percent, duration ) 
    end
     Player:TriggerRTDPlayerDamageSclae(duration, percent)
      return 
      end // end of effects roll 19
   
end //end of alien roll 2


 end //end of alien roll

  if Player:isa("Commander") then
            local WinResLoseRes = math.random(1,2)
     //self:NotifyMarine( nil, "%s Random number is 1. Checking resource gain qualifications)", true, Player:GetName())
           if WinResLoseRes == 1 and Player:GetTeam():GetTeamResources() >= kMaxTeamResources  then self:RollPlayer(Player) return end //self:NotifyMarine( nil, "%s Resources are 90 or greater. No need to add. ReRolling.", true, Player:GetName()) self:RollPlayer(Player) return end
           if WinResLoseRes == 1 and Player:GetTeam():GetTeamResources() <= kMaxTeamResources - 1 then
           local OnlyGiveUpToThisMuch = kMaxTeamResources - Player:GetTeam():GetTeamResources()
           local GiveResRTD = math.random(9.0, OnlyGiveUpToThisMuch)
           Player:GetTeam():SetTeamResources(Player:GetTeam():GetTeamResources() + GiveResRTD)
         if Player:GetTeamNumber() == 1 then
           self:NotifyMarine( nil, "%s won %s team resource(s)", true, Player:GetName(), GiveResRTD)
         else
           self:NotifyAlien( nil, "%s won %s team resource(s)", true, Player:GetName(), GiveResRTD)
        end
           self:AddDelayToPlayer(Player)
          return
          end //end of WinResLoseres roll 1
            //self:NotifyMarine( nil, "%s roll number 2. Calcualting how much res the player has.", true, Player:GetName()) 
             if WinResLoseRes == 2 and Player:GetTeam():GetTeamResources() <= 9 then self:RollPlayer(Player) return end //self:NotifyMarine( nil, "%s Player has 9 or less res. No need to remove. ReRolling Player.", true, Player:GetName()) self:RollPlayer(Player)  end
          if WinResLoseRes == 2 and Player:GetTeam():GetTeamResources() >= 10 then   
             //self:NotifyMarine( nil, "%s Player has 10 or greater res. Calculating how much to randomly take away. ", true, Player:GetName()) 
             local OnlyRemoveUpToThisMuch = Player:GetTeam():GetTeamResources()
             local LoseResRTD = math.random(9.0, OnlyRemoveUpToThisMuch) 
              Player:GetTeam():SetTeamResources(Player:GetTeam():GetTeamResources()  - LoseResRTD)
             if Player:GetTeamNumber() == 1 then
             self:NotifyMarine( nil, "%s lost %s team resource(s)", true, Player:GetName(),  LoseResRTD)
            else
             self:NotifyAlien( nil, "%s lost %s team resource(s)", true, Player:GetName(),  LoseResRTD)
            end
         self:AddDelayToPlayer(Player)
         return
         end // end of WinLoseResHealthArmor 2
   end//end of if player is a commander
   
 return false
end //End of rollplayer

function Plugin:Cleanup()
	self:Disable()
	self.BaseClass.Cleanup( self )    
	self.Enabled = false
end

function Plugin:CreateCommands()

local function Stalemate( Client )
local Gamerules = GetGamerules()
if not Gamerules then return end
Gamerules:DrawGame()
Shine:Notify( Client, "end the game." )
end 

local StalemateCommand = self:BindCommand( "sh_stalemate", "stalemate", Stalemate )
StalemateCommand:Help( "declares the round a draw." )

local function ThirdPerson( Client )
local Player = Client:GetControllingPlayer()
if not Player or not HasMixin( Player, "CameraHolder" ) then return end
Player:SetCameraDistance(3 * ConditionalValue(Player:isa("ReadyRoomPlayer"), 1, Player.modelsize * .5) )
end

local ThirdPersonCommand = self:BindCommand( "sh_thirdperson", { "thirdperson", "3rdperson" }, ThirdPerson, true)
ThirdPersonCommand:Help( "Triggers third person view" )
	
local function FirstPerson( Client )
local Player = Client:GetControllingPlayer()
if not Player or not HasMixin( Player, "CameraHolder" ) then return end
Player:SetCameraDistance(0)
end

local FirstPersonCommand = self:BindCommand( "sh_firstperson", { "firstperson", "1stperson" }, FirstPerson, true)
FirstPersonCommand:Help( "Triggers first person view" )

local function GiveRes( Client, TargetClient, Number )
local Giver = Client:GetControllingPlayer()
local Reciever = TargetClient:GetControllingPlayer()
//local TargetName = TargetClient:GetName()
 //Only apply this formula to pres non commanders // If trying to give a number beyond the amount currently owned in pres, do not continue. Or If the reciever already has 100 resources then do not bother taking resources from the giver
  if Giver:GetTeamNumber() ~= Reciever:GetTeamNumber() or Giver:isa("Commander") or Reciever:isa("Commander") or Number > Giver:GetResources() or Reciever:GetResources() == 100 then
  self:NotifyGiveRes( Giver, "Unable to donate any amount of resources to %s", true, Reciever:GetName())
 return end 

 
            //If giving res to a person and that total amount exceeds 100. Only give what can fit before maxing to 100, and not waste the rest.
            if Reciever:GetResources() + Number > 100 then // for example 80 + 30 = 110
            local GiveBack = 0 //introduce x
            GiveBack = Reciever:GetResources() + Number // x = 80 + 30 (110)
            GiveBack = GiveBack - 100  // 110 = 110 - 100 (10)
            Giver:SetResources(Giver:GetResources () - Number + GiveBack) // Sets resources to the value wanting to donate + the portion to give back that's above 100
            local Show = Number - GiveBack
            Reciever:SetResources(100) // Set res to 100 anyway because the check above says if getres + num > 100. Therefore it would be 100 anyway.
              self:NotifyGiveRes( Giver, "%s has reached 100 res, therefore you've only donated %s resource(s)", true, Reciever:GetName(), Show)
              self:NotifyGiveRes( Reciever, "%s donated %s resource(s) to you", true, Giver:GetName(), Show)
            return //prevent from going through the process of handing out res again down below(?)
            end
            ////
 //Otherwise if the giver has the amount to give, and the reciever amount does not go beyond 100, complete the trade. (pres)     
 //Shine:Notify(Client, Number, TargetClient, "Successfully donated %s resource(s) to %s", nil)
Giver:SetResources(Giver:GetResources() - Number)
Reciever:SetResources(Reciever:GetResources() + Number)
self:NotifyGiveRes( Giver, "Succesfully donated %s resource(s) to %s", true, Number, Reciever:GetName())
self:NotifyGiveRes( Reciever, "%s donated %s resource(s) to you", true, Giver:GetName(), Number)
//Notify(StringFormat("[GiveRes] Succesfully donated %s resource(s) to %s.",  Number, TargetName) )


//Now for some fun and to expand on the potential of giveres within ns2 that ns1 did not reach?
//In particular, team res and commanders. 

//If the giver is a commander to a recieving teammate then take the resources out of team resources rather than personal.

//if Giver:GetTeamNumber() == Reciever:GetTeamNumber() and Giver:isa(Commander) then
end

local GiveResCommand = self:BindCommand( "sh_giveres", "giveres", GiveRes, true)
GiveResCommand:Help( "giveres <name> <amount> ~ (No commanders)" )
GiveResCommand:AddParam{ Type = "client",  NotSelf = true, IgnoreCanTarget = true }
GiveResCommand:AddParam{ Type = "number", Min = 1, Max = 100, Round = true }

/*
local function CreateEntity( Client, Targets, String )
for i = 1, #Targets do
local Player = Targets[ i ]:GetControllingPlayer()
if Player and Player:GetIsAlive() and String ~= "alien" and not (Player:isa("Alien") and String == "armory") and not (Player:isa"ReadyRoomTeam" and String == "CommandStation" or String == "Hive") and not Player:isa("Commander") then
//Player:GiveItem(String)
local derp = CreateEntity(String.kMapName, Player:GetOrigin(), String.kMapName:GetTeamNumber()) 
if HasMixin("Construct", derp) and not derp:GetIsBuilt() then derp:SetConstructionComplete() end 

end
end
end

local CreateEntity = self:BindCommand( "sh_createentity", "createentity", CreateEntity )
CreateEntityCommand:AddParam{ Type = "clients" }
CreateEntityCommand:AddParam{ Type = "string" }
CreateEntityCommand:Help( "<player> Give item to player(s)" )
*/

local function Give( Client, Targets, String )
for i = 1, #Targets do
local Player = Targets[ i ]:GetControllingPlayer()
if Player and Player:GetIsAlive() and String ~= "alien" and not (Player:isa("Alien") and String == "armory") and not (Player:isa"ReadyRoomTeam" and String == "CommandStation" or String == "Hive") and not Player:isa("Commander") then
Player:GiveItem(String)
        for index, target in ipairs(GetEntitiesWithMixinWithinRangeAreVisible("Construct", Player:GetOrigin(), 3, true )) do
              if not target:GetIsBuilt() then target:SetConstructionComplete() end
          end
             Shine:CommandNotify( Client, "gave %s an %s", true,
			 Player:GetName() or "<unknown>", String )  
end
end
end

local GiveCommand = self:BindCommand( "sh_give", "give", Give )
GiveCommand:AddParam{ Type = "clients" }
GiveCommand:AddParam{ Type = "string" }
GiveCommand:Help( "<player> Give item to player(s)" )

local function SlapBomb( Client, Targets, Number )
//local Giver = Client:GetControllingPlayer()
for i = 1, #Targets do
local Player = Targets[ i ]:GetControllingPlayer()
if Player and Player:GetIsAlive() and not Player:isa("Commander") and Player:isa("Marine") or Player:isa("Alien") or Player:isa("ReadyRoomTeam") and Player:GetIsAlive() then
    //       self:NotifyGeneric( nil, %s attained a slap bomb every 0.5 seconds for %s itarations", true, Player:GetName(), Number)
            self:CreateTimer( 13, 0.5, Number, 
            function () 
           if not Player:GetIsAlive()  and self:TimerExists( self.SlapMarineTimer ) then self:DestroyTimer( 13 ) return end
            Player:SetVelocity(Player:GetVelocity() + Vector(math.random(-50, 50),math.random(-10, 10),math.random(-50, 50)))
            end )
             Shine:CommandNotify( Client, "slapped %s for %s iterations", true,
		 	 Targets:GetName() or "<unknown>", Number )  
end
end
end

local SlapBombCommand = self:BindCommand( "sh_slapbomb", "slapbomb", SlapBomb )
SlapBombCommand:Help ("sh_slapbomb <player(s)> <time> Sets a slap bomb on the player(s) with the number being iteration count")
SlapBombCommand:AddParam{ Type = "clients" }
SlapBombCommand:AddParam{ Type = "number" }


/*
local function DiscoLights( Client )
for _, light in ientitylist(Shared.GetEntitiesWithClassname("light_spot")) do
            light:SetColor( math.random(0, 255), math.random(0, 255), math.random(0,255) )
            light:SetIntensity( math.random(1,5) )
end
for _, lighty in ientitylist(Shared.GetEntitiesWithClassname("light_point")) do
            lighty:SetColor( math.random(0, 255), math.random(0, 255), math.random(0,255) )
            lighty:SetIntensity( math.random(1,5) )
end
end

    
local DiscoLightsCommand = self:BindCommand( "sh_discolights", "discolights", DiscoLights, true )
DiscoLightsCommand:Help ("sh_discolights")

*/
local function Construct( Client )
        local Player = Client:GetControllingPlayer()
        for index, constructable in ipairs(GetEntitiesWithMixinWithinRangeAreVisible("Construct", Player:GetEyePos(), 3, true )) do       
            if not constructable:GetIsBuilt() then
                constructable:SetConstructionComplete()
            end
            
        end
end

local ConstructCommand = self:BindCommand ("sh_construct", "construct", Construct)
ConstructCommand:Help ("Be close to the structure and use this to construct it")

local function DeConstruct( Client )
        local Player = Client:GetControllingPlayer()
        for index, deconstructable in ipairs(GetEntitiesWithMixinWithinRangeAreVisible("Construct", Player:GetEyePos(), 3, true )) do       
            if deconstructable:GetIsBuilt() then
                deconstructable:ResetConstructionStatus()
                deconstructable:ResetConstructionStatus()
            end
            
        end
end

local DeConstructCommand = self:BindCommand ("sh_deconstruct", "deconstruct", DeConstruct)
DeConstructCommand:Help ("Be close to the structure and use this to deconstruct it")

local function Destroy( Client  )
        local player = Client:GetControllingPlayer()
        for index, target in ipairs(GetEntitiesWithMixinWithinRangeAreVisible("Construct", player:GetEyePos(), 3, true )) do
               if not target:isa("PowerPoint") or not target:isa("Hive") or not target:isa("CommandStation") then 
                  DestroyEntity(target) end
	        	Shine:CommandNotify( Client, "destroyed %s.", true,
				target:GetTechId()() or "<unknown>" )        
               end
end

local DestroyCommand = self:BindCommand( "sh_destroy", "destroy", Destroy )
DestroyCommand:Help( "Look at the structure you want to destroy and run this command" )

local function Respawn( Client, Targets )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
	        	Shine:CommandNotify( Client, "respawned %s.", true,
				Player:GetName() or "<unknown>" )  
         Player:GetTeam():ReplaceRespawnPlayer(Player)
     end
end

local RespawnCommand = self:BindCommand( "sh_respawn", "respawn", Respawn )
RespawnCommand:AddParam{ Type = "clients" }
RespawnCommand:Help( "<player> respawns said player" )
        
local function PlayerGravity( Client, Targets, Number )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
            if not Player:isa("Commander") and Player:isa("Alien") or Player:isa("Marine") or Player:isa("ReadyRoomTeam") then
              self:NotifyGeneric( nil, "Adjusted %s players gravity to %s", true, Player:GetName(), Number)
               function Player:GetGravityForce(input)
               return Number
               end    
             end
//Glitchy way. There's resistance in the first person camera, to this. Perhaps try hooking with shine and changing that way, instead.
     end
end

local PlayerGravityCommand = self:BindCommand( "sh_playergravity", "playergravity", PlayerGravity )
PlayerGravityCommand:AddParam{ Type = "clients" }
PlayerGravityCommand:AddParam{ Type = "number" }
PlayerGravityCommand:Help( "sh_playergravity <player> <number> works differently than ns1. kinda glitchy. respawn to reset." )


local function ModelSize( Client, Targets, Number )
  if Number > 10 then return end
  if #Targets ~= 1 then
  self:NotifyGeneric( nil, "Adjusted %s players size to %s percent", true, #Targets, Number * 100)
   end
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
            if not Player:isa("Commander") and not Player:isa("Spectator") and Player.modelsize and Player:GetIsAlive() then
                if #Targets == 1 then
                self:NotifyGeneric( nil, "Adjusted %s's size from %s percent to %s percent", true, Player:GetName(), Player.modelsize * 100, Number * 100)
               end
             //  if not ( Player:isa("Exo") or Player:isa("Onos") and Number >= 2 ) or Number ~= 1 then Player:SetCameraDistance(Number) end
                Player.modelsize = Number
               local defaulthealth = LookupTechData(Player:GetTechId(), kTechDataMaxHealth, 1)
               Player:AdjustMaxHealth(defaulthealth * Number)
                Player:AdjustMaxArmor(Player:GetMaxArmor() * Number)
                
             end
     end
end

local ModelSizeCommand = self:BindCommand( "sh_modelsize", "modelsize", ModelSize )
ModelSizeCommand:AddParam{ Type = "clients" }
ModelSizeCommand:AddParam{ Type = "number" }
ModelSizeCommand:Help( "sh_playergravity <player> <number> works differently than ns1. kinda glitchy. respawn to reset." )

/*
local function TimeBomb(Client, Targets)
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer() 
        if not Player:isa("Commander") and ( Player:isa("Alien") or Player:isa("Marine") ) and Player:GetIsAlive() then
        Shine.ScreenText.Add( "TimeBomb", {X = 0.50, Y = 0.50,Text = Player:GetName() .."will explode in %s", Duration = kTimeBombTimer,R = 255, G = 0, B = 0,Alignment = 0,Size = 1,FadeIn = 0,} )
                  self:SimpleTimer( kTimeBombTimer, 
                  function () 
                  if not Player:GetIsAlive() then return end
                  Player:TriggerEffects("xenocide", {effecthostcoords = Coords.GetTranslation(Player:GetOrigin())})
                  local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(Player:GetTeamNumber()), Player:GetOrigin(), 12)
                  RadiusDamage(hitEntities, Targets:GetClient():GetOrigin(), 12, 1000, Targets:GetClient())
                  Player:Kill()
                  end )
             end
        end
end

local TimeBombCommand = self:BindCommand( "sh_timebomb", "timebomb", TimeBomb )
TimeBombCommand:AddParam{ Type = "clients" }
TimeBombCommand:Help( "sh_timebomb <player> makes the person xenocide basically" )

*/
/*
local function PlayerFriction( Client, Targets, Number )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
            if not Player:isa("Commander") and Player:isa("Alien") or Player:isa("Marine") or Player:isa("ReadyRoomTeam") then
               //Player:GetMixinConstants().kGravity = Number    
               function Player:GetFriction(input, velocity)
               local friction = Number
               local frictionScalar = 1
               return friction * frictionScalar
               end    
             end
//Glitchy way. There's resistance in the first person camera, to this. Perhaps try hooking with shine and changing that way, instead.
     end
end

local PlayerFrictionCommand = self:BindCommand( "sh_playerfriction", "playerfriction", PlayerFriction )
PlayerFrictionCommand:AddParam{ Type = "clients" }
PlayerFrictionCommand:AddParam{ Type = "number" }
PlayerFrictionCommand:Help( "sh_playerfriction <player> <number> works differently than ns1. kinda glitchy. respawn to reset." )
*/

local function Pres( Client, Targets, Number )
    for i = 1, #Targets do
    local Player = Targets[ i ]:GetControllingPlayer()
            if not Player:isa("ReadyRoomTeam")  and Player:isa("Alien") or Player:isa("Marine") then
            Player:SetResources(Number)
           	 Shine:CommandNotify( Client, "set %s's resources to %s", true,
			 Player:GetName() or "<unknown>", Number )  
             end
     end
end

local PresCommand = self:BindCommand( "sh_pres", "pres", Pres)
PresCommand:AddParam{ Type = "clients" }
PresCommand:AddParam{ Type = "number" }
PresCommand:Help( "sh_pres <player> <number> sets player's pres to the number desired." )


local function RandomRR( Client )
        local rrPlayers = GetGamerules():GetTeam(kTeamReadyRoom):GetPlayers()
        for p = #rrPlayers, 1, -1 do
            JoinRandomTeam(rrPlayers[p])
        end
           Shine:CommandNotify( Client, "randomized the readyroom", true)  
end

local RandomRRCommand = self:BindCommand( "sh_randomrr", "randomrr", RandomRR )
RandomRRCommand:Help( "randomize's the ready room.") 

local function RTDDelay(Client, Number)
local oldvalue = self.rtd_succeed_cooldown
self.rtd_succeed_cooldown = Number
if oldvalue > Number then self.Users = {} end //So that changing the convar mid game also updates those who rolled before hand rather than it not being updated after. 
                                              //Probably an alternate way that doesn't reset the playerlist, but rather subtract from the total based on the difference.
                                              //But until or if this becomes a problem, then..
if self.rtd_succeed_cooldown > 90 then
self:NotifyMarine( nil, "RTD has been disabled", true)
self.rtdenabled = false
else
self.rtdenabled = true
self:NotifyMarine( nil, "RTD has been enabled. Cooldown set at %s seconds. Type /rtd or press M to try it out", true, Number)
end
end

local RTDDelayCommand = self:BindCommand("sh_rtddelay", "rtddelay", RTDDelay)
RTDDelayCommand:Help("Sets the successful rtd delay cooldown with the failed cooldown 30 seconds less than that.")
RTDDelayCommand:AddParam{ Type = "number" }


local function Buy(Client, String)
local Player = Client:GetControllingPlayer()

local Time = Shared.GetTime()
local NextUse = self.BuyUsersTimer[Client]
if NextUse and NextUse > Time then
self:NotifyCredits( Client, "Please wait %s seconds before purchasing %s. Thanks.", true, string.TimeToString( NextUse - Time ), String)
return
end

if not GetGamerules():GetGameStarted() then
self:NotifyCredits( Client, "Buying in pregame is not supported right now. It's a waste of credits unless determined pregame to be free spending later on.", true)
return
end
local gameRules = GetGamerules()
if gameRules:GetGameStarted() and Shared.GetTime() - gameRules:GetGameStartTime() > (kSiegeDoorTime + kTimeAfterSiegeOpeningToEnableSuddenDeath) then 
self:NotifyCredits( Client, "Buying in suddendeath is not supported right now.", true)
return
end
if Player:isa("Commander") or not Player:GetIsAlive() then 
      self:NotifyCredits( Client, "Either you're dead, or a commander... Really no difference between the two.. anyway, no credit spending for you.", true)
return
end

/*
if Player then
 self:NotifyCredits( Client, "Purchases currently disabled. ", true)
 return
end
*/
local CreditCost = 1
local AddTime = 0

if Player:GetTeamNumber() == 1 then 

if String == "CatPack" then
CreditCost = 2
      if self:GetPlayerCreditsInfo(Client) < CreditCost then
      self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
      return
      end
   self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
   //self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   Shine.ScreenText.Add( 52, {X = 0.20, Y = 0.85,Text = "Catpack: %s",Duration = 30,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
   StartSoundEffectAtOrigin(CatPack.kPickupSound, Player:GetOrigin())
   Player:ApplyDurationCatPack(30) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 60
   return
end

if String == "Nano" then
CreditCost = 2
      if self:GetPlayerCreditsInfo(Client) < CreditCost then
      self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
      return
      end
   self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
   //self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   Shine.ScreenText.Add( 53, {X = 0.20, Y = 0.85,Text = "Nano: %s",Duration = 30,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
   Player:ActivateDurationNanoShield(kNanoShieldDuration)
   self.BuyUsersTimer[Client] = Shared.GetTime() + 60
   return
end

if String == "AmmoPack" then
      if self:GetPlayerCreditsInfo(Client) < CreditCost then
      self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
      return
      end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(AmmoPack.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "MedPack" then

if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
Player:GiveItem(MedPack.kMapName)
   self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "Scan" then
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Scan.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
StartSoundEffectForPlayer(Observatory.kCommanderScanSound, Player)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
      self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "Mac" then
CreditCost = 5

if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 */
 
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.MAC) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end


self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local mac = CreateEntity(MAC.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
mac.iscreditstructure = true
Player:GetTeam():RemoveSupplyUsed(kMACSupply)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "Observatory"  then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Observatory) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local obs = CreateEntity(Observatory.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
obs:SetConstructionComplete()
//obs.isGhostStructure = false
obs.iscreditstructure = true
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "CommandStation" then
CreditCost = 1000
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.CommandStation) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local cc = CreateEntity(CommandStation.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
//cc:SetConstructionComplete()
cc.isGhostStructure = false
obs.iscreditstructure = true
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
return
end

if String == "Armory"  then
CreditCost = 15
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 
if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Armory) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end


self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local armory = CreateEntity(Armory.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
armory:SetConstructionComplete()
//armory.isGhostStructure = false
armory.iscreditstructure = true
Player:GetTeam():RemoveSupplyUsed(kArmorySupply)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "PhaseGate" then
CreditCost = 15
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.PhaseGate) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local pg = CreateEntity(PhaseGate.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
pg:SetConstructionComplete()
//pg.isGhostStructure = false
pg.iscreditstructure = true
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "InfantryPortal" then
CreditCost = 15
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.InfantryPortal) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local ip = CreateEntity(InfantryPortal.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
ip:SetConstructionComplete()
//ip.isGhostStructure = false
ip,iscreditstructure = true
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "RoboticsFactory" then
CreditCost = 15
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.RoboticsFactory) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
if Client:GetUserId() ~= "25542592" then self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost end
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local robo = CreateEntity(RoboticsFactory.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
robo:SetConstructionComplete()
//robo.isGhostStructure = false
robo.iscreditstructure = true
Player:GetTeam():RemoveSupplyUsed(kRoboticsFactorySupply)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 15
return
end

if String == "ARC" then
CreditCost = 20
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end

if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.ARC) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local arc = CreateEntity(ARC.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
arc:GiveOrder(kTechId.ARCDeploy, arc:GetId(), arc:GetOrigin(), nil, false, false)
arc.iscreditstructure = true
Player:GetTeam():RemoveSupplyUsed(kARCSupply)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 30
return
end

if String == "LowerSupplyLimit" then
CreditCost = 5
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s lowered team supply limit by 10, with %s credits", true, Player:GetName(), CreditCost)
Player:GetTeam():RemoveSupplyUsed(5)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "Welder" then
CreditCost = 1
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(Welder.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "Mines" then
CreditCost = 1.5
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(LayMines.kMapName)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 15
return
end

if String == "GrenadeLauncher" then
CreditCost = 3
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(GrenadeLauncher.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "FlameThrower" then
CreditCost = 3
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(Flamethrower.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "UpgradedRifle" then
CreditCost = 2
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(HeavyRifle.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "ShotGun" then
CreditCost = 2
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(Shotgun.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "JetPack" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveJetpack()
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "MiniGunClawExo" then

if Player:isa("Exo") then 
self:NotifyCredits( Client, "Cannot buy exo while an exo. Even if you are a single trying to upgrade, it will error out. Though possible to fix. Easier to restrict.", true)
return
end
CreditCost = 30
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveExo(Player:GetOrigin())
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "RailGunClawExo" then

if Player:isa("Exo") then 
self:NotifyCredits( Client, "Cannot buy exo while an exo. Even if you are a single trying to upgrade, it will error out. Though possible to fix. Easier to restrict.", true)
return
end
CreditCost = 30
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveClawRailgunExo(Player:GetOrigin())
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "DualMiniGunExo" then
if Player:isa("Exo") then 
self:NotifyCredits( Client, "Cannot buy exo while an exo. Even if you are a single trying to upgrade, it will error out. Though possible to fix. Easier to restrict.", true)
return
end
CreditCost = 45
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveDualExo(Player:GetOrigin())
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end
if String == "DualRailExo" then
if Player:isa("Exo") then 
self:NotifyCredits( Client, "Cannot buy exo while an exo. Even if you are a single trying to upgrade, it will error out. Though possible to fix. Easier to restrict.", true)
return
end
CreditCost = 45
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveDualRailgunExo(Player:GetOrigin())
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "TechPoint"  then
    CreditCost = 5000
      if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
      self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
      return
      end
      if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.TechPoint) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
  self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
  self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
  CreateEntity(TechPoint.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
     Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
  return
end


if String == "ResPoint" then
CreditCost = 100
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.ResourcePoint) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
CreateEntity(ResourcePoint.kPointMapName, Player:GetOrigin(), Player:GetTeamNumber())    
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 60
return
end
if String == "Extractor" then
CreditCost = 150
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Extractor) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
local extractor = CreateEntity(Extractor.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
extractor:SetConstructionComplete()
//extractor.isGhostStructure = false
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 60
return
end
if String == "Badge" then
CreditCost = 1000
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
self:NotifyCredits( Client, "Bug Avoca for this.", true)
return
end

if String == "Shrink" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
if Player.modelsize <= .25 then
self:NotifyCredits( Player, "Cannot go below 25%")
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( Client, "Warning: Your size will reset when you die, and/or when you change class. Such as gestation, or changing from marine to jetpack, or exo to marine, etc.", true)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
Player.modelsize = Player.modelsize - .25 
self:NotifyCredits( Client, "Current size = %s percent", true, math.round(Player.modelsize * 100, 1))
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
local defaulthealth = LookupTechData(Player:GetTechId(), kTechDataMaxHealth, 1)
Player:AdjustMaxHealth(defaulthealth * Player.modelsize)
Player:AdjustMaxArmor(90 * Player.modelsize)
return
end
if String == "Grow" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end

if Client then 
self:NotifyCredits( Client, "This heavyily breaks balance and I have no idea how to balance it yet. So until then, growing via credits is disabled.", true)
return
end

if Player:isa("Exo") and Player.modelsize >= 1.3 then
self:NotifyCredits( Player, "Cannot go above 130% as an exo")
return
elseif Player.modelsize >= 1.5 then 
self:NotifyCredits( Player, "Cannot go above 150%")
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( Client, "Warning: Your size will reset when you die, and/or when you change class. Such as gestation, or changing from marine to jetpack, or exo to marine, etc.", true)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
if Player:isa("Exo") then
Player.modelsize = Player.modelsize + .1
else
 Player.modelsize = Player.modelsize + .1
end
self:NotifyCredits( Client, "Current size = %s percent", true, math.round(Player.modelsize * 100, 1))
local defaulthealth = LookupTechData(Player:GetTechId(), kTechDataMaxHealth, 1)
Player:AdjustMaxHealth(defaulthealth * Player.modelsize)
Player:AdjustMaxArmor(90 * Player.modelsize)
          
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

elseif Player:GetTeamNumber() == 2 then

if String == "LowerSupplyLimit" then
CreditCost = 5
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s lowered team supply limit by 10, with %s credits", true, Player:GetName(), CreditCost)
Player:GetTeam():RemoveSupplyUsed(5)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "ResPoint" then
CreditCost = 100
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.ResourcePoint) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
CreateEntity(ResourcePoint.kPointMapName, Player:GetOrigin(), Player:GetTeamNumber())  
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client)   
return
end

if String == "TechPoint"  then
    CreditCost = 500
      if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
      self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
      return
      end
      if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.TechPoint) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
  self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
  self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
  CreateEntity(TechPoint.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
     Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
  return
end
if String == "Harvester" then
CreditCost = 150
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Harvester) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s a purchased a %s for %s credits", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
local harv = CreateEntity(Harvester.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
harv:SetConstructionComplete()
//harv.isGhostStructure = false
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
return
end
if String == "BadgeA" then
CreditCost = 1000
if self.CreditUsers[ Client ] and self.CreditUsers[ Client ] < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
self:NotifyCredits( Client, "Bug Avoca for this.", true)
return
end
if String == "NutrientMist" then
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(NutrientMist.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "Contamination"  then
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( nil, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(Contamination.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "EnzymeCloud" then
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(EnzymeCloud.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
         self.BuyUsersTimer[Client] = Shared.GetTime() + 3
return
end

if String == "Enzyme" then
CreditCost = 2
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
Shine.ScreenText.Add( 53, {X = 0.20, Y = 0.85,Text = "Enzyme: %s",Duration = 30,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
Player:TriggerFireProofEnzyme(30)
self.BuyUsersTimer[Client] = Shared.GetTime() + 60
return
end

if String == "Umbra" then
CreditCost = 2
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
Shine.ScreenText.Add( 53, {X = 0.20, Y = 0.85,Text = "Umbra: %s",Duration = 30,R = 255, G = 255, B = 0,Alignment = 0,Size = 1,FadeIn = 0,}, Player )
Player:SetHasFireProofUmbra(true, 30)
self.BuyUsersTimer[Client] = Shared.GetTime() + 60
return
end

if String == "Ink" then
CreditCost = 1
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( Client, "purchased %s with %s credit(s). Please wait 30 seocnds before purchasing it again. Thanks.", true, String, CreditCost)
self.BuyUsersTimer[Client] = Shared.GetTime() + 60
Player:GiveItem(ShadeInk.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
return
end

if String == "Hallucination" then
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(HallucinationCloud.kMapName)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
      self.BuyUsersTimer[Client] = Shared.GetTime() + 15
return
end

if String == "Drifter" then
CreditCost = 5
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Drifter) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
Player:GiveItem(Drifter.kMapName)
Player:GetTeam():RemoveSupplyUsed(kDrifterSupply)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "Shade" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Shade) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
local shade = CreateEntity(Shade.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
shade:SetConstructionComplete()
//shade.isGhostStructure = false
Player:GetTeam():RemoveSupplyUsed(kShadeSupply)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
   self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "Crag" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Crag) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
local crag = CreateEntity(Crag.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
crag:SetConstructionComplete()
//crag.isGhostStructure = false
Player:GetTeam():RemoveSupplyUsed(kCragSupply)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "Whip" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Whip) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
local Time = Shared.GetTime()
local NextUse = self.BuyUsersTimer[Client]
if NextUse and NextUse > Time then
self:NotifyCredits( Client, "Please wait %s seconds before purchasing %s. Thanks.", true, string.TimeToString( NextUse - Time ), String)
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
local whip = CreateEntity(Whip.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
whip:SetConstructionComplete()
//whip.isGhostStructure = false
whip.whipParentId = Player:GetId()
Player:GetTeam():RemoveSupplyUsed(kWhipSupply)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "Shift" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Shift) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin(), Player:GetTeamNumber()) 
local shift = CreateEntity(Shift.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
shift:SetConstructionComplete()
//shift.isGhostStructure = false
Player:GetTeam():RemoveSupplyUsed(kShiftSupply)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end

if String == "Hydra" then
CreditCost = 1
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
/*
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Hydra) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
*/
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local hydra = CreateEntity(Hydra.kMapName, Player:GetOrigin(), Player:GetTeamNumber())    
hydra:SetConstructionComplete()
//hydra.isGhostStructure = false
hydra.hydraParentId = Player:GetId()
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
self.BuyUsersTimer[Client] = Shared.GetTime() + 5
return
end

if String == "Egg" then
CreditCost = 2
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Egg) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
CreateEntity(Clog.kMapName, Player:GetOrigin() + Vector(1, .5, 0), Player:GetTeamNumber()) 
CreateEntity(Egg.kMapName, Player:GetOrigin(), Player:GetTeamNumber())
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client)   
self.BuyUsersTimer[Client] = Shared.GetTime() + 5  
return
end

if String == "Hive" then
CreditCost = 1000
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Hive) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
local hive = CreateEntity(Hive.kMapName, Player:GetOrigin() + Vector(0, 3, 0), Player:GetTeamNumber())    
hive:SetConstructionComplete()
//hive.isGhostStructure = false
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
return
end

if String == "Gorge" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 

                  local newPlayer = Player:Replace(Gorge.kMapName, Player:GetTeamNumber(), nil, nil, extraValues)
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1


return
end

if String == "Lerk" then
CreditCost = 20
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 

                  local newPlayer = Player:Replace(Lerk.kMapName, Player:GetTeamNumber(), nil, nil, extraValues)
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1


return
end

if String == "Fade" then
CreditCost = 30
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 

                  local newPlayer = Player:Replace(Fade.kMapName, Player:GetTeamNumber(), nil, nil, extraValues)
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1


return
end

if String == "Onos" then
CreditCost = 40
if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased a %s with %s credit(s)", true, Player:GetName(), String, CreditCost)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 

                  local newPlayer = Player:Replace(Onos.kMapName, Player:GetTeamNumber(), nil, nil, extraValues)
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1


return
end

if String == "Shrink" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
if Player.modelsize <= .25 then
self:NotifyCredits( Player, "Cannot go below 25%")
return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( Client, "Warning: Your size will reset when you die, and/or when you change class. Such as gestation, or changing from marine to jetpack, or exo to marine, etc.", true)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
Player.modelsize = Player.modelsize - .25 
self:NotifyCredits( Client, "Current size = %s percent", true, math.round(Player.modelsize * 100, 1))
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
local defaulthealth = LookupTechData(Player:GetTechId(), kTechDataMaxHealth, 1)
local defaultarmor = LookupTechData(Player:GetTechId(), kTechDataMaxArmor, 1)
Player:AdjustMaxHealth(defaulthealth * Player.modelsize)
Player:AdjustMaxArmor(defaultarmor * Player.modelsize)
return
end

if String == "Grow" then
CreditCost = 10
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end

if Client then 
self:NotifyCredits( Client, "This heavyily breaks balance and I have no idea how to balance it yet. So until then, growing via credits is disabled.", true)
return
end

if Player:isa("Onos") and Player.modelsize >= 1.5 then
self:NotifyCredits( Player, "Cannot go above 150% as an onos")
return
elseif Player:isa("Fade") and Player.modelsize >= 2.0 then
self:NotifyCredits( Player, "Cannot go above 200% as an fade")
return
elseif Player:isa("Lerk") and Player.modelsize >= 2.5 then
self:NotifyCredits( Player, "Cannot go above 250% as an lerk")
return
elseif Player:isa("Gorge") and Player.modelsize >= 3.1 then
self:NotifyCredits( Player, "Cannot go above 400% as an gorge")
return
elseif Player:isa("Skulk") and Player.modelsize >= 4.1 then
self:NotifyCredits( Player, "Cannot go above 500% as an skulk")
return
end

self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
self:NotifyCredits( Client, "Warning: Your size will reset when you die, and/or when you change class. Such as gestation, or changing from marine to jetpack, or exo to marine, etc.", true)
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 

if Player:isa("Onos") then
Player.modelsize = Player.modelsize + .1 
elseif Player:isa("Fade") then
Player.modelsize = Player.modelsize + .20
elseif Player:isa("Lerk") then
Player.modelsize = Player.modelsize + .30
elseif Player:isa("Gorge") then
Player.modelsize = Player.modelsize + .6
elseif Player:isa("Skulk") then
Player.modelsize = Player.modelsize + 1
end

self:NotifyCredits( Client, "Current size = %s percent", true, math.round(Player.modelsize * 100, 1))
local defaulthealth = LookupTechData(Player:GetTechId(), kTechDataMaxHealth, 1)
Player:AdjustMaxHealth(defaulthealth * Player.modelsize)
Player:AdjustMaxArmor(90 * Player.modelsize)
          
self.BuyUsersTimer[Client] = Shared.GetTime() + 10
return
end
          if String == "TaxiDrifter" then 
          
          if self:GetPlayerCreditsInfo(Client) < CreditCost then 
self:NotifyCredits( Client, "%s costs %s credits, you have %s credit(s). Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
return
end
if not Player:GetIsOnGround() then
 self:NotifyCredits( Client, "You must be on the ground to purchase an %s", true, String)
 return
 end
 
if not GetPathingRequirementsMet(Vector( Player:GetOrigin() ),  GetExtents(kTechId.Armory) ) then
self:NotifyCredits( Client, "Pathing does not exist in this placement. Purchase invalid.", true)
return 
end

          CreditCost = 10
          self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
          Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
                    local newPlayer = Player:Replace(Gorge.kMapName, Player:GetTeamNumber(), nil, nil, extraValues)
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1
                    
           local drifter = Player:GiveItem(Drifter.kMapName)
           Player:GetTeam():RemoveSupplyUsed(kDrifterSupply)
           drifter.modelsize = 50
           Player.isridingdrifter = true 
           Player.drifterId = drifter:GetId()
           drifter:GiveOrder(kTechId.Move, nil, GetTaxiDrifterCCLocation(self), nil, true, true, giver)
          end //of taxidrifter


end // end of team numbers




if String == "Gravity" and Player:GetTeamNumber() == 2 or Player:GetTeamNumber() == 1 then
CreditCost = 1
if self:GetPlayerCreditsInfo(Client) < CreditCost then
self:NotifyCredits( Client, "%s costs %s credit, you have %s credit. Purchase invalid.", true, String, CreditCost, self:GetPlayerCreditsInfo(Client))
 return
end
self.CreditUsers[ Client ] = self:GetPlayerCreditsInfo(Client) - CreditCost
//self:NotifyCredits( nil, "%s purchased Low Gravity with %s credit(s)", true, Player:GetName(), CreditCost)
self:NotifyCredits( Client, "Low Gravity lasts until death/gestation", true)
   Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Client) 
  function Player:GetGravityForce(input)
  return -5
   end    
return
end

self:NotifyCredits( Client, "Invalid Purchase Request of %s.", true, String)
end

local BuyCommand = self:BindCommand("sh_buy", "buy", Buy, true)
BuyCommand:Help("sh_buy <item name>")
BuyCommand:AddParam{ Type = "string" }

local function Credits(Client, Targets)
for i = 1, #Targets do
local Player = Targets[ i ]:GetControllingPlayer()
self:NotifyCredits( Client, "%s has a total of %s credits", true, Player:GetName(), self:GetPlayerCreditsInfo(Player:GetClient()))
end
end

local CreditsCommand = self:BindCommand("sh_credits", "credits", Credits, true, false)
CreditsCommand:Help("sh_credits <name>")
CreditsCommand:AddParam{ Type = "clients" }

local function AddCredits(Client, Targets, Number)
for i = 1, #Targets do
local Player = Targets[ i ]:GetControllingPlayer()
self.CreditUsers[ Player:GetClient() ] = self:GetPlayerCreditsInfo(Player:GetClient()) + Number
self:NotifyGeneric( nil, "gave %s credits to %s (who now has a total of %s)", true, Number, Player:GetName(), self:GetPlayerCreditsInfo(Player:GetClient()))
Shine.ScreenText.SetText("Credits", string.format( "%s Credits", self:GetPlayerCreditsInfo(Client) ), Player:GetClient()) 
end
end

local AddCreditsCommand = self:BindCommand("sh_addcredits", "addcredits", AddCredits)
AddCreditsCommand:Help("sh_addcredits <player> <number>")
AddCreditsCommand:AddParam{ Type = "clients" }
AddCreditsCommand:AddParam{ Type = "number" }

local function RollTheDice( Client )
//Do something regarding pre-game?
local Player = Client:GetControllingPlayer()

         if Player:isa("Egg") or Player:isa("Embryo") then
         Shine:NotifyError( Player, "You cannot gamble while an egg/embryo (Yet)" )
         return
         end
         
         if Player:isa("ReadyRoomPlayer") or (Player:GetTeamNumber() ~= 1 and Player:GetTeamNumber() ~= 2) then
         Shine:NotifyError( Player, "You must be an alien or marine to gamble (In this version, atleast)" )
         return
         end
         
         if Player:isa("Commander") then
         Shine:NotifyError( Player, "You cannot gamble while a commander (Yet)" )
         return
         end
         
          if Player:isa("Spectator") then
         Shine:NotifyError( Player, "You cannot gamble while spectating (Yet)" )
         return
         end
         
         if not Player:GetIsAlive() then
         Shine:NotifyError( Player, "You cannot gamble when you are dead (Yet)" )
         return
         end
         
local Time = Shared.GetTime()
local NextUse = self.Users[ Client ]

      if not self.rtdenabled or self.rtd_succeed_cooldown > 90 then 
      Shine:NotifyError( Player, "Currently Disabled.", true )
      return
      end
      
      if NextUse and NextUse > Time then
       Shine:NotifyError( Player, "You must wait %s before gambling again.", true, string.TimeToString( NextUse - Time ) )
      return
       end
       //Weekends
       local Success = self:AddDelayToPlayer(Player)
       //local Success = self:NotifyGeneric(Player, "RollTheDice is currently disabled.") 
if Success then
//Weekends
self:RollPlayer(Player) //Differentiate the Delay and the re-rolling to prevent duplicate chat messages of delay during the re-rolling process.
   //   self:NotifyGeneric(Player, "RollTheDice is currently only enabled on weekends.") 
 //weekends
self.Users[ Client ] = Time + self.rtd_succeed_cooldown
else
Shine:NotifyError( Player, "Unable to gamble. Try again in %s.", true, string.TimeToString( self.rtd_failed_cooldown ) )
self.Users[ Client ] = Time + self.rtd_failed_cooldown
end

end

local RollTheDiceCommand = self:BindCommand( "sh_rtd", { "rollthedice", "rtd" }, RollTheDice, true)
RollTheDiceCommand:Help( "Gamble and emit a positive or negative effect") 


end

local function GetTaxiDrifterCCLocation()
    local CC = GetEntitiesForTeam("CommandStation", 1)
	local selectedcc
	
    for i, CC in ipairs(CCs) do
			selectedcc = CC
	end
	return selectedcc:GetOrigin()
end