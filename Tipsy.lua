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
local anchorFrame = nil

--[[
local debugf = tekDebug and tekDebug:GetFrame("Tipsy")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end
]]

local defaults = {
	-- Default location copied from FrameXML/GameTooltip.lua
	-- tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y);
	point = "BOTTOMRIGHT",
	relativePoint = "BOTTOMRIGHT",
	xOfs = -CONTAINER_OFFSET_X - 13,
	yOfs = CONTAINER_OFFSET_Y,
}

local function Tipsy_GameTooltip_SetDefaultAnchor(tooltip, parent, ...)
	tooltip:SetOwner(parent, "ANCHOR_NONE")
	tooltip:ClearAllPoints()
	tooltip:SetPoint(db.point, UIParent, db.relativePoint, db.xOfs, db.yOfs)
end

-- Event handler frame
local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")

function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "tipsy" then return end
	
	-- convert the old Ace3 database
	if TipsyDB and TipsyDB.profiles and TipsyDB.profiles.Default then
		local newDB = {}
		for k,v in pairs(TipsyDB.profiles.Default) do newDB[k] = v end
		TipsyDB = newDB
	end

	TipsyDB = setmetatable(TipsyDB or {}, {__index = defaults})
	db = TipsyDB

	LibStub("tekKonfig-AboutPanel").new(nil, "Tipsy")
	hooksecurefunc("GameTooltip_SetDefaultAnchor", Tipsy_GameTooltip_SetDefaultAnchor)

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil
	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end
 
 
function f:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")
	-- Do anything you need to do after the player has entered the world
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end
 
 
function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	-- Do anything you need to do as the player logs out
end

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function CreateAnchorFrame()
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

	frame:SetScript("OnDragStart", function(self) 
		self:StartMoving() 
	end)

	frame:SetScript("OnDragStop", function(self) 
		self:StopMovingOrSizing() 
	end)

	frame:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			db.point, _, db.relativePoint, db.xOfs, db.yOfs = self:GetPoint()
			self:Hide()
		end
	end)

	return frame
end

local function ShowTooltipAnchor()
	if anchorFrame == nil then anchorFrame = CreateAnchorFrame() end
	anchorFrame:ClearAllPoints()
	anchorFrame:SetPoint( db.point, UIParent, db.relativePoint, db.xOfs, db.yOfs )
	anchorFrame:Show()
end

local function ResetTooltipAnchor()
	db.point = defaults.point
	db.relativePoint = defaults.point
	db.xOfs = defaults.xOfs
	db.yOfs = defaults.yOfs
	ShowTooltipAnchor()
end

LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Tipsy", {
	type = "launcher",
	icon = [[Interface\AddOns\Tipsy\Icon]],
	text = L["Tipsy"],
	OnClick = function(frame, button)
		ShowTooltipAnchor() 
	end,
	OnEnter = function(frame)
		GameTooltip:SetOwner(frame, "ANCHOR_NONE")
		GameTooltip:SetPoint(GetTipAnchor(frame))
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
		ShowTooltipAnchor()
	elseif command == "reset" then
		ResetTooltipAnchor()
	else
		Print(L["Tipsy "] .. GetAddOnMetadata("Tipsy", "Version"))
		Print(L["Usage:"])
		Print(L["/tipsy - displays this message"])
		Print(L["/tipsy show - show the tooltip anchor"])
		Print(L["/tipsy reset - reset the tooltip anchor to the bottom right"])
	end
end

