local prettier = { "prettierd", "prettier", sto_after_first = true }
require("conform").setup({
  formatters = {
    biome = {
      require_cwd = true,
    },
  },
  formatters_by_ft = {
    lua = { "stylua" },
    markdown = prettier,
    javascript = { "prettierd", "prettier", sto_after_first = true },
    javascriptreact = { "prettierd", "prettier", sto_after_first = true },
    typescript = { "biome", "prettierd", "prettier", sto_after_first = true, lsp_format = "fallback" },
    typescriptreact = { "biome", "prettierd", "prettier", sto_after_first = true },
    vue = prettier,
    json = { "biome", "prettierd", "prettier", sto_after_first = true },
    jsonc = { "biome", "prettierd", "prettier", sto_after_first = true },
    python = { "black", "isort" },
    go = { "goimports", "gofumpt" },
  },
})

require("lint").linters_by_ft = {
  go = { "golangcilint" },
}
