--- @since 25.2.26
-- Conditional image preview: native graphics everywhere,
-- chafa (ANSI art) only in Alacritty.
-- Requires chafa >= 1.16.0 (`chafa --version`).

local M = {}

-- Only Alacritty gets chafa. Ghostty (and everything else) uses yazi's
-- native adapter (Kgp on Ghostty, auto-fallback elsewhere).
local function use_chafa()
	-- Positive Alacritty markers
	if os.getenv("ALACRITTY_WINDOW_ID") or os.getenv("ALACRITTY_SOCKET") or os.getenv("ALACRITTY_LOG") then
		return true
	end
	if os.getenv("TERM") == "alacritty" then
		return true
	end
	return false
end

local function peek_native(job)
	local start, url = os.clock(), ya.file_cache(job)
	if not url or not fs.cha(url) then
		url = Url(job.file.path)
	end

	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))

	local _, err = ya.image_show(url, job.area)
	ya.preview_widget(job, err)
end

function M:peek(job)
	-- Ghostty / others: native preview, no chafa
	if not use_chafa() then
		return peek_native(job)
	end
	local w, h = job.area.w, job.area.h
	if w < 1 or h < 1 then
		return ya.preview_widget(job, ui.Text(""):area(job.area))
	end

	-- Same flags yazi itself uses internally (drivers/chafa.rs),
	-- plus --probe off to avoid chafa 1.18.1+ probing /dev/tty
	-- which causes ghost keypresses (see sxyazi/yazi#3671).
	local output, err = Command("chafa")
		:arg({
			"-f",
			"symbols",
			"--relative",
			"off",
			"--probe",
			"off",
			"--polite",
			"on",
			"--passthrough",
			"none",
			"--animate",
			"off",
			"--view-size",
			string.format("%dx%d", w, h),
			"--",
			tostring(job.file.path),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output then
		return ya.preview_widget(
			job,
			ui.Text(string.format("Failed to start `chafa`: %s", err or "")):area(job.area):wrap(ui.Wrap.YES)
		)
	end

	if not output.status.success then
		local msg = (output.stderr or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if msg == "" then
			msg = string.format("chafa exited with code %s", output.status.code)
		end
		return ya.preview_widget(job, ui.Text(msg):area(job.area):wrap(ui.Wrap.YES))
	end

	if output.stdout == "" then
		return ya.preview_widget(job, ui.Text("Empty chafa output"):area(job.area))
	end

	-- Parse ANSI art so colors survive in the preview pane
	local text = ui.Text.parse(output.stdout)
	ya.preview_widget(job, text:area(job.area):wrap(ui.Wrap.NO))
end

function M:seek() end

function M:preload(job)
	-- Needed for the native (Ghostty) path; harmless for chafa path.
	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end

	return ya.image_precache(Url(job.file.path), cache)
end

-- Keep `spot` (Tab) showing image metadata like the built-in image previewer
function M:spot(job)
	local info = ya.image_info(Url(job.file.path))
	local rows = {}
	if info then
		rows = {
			ui.Row({ "Image" }):style(ui.Style():fg("green")),
			ui.Row({ "  Format:", tostring(info.format) }),
			ui.Row({ "  Size:", string.format("%dx%d", info.w, info.h) }),
			ui.Row({ "  Color:", tostring(info.color) }),
			ui.Row({}),
		}
	end
	ya.spot_table(
		job,
		ui.Table(ya.list_merge(rows, require("file"):spot_base(job)))
			:area(ui.Pos({ "center", w = 60, h = 20 }))
			:row(job.skip)
			:row(1)
			:col(1)
			:col_style(th.spot.tbl_col)
			:cell_style(th.spot.tbl_cell)
			:widths({ ui.Constraint.Length(14), ui.Constraint.Fill(1) })
	)
end

return M
