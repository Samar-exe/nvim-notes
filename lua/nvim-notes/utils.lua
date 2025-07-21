local M = {}

function M.center(str, width)
	local padding = math.floor((width - #str) / 2)
	if padding > 0 then
		return string.rep(" ", padding) .. str
	else
		return str
	end
end

function M.hr(char, width)
	return string.rep(char or "-", width or vim.o.columns)
end

return M
