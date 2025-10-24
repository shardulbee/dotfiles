---@diagnostic disable: undefined-global
---
local function readFile(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*all")
	f:close()
	return content:match("^%s*(.-)%s*$")
end

local spotifyClientId = readFile(os.getenv("HOME") .. "/.config/turbospot/client_id")
local spotifyClientSecret = readFile(os.getenv("HOME") .. "/.config/turbospot/client_secret")

local function getTokens()
	return hs.settings.get("spotify_tokens") or {}
end

local function saveTokens(response)
	local tokens = getTokens()
	tokens.access_token = response.access_token
	tokens.refresh_token = response.refresh_token or tokens.refresh_token
	tokens.expires_at = os.time() + (response.expires_in or 3600) - 30
	hs.settings.set("spotify_tokens", tokens)
	return tokens.access_token
end

local function spotifyRequest(url, method, token)
	return hs.http.doRequest(
		url,
		method or "GET",
		method == "PUT" and "" or nil,
		{ Authorization = "Bearer " .. token }
	)
end

local function refreshToken()
	local tokens = getTokens()
	if not tokens.refresh_token then
		return nil
	end

	local body = string.format(
		"grant_type=refresh_token&refresh_token=%s&client_id=%s&client_secret=%s",
		hs.http.encodeForQuery(tokens.refresh_token),
		hs.http.encodeForQuery(spotifyClientId),
		hs.http.encodeForQuery(spotifyClientSecret)
	)

	local status, responseBody = hs.http.doRequest(
		"https://accounts.spotify.com/api/token",
		"POST",
		body,
		{ ["Content-Type"] = "application/x-www-form-urlencoded" }
	)

	if status == 200 then
		return saveTokens(hs.json.decode(responseBody))
	end
	return nil
end

local function getAccessToken()
	local tokens = getTokens()
	if tokens.access_token and tokens.expires_at and tokens.expires_at > os.time() then
		return tokens.access_token
	end
	return refreshToken()
end

local function openSpotifyAuth()
	if not spotifyClientId or not spotifyClientSecret then
		hs.alert("Missing Spotify credentials")
		return
	end

	local query = string.format(
		"response_type=code&client_id=%s&redirect_uri=%s&scope=%s",
		hs.http.encodeForQuery(spotifyClientId),
		hs.http.encodeForQuery("hammerspoon://spotify-auth"),
		hs.http.encodeForQuery("user-library-modify user-read-currently-playing")
	)

	hs.urlevent.openURL("https://accounts.spotify.com/authorize?" .. query)
	hs.alert("Authorize Spotify, then press F5>s>l again")
end

hs.urlevent.bind("spotify-auth", function(_, params)
	if not params or not params.code then
		hs.alert("Spotify auth failed")
		return
	end

	local body = string.format(
		"grant_type=authorization_code&code=%s&redirect_uri=%s&client_id=%s&client_secret=%s",
		hs.http.encodeForQuery(params.code),
		hs.http.encodeForQuery("hammerspoon://spotify-auth"),
		hs.http.encodeForQuery(spotifyClientId),
		hs.http.encodeForQuery(spotifyClientSecret)
	)

	local status, responseBody = hs.http.doRequest(
		"https://accounts.spotify.com/api/token",
		"POST",
		body,
		{ ["Content-Type"] = "application/x-www-form-urlencoded" }
	)

	if status == 200 then
		saveTokens(hs.json.decode(responseBody))
		hs.alert("Spotify connected ✓")
	else
		hs.alert("Spotify auth failed")
	end
end)

local function spotifyLike()
	local token = getAccessToken()
	if not token then
		openSpotifyAuth()
		return
	end

	local status, body = spotifyRequest("https://api.spotify.com/v1/me/player/currently-playing", "GET", token)

	if status == 401 then
		token = refreshToken()
		if not token then
			openSpotifyAuth()
			return
		end
		status, body = spotifyRequest("https://api.spotify.com/v1/me/player/currently-playing", "GET", token)
	end

	if status == 204 then
		hs.alert("Nothing playing")
		return
	end

	if status ~= 200 then
		hs.alert("Failed: " .. status)
		return
	end

	local data = hs.json.decode(body)
	local trackId = data and data.item and data.item.id

	if not trackId then
		hs.alert("No track ID")
		return
	end

	local likeStatus = spotifyRequest("https://api.spotify.com/v1/me/tracks?ids=" .. trackId, "PUT", token)

	hs.alert(likeStatus == 200 or likeStatus == 201 or likeStatus == 204 and "❤️ Liked" or "Like failed")
end

local modals = {}

local function bind(keys)
	for _, modal in ipairs(modals) do
		modal:delete()
	end
	modals = {}

	for key, action in pairs(keys) do
		local modal = hs.hotkey.modal.new()
		modals[#modals + 1] = modal

		modal:bind("", key, function()
			if type(action) == "table" then
				bind(action)
			else
				for _, m in ipairs(modals) do
					m:delete()
				end
				modals = {}
				action()
			end
		end)

		modal:bind("", "escape", function()
			for _, m in ipairs(modals) do
				m:delete()
			end
			modals = {}
		end)

		modal:enter()
	end
end

local commands = {
	c = function()
		hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
	end,
	b = {
		b = function()
			hs.urlevent.openURL("raycast://extensions/raycast/browser-bookmarks/index")
		end,
	},
	h = {
		c = hs.toggleConsole,
		r = hs.reload,
	},
	o = {
		s = function()
			hs.application.launchOrFocus("Slack")
		end,
		m = function()
			hs.urlevent.openURL("https://mail.google.com/mail/u/0/#inbox")
		end,
		c = function()
			hs.urlevent.openURL("https://claude.ai/code")
		end,
	},
	s = {
		l = spotifyLike,
	},
	w = {
		d = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "enable", "toggle" }):start()
		end,
		t = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "tiles", "vertical", "horizontal" }):start()
		end,
		s = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "accordion", "vertical", "horizontal" }):start()
		end,
		f = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "layout", "floating", "tiling" }):start()
		end,
		r = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, { "reload-config" }):start()
		end,
		j = {
			h = function()
				hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "left" }):start()
			end,
			j = function()
				hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "down" }):start()
			end,
			k = function()
				hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "up" }):start()
			end,
			l = function()
				hs.task.new("/opt/homebrew/bin/aerospace", nil, { "join-with", "right" }):start()
			end,
		},
	},
}

hs.hotkey.bind({}, "f5", function()
	bind(commands)
end)

hs.pathwatcher
	.new(hs.execute("realpath ~/.hammerspoon/init.lua"):match("(.*/)") or ".", function(files)
		for _, file in pairs(files) do
			if file:match("%.lua$") then
				hs.reload()
				return
			end
		end
	end)
	:start()

hs.alert.show("✔︎")
