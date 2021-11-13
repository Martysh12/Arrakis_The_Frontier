-- Serverside
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
-- When Hotfixing, tell people
BroadcastLua([[chat.AddText(Color(255,155,50),"[Arrakis: The Frontier]: ",Color(111,155,255),"init.lua ",Color(255,255,255),"reloaded!")]])

-- Resources
resource.AddFile("materials/atreides.png")
resource.AddFile("materials/harkonnen.png")
resource.AddFile("materials/ability_grenade.png")
resource.AddFile("sound/arrakis_credits.mp3")
resource.AddFile("sound/arrakis_ambience.wav")

-- Set Skyname
RunConsoleCommand("sv_skyname", "sky_day01_06")

-- Disable C Menu of TFA
RunConsoleCommand("sv_tfa_cmenu",0)

-- Set up CVARs
CVAR_ShieldInterval = CreateConVar( "dune_sv_recharge_interval", "0.1", FCVAR_NONE, "The lower, the faster the shield recharges", 0.01)
CVAR_ShieldDelay = CreateConVar( "dune_sv_recharge_delay", "1", FCVAR_NONE, "The lower, the sooner the shield starts recharging", 0.1)

-- Loadout
function GM:PlayerLoadout(ply)
	ply:SetArmor(100)
	return true
end

-- Vehicles

-- Simfphys compatibility
function GM:PlayerButtonDown( ply, btn )
	numpad.Activate( ply, btn )
end
function GM:PlayerButtonUp( ply, btn )
	numpad.Deactivate( ply, btn )
end
-- When Hotfixing
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

-- Spawners
HarkonnenVtolEntIndexes = {}

AtreidesVtolEntIndexes = {}
AtreidesAPCEntIndexes = {}

SP_Vtols_Harkonnen = {
	Vector(-12988.833984, 10670.055664, -9034.481445),
	Vector(-11978.709961, 10691.329102, -9012.096680),
	Vector(-11006.250000, 11011.807617, -8930.311523),
}

SP_Vtols_Atreides = {
	Vector(11965.055664, -6706.582520, -9968.274414),
	Vector(11477.743164, -7800.555176, -9969.972656),
	Vector(12658.222656, -8133.210938, -9965.285156),
}

SP_APC_Atreides = {
	Vector(11891.732422, -6082.339355, -10317.850586),
	Vector(12891.853516, -6182.138184, -10342.645508),
	Vector(14891.222656, -8282.210938, -9935.285156),
}

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
		VTOL:SetColor(Color(77,55,44))
		VTOL:SetAngles(Angle(0, -50, 0))
		HarkonnenVtolEntIndexes[k] = VTOL
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
		VTOL:SetAngles(Angle(0, 170, 0))
		AtreidesVtolEntIndexes[k] = VTOL
	end
end

function RespawnVehiclesAtreides(vIndex)
	--sim_fphys_cogtank
	
	local OldAtreidesVtols = ents.FindByName("vtol_atreides")
	iCurAtreidesVtols = table.Count(OldAtreidesVtols)

	local OldAtreidesAPCs = ents.FindByName("apc_atreides")
	iCurAtreidesAPCs = table.Count(OldAtreidesAPCs)

	if !IsValid(AtreidesAPCEntIndexes[vIndex]) then
		local APC = simfphys.SpawnVehicleSimple("sim_fphys_tank_cell_apc", SP_APC_Atreides[vIndex], Angle(0, 170, 0))
		APC:SetNWInt("apc_spawnpoint", k)
		APC:SetName("apc_atreides")
		AtreidesAPCEntIndexes[vIndex] = APC
	end

	if !IsValid(AtreidesVtolEntIndexes[vIndex]) then
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(SP_Vtols_Atreides[vIndex])
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_atreides")
		VTOL:Spawn()
		VTOL:SetAngles(Angle(0, 170, 0))
		AtreidesVtolEntIndexes[vIndex] = VTOL
	end
end

function RespawnVehiclesHarkonnen(vIndex)
	local OldHarkonnenVtols = ents.FindByName("vtol_harkonnen")
	iCurHarkonnenVtols = table.Count(OldHarkonnenVtols)

	if !IsValid(HarkonnenVtolEntIndexes[vIndex]) then
		local VTOL = ents.Create("lfs_crysis_vtol")
		VTOL:SetPos(SP_Vtols_Harkonnen[vIndex])
		VTOL:SetNWInt("vtol_spawnpoint", k)
		VTOL:SetName("vtol_harkonnen")
		VTOL:Spawn()
		VTOL:SetColor(Color(77,55,44))
		VTOL:SetAngles(Angle(0, -50, 0))
		HarkonnenVtolEntIndexes[vIndex] = VTOL
	end
end

timer.Create("Dune_VehicleLoop",11,0,function()
	for k,v in pairs(SP_Vtols_Atreides) do
		RespawnVehiclesAtreides(k)
	end
	for k,v in pairs(SP_Vtols_Harkonnen) do
		RespawnVehiclesHarkonnen(k)
	end
end)

