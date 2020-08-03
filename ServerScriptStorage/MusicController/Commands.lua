local PLAYER = require(script.Parent.MusicPlayer)

--PLAYER.use_allow_list = false	-- Whether to use allow list or no
--PLAYER.adminList = { }	-- IDs of users that can use restricted commands
--PLAYER.allowList = {	 	}	-- IDs of users that are allowed to use the commands
--PLAYER.blockList = {		}	-- IDs of users that are NOT allowed to use the commands
PLAYER.init()


-- #### COMMANDS ####
local commands = {
	
	-- Play an audio
	["play"] = function (userId, args)
		local songId = tonumber(args[2])
		if not songId then return end
		PLAYER.playSong(songId, userId)
	end,
	
	-- Vote to skip an audio
	["voteskip"] = function (userId, args)
		PLAYER.voteSkip(userId)
	end,
	
	
	-- ADMIN COMMANDS
	
	-- Set volume of the audio player,
	["volume"] = function (userId, args)
		if not PLAYER.isAdmin(userId) then return end
		local volume = tonumber(args[2])
		PLAYER.setVolume(volume)
	end,
	
	-- Force skip a currently playing audio
	["forceskip"] = function (userId, args)
		if not PLAYER.isAdmin(userId) then return end
		PLAYER.forceSkip()
	end,
	
	-- Completely reset the music player, this includes
	-- removing the current playing song and the queue.
	["clear"] = function (userId, args)
		if not PLAYER.isAdmin(userId) then return end
		PLAYER.clear()
	end,
}


function interpret(player, message)
	if PLAYER.isBlock(player.UserId) then return end -- If user is blocked don't do anything
	if PLAYER.use_allow_list and not PLAYER.isAllow(player.UserId) then return end -- If allow list is on and user is not allowed then do nothing
	if PLAYER.commandChar ~= message:sub(1, 1) then return end
	
	-- split tokens nad insert into table
	local args = {}
	for token in string.gmatch(message:sub(2), "[^%s]+") do
   		table.insert(args, token)
	end
	
	local command = commands[args[1]]
	if not command then return end
	
	command(player.UserId, args)
end

game.Players.PlayerAdded:connect(function(player)
	player.Chatted:connect(function(message)
		interpret(player, message)
    end)
end)
