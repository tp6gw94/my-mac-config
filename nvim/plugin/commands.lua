local function format_with_lines(base, start_line, end_line)
	if start_line <= 0 or end_line <= 0 then
		return base
	end

	local first = math.min(start_line, end_line)
	local last = math.max(start_line, end_line)
	if first == last then
		return string.format("%s#L%d", base, first)
	end

	return string.format("%s#L%d-L%d", base, first, last)
end

local function copy_path(path_resolver, opts)
	local value = path_resolver()
	if opts and opts.range and opts.range > 0 then
		value = format_with_lines(value, opts.line1, opts.line2)
	end
	vim.fn.setreg("+", value)
	vim.notify("Copied: " .. value)
end

local M = {}

function M.copy_relative(opts)
	copy_path(function()
		return vim.fn.expand("%:.")
	end, opts)
end

function M.copy_absolute(opts)
	copy_path(function()
		return vim.fn.expand("%:p")
	end, opts)
end

vim.api.nvim_create_user_command("CopyRelPath", function(cmd_opts)
	M.copy_relative(cmd_opts)
end, { range = true })

vim.api.nvim_create_user_command("CopyAbsPath", function(cmd_opts)
	M.copy_absolute(cmd_opts)
end, { range = true })

return M
