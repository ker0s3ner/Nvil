-- Inline image rendering. Uses the Kitty graphics protocol under the hood.
--
-- IMPORTANT CAVEAT: this only renders if your terminal/GUI actually supports
-- the Kitty graphics protocol. Ghostty (which you already use) supports it.
-- Neovide's support has historically been partial/version-dependent — if
-- images show as blank boxes in Neovide, run this same config in Ghostty
-- and confirm it works there first to isolate whether it's a Neovide gap.
--
-- System dependency: needs ImageMagick installed.
--   Arch: sudo pacman -S imagemagick

return {
  "3rd/image.nvim",
  ft = { "markdown", "norg" },
  opts = {
    backend = "kitty",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
      },
    },
    max_width_window_percentage = 80,
    max_height_window_percentage = 60,
  },
}
