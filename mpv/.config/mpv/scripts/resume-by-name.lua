-- resume-by-name.lua
--
-- Resume network streams by a stable *name* instead of by their URL.
--
-- mpv's built-in "resume where you left off" keys the saved position on the
-- file path / stream URL it was given. For network streams that is a problem:
--
--   * Stremio plays streams from its local server, and the URL contains the
--     server's port (http://127.0.0.1:<port>/<infohash>/<idx>), which can change
--     between sessions - so the same episode gets a different key each time.
--   * Stremio also launches mpv as `mpv --start=<position> ... <url>`; mpv's
--     command-line options win over the saved position, so resume is overridden
--     even when the key does match.
--
-- This script derives a stable name for the stream (torrent infohash + file
-- index for Stremio, a hash of the URL without its query string otherwise),
-- remembers the position itself and seeks to it after the file has loaded. That
-- makes it work no matter how mpv was launched.
--
-- Local files are left completely alone: mpv's normal resume already keys them
-- on the file name thanks to ignore-path-in-watch-later-config=yes.

local utils = require('mp.utils')
local msg = mp.msg
local options = require('mp.options')

local opts = {
	-- Set to no to disable the script
	enabled = true,
	-- Where the positions are kept. ~~state expands to mpv's state dir, next to
	-- the watch_later/ directory that mpv itself uses.
	directory = '~~state/name-resume',
	-- Positions shorter than this (seconds) are not remembered.
	min_save = 10,
	-- A position this close to the end (seconds) counts as "finished" and is
	-- forgotten, so the next play starts from the beginning.
	eof_margin = 30,
	-- Seconds to wait for Stremio's server when resolving a file name -> index
	timeout = 5,
}
options.read_options(opts, 'resume-by-name')

if not opts.enabled then return end

-- Resolve the directory. mpv's "~~state" expansion depends on the config/state
-- dirs being known, so fall back to XDG paths if it did not resolve to an
-- absolute path.
local dir = (mp.command_native({ 'expand-path', opts.directory })) or ''
if not dir:match('^/') then
	local base = os.getenv('XDG_STATE_HOME')
	if not base or base == '' then base = (os.getenv('HOME') or '') .. '/.local/state' end
	dir = base .. '/mpv/' .. (dir:gsub('^~~state/', ''))
end
if not utils.file_info(dir) then
	-- mp.utils has no mkdir in every build, so shell out.
	mp.command_native({ name = 'subprocess', args = { 'mkdir', '-p', dir }, playback_only = false })
end

local function read_file(path)
	local f = io.open(path, 'r')
	if not f then return nil end
	local data = f:read('*a')
	f:close()
	return data
end

local function write_file(path, data)
	local f = io.open(path, 'w')
	if not f then return false end
	f:write(data)
	f:close()
	return true
end

-- http://127.0.0.1:11470/<infohash>/<idx-or-file-name>
local STREMIO_URL = '^https?://127%.0%.0%.1:%d+/(%x+)/'
local ANY_URL = '^%a[%w+.-]*://'

-- Stable name of the stream playing right now (nil for local files).
local key = nil
-- Most recent playback position, kept current so it is available on quit.
local last_pos = nil

local function md5(s)
	local r = mp.command_native({
		name = 'subprocess',
		args = { 'md5sum' },
		stdin_data = s,
		capture_stdout = true,
		playback_only = false,
	})
	if r and r.status == 0 and r.stdout then
		return r.stdout:match('^%x+')
	end
end

-- Generic stream: hash the URL, ignoring the query string / fragment so that
-- rotating tokens (and Stremio-like ports) do not change the key.
local function hashed_key(url)
	local h = md5((url:gsub('[#?].*$', '')))
	if h then return 'stream-' .. h end
end

local function store_path(k)
	return utils.join_path(dir, k)
end

local function read_saved(k)
	local v = read_file(store_path(k))
	local n = v and tonumber((v:gsub('%s', '')))
	if n and n > 0 then return n end
end

local function write_saved(k, pos)
	write_file(store_path(k), string.format('%.3f\n', pos))
end

local function clear_saved(k)
	os.remove(store_path(k))
end

-- Stremio key: "stremio-<infohash>-<index>". The URL usually ends with the file
-- index, but Stremio sometimes replaces it with the (URL-encoded) file name; in
-- that case ask Stremio's server which index that name is, so both forms of the
-- URL map to the same key.
local function stremio_key(path, callback)
	local base, infohash, tail = path:match('^(https?://127%.0%.0%.1:%d+)/(%x+)/([^/?#]+)')
	if not infohash then return end
	infohash = infohash:lower()

	if tail:match('^%d+$') then
		callback('stremio-' .. infohash .. '-' .. tail)
		return
	end

	local wanted = tail:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
	mp.command_native_async({
		name = 'subprocess',
		args = { 'curl', '-s', '--max-time', tostring(opts.timeout), base .. '/' .. infohash .. '/stats.json' },
		capture_stdout = true,
		capture_stderr = true,
		playback_only = false,
	}, function(ok, res)
		local index
		if ok and res and res.status == 0 and res.stdout then
			local data = utils.parse_json(res.stdout)
			if type(data) == 'table' and type(data.files) == 'table' then
				for i, file in ipairs(data.files) do
					local name = type(file) == 'table' and (file.name or file.path) or file
					if name == wanted then
						index = i - 1 -- URL index is 0-based
						break
					end
				end
			end
		end
		if index then
			callback('stremio-' .. infohash .. '-' .. index)
		else
			local h = md5(wanted)
			if h then callback('stremio-' .. infohash .. '-' .. h) end
		end
	end)
end

local function stream_key(path, callback)
	if path:match(STREMIO_URL) then
		stremio_key(path, callback)
	elseif path:match(ANY_URL) then
		callback(hashed_key(path))
	end
end

-- Keep track of where we are, to save it when playback ends.
mp.observe_property('time-pos', 'number', function(_, value)
	if value then last_pos = value end
end)

mp.register_event('file-loaded', function()
	local path = mp.get_property('stream-open-filename')
	if not path or #path == 0 then path = mp.get_property('path') end
	if not path then return end

	-- Respect an explicit position: Stremio's own resume (mpv --start=<pos>) or
	-- mpv's watch_later when its key happened to match. Only step in when
	-- nothing picked a position - which is the case that was broken.
	local explicit = tonumber(mp.get_property('start') or '')

	key, last_pos = nil, nil
	stream_key(path, function(resolved)
		if not resolved then return end
		key = resolved
		if explicit and explicit > 0 then
			msg.verbose('resume-by-name: keeping explicit start ' .. explicit .. 's')
			return
		end
		local saved = read_saved(resolved)
		if saved then
			mp.commandv('seek', string.format('%.3f', saved), 'absolute')
			msg.verbose('resume-by-name: resuming ' .. resolved .. ' at ' .. saved .. 's')
		end
	end)
end)

local function save(reason)
	if not key or not last_pos then return end
	local duration = mp.get_property_number('duration')
	if reason == 'eof' or (duration and duration > 0 and duration - last_pos <= opts.eof_margin) then
		clear_saved(key)
	elseif last_pos >= opts.min_save then
		write_saved(key, last_pos)
	else
		clear_saved(key)
	end
end

mp.register_event('end-file', function(event)
	local reason = event and event.reason
	if reason ~= 'redirect' then save(reason) end
	key, last_pos = nil, nil
end)

-- Safety net in case the file is never unloaded (e.g. the process is asked to
-- quit before the file fully unloads).
mp.register_event('shutdown', function()
	save('quit')
end)
