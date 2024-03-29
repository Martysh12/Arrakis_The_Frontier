-- Serverside
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
-- When Hotfixing, tell people
BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(111,155,255),"init.lua ",Color(255,255,255),"reloaded!")]])
TFA_BASE_VERSION = 1337

-- MetaTables
_Ply = FindMetaTable("Player")
_Ply.Class = nil
_Ply.AlliedFrags = nil
_Ply.AlliedReady = nil

_ENTSTBL = FindMetaTable("Entity")
_ENTSTBL.DuneTeam = nil

-- Netstrings
util.AddNetworkString("ScoreManip")
util.AddNetworkString("Capture")
util.AddNetworkString("Decapture")
util.AddNetworkString("HarvesterManip")
util.AddNetworkString("PlyKill")
util.AddNetworkString("ClassSync")

-- Resources
resource.AddFile("materials/atreides.png")
resource.AddFile("materials/harkonnen.png")
resource.AddFile("materials/ability_grenade.png")
resource.AddFile("sound/arrakis_credits.mp3")
resource.AddFile("sound/arrakis_ambience.wav")
resource.AddFile("sound/arrakis_music.wav")
resource.AddFile("sound/grenade_recharged.wav")


-- Announcer Sounds
resource.AddFile("sound/announcers/default/1_ex_1.wav")
resource.AddFile("sound/announcers/default/1_ex_2.wav")
resource.AddFile("sound/announcers/default/1_ex_3.wav")
resource.AddFile("sound/announcers/default/1_win.wav")
resource.AddFile("sound/announcers/default/2_ex_1.wav")
resource.AddFile("sound/announcers/default/2_ex_2.wav")
resource.AddFile("sound/announcers/default/2_ex_3.wav")
resource.AddFile("sound/announcers/default/2_win.wav")

-- Sounds
resource.AddFile("resource/fonts/RobotoMono.ttf")
resource.AddFile("resource/fonts/Orbitron.ttf")
resource.AddFile("resource/fonts/Cairo.ttf")

-- Playermodel Setup
Atreides_PlyMDL = "models/player/swat.mdl"
Fremen_PlyMDL = "models/player/guerilla.mdl"
Harkonnen_PlyMDL = "models/ninja/rage_enforcer.mdl"
Sardaukar_PlyMDL = "models/player/combine_soldier.mdl"

-- Workshop Resource
--resource.AddWorkshop("2211859288") -- Crysis Weapons -- UNUSED
resource.AddWorkshop("1622006977") -- Harkonnen VTOL
resource.AddWorkshop("831680603") --  Simfphys APC
--resource.AddWorkshop("2334354896") -- Atreides/Fremen VTOLs -- UNUSED
resource.AddWorkshop("420970650") -- Darkes scifi weaponry
resource.AddWorkshop("415143062") --  TFA Redux
resource.AddWorkshop("848490709") -- TFA KF2 Melee
resource.AddWorkshop("223357888") -- Playermodel Harkonnen

-- This is the new .rakmap format
-- It allows to port vanilla maps to arrakis gamemode
-- It is modular

MapStore = {}
function ReadMapStore()
	local JSONData = file.Read("arrakis/maps/"..game.GetMap()..".rakmap")
	MapStore = util.JSONToTable(JSONData)
	print("Loading rakmap Mapstore Data...")
	PrintTable(MapStore)

end

-- This is the new .arastat format
-- It allows to nerf and buff weapons and entities at will
-- It is modular

StatStore = {}
function ReadStatStore(filename)
	local JSONData2 = file.Read(filename)
	StatStore = util.JSONToTable(JSONData2)
	print("Loading arastat file: "..filename)
	PrintTable(StatStore)
end

-- Read MapStore (rakmap) and StatStore (arastat)
ReadMapStore()
ReadStatStore("arrakis/config/default.arastat")


-- Build up mapdata
SPP = MapStore["SPP"]
SP_Vtols_Harkonnen = MapStore["Harkonnen"]["Vtols"]
SP_APC_Harkonnen = MapStore["Harkonnen"]["APCs"]
SP_Vtols_Atreides = MapStore["Atreides"]["Vtols"]
SP_APC_Atreides = MapStore["Atreides"]["APCs"]
SP_Harkonnen = MapStore["Harkonnen"]["PlySpawns"]
SP_Atreides = MapStore["Atreides"]["PlySpawns"]
SpicePos = MapStore["SpicefogPos"]
SP_HarkonnenBubble = MapStore["Harkonnen"]["PlySpawns"][1]
SP_AtreidesBubble = MapStore["Atreides"]["PlySpawns"][1]

