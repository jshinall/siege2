
local orig_PrototypeLab_GetItemList = PrototypeLab.GetItemList
function PrototypeLab:GetItemList(forPlayer)
    if forPlayer:isa("Exo") then
        return { kTechId.Exosuit }
    end
    return { kTechId.Jetpack, kTechId.Exosuit }
    --return orig_PrototypeLab_GetItemList(self, forPlayer)
end


local orig_PrototypeLab_GetTechButtons = PrototypeLab.GetTechButtons
function PrototypeLab:GetTechButtons(techId)
    return { kTechId.JetpackTech, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.ExosuitTech, kTechId.None, } 
end