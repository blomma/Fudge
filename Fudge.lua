Fudge = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0")
local Fudge, self = Fudge, Fudge

local localeTables = {}
function Fudge:L(name, defaultTable)
	if not localeTables[name] then
		localeTables[name] = setmetatable(defaultTable or {}, {__index = function(self, key)
			self[key] = key
			return key
		end})
	end
	return localeTables[name]
end

local localization = (GetLocale() == "koKR") and {
	["In Range"] = "원거리",
	["Out of Range"] = "거리 벗어남",
} or (GetLocale() == "deDE") and {
	["In Range"] = "Fernkampf",
	["Out of Range"] = "Ausser Reichweite",
} or (GetLocale() == "frFR") and {
	["In Range"] = "A port\195\169e",
	["Out of Range"] = "Hors de port\195\169e",
} or (GetLocale() == "esES") and {
	["In Range"] = "Dentro del Alcance",
	["Out of Range"] = "Fuera de Alcance",
} or (GetLocale() == "zhTW") and {
	["In Range"] = "射程內",
	["Out of Range"] = "射程外",
} or (GetLocale() == "zhCN") and {
	["In Range"] = "射程内",
	["Out of Range"] = "射程外",
} or {}

local L = Fudge:L("Fudge", localization)

local locked = true
local index, spell

local defaults = {
	width		= 135,
	height		= 35,
	textSize	= 12,
	pos			= {},
	spell		= false,
	text		= true,
	colors		= {
		range = {0,0,1,0.7},
		oorange = {1,0,0,0.7}
	}
}

local options = {
	type = "group",
	args = {
		spell = {
			name = "spell",
			desc = "Set spell to range check.",
			type = "text",
			usage = "<name>",
			get = function() return Fudge.db.profile.spell end,
			set = function( v ) 
				Fudge.db.profile.spell = v 
				spell = Fudge.db.profile.spell
			end,
		},
		lock = {
			name = "lock",
			desc = "Lock/Unlock the button.",
			type = "toggle",
			get = function() return locked end,
			set = function( v ) locked = v end,
			map = {[false] = "Unlocked", [true] = "Locked"},
		},
		width = {
			name = "width", 
			desc = "Set the width of the button.",
			type = 'range', 
			min = 10, 
			max = 5000, 
			step = 1,
			get = function() return Fudge.db.profile.width end,
			set = function( v )
				Fudge.db.profile.width = v
				Fudge:Layout()
			end
		},
		height = {
			name = "height", 
			desc = "Set the height of the button.",
			type = 'range', 
			min = 5, 
			max = 50, 
			step = 1,
			get = function() return Fudge.db.profile.height end,
			set = function( v )
				Fudge.db.profile.height = v
				Fudge:Layout()
			end
		},
		font = {
			name = "font", 
			desc = "Set the font size.",
			type = 'group',
			args = {
				text = {
					name = "text", 
					desc = "Set the font size on the button.",
					type = 'range', 
					min = 6, 
					max = 32, 
					step = 1,
					get = function() return Fudge.db.profile.textSize end,
					set = function( v )
						Fudge.db.profile.textSize = v
						Fudge:Layout()
					end
				}
			}
		},
		text = {
			name = "text", 
			desc = "Toggle displaying text on the button.",
			type = 'toggle',
			get = function() return Fudge.db.profile.text end,
			set = function( v )
				Fudge.db.profile.text = v
				Fudge.frame.Range:SetText("")
			end,
			map = {[false] = "Off", [true] = "On"},
		},
		color = {
			name = "color", 
			desc = "Set the color of the different button states.",
			type = 'group', 
			order = 4,
			args = {
				range = {
					name = "range", 
					desc = "Sets the color of the in range state.",
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = Fudge.db.profile.colors.range
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						Fudge.db.profile.colors.range = {r,g,b,a}
						Fudge:Layout()
					end
				},
				oorange = {
					name = "oorange", 
					desc = "Sets the color of the out of range state.",
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = Fudge.db.profile.colors.oorange
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						Fudge.db.profile.colors.oorange = {r,g,b,a}
						Fudge:Layout()
					end
				}
			}
		}
	}
}

Fudge:RegisterDB("FudgeDB")
Fudge:RegisterDefaults('profile', defaults)
Fudge:RegisterChatCommand( {"/fudge"}, options )

function Fudge:OnEnable()
	spell = self.db.profile.spell
	self:CreateFrameWork()

	self:RegisterEvent("UNIT_FACTION", "TargetChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
end

function Fudge:CreateFrameWork()
	local frame = CreateFrame("Frame", "FudgeFrame", UIParent)
	self.frame = frame
	frame:Hide()
	
	local pos = self.db.profile.pos

	if pos.x and pos.y then
		local uis = UIParent:GetScale()
		local s = frame:GetEffectiveScale()
		frame:SetPoint("CENTER", pos.x*uis/s, pos.y*uis/s)
	else
		frame:SetPoint("CENTER", 0, 50)
	end

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() if not locked then this:StartMoving() end end)
	frame:SetScript("OnDragStop", function(this)
		this:StopMovingOrSizing()
		local pos = self.db.profile.pos
		local x, y = this:GetCenter()
		local s = this:GetEffectiveScale()
		local uis = UIParent:GetScale()
		this:ClearAllPoints()
		x = x*s - GetScreenWidth()*uis/2
		y = y*s - GetScreenHeight()*uis/2
		pos.x, pos.y = x/uis, y/uis
		this:SetPoint("CENTER", UIParent, "CENTER", x/s, y/s)
	end)

	frame:SetClampedToScreen(true)

	frame.Range = frame:CreateFontString("FudgeFontStringText", "OVERLAY")

	self:Layout()
end

function Fudge:Layout()
	local db = self.db.profile

	local frame = self.frame
	frame:SetWidth( db.width )
	frame:SetHeight( db.height )

	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	
	frame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	frame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)

	local gameFont, _, _ = GameFontHighlightSmall:GetFont()
	
	frame.Range:SetJustifyH("CENTER")
	frame.Range:SetFont( gameFont, db.textSize )
	frame.Range:ClearAllPoints()
	frame.Range:SetPoint("CENTER", frame, "CENTER",0,0)
	frame.Range:SetTextColor( 1,1,1 )
end

function Fudge:TargetChanged()
	if not spell then return end

	if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
		index = nil
		self:ScheduleRepeatingEvent("Fudge", self.OnUpdate, 0.2, self)
		self.OnUpdate()
		self.frame:Show()
	else
		self:CancelScheduledEvent("Fudge")
		self.frame:Hide()
	end
end

function Fudge:OnUpdate()
	local text
	if IsSpellInRange(spell) == 1 then
		if index ~= "range" then
			text = L["In Range"]
			index = "range"
		else return end
	else
		if index ~= "oorange" then
			text = L["Out of Range"]
			index = "oorange"
		else return end
	end

	local db = Fudge.db.profile
	local color = db.colors[index]

	local frame = Fudge.frame
	frame:SetBackdropColor(unpack(color))
	frame:SetBackdropBorderColor(unpack(color))

	if db.text then
		frame.Range:SetText( text )
	end
end