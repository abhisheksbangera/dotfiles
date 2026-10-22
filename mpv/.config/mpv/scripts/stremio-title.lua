-- stremio-title.lua
--
-- Streams played from Stremio's local server (http://127.0.0.1:11470/<infohash>/<idx>)
-- reach mpv as a bare number, so mpv has no real media title. This makes uosc's
-- top bar and its "Search online" subtitle downloader show "6" (or worse, the raw
-- ${...} title template) instead of the actual file name.
--
-- This script asks Stremio's local server for the torrent's file list and sets a
-- proper title, e.g. "Carrie s01e01".

local utils = require('mp.utils')
local options = require('mp.options')

local opts = {
	-- Set to no to disable the script
	enabled = true,
	-- Tidies the name up for use as a subtitle search query (drops the file
	-- extension, turns dots/underscores into spaces)
	clean_query = true,
	-- Seconds to wait for Stremio's server before giving up
	timeout = 5,
}
options.read_options(opts, 'stremio-title')

-- Matches e.g. http://127.0.0.1:11470/f6a6f60cc3fe6fe5230fcaebc9ef3ee93f7e3134/6
-- The last segment is the file index, but Stremio sometimes puts the (URL
-- encoded) file name there instead.
local URL_PATTERN = '^(https?://127%.0%.0%.1:%d+)/(%x+)/([^/?#]+)'

local function tidy(name)
	if not opts.clean_query then return name end
	name = name:gsub('%.[%w]+$', '') -- file extension
	name = name:gsub('[%._]+', ' ') -- dots and underscores to spaces
	name = name:gsub('%s+', ' ')
	return (name:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Normalize season/episode markers to lowercase and without a gap:
-- "S01 E01", "S01E01", "s01.e01", "S1-E1" -> "s01e01"
local function normalize_episode(name)
	return (name:gsub('[Ss](%d+)[%s._%-]*[Ee](%d+)', 's%1e%2'))
end

local function set_title(name)
	if name and #name > 0 then
		-- file-local, so it doesn't leak into subsequently opened files
		mp.set_property('file-local-options/title', normalize_episode(name))
		mp.msg.verbose('stremio-title: title set to "' .. normalize_episode(name) .. '"')
	end
end

local function resolve(path)
	local base, infohash, tail = path:match(URL_PATTERN)
	if not base then return end

	-- When the URL already carries the file name, no lookup is needed.
	if not tail:match('^%d+$') then
		set_title(tidy(tail:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)))
		return
	end

	local idx = tonumber(tail)
	local stats_url = base .. '/' .. infohash .. '/stats.json'
	mp.command_native_async({
		name = 'subprocess',
		args = { 'curl', '-s', '--max-time', tostring(opts.timeout), stats_url },
		capture_stdout = true,
		capture_stderr = true,
		playback_only = false,
	}, function(success, result)
		if not success or not result or result.status ~= 0 then return end

		local data = utils.parse_json(result.stdout)
		if type(data) ~= 'table' or type(data.files) ~= 'table' then return end

		local file = data.files[idx + 1] -- Lua is 1-based, URL index is 0-based
		-- Stremio usually returns file objects ({name=...}), but some builds
		-- return plain strings, so accept both.
		local name = type(file) == 'table' and (file.name or file.path) or file
		if type(name) ~= 'string' or #name == 0 then
			name = data.name -- fall back to the torrent name
		end

		set_title(tidy(name))
	end)
end

if opts.enabled then
	mp.register_event('file-loaded', function()
		-- stream-open-filename is the effective URL of the stream; fall back to
		-- `path` for the odd case where it is not set.
		local path = mp.get_property('stream-open-filename')
		if not path or path == '' then path = mp.get_property('path') end
		if path then resolve(path) end
	end)
end
