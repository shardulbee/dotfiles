vim.diagnostic.config({
	virtual_text = true,
	update_in_insert = true,
	underline = false,
	float = { border = "rounded" },
})
vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=#1f2335]])
vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]])
local border = {
	{ "🭽", "FloatBorder" },
	{ "▔", "FloatBorder" },
	{ "🭾", "FloatBorder" },
	{ "▕", "FloatBorder" },
	{ "🭿", "FloatBorder" },
	{ "▁", "FloatBorder" },
	{ "🭼", "FloatBorder" },
	{ "▏", "FloatBorder" },
}
local handlers = {
	["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
	["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
}

-------------------------------------------------------------------------
-- Keymaps
-------------------------------------------------------------------------
local on_attach = function(client, bufnr)
	if client.name == "ruff_lsp" then
		client.server_capabilities.hoverProvider = false
	end

	if client.supports_method("textDocument/formatting") and client.name ~= "pylsp" then
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format()
			end,
		})
	end

	local opts = { noremap = true, silent = true }

	vim.api.nvim_buf_set_keymap(bufnr, "n", ",ca", "<cmd>lua require('fzf-lua').lsp_code_actions()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "i", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)

	vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
end

require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = {
		"shfmt",
		"shellcheck",
		"rust-analyzer",
		"jsonls",
		"clangd",
		"lua-language-server",
		-- "zls",
		"gopls",
		"stylua",
		"sql-formatter",
	},
})
require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			handlers = handlers,
			on_attach = on_attach,
		})
	end,
	["ruff_lsp"] = function()
		require("lspconfig").ruff_lsp.setup({
			handlers = handlers,
			on_attach = on_attach,
			init_options = {
				settings = {
					args = {
						"--extend-ignore=F722",
						"--line-length=120",
					},
				},
			},
		})
	end,
	["pylsp"] = function()
		require("lspconfig").pylsp.setup({
			handlers = handlers,
			on_attach = on_attach,
			init_options = {
				plugins = {
					pyflakes = { enabled = false },
					mccabe = { enabled = false },
					pycodestyle = { enabled = false },
					yapf = { enabled = false },
					autopep8 = { enabled = false },
				},
			},
		})
	end,
})
