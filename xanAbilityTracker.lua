--xanAbilityTracker by Xruptor

local f = CreateFrame("frame","xanAbilityTracker",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then  return self[event](self, event, ...) end end)

local debugf = tekDebug and tekDebug:GetFrame("xanAbilityTracker")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end


----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not XAT_DB then XAT_DB = {} end
	
	self:DrawGUI()
	--self:RestoreLayout("xanAbilityTracker")
	self:LoadClass()
	
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:SetScript('OnUpdate', self.DoUpdate)
	
	local ver = GetAddOnMetadata("xanAbilityTracker","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] Loaded", "xanAbilityTracker", ver or "1.0"))

	self:PLAYER_TALENT_UPDATE() --call to set the addon on/off
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function f:DoUpdate()
	if not self.buttons then return end
	if not self.isEnabled then return end
	
	if not InCombatLockdown() then
		for id = 1, #self.buttons do
			self.buttons[id]:SetAlpha(0.1) --hide it so that it doesn't annoy us when not in combat
		end
		return
	end
	
	for id = 1, #self.buttons do
		local data = self.buttons[id].data
		if data then
			local name = GetSpellInfo(data.spellID)
			local start, duration = GetSpellCooldown(data.spellID)
			local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(data.spellID)
			
			if start > 0 then
				self.buttons[id]:SetAlpha(0.3) --show as not ready
				self.buttons[id].Cooldown:SetCooldown(start, duration)
				if data.customGlow then ActionButton_HideOverlayGlow(self.buttons[id]) end
			else
				if not IsUsableSpell(data.spellID) then
					self.buttons[id]:SetAlpha(0.3) --show as not ready
					if data.customGlow then ActionButton_HideOverlayGlow(self.buttons[id]) end
				else
					self.buttons[id]:SetAlpha(1) --show ready
					if data.customGlow then ActionButton_ShowOverlayGlow(self.buttons[id]) end
				end
			end
			
			--some spells don't have overlays so we only want to do the ones that do
			if not data.customGlow then
				if IsSpellOverlayed(data.spellID) then
					ActionButton_ShowOverlayGlow(self.buttons[id])
				else
					ActionButton_HideOverlayGlow(self.buttons[id])
				end
			end

		end
	end
	
end

function f:DrawGUI()
					
	local scale = self:GetScale()
	local border = 2
	local defHeight = 40
	local defWidth = 40
	
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", 0, -293)
	f:SetFrameStrata( "MEDIUM" )
	f:SetClampedToScreen( true )
	f:SetHeight(scale * (border + defHeight))
	f:SetWidth(scale * (border + defWidth))
	--f:EnableMouse(false)
	--f:SetMovable(true)

	local buttons = {}
	
	for id = 1, 5 do

		local buttonName = "XAT_Button"..id

		buttons[id] = CreateFrame("Button", buttonName, f)
		local btn = buttons[id]
		btn.index = id

		btn:SetHeight(scale * defHeight)
		btn:SetWidth(scale * defWidth)

		btn.Shine = CreateFrame("Frame", buttonName.."Shine", btn, "AutoCastShineTemplate")
		btn.Shine:Show()
		btn.Shine:SetAllPoints()

		btn.Icon = btn.Shine:CreateTexture(nil, "OVERLAY")
		btn.Icon:SetSize(btn:GetWidth(), btn:GetHeight())
		btn.Icon:ClearAllPoints()
		btn.Icon:SetPoint("RIGHT", btn.Shine, "RIGHT", 0, 0)
		btn.Icon:Show()

		btn.Keybinding = btn:CreateFontString(buttonName.."Keybind", "OVERLAY")
		btn.Keybinding:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
		btn.Keybinding:ClearAllPoints()
		btn.Keybinding:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
		btn.Keybinding:SetSize(btn:GetWidth(), btn:GetHeight() / 2 )
		btn.Keybinding:SetJustifyH("RIGHT")
		btn.Keybinding:SetJustifyV("TOP")
		btn.Keybinding:SetTextColor(1, 1, 1, 1)
		btn.Keybinding:SetText("?")

		btn.Cooldown = btn.Cooldown or CreateFrame("Cooldown", buttonName.."Cooldown", btn, "CooldownFrameTemplate")
		btn.Cooldown:ClearAllPoints()
		btn.Cooldown:SetAllPoints(btn)

		btn.Backdrop = CreateFrame("Frame", buttonName.."Backdrop", btn)
		btn.Backdrop:ClearAllPoints()
		btn.Backdrop:SetWidth( btn:GetWidth() + 2 )
		btn.Backdrop:SetHeight( btn:GetHeight() + 2 )

		local framelevel = btn:GetFrameLevel()
		if framelevel > 0 then
			btn.Backdrop:SetFrameStrata("MEDIUM")
			btn.Backdrop:SetFrameLevel(framelevel - 1)
		else
			btn.Backdrop:SetFrameStrata("LOW")
		end

		btn.Backdrop:SetBackdrop( {
			bgFile = nil,
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			tile = false,
			tileSize = 0,
			edgeSize = 1,
			insets = { left = -1, right = -1, top = -1, bottom = -1 }
		} )
		btn.Backdrop:SetBackdropBorderColor(1, 1, 1, 1)
		btn.Backdrop:Show()

		local spacing = 5

		if id == 1 then
			btn:ClearAllPoints()
			btn:SetPoint("LEFT", f, "LEFT")
		else
			btn:ClearAllPoints()
			btn:SetPoint("LEFT", buttons[id-1], "RIGHT", spacing, 0)
			--adjust the main frame
			f:SetWidth(f:GetWidth() + (spacing + btn:GetWidth()) )
		end
		
	end

	self.buttons = buttons
end

local MONK = {
	[1] = {spellID = 261947, customGlow = false }, --Fist of the White Tiger
	[2] = {spellID = 100784, customGlow = false }, --Blackout Kick
	[3] = {spellID = 107428, customGlow = false }, --Rising Sun Kick
	[4] = {spellID = 113656, customGlow = false }, --Fists of Fury
	[5] = {spellID = 152175, customGlow = true }, --Whirling Dragon Punch
}

function f:LoadClass()
	if not self.buttons then end
	
	for id = 1, #self.buttons do
		local data = MONK[id]
		local icon = GetSpellTexture(data.spellID)
		if icon then
			self.buttons[id].Icon:SetTexture(icon)
			self.buttons[id]:SetAlpha(0.1)
			self.buttons[id].data = data
		end
	end

end

function f:PLAYER_TALENT_UPDATE()
	if GetSpecializationInfo(GetSpecialization()) == 269 then
		self.isEnabled = true
		
		if self.buttons then
			for id = 1, #self.buttons do
				self.buttons[id]:SetAlpha(0.1) --show them
			end
		end
		
	else
		self.isEnabled = false
		
		if self.buttons then
			for id = 1, #self.buttons do
				self.buttons[id]:SetAlpha(0) --hide them
			end
		end
		
	end
end

function f:SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XAT_DB then XAT_DB = {} end
	
	local opt = XAT_DB[frame] or nil

	if not opt then
		XAT_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XAT_DB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function f:RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XAT_DB then XAT_DB = {} end

	local opt = XAT_DB[frame] or nil

	if not opt then
		XAT_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XAT_DB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
