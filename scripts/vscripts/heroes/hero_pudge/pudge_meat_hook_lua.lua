pudge_meat_hook_lua = class({})
LinkLuaModifier( "modifier_meat_hook_followthrough_lua", "heroes/hero_pudge/modifiers/modifier_meat_hook_followthrough_lua.lua" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_meat_hook_lua", "heroes/hero_pudge/modifiers/modifier_meat_hook_lua.lua" ,LUA_MODIFIER_MOTION_HORIZONTAL )

-- require('../../Timers')
--[[Author: Valve
	Date: 26.09.2015.]]
--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnAbilityPhaseStart()
	self:GetCaster():StartGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
	return true
end

--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnAbilityPhaseInterrupted()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
end

--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnSpellStart()
	self.bChainAttached = false
	if self.hVictim ~= nil then
		self.hVictim:InterruptMotionControllers( true )
	end

	self.hTarget = self:GetCaster().hook_unluckydog  
	self.hTarget.is_hooked = true
	self.hTarget.stop_moving = true

	self.hook_damage = self:GetSpecialValueFor( "hook_damage" )  
	self.hook_speed = self:GetSpecialValueFor( "hook_speed" )
	self.hook_width = self:GetSpecialValueFor( "hook_width" )
	
	self.hook_followthrough_constant = self:GetSpecialValueFor( "hook_followthrough_constant" )

	self.vision_radius = self:GetSpecialValueFor( "vision_radius" )  
	self.vision_duration = self:GetSpecialValueFor( "vision_duration" )  
	
	if self:GetCaster() and self:GetCaster():IsHero() then
		local hHook = self:GetCaster():GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
		if hHook ~= nil then
			hHook:AddEffects( EF_NODRAW )
		end
	end

	self.vStartPosition = self:GetCaster():GetOrigin()
	self.vEndPosition = self.hTarget:GetOrigin()
	self.vProjectileLocation = vStartPosition

	local vDirection = (self.vEndPosition - self.vStartPosition):Normalized()
	vDirection.z = 0.0
	self.vTargetPosition = self.hTarget:GetOrigin()

	self.hook_distance = (self.vEndPosition - self.vStartPosition):Length2D()

	local flFollowthroughDuration = ( self.hook_distance / self.hook_speed * self.hook_followthrough_constant )
	self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_meat_hook_followthrough_lua", { duration = flFollowthroughDuration } )

	self.vHookOffset = Vector( 0, 0, 96 )
	local vHookTarget = self.vTargetPosition + self.vHookOffset
	local vKillswitch = Vector( ( ( self.hook_distance / self.hook_speed ) * 2 ), 0, 0 )

	self.nChainParticleFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
	ParticleManager:SetParticleAlwaysSimulate( self.nChainParticleFXIndex )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", self:GetCaster():GetOrigin() + self.vHookOffset, true )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 1, vHookTarget )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 2, Vector( self.hook_speed, self.hook_distance, self.hook_width ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 3, vKillswitch )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 1, 0, 0 ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 0, 0, 0 ) )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 7, self:GetCaster(), PATTACH_CUSTOMORIGIN, nil, self:GetCaster():GetOrigin(), true )

	EmitSoundOn( "Hero_Pudge.AttackHookExtend", self:GetCaster() )

	-- local info = {
	-- 	Ability = self,
	-- 	vSpawnOrigin = self:GetCaster():GetOrigin(),
	-- 	vVelocity = vDirection:Normalized() * self.hook_speed,
	-- 	fDistance = self.hook_distance,
	-- 	fStartRadius = self.hook_width ,
	-- 	fEndRadius = self.hook_width ,
	-- 	Source = self:GetCaster(),
	-- 	iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
	-- 	iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	-- 	iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
	-- }

	-- ProjectileManager:CreateLinearProjectile( info )

	self.bRetracting = false
	self.hVictim = nil
	self.bDiedInHook = false

	Timers:CreateTimer((self.hook_distance / self.hook_speed),function()
		self:OnHookLanded( self.hTarget, self.hTarget:GetAbsOrigin() )
	end)

	Timers:CreateTimer((self.hook_distance / self.hook_speed * 2 + 0.1),function()
		if self:GetCaster() and self:GetCaster():IsHero() then
			local hHook = self:GetCaster():GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
			if hHook ~= nil then
				hHook:RemoveEffects( EF_NODRAW )
			end
		end

		-- if self.hTarget ~= nil then
		-- 	local vFinalHookPos = vLocation
		-- 	-- self.hTarget:InterruptMotionControllers( true )
		-- 	-- self.hTarget:RemoveModifierByName( "modifier_meat_hook_lua" )

		-- 	--结束被钩的移动！
		-- 	-- prt('结束移动：'..self.hTarget:GetUnitName())
		-- 	if self.hTarget.hook_cb ~= nil then
		-- 		self.hTarget.hook_cb(self:GetCaster())
		-- 	end

		-- 	-- local vVictimPosCheck = self.hVictim:GetOrigin() - vFinalHookPos 
		-- 	-- local flPad = self:GetCaster():GetPaddedCollisionRadius() + self.hVictim:GetPaddedCollisionRadius()
		-- 	-- if vVictimPosCheck:Length2D() > flPad then
		-- 	-- 	FindClearSpaceForUnit( self.hVictim, self.vStartPosition, false )
		-- 	-- end
		-- end

		self.hTarget = nil
		self.hVictim = nil
		ParticleManager:DestroyParticle( self.nChainParticleFXIndex, true )
		EmitSoundOn( "Hero_Pudge.AttackHookRetractStop", self:GetCaster() )
	end)
	
end

--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnHookLanded( hTarget, vLocation )
	
	-- if hTarget == self:GetCaster() or hTarget.is_moving == true then
	-- 	return false
	-- end

	-- if self.bRetracting == false then
	-- 	if hTarget ~= nil and ( not ( hTarget:IsCreep() or hTarget:IsConsideredHero() ) ) then
	-- 		Msg( "Target was invalid")
	-- 		return false
	-- 	end

	-- 	local bTargetPulled = false
		if hTarget ~= nil then
			EmitSoundOn( "Hero_Pudge.AttackHookImpact", hTarget )

	-- 		-- 被钩走
	-- 		hTarget:AddNewModifier( self:GetCaster(), self, "modifier_meat_hook_lua", nil )
			
			if hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
				local damage = {
						victim = hTarget,
						attacker = self:GetCaster(),
						damage = self.hook_damage,
						damage_type = DAMAGE_TYPE_PHYSICAL,		
						ability = this
					}

				ApplyDamage( damage )

	-- 			if not hTarget:IsAlive() then
	-- 				self.bDiedInHook = true
	-- 			end

				if not hTarget:IsMagicImmune() then
					hTarget:Interrupt()
				end
		
				local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf", PATTACH_CUSTOMORIGIN, hTarget )
				ParticleManager:SetParticleControlEnt( nFXIndex, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetOrigin(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
			end

			

	-- 		AddFOWViewer( self:GetCaster():GetTeamNumber(), hTarget:GetOrigin(), self.vision_radius, self.vision_duration, false )
	-- 		self.hVictim = hTarget
	-- 		bTargetPulled = true
		end

	-- 	local vHookPos = self.vTargetPosition
	-- 	local flPad = self:GetCaster():GetPaddedCollisionRadius()
	-- 	if hTarget ~= nil then
	-- 		vHookPos = hTarget:GetOrigin() 
	-- 		flPad = flPad + hTarget:GetPaddedCollisionRadius()
	-- 	end

	-- 	--Missing: Setting target facing angle
	-- 	local vVelocity = self.vStartPosition - vHookPos
	-- 	vVelocity.z = 0.0

	-- 	local flDistance = vVelocity:Length2D() - flPad
	-- 	vVelocity = vVelocity:Normalized() * self.hook_speed

		local info = {
			Ability = self,
			vSpawnOrigin = vHookPos,
			vVelocity = vVelocity,
			fDistance = flDistance,
			Source = self:GetCaster(),
		}

		ProjectileManager:CreateLinearProjectile( info )
		self.vProjectileLocation = vHookPos

		if hTarget ~= nil and ( not hTarget:IsInvisible() ) and bTargetPulled then
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin() + self.vHookOffset, true )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 0, 0, 0 ) )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 1, 0, 0 ) )
		else
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", self:GetCaster():GetOrigin() + self.vHookOffset, true);
		end

		EmitSoundOn( "Hero_Pudge.AttackHookRetract", hTarget )

		if self:GetCaster():IsAlive() then
			self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 );
			self:GetCaster():StartGesture( ACT_DOTA_CHANNEL_ABILITY_1 );
		end

	-- 	self.bRetracting = true
	-- -- else
	-- 	-- print('2222222')
	-- 	-- if self:GetCaster() and self:GetCaster():IsHero() then
	-- 	-- 	local hHook = self:GetCaster():GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
	-- 	-- 	if hHook ~= nil then
	-- 	-- 		hHook:RemoveEffects( EF_NODRAW )
	-- 	-- 	end
	-- 	-- end

	-- 	-- if self.hTarget ~= nil then
	-- 	-- 	local vFinalHookPos = vLocation
	-- 	-- 	self.hTarget:InterruptMotionControllers( true )
	-- 	-- 	self.hTarget:RemoveModifierByName( "modifier_meat_hook_lua" )

	-- 	-- 	--结束被钩的移动！（并没有执行到这？）
	-- 	-- 	print('结束移动：'..self.hTarget:GetUnitName())
	-- 	-- 	if self.hTarget.hook_cb ~= nil then
	-- 	-- 		self.hTarget.hook_cb()
	-- 	-- 	end

	-- 	-- 	-- local vVictimPosCheck = self.hVictim:GetOrigin() - vFinalHookPos 
	-- 	-- 	-- local flPad = self:GetCaster():GetPaddedCollisionRadius() + self.hVictim:GetPaddedCollisionRadius()
	-- 	-- 	-- if vVictimPosCheck:Length2D() > flPad then
	-- 	-- 	-- 	FindClearSpaceForUnit( self.hVictim, self.vStartPosition, false )
	-- 	-- 	-- end
	-- 	-- end

	-- 	-- self.hTarget = nil
	-- 	-- ParticleManager:DestroyParticle( self.nChainParticleFXIndex, true )
	-- 	-- EmitSoundOn( "Hero_Pudge.AttackHookRetractStop", self:GetCaster() )
	-- end

	-- return true
	return false
end

--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnProjectileThink( vLocation )
	self.vProjectileLocation = vLocation
end

--------------------------------------------------------------------------------

function pudge_meat_hook_lua:OnOwnerDied()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 );
	self:GetCaster():RemoveGesture( ACT_DOTA_CHANNEL_ABILITY_1 );
end

--------------------------------------------------------------------------------