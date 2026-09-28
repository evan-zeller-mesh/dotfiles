-- Pastes into tmux's last active pane ("!"), normally the agent pane you came
-- from. Bracketed paste (-p) keeps the multi-line export from submitting early.
local function send_to_agent()
  local markdown, count = require("review.export").deliver()
  if not markdown then
    vim.notify("No comments to send", vim.log.levels.WARN, { title = "review.nvim" })
    return
  end

  local load = vim.system({ "tmux", "load-buffer", "-b", "review", "-" }, { stdin = markdown }):wait()
  local paste = load.code == 0 and vim.system({ "tmux", "paste-buffer", "-p", "-d", "-b", "review", "-t", "!" }):wait()
  if not paste or paste.code ~= 0 then
    vim.notify("tmux send failed: " .. ((paste or load).stderr or ""), vim.log.levels.ERROR, { title = "review.nvim" })
    return
  end
  vim.notify(string.format("Sent %d comment(s) to agent pane", count), vim.log.levels.INFO, { title = "review.nvim" })
end

return {
  "georgeguimaraes/review.nvim",
  version = "*",
  dependencies = {
    -- codediff always splits side-by-side 50/50; inline suits narrow screens.
    { "esmuellert/codediff.nvim", opts = { diff = { layout = "inline" } } },
    "MunifTanjim/nui.nvim",
  },
  cmd = "Review",
  keys = {
    { "<leader>rv", "<cmd>Review<cr>", desc = "Review working tree" },
    { "<leader>rc", "<cmd>Review commits<cr>", desc = "Review commits" },
    { "<leader>rb", "<cmd>Review branch<cr>", desc = "Review branch" },
    { "<leader>rn", ":Review note<cr>", mode = { "n", "v" }, desc = "Review: note here" },
    { "<leader>re", "<cmd>Review edit<cr>", desc = "Review: edit comment" },
    { "<leader>rd", "<cmd>Review delete<cr>", desc = "Review: delete comment" },
    { "<leader>rl", "<cmd>Review list<cr>", desc = "Review: list comments" },
    { "<leader>rx", "<cmd>Review export<cr>", desc = "Review: export to clipboard" },
    { "<leader>rp", "<cmd>Review preview<cr>", desc = "Review: preview export" },
    { "<leader>rq", "<cmd>Review close<cr>", desc = "Review: close and export" },
    { "<leader>rt", "<cmd>Review toggle<cr>", desc = "Review: toggle readonly" },
    { "<leader>rs", send_to_agent, desc = "Review: send to agent pane" },
  },
  opts = {},
}
