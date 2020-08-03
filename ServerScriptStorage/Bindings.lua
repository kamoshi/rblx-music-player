local PLAYER = require(script.Parent.MusicPlayer)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- PLAYING STATE EXPLICIT UPDATE REQUEST
local GetPlayingState = Instance.new("RemoteFunction")
GetPlayingState.Name = "GetPlayingState"
GetPlayingState.Parent = ReplicatedStorage

local function onGetPlayingState(player)
	print("[BIND] Playing state request " .. player.UserId)
	return PLAYER.getPlayingState()
end
GetPlayingState.OnServerInvoke = onGetPlayingState
 
-- QUEUE STATE EXPLICIT UPDATE REQUEST
local GetQueueState = Instance.new("RemoteFunction")
GetQueueState.Name = "GetQueueState"
GetQueueState.Parent = ReplicatedStorage

local function onGetQueueState(player)
	print("[BIND] Queue state request " .. player.UserId)
	return PLAYER.getQueueState()
end
GetQueueState.OnServerInvoke = onGetQueueState

-- PLAYING STATE CHANGED EVENT
local PlayingStateChanged = Instance.new("RemoteEvent")
PlayingStateChanged.Name = "PlayingStateChanged"
PlayingStateChanged.Parent = game.ReplicatedStorage

local function onPlayingStateChanged()
	print("[BIND] Playing state changed")
	PlayingStateChanged:FireAllClients(PLAYER.getPlayingState())
end
PLAYER.PlayingStateChanged:Connect(onPlayingStateChanged)

-- QUEUE STATE CHANGED EVENT
local QueueStateChanged = Instance.new("RemoteEvent")
QueueStateChanged.Name = "QueueStateChanged"
QueueStateChanged.Parent = game.ReplicatedStorage

local function onQueueStateChanged()
	print("[BIND] Queue state changed")
	QueueStateChanged:FireAllClients(PLAYER.getQueueState())
end
PLAYER.QueueStateChanged:Connect(onQueueStateChanged)

-- SONG LOADED EVENT (SERVER SIDE)
local SoundLoaded = Instance.new("RemoteEvent")
SoundLoaded.Name = "SoundLoaded"
SoundLoaded.Parent = game.ReplicatedStorage

local function onSoundLoaded(duration: string)
	print("[BIND] Sound loaded")
	SoundLoaded:FireAllClients(duration)
end
PLAYER.SoundLoaded:Connect(onSoundLoaded)
