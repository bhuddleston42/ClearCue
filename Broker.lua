local _,C=...

function C:UpdateBroker()
    if self.broker then self.broker.text=self.edit and "ClearCue • Editing" or "ClearCue" end
end

function C:RegisterBroker()
    if self.broker or not self.root then return end
    local library=LibStub and LibStub("LibDataBroker-1.1",true)
    if not library then return end
    self.broker=library:NewDataObject("ClearCue",{
        type="launcher", label="ClearCue", text="ClearCue",
        icon="Interface\\Icons\\UI_Spellbook_OneButton",
        OnClick=function(_,button)
            if button=="RightButton" then C:ToggleEdit()
            elseif button=="LeftButton" then C:OpenOptions() end
        end,
        OnTooltipShow=function(tip)
            tip:AddLine("ClearCue",.25,.9,1)
            tip:AddLine("Left-click: Open settings",1,1,1)
            tip:AddLine("Right-click: "..(C.edit and "Finish positioning" or "Preview and position icons"),1,1,1)
            tip:AddLine(C.edit and "Edit mode is ON" or "Edit mode is OFF",.7,.76,.83)
        end,
    })
    self:UpdateBroker()
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function() C:RegisterBroker() end)
