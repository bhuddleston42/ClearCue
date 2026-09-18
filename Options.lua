local _,C=...
local names={target="Hostile target",combat="In combat",always="Always",actionBars="Action Bars",
    cooldownManager="Cooldown Manager",unitFrames="Unit Frames",global="Global font",
    OUTLINE="Outline",THICKOUTLINE="Thick outline",[""]="None",cyan="Cyan",gold="Gold",white="White",pink="Pink",
    player="Player",pet="Pet",mouseover="Mouseover",health="Health",below="Below",above="Above",
    ["0"]="Mana",["1"]="Rage",["2"]="Focus",["3"]="Energy",["6"]="Runic Power",["9"]="Holy Power",
    ["11"]="Maelstrom",["12"]="Chi",["17"]="Fury",["19"]="Essence"}
local function caption(parent,text,x,y)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f:SetPoint("TOPLEFT",x,y); f:SetFont(C:Font("label"),12,""); f:SetTextColor(.8,.85,.9); f:SetText(text); return f
end
function C:UpdateOptionsStatus()
    if self.editButton then self.editButton:SetText(self.edit and "Finish positioning" or "Preview & position") end
    if self.statusText then self.statusText:SetText(self.edit and "EDIT MODE  •  Drag the icons to position them" or "Changes save automatically  •  Escape closes settings") end
end
function C:OpenOptions()
    if self.options then self.options:Show(); self:UpdateOptionsStatus(); return end
    local f=CreateFrame("Frame","ClearCueOptions",UIParent,"BackdropTemplate")
    self.options=f; f:SetSize(760,690); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.035,.045,.06,.98); f:SetBackdropBorderColor(.16,.3,.38,1)
    local title=caption(f,"ClearCue",24,-20); title:SetFont(C:Font("label"),23,"OUTLINE"); title:SetTextColor(.25,.9,1)
    caption(f,"Make the next action clear.",24,-51)
    f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-6,-6)
    close:SetScript("OnClick",function() f:Hide() end)
    local edit=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); edit:SetSize(190,28); edit:SetPoint("TOPRIGHT",-48,-25)
    edit:SetScript("OnClick",function() C:ToggleEdit() end); self.editButton=edit
    self.statusText=caption(f,"",24,-656)
    self.tabButtons={}
    for i,name in ipairs({"Display","Typography","Defensives"}) do
        local page=name
        local tab=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); tab:SetSize(220,30); tab:SetPoint("TOPLEFT",24+(i-1)*236,-83)
        tab:SetText(name); tab:SetScript("OnClick",function() C.page=page; C:RebuildOptions(); C.scroll:SetVerticalScroll(0) end)
        self.tabButtons[page]=tab
    end
    tinsert(UISpecialFrames,"ClearCueOptions")
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",12,-128); scroll:SetPoint("BOTTOMRIGHT",-30,48)
    self.scroll=scroll
    self:RebuildOptions()
