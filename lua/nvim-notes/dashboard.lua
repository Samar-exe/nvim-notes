local dashboard = {}
local utils = require("nvim-notes.utils")

function dashboard.setup()
	function dashboard.open()
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

		vim.cmd("only")
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

		-- ASCII layout
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

		local win_width = vim.api.nvim_win_get_width(0)
		local centered_lines = {}
		for _, line in ipairs(lines) do
			local padding = math.floor((win_width - #line) / 2)
			table.insert(centered_lines, string.rep(" ", padding > 0 and padding or 0) .. line)
		end

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, centered_lines)
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
