-- R6 animations for R15 Characters with custom tweaks
-- Modified to be unique for a new project
-- Created by [TraxHax]

local player = game:GetService("Players").LocalPlayer

function CustomizeAnimation(Character)
	if Character:WaitForChild("Animate") ~= nil then
		Character.Animate.Disabled = true
	end
	
	Character:WaitForChild("Humanoid")

	for _, track in next, Character.Humanoid:GetPlayingAnimationTracks() do
		track:Stop()
	end

	local customScript = Character.Animate

	local Humanoid = Character:WaitForChild("Humanoid")
	local pose = "Standing"

	local UserGameSettings = UserSettings():GetService("UserGameSettings")

	local userNoUpdateOnLoop = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop") end)

	local AnimationSpeedDampeningObject = customScript:FindFirstChild("ScaleDampeningPercent")
	local HumanoidHipHeight = 2

	local humanoidSpeed = 0
	local cachedRunningSpeed = 0
	local cachedLocalDirection = {x=0.0, y=0.0}
	local smallButNotZero = 0.0001
	local runBlendtime = 0.2
	local lastLookVector = Vector3.new(0.0, 0.0, 0.0)
	local lastBlendTime = 0
	local WALK_SPEED = 6.4
	local RUN_SPEED = 12.8

	local EMOTE_TRANSITION_TIME = 0.1

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0

	local PreloadedAnims = {}

	local animTable = {}
	local animNames = { 
		idle = 	{
			{ id = "http://www.roblox.com/asset/?id=12521158637", weight = 9 },
			{ id = "http://www.roblox.com/asset/?id=12521162526", weight = 1 },
		},
		walk = 	{
			{ id = "http://www.roblox.com/asset/?id=12518152696", weight = 10 }
		},
		run = 	{
			{ id = "http://www.roblox.com/asset/?id=12518152696", weight = 10 } 
		},
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=12520880485", weight = 10 }
		},
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=12520972571", weight = 10 }
		},
		climb = {
			{ id = "http://www.roblox.com/asset/?id=12520982150", weight = 10 }
		},
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=12520993168", weight = 10 }
		},
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=12520996634", weight = 10 }
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=12520999032", weight = 10 }
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=12521002003", weight = 10 }
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=12521004586", weight = 10 }
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=12521007694", weight = 10 }
		},
		dance = {
			{ id = "http://www.roblox.com/asset/?id=12521009666", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521151637", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521015053", weight = 10 }
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=12521169800", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521173533", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521027874", weight = 10 }
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=12521178362", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521181508", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521184133", weight = 10 }
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=12521018724", weight = 10 }
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=12521021991", weight = 10 }
		},
	}

	local strafingLocomotionMap = {}
	local fallbackLocomotionMap = {}
	local locomotionMap = strafingLocomotionMap
	local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	math.randomseed(tick())

	function configureAnimationSet(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0
		animTable[name].connections = {}

		if name == "run" or name == "walk" then
			local speed = name == "run" and RUN_SPEED or WALK_SPEED
			fallbackLocomotionMap[name] = {lv=Vector2.new(0.0, speed), speed = speed}
			locomotionMap = fallbackLocomotionMap
		end

		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
			end
		end

		for i, animType in pairs(animTable) do
			for idx = 1, animType.count, 1 do
				if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
					Humanoid:LoadAnimation(animType[idx].anim)
					PreloadedAnims[animType[idx].anim.AnimationId] = true
				end
			end
		end
	end

	function scriptChildModified(child)
		local fileList = animNames[child.Name]
		if (fileList ~= nil) then
			configureAnimationSet(child.Name, fileList)
		end	
	end

	customScript.ChildAdded:connect(scriptChildModified)
	customScript.ChildRemoved:connect(scriptChildModified)

	local animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
	if animator then
		local animTracks = animator:GetPlayingAnimationTracks()
		for _, track in ipairs(animTracks) do
			track:Stop(0)
			track:Destroy()
		end
		animTracks = nil
	end

	for name, fileList in pairs(animNames) do
		configureAnimationSet(name, fileList)
	end

	function stopAllAnimations()
		local oldAnim = currentAnim

		if currentlyPlayingEmote then
			oldAnim = "idle"
			currentlyPlayingEmote = false
		end

		currentAnim = ""
		currentAnimInstance = nil
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end

		for _,v in pairs(locomotionMap) do
			if v.track then
				v.track:Stop()
				v.track:Destroy()
				v.track = nil
			end
		end

		return oldAnim
		end

		function playAnimation(animName, transitionTime, humanoid)
			local idx = rollAnimation(animName)
			local anim = animTable[animName][idx].anim

			switchToAnim(anim, animName, transitionTime, humanoid)
			currentlyPlayingEmote = false
		end

		function playEmote(emoteAnim, transitionTime, humanoid)
			switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
			currentlyPlayingEmote = true
		end

		local toolAnim = "None"
		local toolAnimTime = 0

		local jumpAnimTime = 0
		local jumpAnimDuration = 0.31

		local toolTransitionTime = 0.1
		local fallTransitionTime = 0.2

		local currentlyPlayingEmote = false

		function toolKeyFrameReachedFunc(frameName)
			if (frameName == "End") then
				playToolAnimation(toolAnimName, 0.0, Humanoid)
			end
		end

		function playToolAnimation(animName, transitionTime, humanoid, priority)
			local idx = rollAnimation(animName)
			local anim = animTable[animName][idx].anim

			if (toolAnimInstance ~= anim) then
				if (toolAnimTrack ~= nil) then
					toolAnimTrack:Stop()
					toolAnimTrack:Destroy()
					transitionTime = 0
				end

				toolAnimTrack = humanoid:LoadAnimation(anim)
				if priority then
					toolAnimTrack.Priority = priority
				end

				toolAnimTrack:Play(transitionTime)
				toolAnimName = animName
				toolAnimInstance = anim

				currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
			end
		end

		function stopToolAnimations()
			local oldAnim = toolAnimName

			if (currentToolAnimKeyframeHandler ~= nil) then
				currentToolAnimKeyframeHandler:disconnect()
			end

			toolAnimName = ""
			toolAnimInstance = nil
			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				toolAnimTrack = nil
			end

			return oldAnim
		end

		function onRunning(speed)
			local movedDuringEmote = currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
			local speedThreshold = movedDuringEmote and Humanoid.WalkSpeed or 0.75
			humanoidSpeed = speed
			if speed > speedThreshold then
				playAnimation("walk", 0.2, Humanoid)
				if pose ~= "Running" then
					pose = "Running"
					updateVelocity(0)
				end
			else
				if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
					playAnimation("idle", 0.2, Humanoid)
					pose = "Standing"
				end
			end
		end

		function onDied()
			pose = "Dead"
		end

		function onJumping()
			playAnimation("jump", 0.1, Humanoid)
			jumpAnimTime = jumpAnimDuration
			pose = "Jumping"
		end

		function onClimbing(speed)
			local scale = 5.0
			playAnimation("climb", 0.1, Humanoid)
			setAnimationSpeed(speed / scale)
			pose = "Climbing"
		end

		function onGettingUp()
			pose = "GettingUp"
		end

		function onFreeFall()
			if (jumpAnimTime <= 0) then
				playAnimation("fall", fallTransitionTime, Humanoid)
			end
			pose = "FreeFall"
		end

		function onFallingDown()
			pose = "FallingDown"
		end

		function onSeated()
			pose = "Seated"
		end

		function onPlatformStanding()
			pose = "PlatformStanding"
		end

		function onSwimming(speed)
			if speed > 0 then
				pose = "Running"
			else
				pose = "Standing"
			end
		end

		function animateTool()
			if (toolAnim == "None") then
				playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
				return
			end

			if (toolAnim == "Slash") then
				playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
				return
			end

			if (toolAnim == "Lunge") then
				playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
				return
			end
		end

		function getToolAnim(tool)
			for _, c in ipairs(tool:GetChildren()) do
				if c.Name == "toolanim" and c.className == "StringValue" then
					return c
				end
			end
			return nil
		end

		local lastTick = 0

		function stepAnimate(currentTime)
			local amplitude = 1
			local frequency = 1
			local deltaTime = currentTime - lastTick
			lastTick = currentTime

			local climbFudge = 0
			local setAngles = false

			if (jumpAnimTime > 0) then
				jumpAnimTime = jumpAnimTime - deltaTime
			end

			if (pose == "FreeFall" and jumpAnimTime <= 0) then
				playAnimation("fall", fallTransitionTime, Humanoid)
			elseif (pose == "Seated") then
				playAnimation("sit", 0.5, Humanoid)
				return
			elseif (pose == "Running") then
				playAnimation("walk", 0.2, Humanoid)
				updateVelocity(currentTime)
			elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
				stopAllAnimations()
				amplitude = 0.1
				frequency = 1
				setAngles = true
			end

			local tool = Character:FindFirstChildOfClass("Tool")
			if tool and tool:FindFirstChild("Handle") then
				local animStringValueObject = getToolAnim(tool)

				if animStringValueObject then
					toolAnim = animStringValueObject.Value
					animStringValueObject.Parent = nil
					toolAnimTime = currentTime + .3
				end

				if currentTime > toolAnimTime then
					toolAnimTime = 0
					toolAnim = "None"
				end

				animateTool()
			else
				stopToolAnimations()
				toolAnim = "None"
				toolAnimInstance = nil
				toolAnimTime = 0
			end
		end

	Humanoid.Died:connect(onDied)
	Humanoid.Running:connect(onRunning)
	Humanoid.Jumping:connect(onJumping)
	Humanoid.Climbing:connect(onClimbing)
	Humanoid.GettingUp:connect(onGettingUp)
	Humanoid.FreeFalling:connect(onFreeFall)
	Humanoid.FallingDown:connect(onFallingDown)
	Humanoid.Seated:connect(onSeated)
	Humanoid.PlatformStanding:connect(onPlatformStanding)
	Humanoid.Swimming:connect(onSwimming)

	game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
		local emote = ""
		if (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
		end
	end)

	customScript:WaitForChild("PlayEmote").OnInvoke = function(emote)
		if pose ~= "Standing" then
			return
		end

		if emoteNames[emote] ~= nil then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)

			return true, currentAnimTrack
		elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
			playEmote(emote, EMOTE_TRANSITION_TIME, Humanoid)

			return true, currentAnimTrack
		end

		return false
	end

	if Character.Parent ~= nil then
		playAnimation("idle", 0.1, Humanoid)
		pose = "Standing"
	end

	task.spawn(function()
		while Character.Parent ~= nil do
			local _, currentGameTime = wait(0.1)
			stepAnimate(currentGameTime)
		end
	end)
end

CustomizeAnimation(player.Character)

player.CharacterAdded:Connect(function(Character)
	CustomizeAnimation(Character)
end)
