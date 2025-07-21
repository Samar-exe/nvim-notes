local dashboard = {}

function dashboard.setup()
	local entries = {
		{
			key = "t",
			label = "📅 Today’s Note",
			path = function()
				return utils.get_today_note()
			end,
		},
		{ key = "p", label = "🚀 Project Ideas", path = "~/notes/project_ideas.txt" },
		{ key = "c", label = "🎓 Class Notes", path = "~/notes/class_notes.txt" },
		{ key = "v", label = "📼 Video Notes", path = "~/notes/video_notes.txt" },
		{ key = "s", label = "✍️ Scratchpad", path = "~/notes/scratchpad.txt" },
	}

	function dashboard.open()
		vim.cmd("enew")
		local buf = vim.api.nvim_get_current_buf()

		-- Buffer settings
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "wipe"
		vim.bo[buf].swapfile = false
		vim.bo[buf].modifiable = true
		vim.wo[0].number = false
		vim.wo[0].relativenumber = false
		vim.wo[0].cursorline = false
		vim.wo[0].signcolumn = "no"

		-- Centered ASCII layout
		local lines = {
			"",
			"   ░█▀▀░█▀▀░█▀█░▀█▀░█▀▀░█▀▀░█▀▀░█▄█",
			"   ░▀▀█░█░░░█░█░░█░░█▀▀░▀▀█░█▀▀░█░█",
			"   ░▀▀▀░▀▀▀░▀▀▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀",
			"",
			"  ┌──────────────────────────────────────────┐",
			"  │             🧠 Notes Dashboard           │",
			"  └──────────────────────────────────────────┘",
			"",
		}

		for _, entry in ipairs(entries) do
			table.insert(lines, string.format("   [%s]  %s", entry.key, entry.label))
		end

		table.insert(lines, "")
		table.insert(lines, "   Press corresponding key to open note | q to quit")
		table.insert(lines, "")

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false

		-- Keymaps
		for _, entry in ipairs(entries) do
			vim.keymap.set("n", entry.key, function()
				local file = type(entry.path) == "function" and entry.path() or entry.path
				vim.cmd("e " .. vim.fn.expand(file))
			end, { buffer = buf, nowait = true })
		end

		vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf })
	end
end
return dashboard
