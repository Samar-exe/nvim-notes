-- lua/notes/init.lua
local M = {}

-- Default configuration
local config = {
	notes_dir = vim.fn.expand("~/notes/"),
	default_extension = ".md",
	date_format = "%Y-%m-%d",
	datetime_format = "%Y-%m-%d %H:%M:%S",

	-- Template system - completely customizable
	templates = {
		default = {
			"# {title}",
			"",
			"Created: {datetime}",
			"",
			"",
		},
		daily = {
			"# Daily Note - {date}",
			"",
			"## Focus",
			"",

			"## Logs",
			"",
		},
		project = {
			"# Project: {title}",
			"",
			"**Status:** Active | **Created:** {date}",
			"",
			"## Objective",
			"",
			"## Tasks",
			"- [ ] ",
			"",
			"## Notes",
			"",
			"",
		},
		meeting = {
			"# Meeting: {title}",
			"",
			"**Date:** {datetime}",
			"**Attendees:** ",
			"",
			"## Agenda",
			"",
			"## Notes",
			"",
			"## Action Items",
			"- [ ] ",
			"",
		},
		dsa = {
			"# {title}",
			"**Created:** {datetime}",
			"**Source:** ",
			"**Pattern:** #",
			"",
			"## Problem Description",
			"",
			"## Approach",
			"",
			"## Code",
			"```java",
			"// Your solution",
			"```",
			"",
			"## Time & Space Complexity",
			"**Time:** O() | **Space:** O()",
			"",
			"## Related Problems",
			"- ",
			"",
		},
		atomic = {
			"# {title}",
			"",
			"**Core Idea:** ",
			"",
			"## Key Points",
			"- ",
			"",
			"## Example",
			"```java",
			"// Code example",
			"```",
			"",
			"## Related Concepts",
			"- [[]]",
			"",
		},
	},

	-- Directory structure - easily customizable
	directories = {
		"inbox",
		"fleeting",
		"log",
		"projects",
		"areas",
		"resources",
		"archive",
	},
}

-- Utility functions
local function get_template_content(template_name, replacements)
	local template = config.templates[template_name] or config.templates.default
	local content = {}

	for _, line in ipairs(template) do
		local processed_line = line
		for key, value in pairs(replacements) do
			processed_line = processed_line:gsub("{" .. key .. "}", value)
		end
		table.insert(content, processed_line)
	end

	return content
end

local function ensure_directory(dir)
	-- Handle both absolute paths and relative to notes_dir
	local full_path = dir:match("^/") and dir or config.notes_dir .. dir
	if vim.fn.isdirectory(full_path) == 0 then
		vim.fn.mkdir(full_path, "p") -- "p" flag creates parent directories
	end
end

-- Recursive directory discovery
local function get_all_directories_recursive(base_dir, prefix)
	base_dir = base_dir or config.notes_dir
	prefix = prefix or ""
	local dirs = {}

	if vim.fn.isdirectory(base_dir) == 0 then
		return dirs
	end

	local handle = vim.loop.fs_scandir(base_dir)
	if handle then
		while true do
			local name, type = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			if type == "directory" and not name:match("^%.") then -- Skip hidden directories
				local full_name = prefix == "" and name or prefix .. "/" .. name
				table.insert(dirs, full_name)

				-- Recursively get subdirectories
				local subdirs = get_all_directories_recursive(base_dir .. name .. "/", full_name)
				for _, subdir in ipairs(subdirs) do
					table.insert(dirs, subdir)
				end
			end
		end
	end

	return dirs
end

local function get_all_directories()
	local dirs = { "." } -- Root notes directory

	-- Add configured directories (these might not exist yet)
	for _, dir in ipairs(config.directories) do
		if not vim.tbl_contains(dirs, dir) then
			table.insert(dirs, dir)
		end
	end

	-- Add all existing nested directories
	local existing_dirs = get_all_directories_recursive()
	for _, dir in ipairs(existing_dirs) do
		if not vim.tbl_contains(dirs, dir) then
			table.insert(dirs, dir)
		end
	end

	table.sort(dirs, function(a, b)
		if a == "." then
			return true
		elseif b == "." then
			return false
		else
			return a < b
		end
	end)

	return dirs
end