-- Build up Vars
HarkonnenVtolEntIndexes = {}
AtreidesVtolEntIndexes = {}
AtreidesAPCEntIndexes = {}
HarkonnenAPCEntIndexes = {}
CapturingInProgress = {}
HarvesterWinners = {}
CapturingTable = {}
SPH = {}

local PInit = {}

-- Round Vars
RoundHasEnded = 0

-- Set Skyname
RunConsoleCommand("sv_skyname", "sky_day01_06")
RunConsoleCommand("sv_tfa_cmenu_key","27")
RunConsoleCommand("sv_tfa_attachments_enabled","1")
RunConsoleCommand("sfw_allow_advanceddamage", "1")

-- Set up CVARs
CVAR_CaptureTime = CreateConVar("dune_sv_capture_time", "5", FCVAR_NONE+FCVAR_NOTIFY, "Time needed to capture harvesters", 0.01)
CVAR_GrenadeCooldown = CreateConVar("dune_sv_grenade_cooldown", "7", FCVAR_NONE+FCVAR_NOTIFY, "The lower, the faster the Grenade recharges", 0.01)
CVAR_ShieldInterval = CreateConVar("dune_sv_recharge_interval", "0.1", FCVAR_NONE+FCVAR_NOTIFY, "The lower, the faster the shield recharges", 0.01)
CVAR_ShieldDelay = CreateConVar("dune_sv_recharge_delay", "1", FCVAR_NONE+FCVAR_NOTIFY, "The lower, the sooner the shield starts recharging", 0.1)
CVAR_Gamemode = CreateConVar("dune_sv_gamemode", "2", FCVAR_NONE+FCVAR_NOTIFY, "1 - DM; 2 - Spice Harvest", 1,2)
CVAR_Announcer = CreateConVar("dune_sv_announcer", "1", FCVAR_NONE+FCVAR_NOTIFY, "1 - On; 0 - Off", 0,1)
CVAR_AlliedNeeded = CreateConVar("dune_sv_allied_minfrags", "10", FCVAR_NONE+FCVAR_NOTIFY, "Minimum kills needed for allied race unlocking", 1,1000)
CVAR_AnnouncerVoice = CreateConVar("dune_sv_announcer_voice", "default", FCVAR_NONE+FCVAR_NOTIFY, "Folder name in sound/arrakis/announcers/<voice>; Default: default")

-- Spawn Protection
function CheckSpawnBubbles(iRadius)
	for k,v in pairs(ents.FindInSphere(SP_AtreidesBubble, iRadius)) do
		if v:IsPlayer() then
			if v:Team() == 2 && v:Health() > 0 then
				v:TakeDamage(5, v, v)
			end
		end	
	end
	for k,v in pairs(ents.FindInSphere(SP_HarkonnenBubble, iRadius)) do
		if v:IsPlayer() then
			if v:Team() == 1 && v:Health() > 0 then
				v:TakeDamage(5, v, v)
			end
		end	
	end
end

timer.Create("Dune_SpawnProtection",0.1,0,function() 
	CheckSpawnBubbles(6543) 
end)


-- Announcer
local function Announce(FileName)
	local sound
	local filter
	if SERVER then
		filter = RecipientFilter()
		filter:AddAllPlayers()
	end
	if SERVER or !LoadedSounds[FileName] then
		sound = CreateSound(game.GetWorld(), FileName, filter)
		if sound then
			sound:SetSoundLevel(0)
			if CLIENT then
				LoadedSounds[FileName] = {sound, filter}
			end
		end
	else
		sound = LoadedSounds[FileName][1]
		filter = LoadedSounds[FileName][2]
	end
	if sound then
		if CLIENT then
			sound:Stop()
		end
		sound:Play()
		sound:ChangeVolume(1)
	end
	return sound
end

-- Loadout
function GM:PlayerLoadout(ply)
	ply:SetArmor(100)
	ply:ShouldDropWeapon(1)
	timer.Simple(0.3, function() 
	    for k,v in pairs(ply:GetWeapons()) do
	    	if v:GetClass() == "tfa_bcry2_gauss" then
	    		ply:GiveAmmo(25,v:GetPrimaryAmmoType(),true)
	    	elseif v:GetClass() == "weapon_lfsmissilelauncher" then
	    		ply:GiveAmmo(5,v:GetPrimaryAmmoType(),true)
	    	else
	    		ply:GiveAmmo(150,v:GetPrimaryAmmoType(),true)
	    	end
	    end
	end)
	return true
