local _, C = ...
local fallback = "Fonts\\FRIZQT__.TTF"
C.defaults = { enabled=true, visibility="target", mounted=true, size=72, reminderSize=40, gap=10, fontSource="actionBars",
    x=0, y=-170, inactive=0, font="EllesmereUI", keySize=17, timerSize=18,
    chargeSize=12, labelSize=11, keyFont="inherit", timerFont="inherit",
    chargeFont="inherit", labelFont="inherit", outline="OUTLINE", timers=false,
    charges=false, labels=false, interrupt=true, range=true, keyColor="cyan", specs={} }
C.palette = { cyan={0.25,0.9,1}, gold={1,0.8,0.3}, white={1,1,1}, pink={1,0.5,0.8} }
C.interrupts = { MAGE={2139}, WARRIOR={6552}, PALADIN={96231}, HUNTER={147362,187707},
    ROGUE={1766}, PRIEST={15487}, DEATHKNIGHT={47528}, SHAMAN={57994},
    MONK={116705}, DRUID={106839,78675}, DEMONHUNTER={183752}, EVOKER={351338}, WARLOCK={119910,119914} }
C.defensives = { MAGE={11426,235313,235450,45438}, WARRIOR={34428,184364,12975},
    PALADIN={498,184662,642}, HUNTER={109304,186265}, ROGUE={185311,1966},
    PRIEST={19236,47585}, DEATHKNIGHT={48792,55233}, SHAMAN={108271},
    MONK={115203,122278}, DRUID={22812,108238}, DEMONHUNTER={198589,187827}, EVOKER={363916,374348}, WARLOCK={104773,108416} }
local function public(v) return not issecretvalue or not issecretvalue(v) end
C.public = public
local function known(id) return IsPlayerSpell(id) or IsSpellKnown(id) or IsSpellKnown(id,true) end
function C:Spec()
    local index=GetSpecialization()
    return index and GetSpecializationInfo(index) or 0
end
function C:Rules()
    local spec=self:Spec()
    if not self.db.specs[spec] then
        local rules={}
        local _,class=UnitClass("player")
        for _,id in ipairs(self.defensives[class] or {}) do
            if known(id) and #rules<4 then rules[#rules+1]={spell=id, threshold=40, unit="player", resource="health", op="below", key=""} end
        end
        while #rules<4 do rules[#rules+1]={spell=0,threshold=40,unit="player",resource="health",op="below",key=""} end
        self.db.specs[spec]=rules
    end
    return self.db.specs[spec]
end
function C:Font(role)
    local choice=self.db[role.."Font"]
    if not choice or choice=="inherit" then choice=self.db.font end
    if choice=="EllesmereUI" and EllesmereUI and EllesmereUI.GetFontPath then
        return EllesmereUI.GetFontPath(self.db.fontSource~="global" and self.db.fontSource or nil) or fallback
    end
    if choice=="Arial" then return "Fonts\\ARIALN.TTF" end
    if choice=="Default" or choice=="EllesmereUI" then return fallback end
    local media=LibStub and LibStub("LibSharedMedia-3.0",true)
    return (media and media:Fetch("font",choice,true)) or fallback
end
function C:FontLabel(choice)
    if choice=="inherit" then return "Use ClearCue font" end
    if choice=="EllesmereUI" then
        local key=self.db.fontSource~="global" and self.db.fontSource or nil
        local name=EllesmereUI and EllesmereUI.GetFontName and EllesmereUI.GetFontName(key)
        return "Follow Ellesmere"..(name and (": "..name) or "")
    end
    return choice
