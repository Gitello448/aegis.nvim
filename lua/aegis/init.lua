-- lua/aegis/init.lua --

local state = require 'aegis.state'
local utils = require 'aegis.utils'

local M = {}
state.ns = vim.api.nvim_create_namespace 'Aegis'

M.setup = function(opts)
  state.config = vim.tbl_deep_extend('force', state.config, opts or {})
end

M.open = function()
  state.visible = true
  state.buf = vim.api.nvim_create_buf(false, true)
  utils.gen_winconfig()
  vim.bo[state.buf].ft = 'Aegis'

  state.timer = vim.loop.new_timer()
  state.on_key = vim.on_key(function(_, char)
    if not state.win then
      state.win = vim.api.nvim_open_win(state.buf, false, state.config.winopts)
      vim.api.nvim_set_option_value('winhl', state.config.winhl, { win = state.win })
    end

    utils.parse_key(char)

    state.timer:stop()
    state.timer:start(state.config.timeout * 1000, 0, vim.schedule_wrap(utils.clear_and_close))
  end)

  vim.api.nvim_set_hl(0, 'SkInactive', { default = true, link = 'Visual' })
  vim.api.nvim_set_hl(0, 'SkActive', { default = true, link = 'pmenusel' })

  local augroup = vim.api.nvim_create_augroup('AegisAu', { clear = true })

  vim.api.nvim_create_autocmd('VimResized', {
    group = augroup,
    callback = function()
      if state.win then
        utils.redraw()
      end
    end,
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    group = augroup,
    callback = function()
      if state.win then
        M.close()
        M.open()
      end
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function()
      if state.win then
        M.close()
        M.open()
      end
    end,
    buffer = state.buf,
  })
end

M.close = function()
  vim.api.nvim_del_augroup_by_name 'AegisAu'
  state.timer:stop()
  state.keys = {}
  state.w = 1
  state.extmark_id = nil
  vim.cmd('bd' .. state.buf)
  vim.on_key(nil, state.on_key)
  state.visible = false
  state.win = nil
end

M.toggle = function()
  M[state.visible and 'close' or 'open']()
end

return M
