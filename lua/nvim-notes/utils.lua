local utils = {}

function utils.get_today_note()
	local date = os.date("%Y-%m-%d")
	local path = vim.fn.expand("~/notes/daily/" .. date .. ".txt")

	if vim.fn.filereadable(path) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		local header = "# " .. os.date("%A, %d %B %Y")
		vim.fn.writefile({ header }, path)
	end

	return path
end

return utils
