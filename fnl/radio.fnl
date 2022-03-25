(local server "https://matrix.org/_matrix/client/r0")
(var config_module "radio_cfg")

(fn curl [args]
    (local cmd (vim.tbl_flatten ["curl" args]))
    (var output (vim.fn.system cmd))
    (set output (vim.split output "\n"))
    (. output (length output))
)

(fn url-encode [str]
    (var out (str:gsub "\r?\n" "\r\n"))
    (set out (out:gsub "([^%w%-%.%_%~ ])" (fn [c]
        (string.format "%%%02X" (c:byte))
    )))
    (set out (out:gsub " " "+"))
    out
)

(fn get-id [alias]
    (local enc-alias (url-encode alias))
    (local url (string.format "%s/directory/room/%s" server enc-alias))
    (. (vim.fn.json_decode (curl ["-XGET" url])) :room_id)
)

(fn get-token [user password]
    (local json (vim.fn.json_encode {
        :type "m.login.password"
        : user
        : password
    }))
    (local url (string.format "%s/login" server))
    (local raw-output (curl ["-XPOST" "-d" json url]))
    (local json-output (vim.fn.json_decode raw-output))
    (. json-output :access_token)
)

(fn send-text [id token text f-text]
    (local enc-id (url-encode id))
    (local json (vim.fn.json_encode {
        :msgtype "m.text"
        :body text
        :format "org.matrix.custom.html"
        :formatted_body f-text
    }))
    (local url (string.format "%s/rooms/%s/send/m.room.message?access_token=%s" server enc-id token))
    (curl ["-XPOST" "-d" json url])
    nil
)

(fn get-selection []
    (local (start-row start-col) (unpack (vim.api.nvim_buf_get_mark 0 "<")))
    (local (end-row end-col) (unpack (vim.api.nvim_buf_get_mark 0 ">")))
    (local chunk (vim.api.nvim_buf_get_lines 0 (- start-row 1) end-row true))
    (if (= (length chunk) 1)
        (string.sub (. chunk 1) (+ start-col 1) (+ end-col 1))
        (do
            (tset chunk 1
                (string.sub (. chunk 1) (+ start-col 1))
            )
            (tset chunk (length chunk)
                (string.sub (. chunk (length chunk)) 1 (+ end-col 1))
            )
            (table.concat chunk "\n")
        )
    )
)

(fn gen-text [text]
    (local ft vim.bo.filetype)
    (string.format "```%s\n%s\n```" ft text)
)

(fn gen-f-text [text]
    (local ft vim.bo.filetype)
    (string.format "<pre><code class=\"language-%s\">%s\n</code></pre>\n" ft text)
)

(fn exec [alias]
    (local config (require config_module))
    (local id (get-id (or alias config.room)))
    (local token (get-token config.user config.password))
    (local selection (get-selection))
    (local text (gen-text selection))
    (local f-text (gen-f-text selection))
    (send-text id token text f-text)
)

(fn setup [cfg]
  (set config_module cfg.module)
)

(fn change-room []
    (vim.ui.input {
        :prompt "Change room: "
    }
    (fn [input]
            (when input (lua "require(config_module).room = input"))
        )
    )
)

{
  :send exec
  : setup
  :change_room change-room
}
