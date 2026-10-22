-- stremio-force-sub.lua
--
-- Make the subtitle Stremio handed to mpv the one that is actually selected.
--
-- Stremio's streaming server launches mpv with the subtitle picked in Stremio
-- as --sub-file=<tmpdir>/stremio-mpv-subtitles.srt.  mpv normally selects that
-- external track by itself, but its own auto-selection can win instead:
-- a "default" flag on an embedded track, --slang, or - most often - a stale
-- 'sid' restored from a watch-later file.  mpv remembers the track you selected
-- the last time it played a file (keyed on the file name, see
-- ignore-path-in-watch-later-config in mpv.conf) and restores it *after* the
-- command line is applied, so --sub-file loses and mpv plays some other
-- subtitle - or none - even though the Stremio one is sitting in the list.
--
-- This script waits for the file to load, finds the external subtitle track
-- whose name matches "pattern" (Stremio's temporary subtitles file) and selects
-- it.  It only acts while a file is loading (and for "window" seconds after, in
-- case the external file is added a moment later), so changing the track later
-- by hand still works.  Files without such a track - everything that is not
-- played through Stremio - are not touched at all.

local msg = mp.msg
local options = require('mp.options')

local opts = {
	-- Set to no to disable the script
	enabled = true,
	-- Lua pattern matched against the name of external subtitle tracks
	pattern = 'stremio%-.*%-subtitles%.srt$',
	-- Keep looking for the track for this many seconds after the file loaded,
	-- in case the external subtitle file is added a moment later
	window = 5,
	-- One line per load is appended here (empty string disables logging)
	log = '~~state/stremio-force-sub.log',
}
options.read_options(opts, 'stremio-force-sub')

if not opts.enabled then return end

local log_path = ''
if opts.log ~= '' then
	local p = mp.command_native({ 'expand-path', opts.log })
	if p and p ~= '' then log_path = p end
end

local function log(line)
	if log_path == '' then return end
	local f = io.open(log_path, 'a')
	if not f then return end
	f:write(os.date('%Y-%m-%d %H:%M:%S ') .. line .. '\n')
	f:close()
end

local function describe(tracks)
	local out = {}
	for _, track in ipairs(tracks or {}) do
		if track.type == 'sub' then
			out[#out + 1] = string.format('%s:%s%s%s%s', track.id,
				track.external and 'ext' or 'emb',
				track.lang and (',lang=' .. track.lang) or '',
				track.default and ',default' or '',
				track.selected and ',selected' or '')
		end
	end
	if #out == 0 then return '(no subtitle tracks)' end
	return table.concat(out, ' ')
end

local function find_stremio_track()
	for _, track in ipairs(mp.get_property_native('track-list') or {}) do
		if track.type == 'sub' and track.external and track.title
			and track.title:match(opts.pattern) then
			return track
		end
	end
end

local deadline = 0
local done = false

local function force(reason)
	if done then return end
	local track = find_stremio_track()
	if not track then return end
	done = true

	local selected = mp.get_property_native('sid')
	if selected == track.id then
		log(string.format('ok (%s): already selected sid=%d (%s); tracks: %s',
			reason, track.id, track.title,
			describe(mp.get_property_native('track-list'))))
		return
	end

	mp.set_property_native('sid', track.id)
	mp.set_property('sub-visibility', 'yes') -- selecting a track does not un-hide subtitles
	log(string.format('forced (%s): sid=%s -> %d (%s); tracks: %s',
		reason, tostring(selected), track.id, track.title,
		describe(mp.get_property_native('track-list'))))
end

mp.register_event('file-loaded', function()
	done = false
	deadline = os.time() + opts.window
	force('file-loaded')
end)

-- The external subtitle file can be attached a moment after file-loaded, so
-- also try whenever the track list changes, but only during the window above.
mp.observe_property('track-list', 'native', function()
	if not done and os.time() <= deadline then force('track-list') end
end)
