require("treesitter-context").setup()
require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"ruby",
		"python",
		"rust",
		"lua",
		"ocaml",
		"nix",
		"zig",
		"vimdoc",
		"cpp",
	},
	auto_install = false,
	disable = { "markdown" },
	highlight = {
		additional_vim_regex_highlighting = false,
		enable = true,
	},
	indent = {
		enable = true,
		disable = { "ruby" },
	},
	endwise = {
		enable = true,
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true,

			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = {
					query = "@class.inner",
					desc = "Select inner part of a class region",
				},
			},
		},
	},
})
