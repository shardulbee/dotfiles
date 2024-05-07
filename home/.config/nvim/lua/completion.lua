local cmp = require("cmp")
cmp.setup({
	enabled = function()
		if
			require("cmp.config.context").in_treesitter_capture("comment") == true
			or require("cmp.config.context").in_syntax_group("Comment")
		then
			return false
		else
			return true
		end
	end,
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	formatting = {
		fields = { "menu", "abbr", "kind" },
		format = function(entry, item)
			local menu_icon = {
				nvim_lsp = "λ",
				buffer = "Ω",
			}
			item.menu = menu_icon[entry.source.name]
			return item
		end,
	},
	completion = {
		completeopt = "menu,menuone,noinsert",
	},
	mapping = cmp.mapping.preset.insert({
		["<Tab>"] = vim.schedule_wrap(function(fallback)
			if cmp.visible() then
				cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
			else
				fallback()
			end
		end),
		["<S-Tab>"] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_prev_item()
			end
		end, { "i", "s" }),
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({
			select = false,
			behavior = cmp.ConfirmBehavior.Replace,
		}),
	}),
	sources = {
		{ name = "vsnip" },
		{ name = "path" },
		{ name = "nvim_lsp", keyword_length = 3 }, -- from language server
		{ name = "nvim_lsp_signature_help" }, -- display function signatures with current parameter emphasized
		{ name = "buffer", keyword_length = 2 }, -- source current buffer
	},
})

cmp.setup.filetype("markdown", {
	sources = cmp.config.sources({}, {}),
})
