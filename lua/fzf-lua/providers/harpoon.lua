local uv = vim.uv or vim.loop
local core = require("fzf-lua.core")
local config = require("fzf-lua.config")
local make_entry = require("fzf-lua.make_entry")

local M = {}

M.harpoon = function(opts)
  opts = config.normalize_opts(opts, "harpoon")
  if not opts then
    return
  end

  local contents = function(cb)
    local function add_entry(x, co)
      x = make_entry.file(x, opts)
      if not x then
        return
      end
      cb(x, function(err)
        coroutine.resume(co)
        if err then
          -- close the pipe to fzf, this
          -- removes the loading indicator in fzf
          cb(nil)
        end
      end)
      coroutine.yield()
    end

    -- run in a coroutine for async progress indication
    coroutine.wrap(function()
      local co = coroutine.running()

      for _, file in ipairs(require("harpoon"):list():display()) do
        print("harpoon", file)
        add_entry(file, co)
      end

      -- done
      cb(nil)
    end)()
  end

  -- for 'file_ignore_patterns' to work on relative paths
  opts.cwd = opts.cwd or uv.cwd()
  opts = core.set_header(opts, opts.headers or { "cwd" })
  return core.fzf_exec(contents, opts)
end

return M
