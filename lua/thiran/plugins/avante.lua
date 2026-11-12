-- Chat and inline edit through a Cursor subscription.
--
-- This file is the place to change keys, the sidebar, and which agent runs.
-- Nothing in here is a personal path or a key. Cursor login stays in the
-- Cursor CLI, outside this repository. Run this once in a terminal:
--
--   agent login
--
-- The chat does not attach the current file on its own. Tools ask before
-- they read or change files, and they skip gitignored files. Prompt text is
-- not written to disk. A selection is sent only when you ask Avante to edit it.
--
-- Keys, with Space as the leader:
--   Space a a   open the chat on the right
--   Space a t   hide or show that chat
--   Space a e   edit the selected lines (visual mode)
--   Ctrl-Shift-s  submit the edit or the chat. Ctrl-s is left for the system.
--   Space a m   switch Cursor mode (agent, ask, plan) after the chat is open
--   Space a M   switch the Cursor model after the chat is open
--   Space a p   paste a clipboard image into the chat
--   Space a u   refresh the Cursor usage line
--   za or Enter on a thought opens or closes it
--
-- Space in the prompt types a space. Leader keys run after Esc.
--   @           in the chat, attach a file from disk, including an image
--
-- The usage line under the prompt uses the same agent login as Pi and
-- OpenCode, so the Cursor app does not have to be open. Space a u refreshes it.

local function agent_command()
	local on_path = vim.fn.exepath("agent")
	if on_path ~= "" then
		return on_path
	end
	-- Cursor's documented install location, for people whose shell PATH
	-- does not include it yet.
	local fallback = vim.fs.normalize("~/.local/bin/agent")
	if vim.fn.executable(fallback) == 1 then
		return fallback
	end
	return "agent"
end

