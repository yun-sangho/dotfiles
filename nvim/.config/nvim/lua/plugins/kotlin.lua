return {
  -- brew로 설치한 JetBrains kotlin-lsp 사용, 기본 fwcd 서버는 끔
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = { mason = false, cmd = { "kotlin-lsp", "--stdio" } },
      },
    },
  },
  -- kotlin extra가 DAP 설정만 하고 어댑터 설치는 안 해줌
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "kotlin-debug-adapter" } },
  },
}
