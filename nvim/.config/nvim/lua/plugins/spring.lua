return {
  -- application.yml/properties 자동완성, Bean/Endpoint 탐색
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {},
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "vscode-spring-boot-tools" } },
  },
  -- jdtls에 Spring Boot 확장 jar 연결
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      jdtls = function(config)
        config.init_options = config.init_options or {}
        config.init_options.bundles =
          vim.list_extend(config.init_options.bundles or {}, require("spring_boot").java_extensions())
        return config
      end,
    },
  },
}