end

-- Thx to Omni Games on YT!
function AutoBalance()
	if #team.GetPlayers(1) > #team.GetPlayers(2) then
		return 2
	elseif #team.GetPlayers(1) < #team.GetPlayers(2) then
		return 1
	else
		local KDR_Atreides = 0
		local KDR_Harkonnen = 0
		for k,v in pairs(team.GetPlayers(1)) do
			KDR_Atreides = KDR_Atreides + v:Frags()/v:Deaths()
		end
		KDR_Atreides = KDR_Atreides/#team.GetPlayers(1)

		for k,v in pairs(team.GetPlayers(2)) do
			KDR_Harkonnen = KDR_Harkonnen + v:Frags()/v:Deaths()
		end
		KDR_Harkonnen = KDR_Harkonnen/#team.GetPlayers(2)

		if KDR_Atreides > KDR_Harkonnen then
			--return 2
		elseif KDR_Atreides < KDR_Harkonnen then
			--return 1
		else
			--return math.random(0,1)
		end	
	end
end

-- Vehicles
-- Simfphys compatibility
function GM:PlayerButtonDown(ply, btn)
	numpad.Activate(ply, btn)
end
function GM:PlayerButtonUp(ply, btn)
	numpad.Deactivate(ply, btn)
end

local OldHarkonnenVtols = ents.FindByName("vtol_harkonnen")
for k, v in ipairs(OldHarkonnenVtols) do
	if(IsValid(v)) then
		v:Remove()
	end
end

local OldAtreidesVtols = ents.FindByName("vtol_atreides")
for k, v in ipairs(OldAtreidesVtols) do
	if(IsValid(v)) then
		v:Remove()
	end
end

local OldAtreidesAPCs = ents.FindByName("apc_atreides")
for k, v in ipairs(OldAtreidesAPCs) do
	if(IsValid(v)) then
		v:Remove()
	end
end

local OldHarkonnenAPCs = ents.FindByName("apc_atreides")
for k, v in ipairs(OldHarkonnenAPCs) do
	if(IsValid(v)) then
		v:Remove()
	end
end

-- Score Changer
function ManipScore(iTeam,iScore)
	if iTeam == 1 then
		ScoreAtreides = iScore
	elseif iTeam == 2 then
		ScoreHarkonnen = iScore
	end
	net.Start("ScoreManip")
		net.WriteInt(iTeam,32)
		net.WriteInt(iScore,32)
	net.Broadcast()
end

function WinHarvester(iTeam,iHarvester)
	HarvesterWinners[iHarvester] = iTeam
	HarvesterManip(iHarvester,iTeam)
	if CVAR_Announcer:GetInt() == 1 then
		local Announcement = [[announcers/]]..CVAR_AnnouncerVoice:GetString()..[[/]]..iTeam..[[_ex_]]..iHarvester..".wav"
		Announce(Announcement)
	end
	Decapture(1,1)
end

function Capture(iTeam,iHarvester)
	net.Start("Capture")
		net.WriteInt(iTeam,32)
		net.WriteInt(iHarvester,32)
	net.Broadcast()
	timer.Stop("CaptureStarter"..iHarvester)
	timer.Create("CaptureStarter"..iHarvester, CVAR_CaptureTime:GetFloat(), 1, function()
		WinHarvester(iTeam,iHarvester)
	end)
end

function Decapture(iTeam,iHarvester)
	net.Start("Decapture")
		net.WriteInt(iTeam,32)
		net.WriteInt(iHarvester,32)
	net.Broadcast()
end

function HarvesterManip(iTeam,iHarvester)
	net.Start("HarvesterManip")
		net.WriteInt(iHarvester,32)
		net.WriteInt(iTeam,32)
	net.Broadcast()
end

function ScanSpawnpoint(ply, vCorner1,radius1)
	local tEntities = ents.FindInSphere(vCorner1,radius1)
	local tPlayers = {}
	local iPlayers = 0
	
	for i = 1, #tEntities do
		if (tEntities[i]:IsPlayer() && tEntities[i] != ply) then
			iPlayers = iPlayers + 1
			tPlayers[iPlayers] = tEntities[i]
		end
	end
	
	return tPlayers, iPlayers
end

function ScanHarvester(vCorner1,radius1)
	local tEntities = ents.FindInSphere(vCorner1,radius1)
	local tPlayers = {}
	local iPlayers = 0
	
	for i = 1, #tEntities do
		if (tEntities[ i ]:IsPlayer()) then
			iPlayers = iPlayers + 1
			tPlayers[ iPlayers ] = tEntities[ i ]
		end
	end
	
	return tPlayers, iPlayers
