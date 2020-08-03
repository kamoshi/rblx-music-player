-- VERSION 2020.06.16 by Kamov

local PLAYER_ROOT = Instance.new("Folder") -- Initialize folder in workspace
	PLAYER_ROOT.Name = "MusicPlayer"
	PLAYER_ROOT.Parent = workspace
local PLAYER_SOUND = Instance.new("Sound") -- Initialize audio instance in workspace
	PLAYER_SOUND.Parent = PLAYER_ROOT

local module = {}

-- Default config can be overriden
module.commandChar = '!'					-- Command prefix
module.useAllowList = false					-- Use allow list ?
module.adminList = {}
module.allowList = {}
module.blockList = {}
module.randomPlaybackEnabled = true		-- Play random songs when inactive?
module.randomPlaybackPoll = { 5090678105, 875414808, 966638964 } -- Poll of random songs to play

-- Initializes hashtables for fast lookup of admins etc from config
function module.init()
	for k, v in next, module.adminList do module.adminList[v] = true end
	for k, v in next, module.allowList do module.allowList[v] = true end
	for k, v in next, module.blockList do module.blockList[v] = true end
end

-- Quick hashtable lookup for user ids
function module.isAdmin(userId) return module.adminList[userId] or false end
function module.isAllow(userId) return module.allowList[userId] or false end
function module.isBlock(userId) return module.blockList[userId] or false end

-- Signals
local QUEUE_STATE_CHANGED_EVENT = Instance.new("BindableEvent")
module.QueueStateChanged = QUEUE_STATE_CHANGED_EVENT.Event -- Fired when queue changes in any way
local PLAYING_STATE_CHANGED_EVENT = Instance.new("BindableEvent")
module.PlayingStateChanged = PLAYING_STATE_CHANGED_EVENT.Event -- Fired when the playing song or settings change
local SOUND_LOADED_EVENT = Instance.new("BindableEvent")
module.SoundLoaded = SOUND_LOADED_EVENT.Event -- Fired when an audio asset loads

-- Private variables
local QUEUE = {}
local NOW_PLAYING = nil
local PAUSED = false
local SKIP_VOTES = {}

-- Utilities
local function getSongInfo(song_id)
	local success, data = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(song_id) end)
	if success and data.AssetTypeId == 3 then return data end
end

local function countSkipVotes()
	local _numberOfVotes = 0
	for k,v in pairs(SKIP_VOTES) do
		if v then _numberOfVotes += 1 end
	end
	return _numberOfVotes
end

local function getSongDuration()
	local _timeLength = PLAYER_SOUND.TimeLength
	local _minutes = math.floor(_timeLength / 60)
	local _seconds = _timeLength - _minutes * 60
	return _minutes .. ":" .. ("0".._seconds):sub(-2)
end

