return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- Visual UI panels for debugging variables, call stacks, etc.
			"rcarriga/nvim-dap-ui",
			-- Required dependency for nvim-dap-ui
			"nvim-neotest/nvim-nio",

			-- Bridges Mason downloads directly into your DAP configurations
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- 1. Initialize the UI layouts
			dapui.setup()

			-- 2. Automated UI triggers: Open panels when debugging starts, close when it ends
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- 3. Configure mason-nvim-dap to auto-hook up backends you install in Mason
			require("mason-nvim-dap").setup({
				-- Automatically installs backends if you list them here
				ensure_installed = { "python", "codelldb" },
				automatic_installation = true,
				handlers = {}, -- Uses default configurations for installed debuggers
			})

			-- 4. Essential Debugging Keymaps
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })

			-- Toggle UI manually if needed
			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI Panels" })
		end,
	},
}