end

timer.Create("HarvesterScan",0.3,0,function()
	Scores = {
		ScoreAtreides,
		ScoreHarkonnen
	}
	if CVAR_Gamemode:GetInt() != 2 then return end

		-- B - 1
		for k,v in pairs(SPP) do
			local A1 = v
			local People1 = ScanHarvester(A1,1500)
			if People1[1] && People1[1]:Team() != HarvesterWinners[k] && People1[1]:Alive() && People1[1]:Health() > 0 then
				if People1[2] && People1[2]:Team() == HarvesterWinners[k] && People1[2]:Alive() && People1[2]:Health() > 0 then
					return
				end
				if CapturingInProgress[k] == 0 then
					CapturingInProgress[k] = 1
					CapturingTable[k] = People1[1]:Team()
					Capture(People1[1]:Team(),k)
				end
			else
				CapturingInProgress[k] = 0
				CapturingTable[k] = 0
				timer.Stop("CaptureStarter"..k)
			end
		end

		local Empties = 0
		for xk,xv in pairs(CapturingTable) do
			if xv < 1 then Empties = Empties + 1 end
		end
		if Empties == #SPP then
			Decapture(1,1)
		end
end)



function SpawnVehiclesHarkonnen()
	local OldHarkonnenVtols = ents.FindByName("vtol_harkonnen")
	for k, v in ipairs(OldHarkonnenVtols) do
		if(IsValid(v)) then
			v:Remove()
		end
	end
	
	for k,v in pairs(SP_Vtols_Harkonnen) do
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(v)
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_harkonnen")
		VTOL:Spawn()
		VTOL.DuneTeam = 2
		VTOL:SetColor(Color(77,55,44))
		VTOL:SetAngles(Angle(0, -50, 0))
		HarkonnenVtolEntIndexes[k] = VTOL
	end
end

function MakeVtolAI()
	local AllVtols = ents.FindByClass("lfs_crysis_vtol")
	for k, v in ipairs(AllVtols) do
		if(IsValid(v)) && !v:GetDriver() then
			v:SetAI(true)
			v:SetAITEAM(3)
		end
	end

end
function SpawnVehiclesAtreides()
	local OldAtreidesVtols = ents.FindByName("vtol_atreides")
	for k, v in ipairs(OldAtreidesVtols) do
		if(IsValid(v)) then
			v:Remove()
		end
	end
	
	for k,v in pairs(SP_Vtols_Atreides) do
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(v)
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_atreides")
		VTOL:Spawn()
		VTOL.DuneTeam = 1
		VTOL:SetAngles(Angle(0, 170, 0))
		AtreidesVtolEntIndexes[k] = VTOL
	end
end

function RespawnVehiclesAtreides(vIndex)
	local OldAtreidesVtols = ents.FindByName("vtol_atreides")
	iCurAtreidesVtols = #OldAtreidesVtols

	local OldAtreidesAPCs = ents.FindByName("apc_atreides")
	iCurAtreidesAPCs = #OldAtreidesAPCs

	if !IsValid(AtreidesAPCEntIndexes[vIndex]) then
		local APC = simfphys.SpawnVehicleSimple("sim_fphys_conscriptapc_armed", SP_APC_Atreides[vIndex], Angle(0, 170, 0))
		APC:SetNWInt("apc_spawnpoint", k)
		APC:SetName("apc_atreides")
		APC.DuneTeam = 1
		AtreidesAPCEntIndexes[vIndex] = APC
	end

	if !IsValid(AtreidesVtolEntIndexes[vIndex]) then
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(SP_Vtols_Atreides[vIndex])
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_atreides")
		VTOL:Spawn()
		VTOL.DuneTeam = 1
		VTOL:SetAngles(Angle(0, 170, 0))
		AtreidesVtolEntIndexes[vIndex] = VTOL
	end
end

