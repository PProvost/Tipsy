--[[
Tipsy/Tipsy.lua

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

local L = setmetatable({}, {__index=function(t,i) return i end})
local function Print(...) print("|cFF33FF99Tipsy|r:", ...) end
local db = nil

local defaults = {
	profile = {
		-- Default location copied from FrameXML/GameTooltip.lua
		-- tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y);
		point = "BOTTOMRIGHT",
		relativePoint = "BOTTOMRIGHT",
		xOfs = -CONTAINER_OFFSET_X - 13,
		yOfs = CONTAINER_OFFSET_Y,
	}
}

local function Tipsy_GameTooltip_SetDefaultAnchor(tooltip, parent, ...)
	tooltip:SetOwner(parent, "ANCHOR_NONE")
	tooltip:ClearAllPoints()
	tooltip:SetPoint(db.point, UIParent, db.relativePoint, db.xOfs, db.yOfs)
end

Tipsy = CreateFrame("frame")
Tipsy:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
Tipsy:RegisterEvent("ADDON_LOADED")

function Tipsy:ADDON_LOADED(event, addon)
	if addon:lower() ~= "addontemplate" then return end

	self.db = LibStub("AceDB-3.0"):New("TipsyDB", defaults, "Default")
	db = self.db.profile

	LibStub("tekKonfig-AboutPanel").new(nil, "Tipsy")

	hooksecurefunc("GameTooltip_SetDefaultAnchor", Tipsy_GameTooltip_SetDefaultAnchor)
end

function Tipsy:ResetTooltipAnchor()
	db.point = defaults.profile.point
	db.relativePoint = defaults.profile.point
	db.xOfs = defaults.profile.xOfs
	db.yOfs = defaults.profile.yOfs
	self:ShowTooltipAnchor()
end

function Tipsy:ShowTooltipAnchor()
	if self.anchorFrame == nil then self.anchorFrame = self:CreateAnchorFrame() end
	self.anchorFrame:ClearAllPoints()
	self.anchorFrame:SetPoint( self.db.profile.point, UIParent, self.db.profile.relativePoint, self.db.profile.xOfs, self.db.profile.yOfs )
	self.anchorFrame:Show()
end

function Tipsy:GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

function Tipsy:CreateAnchorFrame()
	local db = self.db.profile
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("DIALOG")
	frame:SetWidth(125)
	frame:SetHeight(85)

	local title = L["|cFFFFFFFFTipsy Tooltip Anchor|r"]
	local notes = L["Right click when finished positioning the tooltip."]

	local string = frame:CreateFontString()
	string:SetAllPoints(frame)
	string:SetFontObject("GameFontNormalSmall")
	string:SetText(title .. "|n|n" .. notes)

	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left=4, right=4, top=4, bottom=4 }
	})
	frame:SetBackdropColor(0.75,0,0,1)
	frame:SetBackdropBorderColor(0.75,0,0,1)

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")

	frame:SetScript("OnDragStart", function() 
		this:StartMoving() 
	end)

	frame:SetScript("OnDragStop", function() 
		this:StopMovingOrSizing() 
	end)

	frame:SetScript("OnMouseDown", function(this, button)
		if button == "RightButton" then
			db.point, _, db.relativePoint, db.xOfs, db.yOfs = this:GetPoint()
			this:Hide()
		end
	end)

	return frame
end

LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Tipsy", {
	type = "launcher",
	icon = [[Interface\AddOns\Tipsy\Icon]],
	text = L["Tipsy"],
	OnClick = function(frame, button)
		Tipsy:ShowTooltipAnchor() 
	end,
	OnEnter = function(frame)
		GameTooltip:SetOwner(frame, "ANCHOR_NONE")
		GameTooltip:SetPoint(Tipsy:GetTipAnchor(frame))
		GameTooltip:ClearLines()

		GameTooltip:AddLine(L["Tipsy"])
		GameTooltip:AddLine("")
		GameTooltip:AddLine(L["Click to toggle the tooltip anchor frame"])

		GameTooltip:Show()
	end,
	OnLeave = function()
		GameTooltip:Hide()
	end,
})

local function GetSlashCommand(msg) -- returns: command, args
	if msg then
		local a,b,c = string.find(msg, "(%S+)");
		if a then return c, string.sub(msg, b+2); else	return ""; end
	end
end

SLASH_TIPSY1 = L["/tipsy"]
SlashCmdList.TIPSY = function(msg)
	local command, args = GetSlashCommand(msg)
	if command == "show" then
		Tipsy:ShowTooltipAnchor()
	elseif command == "reset" then
		Tipsy:ResetTooltipAnchor()
	else
		Print(L["Tipsy Usage:"])
		Print(L["/tipsy show - show the tooltip anchor"])
		Print(L["/tipsy reset - reset the tooltip anchor to the bottom right"])
	end
end

