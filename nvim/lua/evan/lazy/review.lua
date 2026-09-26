-- Neovim's <C-w>hjkl only walks the tabpage's split layout, and review.nvim
-- draws every pane as an editor-relative float, so directional motion between
-- them has to be resolved from window geometry.
local function box(winid)
  local pos = vim.api.nvim_win_get_position(winid)
  local height, width = vim.api.nvim_win_get_height(winid), vim.api.nvim_win_get_width(winid)
  return {
    row = pos[1] + height / 2,
    col = pos[2] + width / 2,
    rows = { pos[1], pos[1] + height },
    cols = { pos[2], pos[2] + width },
  }
end

local function overlaps(a, b)
  return a[1] < b[2] and b[1] < a[2]
end

---How far `to` lies in direction `dir`, how far it strays off that axis, and
---whether it shares extent with `from` perpendicular to the motion.
local function offsets(dir, from, to)
  if dir == "h" then
    return from.col - to.col, math.abs(from.row - to.row), overlaps(from.rows, to.rows)
  elseif dir == "l" then
    return to.col - from.col, math.abs(from.row - to.row), overlaps(from.rows, to.rows)
  elseif dir == "k" then
    return from.row - to.row, math.abs(from.col - to.col), overlaps(from.cols, to.cols)
  end
  return to.row - from.row, math.abs(from.col - to.col), overlaps(from.cols, to.cols)
end

local function focus(dir)
  local layout = require("review.ui.layout")
  if not layout.is_mounted() then
    return
  end

  local current = vim.api.nvim_get_current_win()
  local from = box(current)
  local best, best_aligned, best_toward, best_across

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    -- A passive window has no keymaps to leave it again, so it is never a target.
    if winid ~= current and layout.is_layout_window(winid) and not layout.is_passive_window(winid) then
      local toward, across, aligned = offsets(dir, from, box(winid))
      -- A pane that lines up beats a nearer one that does not, so moving down
      -- a stacked sidebar cannot veer sideways into the diff.
      local better = not best
        or (aligned and not best_aligned)
        or (aligned == best_aligned and (toward < best_toward or (toward == best_toward and across < best_across)))
      if toward > 0 and better then
        best, best_aligned, best_toward, best_across = winid, aligned, toward, across
      end
    end
  end

  if best then
    vim.api.nvim_set_current_win(best)
  end
end

return {
  "vuki656/review.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Review",
  keys = {
    { "<leader>rv", "<cmd>Review<cr>", desc = "Review toggle" },
    { "<leader>rs", "<cmd>Review send<cr>", desc = "Review send to agent pane" },
    { "<leader>re", "<cmd>Review export<cr>", desc = "Review export to clipboard" },
  },
  opts = {},
  config = function(_, opts)
    require("review").setup(opts)

    -- The comment composer is a markdown buffer, so autoclose.nvim pairs every
    -- apostrophe and quote in prose. Buffer-local mappings shadow its global
    -- insert-mode ones; the composer is the only caller worth exempting, so the
    -- exemption hangs off the constructor rather than off the markdown filetype.
    local ui_util = require("review.ui.util")
    local create_input_buffer = ui_util.create_comment_input_buffer
    ui_util.create_comment_input_buffer = function()
      local bufnr = create_input_buffer()
      for _, key in ipairs({ '"', "'", "`" }) do
        vim.keymap.set("i", key, key, { buffer = bufnr, nowait = true })
      end
      return bufnr
    end

    -- The split diff's left buffer is created without a filetype, so the
    -- mappings are attached on entry rather than by filetype.
    vim.api.nvim_create_autocmd("WinEnter", {
      group = vim.api.nvim_create_augroup("ReviewWindowNavigation", { clear = true }),
      callback = function()
        local layout = require("review.ui.layout")
        local winid = vim.api.nvim_get_current_win()
        if not layout.is_mounted() or not layout.is_layout_window(winid) then
          return
        end

        local bufnr = vim.api.nvim_win_get_buf(winid)
        for _, dir in ipairs({ "h", "j", "k", "l" }) do
          for _, lhs in ipairs({ "<C-w>" .. dir, "<C-w><C-" .. dir .. ">" }) do
            vim.keymap.set("n", lhs, function()
              focus(dir)
            end, { buffer = bufnr, nowait = true, desc = "Review pane " .. dir })
          end
        end
      end,
    })
  end,
}
