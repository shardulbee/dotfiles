---@diagnostic disable: undefined-global

-- Spotify integration
local function readFile(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content:match("^%s*(.-)%s*$")
end

local spotifyClientId = readFile(os.getenv("HOME") .. "/.config/turbospot/client_id")
local spotifyClientSecret = readFile(os.getenv("HOME") .. "/.config/turbospot/client_secret")
local spotifyRedirectUri = "hammerspoon://spotify-auth"
local spotifyScopes = "user-library-modify user-read-currently-playing"
local spotifyStoreKey = "spotify_tokens"

local function spotifyGetTokens()
  return hs.settings.get(spotifyStoreKey) or {}
end

local function spotifySetTokens(tokens)
  hs.settings.set(spotifyStoreKey, tokens)
end

local function spotifySaveTokensFromResponse(response)
  local tokens = spotifyGetTokens()
  tokens.access_token = response.access_token
  tokens.refresh_token = response.refresh_token or tokens.refresh_token
  tokens.expires_at = os.time() + (response.expires_in or 3600) - 30
  spotifySetTokens(tokens)
  return tokens.access_token
end

local function spotifyOpenAuth()
  if not spotifyClientId or not spotifyClientSecret then
    hs.alert("Missing Spotify credentials in ~/.config/turbospot/")
    return
  end
  local query = "response_type=code"
    .. "&client_id=" .. hs.http.encodeForQuery(spotifyClientId)
    .. "&redirect_uri=" .. hs.http.encodeForQuery(spotifyRedirectUri)
    .. "&scope=" .. hs.http.encodeForQuery(spotifyScopes)
  hs.urlevent.openURL("https://accounts.spotify.com/authorize?" .. query)
  hs.alert("Authorize Spotify, then press F5>s>l again")
end

local function spotifyExchangeCode(code)
  local body = "grant_type=authorization_code"
    .. "&code=" .. hs.http.encodeForQuery(code)
    .. "&redirect_uri=" .. hs.http.encodeForQuery(spotifyRedirectUri)
    .. "&client_id=" .. hs.http.encodeForQuery(spotifyClientId)
    .. "&client_secret=" .. hs.http.encodeForQuery(spotifyClientSecret)
  local status, responseBody = hs.http.doRequest(
    "https://accounts.spotify.com/api/token",
    "POST",
    body,
    { ["Content-Type"] = "application/x-www-form-urlencoded" }
  )
  if status == 200 then
    local response = hs.json.decode(responseBody)
    return spotifySaveTokensFromResponse(response)
  end
  return nil
end

hs.urlevent.bind("spotify-auth", function(_, params)
  if params and params.code and spotifyExchangeCode(params.code) then
    hs.alert("Spotify connected ✓ Press F5>s>l to like")
  else
    hs.alert("Spotify auth failed")
  end
end)

local function spotifyEnsureAccessToken()
  local tokens = spotifyGetTokens()
  if tokens.access_token and tokens.expires_at and tokens.expires_at > os.time() then
    return tokens.access_token
  end
  if tokens.refresh_token then
    local body = "grant_type=refresh_token"
      .. "&refresh_token=" .. hs.http.encodeForQuery(tokens.refresh_token)
      .. "&client_id=" .. hs.http.encodeForQuery(spotifyClientId)
      .. "&client_secret=" .. hs.http.encodeForQuery(spotifyClientSecret)
    local status, responseBody = hs.http.doRequest(
      "https://accounts.spotify.com/api/token",
      "POST",
      body,
      { ["Content-Type"] = "application/x-www-form-urlencoded" }
    )
    if status == 200 then
      local response = hs.json.decode(responseBody)
      return spotifySaveTokensFromResponse(response)
    end
  end
  spotifyOpenAuth()
  return nil
end

local function spotifyLikeCurrentTrack()
  local token = spotifyEnsureAccessToken()
  if not token then return end

  local headers = { Authorization = "Bearer " .. token }
  local currentTrackUrl = "https://api.spotify.com/v1/me/player/currently-playing"
  local status, body = hs.http.doRequest(currentTrackUrl, "GET", nil, headers)

  if status == 401 then
    local tokens = spotifyGetTokens()
    tokens.access_token = nil
    spotifySetTokens(tokens)
    token = spotifyEnsureAccessToken()
    if not token then return end
    headers.Authorization = "Bearer " .. token
    status, body = hs.http.doRequest(currentTrackUrl, "GET", nil, headers)
  end

  if status == 204 then
    hs.alert("Nothing playing")
    return
  end
  if status ~= 200 then
    hs.alert("Failed to get track: " .. status)
    return
  end

  local data = hs.json.decode(body)
  local trackId = data and data.item and data.item.id
  if not trackId then
    hs.alert("No track ID")
    return
  end

  local likeUrl = "https://api.spotify.com/v1/me/tracks?ids=" .. trackId
  local likeStatus = hs.http.doRequest(likeUrl, "PUT", "", headers)
  if likeStatus == 200 or likeStatus == 201 or likeStatus == 204 then
    hs.alert("❤️ Liked")
  else
    hs.alert("Like failed: " .. likeStatus)
  end
end

local keys = {}
local commands = {
  c = function()
    hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
  end,
  h = { c = hs.toggleConsole, r = hs.reload },
  o = {
    s = function()
      hs.application.launchOrFocus("Slack")
    end,
    m = function()
      hs.urlevent.openURL("https://mail.google.com/mail/u/0/#inbox")
    end,
    c = function()
      hs.urlevent.openURL("https://calendar.google.com/calendar/u/0/r")
    end,
  },
  s = {
    l = spotifyLikeCurrentTrack,
    x = function()
      hs.settings.set(spotifyStoreKey, nil)
      hs.alert("Spotify logged out")
    end,
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

local function bind(cmds)
  for _, k in ipairs(keys) do
    if k ~= keys[1] then
      k:delete()
    end
  end
  keys = { keys[1] }
  for key, cmd in pairs(cmds) do
    table.insert(
      keys,
      hs.hotkey.bind({}, key, function()
        if type(cmd) == "table" then
          bind(cmd)
        else
          for _, k in ipairs(keys) do
            if k ~= keys[1] then
              k:delete()
            end
          end
          keys = { keys[1] }
          cmd()
        end
      end)
    )
  end
  table.insert(
    keys,
    hs.hotkey.bind({}, "escape", function()
      for _, k in ipairs(keys) do
        if k ~= keys[1] then
          k:delete()
        end
      end
      keys = { keys[1] }
    end)
  )
end

table.insert(
  keys,
  hs.hotkey.bind({}, "f5", function()
    bind(commands)
  end)
)

hs.pathwatcher
  .new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
      if file:sub(-4) == ".lua" then
        hs.reload()
        return
      end
    end
  end)
  :start()

hs.alert.show("✔︎")