function RespawnVehiclesHarkonnen(vIndex)
	local OldHarkonnenVtols = ents.FindByName("vtol_harkonnen")
	iCurHarkonnenVtols = #OldHarkonnenVtols

	local OldHarkonnenAPCs = ents.FindByName("apc_harkonnen")
	iCurHarkonnenAPCs = #OldHarkonnenAPCs

	if !IsValid(HarkonnenAPCEntIndexes[vIndex]) then
		local APC = simfphys.SpawnVehicleSimple("sim_fphys_conscriptapc_armed", SP_APC_Harkonnen[vIndex], Angle(0, 170, 0))
		APC:SetNWInt("apc_spawnpoint", k)
		APC:SetName("apc_atreides")
		APC.DuneTeam = 2
		APC:SetColor(Color(155,122,111))
		HarkonnenAPCEntIndexes[vIndex] = APC
	end

	if !IsValid(HarkonnenVtolEntIndexes[vIndex]) then
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(SP_Vtols_Harkonnen[vIndex])
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_harkonnen")
		VTOL:Spawn()
		VTOL.DuneTeam = 2
		VTOL:SetColor(Color(77,55,44))
		VTOL:SetAngles(Angle(0, -50, 0))
		HarkonnenVtolEntIndexes[vIndex] = VTOL
	end
end

if timer.Exists("Dune_VehicleLoop") == false then
	timer.Create("Dune_VehicleLoop",11,0,function()
		for k,v in pairs(SP_Vtols_Atreides) do
			RespawnVehiclesAtreides(k)
		end
		for k,v in pairs(SP_Vtols_Harkonnen) do
			RespawnVehiclesHarkonnen(k)
		end
	end)
end

timer.Create("Dune_Announce1",556,0,function()
	BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(200,200,200),"To change team, use the console command: dune_team")]])
end)
timer.Create("Dune_Announce2",851,0,function()
	BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(200,200,200),"To join the Discord: https://discord.gg/XgbQrB7SJ7")]])
end)
timer.Create("Dune_Announce3",720,0,function()
	BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(200,200,200),"Remember: Moving into Enemy Spawns will weaken you!")]])
end)
timer.Create("Dune_Announce4",934,0,function()
	BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(200,200,200),"This is early access, please help us create a community and tell your friends if you like the gamemode! :)")]])
end)

-- Spawning Spice Harvesters
function SpawnHarvesters()
	for k,v in pairs(SPH) do
		if IsValid(SPH[k]) then
			SPH[k]:Remove()
		end
	end
	for k,v in pairs(SPP) do
		SPH[k] = ents.Create("prop_thumper")
		SPH[k]:SetRenderMode(RENDERMODE_TRANSALPHA)
		SPH[k]:SetColor(Color(255,190,111,255))
		SPH[k]:SetAngles(Angle(0,0,0))
		SPH[k]:Fire("Enable")
		local Harvester = SPH[k]
		Harvester:SetModelScale(5, 0)
		Harvester:SetPos(v)
		Harvester:Activate()
		Harvester:Spawn()
		Harvester:SetNWInt("harvester_id",k)
		Harvester:SetSolid(2)
		Harvester:SetName("dune_spiceharvester")
		Harvester:SetMaterial("valk/crysis/vehicles/vtol/vtol_hull")
		Harvester:SetMoveType(MOVETYPE_NONE)
		CapturingInProgress[k] = 0
		PrintTable(CapturingInProgress)
	end
end

function GM:PostGamemodeLoaded()
	timer.Simple(1,function() 
		SpawnVehiclesAtreides()
		SpawnVehiclesHarkonnen()
		SpawnHarvesters()
	end)
	if timer.Exists("Dune_VehicleLoop") == false then
		timer.Create("Dune_VehicleLoop",3,0,function()
			for ix=1,3 do
				RespawnVehiclesAtreides(ix)
				RespawnVehiclesHarkonnen(ix)

			end
		end)
	end
	SpawnSpiceFog()	
end

-- Spice Smokestack
function SpawnSpiceFog()
	if IsValid(Spicestack) then 
		Spicestack:Remove()
	end
	Spicestack = ents.Create("env_smokestack")
	Spicestack:SetKeyValue("SmokeMaterial","particle/smokesprites_0002.vmt")
	Spicestack:SetKeyValue("StartSize","12595")
	Spicestack:SetKeyValue("EndSize","13510")
	Spicestack:SetKeyValue("Rate","1")
	Spicestack:SetKeyValue("Speed","680")
	Spicestack:SetKeyValue("SpreadSpeed","11600")
	Spicestack:SetKeyValue("JetLength","14500")
	Spicestack:SetKeyValue("Twist","33")
	Spicestack:SetKeyValue("InitialState","1")
	Spicestack:SetKeyValue("rendercolor","222 222 165")
	Spicestack:SetKeyValue("renderamt","55")

	Spicestack:Spawn()
	Spicestack:Activate()
	Spicestack:SetPos(SpicePos)
	Spicestack:Fire("TurnOn")
end