---@type LazySpec
return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		init = function()
			require("thiran.config.avante_native").install()
		end,
		-- Cursor goes through Avante's ACP library. That library is Rust, so the
		-- build needs cargo. rustup's default install is used when it is not on PATH.
		build = function(plugin)
			local cargo = vim.fn.exepath("cargo")
			if cargo == "" then
				local fallback = vim.fs.normalize("~/.cargo/bin/cargo")
				if vim.fn.executable(fallback) == 1 then
					cargo = fallback
				end
			end
			if cargo == "" then
				error("Avante needs Rust. Install it from https://rustup.rs, then restart Neovim.")
			end
			-- Keep the build inside the plugin directory. A redirected Cargo
			-- target dir makes `make` look for libraries that were written elsewhere.
			local env = vim.fn.environ()
			env.CARGO_TARGET_DIR = nil
			env.PATH = vim.fn.fnamemodify(cargo, ":h") .. ":" .. (env.PATH or "")
			local result = vim.system({ "make" }, {
				cwd = plugin.dir,
				env = env,
			}):wait()
			if result.code ~= 0 then
				error(result.stderr ~= "" and result.stderr or result.stdout)
			end
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			{ "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
			{
				-- Clipboard images and drag-and-drop into the chat.
				-- Avante stores pasted images under Neovim's state directory.
				"HakonHarnes/img-clip.nvim",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						dir_path = vim.fn.stdpath("cache") .. "/img-clip",
						relative_to_current_file = false,
						use_absolute_path = true,
						drag_and_drop = {
							insert_mode = true,
						},
					},
				},
			},
		},
		opts = function()
			local command = agent_command()
			if vim.fn.executable(command) == 0 then
				vim.schedule(function()
					vim.notify(
						"Avante needs the Cursor CLI (`agent`). Install it, then run `agent login`.",
						vim.log.levels.WARN
					)
				end)
			end

			return {
				provider = "cursor",
				mode = "agentic",
				acp_providers = {
					cursor = {
						command = command,
						args = { "acp" },
						auth_method = "cursor_login",
						env = {
							HOME = os.getenv("HOME"),
							PATH = os.getenv("PATH"),
						},
					},
				},
				behaviour = {
					auto_suggestions = false,
					auto_apply_diff_after_generation = false,
					support_paste_from_clipboard = true,
					enable_token_counting = false,
					-- Opening the chat must not upload the buffer by itself.
					auto_add_current_file = false,
					-- The agent asks before it reads or edits the project.
					auto_approve_tool_permissions = false,
					allow_access_to_git_ignored_files = false,
					confirmation_ui_style = "inline_buttons",
				},
				-- Prompts can contain source. Leave them out of the cache.
				prompt_logger = {
					enabled = false,
				},
				selection = {
					enabled = true,
					hint_display = "delayed",
				},
				windows = {
					position = "right",
					width = 35,
					sidebar_header = {
						enabled = true,
						align = "left",
						rounded = true,
						include_model = true,
					},
					edit = {
						border = "rounded",
						start_insert = true,
					},
					ask = {
						floating = false,
						start_insert = true,
						border = "rounded",
					},
				},
				mappings = {
					ask = "<leader>aa",
					edit = "<leader>ae",
					toggle = {
						default = "<leader>at",
					},
					submit = {
						normal = "<CR>",
						-- Ctrl-s is claimed by the system. Shift keeps submit off that key.
						insert = "<C-S-s>",
					},
					select_acp_mode = "<leader>am",
					select_acp_model = "<leader>aM",
				},
				-- Attach a file with the picker this config already uses.
				selector = {
					provider = "telescope",
				},
				file_selector = {
					provider = "telescope",
				},
				input = {
					provider = "native",
				},
			}
		end,
		config = function(_, opts)
			local native = require("thiran.config.avante_native")
			native.install()
			-- The two errors in the chat were saved there. Drop them, and drop
			-- the session id, before Avante opens that history.
			native.forget_dead_sessions()
			require("avante").setup(opts)
			require("thiran.config.avante_model").install()

			-- Cursor drops a session when its agent process exits. Avante then
			-- reports that as invalid input and stops. Treat it as a missing
			-- session so the chat starts a new one.
			local acp = require("avante.libs.acp_client")
			local load_session = acp.load_session
			function acp:load_session(session_id, cwd, mcp_servers, callback, opts)
				return load_session(self, session_id, cwd, mcp_servers, function(result, err)
					local detail = ""
					if type(err) == "table" then
						if type(err.data) == "table" and type(err.data.message) == "string" then
							detail = err.data.message
						elseif type(err.message) == "string" then
							detail = err.message
						end
						detail = detail:lower()
						if detail:find("session", 1, true) and detail:find("not found", 1, true) then
							err.kind = "not_found"
						end
					end
					callback(result, err)
				end, opts)
			end

			vim.api.nvim_create_augroup("thiran_avante_model", { clear = true })
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local ok_bar, bar = pcall(vim.api.nvim_get_option_value, "winbar", { win = win })
				if ok_bar and type(bar) == "string" and bar:find("Avante", 1, true) then
					vim.api.nvim_set_option_value("winbar", "", { win = win })
				end
			end

			require("thiran.config.cursor_usage").attach()
			require("thiran.config.avante_thoughts").attach()

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("thiran_avante_insert_space", { clear = true }),
				pattern = "AvanteInput",
				callback = function(ev)
					-- Leader is Space. Without nowait, insert mode waits to see if a
					-- leader chord follows, so a typed space appears late.
					vim.keymap.set("i", "<Space>", "<Space>", { buffer = ev.buf, nowait = true })
				end,
			})

			vim.keymap.set("n", "<leader>au", function()
				require("thiran.config.cursor_usage").refresh(true)
			end, { desc = "Refresh Cursor usage" })

			vim.keymap.set("n", "<leader>ap", function()
				local filetype = vim.bo.filetype
				if filetype ~= "AvanteInput" and filetype ~= "Avante" then
					vim.notify("Focus the Avante input, then paste the image.", vim.log.levels.INFO)
					return
				end
				require("avante.clipboard").paste_image()
			end, { desc = "Avante: Paste clipboard image" })

			local ok, wk = pcall(require, "which-key")
			if ok then
				wk.add({
					{ "<leader>a", group = "Avante" },
					{ "<leader>aa", desc = "Open chat" },
					{ "<leader>at", desc = "Toggle chat" },
					{ "<leader>ae", desc = "Edit selection", mode = "v" },
					{ "<leader>am", desc = "Switch mode" },
					{ "<leader>aM", desc = "Switch model" },
					{ "<leader>ap", desc = "Paste clipboard image" },
					{ "<leader>au", desc = "Refresh Cursor usage" },
					{ "<leader>ac", desc = "Add current file" },
				})
			end
		end,
	},
}
