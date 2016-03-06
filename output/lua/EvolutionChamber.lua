--[[
    lua/EvolutionChamber.lua
    
    Handles the life-form researches for the Hive.
]]
class 'EvolutionChamber' (ScriptActor)

EvolutionChamber.kMapName = "evolutionchamber"

local networkVars = { }

AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function EvolutionChamber:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, ResearchMixin)

end

function EvolutionChamber:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)
    ScriptActor.SetIncludeRelevancyMask(self, includeMask)

end

EvolutionChamber.kUpgradeButtons ={                            
    [kTechId.SkulkMenu] = { kTechId.Leap, kTechId.Xenocide, kTechId.SkulkRupture, kTechId.None,
                                kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                             
    [kTechId.GorgeMenu] = { kTechId.BileBomb, kTechId.WebTech, kTechId.SpiderGorge, kTechId.None,
                                 kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                                 
    [kTechId.LerkMenu] = { kTechId.Umbra, kTechId.Spores, kTechId.PrimalScream, kTechId.None,
                                 kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                                 
    [kTechId.FadeMenu] = { kTechId.MetabolizeEnergy, kTechId.MetabolizeHealth, kTechId.Stab, kTechId.AcidRocket,
                                 kTechId.None, kTechId.None, kTechId.None, kTechId.None },
                                 
    [kTechId.OnosMenu] = { kTechId.Charge, kTechId.BoneShield, kTechId.Stomp, kTechId.StompUpgrade,
                                 kTechId.None, kTechId.OniPoop, kTechId.None, kTechId.None }
}

function EvolutionChamber:GetTechButtons(techId)

    local techButtons = { kTechId.SkulkMenu, kTechId.GorgeMenu, kTechId.LerkMenu, kTechId.FadeMenu,
                                kTechId.OnosMenu, kTechId.None, kTechId.None, kTechId.None }
    
    local returnButton = kTechId.Return
    if self.kUpgradeButtons[techId] then
        techButtons = self.kUpgradeButtons[techId]
        returnButton = kTechId.RootMenu
    end
    
	techButtons[8] = returnButton
	
    if self:GetIsResearching() then
        techButtons[7] = kTechId.Cancel
    else
        techButtons[7] = kTechId.None
    end
    
    return techButtons
    
end

Shared.LinkClassToMap("EvolutionChamber", EvolutionChamber.kMapName, networkVars)
