require "ido"

-- Convenience variables
local api             = vim.api
local fn              = vim.fn

-- local variables
local directory_name
local directory_cache = {}

-- Set the prompt
local function ido_browser_set_prompt()
  -- This is an action used more than once, so I decided to abstract it out into a function.
  -- ido_prompt = string.format("Browse (%s): ",
  ido_prompt = string.format("Find file: %s/",

  string.gsub(fn.resolve(directory_name), '^' .. os.getenv('HOME'), '~'))
end

-- Directory Browser
function ido_browser()
  directory_name = vim.api.nvim_buf_get_name(0):gsub("/[^/]+$", "")

  if directory_name == '' then
    directory_name = vim.loop.cwd()
  end

  ido_browser_set_prompt()

  return ido_complete {
    prompt = ido_prompt:gsub(' $', ''),
    items = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name)),
    ido_overlap_statusline = true,
    ido_minimal_mode = true,
    keybinds = {
      ["<BS>"]     = 'ido_browser_backspace',
      ["<Return>"] = 'ido_browser_accept',
      ["<Tab>"]    = 'ido_browser_prefix',
      ["<Right>"]  = 'ido_next_item',
      ["<Left>"]   = 'ido_prev_item'
    },
    on_enter = function(s) directory_name = vim.loop.cwd() end
  }

-- print(ido_complete({prompt = 'Choose: ', items = {'red', 'green', 'blue'}}))
end

-- Custom backspace in ido_browser
function ido_browser_backspace()
  if ido_pattern_text == '' then
    directory_name = fn.fnamemodify(directory_name, ':h')

    ido_browser_set_prompt()
    ido_match_list = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name))
    ido_get_matches()
  else
    ido_key_backspace()
  end
end

-- Accept current item in ido_browser
function ido_browser_accept()
  if ido_current_item == '' then
    ido_current_item = ido_pattern_text
  end

  if fn.isdirectory(directory_name .. '/' .. ido_current_item) == 1 then
    directory_cache[directory_name] = ido_current_item

    directory_name      = directory_name .. '/' .. ido_current_item
    ido_match_list      = fn.systemlist('ls -A ' .. fn.fnameescape(directory_name))
    ido_pattern_text    = ''
    ido_before_cursor   = ''
    ido_after_cursor    = ''
    ido_cursor_position = 1

    ido_get_matches()
    ido_browser_set_prompt()
  else
    ido_close_window()

    directory_cache[directory_name] = ido_current_item

    print("*************************")
    for key, value in pairs(directory_cache) do
      print(key, value)
    end
    print("*************************")

    return vim.cmd('edit ' .. directory_name .. '/' .. ido_current_item)
  end
end

-- Modified prefix acception in ido_browser
function ido_browser_prefix()
  ido_complete_prefix()

  if ido_prefix_text == ido_current_item and #ido_matched_items == 0 and
    ido_prefix_text ~= '' then
    ido_browser_accept()
  end
end


function ido_open_directory()
  ido_close_window()
  vim.cmd('edit ' .. directory_name)
end

function trim(string)
  return string:match("^%s*(.-)%s*$")
end

function ido_directory_name()
  return directory_name
end