function GM:PostGamemodeLoaded()
	timer.Simple(1,function() 
		SpawnVehiclesAtreides()
		SpawnVehiclesHarkonnen()
	end)
	timer.Create("Dune_VehicleLoop",3,0,function()
		for ix=1,3 do
			RespawnVehiclesAtreides(ix)
		end
	end)
end

-- Factions
function jAtreides( ply ) 
	ply:StripAmmo()
	ply:StripWeapons()
    ply:SetTeam(1)
    ply:Spawn()
    ChatAdd("TEAMCHANGE"," joined House Atreides!",{1,ply:Nick()})
end 
 
function jHarkonnen( ply )
	ply:StripAmmo()
	ply:StripWeapons()
    ply:SetTeam(2)
    ply:Spawn()
    ChatAdd("TEAMCHANGE"," joined House Harkonnen!",{2,ply:Nick()})
end 

concommand.Add( "dune_join_atreides", jAtreides )
concommand.Add( "dune_join_harkonnen", jHarkonnen )

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
	end
end

-- Spawn
hook.Add("PlayerSpawn","Dune_Spawn",function(ply)
	SP_Atreides = {
		Vector(12408.885742, -7528.326660, -10543.968750),
		Vector(12517.307617, -7696.805176, -10551.283203),
		Vector(12313.879883, -8009.676758, -10550.638672),
		Vector(11923.995117, -7815.384766, -10501.597656),
		Vector(11804.260742, -7461.417969, -10472.499023),
		Vector(11974.820313, -7199.516602, -10497.281250),

	}
	SP_Harkonnen = {
		Vector(-12395.594727, 11587.176758, -9147.045898),
		Vector(-12814.399414, 10839.073242, -9256.389648),
		Vector(-12302.385742, 10749.623047, -9257.607422),
		Vector(-12859.300781, 10293.492188, -9312.452148),
		Vector(-13258.383789, 10780.868164, -9239.381836),
		Vector(-13702.872070, 10912.717773, -9183.007813)
	}
	if ply:Team() == 1 then
		ply:SetPos(table.Random(SP_Atreides))
		ply:SetEyeAngles(Angle(0, 170, 0))
	elseif ply:Team() == 2 then
		ply:SetPos(table.Random(SP_Harkonnen))
		ply:SetEyeAngles(Angle(0, -50, 0))
	end
end)

hook.Add("PlayerInitialSpawn","Dune_JL",function(ply)
	ChatAdd("JL"," joined the Battlefield!",ply:Nick())
	ply:ConCommand("dune_team")
end)
local PInit = {}

gameevent.Listen("OnRequestFullUpdate")

hook.Add("OnRequestFullUpdate", "Dune_JL2", function(t)
	if not PInit[t.userid] then
		PInit[t.userid] = true
		Player(t.userid):SendLua([[surface.PlaySound("arrakis_ambience.wav")]])
	else
		return
	end
end)


function GM:PlayerShouldTakeDamage(ply,attacker)
	return ply == attacker || attacker:IsPlayer() && ply:Team() != attacker:Team() || attacker:IsVehicle() && ply:Team() != attacker:GetDriver():Team()
end
function GM:PlayerSetModel(ply)

	Atreides_PlyMDL = "models/player/swat.mdl"
	Harkonnen_PlyMDL = "models/player/combine_soldier.mdl"

	if ply:Team() == Atreides then
		ply:Give("tfeye_damo") --melee sword
	    ply:Give("tfeye_s6000") --pulse ar
	    ply:Give("tfeye_rotten") --pulse carbine
	    ply:Give("tfeye_depez") -- shotgun
	    ply:Give("tfeye_ovum") -- grenade launcher
	    --ply:GiveAmmo(32, "357")
	    ply:SetModel(Atreides_PlyMDL)

	elseif ply:Team() == Harkonnen then
	    ply:Give("tfeye_arra") --melee hammer
	    ply:Give("tfeye_ka93") --pulse smg
	    ply:Give("tfeye_huntr") -- carbine
	  	ply:Give("tfeye_depez") --shotgun
	    ply:Give("tfeye_excidium") --grenade launcher
	    --ply:GiveAmmo(32, "357")
	    ply:SetModel(Harkonnen_PlyMDL)
	end
end
function GM:PlayerHurt(victim, attacker)
	timer.Stop("Recharge_"..victim:SteamID())
	timer.Stop("Recharge_Starter_"..victim:SteamID())
	timer.Create( "Recharge_Starter_"..victim:SteamID(), CVAR_ShieldDelay:GetFloat(), 1, function() 
		if victim:Armor() == 0 then
			timer.Create( "Recharge_"..victim:SteamID(), CVAR_ShieldInterval:GetFloat(), 100, function() 
				victim:SetArmor(victim:Armor()+1)
			end)
		else
			timer.Create( "Recharge_"..victim:SteamID(), CVAR_ShieldInterval:GetFloat(), 100-victim:Armor(), function() 
				victim:SetArmor(victim:Armor()+1)
			end)
		end
	end)
end
--