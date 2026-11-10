-- Notebooks for Thiran.
--
-- This switch controls jupytext, Molten, and Notebook Navigator.
-- It does not touch Markdown or live preview.
--
--   enabled = true   the plugins load. On startup, Neovim installs them if
--                    their folders are missing, and creates a Python host
--                    for Molten if that host is not there yet.
--   enabled = false  the plugins stay unloaded, and their install folders
--                    are deleted. The notebook Python host is removed too.
--                    Set this back to true and restart Neovim to install
--                    and enable them again.
--
-- The config file stays in the repo either way:
--   lua/thiran/plugins/notebooks.lua
--
-- A .ipynb file opens as a Python script. Cells are separated by `# %%`.
-- Space j r runs the cell under the cursor.
-- \i picks a kernel.
--
-- The kernel named thiran is created with this host. It can run plain
-- Python. Conda environments that already have ipykernel are added to that
-- list. An environment without ipykernel is skipped.
-- For any other project environment, install ipykernel there, then pick
-- that kernel with \i.
local M = {
	enabled = true,
	-- Folder names under Neovim's lazy install directory.
	plugins = { "jupytext.nvim", "molten-nvim", "NotebookNavigator.nvim" },
}

local function host_root()
	return vim.fs.normalize(vim.fn.stdpath("data") .. "/thiran-notebooks")
end

function M.python()
	return host_root() .. "/bin/python"
end

function M.jupytext_cmd()
	local bin = host_root() .. "/bin/jupytext"
	if vim.fn.executable(bin) == 1 then
		return bin
	end
	return "jupytext"
end

local function system_python()
	for _, name in ipairs({ "python3.13", "python3.12", "python3.11", "python3.10", "python3" }) do
		if vim.fn.executable(name) == 1 then
			return vim.fn.exepath(name)
		end
	end
end

local function host_ready(python)
	vim.fn.system({ python, "-c", "import pynvim, jupyter_client" })
	if vim.v.shell_error ~= 0 then
		return false
	end
	return vim.fn.executable(host_root() .. "/bin/jupytext") == 1
end

local function run(cmd)
	local out = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		out = (out or ""):gsub("%s+$", "")
		if #out > 500 then
			out = out:sub(-500)
		end
		return nil, out
	end
	return out
end

function M.install_host()
	local base = system_python()
	if not base then
		vim.notify("Notebooks need Python 3.10 or newer on PATH.", vim.log.levels.ERROR)
		return false
	end

	local root = host_root()
	local python = root .. "/bin/python"
	vim.notify("Installing the notebook Python host. This runs once.", vim.log.levels.INFO)

	if vim.fn.executable(python) == 0 then
		local _, err = run({ base, "-m", "venv", root })
		if err then
			vim.notify("Could not create the notebook Python environment.\n" .. err, vim.log.levels.ERROR)
			return false
		end
	end

	local _, err = run({ python, "-m", "pip", "install", "pynvim", "jupyter_client", "jupytext", "ipykernel" })
	if err then
		vim.notify("Could not install notebook Python packages.\n" .. err, vim.log.levels.ERROR)
		return false
	end

	run({
		python,
		"-m",
		"ipykernel",
		"install",
		"--user",
		"--name",
		"thiran",
		"--display-name",
		"Python (Thiran)",
	})

	return host_ready(python)
end

-- Called before lazy.nvim setup. Molten's Python host has to be chosen
-- before plugins load.
function M.prepare()
	if not M.enabled then
		return
	end

	local python = M.python()
	if vim.fn.executable(python) == 0 or not host_ready(python) then
		if not M.install_host() then
			return
		end
	end

	vim.g.python3_host_prog = M.python()
end

local function remove_dir(dir, removed)
	if vim.fn.isdirectory(dir) ~= 1 then
		return
	end
	if vim.fn.delete(dir, "rf") == 0 then
		table.insert(removed, vim.fs.basename(dir))
	else
		vim.notify("Could not remove " .. dir .. ".", vim.log.levels.WARN)
	end
end

-- Molten registers a remote plugin. Drop that entry when the plugin is gone,
-- or Neovim will try to start it on the next launch.
local function clean_manifest()
	local manifest = vim.fs.normalize(vim.fn.stdpath("data") .. "/rplugin.vim")
	if vim.fn.filereadable(manifest) == 0 then
		return
	end

	local kept = {}
	local changed = false
	for _, line in ipairs(vim.fn.readfile(manifest)) do
		if line:find("molten", 1, true) then
			changed = true
		else
			table.insert(kept, line)
		end
	end

	if changed then
		vim.fn.writefile(kept, manifest)
	end
