local _, A = ...
local cfg = A.cfg
local oUF = A.oUF or oUF
local class = select(2, UnitClass('player'))

local auraLoader = CreateFrame('Frame')
auraLoader:RegisterEvent('ADDON_LOADED')
auraLoader:SetScript('OnEvent', function(self, event, addon)
	ActivityAuras = ActivityAuras or {}
	PersonalAuras = PersonalAuras or {}
	--NameplateBuffs = NameplateBuffs or {}
	UpdateAuraList()
end)

local Shared = function(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', OnEnterHL)
	self:SetScript('OnLeave', OnLeaveHL)

	Health(self)

	self.fBackDrop = fBackDrop(self, self)
	self.Range = { insideAlpha = 1, outsideAlpha = 0.4 }
end

local UnitSpecific = {
	player = function(self, ...)
		Shared(self, ...)
		self.unit = 'player'

		Power(self, 'BOTTOM')
		HealthPrediction(self)
		extCastbar(self)

		self:SetSize(cfg.mainUF.player.width, cfg.mainUF.player.height)
		self.Health:SetHeight(cfg.mainUF.player.height-4)
		self.Power:SetHeight(3)

    	self.Health.colorClass = true

		local htext = cFontString(self.Health, nil, cfg.bfont, 12, cfg.fontflag, 1, 1, 1, 'RIGHT')
		htext:SetPoint('RIGHT', self.Health, 'RIGHT', 1, 0)
		self:Tag(htext, '[unit:HPpercent]')
		local ptext = cFontString(self.Power, nil, cfg.bfont, 9, cfg.fontflag, 1, 1, 1, 'CENTER')
		ptext:SetPoint('CENTER', self.Power, 'CENTER', 1, -1)
		self:Tag(ptext, '[unit:PPflex]')
		local cres = cFontString(self.Power, nil, cfg.bfont, 26, cfg.fontflag, 1, 1, 1, 'RIGHT')
		cres:SetPoint('RIGHT', self, 'LEFT', -3, 0)
		self:Tag(cres, '[color][player:Resource]')
		local subpower = cFontString(self.Power, nil, cfg.bfont, 10, cfg.fontflag, 1, 1, 1, 'LEFT')
		subpower:SetPoint('LEFT', self.Power, 'RIGHT', 3, 0)
		self:Tag(subpower, '[player:SubMana]')

		if class == 'DEATHKNIGHT' and not UnitHasVehicleUI('player') then
			local runes = CreateFrame('Frame', nil, self)
			runes:SetSize(cfg.mainUF.player.width, 5)
			runes:SetPoint('TOP', self.Power, 'BOTTOM', 0, -4)
			runes.bg = fBackDrop(runes, runes)
			local i = 6
			for index = 1, 6 do
				runes[i] = cStatusbar(runes, cfg.texture, nil, cfg.mainUF.player.width/6-1, 5, 0.21, 0.6, 0.7, 1)
				if i == 6 then
					runes[i]:SetPoint('TOPRIGHT', runes, 'TOPRIGHT', 0, 0)
				else
					runes[i]:SetPoint('RIGHT', runes[i+1], 'LEFT', -1, 0)
				end
				runes[i].bg = runes[i]:CreateTexture(nil, 'BACKGROUND')
				runes[i].bg:SetAllPoints(runes[i])
				runes[i].bg:SetTexture(cfg.texture)
				runes[i].bg.multiplier = 0.3

				i=i-1
			end
			self.Runes = runes
		elseif class == 'MONK' and not UnitHasVehicleUI('player') then
			local stagger = CreateFrame('StatusBar', nil, self)
			stagger:SetSize(cfg.mainUF.player.width, 5)
			stagger:SetPoint('TOP', self.Power, 'BOTTOM', 0, -4)
			stagger.bg = fBackDrop(stagger, stagger)
			stagger.bg = stagger:CreateTexture(nil, 'BACKGROUND')
			stagger.bg:SetAllPoints(stagger)
			stagger.bg:SetTexture(cfg.texture)
			stagger.bg.multiplier = 0.3
			self.Stagger = stagger

			local staggerCurrent = cFontString(self.Stagger, nil, cfg.bfont, 10, cfg.fontflag, 1, 1, 1, 'LEFT')
			staggerCurrent:SetPoint('LEFT', self.Stagger, 'LEFT', 1, 0)
			self:Tag(staggerCurrent, '[player:StaggerCurrent]')
			local staggerPercent = cFontString(self.Power, nil, cfg.bfont, 14, cfg.fontflag, 1, 1, 1, 'RIGHT')
			staggerPercent:SetPoint('RIGHT', self, 'LEFT', -3, 0)
			self:Tag(staggerPercent, '[player:StaggerPercent]')
		-- elseif class == 'DRUID' then
			-- TODO : MushroomBar?
		-- elseif class == 'SHAMAN' then
			-- TODO : TotemBar? like Runebar
		end

		--[[ GCD Bar
		local class_color = RAID_CLASS_COLORS[class]
		local gcd = cStatusbar(self, cfg.texture, nil, cfg.mainUF.player.width, 3, class_color.r, class_color.g, class_color.b, 1)
		gcd:SetPoint(cfg.castbar.player.position.sa, cfg.castbar.player.position.a, cfg.castbar.player.position.pa, cfg.castbar.player.position.x, cfg.castbar.player.position.y-cfg.castbar.player.height)
		gcd.bd = fBackDrop(gcd, gcd)
		gcd.bg = gcd:CreateTexture(nil, 'BACKGROUND')
		gcd.bg:SetAllPoints(gcd)
		gcd.bg:SetTexture(cfg.texture)
		gcd.bg:SetVertexColor(class_color.r, class_color.g, class_color.b, 0.4)
		self.GCD = gcd
		]]

		self.RestingIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
		self.RestingIndicator:SetSize(6, 6)
		self.RestingIndicator:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
		self.RestingIndicator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		self.RestingIndicator:SetVertexColor(0,0.4,0.9)

		self.CombatIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
		self.CombatIndicator:SetSize(6, 6)
		self.CombatIndicator:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
		self.CombatIndicator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		self.CombatIndicator:SetVertexColor(1,0,0)
		-- TODO : Rest Highlight

		-- EXP Bar
		local Experience = CreateFrame('StatusBar', nil, self, 'AnimatedStatusBarTemplate')
		Experience:SetPoint('TOP', UIParent, 'TOP',0, -5)
		Experience:SetSize(300, 8)
		Experience:SetStatusBarTexture(cfg.texture)
		Experience.bg = fBackDrop(Experience, Experience)

		local Rested = CreateFrame('StatusBar', nil, Experience)
		Rested:SetAllPoints()
		Rested:SetStatusBarTexture(cfg.texture)
		Rested:SetAlpha(0.7)
		Rested:SetBackdrop({
			bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
			insets = {top = -1, left = -1, bottom = -1, right = -1},
		})
		Rested:SetBackdropColor(0, 0, 0)

		local ExperienceLv = cFontString(Experience, 'OVERLAY', cfg.font, 11, cfg.fontflag, 1, 1, 1)
		ExperienceLv:SetPoint('RIGHT', Experience, 'LEFT', -1, 0)
		ExperienceLv:SetJustifyH('CENTER')
		self:Tag(ExperienceLv, 'Lv [level]')

		local ExperienceInfo = cFontString(Experience, 'OVERLAY', cfg.font, 9, cfg.fontflag, 1, 1, 1)
		ExperienceInfo:SetPoint('CENTER', Experience, 'CENTER', 0, 0)
		ExperienceInfo:SetJustifyH('CENTER')
		self:Tag(ExperienceInfo, '[experience:per]% / TNL : [experience:tnl] (Rest : [experience:perrested]%)')

		local ExperienceBG = Rested:CreateTexture(nil, 'BORDER')
		ExperienceBG:SetAllPoints()
		ExperienceBG:SetColorTexture(1/3, 1/3, 1/3)

		self.Experience = Experience
		self.Experience.Rested = Rested

		--[[
		local personalBuff = CreateFrame('Frame', nil, self)
		personalBuff.size = 36
		personalBuff.spacing = 4
		personalBuff.num = 4
		personalBuff:SetSize((personalBuff.size+personalBuff.spacing)*personalBuff.num-personalBuff.spacing, personalBuff.size)
		personalBuff:SetPoint('CENTER', UIParent, 'CENTER', 75, 0)
		personalBuff.initialAnchor = 'CENTER'
		personalBuff['growth-x'] = 'RIGHT'
		personalBuff['growth-y'] = 'DOWN'
		personalBuff.PostCreateIcon = PostCreateIconNormal
		personalBuff.PostUpdateIcon = PostUpdateIcon
		personalBuff.CustomFilter = CustomAuraFilters.personal
		self.Auras = personalBuff

		local activityBuff = CreateFrame('Frame', nil, self)
		activityBuff.size = 30
		activityBuff.spacing = 4
		activityBuff.num = 10
		activityBuff:SetSize((activityBuff.size+activityBuff.spacing)*(activityBuff.num/2)-activityBuff.spacing, activityBuff.size*2+activityBuff.spacing)
		activityBuff:SetPoint('CENTER', UIParent, 'CENTER', -75, 0)
		activityBuff.initialAnchor = 'CENTER'
		activityBuff['growth-x'] = 'LEFT'
		activityBuff['growth-y'] = 'DOWN'
		activityBuff.PostCreateIcon = PostCreateIconNormal
		activityBuff.PostUpdateIcon = PostUpdateIcon
		activityBuff.CustomFilter = CustomAuraFilters.activity
		self.Buffs = activityBuff
		]]

		local PlayerFCF = CreateFrame("Frame", nil, self)
		PlayerFCF:SetSize(35, 35)
		PlayerFCF:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		for i = 1, 8 do
			PlayerFCF[i] = PlayerFCF:CreateFontString(nil, "OVERLAY", "CombatTextFont")
		end
		PlayerFCF.mode = "Fountain"
		--PlayerFCF.xOffset = 30
		PlayerFCF.fontHeight = cfg.plugin.fcf.size
		PlayerFCF.abbreviateNumbers = true
		self.FloatingCombatFeedback = PlayerFCF
	end,

	target = function(self, ...)
		Shared(self, ...)
		self.unit = 'target'

		HealthPrediction(self)
		extCastbar(self)

		self:SetSize(cfg.mainUF.player.width*0.8, cfg.mainUF.player.height)
		--self.Health.colorHealth = true

    	self.Health.colorClass = true
    	self.Health.colorReaction = true

		local name = cFontString(self.Health, nil, cfg.font, 13, cfg.fontflag, 1, 1, 1, 'LEFT')
		name:SetPoint('LEFT', self.Health, 'RIGHT', 3, 0)
		self:Tag(name, '[unit:lv] [color][name]')
		local hptext = cFontString(self.Health, nil, cfg.bfont, 16, cfg.fontflag, 1, 1, 1, 'LEFT')
		hptext:SetPoint('LEFT', self.Health, 'LEFT', 1, 0)
		self:Tag(hptext, '[unit:HPpercent]')
		local hctext = cFontString(self.Health, nil, cfg.bfont, 10, cfg.fontflag, 1, 1, 1, 'RIGHT')
		hctext:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', 1, 1)
		self:Tag(hctext, '[unit:HPcurrent]')

		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(16, 16)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

		local unitBuff = CreateFrame('Frame', nil, self)
		unitBuff.size = 14
		unitBuff.spacing = 4
		unitBuff.num = 6
		unitBuff:SetSize(unitBuff.size*unitBuff.num+unitBuff.spacing*(unitBuff.num-1), unitBuff.size)
		unitBuff:SetPoint('LEFT', name, 'RIGHT', 5, 0)
		unitBuff.initialAnchor = 'LEFT'
		unitBuff.PostCreateIcon = PostCreateIconSmall
		unitBuff.PostUpdateIcon = PostUpdateIcon
		--unitBuff.CustomFilter = CustomFilter
		self.Buffs = unitBuff

		local unitDebuff = CreateFrame('Frame', nil, self)
		unitDebuff.size = 16
		unitDebuff.spacing = 4
		unitDebuff.num = 8
		unitDebuff:SetSize(unitDebuff.size*unitDebuff.num+unitDebuff.spacing*(unitDebuff.num-1), unitDebuff.size)
		unitDebuff:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -5)
		unitDebuff.initialAnchor = 'LEFT'
		unitDebuff.onlyShowPlayer = true
		unitDebuff.PostCreateIcon = PostCreateIconSmall
		unitDebuff.PostUpdateIcon = PostUpdateIcon
		--unitDebuff.CustomFilter = CustomFilter
		self.Debuffs = unitDebuff

		AuraTracker(self, 32, 'BOTTOMLEFT', self, 'TOPLEFT', 0, 5)
	end,

	focus = function(self, ...)
		Shared(self, ...)
		self.unit = 'focus'

		extCastbar(self)

		self:SetSize(cfg.mainUF.focus.width, cfg.mainUF.focus.height)
		self.Health:SetHeight(cfg.mainUF.focus.height)

		self.Health.colorClass = true
    	self.Health.colorReaction = true

		local name = cFontString(self.Health, nil, cfg.font, 13, cfg.fontflag, 1, 1, 1, 'LEFT')
		name:SetPoint('LEFT', self.Health, 'RIGHT', 3, 0)
		self:Tag(name, '[color][name]')

		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(16, 16)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("RIGHT", self.Health, "LEFT", -4, 0)

		AuraTracker(self, cfg.mainUF.focus.height*2.2, 'RIGHT', self, 'LEFT', -5, 0)
	end,

	pet = function(self, ...)
		Shared(self, ...)
		self.unit = 'pet'

		self:SetSize(cfg.mainUF.player.width/3, 4)

		self.Health.colorHealth = true
	end,

	targettarget = function(self, ...)
		Shared(self, ...)
		self.unit = 'targettarget'

		self:SetSize((cfg.mainUF.player.width*0.8)/3, 6)
		self.Health.colorHealth = true

		local name = cFontString(self.Health, nil, cfg.font, 12, cfg.fontflag, 1, 1, 1, 'LEFT')
	    name:SetPoint('LEFT', self.Health, 'RIGHT', 3, 0.5)
		self:Tag(name, '[color][name]')
	end,

	focustarget = function(self, ...)
		Shared(self, ...)
		self.unit = 'focustarget'

		self:SetSize((cfg.mainUF.player.width*0.8)/3, 6)
		self.Health.colorHealth = true

		local name = cFontString(self.Health, nil, cfg.font, 12, cfg.fontflag, 1, 1, 1, 'LEFT')
	    name:SetPoint('LEFT', self.Health, 'RIGHT', 3, 0.5)
		self:Tag(name, '[color][name]')
	end,

	party = function(self, ...)
		Shared(self, ...)
		self.unit = 'party'

		HealthPrediction(self)
		Power(self, 'BOTTOM')
		Phase(self)
		ctfBorder(self)

        self:SetSize(cfg.subUF.party.width, cfg.subUF.party.height)
        self.Health:SetHeight(cfg.subUF.party.height-3)
        self.Power:SetHeight(2)
        self.Range = {}

		self.Health.colorReaction = true
		self.Health.colorDisconnected = true

        local name = cFontString(self.Health, nil, cfg.font, 10, nil, 1, 1, 1, 'CENTER')
        name:SetPoint('TOP', self.Health, 'TOP', 0, -1)
		name:SetShadowOffset(1, -1)
        self:Tag(name, '[color][name]')
        local htext = cFontString(self.Health, nil, cfg.bfont, 14, cfg.fontflag, 1, 1, 1, 'LEFT')
        htext:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 1, 1)
        self:Tag(htext, '[unit:HPmix]')

		self.DebuffHighlight = true

		self.LeaderIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.LeaderIndicator:SetSize(11, 11)
		self.LeaderIndicator:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
		self.AssistantIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.AssistantIndicator:SetSize(11, 11)
		self.AssistantIndicator:SetPoint("CENTER", self, "TOPLEFT", 4, 5)
		self.GroupRoleIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.GroupRoleIndicator:SetSize(10, 10)
		self.GroupRoleIndicator:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 1, -1)
		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(20, 20)
		self.RaidTargetIndicator:SetAlpha(0.7)
		self.RaidTargetIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.ReadyCheckIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ReadyCheckIndicator:SetSize(24, 24)
		self.ReadyCheckIndicator:SetPoint("CENTER", self.Health, "TOP", 0, 8)
		self.ResurrectIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ResurrectIndicator:SetSize(22, 22)
		self.ResurrectIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.SummonIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.SummonIndicator:SetSize(32, 32)
		self.SummonIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

		local unitDebuff = CreateFrame('Frame', nil, self)
		unitDebuff.spacing = 3
		unitDebuff.num = 9 -- 3*3
		unitDebuff.size = (cfg.subUF.party.width-unitDebuff.spacing*2)/3
		unitDebuff:SetSize(cfg.subUF.party.width, unitDebuff.size*3+unitDebuff.spacing*2)
		unitDebuff:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
		unitDebuff.initialAnchor = 'TOPLEFT'
		unitDebuff['growth-y'] = 'DOWN'
		unitDebuff.PostCreateIcon = PostCreateIconSmall
		unitDebuff.PostUpdateIcon = PostUpdateIcon
		--unitDebuff.CustomFilter = CustomFilter
		self.Debuffs = unitDebuff

		AuraTracker(self, cfg.subUF.party.height*0.7, 'CENTER', self.Health, 'CENTER', 0, 0)
	end,

	partypet = function(self, ...)
		Shared(self, ...)
		self.unit = 'partypet'

		self:SetSize(cfg.subUF.party.width/3, 2)
		self.Health.colorHealth = true
	end,

	partytarget = function(self, ...)
		Shared(self, ...)
		self.unit = 'partytarget'

		self:SetSize(cfg.subUF.party.width, 5)
		self.Health:SetHeight(5)
		self.Health.colorHealth = true

		local name = cFontString(self.Health, nil, cfg.font, 10, cfg.fontflag, 1, 1, 1, 'LEFT')
	    name:SetPoint('BOTTOMLEFT', self.Health, 'TOPLEFT', 0, 2)
		self:Tag(name, '[color][unit:name8]')

		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(12, 12)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
	end,

	raid = function(self, ...)
		Shared(self, ...)
		self.unit = 'raid'
		self:SetAttribute("type2", "focus")

		Power(self, 'BOTTOM')
		Phase(self)
		ctfBorder(self)

		self:SetSize(cfg.subUF.raid.width, cfg.subUF.raid.height)
		self.Health:SetHeight(cfg.subUF.raid.height-3)
		self.Health:SetOrientation("VERTICAL")
		self.Power:SetHeight(2)

		self.Health.colorClass = true
		self.Health.colorReaction = true

		local name = cFontString(self.Health, nil, cfg.bfont, 10, 'none', 1, 1, 1)
		name:SetPoint('TOPLEFT', 1, 0)
		name:SetShadowOffset(1, -1)
	    name:SetJustifyH('LEFT')
		self:Tag(name, '[unit:name4]')
	    local htext = cFontString(self.Health, nil, cfg.bfont, 10, cfg.fontflag, 1, 1, 1)
	    htext:SetPoint('BOTTOMRIGHT', 2, 0)
		htext:SetJustifyH('RIGHT')
	    self:Tag(htext, '[unit:HPpercent]')

	    self.LeaderIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.LeaderIndicator:SetSize(11, 11)
		self.LeaderIndicator:SetPoint("CENTER", self, "TOPLEFT", 4, 5)
		self.AssistantIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.AssistantIndicator:SetSize(11, 11)
		self.AssistantIndicator:SetPoint("CENTER", self, "TOPLEFT", 4, 5)
		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(16, 16)
		self.RaidTargetIndicator:SetPoint("CENTER", self, "LEFT", 0, 0)
		self.GroupRoleIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.GroupRoleIndicator:SetSize(10, 10)
		self.GroupRoleIndicator:SetPoint("CENTER", self, "TOPRIGHT", -6, -6)
		self.ReadyCheckIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ReadyCheckIndicator:SetSize(32, 32)
		self.ReadyCheckIndicator:SetPoint("CENTER", self, "CENTER", 0, 0)
		self.ResurrectIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ResurrectIndicator:SetSize(16, 16)
		self.ResurrectIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.SummonIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.SummonIndicator:SetSize(32, 32)
		self.SummonIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

		AuraTracker(self, cfg.subUF.raid.width*0.65, 'CENTER', self.Health)
	end,

	tank = function(self, ...)
		Shared(self, ...)
		self.unit = 'tank'

		Power(self, 'BOTTOM')
		ctfBorder(self)

		self:SetSize(cfg.subUF.party.width, cfg.subUF.party.height)
		self.Health:SetHeight(cfg.subUF.party.height-3)
		self.Health:SetReverseFill(true)
		self.Power:SetHeight(2)
		self.Power:SetReverseFill(true)

		self.Health.colorClass = true

		local name = cFontString(self.Health, nil, cfg.font, 11, cfg.fontflag, 1, 1, 1, 'RIGHT')
		name:SetPoint('BOTTOMRIGHT', self.Health, 'TOPRIGHT', 2, 2)
		self:Tag(name, '[color][name]')

		local htext = cFontString(self.Health, nil, cfg.bfont, 18, cfg.fontflag, 1, 1, 1, 'RIGHT')
		htext:SetPoint('LEFT', self.Health, 'LEFT')
		htext:SetPoint('RIGHT', self.Health, 'RIGHT', 1, 0)
		self:Tag(htext, '[unit:HPmix]')

		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(18, 18)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("LEFT", self.Health, "LEFT", 0, 0)

		local unitDebuff = CreateFrame('Frame', nil, self)
		unitDebuff.size = cfg.subUF.party.height
		unitDebuff.spacing = 5
		unitDebuff.num = 5
		unitDebuff:SetSize(unitDebuff.size*unitDebuff.num+unitDebuff.spacing*(unitDebuff.num-1), unitDebuff.size)
		unitDebuff:SetPoint('RIGHT', self, 'LEFT', -5, 0)
		unitDebuff.initialAnchor = 'RIGHT'
		unitDebuff['growth-x'] = 'LEFT'
		unitDebuff.PostCreateIcon = PostCreateIconSmall
		unitDebuff.PostUpdateIcon = PostUpdateIcon
		--unitDebuff.CustomFilter = CustomFilter
		self.Debuffs = unitDebuff

		AuraTracker(self, cfg.subUF.party.height, 'LEFT', self, 'RIGHT', 5, 0)
	end,

	boss = function(self, ...)
		Shared(self, ...)
		self.unit = 'boss'

		Power(self, 'BOTTOM')
		ctfBorder(self)

		self:SetSize(cfg.subUF.boss.width, cfg.subUF.boss.height)
		self.Health:SetHeight(cfg.subUF.boss.height-5)
		self.Power:SetHeight(4)

		self.Health.colorReaction = true

		local name = cFontString(self.Health, nil, cfg.font, 11, cfg.fontflag, 1, 1, 1, 'LEFT')
		name:SetPoint('BOTTOMLEFT', self.Health, 'TOPLEFT', 0, 2)
		self:Tag(name, '[color][name]')

		local hptext = cFontString(self.Health, nil, cfg.bfont, 20, cfg.fontflag, 1, 1, 1, 'LEFT')
		hptext:SetPoint('LEFT', self.Health, 'LEFT', 1, 0)
		self:Tag(hptext, '[unit:HPpercent]')

		local hctext = cFontString(self.Health, nil, cfg.bfont, 10, cfg.fontflag, 1, 1, 1, 'RIGHT')
		hctext:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', 1, 1)
		self:Tag(hctext, '[unit:HPcurrent]')

		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(22, 22)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

	    --[[
	    local altp = createStatusbar(self, cfg.texture, nil, cfg.AlternativePower.boss.height, cfg.AlternativePower.boss.width, 1, 1, 1, 1)
        altp:SetPoint(unpack(cfg.AlternativePower.boss.pos))
		altp.bd = framebd(altp, altp)
        altp.bg = altp:CreateTexture(nil, 'BORDER')
        altp.bg:SetAllPoints(altp)
        altp.bg:SetTexture(cfg.texture)
        altp.bg:SetVertexColor(1, 1, 1, 0.3)
        altp.Text = fs(altp, 'OVERLAY', cfg.aura.font, cfg.aura.fontsize, cfg.aura.fontflag, 1, 1, 1)
        altp.Text:SetPoint('CENTER')
        self:Tag(altp.Text, '[altpower]')
		altp:EnableMouse(true)
        self.AlternativePower = altp
        ]]

		local unitBuff = CreateFrame('Frame', nil, self)
		unitBuff.size = cfg.subUF.boss.height
		unitBuff.spacing = 5
		unitBuff.num = 2
		unitBuff:SetSize(unitBuff.size*unitBuff.num+unitBuff.spacing*(unitBuff.num-1), unitBuff.size)
		unitBuff:SetPoint('RIGHT', self, 'LEFT', -5, 0)
		--unitBuff:SetAlpha(0.7)
		unitBuff.initialAnchor = 'RIGHT'
		unitBuff['growth-x'] = 'LEFT'
		unitBuff.PostCreateIcon = PostCreateIconSmall
		unitBuff.PostUpdateIcon = PostUpdateIcon
		self.Buffs = unitBuff

		--[[
		local unitDebuff = CreateFrame('Frame', nil, self)
		unitDebuff.size = cfg.subUF.boss.height
		unitDebuff.spacing = 5
		unitDebuff.num = 5
		unitDebuff:SetSize(unitDebuff.size*unitDebuff.num+unitDebuff.spacing*(unitDebuff.num-1), unitDebuff.size)
		unitDebuff:SetPoint('LEFT', self, 'RIGHT', 5, 0)
		--unitDebuff:SetAlpha(0.7)
		unitDebuff.PostCreateIcon = PostCreateIconSmall
		unitDebuff.PostUpdateIcon = PostUpdateIcon
		--unitDebuff.CustomFilter = CustomFilter
		self.Debuffs = unitDebuff
		]]
	end,

	-- DEBUG
    debugparty = function(self, ...)
        Shared(self, ...)
        self.unit = 'target'

        Power(self, 'BOTTOM')
        Phase(self)
        ctfBorder(self)

        self:SetSize(cfg.subUF.party.width, cfg.subUF.party.height)
        self.Health:SetPoint("TOPLEFT")
        self.Health:SetPoint("TOPRIGHT")
        self.Health:SetHeight(cfg.subUF.party.height-3)
        self.Power:SetHeight(2)
        self.Range = {}

        self.Health.colorClass = false

        local name = cFontString(self.Health, nil, cfg.font, 10, nil, 1, 1, 1, 'CENTER')
        name:SetPoint('TOP', self.Health, 'TOP', 0, -1)
		name:SetShadowOffset(1, -1)
        self:Tag(name, '[color][name]')
        local htext = cFontString(self.Health, nil, cfg.bfont, 14, cfg.fontflag, 1, 1, 1, 'LEFT')
        htext:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 1, 1)
        self:Tag(htext, '[unit:HPmix]')

		self.DebuffHighlight = true

		self.LeaderIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.LeaderIndicator:SetSize(11, 11)
		self.LeaderIndicator:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
		self.AssistantIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.AssistantIndicator:SetSize(11, 11)
		self.AssistantIndicator:SetPoint("CENTER", self, "TOPLEFT", 4, 5)
		self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidTargetIndicator:SetSize(17, 17)
		self.RaidTargetIndicator:SetAlpha(0.9)
		self.RaidTargetIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.GroupRoleIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.GroupRoleIndicator:SetSize(10, 10)
		self.GroupRoleIndicator:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 1, -1)
		self.ReadyCheckIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ReadyCheckIndicator:SetSize(22, 22)
		self.ReadyCheckIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.ResurrectIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.ResurrectIndicator:SetSize(16, 16)
		self.ResurrectIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
		self.SummonIndicator = self.Health:CreateTexture(nil, "OVERLAY")
		self.SummonIndicator:SetSize(32, 32)
		self.SummonIndicator:SetPoint("CENTER", self.Health, "CENTER", 0, 0)

        --[[
        local unitDebuff = CreateFrame('Frame', nil, self)
        unitDebuff.size = cfg.subUF.party.height
        unitDebuff.spacing = 5
        unitDebuff.num = 4
        unitDebuff:SetSize(unitDebuff.size*unitDebuff.num+unitDebuff.spacing*(unitDebuff.num-1), unitDebuff.size)
        unitDebuff:SetPoint('RIGHT', self, 'LEFT', -5, 0)
        unitDebuff.initialAnchor = 'RIGHT'
        unitDebuff['growth-x'] = 'LEFT'
        unitDebuff.PostCreateIcon = PostCreateIconSmall
        unitDebuff.PostUpdateIcon = PostUpdateIcon
        --unitDebuff.CustomFilter = CustomFilter
        self.Debuffs = unitDebuff
        ]]

        AuraTracker(self, cfg.subUF.party.height*0.8, 'CENTER', self, 'CENTER', 0, 0)
    end,
}

