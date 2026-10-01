return {
  -- brew로 설치한 JetBrains kotlin-lsp 사용, 기본 fwcd 서버는 끔
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {
          mason = false,
          cmd = { "kotlin-lsp", "--stdio" },
          handlers = {
            -- Workaround: kotlin-lsp returns a stale textDocument.version in rename
            -- results, so Neovim rejects them with "Buffer ... newer than edits."
            -- Only rewrite the version when the buffer is unchanged since the request.
            ["textDocument/rename"] = function(err, result, ctx, config)
              local cur = vim.lsp.util.buf_versions[ctx.bufnr]
              if result and result.documentChanges and ctx.version == cur then
                local uri = vim.uri_from_bufnr(ctx.bufnr)
                for _, dc in ipairs(result.documentChanges) do
                  if dc.textDocument and dc.textDocument.uri == uri then
                    dc.textDocument.version = cur
                  end
                end
              end
              return vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)
            end,
          },
        },
      },
    },
  },
  -- kotlin extra가 DAP 설정만 하고 어댑터 설치는 안 해줌
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "kotlin-debug-adapter" } },
  },
}
