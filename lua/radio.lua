local _2afile_2a = "fnl\\radio.fnl"
local domain = "matrix.org"
local config_module = "radio_cfg"
local function server()
  return string.format("https://%s/_matrix/client/r0", domain)
end
local function curl(args)
  local cmd = vim.tbl_flatten({"curl", args})
  local output = vim.fn.system(cmd)
  output = vim.split(output, "\n")
  return output[#output]
end
local function url_encode(str)
  local out = str:gsub("\13?\n", "\13\n")
  local function _1_(c)
    return string.format("%%%02X", c:byte())
  end
  out = out:gsub("([^%w%-%.%_%~ ])", _1_)
  out = out:gsub(" ", "+")
  return out
end
local function get_id(alias)
  if (alias:sub(1, 1) == "!") then
    return alias
  else
    local enc_alias = url_encode(alias)
    local url = string.format("%s/directory/room/%s", server(), enc_alias)
    return (vim.fn.json_decode(curl({"-XGET", url}))).room_id
  end
end
local function get_token(user, password)
  local json = vim.fn.json_encode({type = "m.login.password", user = user, password = password})
  local url = string.format("%s/login", server())
  local raw_output = curl({"-XPOST", "-d", json, url})
  local json_output = vim.fn.json_decode(raw_output)
  return json_output.access_token
end
local function send_text(id, token, text, f_text)
  local enc_id = url_encode(id)
  local json = vim.fn.json_encode({msgtype = "m.text", body = text, format = "org.matrix.custom.html", formatted_body = f_text})
  local url = string.format("%s/rooms/%s/send/m.room.message?access_token=%s", server(), enc_id, token)
  curl({"-XPOST", "-d", json, url})
  return nil
end
local function get_selection()
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  local chunk = vim.api.nvim_buf_get_lines(0, (start_row - 1), end_row, true)
  if (#chunk == 1) then
    return string.sub(chunk[1], (start_col + 1), (end_col + 1))
  else
    chunk[1] = string.sub(chunk[1], (start_col + 1))
    do end (chunk)[#chunk] = string.sub(chunk[#chunk], 1, (end_col + 1))
    return table.concat(chunk, "\n")
  end
end
local function gen_text(text)
  local ft = vim.bo.filetype
  return string.format("```%s\n%s\n```", ft, text)
end
local function gen_f_text(text)
  local ft = vim.bo.filetype
  return string.format("<pre><code class=\"language-%s\">%s\n</code></pre>\n", ft, text)
end
local function exec(alias)
  local config = require(config_module)
  local id = get_id((alias or config.room))
  local token = get_token(config.user, config.password)
  local selection = get_selection()
  local text = gen_text(selection)
  local f_text = gen_f_text(selection)
  return send_text(id, token, text, f_text)
end
local function setup(cfg)
  config_module = (cfg.module or config_module)
  domain = (cfg.domain or domain)
  return nil
end
local function change_room()
  local function _4_(input)
    if input then
      require(config_module).room = input
      return nil
    else
      return nil
    end
  end
  return vim.ui.input({prompt = "Change room: "}, _4_)
end
return {send = exec, setup = setup, change_room = change_room}