-- Recursive file discovery
local function get_note_files_recursive(directory)
	local search_dir = directory == "." and config.notes_dir or config.notes_dir .. directory .. "/"
	local files = {}

	if vim.fn.isdirectory(search_dir) == 0 then
		return files
	end

	local handle = vim.loop.fs_scandir(search_dir)
	if handle then
		while true do
			local name, type = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			if type == "file" and name:match("%.md$") then
				table.insert(files, {
					name = name,
					path = directory == "." and name or directory .. "/" .. name,
					full_path = search_dir .. name,
					directory = directory,
				})
			elseif type == "directory" and not name:match("^%.") then
				-- Recursively scan subdirectories
				local subdir = directory == "." and name or directory .. "/" .. name
				local subfiles = get_note_files_recursive(subdir)
				for _, file in ipairs(subfiles) do
					table.insert(files, file)
				end
			end
		end
	end

	table.sort(files, function(a, b)
		-- Sort by directory first, then by name
		if a.directory ~= b.directory then
			return a.directory < b.directory
		end
		return a.name < b.name
	end)

	return files
end

local function get_note_files(directory)
	-- For backward compatibility, but now supports nested structure
	return get_note_files_recursive(directory)
end

local function get_all_notes()
	return get_note_files_recursive(".")
end

-- Enhanced directory selection with visual nesting
local function select_directory(callback, prompt)
	prompt = prompt or "Select directory:"
	local dirs = get_all_directories()

	-- Add option to create new directory
	table.insert(dirs, "📁 Create new directory...")

	vim.ui.select(dirs, {
		prompt = prompt,
		format_item = function(item)
			if item == "." then
				return "📝 Root (notes/)"
			elseif item == "📁 Create new directory..." then
				return item
			else
				-- Show nested structure visually with indentation
				local depth = select(2, item:gsub("/", "/"))
				local indent = string.rep("  ", depth)
				local name = item:match("([^/]+)$") or item
				return indent .. "📁 " .. name
			end
		end,
	}, function(choice)
		if not choice then
			return
		end

		if choice == "📁 Create new directory..." then
			vim.ui.input({
				prompt = "Directory path (e.g., areas/programming/dsa): ",
			}, function(new_dir)
				if new_dir and new_dir ~= "" then
					-- Clean the directory name
					new_dir = new_dir:gsub("[^%w%-_/]", ""):gsub("^/+", ""):gsub("/+$", "")
					if new_dir ~= "" then
						ensure_directory(new_dir)
						callback(new_dir)
					end
				end
			end)
		else
			callback(choice)
		end
	end)
end

-- Interactive template selection
local function select_template(callback)
	local template_names = {}
	for name, _ in pairs(config.templates) do
		table.insert(template_names, name)
	end
	table.sort(template_names)

	vim.ui.select(template_names, {
		prompt = "Select template:",
		format_item = function(item)
			return "📄 " .. item:gsub("^%l", string.upper)
		end,
	}, callback)
end

