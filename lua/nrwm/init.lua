local river=require'nrwm.river'

local M={}

function M.start()
  river.start()
  local function t()
    if river.step() then
      return
    end
    vim.defer_fn(t,1)
  end
  t()
end

return M
