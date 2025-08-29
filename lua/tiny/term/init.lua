local M = {}
local config = { enabled = true }
local vim = vim

M.term_buf = nil
M.term_win = nil

local function create_buffer()
  return vim.api.nvim_create_buf(false, true)
end

local function open_window(buf, mode)
  local win

  if mode == "vertical" then
    vim.cmd("vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  elseif mode == "floating" then
    local width  = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row    = math.floor((vim.o.lines - height) / 2)
    local col    = math.floor((vim.o.columns - width) / 2)

    win          = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
    })
  else
    vim.cmd("split")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.cmd("resize 10")
  end

  return win
end

local function setup_terminal(buf, win)
  vim.fn.termopen(vim.o.shell)
  vim.bo[buf].buflisted = false
  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert")
end

function M.toggle_term(mode)
  mode = mode or "floating"

  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    vim.api.nvim_win_close(M.term_win, true)
    M.term_win = nil
    return
  end

  if not (M.term_buf and vim.api.nvim_buf_is_valid(M.term_buf)) then
    M.term_buf = create_buffer()
  end

  M.term_win = open_window(M.term_buf, mode)
  setup_terminal(M.term_buf, M.term_win)
end

function M.new_term(mode)
  local buf = create_buffer()
  local win = open_window(buf, mode)
  setup_terminal(buf, win)
end

local function create_terminal_command(name, func)
  vim.api.nvim_create_user_command(name, function(opts)
    func(opts.args)
  end, {
    nargs = "?",
    complete = function()
      return { "floating", "horizontal", "vertical", "plain" }
    end,
  })
end

function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  if config.enabled then
    create_terminal_command("Terminal", M.toggle_term)
    create_terminal_command("NewTerminal", M.new_term)
    create_terminal_command("Term", M.toggle_term)
    create_terminal_command("NewTerm", M.new_term)
  end
end

return M
