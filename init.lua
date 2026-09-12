-- ~/.config/nvim/init.lua
-- Entry point. Everything else lives in lua/config and lua/plugins.

require("config.lazy")     -- bootstraps lazy.nvim and loads lua/plugins/*.lua
require("config.options")  -- core vim options (the "UI settings" file)
require("config.keymaps")  -- custom keybinds (the "keybind settings" file)
require("config.autocmds") -- small quality-of-life automations
