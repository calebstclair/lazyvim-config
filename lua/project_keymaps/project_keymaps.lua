local function load_project_keymaps()
  -- Look upward in the directory tree for these markers
  local root = vim.fs.root(0, {
    "pubspec.yaml", -- Flutter
    "config/application.rb", -- Rails
    "Gemfile", -- Ruby
  })

  if not root then
    return
  end

  -- Flutter project
  if vim.fn.filereadable(root .. "/pubspec.yaml") == 1 then
    require("project_keymaps.flutter").setup()
    return
  end

  -- Rails project
  if vim.fn.filereadable(root .. "/config/application.rb") == 1 then
    require("project_keymaps.rails").setup()
    return
  end

  -- Generic Ruby project
  if vim.fn.filereadable(root .. "/Gemfile") == 1 then
    require("project_keymaps.ruby").setup()
    return
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = load_project_keymaps,
})