end
function C:FontList(overrides)
    local list=overrides and {"inherit","EllesmereUI","Default","Arial"} or {"EllesmereUI","Default","Arial"}
    local media=LibStub and LibStub("LibSharedMedia-3.0",true)
    if media then for _,name in ipairs(media:List("font")) do list[#list+1]=name end end
    return list
end
local function curve(points)
    local c=C_CurveUtil.CreateCurve()
    for _,p in ipairs(points) do c:AddPoint(p[1],p[2]) end
    return c
end
function C:BuildCurves()
    local low=self.db.inactive
    self.readyCurve=curve({{0,1},{0.01,1},{0.02,low},{600,low}})
    self.chargeCurve=curve({{0,low},{1,1},{20,1}})
    self.conditions={}
    for i,r in ipairs(self:Rules()) do
        local t=math.max(.01,math.min(.99,r.threshold/100))
        if r.op=="above" then
            self.conditions[i]=curve({{0,low},{t,low},{t+.00001,1},{1,1}})
        else
            self.conditions[i]=curve({{0,1},{t-.00001,1},{t,low},{1,low}})
        end
    end
end
function C:ScanKeys()
    if InCombatLockdown() then self.keysPending=true; return end
    self.keysPending=false; self.keys={}; self.keyNames={}; self.bindingRows={}
    local function record(slot,command,buttonName)
        if not slot or not public(slot) or not command then return end
        local kind,id,subType=GetActionInfo(slot)
        if not public(kind) or not public(id) or not public(subType) then return end
        -- A spell-backed macro can already report its resolved spell ID.
        -- Only the older macro-index form needs GetMacroSpell.
        if kind=="macro" and subType~="spell" then
            if subType and subType~="macro" then return end
            id=GetMacroSpell(id)
        end
        if (kind~="spell" and kind~="macro") or not public(id) or not id then return end
        local key=GetBindingKey(command)
        if not key and buttonName then key=GetBindingKey("CLICK "..buttonName..":LeftButton") or GetBindingKey("CLICK "..buttonName..":RightButton") end
        self.bindingRows[#self.bindingRows+1]={slot=slot,spell=id,command=command,key=key}
        if not key then return end
        key=key:gsub("SHIFT%-","S-"):gsub("CTRL%-","C-"):gsub("ALT%-","A-")
        if not self.keys[id] then self.keys[id]=key end
        local base=C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(id)
        if public(base) and base and not self.keys[base] then self.keys[base]=key end
        local override=C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(id)
        if public(override) and override and not self.keys[override] then self.keys[override]=key end
        local info=C_Spell.GetSpellInfo(id)
        if info and public(info.name) and info.name then self.keyNames[info.name]=self.keyNames[info.name] or key end
    end
    -- Ellesmere owns separate buttons. Read their action and binding metadata
    -- only outside combat; never change or hook the secure buttons.
    for slot=1,180 do
        local button=_G["EABButton"..slot]
        if button then
            local action=button.GetAttribute and button:GetAttribute("action") or button.action
            local command=button.commandName or (button.GetAttribute and button:GetAttribute("binding"))
            record(action,command,"EABButton"..slot)
        end
    end
    local bars={"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton","MultiBar5Button","MultiBar6Button","MultiBar7Button"}
    local commands={"ACTIONBUTTON","MULTIACTIONBAR1BUTTON","MULTIACTIONBAR2BUTTON","MULTIACTIONBAR3BUTTON","MULTIACTIONBAR4BUTTON","MULTIACTIONBAR5BUTTON","MULTIACTIONBAR6BUTTON","MULTIACTIONBAR7BUTTON"}
    for b,prefix in ipairs(bars) do for i=1,12 do
        local button=_G[prefix..i]
        local slot=button and button.action
        record(slot,commands[b]..i,prefix..i)
    end end
end
function C:BindingReport()
    if InCombatLockdown() then print("ClearCue: run /cc bindings outside combat."); return end
    self:ScanKeys()
    print("ClearCue bindings: "..#self.bindingRows.." spell/macro buttons inspected.")
    local ids={}
    local nextSpell=C_AssistedCombat and C_AssistedCombat.GetNextCastSpell(false)
    if public(nextSpell) and nextSpell then ids[nextSpell]=true end
    for _,r in ipairs(self:Rules()) do if r.spell>0 then ids[r.spell]=true end end
    local _,class=UnitClass("player")
    for _,id in ipairs(self.interrupts[class] or {}) do if known(id) then ids[id]=true end end
    for id in pairs(ids) do
        local info=C_Spell.GetSpellInfo(id)
        local name=info and info.name or tostring(id)
        print(name.." ("..id.."): "..(self.keys[id] or self.keyNames[name] or "NO BINDING FOUND"))
        for _,row in ipairs(self.bindingRows) do
            local candidate=C_Spell.GetSpellInfo(row.spell)
            if row.spell==id or (candidate and candidate.name==name) then
                print("  slot "..row.slot.." spell "..row.spell.." "..row.command.." = "..(row.key or "unbound"))
            end
        end
    end
end
local function widget(parent)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.025,.035,.05,.94); f:SetBackdropBorderColor(.15,.22,.28,1)
    f.gate=CreateFrame("Frame",nil,f); f.gate:SetAllPoints()
    f.ready=CreateFrame("Frame",nil,f.gate); f.ready:SetAllPoints()
    f.background=f.ready:CreateTexture(nil,"BACKGROUND"); f.background:SetAllPoints(); f.background:SetColorTexture(.025,.035,.05,.94)
    f.accent=f.ready:CreateTexture(nil,"OVERLAY"); f.accent:SetPoint("TOPLEFT"); f.accent:SetPoint("TOPRIGHT"); f.accent:SetHeight(2)
    f.icon=f.ready:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("TOPLEFT",3,-3); f.icon:SetPoint("BOTTOMRIGHT",-3,3); f.icon:SetTexCoord(.07,.93,.07,.93)
    f.cooldown=CreateFrame("Cooldown",nil,f.ready,"CooldownFrameTemplate"); f.cooldown:SetAllPoints(f.icon); f.cooldown:SetDrawEdge(false); f.cooldown:SetDrawBling(false)
    f.textLayer=CreateFrame("Frame",nil,f.ready); f.textLayer:SetAllPoints(); f.textLayer:SetFrameLevel(f.cooldown:GetFrameLevel()+2)
    f.key=f.textLayer:CreateFontString(nil,"OVERLAY"); f.key:SetPoint("TOPRIGHT",f.icon,"TOPRIGHT",-2,-2)
    f.count=f.textLayer:CreateFontString(nil,"OVERLAY"); f.count:SetPoint("BOTTOMRIGHT",f.icon,"BOTTOMRIGHT",-2,2)
    f.label=f.textLayer:CreateFontString(nil,"OVERLAY"); f.label:SetPoint("TOP",f,"BOTTOM",0,-4)
    return f
end
function C:Layout()
    local d=self.db
    self.root:ClearAllPoints(); self.root:SetPoint("CENTER",UIParent,"CENTER",d.x,d.y)
    local small=d.reminderSize
    local topWidth=d.size*2+d.gap
    local bottomWidth=small*4+d.gap*3
    local width=math.max(topWidth,bottomWidth)
    local labelGap=d.labels and d.labelSize+8 or 4
    local start=d.size+labelGap+d.gap
    self.root:SetSize(width,start+small+labelGap)
    for i,f in ipairs(self.frames) do
        local size=i<=2 and d.size or small
        f:ClearAllPoints()
        if i<=2 then f:SetPoint("TOPLEFT",(width-topWidth)/2+(i-1)*(d.size+d.gap),0)
        else
            f:SetPoint("TOPLEFT",(width-bottomWidth)/2+(i-3)*(small+d.gap),-start)
        end
        f:SetSize(size,size)
        if i==1 then f.accent:SetColorTexture(.25,.9,1,1)
        elseif i==2 then f.accent:SetColorTexture(1,.65,.2,1)
        else f.accent:SetColorTexture(.18,.28,.34,1) end
        for _,role in ipairs({"key","count","label"}) do
            local r=role=="count" and "charge" or role
            if not f[role]:SetFont(self:Font(r),d[r.."Size"],d.outline) then f[role]:SetFont(fallback,d[r.."Size"],d.outline) end
        end
        f.key:SetTextColor(unpack(self.palette[d.keyColor] or self.palette.cyan))
        f.label:SetTextColor(.7,.76,.83)
        f.cooldown:SetHideCountdownNumbers(not d.timers)
        local text=f.cooldown:GetCountdownFontString()
        if text then text:SetFont(self:Font("timer"),d.timerSize,d.outline) end
        f:EnableMouse(self.edit or false)
        f:SetMovable(false)
    end
end
function C:Refresh()
    if not self.root then return end
    self:BuildCurves(); self:Layout(); self:ScanKeys(); self:Update()
end
function C:Render(f,id,key,label,reminder,rangeUnit)
    f:SetAlpha(1); f.gate:SetAlpha(1); f.ready:SetAlpha(1)
    f:SetBackdropColor(0,0,0,0); f:SetBackdropBorderColor(0,0,0,0)
    if not id or not public(id) or id==0 then f:Hide(); return false end
    f:Show(); f.icon:SetTexture(C_Spell.GetSpellTexture(id)); f.icon:SetVertexColor(1,1,1)
    if self.db.range and rangeUnit and C_Spell.IsSpellInRange then
        local inRange=C_Spell.IsSpellInRange(id,rangeUnit)
        if public(inRange) and inRange==false then f.icon:SetVertexColor(1,.25,.25) end
    end
    local base=C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(id) or id
    local info=C_Spell.GetSpellInfo(id)
    local namedKey=info and public(info.name) and self.keyNames and self.keyNames[info.name]
    f.key:SetText((key and key~="" and key) or self.keys[id] or (public(base) and self.keys[base]) or namedKey or "")
    f.label:SetText(self.db.labels and label or "")
    f.count:SetText("")
    local duration=C_Spell.GetSpellCooldownDuration(id,reminder or false)
    if duration then f.cooldown:SetCooldownFromDurationObject(duration) else f.cooldown:Clear() end
    local charges=C_Spell.GetSpellCharges(id)
    if charges then
        if self.db.charges then f.count:SetFormattedText("%d",charges.currentCharges) end
        if reminder then
            if public(charges.currentCharges) then
                f.ready:SetAlpha(self.chargeCurve:Evaluate(charges.currentCharges))
            elseif duration then
                -- Never feed a secret charge count to LuaCurveObject:Evaluate.
                -- Use the engine's spell cooldown (not the recharge duration),
                -- which describes availability rather than missing charges.
                f.ready:SetAlpha(duration:EvaluateRemainingDuration(self.readyCurve))
            end
        end
    elseif reminder and duration then
        f.ready:SetAlpha(duration:EvaluateRemainingDuration(self.readyCurve))
    end
    return true
end
function C:Preview()
    for i,f in ipairs(self.frames) do
        f:Show(); f:SetAlpha(1); f.gate:SetAlpha(1); f.ready:SetAlpha(1)
        f:SetBackdropColor(.025,.035,.05,.94); f:SetBackdropBorderColor(.2,.65,.8,1)
        f.icon:SetTexture(i==1 and 136096 or i==2 and 135856 or 135940)
        f.icon:SetVertexColor(1,1,1); f.cooldown:Clear(); f.count:SetText(self.db.charges and "2" or "")
        f.key:SetText(i==1 and "S-1" or i==2 and "F" or "C-"..(i-2))
        f.label:SetText(self.db.labels and (i==1 and "Next spell" or i==2 and "Kick" or "Def "..(i-2)) or "")
    end
end
function C:Update()
    if self.edit then self.root:Show(); self:Preview(); return end
    local d=self.db
    local show=d.enabled and not (d.mounted and IsMounted())
    if d.visibility=="target" then show=show and UnitExists("target") and UnitCanAttack("player","target") and not UnitIsDead("target")
    elseif d.visibility=="combat" then show=show and InCombatLockdown() end
    self.root:SetShown(show)
    if not show then return end
    local id=C_AssistedCombat and C_AssistedCombat.GetNextCastSpell(false)
    self:Render(self.frames[1],id,nil,"Next spell",false,"target")
    local _,class=UnitClass("player")
    local interrupt
    for _,spell in ipairs(self.interrupts[class] or {}) do if known(spell) then interrupt=spell; break end end
    local f=self.frames[2]
    if d.interrupt and interrupt and UnitExists("target") and UnitCanAttack("player","target") then
        local name,_,_,_,_,_,_,blocked=UnitCastingInfo("target")
        if not name then name,_,_,_,_,_,blocked=UnitChannelInfo("target") end
        if name and self:Render(f,interrupt,nil,"Interrupt",true,"target") then
            if not public(blocked) or blocked~=nil then f.gate:SetAlphaFromBoolean(blocked,d.inactive,1) end
        else f:Hide() end
    else f:Hide() end
    for i,r in ipairs(self:Rules()) do
        f=self.frames[i+2]
        if known(r.spell) and UnitExists(r.unit) and self:Render(f,r.spell,r.key,"Defensive",true,r.unit) then
            if r.resource=="health" then f.gate:SetAlpha(UnitHealthPercent(r.unit,false,self.conditions[i]))
            else f.gate:SetAlpha(UnitPowerPercent(r.unit,tonumber(r.resource),false,self.conditions[i])) end
        else f:Hide() end
    end
end
function C:ToggleEdit()
    self.edit=not self.edit; self:Layout(); self:Update()
    if self.UpdateOptionsStatus then self:UpdateOptionsStatus() end
    if self.UpdateBroker then self:UpdateBroker() end
    print("ClearCue: edit mode "..(self.edit and "on — drag any icon; /cc edit to finish." or "off."))
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~="ClearCue" then return end
        ClearCueDB=ClearCueDB or {}
        C.db=ClearCueDB
        for k,v in pairs(C.defaults) do if C.db[k]==nil then C.db[k]=type(v)=="table" and {} or v end end
        if not C.db.compactLayout then C.db.size=math.max(C.db.size,72); C.db.compactLayout=true end
        events:RegisterEvent("PLAYER_LOGIN")
    elseif event=="PLAYER_LOGIN" then
        C.root=CreateFrame("Frame","ClearCueDisplay",UIParent); C.root:SetMovable(true); C.root:SetClampedToScreen(true)
        C.frames={}; C.keys={}
        for i=1,6 do
            local f=widget(C.root); C.frames[i]=f; f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart",function() if C.edit then C.dragging=true; C.root:StartMoving() end end)
            f:SetScript("OnDragStop",function()
                C.dragging=false; C.root:StopMovingOrSizing(); local x,y=C.root:GetCenter(); local px,py=UIParent:GetCenter()
                C.db.x=x-px; C.db.y=y-py; C:Layout()
            end)
        end
        C:Refresh()
        if C.RegisterBroker then C:RegisterBroker() end
        for _,e in ipairs({"UPDATE_BINDINGS","ACTIONBAR_SLOT_CHANGED","ACTIONBAR_PAGE_CHANGED","PLAYER_SPECIALIZATION_CHANGED","PLAYER_REGEN_ENABLED","SPELLS_CHANGED"}) do events:RegisterEvent(e) end
        local elapsed,fontElapsed,keyElapsed=0,0,0
        events:SetScript("OnUpdate",function(_,dt)
            keyElapsed=keyElapsed+dt
            if keyElapsed>=2 and not InCombatLockdown() then keyElapsed=0; C:ScanKeys() end
            fontElapsed=fontElapsed+dt
            if fontElapsed>=1 and not C.dragging then
                fontElapsed=0
                local signature=C:Font("key")..C:Font("timer")..C:Font("charge")..C:Font("label")
                if signature~=C.fontSignature then C.fontSignature=signature; C:Layout() end
            end
            elapsed=elapsed+dt; if elapsed<.1 then return end; elapsed=0
            C:Update()
        end)
        print("ClearCue alpha loaded. /cc settings, /cc edit preview.")
    elseif C.root then
        if event=="PLAYER_SPECIALIZATION_CHANGED" or event=="SPELLS_CHANGED" then
            C:BuildCurves()
            if C.options and C.options:IsShown() then C:RebuildOptions() end
        end
        C:ScanKeys()
    end
end)
SLASH_CLEARCUE1="/cc"
SLASH_CLEARCUE2="/clearcue"
SlashCmdList.CLEARCUE=function(msg)
    if not C.root then return end
    if msg=="edit" then C:ToggleEdit()
    elseif msg=="refresh" then C:Refresh()
    elseif msg=="bindings" then C:BindingReport()
    else C:OpenOptions() end
end