oUF:RegisterStyle('CombaUI', Shared)
for unit,layout in next, UnitSpecific do
    oUF:RegisterStyle('CombaUI - ' .. unit:gsub('^%l', string.upper), layout)
end

-- Spawn Helper -------------------------------------------------------------------------
local spawnHelper = function(self, unit, ...)
    if(UnitSpecific[unit]) then
        self:SetActiveStyle('CombaUI - ' .. unit:gsub('^%l', string.upper))
    elseif(UnitSpecific[unit:match('[^%d]+')]) then
        self:SetActiveStyle('CombaUI - ' .. unit:match('[^%d]+'):gsub('^%l', string.upper))
    else
        self:SetActiveStyle('CombaUI')
    end
    local object = self:Spawn(unit)
    object:SetPoint(...)
    return object
end

oUF:Factory(function(self)
	spawnHelper(self, 'player', cfg.mainUF.player.position.sa, cfg.mainUF.player.position.a, cfg.mainUF.player.position.pa, cfg.mainUF.player.position.x, cfg.mainUF.player.position.y)
	spawnHelper(self, 'pet', 'BOTTOMLEFT', 'oUF_CombaUIPlayer', 'TOPLEFT', 0, 5)
	spawnHelper(self, 'target', 'LEFT', 'oUF_CombaUIPlayer', 'RIGHT', 10, 0)
	spawnHelper(self, 'targettarget', 'BOTTOMRIGHT', 'oUF_CombaUITarget', 'TOPRIGHT', 0, 5)
	spawnHelper(self, 'focus', cfg.mainUF.focus.position.sa, cfg.mainUF.focus.position.a, cfg.mainUF.focus.position.pa, cfg.mainUF.focus.position.x, cfg.mainUF.focus.position.y)
	spawnHelper(self, 'focustarget', 'TOPRIGHT', 'oUF_CombaUIFocus','BOTTOMRIGHT', 0, -7)

	self:SetActiveStyle('CombaUI - Party') -- custom [group:party,nogroup:raid][@raid4,noexists,group:raid]show; hide
	self:SpawnHeader('oUF_Party', nil, 'custom [group:party,nogroup:raid][@raid4,noexists,group:raid]show; hide',
		'showParty', true, 'showPlayer', true, 'showSolo', true, 'showRaid', true,
		'xOffset', 10,
		'point', 'LEFT',
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'TANK,HEALER,DAMAGER',
		"initial-width", cfg.subUF.party.width,
		"initial-height", cfg.subUF.party.height,
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]]
	):SetPoint(cfg.subUF.party.position.sa, cfg.subUF.party.position.a, cfg.subUF.party.position.pa, cfg.subUF.party.position.x, cfg.subUF.party.position.y)

	self:SetActiveStyle('CombaUI - Partypet')
	self:SpawnHeader('oUF_PartyPets', nil, 'custom [group:party,nogroup:raid][@raid4,noexists,group:raid]show; hide',
		'showParty', true, 'showPlayer', true, 'showSolo', true, 'showRaid', true,
		'xOffset', 70,
		'point', 'LEFT',
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'HEALER,TANK,DAMAGER',
		"initial-width", cfg.subUF.party.width/3,
		"initial-height", 4,
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetAttribute('unitsuffix', 'pet')
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]]
	):SetPoint("BOTTOMRIGHT", 'oUF_Party', "TOPRIGHT", 0, 4)

	self:SetActiveStyle('CombaUI - Partytarget')
	self:SpawnHeader('oUF_PartyTargets', nil, 'custom [group:party,nogroup:raid][@raid4,noexists,group:raid]show; hide',
		'showParty', true, 'showPlayer', true, 'showSolo', true, 'showRaid', true,
		'xOffset', 10,
		'point', 'LEFT',
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'HEALER,TANK,DAMAGER',
		"initial-width", cfg.subUF.party.width,
		"initial-height", 5,
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetAttribute('unitsuffix', 'target')
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]]
	):SetPoint('BOTTOM', 'oUF_Party', 'TOP', 0, 15)

	self:SetActiveStyle('CombaUI - Raid')
	self:SpawnHeader('oUF_Raid', nil, 'custom show',
		'showParty', false, 'showPlayer', true, 'showSolo', false, 'showRaid', true,
		'xoffset', 5,
		'yOffset', -12,
		'point', 'TOP',
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		'groupBy', 'GROUP',
		'maxColumns', 8,
		'unitsPerColumn', 5,
		'columnSpacing', 5,
		'columnAnchorPoint', 'LEFT',
		"initial-width", cfg.subUF.raid.width,
		"initial-height", cfg.subUF.raid.height,
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]]
	):SetPoint(cfg.subUF.raid.position.sa, cfg.subUF.raid.position.a, cfg.subUF.raid.position.pa, cfg.subUF.raid.position.x, cfg.subUF.raid.position.y)

	self:SetActiveStyle('CombaUI - Tank')
	self:SpawnHeader('oUF_MainTank', nil, 'raid',
		'showParty', false, 'showPlayer', true, 'showSolo', false, 'showRaid', true,
		'groupFilter', 'MAINTANK',
		'yOffset', 18,
		'point', 'BOTTOM'
	):SetPoint(cfg.subUF.party.position.sa, cfg.subUF.party.position.a, cfg.subUF.party.position.pa, cfg.subUF.party.position.x, cfg.subUF.party.position.y)

	for i = 1, MAX_BOSS_FRAMES do
		spawnHelper(self, 'boss'..i, cfg.subUF.boss.position.sa, cfg.subUF.boss.position.a, cfg.subUF.boss.position.pa, cfg.subUF.boss.position.x, cfg.subUF.boss.position.y-55+(55*i))
	end

    -- DEBUG
    for i = 1, 5 do
        spawnHelper(self, 'debugparty'..i, "BOTTOM", UIParent, "BOTTOM", -200-100+(100*i), cfg.subUF.party.position.y)
    end
