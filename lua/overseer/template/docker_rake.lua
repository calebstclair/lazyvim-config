---@param opts overseer.SearchParams
---@return nil|string
local function get_rakefile(opts)
  return vim.fs.find("Rakefile", { upward = true, type = "file", path = opts.dir })[1]
end

local ENV_KEYS = { "STATE", "PERMIT_ID" }

---@type overseer.TemplateFileProvider
return {
  cache_key = function(opts)
    return get_rakefile(opts)
  end,
  generator = function(opts, cb)
    local rakefile = get_rakefile(opts)
    if not rakefile then
      cb({})
      return
    end
    local cwd = vim.fs.dirname(rakefile)

    local out_w, out_t
    local pending = 2

    local function finish()
      pending = pending - 1
      if pending > 0 then return end

      if out_w.code ~= 0 or out_t.code ~= 0 then
        cb({})
        return
      end

      local caleb_tasks = {}
      for line in vim.gsplit(out_w.stdout or "", "\n") do
        local task_name = line:match("^rake (%S+)")
        if task_name and line:find("lib/tasks/caleb/", 1, true) then
          caleb_tasks[task_name] = true
        end
      end

      local ret = {}
      for line in vim.gsplit(out_t.stdout or "", "\n") do
        if line ~= "" then
          local task_name, params = line:match("^rake (%S+)(%[.-%])")
          if not task_name then
            task_name = line:match("^rake (%S+)")
          end

          if task_name and caleb_tasks[task_name] then
            local desc = line:match("#%s*(.+)$") or ""
            local param_names = {}
            local args = {}

            if params then
              local idx = 1
              for token in params:gmatch("[^,%[%]]+") do
                param_names[#param_names + 1] = token
                args[token] = { type = "string", default = "", order = idx }
                idx = idx + 1
              end
            end

            args["STATE"] = { type = "string", default = "", order = 100 }
            args["PERMIT_ID"] = { type = "string", default = "", order = 101 }
            args["debug"] = { type = "boolean", default = false, order = 102, desc = "Attach debugger (rdbg port 1234)" }

            ret[#ret + 1] = {
              name = "rake " .. task_name,
              desc = desc,
              params = args,
              builder = function(parms)
                local param_vals = {}
                for _, pname in ipairs(param_names) do
                  param_vals[#param_vals + 1] = parms[pname]
                end
                local p = #param_vals > 0 and ("[" .. table.concat(param_vals, ",") .. "]") or ""

                local cmd = { "docker", "compose", "exec", "-T", "-e", "RAILS_ENV=development" }

                for _, key in ipairs(ENV_KEYS) do
                  if parms[key] ~= "" then
                    vim.list_extend(cmd, { "-e", key .. "=" .. parms[key] })
                  end
                end

                if parms.debug then
                  vim.list_extend(cmd, { "-e", "RUBY_DEBUG_OPEN=true", "-e", "RUBY_DEBUG_PORT=1234" })
                  vim.defer_fn(function() require("dap").continue() end, 5000)
                end

                vim.list_extend(cmd, { "web", "bundle", "exec", "rake", task_name .. p })
                return { cmd = cmd, cwd = cwd }
              end,
            }
          end
        end
      end

      cb(ret)
    end

    local exec = { "docker", "compose", "exec", "-T", "web", "bundle", "exec", "rake" }
    vim.system(vim.list_extend(vim.deepcopy(exec), { "-W" }), { text = true, cwd = cwd },
      vim.schedule_wrap(function(out) out_w = out; finish() end))
    vim.system(vim.list_extend(vim.deepcopy(exec), { "-T" }), { text = true, cwd = cwd },
      vim.schedule_wrap(function(out) out_t = out; finish() end))
  end,
}
