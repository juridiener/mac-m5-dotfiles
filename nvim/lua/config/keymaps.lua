-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Shorten function name
local keymap = vim.keymap.set
-- Silent keymap option
local opts = { silent = true, noremap = true }

keymap("i", "jk", "<ESC>", opts)

-- Folds
keymap("n", "zz", "za", opts)

local typescript = require("functions.typescript_typecheck")
vim.keymap.set(
  "n",
  "<leader>xp",
  typescript.pick_tsconfig_and_run,
  { desc = "Choose tsconfig.json and run TypeScript check" }
)
