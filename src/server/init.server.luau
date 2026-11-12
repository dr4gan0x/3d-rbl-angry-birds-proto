--!strict
-- Sunucu giris noktasi: servisleri sirayla kurar ve ilk seviyeyi baslatir.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local FireService = require(script.Parent:WaitForChild("FireService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

-- Remote'lari bir kez olustur (istemci WaitForChild ile bekler).
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remoteSet = Remotes.ensure(remotesFolder, true)

FireService.start(remoteSet)
RoundService.start(remoteSet)
RoundService.startLevel(1)

print("[flockfall] server boot — level 1 hazir")
