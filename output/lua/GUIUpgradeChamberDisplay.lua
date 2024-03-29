// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/GUIUpgradeChamberDisplay.lua
//
// Shows how many shells, spurs, veils you have
//
// Created by Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/GUIScript.lua")

class 'GUIUpgradeChamberDisplay' (GUIScript)

local kMinBioMass = 0
local kMaxBioMass = 9

local kBackgroundPos = GUIScale(Vector(32, 190, 0))
local kBackgroundColor = Color(0, 0, 0, 0)

local kIconSize = GUIScale(58)
local kIconTexture = "ui/buildmenu.dds"

local kIconOffset = GUIScale(Vector(20, 2, 0))
local kIconColor = Color(kIconColors[kAlienTeamType])

local kUpgradeLevelFunc =
{
    GetShellLevel,
    GetSpurLevel,
    GetVeilLevel
}

// first entry is tech id to use if the player has none of the upgrades in the list
local kIndexToUpgrades =
{
    { kTechId.Shell, kTechId.Carapace, kTechId.Regeneration, kTechId.Redemption },
    { kTechId.Spur, kTechId.Celerity, kTechId.Adrenaline },
    { kTechId.Veil, kTechId.Phantom, kTechId.Aura },
}

local function CreateUpgradeIcon()

    local icon = GetGUIManager():CreateGraphicItem()
    icon:SetSize(Vector(kIconSize, kIconSize, 0))
    icon:SetTexture(kIconTexture)
    icon:SetPosition(kIconOffset)
    icon:SetColor(kIconColor)
    
    return icon

end

local function CreateIcons(background)

    local icons = {}

    for type = 1, 3 do

        local category = {}

        local upgradeLevelOne = CreateUpgradeIcon()
        background:AddChild(upgradeLevelOne)        
        table.insert(category, upgradeLevelOne)
        
        upgradeLevelTwo = CreateUpgradeIcon()
        upgradeLevelOne:AddChild(upgradeLevelTwo)
        table.insert(category, upgradeLevelTwo)
        
        upgradeLevelThree = CreateUpgradeIcon()
        upgradeLevelTwo:AddChild(upgradeLevelThree)
        table.insert(category, upgradeLevelThree)
        
        upgradeLevelOne:SetPosition(Vector(0, (type - 1) * kIconSize, 0))
        
        table.insert(icons, category)
    
    end
    
    return icons

end

function GUIUpgradeChamberDisplay:Initialize()

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetPosition(kBackgroundPos)
    self.background:SetColor(kBackgroundColor)
    
    self.upgradeIcons = CreateIcons(self.background)

end

function GUIUpgradeChamberDisplay:Uninitialize()

    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end

end

local function GetTechIdToUse(playerUpgrades, categoryUpgrades)

    for i = 1, #categoryUpgrades do
    
        if table.contains(playerUpgrades, categoryUpgrades[i]) then
            return categoryUpgrades[i], true
        end
    
    end
    
    return categoryUpgrades[1], false

end

function GUIUpgradeChamberDisplay:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    if player then

        local upgrades = player:GetUpgrades()

        for i = 1, 3 do
        
            local category = self.upgradeIcons[i]
            local level = kUpgradeLevelFunc[i](player:GetTeamNumber())
            local techId, upgraded = GetTechIdToUse(upgrades, kIndexToUpgrades[i])    
            local alpha = (upgraded or player:isa("Commander")) and 1 or (0.25 + (1 + math.sin(Shared.GetTime() * 5)) * 0.5) * 0.75
            
            for upgradeLevel = 1, 3 do
            
                if level == 0 then
                
                    self.upgradeIcons[i][upgradeLevel]:SetIsVisible(false)
                    break
                
                else
                
                    local color = Color(kIconColor.r, kIconColor.g, kIconColor.b, alpha)
                    if level < upgradeLevel then
                        
                        color.r = 0
                        color.g = 0
                        color.b = 0
                        color.a = 1
                        
                    end
                
                    self.upgradeIcons[i][upgradeLevel]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId)))
                    self.upgradeIcons[i][upgradeLevel]:SetColor(color)
                    self.upgradeIcons[i][upgradeLevel]:SetIsVisible(true)
                    
                end    
                
            end
            
        end
    
    end

end