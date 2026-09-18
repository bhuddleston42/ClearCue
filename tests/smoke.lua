-- Run from the ClearCue directory with Lua 5.1: lua tests/smoke.lua
-- Simulates lifecycle and rule state; does not replace live combat testing.
local C={}
local frames={}
local methods={}
local function noop() end
local function frame()
    local f={scripts={},shown=true,alpha=1}
    setmetatable(f,{__index=methods}); frames[#frames+1]=f; return f
end
for _,m in ipairs({'SetPoint','ClearAllPoints','SetSize','SetFrameStrata','SetFrameLevel','SetMovable','SetClampedToScreen','RegisterForDrag','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetAllPoints','SetTexCoord','SetDrawEdge','SetDrawBling','SetTextColor','SetVertexColor','SetJustifyH','SetAutoFocus','SetMaxLetters','SetScrollChild','SetHeight','SetParent','StartMoving','StopMovingOrSizing','RegisterEvent'}) do methods[m]=noop end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:CreateTexture() return frame() end
function methods:CreateFontString() return frame() end
function methods:GetCountdownFontString() self.timer=self.timer or frame(); return self.timer end
function methods:SetFont(path,size,outline) self.font=path; self.fontSize=size; return true end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetAlphaFromBoolean(v,a,b) self.alpha=v and a or b end
function methods:SetShown(v) self.shown=not not v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetText(v) self.textValue=v end
function methods:GetText() return self.textValue end
function methods:SetFormattedText(fmt,v) self.textValue=string.format(fmt,v) end
function methods:SetTexture(v) self.texture=v end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetVertexColor(...) self.tint={...} end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetHideCountdownNumbers(v) self.hideNumbers=v end
function methods:SetCooldownFromDurationObject(v) self.duration=v end
function methods:Clear() self.duration=nil end
function methods:GetFrameLevel() return 1 end
function methods:GetCenter() return 500,400 end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:ClearFocus() end
function CreateFrame(kind,name,parent,template)
    local f=frame(); f.text=frame(); f.TitleText=frame()
    if name then _G[name]=f end
    return f
end
UIParent=frame(); UISpecialFrames={}; SlashCmdList={}; tinsert=table.insert
UIDropDownMenu_SetWidth=noop; UIDropDownMenu_SetText=noop; UIDropDownMenu_Initialize=noop
local state={target=true,combat=false,hp=.2,power=.2,cooldown=0,cast=true,blocked=false,spec=64}
local secretCharge={}
function issecretvalue(v) return v==secretCharge end
function GetSpecialization() return 1 end
function GetSpecializationInfo() return state.spec end
function UnitClass() return 'Mage','MAGE' end
function IsPlayerSpell(id) return id==11426 or id==2139 or id==45438 end
IsSpellKnown=IsPlayerSpell
function InCombatLockdown() return state.combat end
function IsMounted() return state.mounted end
function UnitExists(unit) return unit=='player' or (unit=='target' and state.target) end
function UnitCanAttack() return true end
function UnitIsDead() return false end
function UnitCastingInfo() if state.cast then return 'Cast',nil,nil,nil,nil,nil,nil,state.blocked end end
function UnitChannelInfo() end
ActionButton1={action=1}; ActionButton2={action=2}
function GetActionInfo(slot) if slot==1 then return 'spell',116 else return 'macro',1 end end
function GetMacroSpell() return 11426 end
function GetBindingKey(command) return command=='ACTIONBUTTON1' and 'SHIFT-1' or 'CTRL-2' end
C_CurveUtil={CreateCurve=function()
    local c={points={}}
    function c:AddPoint(x,y) self.points[#self.points+1]={x,y} end
    function c:Evaluate(x)
        assert(not issecretvalue(x),'secret values cannot enter curve Evaluate')
        if x<=self.points[1][1] then return self.points[1][2] end
        for i=2,#self.points do local a,b=self.points[i-1],self.points[i]; if x<=b[1] then return a[2]+(b[2]-a[2])*(x-a[1])/(b[1]-a[1]) end end
        return self.points[#self.points][2]
    end
    return c
end}
function UnitHealthPercent(unit,predict,c) return c:Evaluate(state.hp) end
function UnitPowerPercent(unit,power,raw,c) return c:Evaluate(state.power) end
C_Spell={GetSpellTexture=function(id) return id end, GetBaseSpell=function(id) return id end,
    GetSpellInfo=function(id) return {name='Test spell'} end,
    GetSpellCooldownDuration=function() return {EvaluateRemainingDuration=function(_,c) return c:Evaluate(state.cooldown) end} end,
    GetSpellCharges=function() if state.charges then return {currentCharges=state.charges} end end}
C_AssistedCombat={GetNextCastSpell=function() return 116 end}
local themeFont='ThemeFont.ttf'
EllesmereUI={GetFontPath=function(key) return key=='actionBars' and themeFont or 'GlobalFont.ttf' end}
assert(loadfile('Core.lua'))('ClearCue',C)
local eventFrame=frames[#frames-2] -- resolve event owner by handler, independent of helper allocations
for _,f in ipairs(frames) do if f.scripts.OnEvent then eventFrame=f; break end end
eventFrame.scripts.OnEvent(eventFrame,'ADDON_LOADED','ClearCue')
eventFrame.scripts.OnEvent(eventFrame,'PLAYER_LOGIN')
assert(C.root.shown and C.frames[1].shown,'startup recommendation')
assert(C.frames[1].key.font=='ThemeFont.ttf','Ellesmere font inheritance')
assert(C.frames[1].width==C.frames[2].width,'assistant and interrupt have equal prominence')
assert(C.frames[1].width>C.frames[3].width,'defensives are smaller')
assert(C.frames[1].point[3]==C.frames[2].point[3],'assistant and interrupt share top row')
for i,f in ipairs(C.frames) do assert(f.width==f.height,'all tiles square'); if i>=3 then assert(f.point[3]==C.frames[3].point[3],'defensives share one row') end end
assert(C.frames[3].point[3]<C.frames[1].point[3],'defensives below main cues')
themeFont='ChangedTheme.ttf'; eventFrame.scripts.OnUpdate(eventFrame,1.1)
assert(C.frames[1].key.font=='ChangedTheme.ttf','live configured-font change')
C.db.fontSource='global'; C:Layout(); assert(C.frames[1].key.font=='GlobalFont.ttf','explicit global font source')
C.db.fontSource='actionBars'; C:Layout()
assert(C.frames[1].key.textValue=='S-1','main action key lookup')
assert(C.frames[3].key.textValue=='C-2','spell macro key lookup')
local nativeBinding=GetBindingKey
local originalActionInfo,originalMacroSpell=GetActionInfo,GetMacroSpell
ActionButton6={action=6}; MultiBarBottomRightButton10={action=58}
GetActionInfo=function(slot)
    if slot==6 then return 'macro',11426,'spell' end
    if slot==58 then return 'macro',45438,'spell' end
    return originalActionInfo(slot)
end
GetMacroSpell=function(id)
    assert(id~=11426 and id~=45438,'resolved spell IDs must not be used as macro indices')
    return originalMacroSpell(id)
end
GetBindingKey=function(command)
    if command=='ACTIONBUTTON6' then return '6' end
    if command=='MULTIACTIONBAR2BUTTON10' then return '`' end
end
C:ScanKeys()
assert(C.keys[11426]=='6','spell-backed Ice Barrier macro uses bar 1 binding')
assert(C.keys[45438]=='`','spell-backed Ice Block macro uses bar 3 binding')
GetActionInfo=function(slot) if slot==6 then return 'macro',11426,'item' end end
C:ScanKeys(); assert(not C.keys[11426],'item macro is not interpreted as a spell')
GetActionInfo=originalActionInfo; GetMacroSpell=originalMacroSpell; GetBindingKey=nativeBinding
ActionButton6=nil; MultiBarBottomRightButton10=nil
EABButton13={commandName='CUSTOM',GetAttribute=function(_,name) if name=='action' then return 2 end end}
GetBindingKey=function(command) if command=='CLICK EABButton13:LeftButton' then return 'ALT-F' end end
C:ScanKeys(); C:Update(); assert(C.frames[3].key.textValue=='A-F','direct click binding lookup')
GetBindingKey=nativeBinding; EABButton13=nil; C:ScanKeys()
C_Spell.IsSpellInRange=function() return false end
C:Update(); assert(C.frames[1].icon.tint[2]==.25,'out-of-range cue')
C_Spell.IsSpellInRange=function() return nil end
C:Update(); assert(C.frames[1].icon.tint[2]==1,'unknown range is neutral')
C_Spell.IsSpellInRange=function() return secretCharge end
C:Update(); assert(C.frames[1].icon.tint[2]==1,'secret range is not compared')
C_Spell.IsSpellInRange=nil
local native1,native2=ActionButton1,ActionButton2
ActionButton1=nil; ActionButton2=nil
EABButton13={commandName='ACTIONBUTTON2',GetAttribute=function(_,name) if name=='action' then return 2 end end}
C:ScanKeys(); C:Update(); assert(C.frames[3].key.textValue=='C-2','Ellesmere-owned spell macro binding')
EABButton13=nil; ActionButton1=native1; ActionButton2=native2; C:ScanKeys()
assert(C.frames[3].gate.alpha==1,'low-health reminder active')
state.hp=.9; C:Update(); assert(C.frames[3].gate.alpha==0,'healthy reminder hidden')
state.hp=.2; state.cooldown=30; C:Update(); assert(C.frames[3].ready.alpha==0,'cooldown reminder hidden')
state.charges=1; C:Update(); assert(C.frames[3].ready.alpha==1,'available charge remains ready')
state.charges=secretCharge; state.cooldown=0; C:Update()
assert(C.frames[3].ready.alpha==1,'secret charges use available spell duration')
state.cooldown=30; C:Update()
assert(C.frames[3].ready.alpha==0,'secret charges use unavailable spell duration')
state.charges=nil; state.cooldown=0; state.blocked=true; C:Update(); assert(C.frames[2].gate.alpha==0,'uninterruptible hidden')
state.blocked=false; C:Update(); assert(C.frames[2].gate.alpha==1,'interruptible shown')
state.target=false; C:Update(); assert(not C.root.shown,'target condition hides entire row')
C:ToggleEdit(); assert(C.root.shown and C.frames[1].mouse,'preview is visible and movable')
C:ToggleEdit(); assert(not C.root.shown and not C.frames[1].mouse,'exit restores visibility and click-through')
C.db.visibility='always'; C.db.mounted=true; state.mounted=true; C:Update(); assert(not C.root.shown,'mounted hide')
state.mounted=false; C:Update(); assert(C.root.shown,'always visibility')
local rules=C:Rules(); rules[1].resource='3'; rules[1].op='above'; C:BuildCurves()
state.power=.9; C:Update(); assert(C.frames[3].gate.alpha==1,'resource above threshold')
state.power=.1; C:Update(); assert(C.frames[3].gate.alpha==0,'resource below threshold')
state.spec=63; C:BuildCurves(); assert(C:Rules()~=rules,'per-spec rules isolated')
assert(loadfile('Options.lua'))('ClearCue',C); C:OpenOptions(); assert(C.options.shown,'settings builds')
for _,page in ipairs({'Typography','Defensives','Display'}) do C.page=page; C:RebuildOptions(); assert(C.content.shown,'settings page builds: '..page) end
assert(loadfile('Broker.lua'))('ClearCue',C)
C:RegisterBroker(); assert(not C.broker,'optional broker library may be absent')
local registrations=0
LibStub=function(name)
    if name=='LibDataBroker-1.1' then return {NewDataObject=function(_,key,data) registrations=registrations+1; assert(key=='ClearCue'); return data end} end
end
C:RegisterBroker(); C:RegisterBroker(); assert(registrations==1,'broker registers once when library becomes available')
C.options:Hide(); C.broker.OnClick(nil,'LeftButton'); assert(C.options.shown,'broker opens settings')
C.broker.OnClick(nil,'RightButton'); assert(C.edit and C.broker.text:find('Editing'),'broker enables edit mode and updates text')
assert(C.editButton.textValue=='Finish positioning','panel edit state stays synchronized')
C.broker.OnClick(nil,'RightButton'); assert(not C.edit and C.broker.text=='ClearCue','broker exits edit mode')
state.combat=true; C:ScanKeys(); assert(C.keysPending,'combat key scan is deferred')
state.combat=false; eventFrame.scripts.OnEvent(eventFrame,'PLAYER_REGEN_ENABLED'); assert(not C.keysPending,'key scan resumes after combat')
state.spec=64; eventFrame.scripts.OnEvent(eventFrame,'PLAYER_SPECIALIZATION_CHANGED'); assert(C:Rules()==rules,'spec change restores saved rules')
print('PASS: startup, font, health/resource rules, cooldown/charges, interrupts, visibility, edit mode, spec isolation, settings')
