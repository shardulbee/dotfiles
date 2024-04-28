local fzfLua = require("fzf-lua")

fzfLua.setup({
	grep = {
		rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
	},
	winopts = {
		height = 0.95,
		width = 0.95,
		preview = {
			flip_columns = 140,
			winopts = {
				number = false,
				relativenumber = false,
			},
		},
		fzf_opts = {
			["--layout"] = "reverse-list",
		},
		previewers = {
			bat = { theme = "base16-default-dark" },
		},
	},
})

local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<C-p>", fzfLua.commands, opts)
vim.keymap.set("n", "gr", fzfLua.lsp_references, opts)
vim.keymap.set("n", "<leader>hh", fzfLua.help_tags, opts)
vim.keymap.set("n", "<leader>b", fzfLua.buffers, opts)
vim.keymap.set("n", "<leader>f", fzfLua.blines, opts)
vim.keymap.set("n", "<leader>F", fzfLua.live_grep_native, opts)
vim.keymap.set("n", "<C-t>", function()
	require("fzf-lua").files({
		winopts = {
			preview = {
				default = "bat",
				flip_columns = 140,
				winopts = {
					number = false,
					relativenumber = false,
				},
			},
		},
		actions = {
			["alt-d"] = function(selected)
				for _, file in ipairs(selected) do
					vim.fn.delete(file)
				end
			end,
		},
	})
end, opts)
