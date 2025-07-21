-- lua/nvim-notes/init.lua

local M = {}

function M.setup(opts)
	require("nvim-notes.dashboard").setup()
end

return M
