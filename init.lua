local M = {}

function M.setup()
  vim.api.nvim_create_user_command("Notes", function()
    require("nvim-notes-dashboard.dashboard").open()
  end, {})
end

return M

