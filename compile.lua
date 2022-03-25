local ok, fennel = pcall(require, "aniseed.compile")
if ok then
    fennel.glob("**/*.fnl", "fnl", "lua")
else
    print("Install Olical/aniseed to compile fennel into lua")
end