end

local function jupyter_kernel_dir()
	if vim.fn.has("mac") == 1 then
		return vim.fs.normalize(vim.env.HOME .. "/Library/Jupyter/kernels")
	end
	return vim.fs.normalize(vim.env.HOME .. "/.local/share/jupyter/kernels")
end

local function conda_executable()
	local candidates = {
		"conda",
		vim.env.HOME .. "/miniforge3/bin/conda",
		vim.env.HOME .. "/miniconda3/bin/conda",
		vim.env.HOME .. "/anaconda3/bin/conda",
		"/opt/homebrew/bin/conda",
	}
	for _, cmd in ipairs(candidates) do
		if vim.fn.executable(cmd) == 1 then
			return cmd
		end
	end
end

local function conda_env_name(path)
	local normalized = vim.fs.normalize(path)
	if vim.fs.basename(vim.fs.dirname(normalized)) == "envs" then
		return vim.fs.basename(normalized)
	end
	return "base"
end

local function env_has_ipykernel(env_path)
	local matches = vim.fn.glob(vim.fs.normalize(env_path) .. "/lib/python*/site-packages/ipykernel/__init__.py", false, true)
	return type(matches) == "table" and #matches > 0
end

local function env_python(env_path)
	local unix = vim.fs.normalize(env_path .. "/bin/python")
	if vim.fn.executable(unix) == 1 then
		return unix
	end
	local windows = vim.fs.normalize(env_path .. "/python.exe")
	if vim.fn.executable(windows) == 1 then
		return windows
	end
end

local function ours_kernel(spec_path)
	if vim.fn.filereadable(spec_path) == 0 then
		return true
	end
	local ok, existing = pcall(vim.json.decode, table.concat(vim.fn.readfile(spec_path), "\n"))
	return ok
		and type(existing) == "table"
		and type(existing.metadata) == "table"
		and existing.metadata.thiran_conda == true
end

-- Jupyter only lists registered kernels. Conda environments are not kernels
-- until a spec points at that environment's Python.
function M.register_conda_kernels(force)
	if M._conda_registered and not force then
		return
	end

	local conda = conda_executable()
	if not conda then
		M._conda_registered = true
		return
	end

	local out = vim.fn.system({ conda, "env", "list", "--json" })
	if vim.v.shell_error ~= 0 then
		return
	end

	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" or type(data.envs) ~= "table" then
		return
	end

	local root = jupyter_kernel_dir()
	vim.fn.mkdir(root, "p")
	for _, env in ipairs(data.envs) do
		if type(env) == "string" and env_has_ipykernel(env) then
			local name = conda_env_name(env)
			local python = env_python(env)
			if python and name:match("^[%w_.+-]+$") and name ~= "thiran" then
				local dir = root .. "/" .. name
				local spec_path = dir .. "/kernel.json"
				if ours_kernel(spec_path) then
					vim.fn.mkdir(dir, "p")
					local spec = {
						argv = { python, "-m", "ipykernel_launcher", "-f", "{connection_file}" },
						display_name = name,
						language = "python",
						metadata = { thiran_conda = true },
					}
					vim.fn.writefile({ vim.json.encode(spec) }, spec_path)
				end
			end
		end
	end

	M._conda_registered = true
end

local function remove_conda_kernels()
	local root = jupyter_kernel_dir()
	if vim.fn.isdirectory(root) ~= 1 then
		return
	end
	for name, kind in vim.fs.dir(root) do
		if kind == "directory" then
			local spec_path = root .. "/" .. name .. "/kernel.json"
			if ours_kernel(spec_path) and vim.fn.filereadable(spec_path) == 1 then
				vim.fn.delete(root .. "/" .. name, "rf")
			end
		end
	end
end

function M.sync()
	if M.enabled then
		return
	end

	local removed = {}
	local root = vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy")
	for _, name in ipairs(M.plugins) do
		remove_dir(vim.fs.normalize(root .. "/" .. name), removed)
	end

	remove_dir(host_root(), removed)
	remove_dir(vim.fs.normalize(vim.env.HOME .. "/.local/share/jupyter/kernels/thiran"), removed)
	remove_dir(vim.fs.normalize(vim.env.HOME .. "/Library/Jupyter/kernels/thiran"), removed)
	remove_conda_kernels()
	clean_manifest()

	if #removed > 0 then
		vim.notify(
			"Removed "
				.. table.concat(removed, ", ")
				.. ". Set enabled = true in lua/thiran/config/notebooks.lua and restart Neovim to install them again.",
			vim.log.levels.INFO
		)
	end
end

return M
