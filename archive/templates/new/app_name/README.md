# <%= app_module %>

To develop a Vessel job for Hadoop:

- Modify the logic inside `lib/<%= app_name %>/mapper.ex` and `lib/<%= app_name %>/reducer.ex` to use your own desired behaviour.
- Compile your job using either `mix compile` or `mix vessel.compile`.
- Use the binaries inside `rel/` for your Hadoop jobs.

If you wish to only build a single binary, remove the entry from `vessel/0` in `mix.exs`, and feel free to remove the generated file.

For support or improvements, please visit [the GitHub repo](https://github.com/zackehh/vessel).
