-- lua/notes/init.lua
local M = {}

-- Default configuration
local config = {
	notes_dir = vim.fn.expand("~/notes/"),
	default_extension = ".md",
	date_format = "%Y-%m-%d",
	datetime_format = "%Y-%m-%d %H:%M:%S",
}

-- Ensure notes directory exists
local function ensure_notes_dir()
	local notes_dir = config.notes_dir
	if vim.fn.isdirectory(notes_dir) == 0 then
		vim.fn.mkdir(notes_dir, "p")
	end
end

-- Get all markdown files in notes directory
local function get_note_files()
	local notes_dir = config.notes_dir
	local files = {}
	local handle = vim.loop.fs_scandir(notes_dir)

	if handle then
		while true do
			local name, type = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			if type == "file" and name:match("%.md$") then
				table.insert(files, name)
			end
		end
	end

	table.sort(files)
	return files
end

-- Create a new note
function M.new_note(name)
	ensure_notes_dir()

	if not name or name == "" then
		name = vim.fn.input("Note name: ")
		if name == "" then
			print("Note creation cancelled")
			return
		end
	end

	-- Add .md extension if not present
	if not name:match("%.md$") then
		name = name .. config.default_extension
	end

	local filepath = config.notes_dir .. name

	-- Check if file already exists
	if vim.fn.filereadable(filepath) == 1 then
		print("Note already exists: " .. name)
		vim.cmd("edit " .. filepath)
		return
	end

	-- Create new file with basic template
	local template = {
		"# " .. name:gsub("%.md$", ""),
		"",
		"Created: " .. os.date(config.datetime_format),
		"",
		"## Notes",
		"",
		"## Todo",
		"",
		"- [ ] ",
	}

	vim.cmd("edit " .. filepath)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
	vim.cmd("write")

	-- Position cursor at the end
	vim.api.nvim_win_set_cursor(0, { #template, 0 })
end

-- Open existing note with fuzzy search
function M.open_note()
	ensure_notes_dir()
	local files = get_note_files()

	if #files == 0 then
		print("No notes found in " .. config.notes_dir)
		return
	end

	vim.ui.select(files, {
		prompt = "Select note:",
		format_item = function(item)
			return item:gsub("%.md$", "")
		end,
	}, function(choice)
		if choice then
			vim.cmd("edit " .. config.notes_dir .. choice)
		end
	end)
end

-- List all notes
function M.list_notes()
	ensure_notes_dir()
	local files = get_note_files()

	if #files == 0 then
		print("No notes found in " .. config.notes_dir)
		return
	end

	print("Notes in " .. config.notes_dir .. ":")
	for i, file in ipairs(files) do
		print(string.format("%d. %s", i, file:gsub("%.md$", "")))
	end
end

-- Toggle todo item under cursor
function M.toggle_todo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	if not line then
		return
	end

	local new_line
	if line:match("^%s*%- %[ %]") then
		-- Unchecked -> Checked
		new_line = line:gsub("^(%s*%- )%[ %]", "%1[x]")
	elseif line:match("^%s*%- %[x%]") then
		-- Checked -> Unchecked
		new_line = line:gsub("^(%s*%- )%[x%]", "%1[ ]")
	elseif line:match("^%s*%- ") then
		-- Regular list item -> Todo
		new_line = line:gsub("^(%s*%- )", "%1[ ] ")
	else
		-- Regular line -> Todo
		local indent = line:match("^%s*") or ""
		local content = line:gsub("^%s*", "")
		new_line = indent .. "- [ ] " .. content
	end

	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
end

-- Add new todo item
function M.add_todo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	-- Get current indentation
	local indent = ""
	if line then
		indent = line:match("^%s*") or ""
	end

	local todo_text = vim.fn.input("Todo: ")
	if todo_text == "" then
		return
	end

	local new_todo = indent .. "- [ ] " .. todo_text
	vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { new_todo })

	-- Move cursor to new line
	vim.api.nvim_win_set_cursor(0, { line_num + 1, #new_todo })
end

-- Search in notes
function M.search_notes(query)
	ensure_notes_dir()

	if not query or query == "" then
		query = vim.fn.input("Search in notes: ")
		if query == "" then
			return
		end
	end

	-- Use ripgrep if available, otherwise fallback to grep
	local search_cmd
	if vim.fn.executable("rg") == 1 then
		search_cmd = "rg --type md --line-number --no-heading --color=never '" .. query .. "' " .. config.notes_dir
	else
		search_cmd = "grep -rn --include='*.md' '" .. query .. "' " .. config.notes_dir
	end

	local results = vim.fn.systemlist(search_cmd)

	if #results == 0 then
		print("No matches found for: " .. query)
		return
	end

	-- Open quickfix list with results
	local qf_list = {}
	for _, result in ipairs(results) do
		local file, line_num, text = result:match("^([^:]+):(%d+):(.*)$")
		if file and line_num and text then
			table.insert(qf_list, {
				filename = file,
				lnum = tonumber(line_num),
				text = text:gsub("^%s+", ""),
			})
		end
	end

	vim.fn.setqflist(qf_list)
	vim.cmd("copen")
end

-- Daily note functionality
function M.daily_note()
	ensure_notes_dir()
	local date = os.date(config.date_format)
	local filename = "daily-" .. date .. config.default_extension
	local filepath = config.notes_dir .. filename

	if vim.fn.filereadable(filepath) == 0 then
		-- Create new daily note
		local template = {
			"# Daily Note - " .. date,
			"",
			"## Schedule",
			"",
			"## Notes",
			"",
			"## Todo",
			"",
			"- [ ] ",
			"",
			"## Completed",
			"",
			"",
		}

		vim.cmd("edit " .. filepath)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
		vim.cmd("write")
	else
		vim.cmd("edit " .. filepath)
	end
end

-- Setup function for configuration
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_extend("force", config, opts)

	-- Ensure notes directory exists
	ensure_notes_dir()

	-- Set up commands
	vim.api.nvim_create_user_command("NotesNew", function(args)
		M.new_note(args.args)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("NotesOpen", M.open_note, {})
	vim.api.nvim_create_user_command("NotesList", M.list_notes, {})
	vim.api.nvim_create_user_command("NotesDaily", M.daily_note, {})
	vim.api.nvim_create_user_command("NotesSearch", function(args)
		M.search_notes(args.args)
	end, { nargs = "?" })

	-- Set up keymaps for markdown files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			local opts = { buffer = true, silent = true }
			vim.keymap.set("n", "<leader>tt", M.toggle_todo, opts)
			vim.keymap.set("n", "<leader>ta", M.add_todo, opts)
		end,
	})
end

return M