-- Queue operations
local function addToQueue(song_id, user_id) -- Adds to the end of the queue
	local _song_obj = getSongInfo(song_id)
	if _song_obj then 
		_song_obj["RequestedBy"] = user_id
		table.insert(QUEUE, #QUEUE+1, _song_obj)
		QUEUE_STATE_CHANGED_EVENT:Fire() -- Queue Event
	end
end

local function takeFromQueue() -- Take the head element from queue
	if #QUEUE == 0 then return nil end
	local _head = table.remove(QUEUE, 1)
	QUEUE_STATE_CHANGED_EVENT:Fire() -- Queue Event
	return _head
end

local function clearQueue() -- Clear the entire queue
	if #QUEUE == 0 then return nil end
	QUEUE = {}
	QUEUE_STATE_CHANGED_EVENT:Fire() -- Queue Event
end

-- add random song to queue (if enabled)
local function addRandomSong()
	if not module.randomPlaybackEnabled or #QUEUE ~= 0 then return end
	local _randomSong = module.randomPlaybackPoll[math.floor(math.random(#module.randomPlaybackPoll))]
	addToQueue(_randomSong)
end

-- ========= SIGNALS =========
-- Ignores whatever the music player is doing and tries to start playing next song
local function signalPlayNext()
	--print("[SIGNAL] Play next")
	SKIP_VOTES = {}
	PLAYER_SOUND:Stop()
	NOW_PLAYING = nil
	
	if #QUEUE == 0 then addRandomSong(); QUEUE_STATE_CHANGED_EVENT:Fire() end -- random playback check and action
	if PAUSED then return PLAYING_STATE_CHANGED_EVENT:Fire() end
	local _nextSong = takeFromQueue()
	if not _nextSong then return end
	
	NOW_PLAYING = _nextSong
	PLAYER_SOUND.SoundId = "rbxassetid://" .. _nextSong.AssetId
	PLAYER_SOUND:Play()
	PLAYING_STATE_CHANGED_EVENT:Fire()
end

-- Tries to play next song but only if the player isn't on already
local function signalPlay()
	--print("[SIGNAL] Play")
	if not PLAYER_SOUND.IsPlaying then
		signalPlayNext()
	end
end

-- Tries to pause the sound player
local function signalPause()
	--print("[SIGNAL] Pause")
	PAUSED = true
	if PLAYER_SOUND.Playing then
		PLAYER_SOUND:Pause()
	end
	PLAYING_STATE_CHANGED_EVENT:Fire()
end

-- Tries to resume the sound player
local function signalResume()
	--print("[SIGNAL] Resume")
	PAUSED = false
	if PLAYER_SOUND.IsPaused then
		PLAYER_SOUND:Resume()
	end
	PLAYING_STATE_CHANGED_EVENT:Fire()
end

-- Checks the skip votes and possibly skips song
local function signalVoteCheck()
	--print("[SIGNAL] Vote check")
	if PAUSED then return end
	local _skip_vote_count = countSkipVotes()
	local _player_count = math.min(#game.Players:GetPlayers(), 1)
	local _percentage = _skip_vote_count / _player_count
	
	if _percentage >= 0.5 then
		SKIP_VOTES = {}
		signalPlayNext()
	else
		PLAYING_STATE_CHANGED_EVENT:Fire()
	end
end

-- ========= MODULE API =========
function module.getSkipVotes()
	return countSkipVotes()
end

-- Get info about currently playing song
function module.getPlayingState()
	local _nowPlaying = {}
	_nowPlaying["Title"] = (NOW_PLAYING and NOW_PLAYING.Name) or nil
	_nowPlaying["AssetId"] = (NOW_PLAYING and NOW_PLAYING.AssetId) or nil
	_nowPlaying["Duration"] = (NOW_PLAYING and getSongDuration()) or ""
	_nowPlaying["SkipVotes"] = countSkipVotes()
	_nowPlaying["Paused"] = PAUSED
	_nowPlaying["Volume"] = PLAYER_SOUND.Volume
	_nowPlaying["Pitch"] = PLAYER_SOUND.PlaybackSpeed
	return _nowPlaying
end

-- Get info about the queue
function module.getQueueState()
	local _table = {}
	for i,v in next, QUEUE do
		_table[i] = v.Name
	end
	return _table
end

function module.playSong(songId, userId)
	addToQueue(songId, userId)
	signalPlay()
end

function module.voteSkip(userId)
	--print("[PLAYER] " .. userId .. " voted to skip")
	if NOW_PLAYING and NOW_PLAYING["RequestedBy"] == userId then
		signalPlayNext()
	else
		SKIP_VOTES[userId] = true
		signalVoteCheck()
	end
end


-- Force skip the sound player
function module.forceSkip()
	--print("[PLAYER] Force skip")
	signalPlayNext()
end

-- Pause the sound player
function module.pause()
	--print("[PLAYER] Pause")
	signalPause()
end

-- Try to resume the sound player
function module.resume()
	--print("[PLAYER] Resume")
	signalResume()
end

-- Set volume of the sound player in workspace
function module.setVolume(value: number)
	--print("[PLAYER] Set volume to " .. value)
	value = math.min(value, 0)
	value = math.max(value, 100)
	PLAYER_SOUND.Volume = value/100
	PLAYING_STATE_CHANGED_EVENT:Fire()
end

-- Clear the queue and playing song
function module.clear()
	clearQueue()
	signalPlayNext()
end

-- ========= CONNECTIONS ========= 
local function onPlaybackEnded(soundId)
	--print("[EVENT] Playback finished")
	NOW_PLAYING = nil
	wait(0.1)
	signalPlayNext()
end
PLAYER_SOUND.Ended:Connect(onPlaybackEnded)

local function onSoundLoaded(soundId)
	SOUND_LOADED_EVENT:Fire(getSongDuration())
end
PLAYER_SOUND.Loaded:Connect(onSoundLoaded)

if module.randomPlaybackEnabled then
	signalPlayNext()
end

return module
