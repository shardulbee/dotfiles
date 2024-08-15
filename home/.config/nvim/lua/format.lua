local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("NoneLsFormatting", {})
null_ls.setup({
	sources = {
		null_ls.builtins.formatting.ocamlformat,
		null_ls.builtins.formatting.fixjson,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.jq,
		null_ls.builtins.formatting.rustfmt,
		null_ls.builtins.formatting.shfmt,
		null_ls.builtins.diagnostics.shellcheck,
		null_ls.builtins.code_actions.gitsigns,
		null_ls.builtins.formatting.sqlfluff.with({
			extra_args = { "--dialect", "duckdb" }, -- change to your dialect
		}),
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format()
				end,
			})
		end
	end,
})
