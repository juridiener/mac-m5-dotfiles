return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<A-k>"] = { "scroll_documentation_up", "fallback" },
      ["<A-j>"] = { "scroll_documentation_down", "fallback" },
    },
  },
}