-- Main functions
function M.new_note(name, directory, template)
	-- Interactive workflow if parameters not provided
	if not directory then
		select_directory(function(selected_dir)
			if not template then
				select_template(function(selected_template)
					M.new_note(name, selected_dir, selected_template)
				end)
			else
				M.new_note(name, selected_dir, template)
			end
		end, "Where should the note be created?")
		return
	end

	if not template then
		select_template(function(selected_template)
			M.new_note(name, directory, selected_template)
		end)
		return
	end

	if not name or name == "" then
		vim.ui.input({ prompt = "Note name: " }, function(input_name)
			if input_name and input_name ~= "" then
				M.new_note(input_name, directory, template)
			else
				print("Note creation cancelled")
			end
		end)
		return
	end

	-- Ensure directory exists
	local target_dir = directory == "." and config.notes_dir or config.notes_dir .. directory .. "/"
	ensure_directory(target_dir)

	-- Add extension if not present
	if not name:match("%.md$") then
		name = name .. config.default_extension
	end

	local filepath = target_dir .. name

	-- Check if file already exists
	if vim.fn.filereadable(filepath) == 1 then
		print("Note already exists: " .. name)
		vim.cmd("edit " .. filepath)
		return
	end

	-- Create template content
	local replacements = {
		title = name:gsub("%.md$", ""),
		date = os.date(config.date_format),
		datetime = os.date(config.datetime_format),
	}

	local content = get_template_content(template, replacements)

	-- Create and open file
	vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
	vim.cmd("write")

	-- Position cursor at the end
	vim.api.nvim_win_set_cursor(0, { #content, 0 })

	local display_path = directory == "." and name or directory .. "/" .. name
	print("Created note: " .. display_path)
end

function M.open_note()
	local all_notes = get_all_notes()

	if #all_notes == 0 then
		print("No notes found in " .. config.notes_dir)
		return
	end

	vim.ui.select(all_notes, {
		prompt = "Open note:",
		format_item = function(item)
			local dir_display = item.directory == "." and "" or "📁 " .. item.directory .. " → "
			return dir_display .. "📝 " .. item.name:gsub("%.md$", "")
		end,
	}, function(choice)
		if choice then
			vim.cmd("edit " .. vim.fn.fnameescape(choice.full_path))
		end
	end)
end

function M.browse_directory()
	select_directory(function(selected_dir)
		local files = get_note_files(selected_dir)

		if #files == 0 then
			print("No notes in directory: " .. selected_dir)
			return
		end

		-- Filter files to only show those directly in the selected directory or its immediate subdirectories
		local filtered_files = {}
		for _, file in ipairs(files) do
			-- Show files that are in the exact directory or one level deeper
			local relative_path = file.path
			if selected_dir ~= "." then
				relative_path = relative_path:gsub("^" .. vim.pesc(selected_dir) .. "/", "")
			end

			-- Count directory separators - 0 means direct file, 1 means one level deep
			local depth = select(2, relative_path:gsub("/", "/"))
			if depth <= 1 then
				table.insert(filtered_files, file)
			end
		end

		vim.ui.select(filtered_files, {
			prompt = "Notes in " .. (selected_dir == "." and "root" or selected_dir) .. ":",
			format_item = function(item)
				local relative_path = item.path
				if selected_dir ~= "." then
					relative_path = relative_path:gsub("^" .. vim.pesc(selected_dir) .. "/", "")
				end

				-- Show subdirectory if file is in one
				local subdir = relative_path:match("^([^/]+)/")
				if subdir then
					return "📁 " .. subdir .. " → 📝 " .. item.name:gsub("%.md$", "")
				else
					return "📝 " .. item.name:gsub("%.md$", "")
				end
			end,
		}, function(choice)
			if choice then
				vim.cmd("edit " .. vim.fn.fnameescape(choice.full_path))
			end
		end)
	end, "Browse which directory?")
end

function M.list_notes()
	local all_notes = get_all_notes()

	if #all_notes == 0 then
		print("No notes found in " .. config.notes_dir)
		return
	end

	print("All notes in " .. config.notes_dir .. ":")
	local current_dir = ""

	for _, note in ipairs(all_notes) do
		if note.directory ~= current_dir then
			current_dir = note.directory
			local display_dir = current_dir == "." and "Root" or current_dir
			print("\n📁 " .. display_dir .. ":")
		end
		print("  📝 " .. note.name:gsub("%.md$", ""))
	end
end

-- Todo functions (unchanged)
function M.toggle_todo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	if not line then
		return
	end

	local new_line
	if line:match("^%s*%- %[ %]") then
		new_line = line:gsub("^(%s*%- )%[ %]", "%1[x]")
	elseif line:match("^%s*%- %[x%]") then
		new_line = line:gsub("^(%s*%- )%[x%]", "%1[ ]")
	elseif line:match("^%s*%- ") then
		new_line = line:gsub("^(%s*%- )", "%1[ ] ")
	else
		local indent = line:match("^%s*") or ""
		local content = line:gsub("^%s*", "")
		new_line = indent .. "- [ ] " .. content
	end

	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
end

function M.add_todo()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	local indent = ""
	if line then
		indent = line:match("^%s*") or ""
	end

	vim.ui.input({ prompt = "Todo: " }, function(todo_text)
		if todo_text and todo_text ~= "" then
			local new_todo = indent .. "- [ ] " .. todo_text
			vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { new_todo })
			vim.api.nvim_win_set_cursor(0, { line_num + 1, #new_todo })
		end
	end)
end

-- Enhanced search function with better path handling
function M.search_notes(query)
	if not query or query == "" then
		vim.ui.input({ prompt = "Search in notes: " }, function(input_query)
			if input_query and input_query ~= "" then
				M.search_notes(input_query)
			end
		end)
		return
	end

	local search_cmd
	if vim.fn.executable("rg") == 1 then
		search_cmd = "rg --type md --line-number --no-heading --color=never '"
			.. query
			.. "' "
			.. vim.fn.shellescape(config.notes_dir)
	else
		search_cmd = "grep -rn --include='*.md' '" .. query .. "' " .. vim.fn.shellescape(config.notes_dir)
	end

	local results = vim.fn.systemlist(search_cmd)

	if #results == 0 then
		print("No matches found for: " .. query)
		return
	end

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
	print("Found " .. #results .. " matches for: " .. query)
end

-- Daily note with flexible location
function M.daily_note()
	local date = os.date(config.date_format)
	local filename = "daily-" .. date .. config.default_extension

	-- Check if log directory exists, if not ask where to put it
	local daily_dir = config.notes_dir .. "log/"
	if vim.fn.isdirectory(daily_dir) == 0 then
		select_directory(function(selected_dir)
			local target_dir = selected_dir == "." and config.notes_dir or config.notes_dir .. selected_dir .. "/"
			ensure_directory(target_dir)
			M.create_daily_note(target_dir .. filename, date)
		end, "Where should daily notes be stored?")
	else
		M.create_daily_note(daily_dir .. filename, date)
	end
end

function M.create_daily_note(filepath, date)
	if vim.fn.filereadable(filepath) == 0 then
		local replacements = {
			title = "Daily Note",
			date = date,
			datetime = os.date(config.datetime_format),
		}

		local content = get_template_content("daily", replacements)

		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
		vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
		vim.cmd("write")
	else
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	end
end

-- Quick note (inbox-style)
function M.quick_note()
	local name = "quick"
	vim.ui.input({ prompt = "Quick note: " }, function(input_name)
		if input_name and input_name ~= "" then
			name = input_name
		else
			print("Quick note not created")
			return
		end
	end)

	local filename = os.date(config.date_format) .. "-" .. name .. "-" .. config.default_extension
	-- Always goes to inbox or root
	local inbox_dir = config.notes_dir .. "inbox/"
	if vim.fn.isdirectory(inbox_dir) == 0 then
		inbox_dir = config.notes_dir
	end

	local filepath = inbox_dir .. filename

	local title = name:gsub("%$", "")
	local create = function()
		local content = {
			"# " .. title,
			"",
			"Created: " .. os.date(config.datetime_format),
			"",
		}

		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
		vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
		vim.cmd("write")
		print("Quick note saved: " .. filename)
	end
	create()
end

-- Configuration and setup
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", config, opts)

	-- Ensure base notes directory exists
	ensure_directory(config.notes_dir)

	-- Create configured directories
	for _, dir in ipairs(config.directories) do
		ensure_directory(dir)
	end

	-- Commands
	vim.api.nvim_create_user_command("NotesNew", function(args)
		if args.args ~= "" then
			M.new_note(args.args)
		else
			M.new_note()
		end
	end, { nargs = "?", desc = "Create new note" })

	vim.api.nvim_create_user_command("NotesOpen", M.open_note, { desc = "Open existing note" })
	vim.api.nvim_create_user_command("NotesBrowse", M.browse_directory, { desc = "Browse notes by directory" })
	vim.api.nvim_create_user_command("NotesList", M.list_notes, { desc = "List all notes" })
	vim.api.nvim_create_user_command("NotesDaily", M.daily_note, { desc = "Open/create daily note" })
	vim.api.nvim_create_user_command("NotesQuick", M.quick_note, { desc = "Create quick note" })
	vim.api.nvim_create_user_command("NotesSearch", function(args)
		M.search_notes(args.args)
	end, { nargs = "?", desc = "Search in notes" })

	-- Keymaps for markdown files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			local opts = { buffer = true, silent = true }
			vim.keymap.set("n", "<leader>tt", M.toggle_todo, opts)
			vim.keymap.set("n", "<leader>ta", M.add_todo, opts)
		end,
	})
end

-- Utility function to switch organizational systems
function M.switch_system(system_name)
	local systems = {
		flat = {
			directories = {},
		},
		para = {
			directories = { "projects", "areas", "resources", "archive" },
		},
		simple = {
			directories = { "work", "personal", "learning", "archive" },
		},
		by_type = {
			directories = { "daily", "projects", "meetings", "reference", "inbox" },
		},
		zettelkasten = {
			directories = { "permanent", "literature", "fleeting", "projects" },
		},
		learning = {
			directories = { "inbox", "fleeting", "log", "areas", "resources", "archive" },
		},
	}

	if systems[system_name] then
		config = vim.tbl_deep_extend("force", config, systems[system_name])

		-- Create new directories
		for _, dir in ipairs(config.directories) do
			ensure_directory(dir)
		end

		print("Switched to " .. system_name .. " organizational system")
	else
		print("Unknown system: " .. system_name)
		print("Available systems: " .. table.concat(vim.tbl_keys(systems), ", "))
	end
end

return M