end)

----------------------------------------------------------------------------------------
--	Test UnitFrames(by community)
----------------------------------------------------------------------------------------
-- For testing /run oUFAbu.TestArena()
function TUF()
	oUF_CombaUIBoss1:Show(); oUF_CombaUIBoss1.Hide = function() end oUF_CombaUIBoss1.unit = "target"
	oUF_CombaUIBoss2:Show(); oUF_CombaUIBoss2.Hide = function() end oUF_CombaUIBoss2.unit = "target"
    oUF_CombaUIBoss3:Show(); oUF_CombaUIBoss3.Hide = function() end oUF_CombaUIBoss3.unit = "target"
	--oUF_Party:Show(); oUF_Party.Hide = function() end oUF_Party.unit = "target"
	--oUF_PartyPets:Show(); oUF_PartyPets.Hide = function() end oUF_PartyPets.unit = "target"
	--oUF_PartyTargets:Show(); oUF_PartyTargets.Hide = function() end oUF_PartyTargets.unit = "target"

	--oUF_MainTank:Show(); oUF_MainTank.Hide = function() end oUF_MainTank.unit = "target"

    oUF_CombaUIDebugparty1:Show(); oUF_CombaUIDebugparty1.Hide = function() end oUF_CombaUIDebugparty1.unit = "target"
    oUF_CombaUIDebugparty2:Show(); oUF_CombaUIDebugparty2.Hide = function() end oUF_CombaUIDebugparty2.unit = "target"
    oUF_CombaUIDebugparty3:Show(); oUF_CombaUIDebugparty3.Hide = function() end oUF_CombaUIDebugparty3.unit = "target"
    oUF_CombaUIDebugparty4:Show(); oUF_CombaUIDebugparty4.Hide = function() end oUF_CombaUIDebugparty4.unit = "target"
    oUF_CombaUIDebugparty5:Show(); oUF_CombaUIDebugparty5.Hide = function() end oUF_CombaUIDebugparty5.unit = "target"

	local time = 0
	local f = CreateFrame("Frame")
	f:SetScript("OnUpdate", function(self, elapsed)
		time = time + elapsed
		if time > 5 then
			oUF_CombaUIBoss1:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit
			oUF_CombaUIBoss2:UpdateAllElements("ForceUpdate")
            oUF_CombaUIBoss3:UpdateAllElements("ForceUpdate")
			--oUF_Party:UpdateAllElements("RefreshUnit")
			--oUF_Party1Pets:UpdateAllElements("ForceUpdate")
			--oUF_Party1Targets:UpdateAllElements("ForceUpdate")
			--oUF_MainTank:UpdateAllElements("ForceUpdate")

            oUF_CombaUIDebugparty1:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit
            oUF_CombaUIDebugparty2:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit
            oUF_CombaUIDebugparty3:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit
            oUF_CombaUIDebugparty4:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit
            oUF_CombaUIDebugparty5:UpdateAllElements("ForceUpdate") -- OnUpdate RefreshUnit

			time = 0
		end
	end)
end
