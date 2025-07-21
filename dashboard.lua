local utils = require("nvim-notes-dashboard.utils")

local dashboard = {}

local entries = {
  { key = "t", label = "📅 Today’s Note",     path = function() return utils.get_today_note() end },
  { key = "p", label = "🚀 Project Ideas",     path = "~/notes/project_ideas.txt" },
  { key = "c", label = "🎓 Class Notes",       path = "~/notes/class_notes.txt" },
  { key = "v", label = "📼 Video Notes",       path = "~/notes/video_notes.txt" },
  { key = "s", label = "✍️ Scratchpad",         path = "~/notes/scratchpad.txt" },
}

function dashboard.open()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "┌─────────────────────────────────────────────┐",
    "│             🧠 Notes Dashboard              │",
    "└─────────────────────────────────────────────┘",
    ""
  }

  for _, entry in ipairs(entries) do
    table.insert(lines, string.format(" [%s]  %s", entry.key, entry.label))
  end

  table.insert(lines, "")
  table.insert(lines, " Shortcut Keys: t / p / c / v / s")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 50,
    height = #lines,
    row = math.floor((vim.o.lines - #lines) / 2),
    col = math.floor((vim.o.columns - 50) / 2),
    style = "minimal",
    border = "rounded"
  })

  -- keybindings for each note
  for _, entry in ipairs(entries) do
    vim.keymap.set("n", entry.key, function()
      local file = type(entry.path) == "function" and entry.path() or entry.path
      vim.cmd("e " .. vim.fn.expand(file))
    end, { buffer = buf, nowait = true })
  end

  -- Escape to quit dashboard
  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf })
end

return dashboard

