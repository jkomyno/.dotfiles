local function add_unique(list, values)
  local seen = {}
  for _, value in ipairs(list) do
    seen[value] = true
  end
  for _, value in ipairs(values) do
    if not seen[value] then
      table.insert(list, value)
      seen[value] = true
    end
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      add_unique(opts.ensure_installed, {
        "javascript",
        "tsx",
        "typescript",
        "rust",
        "python",
        "sql",
        "wat",
        "json",
        "toml",
        "yaml",
        "markdown",
        "markdown_inline",
      })
    end,
  },
}
