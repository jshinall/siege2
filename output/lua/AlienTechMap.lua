// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienTechMap.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// Formatted alien tech tree.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

kAlienTechMapYStart = 2
local function CheckHasTech(techId)

    local techTree = GetTechTree()
    return techTree ~= nil and techTree:GetHasTech(techId)

end

local function SetShellIcon(icon)

    if CheckHasTech(kTechId.ThreeShells) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.ThreeShells)))
    elseif CheckHasTech(kTechId.TwoShells) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.TwoShells)))
    else
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Shell)))
    end    

end

local function SetVeilIcon(icon)

    if CheckHasTech(kTechId.ThreeVeils) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.ThreeVeils)))
    elseif CheckHasTech(kTechId.TwoVeils) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.TwoVeils)))
    else
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Veil)))
    end
    
end

local function SetSpurIcon(icon)    

    if CheckHasTech(kTechId.ThreeSpurs) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.ThreeSpurs)))
    elseif CheckHasTech(kTechId.TwoSpurs) then
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.TwoSpurs)))
    else
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Spur)))
    end 

end

kAlienTechMap =
{
                    { kTechId.Whip, 5.5, 0.5 },          { kTechId.Shift, 6.5, 0.5 },          { kTechId.Shade, 7.5, 0.5 }, { kTechId.Crag, 8.5, 0.5 }, 
                    
                    { kTechId.Harvester, 4, 1.5 },                           { kTechId.Hive, 7, 1.5 },                         { kTechId.UpgradeGorge, 10, 1.5 }, 
  
                   { kTechId.CragHive, 4, 3 },                               { kTechId.ShadeHive, 7, 3 },                            { kTechId.ShiftHive, 10, 3 },
              { kTechId.Shell, 4, 4, SetShellIcon },                     { kTechId.Veil, 7, 4, SetVeilIcon },                    { kTechId.Spur, 10, 4, SetSpurIcon },
  { kTechId.Carapace, 3.5, 5 },{ kTechId.Regeneration, 4.5, 5 }, { kTechId.Phantom, 6.5, 5 },{ kTechId.Aura, 7.5, 5 },{ kTechId.Celerity, 9.5, 5 },{ kTechId.Adrenaline, 10.5, 5 },
  
  { kTechId.BioMassOne, 3, 7, nil, "1" }, { kTechId.BabblerEgg, 3, 8 },
  
  { kTechId.BioMassTwo, 4, 7, nil, "2" }, {kTechId.Rupture, 4, 8},  { kTechId.Charge, 4, 9 },
  
  { kTechId.BioMassThree, 5, 7, nil, "3" }, {kTechId.BoneWall, 5, 8}, {kTechId.BileBomb, 5, 9}, { kTechId.MetabolizeEnergy, 5, 10 },

  { kTechId.BioMassFour, 6, 7, nil, "4" }, {kTechId.Leap, 6, 8}, {kTechId.Umbra, 6, 9},
  
  { kTechId.BioMassFive, 7, 7, nil, "5" },  {kTechId.WebTech, 7, 8}, {kTechId.BoneShield, 7, 9}, {kTechId.OniPoop, 7, 10}, {kTechId.MetabolizeHealth, 7, 11},
  
  { kTechId.BioMassSix, 8, 7, nil, "6" },  {kTechId.Spores, 8, 8}, 
  
  { kTechId.BioMassSeven, 9, 7, nil, "7" }, {kTechId.Stab, 9, 8}, 
  
  { kTechId.BioMassEight, 10, 7, nil, "8" },  {kTechId.Stomp, 10, 8}, {kTechId.StompUpgrade, 10, 9},
  
  { kTechId.BioMassNine, 11, 7, nil, "9" }, {kTechId.Contamination, 11, 8}, {kTechId.Xenocide, 11, 9}, 
 
 { kTechId.BioMassTen, 12, 7, nil, "10" }, {kTechId.SpiderGorge, 12, 8}, {kTechId.SkulkRupture, 12, 9},
 { kTechId.BioMassEleven, 13, 7, nil, "11" }, {kTechId.PrimalScream, 13, 8},
 { kTechId.BioMassTwelve, 14, 7, nil, "12" }, {kTechId.AcidRocket, 14, 8}, 

}

kAlienLines = 
{
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Crag),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shift),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shade),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Whip),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Harvester, kTechId.Hive),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.UpgradeGorge),
    { 7, 1.5, 7, 2.5 },
    { 4, 2.5, 10, 2.5},
    { 4, 2.5, 4, 3},{ 7, 2.5, 7, 3},{ 10, 2.5, 10, 3},
    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.Shell),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.Veil),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.Spur),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Carapace),GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Regeneration),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Phantom),GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Aura),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Celerity),GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Adrenaline),

}