end
function C:RebuildOptions()
    self.page=self.page or "Display"
    self:UpdateOptionsStatus()
    for name,tab in pairs(self.tabButtons or {}) do tab:SetText(name==self.page and ("|cff40e6ff"..name.."|r") or name) end
    if self.content then self.content:Hide(); self.content:SetParent(nil) end
    local p=CreateFrame("Frame",nil,self.scroll); p:SetSize(700,1500)
    self.content=p; self.scroll:SetScrollChild(p)
    local y=-8
    local function heading(text)
        local t=caption(p,text,12,y); t:SetTextColor(.25,.9,1); y=y-32
    end
    local function check(text,key)
        local b=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
        b:SetPoint("TOPLEFT",10,y); caption(p,text,44,y-8); b:SetChecked(C.db[key])
        b:SetScript("OnClick",function(s) C.db[key]=s:GetChecked() and true or false; C:Refresh() end)
        y=y-30
    end
    local function dropdown(text,values,value,apply,x,width,row)
        x=x or 12; width=width or 185; row=row or y
        caption(p,text,x,row)
        local d=CreateFrame("Frame",nil,p,"UIDropDownMenuTemplate")
        local function label(v) return names[tostring(v)] or C:FontLabel(tostring(v)) end
        d:SetPoint("TOPLEFT",x-16,row-17); UIDropDownMenu_SetWidth(d,width); UIDropDownMenu_SetText(d,label(value))
        UIDropDownMenu_Initialize(d,function()
            for _,v in ipairs(values) do
                local choice=v; local info=UIDropDownMenu_CreateInfo()
                info.text=label(choice); info.checked=choice==value
                info.func=function() value=choice; UIDropDownMenu_SetText(d,label(choice)); apply(choice); C:Refresh() end
                UIDropDownMenu_AddButton(info)
            end
        end)
        return d
    end
    local function number(text,value,min,max,apply,x,row,width)
        x=x or 12; row=row or y
        caption(p,text,x,row)
        local e=CreateFrame("EditBox",nil,p,"InputBoxTemplate"); e:SetSize(width or 65,24)
        e:SetPoint("TOPLEFT",x+5,row-22); e:SetAutoFocus(false); e:SetText(tostring(value))
        local function save(s)
            local n=tonumber(s:GetText())
            if n then n=math.max(min,math.min(max,n)); value=n; apply(n); s:SetText(tostring(n)); C:Refresh() else s:SetText(tostring(value)) end
        end
        e:SetScript("OnEnterPressed",function(s) save(s); s:ClearFocus() end)
        e:SetScript("OnEditFocusLost",save); e:SetScript("OnEscapePressed",function(s) s:SetText(tostring(value)); s:ClearFocus() end)
    end
    if self.page=="Display" then
    heading("Visibility")
    check("Enabled", "enabled")
    check("Hide while mounted", "mounted")
    check("Interrupt reminder", "interrupt")
    check("Tint out-of-range spells red", "range")
    dropdown("Show display",{"target","combat","always"},self.db.visibility,function(v) C.db.visibility=v end)
    number("Inactive opacity (%)",self.db.inactive*100,0,100,function(v) C.db.inactive=v/100 end,350)
    y=y-65
    caption(p,"0% hides inactive defensives. Interrupts appear only during enemy casts.",12,y); y=y-36
    heading("Size & spacing")
    number("Assistant / interrupt size",self.db.size,48,110,function(v) C.db.size=v end)
    y=y-65
    number("Reminder size",self.db.reminderSize,28,64,function(v) C.db.reminderSize=v end)
    number("Reminder spacing",self.db.gap,4,24,function(v) C.db.gap=v end,240)
    y=y-65
    heading("Details")
    check("Show cooldown numbers", "timers")
    check("Show charges", "charges")
    check("Show icon labels", "labels")
    elseif self.page=="Typography" then
    heading("Theme font")
    caption(p,"Follow your Ellesmere selection, or choose a font just for ClearCue.",12,y); y=y-30
    dropdown("Ellesmere font source",{"actionBars","cooldownManager","unitFrames","global"},self.db.fontSource,function(v) C.db.fontSource=v end,12,255)
    y=y-65
    dropdown("ClearCue font",self:FontList(),self.db.font,function(v) C.db.font=v end,12,290)
    dropdown("Outline",{"OUTLINE","THICKOUTLINE",""},self.db.outline,function(v) C.db.outline=v end,370,180)
    y=y-65
    heading("Individual text styles")
    local roleNames={key="Keybind",timer="Cooldown",charge="Charge count",label="Icon label"}
    for _,role in ipairs({"key","timer","charge","label"}) do
        local r=role
        dropdown(roleNames[r],self:FontList(true),self.db[r.."Font"],function(v) C.db[r.."Font"]=v end,12,290)
        number("Size (px)",self.db[r.."Size"],8,40,function(v) C.db[r.."Size"]=v end,370)
        y=y-62
    end
    dropdown("Keybind color",{"cyan","gold","white","pink"},self.db.keyColor,function(v) C.db.keyColor=v end)
    y=y-62
    else
    local _,specName=GetSpecializationInfo(GetSpecialization() or 1)
    heading("Defensive reminders — "..(specName or "current specialization"))
    caption(p,"Shown when the rule matches and the spell is ready. Spell ID 0 disables a slot.",12,y); y=y-32
    for i,r in ipairs(self:Rules()) do
        local rule=r
        local info=r.spell>0 and C_Spell.GetSpellInfo(r.spell)
        local title=caption(p,"",12,y); title:SetTextColor(.25,.9,1)
        local function updateTitle()
            local spell=rule.spell>0 and C_Spell.GetSpellInfo(rule.spell)
            title:SetText("Slot "..i.."  •  "..(spell and spell.name or "Not configured"))
        end
        updateTitle(); y=y-28
        number("Spell ID",r.spell,0,2000000,function(v) rule.spell=math.floor(v); updateTitle() end,12,y,95)
        dropdown("Unit",{"player","pet","mouseover"},r.unit,function(v) rule.unit=v end,145,125)
        dropdown("Resource",{"health","0","1","2","3","6","9","11","12","17","19"},r.resource,function(v) rule.resource=v end,300,110)
        dropdown("Condition",{"below","above"},r.op,function(v) rule.op=v end,440,90)
        number("Percent",r.threshold,1,99,function(v) rule.threshold=v end,560,y)
        y=y-58
        caption(p,"Keybind override (optional)",12,y)
        local e=CreateFrame("EditBox",nil,p,"InputBoxTemplate"); e:SetSize(100,24); e:SetPoint("TOPLEFT",230,y+3)
        e:SetAutoFocus(false); e:SetMaxLetters(14); e:SetText(r.key or "")
        e:SetScript("OnEnterPressed",function(s) rule.key=s:GetText(); s:ClearFocus(); C:Refresh() end)
        e:SetScript("OnEditFocusLost",function(s) rule.key=s:GetText(); C:Refresh() end)
        caption(p,"Leave blank to use your action-bar binding.",355,y)
        y=y-48
    end
    end
    p:SetHeight(-y+45)
end