-- Killmsgs
local SuicideFunnies = {
	"tried eating sand.",
	"wiped their ass with spice.",
	"thought he was a VTOL.",
	"didn't have the high ground.",
	"was unborn.",
	"thought he was in godmode.",
	"ate a shoe.",
	"paid a visit to heaven.",
	"got eaten by the gits.",
	"got run over by a Toyota Corolla."
}

-- DM Score
hook.Add("PlayerDeath", "DMScore", function(victim, inflictor, attacker)
	victim.Class = 0
	if attacker:IsPlayer() && attacker != victim then
		if attacker.AlliedFrags == nil then
			attacker.AlliedFrags = 1
		else
			attacker.AlliedFrags = attacker.AlliedFrags + 1
			if (attacker.AlliedFrags > (CVAR_AlliedNeeded:GetInt() -1)) && attacker.AlliedReady != 1 then
				attacker:SendLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]:" ,Color(111,255,155)," ]].."You unlocked one spawn as allied race!"..[[")]])
				attacker:SendLua([[AlliedReady = 1]])
				attacker.AlliedReady = 1

			end
		end
	end
	net.Start("PlyKill")
		net.WriteEntity(victim)
		if !attacker:IsVehicle() then
			net.WriteEntity(attacker)
		else
			net.WriteEntity(attacker:GetDriver())
		end
		net.WriteString(SuicideFunnies[math.random(#SuicideFunnies)])
	net.Broadcast()
	victim:ConCommand("dune_class")
	if CVAR_Gamemode:GetInt() != 1 || victim == attacker || !attacker:IsPlayer() then return end
	if attacker:Team() == 1 then
		ManipScore(1,ScoreAtreides+1)
	elseif attacker:Team() == 2 then
		ManipScore(2,ScoreHarkonnen+1)
	end

end)

-- Factions
function jAtreides(ply)
	ply:StripAmmo()
	ply:ExitVehicle()
	ply:StripWeapons()
    ply:SetTeam(1)
    ply:Spawn()
end 

function jHarkonnen(ply)
	ply:StripAmmo()
	ply:ExitVehicle()
	ply:StripWeapons()
    ply:SetTeam(2)
    ply:Spawn()
end 

function jAtreidesPLY(ply)
	ply:StripAmmo()
	ply:ExitVehicle()
	ply:StripWeapons()
    ply:SetTeam(1)
    ply:Spawn()
	Rebalance()
end 
 
function jHarkonnenPLY(ply)
	ply:StripAmmo()
	ply:ExitVehicle()
	ply:StripWeapons()
    ply:SetTeam(2)
    ply:Spawn()
	Rebalance()
end 

concommand.Add("dune_join_atreides", jAtreidesPLY)
concommand.Add("dune_join_harkonnen", jHarkonnenPLY)
concommand.Add("dune_setclass", function(ply,cmd,args) 
	D_SetClass(ply,args[1])
end)

-- Class setter
function D_SetClass(ply,_classId)
	local classId = tonumber(_classId)
	local ClassNotAvailable = "You can only hire the allied race if you have at least "..CVAR_AlliedNeeded:GetInt().." kills!"
	if classId == 4 && ply.AlliedReady != 1 then
		ply:SendLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]:" ,Color(255,111,111)," ]]..ClassNotAvailable..[[")]])
		ply:ConCommand("dune_class")
	end
	if classId == 4 && ply.AlliedReady == 1 then
		ply.AlliedFrags = 0
		ply.Class = classId
		ply:SendLua([[AlliedReady = 0]])
		ply.AlliedReady = 0
	elseif classId == 3 then
		ply.Class = classId
	elseif classId == 2 then
		ply.Class = classId
	elseif classId == 1 then
		ply.Class = classId
	end
	ply:Spawn()
	SyncHUD()
end

function _Ply:GetUnitClass()
	return self.Class
end

-- Chatlog Helper
function ChatAdd(type,message,args)
	if type == "JL" then
		BroadcastLua([[chat.AddText(Color(255,155,50),"[SERVER]: ",Color(255,200,100),"]]..args..[[",Color(255,255,255),"]]..message..[[")]])
	elseif type == "TEAMCHANGE" then
		if args[1] == 1 then
			BroadcastLua([[chat.AddText(Color(255,155,50),"[SERVER]: ",Color(255,200,100),"]]..args[2]..[[",Color(111,200,155),"]]..message..[[")]])
		elseif args[1] == 2 then
			BroadcastLua([[chat.AddText(Color(255,155,50),"[SERVER]: ",Color(255,200,100),"]]..args[2]..[[",Color(155,55,11),"]]..message..[[")]])
		end
	elseif type == "LOG" then
			BroadcastLua([[chat.AddText(Color(255,155,50),"[SERVER]:" ,Color(111,200,155),"]]..message..[[")]])
	end
end

-- Spawn
hook.Add("PlayerSpawn","Dune_Spawn",function(ply)
	if ply:Team() == 1 then
		Reposition1(ply)
		ply:SetEyeAngles(Angle(0, 170, 0))
	elseif ply:Team() == 2 then
		Reposition2(ply)
		ply:SetEyeAngles(Angle(0, -50, 0))
	end
end)

function Reposition1(ply)
	ply:SetPos(SP_Atreides[math.random(#SP_Atreides)])
	if ScanSpawnpoint(ply,ply:GetPos(),5)[1] then
		ply:SetPos(ply:GetPos()+Vector(math.random(-200, 200),math.random(-200, 200),100))
	end
end

function Reposition2(ply)
	ply:SetPos(SP_Harkonnen[math.random(#SP_Harkonnen)])
	if ScanSpawnpoint(ply,ply:GetPos(),5)[1] then
		ply:SetPos(ply:GetPos()+Vector(math.random(-200, 200),math.random(-200, 200),100))
	end
end

hook.Add("PlayerInitialSpawn","Dune_JL",function(ply)
	ChatAdd("JL"," joined the Battlefield!",ply:Nick())
	ply:ConCommand("sfw_allow_advanims 0")
	ply:ConCommand("sfw_allow_viewbob 0")
	ply:ConCommand("sfw_allow_viewsway 0")
	ply:ConCommand("sfw_allow_recoiltoaimvector 1")
	ply:ConCommand("sfw_precachemethod 1")
	ply:ConCommand("dune_team")
end)

hook.Add("PlayerDisconnected", "Dune_JL_Disconnect", function(ply)
    ChatAdd("JL"," has left arrakis!",ply:Nick())
end)

function Rebalance()
	for k,v in pairs(player.GetAll()) do
		if AutoBalance() == 1 then
			jAtreides(v)
		else
			jHarkonnen(v)
		end
	end
end

function SyncHUD()
	for k,v in pairs(HarvesterWinners) do
		HarvesterManip(k,v)
	end
	for k,v in pairs(player.GetAll()) do
		net.Start("ClassSync")
			net.WriteEntity(v)
			net.WriteInt(v.Class, 32)
		net.Broadcast()
	end
end

gameevent.Listen("OnRequestFullUpdate")

hook.Add("OnRequestFullUpdate", "Dune_JL2", function(t)
	if not PInit[t.userid] then
		PInit[t.userid] = true
		Player(t.userid):SendLua([[SPlayAmbience()]])
		Player(t.userid).CanGrenade = true
		Player(t.userid):SendLua([[Player(]]..Player(t.userid):UserID()..[[).CanGrenade = true]])
		Player(t.userid):SendLua([[Abilities.GrenadeCoolBar = 1]])
		SyncHUD()
	else
		return
	end
end)


function GM:PlayerShouldTakeDamage(ply,attacker)
	return attacker:GetClass() == "npc_grenade_frag" || ply == attacker || attacker:IsPlayer() && ply:Team() != attacker:Team() || attacker:IsVehicle() && ply:Team() != attacker:GetDriver():Team()
end

hook.Add("EntityTakeDamage", "DMGStats", function(target, dmginfo)
	if dmginfo:IsExplosionDamage() && !dmginfo:GetAttacker():IsVehicle() then
		dmginfo:ScaleDamage(3)
	end
	
	for k, v in pairs(StatStore["weapons"]) do
		if (dmginfo:GetAttacker():IsPlayer() && dmginfo:GetAttacker():GetActiveWeapon():GetClass() == k) then
			dmginfo:ScaleDamage(v["damage"])
		end
	end
end)

function GM:PlayerSetModel(ply)
	ply:StripAmmo()
	ply:ExitVehicle()
	ply:StripWeapons()
	if ply:Team() != 1 && ply:Team() != 2 then 
		ply:SetModel("models/effects/teleporttrail_alyx.mdl")
		ply:SetPos(Vector(0,0,-31110))
	end
	if ply:Team() == Atreides then
		if ply.Class == 1 then
			ply:Give("tfa_kf2_katana") --melee sword
		    ply:Give("sfw_lapis") --pistol
		    ply:Give("sfw_hwave") --rifle
		elseif ply.Class == 2 then
			ply:Give("tfa_kf2_katana") --melee sword
		    ply:Give("sfw_lapis") --pistol
		    ply:Give("sfw_phoenix") --sniper
		elseif ply.Class == 3 then
			ply:Give("tfa_kf2_katana") --melee sword
		    ply:Give("sfw_behemoth") --heavy
		    ply:Give("weapon_lfsmissilelauncher") -- Rocket Launcher
		elseif ply.Class == 4 then
			ply:Give("sfw_dartgun") -- Pistol
			ply:Give("sfw_aquamarine") -- Carbine
			--ply:Give("sfw_pulsar") -- Sniper
			ply:Give("sfw_storm") -- Shotgun
		end

		if ply.Class != 4 then
	    	ply:SetModel(Atreides_PlyMDL)
		else
			ply:SetModel(Fremen_PlyMDL)
		end

	elseif ply:Team() == Harkonnen then
		if ply.Class == 1 then
		    ply:Give("tfa_kf2_pulverizer") --melee hammer
		    ply:Give("sfw_corruptor") --pistol
		  	ply:Give("sfw_vk21") -- rifle without loop glitch til fix
		elseif ply.Class == 2 then
		    ply:Give("tfa_kf2_pulverizer") --melee hammer
		    ply:Give("sfw_phoenix") --sniper
		    ply:Give("sfw_corruptor") --pistol
		elseif ply.Class == 3 then
		    ply:Give("tfa_kf2_pulverizer") --melee hammer
		  	ply:Give("sfw_grinder") --heavy
		  	ply:Give("weapon_lfsmissilelauncher") -- Rocket Launcher
		elseif ply.Class == 4 then
			ply:Give("sfw_ember") -- Pistol
			ply:Give("sfw_draco") -- Carbine
			--ply:Give("sfw_hellfire") -- Special
			ply:Give("sfw_seraphim") -- Shotgun
		end

		if ply.Class != 4 then
	    	ply:SetModel(Harkonnen_PlyMDL)
			ply:SetSkin(0)
		else
			ply:SetModel(Sardaukar_PlyMDL)
			ply:SetSkin(1)
		end

	end
end
function GM:PlayerHurt(victim, attacker)
	timer.Stop("Recharge_"..victim:SteamID())
	timer.Stop("Recharge_Starter_"..victim:SteamID())
	timer.Create("Recharge_Starter_"..victim:SteamID(), CVAR_ShieldDelay:GetFloat(), 1, function() 
		if victim:Armor() == 0 then
			timer.Create("Recharge_"..victim:SteamID(), CVAR_ShieldInterval:GetFloat(), 100, function() 
				victim:SetArmor(victim:Armor()+1)
			end)
		else
			timer.Create("Recharge_"..victim:SteamID(), CVAR_ShieldInterval:GetFloat(), 100-victim:Armor(), function() 
				victim:SetArmor(victim:Armor()+1)
			end)
		end
	end)
end

-- Round End
function WinRound(iTeam)
	if RoundHasEnded == 1 then return end
	RoundHasEnded = 1
	BroadcastLua("WinRound("..iTeam..")")
	if CVAR_Announcer:GetInt() == 1 then
		local Announcement = [[announcers/]]..CVAR_AnnouncerVoice:GetString()..[[/]]..iTeam..[[_win]]..".wav"
		Announce(Announcement)
	end
	timer.Simple(7,function()
		game.ConsoleCommand("changelevel " .. game.GetMap() ..  "\n")
	end)
end

-- Spice Counter
timer.Create("SP_Countspice",0.5,0,function()
	if RoundHasEnded == 1 then return end
	local SpiceProduction = {0,0}
	for k,v in pairs(HarvesterWinners) do
		if v == 1 then
			if SpiceProduction[v] == 0 then 
				SpiceProduction[v] = 2
			else
				SpiceProduction[v] = SpiceProduction[v] *2
			end
			if Scores[v] < 5000 then
				ManipScore(v,Scores[v]+SpiceProduction[v])
			else
				Scores[v] = 5000
				WinRound(1)
			end
		end
		if v == 2 then
			if SpiceProduction[v] == 0 then 
				SpiceProduction[v] = 2
			else
				SpiceProduction[v] = SpiceProduction[v] *2
			end
			if Scores[v] < 5000 then
				ManipScore(v,Scores[v]+SpiceProduction[v])
			else
				Scores[v] = 5000
				WinRound(2)
			end
		end
	end
end)

-- Use Protection
hook.Add("PlayerUse", "Dune_UseProtection", function(ply, ent)
	if ent.DuneTeam != nil && ply:Team() != ent.DuneTeam then
		return false
	end
end)
